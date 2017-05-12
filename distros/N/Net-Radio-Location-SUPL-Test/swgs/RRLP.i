%{
enum {
    posEstimate_type_ellipsoid_point = 0, // 0000
    posEstimate_type_ellipsoid_point_with_uncertainty_circle = 1, // 0001
    posEstimate_type_ellipsoid_point_with_uncertainty_ellipse = 3, // 0011
    posEstimate_type_polygon = 5, // 0101
    posEstimate_type_ellipsoid_point_with_altitude = 8, // 1000
    posEstimate_type_ellipsoid_point_with_altitude_and_uncertainty_ellipse = 9, // 1001
    posEstimate_type_ellipsoid_arc = 10, // 1010
};

struct ellipsoid_point {
    enum {
        ellipsoid_point_north = 0,
        ellipsoid_point_south = 1
    } sign_of_latitude;
    unsigned int latitude;
    unsigned int longitude;
};

#if __BYTE_ORDER == __LITTLE_ENDIAN
#define MAKE_OCTET_TUPLE2(i1,l1,i2,l2) \
uint8_t i2:l2; \
uint8_t i1:l1
#elif __BYTE_ORDER == __BIG_ENDIAN
#define MAKE_OCTET_TUPLE2(i1,l1,i2,l2) \
uint8_t i1:l1; \
uint8_t i2:l2
#else
# error "Please fix <bits/endian.h>"
#endif

struct ellipsoid_point_shape_data {
    MAKE_OCTET_TUPLE2(sign,1, latitude_high,7);
    uint8_t latitude_mid;
    uint8_t latitude_low;
    uint8_t longitude_high;
    uint8_t longitude_mid;
    uint8_t longitude_low;
};

struct ellipsoid_point_shape {
    MAKE_OCTET_TUPLE2(type,4, padding,4);
    struct ellipsoid_point_shape_data ellipsoid_point;
};

struct ellipsoid_point_shape_with_uncertainy_circle {
    MAKE_OCTET_TUPLE2(type,4, padding,4);
    struct ellipsoid_point_shape_data ellipsoid_point;
    MAKE_OCTET_TUPLE2(spare,1, uncertainty_code,7);
};

struct ellipsoid_point_shape_with_uncertainy_ellipse {
    MAKE_OCTET_TUPLE2(type,4, padding,4);
    struct ellipsoid_point_shape_data ellipsoid_point;
    MAKE_OCTET_TUPLE2(spare0,1, uncertainty_semi_major,7);
    MAKE_OCTET_TUPLE2(spare1,1, uncertainty_semi_minor,7);
    uint8_t orientation_of_major_axis;
    MAKE_OCTET_TUPLE2(spare2,1, confidence,7);
};

struct polygon {
    MAKE_OCTET_TUPLE2(type,4, npoints,4);
    struct ellipsoid_point_shape_data points[];
};

enum {
    altitude_expresses_height = 0,
    altitude_expresses_depth = 1
};

struct ellipsoid_point_shape_with_altitude {
    MAKE_OCTET_TUPLE2(type,4, padding,4);
    struct ellipsoid_point_shape_data ellipsoid_point;
    MAKE_OCTET_TUPLE2(altitude_direction,1, altitude_high,7);
    uint8_t altitude_low;
};

struct ellipsoid_point_shape_with_altitude_and_uncertainy_ellipse {
    MAKE_OCTET_TUPLE2(type,4, padding,4);
    struct ellipsoid_point_shape_data ellipsoid_point;
    MAKE_OCTET_TUPLE2(altitude_direction,1, altitude_high,7);
    uint8_t altitude_low;
    MAKE_OCTET_TUPLE2(spare0,1, uncertainty_semi_major,7);
    MAKE_OCTET_TUPLE2(spare1,1, uncertainty_semi_minor,7);
    uint8_t orientation_of_major_axis;
    MAKE_OCTET_TUPLE2(spare2,1, uncertainty_altitude,7);
    MAKE_OCTET_TUPLE2(spare3,1, confidence,7);
};

struct ellipsoid_arc {
    MAKE_OCTET_TUPLE2(type,4, padding,4);
    struct ellipsoid_point_shape_data ellipsoid_point;
    uint8_t inner_radius_high;
    uint8_t inner_radius_low;
    MAKE_OCTET_TUPLE2(spare0,1, uncertainty_radius,7);
    uint8_t offset_angle;
    uint8_t included_angle;
    MAKE_OCTET_TUPLE2(space1,1, confidence,7);
};

static double
get_fixpoint_arith_multiplier() {
    double fpam = 1E6;
    return fpam;
}

static void
encode_ellipsoid_point(struct ellipsoid_point_shape_data *point, unsigned int south, unsigned int latitude, unsigned int longitude) {
    double dtmp;
    unsigned int utmp;
    int itmp;

    point->sign = south;

    dtmp = latitude;
    dtmp /= get_fixpoint_arith_multiplier();
    dtmp *= (1<<23);
    dtmp /= 90;
    utmp = (unsigned int)dtmp;
    point->latitude_high = (utmp >> 16) & 0x7F;
    point->latitude_mid = (utmp >> 8) & 0xFF;
    point->latitude_low = utmp & 0xFF;

    dtmp = longitude;
    dtmp /= get_fixpoint_arith_multiplier();
    dtmp *= (1<<24);
    dtmp /= 360;
    itmp = (int)dtmp;
    point->longitude_high = (itmp >> 16) & 0xFF;
    point->longitude_mid = (itmp >> 8) & 0xFF;
    point->longitude_low = itmp & 0xFF;
}

static unsigned int
calc_uncertainty_code(unsigned int uncertainty, unsigned int C, double x) {
    double tmp;
    double num, denum;

    tmp = uncertainty;
    tmp /= C;
    tmp += 1;
    num = log(tmp);

    tmp = 1 + x;
    denum = log(tmp);

    tmp = num/denum;
    return (unsigned int)tmp;
}

static void *
prepare_geographical_information_buf(OCTET_STRING_t *posEstimate, size_t shape_size, const char *type_for_err) {
    asn_DEF_OCTET_STRING.free_struct(&asn_DEF_OCTET_STRING, posEstimate, 1);

    posEstimate->buf = calloc( 1, shape_size );
    if( NULL == posEstimate->buf )
        croak("Couldn't allocate memory to encode %s", type_for_err);
    posEstimate->size = shape_size;

    return posEstimate->buf;
}
%}

