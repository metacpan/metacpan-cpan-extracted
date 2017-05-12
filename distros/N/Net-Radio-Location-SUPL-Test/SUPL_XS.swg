%module "Net::Radio::Location::SUPL::XS"

%include <typemaps.i>

%typemap(in) (const char * data, size_t) {
    if($input == NULL) {
	SWIG_exception_fail(SWIG_ArgError(SWIG_TypeError), "in method '" "$symname" "', argument " "$1_name" " of type '" "MsgBuffer""'");
    }
    if( SvFLAGS($input) & (SVf_OK & ~SVf_ROK) ) {
	$1 = SvPV($input, $2);
    }
    else {
	SWIG_exception_fail(SWIG_ArgError(SWIG_TypeError), "in method '" "$symname" "', argument " "$1_name" " of type '" "MsgBuffer""'");
    }
}

%typemap(in) MsgBuffer {
    // $1 = AV2MsgBuf($input);
    // MsgBuffer retval = { NULL, -1 };
    if($input == NULL) {
	SWIG_exception_fail(SWIG_ArgError(SWIG_TypeError), "in method '" "$symname" "', argument " "$1_name" " of type '" "MsgBuffer""'");
    }
    if( SvFLAGS($input) & (SVf_OK & ~SVf_ROK) ) {
	$1.buf = SvPV($input, $1.size);
    }
    else {
	SWIG_exception_fail(SWIG_ArgError(SWIG_TypeError), "in method '" "$symname" "', argument " "$1_name" " of type '" "MsgBuffer""'");
    }
}

%typemap(out) MsgBuffer {
    if (argvi >= items) {            
	EXTEND(sp,1); /* Extend the stack by 1 object */
    }
    $result = sv_2mortal(newSVpv($1.buf, $1.size));
    ++argvi; /* intentional - not portable between languages */
}

%typemap(newfree) MsgBuffer "do { if( $1.buf ) free($1.buf); } while(0);"
%typemap(newfree) MsgBuffer * "do { if( $1 ) { if( $1->buf ) { free( $1->buf ); } free( $1 ); } } while(0);"

%ignore _asn_ctx;
%apply long { time_t, ssize_t };

%{
#include "asn1/ULP-PDU.h"
#include "asn1/RRLP-PDU.h"

struct per_target_buffer
{
	uint8_t *buf;
	size_t pos;
	size_t size;
};

static int per_output(const void *data, size_t size, void *op_key);
static const char * asn_dec_rval_code_str(enum asn_dec_rval_code_e code);

typedef struct _MsgBuffer
{
	uint8_t *buf;
	ssize_t size;
} MsgBuffer;

static MsgBuffer encode_ulp_pdu(struct ULP_PDU *pdu);
%}

%include "swgs/ASN1.i"
%include "swgs/SUPL.i"
%include "swgs/RRLP.i"