%typemap(arginit) AccuracyOpt_t {
    memset(&$1, 0, sizeof($1));
}

%typemap(in) AccuracyOpt_t {
    if( 0 != SvOK($input) ) {
	$1.accuracy = calloc(1, sizeof(*($1.accuracy)));
	if( $1.accuracy ) {
	    *($1.accuracy) = SvIV($input);
	}
	else {
	    asn_DEF_AccuracyOpt.free_struct(&asn_DEF_AccuracyOpt, $input, 0);
	    croak("Couldn't allocate memory to transform Accuracy_t embedded attribute of AccuracyOpt_t at $argnum");
	}
    }
    else {
	$1.accuracy = NULL;
    }
}

%typemap(in) AccuracyOpt_t * {
    $1 = calloc(1, sizeof(*$1));
    if( $1 ) {
	if( 0 != SvOK($input) ) {
	    $1->accuracy = calloc(1, sizeof(*($1->accuracy)));
	    if( $1->accuracy ) {
		*($1->accuracy) = SvIV($input);
	    }
	    else {
		asn_DEF_AccuracyOpt.free_struct(&asn_DEF_AccuracyOpt, $input, 0);
		croak("Couldn't allocate memory to transform Accuracy_t embedded attribute of AccuracyOpt_t at $argnum");
	    }
	}
	else {
	    $1->accuracy = NULL;
	}
    }
    else {
	croak("Couldn't allocate memory to transform AccuracyOpt_t at $argnum", i);
    }
}

%typemap(out) AccuracyOpt_t {
    if (argvi >= items) {
	EXTEND(sp,1); /* Extend the stack by 1 object */
    }
    $result = sv_newmortal();
    if(NULL != $1.accuracy) {
	sv_setiv($result, *($1.accuracy));
    }
    ++argvi; /* intentional - not portable between languages */
}

%typemap(out) AccuracyOpt_t * {
    if (argvi >= items) {
	EXTEND(sp,1); /* Extend the stack by 1 object */
    }
    $result = sv_newmortal();
    if($1 && $1->accuracy) {
	sv_setiv($result, *($1->accuracy));
    }
    ++argvi; /* intentional - not portable between languages */
}

%typemap(newfree) AccuracyOpt_t "asn_DEF_AccuracyOpt.free_struct(&asn_DEF_AccuracyOpt, &$1, 1);"
%typemap(newfree) AccuracyOpt_t * "if( $1 ) { asn_DEF_AccuracyOpt.free_struct(&asn_DEF_AccuracyOpt, $1, 0); }"

%apply OCTET_STRING_t { VelocityEstimate_t };
%apply OCTET_STRING_t * { VelocityEstimate_t * };
%apply OCTET_STRING_t { Ext_GeographicalInformation_t };
%apply OCTET_STRING_t * { Ext_GeographicalInformation_t * };

%ignore asn_DEF_RRLP_Component;
%ignore asn_DEF_MsrPosition_Req;
%ignore asn_DEF_MsrPosition_Rsp;
%ignore asn_DEF_PositionInstruct;
%ignore asn_DEF_MethodType;
%ignore asn_DEF_ProtocolError;
%ignore asn_DEF_LocationInfo;
%ignore asn_DEF_RRLP_PDU;

%include "asn1/RRLP-PDU.h"
%include "asn1/RRLP-Component.h"
%include "asn1/MsrPosition-Req.h"
%include "asn1/MsrPosition-Rsp.h"
%include "asn1/PositionInstruct.h"
%include "asn1/MethodType.h"
%include "asn1/ProtocolError.h"
%include "asn1/LocationInfo.h"
%include "asn1/AssistanceData.h"
%include "asn1/PosCapability-Req.h"
%include "asn1/PosCapability-Rsp.h"
typedef long Accuracy_t;
typedef long ErrorCodes_t;

enum FixType {
	FixType_twoDFix	= 0,
	FixType_threeDFix	= 1
};

typedef long FixType_t;