%{
static int
per_output(const void *data, size_t size, void *op_key)
{
	struct per_target_buffer *pb = op_key;
	if (pb->size < (pb->pos + size)) {
		uint8_t *tmp = realloc(pb->buf, pb->size + 4096);
		if (!tmp) {
			/* XXX report error */
			abort();
		}
		pb->buf = tmp;
		pb->size += 4096;
	}
	memcpy( pb->buf + pb->pos, data, size );
	pb->pos += size;

	return 0;
}

static const char *
asn_dec_rval_code_str(enum asn_dec_rval_code_e code)
{
    switch(code)
    {
    case RC_OK:
	return "RC_OK - Decoded successfully";

    case RC_WMORE:
	return "RC_WMORE - More data expected, call again";

    case RC_FAIL:
	return "RC_FAIL - Failure to decode data";

    default:
	return "Unknown decoder error code";
    }
}

static MsgBuffer
encode_ulp_pdu(struct ULP_PDU *pdu)
{
	/* asn_per_data_t per_data; */
	struct per_target_buffer per_buf;
	asn_enc_rval_t rval = { 0 };
	MsgBuffer retbuf = { NULL, -1 };

	if (NULL == pdu)
		return retbuf;

	per_buf.buf = calloc( 4096, sizeof(uint8_t) );
	per_buf.pos = 0;
	per_buf.size = 4096;
	rval = uper_encode(&asn_DEF_ULP_PDU, pdu, &per_output, &per_buf);

	if (rval.encoded == -1) {
		free(per_buf.buf);
		croak("error encoding ULP pdu %s: %s",
			rval.failed_type->name,
			strerror(errno));

		return retbuf; /* unreached */
	}

	if (0 == pdu->length) {
		pdu->length = per_buf.pos;
		per_buf.pos = 0;

		/* encode 2nd with length set */
		rval = uper_encode( &asn_DEF_ULP_PDU, pdu, &per_output, &per_buf);
	}

#if 0
	xer_fprint(stdout, &asn_DEF_ULP_PDU, pdu);
	fflush(stdout);
#endif

	if (rval.encoded == -1) {
		free(per_buf.buf);
		croak("error encoding ULP pdu %s: %s",
			rval.failed_type->name,
			strerror(errno));

		return retbuf; /* unreached */
	}

	retbuf.buf = per_buf.buf;
	retbuf.size = per_buf.pos;

	return retbuf;
}

static struct ULP_PDU *
decode_ulp_pdu(MsgBuffer buf)
{
	struct ULP_PDU *ulp_pdu = NULL;
	asn_dec_rval_t rval;
	asn_per_data_t per_data = { buf.buf, 0, ((size_t)buf.size) * 8 };

	rval = asn_DEF_ULP_PDU.uper_decoder( 0, &asn_DEF_ULP_PDU,
					NULL, (void **)&ulp_pdu,
					&per_data);
	if (rval.code != RC_OK) {
		/* Free partially decoded ulp-pdu */
		asn_DEF_ULP_PDU.free_struct(
			&asn_DEF_ULP_PDU, ulp_pdu, 0);

		croak("error parsing ULP pdu on byte %u with %s",
			(unsigned)rval.consumed,
			asn_dec_rval_code_str(rval.code));

		return NULL; /* unreached */
	}

#if 0
	xer_fprint(stdout, &asn_DEF_ULP_PDU, ulp_pdu);
#endif

	return ulp_pdu;
}

static char *
ulp_pdu_to_xml(MsgBuffer buf)
{
	asn_enc_rval_t rval = { 0 };
	struct per_target_buffer per_buf;
	struct ULP_PDU *tmp_pdu = decode_ulp_pdu(buf);

	if (NULL == tmp_pdu)
		return NULL;

	per_buf.buf = calloc( 4096, sizeof(uint8_t) );
	per_buf.pos = 0;
	per_buf.size = 4096;
	rval = xer_encode( &asn_DEF_ULP_PDU, tmp_pdu, XER_F_BASIC, &per_output, &per_buf);

	asn_DEF_ULP_PDU.free_struct(&asn_DEF_ULP_PDU, tmp_pdu, 0);

	if (rval.encoded == -1) {
		free(per_buf.buf);
		croak("error encoding ULP pdu %s: %s",
			rval.failed_type->name,
			strerror(errno));

		return NULL; /* unreached */
	}

	return (char *)per_buf.buf;
}

static char *
dump_ulp_pdu(MsgBuffer buf)
{
	struct per_target_buffer per_buf;
	struct ULP_PDU *tmp_pdu = decode_ulp_pdu(buf);

	if (NULL == tmp_pdu)
		return NULL;

	per_buf.buf = calloc( 4096, sizeof(uint8_t) );
	per_buf.pos = 0;
	per_buf.size = 4096;
	asn_DEF_ULP_PDU.print_struct( &asn_DEF_ULP_PDU, tmp_pdu, 4, &per_output, &per_buf);
	asn_DEF_ULP_PDU.free_struct(&asn_DEF_ULP_PDU, tmp_pdu, 0);

	return (char *)per_buf.buf;
}

%}

%newobject encode_ulp_pdu;
%newobject ulp_pdu_to_xml;
%newobject dump_ulp_pdu;

MsgBuffer encode_ulp_pdu(struct ULP_PDU *pdu);
struct ULP_PDU *decode_ulp_pdu(MsgBuffer buf);
char * ulp_pdu_to_xml(MsgBuffer buf);
char * dump_ulp_pdu(MsgBuffer buf);