%extend RRLP_PDU {
    RRLP_PDU() {
	struct RRLP_PDU *newobj;
        newobj = calloc( 1, sizeof(*newobj) );
        if( NULL == newobj )
            croak( "Can't allocate memory for new RRLP_PDU object" );

        return newobj;
    }

    RRLP_PDU(const char *data, size_t data_len) {
	struct RRLP_PDU *newobj = NULL;
        asn_dec_rval_t rval;
        asn_per_data_t per_data = { data, 0, data_len * 8 };

        rval = asn_DEF_RRLP_PDU.uper_decoder( 0, &asn_DEF_RRLP_PDU,
                                        NULL, (void **)&newobj,
                                        &per_data);
        if (rval.code != RC_OK) {
                /* Free partially decoded rrlp */
                asn_DEF_RRLP_PDU.free_struct(
                        &asn_DEF_RRLP_PDU, newobj, 0);

                croak("error parsing RRLP pdu on byte %u with %s",
                        (unsigned)rval.consumed,
                        asn_dec_rval_code_str(rval.code));

                return NULL; /* unreached */
        }

        return newobj;
    }

    ~RRLP_PDU() {
	asn_DEF_RRLP_PDU.free_struct(&asn_DEF_RRLP_PDU, $self, 1);
    }

    %newobject encode;
    MsgBuffer encode() {
	/* asn_per_data_t per_data; */
	struct per_target_buffer per_buf;
	asn_enc_rval_t rval = { 0 };
	MsgBuffer retbuf = { NULL, -1 };

	per_buf.buf = calloc( 4096, sizeof(uint8_t) );
	per_buf.pos = 0;
	per_buf.size = 4096;
	rval = uper_encode(&asn_DEF_RRLP_PDU, $self, &per_output, &per_buf);

	if (rval.encoded == -1) {
		free(per_buf.buf);
		croak("error encoding RRLP pdu %s: %s",
			rval.failed_type->name,
			strerror(errno));

		return retbuf; /* unreached */
	}

	retbuf.buf = per_buf.buf;
	retbuf.size = per_buf.pos;

	return retbuf;
    }

    %newobject dump;
    char * dump() {
	struct per_target_buffer per_buf = { calloc( 4096, sizeof(*per_buf.buf) ), 0, 4096 };

	asn_DEF_RRLP_PDU.print_struct(&asn_DEF_RRLP_PDU, $self, 4, &per_output, &per_buf);

	return (char *)per_buf.buf;
    }

    %newobject xml_dump;
    char * xml_dump() {
	asn_enc_rval_t rval = { 0 };
	struct per_target_buffer per_buf = { calloc( 4096, sizeof(*per_buf.buf) ), 0, 4096 };

	rval = xer_encode( &asn_DEF_RRLP_PDU, $self, XER_F_BASIC, &per_output, &per_buf);

	return (char *)per_buf.buf;
    }

    void set_component_type(RRLP_Component_PR kind_of)
    {
	if($self->component.present != RRLP_Component_PR_NOTHING) {
	    asn_DEF_RRLP_PDU.free_struct(&asn_DEF_RRLP_PDU, &$self->component, 1);
	    memset(&$self->component, 0, sizeof($self->component));
	}

        switch(kind_of)
        {
        case RRLP_Component_PR_msrPositionReq:
            break;
        case RRLP_Component_PR_msrPositionRsp:
            break;
        case RRLP_Component_PR_assistanceData:
            break;
        case RRLP_Component_PR_assistanceDataAck:
            break;
        case RRLP_Component_PR_protocolError:
            break;
        case RRLP_Component_PR_posCapabilityReq:
            break;
        case RRLP_Component_PR_posCapabilityRsp:
            break;
	default:
	    croak("Invalid value for component type %d, expecting between %d .. %d",
		    (int)kind_of,
		    (int)RRLP_Component_PR_msrPositionReq,
		    (int)RRLP_Component_PR_posCapabilityRsp);

	    break;
        }

        $self->component.present = kind_of;

        return;
    }
};

%nodefaultctor LocationInfo;
%extend LocationInfo {
    LocationInfo(long refFrame, unsigned int fixType) {
	struct LocationInfo *newobj;
        if( refFrame < 0 || refFrame > 65535 )
            croak("refFrame exceeds range (0..65535)");

        if( fixType != FixType_twoDFix && fixType != FixType_threeDFix )
	    croak( "fixType must be one of following values: FixType_twoDFix, FixType_threeDFix" );

	newobj = calloc( 1, sizeof(*newobj) );
	if( NULL == newobj )
	    croak( "Can't allocate memory for new LocationInfo object" );

	newobj->refFrame = refFrame;
        newobj->fixType = fixType;

        return newobj;
    }

    LocationInfo(long refFrame, long gpsTOW, unsigned int fixType) {
	struct LocationInfo *newobj;
        if( refFrame < 0 || refFrame > 65535 )
            croak("refFrame exceeds range (0..65535)");

        if( gpsTOW < 0 || gpsTOW > 14399999 )
            croak("gpsTOW exceeds range (0..14399999)");

        if( fixType != FixType_twoDFix && fixType != FixType_threeDFix )
	    croak( "fixType must be one of following values: FixType_twoDFix, FixType_threeDFix" );

	newobj = calloc( 1, sizeof(*newobj) );
	if( NULL == newobj )
	    croak( "Can't allocate memory for new LocationInfo object" );

        newobj->gpsTOW = calloc( 1, sizeof(*newobj) );;
	if( NULL == newobj->gpsTOW ) {
            asn_DEF_LocationInfo.free_struct(&asn_DEF_LocationInfo, newobj, 0);
	    croak( "Can't allocate memory for new gpsTOW object" );
        }
	newobj->refFrame = refFrame;
	*(newobj->gpsTOW) = gpsTOW;
        newobj->fixType = fixType;

        return newobj;
    }

    ~LocationInfo() {
	asn_DEF_LocationInfo.free_struct(&asn_DEF_LocationInfo, $self, 0);
    }

    // posEstimate_type_ellipsoid_point = 0, // 0000
    void set_posEstimate(unsigned int south, unsigned int latitude, unsigned int longitude) {
        struct ellipsoid_point_shape *target;

	target = prepare_geographical_information_buf(&$self->posEstimate, sizeof(*target), "ellipsoid point");
        target->type = posEstimate_type_ellipsoid_point;

        encode_ellipsoid_point( &target->ellipsoid_point, south, latitude, longitude);

        return;
    }

    // posEstimate_type_ellipsoid_point_with_uncertainty_circle = 1, // 0001
    void set_posEstimate(unsigned int south, unsigned int latitude, unsigned int longitude, unsigned uncertainty) {
        struct ellipsoid_point_shape_with_uncertainy_circle *target;

	target = prepare_geographical_information_buf(&$self->posEstimate, sizeof(*target), "ellipsoid point with uncertainy circle");
        target->type = posEstimate_type_ellipsoid_point_with_uncertainty_circle;

        encode_ellipsoid_point( &target->ellipsoid_point, south, latitude, longitude);
        // uncertainty = C((1 + x )^K − 1) .. with C = 10 and x = 0,1.
        target->uncertainty_code = calc_uncertainty_code(uncertainty, 10, 0.1);

        return;
    }

    // posEstimate_type_ellipsoid_point_with_uncertainty_ellipse = 3, // 0011
    void set_posEstimate(int south, unsigned int latitude, unsigned int longitude,
                         unsigned uncertainty_semi_major, unsigned uncertainty_semi_minor, unsigned orientation_of_major_axis,
                         unsigned int confidence) {
        struct ellipsoid_point_shape_with_uncertainy_ellipse *target;

	target = prepare_geographical_information_buf(&$self->posEstimate, sizeof(*target), "ellipsoid point with uncertainy ellipse");
        target->type = posEstimate_type_ellipsoid_point_with_uncertainty_ellipse;

        encode_ellipsoid_point( &target->ellipsoid_point, south, latitude, longitude);
        // uncertainty = C((1 + x )^K − 1) .. with C = 10 and x = 0,1.
        target->uncertainty_semi_major = calc_uncertainty_code(uncertainty_semi_major, 10, 0.1);
        target->uncertainty_semi_minor = calc_uncertainty_code(uncertainty_semi_minor, 10, 0.1);
        target->orientation_of_major_axis = orientation_of_major_axis / 2;
        target->confidence = confidence;

        return;
    }

    // posEstimate_type_polygon = 5, // 0101
    void set_posEstimate(struct ellipsoid_point *points, unsigned amount) {
        struct polygon *target;
        unsigned i;

	target = prepare_geographical_information_buf(&$self->posEstimate, sizeof(*target) + amount * sizeof(target->points[0]), "polygon");
        target->type = posEstimate_type_polygon;
        target->npoints = amount;

        for( i = 0; i < amount; ++i ) {
            encode_ellipsoid_point( &target->points[i], points[i].sign_of_latitude, points[i].latitude, points[i].longitude);
        }

        return;
    }

    // posEstimate_type_ellipsoid_point_with_altitude = 8, // 1000
    void set_posEstimate(int south, unsigned int latitude, unsigned int longitude,
                         int depth_altitude, unsigned altitude) {
        struct ellipsoid_point_shape_with_altitude *target;

	target = prepare_geographical_information_buf(&$self->posEstimate, sizeof(*target), "ellipsoid point with altitude");
        target->type = posEstimate_type_ellipsoid_point_with_altitude;

        encode_ellipsoid_point( &target->ellipsoid_point, south, latitude, longitude);

        target->altitude_direction = depth_altitude;
        target->altitude_high = (altitude >> 8) & 0x7F;
        target->altitude_low = altitude & 0xFF;

        return;
    }

    // posEstimate_type_ellipsoid_point_with_altitude_and_uncertainty_ellipse = 9, // 1001
    void set_posEstimate(int south, unsigned int latitude, unsigned int longitude,
                         int depth_altitude, unsigned altitude,
                         unsigned uncertainty_semi_major, unsigned uncertainty_semi_minor, unsigned orientation_of_major_axis,
                         unsigned int uncertainty_altitude, unsigned int confidence) {
        struct ellipsoid_point_shape_with_altitude_and_uncertainy_ellipse *target;

	target = prepare_geographical_information_buf(&$self->posEstimate, sizeof(*target), "ellipsoid point with altitude and uncertainy ellipse");
        target->type = posEstimate_type_ellipsoid_point_with_altitude_and_uncertainty_ellipse;

        encode_ellipsoid_point( &target->ellipsoid_point, south, latitude, longitude);

        target->altitude_direction = depth_altitude;
        target->altitude_high = (altitude >> 8) & 0x7F;
        target->altitude_low = altitude & 0xFF;

        // uncertainty = C((1 + x )^K − 1) .. with C = 10 and x = 0,1.
        target->uncertainty_semi_major = calc_uncertainty_code(uncertainty_semi_major, 10, 0.1);
        target->uncertainty_semi_minor = calc_uncertainty_code(uncertainty_semi_minor, 10, 0.1);
        target->orientation_of_major_axis = orientation_of_major_axis / 2;

        // Uncertainty Altitude h = C((1 + x )^K − 1) .. with C = 45 and x = 0,025.
        target->uncertainty_altitude = calc_uncertainty_code(uncertainty_altitude, 45, 0.025);

        target->confidence = confidence;

        return;
    }

    // posEstimate_type_ellipsoid_arc = 10, // 1010
    void set_posEstimate(int south, unsigned int latitude, unsigned int longitude,
                         unsigned inner_radius, unsigned uncertainty_radius, unsigned offset_angle, unsigned included_angle,
                         unsigned int confidence) {
        struct ellipsoid_arc *target;
        uint16_t inner;

	target = prepare_geographical_information_buf(&$self->posEstimate, sizeof(*target), "ellipsoid arc");
        target->type = posEstimate_type_ellipsoid_arc;

        encode_ellipsoid_point( &target->ellipsoid_point, south, latitude, longitude);

        inner = inner_radius / 5;
        target->inner_radius_high = (inner >> 8) & 0xFF;
        target->inner_radius_low = inner & 0xFF;

        // uncertainty = C((1 + x )^K − 1) .. with C = 10 and x = 0,1.
        target->uncertainty_radius = calc_uncertainty_code(uncertainty_radius, 10, 0.1);

        target->offset_angle = offset_angle / 2;
        target->included_angle = (included_angle + 1) / 2; // good enough ?

        target->confidence = confidence;
    }

    static double get_fixpoint_arith_multiplier() {
        return get_fixpoint_arith_multiplier();
    }
}
