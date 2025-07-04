
/* Boolean */
#ifdef UA_TYPES_BOOLEAN
static void pack_UA_Boolean(SV *out, const UA_Boolean *in);
static void unpack_UA_Boolean(UA_Boolean *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* SByte */
#ifdef UA_TYPES_SBYTE
static void pack_UA_SByte(SV *out, const UA_SByte *in);
static void unpack_UA_SByte(UA_SByte *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Byte */
#ifdef UA_TYPES_BYTE
static void pack_UA_Byte(SV *out, const UA_Byte *in);
static void unpack_UA_Byte(UA_Byte *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Int16 */
#ifdef UA_TYPES_INT16
static void pack_UA_Int16(SV *out, const UA_Int16 *in);
static void unpack_UA_Int16(UA_Int16 *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* UInt16 */
#ifdef UA_TYPES_UINT16
static void pack_UA_UInt16(SV *out, const UA_UInt16 *in);
static void unpack_UA_UInt16(UA_UInt16 *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Int32 */
#ifdef UA_TYPES_INT32
static void pack_UA_Int32(SV *out, const UA_Int32 *in);
static void unpack_UA_Int32(UA_Int32 *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* UInt32 */
#ifdef UA_TYPES_UINT32
static void pack_UA_UInt32(SV *out, const UA_UInt32 *in);
static void unpack_UA_UInt32(UA_UInt32 *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Int64 */
#ifdef UA_TYPES_INT64
static void pack_UA_Int64(SV *out, const UA_Int64 *in);
static void unpack_UA_Int64(UA_Int64 *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* UInt64 */
#ifdef UA_TYPES_UINT64
static void pack_UA_UInt64(SV *out, const UA_UInt64 *in);
static void unpack_UA_UInt64(UA_UInt64 *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Float */
#ifdef UA_TYPES_FLOAT
static void pack_UA_Float(SV *out, const UA_Float *in);
static void unpack_UA_Float(UA_Float *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Double */
#ifdef UA_TYPES_DOUBLE
static void pack_UA_Double(SV *out, const UA_Double *in);
static void unpack_UA_Double(UA_Double *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* String */
#ifdef UA_TYPES_STRING
static void pack_UA_String(SV *out, const UA_String *in);
static void unpack_UA_String(UA_String *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* DateTime */
#ifdef UA_TYPES_DATETIME
static void pack_UA_DateTime(SV *out, const UA_DateTime *in);
static void unpack_UA_DateTime(UA_DateTime *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Guid */
#ifdef UA_TYPES_GUID
static void pack_UA_Guid(SV *out, const UA_Guid *in);
static void unpack_UA_Guid(UA_Guid *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* ByteString */
#ifdef UA_TYPES_BYTESTRING
static void pack_UA_ByteString(SV *out, const UA_ByteString *in);
static void unpack_UA_ByteString(UA_ByteString *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* XmlElement */
#ifdef UA_TYPES_XMLELEMENT
static void pack_UA_XmlElement(SV *out, const UA_XmlElement *in);
static void unpack_UA_XmlElement(UA_XmlElement *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* NodeId */
#ifdef UA_TYPES_NODEID
static void pack_UA_NodeId(SV *out, const UA_NodeId *in);
static void unpack_UA_NodeId(UA_NodeId *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* ExpandedNodeId */
#ifdef UA_TYPES_EXPANDEDNODEID
static void pack_UA_ExpandedNodeId(SV *out, const UA_ExpandedNodeId *in);
static void unpack_UA_ExpandedNodeId(UA_ExpandedNodeId *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* StatusCode */
#ifdef UA_TYPES_STATUSCODE
static void pack_UA_StatusCode(SV *out, const UA_StatusCode *in);
static void unpack_UA_StatusCode(UA_StatusCode *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* QualifiedName */
#ifdef UA_TYPES_QUALIFIEDNAME
static void pack_UA_QualifiedName(SV *out, const UA_QualifiedName *in);
static void unpack_UA_QualifiedName(UA_QualifiedName *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* LocalizedText */
#ifdef UA_TYPES_LOCALIZEDTEXT
static void pack_UA_LocalizedText(SV *out, const UA_LocalizedText *in);
static void unpack_UA_LocalizedText(UA_LocalizedText *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* ExtensionObject */
#ifdef UA_TYPES_EXTENSIONOBJECT
static void pack_UA_ExtensionObject(SV *out, const UA_ExtensionObject *in);
static void unpack_UA_ExtensionObject(UA_ExtensionObject *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* DataValue */
#ifdef UA_TYPES_DATAVALUE
static void pack_UA_DataValue(SV *out, const UA_DataValue *in);
static void unpack_UA_DataValue(UA_DataValue *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* Variant */
#ifdef UA_TYPES_VARIANT
static void pack_UA_Variant(SV *out, const UA_Variant *in);
static void unpack_UA_Variant(UA_Variant *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* DiagnosticInfo */
#ifdef UA_TYPES_DIAGNOSTICINFO
static void pack_UA_DiagnosticInfo(SV *out, const UA_DiagnosticInfo *in);
static void unpack_UA_DiagnosticInfo(UA_DiagnosticInfo *out, SV *in);
/* implemented in Open62541.xs */
#endif

/* NamingRuleType */
#ifdef UA_TYPES_NAMINGRULETYPE
static void pack_UA_NamingRuleType(SV *out, const UA_NamingRuleType *in);
static void unpack_UA_NamingRuleType(UA_NamingRuleType *out, SV *in);

static void
pack_UA_NamingRuleType(SV *out, const UA_NamingRuleType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_NamingRuleType(UA_NamingRuleType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* Enumeration */
#ifdef UA_TYPES_ENUMERATION
static void pack_UA_Enumeration(SV *out, const UA_Enumeration *in);
static void unpack_UA_Enumeration(UA_Enumeration *out, SV *in);

static void
pack_UA_Enumeration(SV *out, const UA_Enumeration *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_Enumeration(UA_Enumeration *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ImageBMP */
#ifdef UA_TYPES_IMAGEBMP
static void pack_UA_ImageBMP(SV *out, const UA_ImageBMP *in);
static void unpack_UA_ImageBMP(UA_ImageBMP *out, SV *in);

static void
pack_UA_ImageBMP(SV *out, const UA_ImageBMP *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_ImageBMP(UA_ImageBMP *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* ImageGIF */
#ifdef UA_TYPES_IMAGEGIF
static void pack_UA_ImageGIF(SV *out, const UA_ImageGIF *in);
static void unpack_UA_ImageGIF(UA_ImageGIF *out, SV *in);

static void
pack_UA_ImageGIF(SV *out, const UA_ImageGIF *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_ImageGIF(UA_ImageGIF *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* ImageJPG */
#ifdef UA_TYPES_IMAGEJPG
static void pack_UA_ImageJPG(SV *out, const UA_ImageJPG *in);
static void unpack_UA_ImageJPG(UA_ImageJPG *out, SV *in);

static void
pack_UA_ImageJPG(SV *out, const UA_ImageJPG *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_ImageJPG(UA_ImageJPG *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* ImagePNG */
#ifdef UA_TYPES_IMAGEPNG
static void pack_UA_ImagePNG(SV *out, const UA_ImagePNG *in);
static void unpack_UA_ImagePNG(UA_ImagePNG *out, SV *in);

static void
pack_UA_ImagePNG(SV *out, const UA_ImagePNG *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_ImagePNG(UA_ImagePNG *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* AudioDataType */
#ifdef UA_TYPES_AUDIODATATYPE
static void pack_UA_AudioDataType(SV *out, const UA_AudioDataType *in);
static void unpack_UA_AudioDataType(UA_AudioDataType *out, SV *in);

static void
pack_UA_AudioDataType(SV *out, const UA_AudioDataType *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_AudioDataType(UA_AudioDataType *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* BitFieldMaskDataType */
#ifdef UA_TYPES_BITFIELDMASKDATATYPE
static void pack_UA_BitFieldMaskDataType(SV *out, const UA_BitFieldMaskDataType *in);
static void unpack_UA_BitFieldMaskDataType(UA_BitFieldMaskDataType *out, SV *in);

static void
pack_UA_BitFieldMaskDataType(SV *out, const UA_BitFieldMaskDataType *in)
{
	dTHX;
	pack_UA_UInt64(out, in);
}

static void
unpack_UA_BitFieldMaskDataType(UA_BitFieldMaskDataType *out, SV *in)
{
	dTHX;
	unpack_UA_UInt64(out, in);
}
#endif

/* KeyValuePair */
#ifdef UA_TYPES_KEYVALUEPAIR
static void pack_UA_KeyValuePair(SV *out, const UA_KeyValuePair *in);
static void unpack_UA_KeyValuePair(UA_KeyValuePair *out, SV *in);

static void
pack_UA_KeyValuePair(SV *out, const UA_KeyValuePair *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "KeyValuePair_key", sv);
	pack_UA_QualifiedName(sv, &in->key);

	sv = newSV(0);
	hv_stores(hv, "KeyValuePair_value", sv);
	pack_UA_Variant(sv, &in->value);

	return;
}

static void
unpack_UA_KeyValuePair(UA_KeyValuePair *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_KeyValuePair_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "KeyValuePair_key", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->key, *svp);

	svp = hv_fetchs(hv, "KeyValuePair_value", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->value, *svp);

	return;
}
#endif

/* AdditionalParametersType */
#ifdef UA_TYPES_ADDITIONALPARAMETERSTYPE
static void pack_UA_AdditionalParametersType(SV *out, const UA_AdditionalParametersType *in);
static void unpack_UA_AdditionalParametersType(UA_AdditionalParametersType *out, SV *in);

static void
pack_UA_AdditionalParametersType(SV *out, const UA_AdditionalParametersType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "AdditionalParametersType_parameters", newRV_noinc((SV*)av));
	av_extend(av, in->parametersSize);
	for (i = 0; i < in->parametersSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->parameters[i]);
	}

	return;
}

static void
unpack_UA_AdditionalParametersType(UA_AdditionalParametersType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AdditionalParametersType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AdditionalParametersType_parameters", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AdditionalParametersType_parameters");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->parameters = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->parameters == NULL)
			CROAKE("UA_Array_new");
		out->parametersSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->parameters[i], *svp);
		}
	}

	return;
}
#endif

/* EphemeralKeyType */
#ifdef UA_TYPES_EPHEMERALKEYTYPE
static void pack_UA_EphemeralKeyType(SV *out, const UA_EphemeralKeyType *in);
static void unpack_UA_EphemeralKeyType(UA_EphemeralKeyType *out, SV *in);

static void
pack_UA_EphemeralKeyType(SV *out, const UA_EphemeralKeyType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EphemeralKeyType_publicKey", sv);
	pack_UA_ByteString(sv, &in->publicKey);

	sv = newSV(0);
	hv_stores(hv, "EphemeralKeyType_signature", sv);
	pack_UA_ByteString(sv, &in->signature);

	return;
}

static void
unpack_UA_EphemeralKeyType(UA_EphemeralKeyType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EphemeralKeyType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EphemeralKeyType_publicKey", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->publicKey, *svp);

	svp = hv_fetchs(hv, "EphemeralKeyType_signature", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->signature, *svp);

	return;
}
#endif

/* RationalNumber */
#ifdef UA_TYPES_RATIONALNUMBER
static void pack_UA_RationalNumber(SV *out, const UA_RationalNumber *in);
static void unpack_UA_RationalNumber(UA_RationalNumber *out, SV *in);

static void
pack_UA_RationalNumber(SV *out, const UA_RationalNumber *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RationalNumber_numerator", sv);
	pack_UA_Int32(sv, &in->numerator);

	sv = newSV(0);
	hv_stores(hv, "RationalNumber_denominator", sv);
	pack_UA_UInt32(sv, &in->denominator);

	return;
}

static void
unpack_UA_RationalNumber(UA_RationalNumber *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RationalNumber_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RationalNumber_numerator", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->numerator, *svp);

	svp = hv_fetchs(hv, "RationalNumber_denominator", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->denominator, *svp);

	return;
}
#endif

/* ThreeDVector */
#ifdef UA_TYPES_THREEDVECTOR
static void pack_UA_ThreeDVector(SV *out, const UA_ThreeDVector *in);
static void unpack_UA_ThreeDVector(UA_ThreeDVector *out, SV *in);

static void
pack_UA_ThreeDVector(SV *out, const UA_ThreeDVector *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ThreeDVector_x", sv);
	pack_UA_Double(sv, &in->x);

	sv = newSV(0);
	hv_stores(hv, "ThreeDVector_y", sv);
	pack_UA_Double(sv, &in->y);

	sv = newSV(0);
	hv_stores(hv, "ThreeDVector_z", sv);
	pack_UA_Double(sv, &in->z);

	return;
}

static void
unpack_UA_ThreeDVector(UA_ThreeDVector *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ThreeDVector_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ThreeDVector_x", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->x, *svp);

	svp = hv_fetchs(hv, "ThreeDVector_y", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->y, *svp);

	svp = hv_fetchs(hv, "ThreeDVector_z", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->z, *svp);

	return;
}
#endif

/* ThreeDCartesianCoordinates */
#ifdef UA_TYPES_THREEDCARTESIANCOORDINATES
static void pack_UA_ThreeDCartesianCoordinates(SV *out, const UA_ThreeDCartesianCoordinates *in);
static void unpack_UA_ThreeDCartesianCoordinates(UA_ThreeDCartesianCoordinates *out, SV *in);

static void
pack_UA_ThreeDCartesianCoordinates(SV *out, const UA_ThreeDCartesianCoordinates *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ThreeDCartesianCoordinates_x", sv);
	pack_UA_Double(sv, &in->x);

	sv = newSV(0);
	hv_stores(hv, "ThreeDCartesianCoordinates_y", sv);
	pack_UA_Double(sv, &in->y);

	sv = newSV(0);
	hv_stores(hv, "ThreeDCartesianCoordinates_z", sv);
	pack_UA_Double(sv, &in->z);

	return;
}

static void
unpack_UA_ThreeDCartesianCoordinates(UA_ThreeDCartesianCoordinates *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ThreeDCartesianCoordinates_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ThreeDCartesianCoordinates_x", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->x, *svp);

	svp = hv_fetchs(hv, "ThreeDCartesianCoordinates_y", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->y, *svp);

	svp = hv_fetchs(hv, "ThreeDCartesianCoordinates_z", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->z, *svp);

	return;
}
#endif

/* ThreeDOrientation */
#ifdef UA_TYPES_THREEDORIENTATION
static void pack_UA_ThreeDOrientation(SV *out, const UA_ThreeDOrientation *in);
static void unpack_UA_ThreeDOrientation(UA_ThreeDOrientation *out, SV *in);

static void
pack_UA_ThreeDOrientation(SV *out, const UA_ThreeDOrientation *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ThreeDOrientation_a", sv);
	pack_UA_Double(sv, &in->a);

	sv = newSV(0);
	hv_stores(hv, "ThreeDOrientation_b", sv);
	pack_UA_Double(sv, &in->b);

	sv = newSV(0);
	hv_stores(hv, "ThreeDOrientation_c", sv);
	pack_UA_Double(sv, &in->c);

	return;
}

static void
unpack_UA_ThreeDOrientation(UA_ThreeDOrientation *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ThreeDOrientation_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ThreeDOrientation_a", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->a, *svp);

	svp = hv_fetchs(hv, "ThreeDOrientation_b", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->b, *svp);

	svp = hv_fetchs(hv, "ThreeDOrientation_c", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->c, *svp);

	return;
}
#endif

/* ThreeDFrame */
#ifdef UA_TYPES_THREEDFRAME
static void pack_UA_ThreeDFrame(SV *out, const UA_ThreeDFrame *in);
static void unpack_UA_ThreeDFrame(UA_ThreeDFrame *out, SV *in);

static void
pack_UA_ThreeDFrame(SV *out, const UA_ThreeDFrame *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ThreeDFrame_cartesianCoordinates", sv);
	pack_UA_ThreeDCartesianCoordinates(sv, &in->cartesianCoordinates);

	sv = newSV(0);
	hv_stores(hv, "ThreeDFrame_orientation", sv);
	pack_UA_ThreeDOrientation(sv, &in->orientation);

	return;
}

static void
unpack_UA_ThreeDFrame(UA_ThreeDFrame *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ThreeDFrame_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ThreeDFrame_cartesianCoordinates", 0);
	if (svp != NULL)
		unpack_UA_ThreeDCartesianCoordinates(&out->cartesianCoordinates, *svp);

	svp = hv_fetchs(hv, "ThreeDFrame_orientation", 0);
	if (svp != NULL)
		unpack_UA_ThreeDOrientation(&out->orientation, *svp);

	return;
}
#endif

/* OpenFileMode */
#ifdef UA_TYPES_OPENFILEMODE
static void pack_UA_OpenFileMode(SV *out, const UA_OpenFileMode *in);
static void unpack_UA_OpenFileMode(UA_OpenFileMode *out, SV *in);

static void
pack_UA_OpenFileMode(SV *out, const UA_OpenFileMode *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_OpenFileMode(UA_OpenFileMode *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* IdentityCriteriaType */
#ifdef UA_TYPES_IDENTITYCRITERIATYPE
static void pack_UA_IdentityCriteriaType(SV *out, const UA_IdentityCriteriaType *in);
static void unpack_UA_IdentityCriteriaType(UA_IdentityCriteriaType *out, SV *in);

static void
pack_UA_IdentityCriteriaType(SV *out, const UA_IdentityCriteriaType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_IdentityCriteriaType(UA_IdentityCriteriaType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* IdentityMappingRuleType */
#ifdef UA_TYPES_IDENTITYMAPPINGRULETYPE
static void pack_UA_IdentityMappingRuleType(SV *out, const UA_IdentityMappingRuleType *in);
static void unpack_UA_IdentityMappingRuleType(UA_IdentityMappingRuleType *out, SV *in);

static void
pack_UA_IdentityMappingRuleType(SV *out, const UA_IdentityMappingRuleType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "IdentityMappingRuleType_criteriaType", sv);
	pack_UA_IdentityCriteriaType(sv, &in->criteriaType);

	sv = newSV(0);
	hv_stores(hv, "IdentityMappingRuleType_criteria", sv);
	pack_UA_String(sv, &in->criteria);

	return;
}

static void
unpack_UA_IdentityMappingRuleType(UA_IdentityMappingRuleType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_IdentityMappingRuleType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "IdentityMappingRuleType_criteriaType", 0);
	if (svp != NULL)
		unpack_UA_IdentityCriteriaType(&out->criteriaType, *svp);

	svp = hv_fetchs(hv, "IdentityMappingRuleType_criteria", 0);
	if (svp != NULL)
		unpack_UA_String(&out->criteria, *svp);

	return;
}
#endif

/* CurrencyUnitType */
#ifdef UA_TYPES_CURRENCYUNITTYPE
static void pack_UA_CurrencyUnitType(SV *out, const UA_CurrencyUnitType *in);
static void unpack_UA_CurrencyUnitType(UA_CurrencyUnitType *out, SV *in);

static void
pack_UA_CurrencyUnitType(SV *out, const UA_CurrencyUnitType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CurrencyUnitType_numericCode", sv);
	pack_UA_Int16(sv, &in->numericCode);

	sv = newSV(0);
	hv_stores(hv, "CurrencyUnitType_exponent", sv);
	pack_UA_SByte(sv, &in->exponent);

	sv = newSV(0);
	hv_stores(hv, "CurrencyUnitType_alphabeticCode", sv);
	pack_UA_String(sv, &in->alphabeticCode);

	sv = newSV(0);
	hv_stores(hv, "CurrencyUnitType_currency", sv);
	pack_UA_LocalizedText(sv, &in->currency);

	return;
}

static void
unpack_UA_CurrencyUnitType(UA_CurrencyUnitType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CurrencyUnitType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CurrencyUnitType_numericCode", 0);
	if (svp != NULL)
		unpack_UA_Int16(&out->numericCode, *svp);

	svp = hv_fetchs(hv, "CurrencyUnitType_exponent", 0);
	if (svp != NULL)
		unpack_UA_SByte(&out->exponent, *svp);

	svp = hv_fetchs(hv, "CurrencyUnitType_alphabeticCode", 0);
	if (svp != NULL)
		unpack_UA_String(&out->alphabeticCode, *svp);

	svp = hv_fetchs(hv, "CurrencyUnitType_currency", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->currency, *svp);

	return;
}
#endif

/* TrustListMasks */
#ifdef UA_TYPES_TRUSTLISTMASKS
static void pack_UA_TrustListMasks(SV *out, const UA_TrustListMasks *in);
static void unpack_UA_TrustListMasks(UA_TrustListMasks *out, SV *in);

static void
pack_UA_TrustListMasks(SV *out, const UA_TrustListMasks *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_TrustListMasks(UA_TrustListMasks *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* TrustListDataType */
#ifdef UA_TYPES_TRUSTLISTDATATYPE
static void pack_UA_TrustListDataType(SV *out, const UA_TrustListDataType *in);
static void unpack_UA_TrustListDataType(UA_TrustListDataType *out, SV *in);

static void
pack_UA_TrustListDataType(SV *out, const UA_TrustListDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "TrustListDataType_specifiedLists", sv);
	pack_UA_UInt32(sv, &in->specifiedLists);

	av = newAV();
	hv_stores(hv, "TrustListDataType_trustedCertificates", newRV_noinc((SV*)av));
	av_extend(av, in->trustedCertificatesSize);
	for (i = 0; i < in->trustedCertificatesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ByteString(sv, &in->trustedCertificates[i]);
	}

	av = newAV();
	hv_stores(hv, "TrustListDataType_trustedCrls", newRV_noinc((SV*)av));
	av_extend(av, in->trustedCrlsSize);
	for (i = 0; i < in->trustedCrlsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ByteString(sv, &in->trustedCrls[i]);
	}

	av = newAV();
	hv_stores(hv, "TrustListDataType_issuerCertificates", newRV_noinc((SV*)av));
	av_extend(av, in->issuerCertificatesSize);
	for (i = 0; i < in->issuerCertificatesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ByteString(sv, &in->issuerCertificates[i]);
	}

	av = newAV();
	hv_stores(hv, "TrustListDataType_issuerCrls", newRV_noinc((SV*)av));
	av_extend(av, in->issuerCrlsSize);
	for (i = 0; i < in->issuerCrlsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ByteString(sv, &in->issuerCrls[i]);
	}

	return;
}

static void
unpack_UA_TrustListDataType(UA_TrustListDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TrustListDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TrustListDataType_specifiedLists", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedLists, *svp);

	svp = hv_fetchs(hv, "TrustListDataType_trustedCertificates", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TrustListDataType_trustedCertificates");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->trustedCertificates = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BYTESTRING]);
		if (out->trustedCertificates == NULL)
			CROAKE("UA_Array_new");
		out->trustedCertificatesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ByteString(&out->trustedCertificates[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "TrustListDataType_trustedCrls", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TrustListDataType_trustedCrls");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->trustedCrls = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BYTESTRING]);
		if (out->trustedCrls == NULL)
			CROAKE("UA_Array_new");
		out->trustedCrlsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ByteString(&out->trustedCrls[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "TrustListDataType_issuerCertificates", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TrustListDataType_issuerCertificates");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->issuerCertificates = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BYTESTRING]);
		if (out->issuerCertificates == NULL)
			CROAKE("UA_Array_new");
		out->issuerCertificatesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ByteString(&out->issuerCertificates[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "TrustListDataType_issuerCrls", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TrustListDataType_issuerCrls");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->issuerCrls = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BYTESTRING]);
		if (out->issuerCrls == NULL)
			CROAKE("UA_Array_new");
		out->issuerCrlsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ByteString(&out->issuerCrls[i], *svp);
		}
	}

	return;
}
#endif

/* DecimalDataType */
#ifdef UA_TYPES_DECIMALDATATYPE
static void pack_UA_DecimalDataType(SV *out, const UA_DecimalDataType *in);
static void unpack_UA_DecimalDataType(UA_DecimalDataType *out, SV *in);

static void
pack_UA_DecimalDataType(SV *out, const UA_DecimalDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DecimalDataType_scale", sv);
	pack_UA_Int16(sv, &in->scale);

	sv = newSV(0);
	hv_stores(hv, "DecimalDataType_value", sv);
	pack_UA_ByteString(sv, &in->value);

	return;
}

static void
unpack_UA_DecimalDataType(UA_DecimalDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DecimalDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DecimalDataType_scale", 0);
	if (svp != NULL)
		unpack_UA_Int16(&out->scale, *svp);

	svp = hv_fetchs(hv, "DecimalDataType_value", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->value, *svp);

	return;
}
#endif

/* DataTypeDescription */
#ifdef UA_TYPES_DATATYPEDESCRIPTION
static void pack_UA_DataTypeDescription(SV *out, const UA_DataTypeDescription *in);
static void unpack_UA_DataTypeDescription(UA_DataTypeDescription *out, SV *in);

static void
pack_UA_DataTypeDescription(SV *out, const UA_DataTypeDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DataTypeDescription_dataTypeId", sv);
	pack_UA_NodeId(sv, &in->dataTypeId);

	sv = newSV(0);
	hv_stores(hv, "DataTypeDescription_name", sv);
	pack_UA_QualifiedName(sv, &in->name);

	return;
}

static void
unpack_UA_DataTypeDescription(UA_DataTypeDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataTypeDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataTypeDescription_dataTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataTypeId, *svp);

	svp = hv_fetchs(hv, "DataTypeDescription_name", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->name, *svp);

	return;
}
#endif

/* SimpleTypeDescription */
#ifdef UA_TYPES_SIMPLETYPEDESCRIPTION
static void pack_UA_SimpleTypeDescription(SV *out, const UA_SimpleTypeDescription *in);
static void unpack_UA_SimpleTypeDescription(UA_SimpleTypeDescription *out, SV *in);

static void
pack_UA_SimpleTypeDescription(SV *out, const UA_SimpleTypeDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SimpleTypeDescription_dataTypeId", sv);
	pack_UA_NodeId(sv, &in->dataTypeId);

	sv = newSV(0);
	hv_stores(hv, "SimpleTypeDescription_name", sv);
	pack_UA_QualifiedName(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "SimpleTypeDescription_baseDataType", sv);
	pack_UA_NodeId(sv, &in->baseDataType);

	sv = newSV(0);
	hv_stores(hv, "SimpleTypeDescription_builtInType", sv);
	pack_UA_Byte(sv, &in->builtInType);

	return;
}

static void
unpack_UA_SimpleTypeDescription(UA_SimpleTypeDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SimpleTypeDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SimpleTypeDescription_dataTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataTypeId, *svp);

	svp = hv_fetchs(hv, "SimpleTypeDescription_name", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->name, *svp);

	svp = hv_fetchs(hv, "SimpleTypeDescription_baseDataType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->baseDataType, *svp);

	svp = hv_fetchs(hv, "SimpleTypeDescription_builtInType", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->builtInType, *svp);

	return;
}
#endif

/* PubSubState */
#ifdef UA_TYPES_PUBSUBSTATE
static void pack_UA_PubSubState(SV *out, const UA_PubSubState *in);
static void unpack_UA_PubSubState(UA_PubSubState *out, SV *in);

static void
pack_UA_PubSubState(SV *out, const UA_PubSubState *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_PubSubState(UA_PubSubState *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* DataSetFieldFlags */
#ifdef UA_TYPES_DATASETFIELDFLAGS
static void pack_UA_DataSetFieldFlags(SV *out, const UA_DataSetFieldFlags *in);
static void unpack_UA_DataSetFieldFlags(UA_DataSetFieldFlags *out, SV *in);

static void
pack_UA_DataSetFieldFlags(SV *out, const UA_DataSetFieldFlags *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_DataSetFieldFlags(UA_DataSetFieldFlags *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ConfigurationVersionDataType */
#ifdef UA_TYPES_CONFIGURATIONVERSIONDATATYPE
static void pack_UA_ConfigurationVersionDataType(SV *out, const UA_ConfigurationVersionDataType *in);
static void unpack_UA_ConfigurationVersionDataType(UA_ConfigurationVersionDataType *out, SV *in);

static void
pack_UA_ConfigurationVersionDataType(SV *out, const UA_ConfigurationVersionDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ConfigurationVersionDataType_majorVersion", sv);
	pack_UA_UInt32(sv, &in->majorVersion);

	sv = newSV(0);
	hv_stores(hv, "ConfigurationVersionDataType_minorVersion", sv);
	pack_UA_UInt32(sv, &in->minorVersion);

	return;
}

static void
unpack_UA_ConfigurationVersionDataType(UA_ConfigurationVersionDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ConfigurationVersionDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ConfigurationVersionDataType_majorVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->majorVersion, *svp);

	svp = hv_fetchs(hv, "ConfigurationVersionDataType_minorVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->minorVersion, *svp);

	return;
}
#endif

/* PublishedVariableDataType */
#ifdef UA_TYPES_PUBLISHEDVARIABLEDATATYPE
static void pack_UA_PublishedVariableDataType(SV *out, const UA_PublishedVariableDataType *in);
static void unpack_UA_PublishedVariableDataType(UA_PublishedVariableDataType *out, SV *in);

static void
pack_UA_PublishedVariableDataType(SV *out, const UA_PublishedVariableDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "PublishedVariableDataType_publishedVariable", sv);
	pack_UA_NodeId(sv, &in->publishedVariable);

	sv = newSV(0);
	hv_stores(hv, "PublishedVariableDataType_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "PublishedVariableDataType_samplingIntervalHint", sv);
	pack_UA_Double(sv, &in->samplingIntervalHint);

	sv = newSV(0);
	hv_stores(hv, "PublishedVariableDataType_deadbandType", sv);
	pack_UA_UInt32(sv, &in->deadbandType);

	sv = newSV(0);
	hv_stores(hv, "PublishedVariableDataType_deadbandValue", sv);
	pack_UA_Double(sv, &in->deadbandValue);

	sv = newSV(0);
	hv_stores(hv, "PublishedVariableDataType_indexRange", sv);
	pack_UA_String(sv, &in->indexRange);

	sv = newSV(0);
	hv_stores(hv, "PublishedVariableDataType_substituteValue", sv);
	pack_UA_Variant(sv, &in->substituteValue);

	av = newAV();
	hv_stores(hv, "PublishedVariableDataType_metaDataProperties", newRV_noinc((SV*)av));
	av_extend(av, in->metaDataPropertiesSize);
	for (i = 0; i < in->metaDataPropertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_QualifiedName(sv, &in->metaDataProperties[i]);
	}

	return;
}

static void
unpack_UA_PublishedVariableDataType(UA_PublishedVariableDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PublishedVariableDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishedVariableDataType_publishedVariable", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->publishedVariable, *svp);

	svp = hv_fetchs(hv, "PublishedVariableDataType_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "PublishedVariableDataType_samplingIntervalHint", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->samplingIntervalHint, *svp);

	svp = hv_fetchs(hv, "PublishedVariableDataType_deadbandType", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->deadbandType, *svp);

	svp = hv_fetchs(hv, "PublishedVariableDataType_deadbandValue", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->deadbandValue, *svp);

	svp = hv_fetchs(hv, "PublishedVariableDataType_indexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->indexRange, *svp);

	svp = hv_fetchs(hv, "PublishedVariableDataType_substituteValue", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->substituteValue, *svp);

	svp = hv_fetchs(hv, "PublishedVariableDataType_metaDataProperties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishedVariableDataType_metaDataProperties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->metaDataProperties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_QUALIFIEDNAME]);
		if (out->metaDataProperties == NULL)
			CROAKE("UA_Array_new");
		out->metaDataPropertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_QualifiedName(&out->metaDataProperties[i], *svp);
		}
	}

	return;
}
#endif

/* PublishedDataItemsDataType */
#ifdef UA_TYPES_PUBLISHEDDATAITEMSDATATYPE
static void pack_UA_PublishedDataItemsDataType(SV *out, const UA_PublishedDataItemsDataType *in);
static void unpack_UA_PublishedDataItemsDataType(UA_PublishedDataItemsDataType *out, SV *in);

static void
pack_UA_PublishedDataItemsDataType(SV *out, const UA_PublishedDataItemsDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "PublishedDataItemsDataType_publishedData", newRV_noinc((SV*)av));
	av_extend(av, in->publishedDataSize);
	for (i = 0; i < in->publishedDataSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_PublishedVariableDataType(sv, &in->publishedData[i]);
	}

	return;
}

static void
unpack_UA_PublishedDataItemsDataType(UA_PublishedDataItemsDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PublishedDataItemsDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishedDataItemsDataType_publishedData", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishedDataItemsDataType_publishedData");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->publishedData = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_PUBLISHEDVARIABLEDATATYPE]);
		if (out->publishedData == NULL)
			CROAKE("UA_Array_new");
		out->publishedDataSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_PublishedVariableDataType(&out->publishedData[i], *svp);
		}
	}

	return;
}
#endif

/* DataSetFieldContentMask */
#ifdef UA_TYPES_DATASETFIELDCONTENTMASK
static void pack_UA_DataSetFieldContentMask(SV *out, const UA_DataSetFieldContentMask *in);
static void unpack_UA_DataSetFieldContentMask(UA_DataSetFieldContentMask *out, SV *in);

static void
pack_UA_DataSetFieldContentMask(SV *out, const UA_DataSetFieldContentMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_DataSetFieldContentMask(UA_DataSetFieldContentMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* DataSetWriterDataType */
#ifdef UA_TYPES_DATASETWRITERDATATYPE
static void pack_UA_DataSetWriterDataType(SV *out, const UA_DataSetWriterDataType *in);
static void unpack_UA_DataSetWriterDataType(UA_DataSetWriterDataType *out, SV *in);

static void
pack_UA_DataSetWriterDataType(SV *out, const UA_DataSetWriterDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_enabled", sv);
	pack_UA_Boolean(sv, &in->enabled);

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_dataSetWriterId", sv);
	pack_UA_UInt16(sv, &in->dataSetWriterId);

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_dataSetFieldContentMask", sv);
	pack_UA_DataSetFieldContentMask(sv, &in->dataSetFieldContentMask);

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_keyFrameCount", sv);
	pack_UA_UInt32(sv, &in->keyFrameCount);

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_dataSetName", sv);
	pack_UA_String(sv, &in->dataSetName);

	av = newAV();
	hv_stores(hv, "DataSetWriterDataType_dataSetWriterProperties", newRV_noinc((SV*)av));
	av_extend(av, in->dataSetWriterPropertiesSize);
	for (i = 0; i < in->dataSetWriterPropertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->dataSetWriterProperties[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_transportSettings", sv);
	pack_UA_ExtensionObject(sv, &in->transportSettings);

	sv = newSV(0);
	hv_stores(hv, "DataSetWriterDataType_messageSettings", sv);
	pack_UA_ExtensionObject(sv, &in->messageSettings);

	return;
}

static void
unpack_UA_DataSetWriterDataType(UA_DataSetWriterDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataSetWriterDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataSetWriterDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "DataSetWriterDataType_enabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->enabled, *svp);

	svp = hv_fetchs(hv, "DataSetWriterDataType_dataSetWriterId", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->dataSetWriterId, *svp);

	svp = hv_fetchs(hv, "DataSetWriterDataType_dataSetFieldContentMask", 0);
	if (svp != NULL)
		unpack_UA_DataSetFieldContentMask(&out->dataSetFieldContentMask, *svp);

	svp = hv_fetchs(hv, "DataSetWriterDataType_keyFrameCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->keyFrameCount, *svp);

	svp = hv_fetchs(hv, "DataSetWriterDataType_dataSetName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->dataSetName, *svp);

	svp = hv_fetchs(hv, "DataSetWriterDataType_dataSetWriterProperties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetWriterDataType_dataSetWriterProperties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataSetWriterProperties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->dataSetWriterProperties == NULL)
			CROAKE("UA_Array_new");
		out->dataSetWriterPropertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->dataSetWriterProperties[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetWriterDataType_transportSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->transportSettings, *svp);

	svp = hv_fetchs(hv, "DataSetWriterDataType_messageSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->messageSettings, *svp);

	return;
}
#endif

/* NetworkAddressDataType */
#ifdef UA_TYPES_NETWORKADDRESSDATATYPE
static void pack_UA_NetworkAddressDataType(SV *out, const UA_NetworkAddressDataType *in);
static void unpack_UA_NetworkAddressDataType(UA_NetworkAddressDataType *out, SV *in);

static void
pack_UA_NetworkAddressDataType(SV *out, const UA_NetworkAddressDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NetworkAddressDataType_networkInterface", sv);
	pack_UA_String(sv, &in->networkInterface);

	return;
}

static void
unpack_UA_NetworkAddressDataType(UA_NetworkAddressDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NetworkAddressDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NetworkAddressDataType_networkInterface", 0);
	if (svp != NULL)
		unpack_UA_String(&out->networkInterface, *svp);

	return;
}
#endif

/* NetworkAddressUrlDataType */
#ifdef UA_TYPES_NETWORKADDRESSURLDATATYPE
static void pack_UA_NetworkAddressUrlDataType(SV *out, const UA_NetworkAddressUrlDataType *in);
static void unpack_UA_NetworkAddressUrlDataType(UA_NetworkAddressUrlDataType *out, SV *in);

static void
pack_UA_NetworkAddressUrlDataType(SV *out, const UA_NetworkAddressUrlDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NetworkAddressUrlDataType_networkInterface", sv);
	pack_UA_String(sv, &in->networkInterface);

	sv = newSV(0);
	hv_stores(hv, "NetworkAddressUrlDataType_url", sv);
	pack_UA_String(sv, &in->url);

	return;
}

static void
unpack_UA_NetworkAddressUrlDataType(UA_NetworkAddressUrlDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NetworkAddressUrlDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NetworkAddressUrlDataType_networkInterface", 0);
	if (svp != NULL)
		unpack_UA_String(&out->networkInterface, *svp);

	svp = hv_fetchs(hv, "NetworkAddressUrlDataType_url", 0);
	if (svp != NULL)
		unpack_UA_String(&out->url, *svp);

	return;
}
#endif

/* OverrideValueHandling */
#ifdef UA_TYPES_OVERRIDEVALUEHANDLING
static void pack_UA_OverrideValueHandling(SV *out, const UA_OverrideValueHandling *in);
static void unpack_UA_OverrideValueHandling(UA_OverrideValueHandling *out, SV *in);

static void
pack_UA_OverrideValueHandling(SV *out, const UA_OverrideValueHandling *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_OverrideValueHandling(UA_OverrideValueHandling *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* DataSetOrderingType */
#ifdef UA_TYPES_DATASETORDERINGTYPE
static void pack_UA_DataSetOrderingType(SV *out, const UA_DataSetOrderingType *in);
static void unpack_UA_DataSetOrderingType(UA_DataSetOrderingType *out, SV *in);

static void
pack_UA_DataSetOrderingType(SV *out, const UA_DataSetOrderingType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_DataSetOrderingType(UA_DataSetOrderingType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* UadpNetworkMessageContentMask */
#ifdef UA_TYPES_UADPNETWORKMESSAGECONTENTMASK
static void pack_UA_UadpNetworkMessageContentMask(SV *out, const UA_UadpNetworkMessageContentMask *in);
static void unpack_UA_UadpNetworkMessageContentMask(UA_UadpNetworkMessageContentMask *out, SV *in);

static void
pack_UA_UadpNetworkMessageContentMask(SV *out, const UA_UadpNetworkMessageContentMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_UadpNetworkMessageContentMask(UA_UadpNetworkMessageContentMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* UadpWriterGroupMessageDataType */
#ifdef UA_TYPES_UADPWRITERGROUPMESSAGEDATATYPE
static void pack_UA_UadpWriterGroupMessageDataType(SV *out, const UA_UadpWriterGroupMessageDataType *in);
static void unpack_UA_UadpWriterGroupMessageDataType(UA_UadpWriterGroupMessageDataType *out, SV *in);

static void
pack_UA_UadpWriterGroupMessageDataType(SV *out, const UA_UadpWriterGroupMessageDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UadpWriterGroupMessageDataType_groupVersion", sv);
	pack_UA_UInt32(sv, &in->groupVersion);

	sv = newSV(0);
	hv_stores(hv, "UadpWriterGroupMessageDataType_dataSetOrdering", sv);
	pack_UA_DataSetOrderingType(sv, &in->dataSetOrdering);

	sv = newSV(0);
	hv_stores(hv, "UadpWriterGroupMessageDataType_networkMessageContentMask", sv);
	pack_UA_UadpNetworkMessageContentMask(sv, &in->networkMessageContentMask);

	sv = newSV(0);
	hv_stores(hv, "UadpWriterGroupMessageDataType_samplingOffset", sv);
	pack_UA_Double(sv, &in->samplingOffset);

	av = newAV();
	hv_stores(hv, "UadpWriterGroupMessageDataType_publishingOffset", newRV_noinc((SV*)av));
	av_extend(av, in->publishingOffsetSize);
	for (i = 0; i < in->publishingOffsetSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Double(sv, &in->publishingOffset[i]);
	}

	return;
}

static void
unpack_UA_UadpWriterGroupMessageDataType(UA_UadpWriterGroupMessageDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UadpWriterGroupMessageDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UadpWriterGroupMessageDataType_groupVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->groupVersion, *svp);

	svp = hv_fetchs(hv, "UadpWriterGroupMessageDataType_dataSetOrdering", 0);
	if (svp != NULL)
		unpack_UA_DataSetOrderingType(&out->dataSetOrdering, *svp);

	svp = hv_fetchs(hv, "UadpWriterGroupMessageDataType_networkMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_UadpNetworkMessageContentMask(&out->networkMessageContentMask, *svp);

	svp = hv_fetchs(hv, "UadpWriterGroupMessageDataType_samplingOffset", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->samplingOffset, *svp);

	svp = hv_fetchs(hv, "UadpWriterGroupMessageDataType_publishingOffset", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UadpWriterGroupMessageDataType_publishingOffset");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->publishingOffset = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DOUBLE]);
		if (out->publishingOffset == NULL)
			CROAKE("UA_Array_new");
		out->publishingOffsetSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Double(&out->publishingOffset[i], *svp);
		}
	}

	return;
}
#endif

/* UadpDataSetMessageContentMask */
#ifdef UA_TYPES_UADPDATASETMESSAGECONTENTMASK
static void pack_UA_UadpDataSetMessageContentMask(SV *out, const UA_UadpDataSetMessageContentMask *in);
static void unpack_UA_UadpDataSetMessageContentMask(UA_UadpDataSetMessageContentMask *out, SV *in);

static void
pack_UA_UadpDataSetMessageContentMask(SV *out, const UA_UadpDataSetMessageContentMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_UadpDataSetMessageContentMask(UA_UadpDataSetMessageContentMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* UadpDataSetWriterMessageDataType */
#ifdef UA_TYPES_UADPDATASETWRITERMESSAGEDATATYPE
static void pack_UA_UadpDataSetWriterMessageDataType(SV *out, const UA_UadpDataSetWriterMessageDataType *in);
static void unpack_UA_UadpDataSetWriterMessageDataType(UA_UadpDataSetWriterMessageDataType *out, SV *in);

static void
pack_UA_UadpDataSetWriterMessageDataType(SV *out, const UA_UadpDataSetWriterMessageDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetWriterMessageDataType_dataSetMessageContentMask", sv);
	pack_UA_UadpDataSetMessageContentMask(sv, &in->dataSetMessageContentMask);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetWriterMessageDataType_configuredSize", sv);
	pack_UA_UInt16(sv, &in->configuredSize);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetWriterMessageDataType_networkMessageNumber", sv);
	pack_UA_UInt16(sv, &in->networkMessageNumber);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetWriterMessageDataType_dataSetOffset", sv);
	pack_UA_UInt16(sv, &in->dataSetOffset);

	return;
}

static void
unpack_UA_UadpDataSetWriterMessageDataType(UA_UadpDataSetWriterMessageDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UadpDataSetWriterMessageDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UadpDataSetWriterMessageDataType_dataSetMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_UadpDataSetMessageContentMask(&out->dataSetMessageContentMask, *svp);

	svp = hv_fetchs(hv, "UadpDataSetWriterMessageDataType_configuredSize", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->configuredSize, *svp);

	svp = hv_fetchs(hv, "UadpDataSetWriterMessageDataType_networkMessageNumber", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->networkMessageNumber, *svp);

	svp = hv_fetchs(hv, "UadpDataSetWriterMessageDataType_dataSetOffset", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->dataSetOffset, *svp);

	return;
}
#endif

/* UadpDataSetReaderMessageDataType */
#ifdef UA_TYPES_UADPDATASETREADERMESSAGEDATATYPE
static void pack_UA_UadpDataSetReaderMessageDataType(SV *out, const UA_UadpDataSetReaderMessageDataType *in);
static void unpack_UA_UadpDataSetReaderMessageDataType(UA_UadpDataSetReaderMessageDataType *out, SV *in);

static void
pack_UA_UadpDataSetReaderMessageDataType(SV *out, const UA_UadpDataSetReaderMessageDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_groupVersion", sv);
	pack_UA_UInt32(sv, &in->groupVersion);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_networkMessageNumber", sv);
	pack_UA_UInt16(sv, &in->networkMessageNumber);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_dataSetOffset", sv);
	pack_UA_UInt16(sv, &in->dataSetOffset);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_dataSetClassId", sv);
	pack_UA_Guid(sv, &in->dataSetClassId);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_networkMessageContentMask", sv);
	pack_UA_UadpNetworkMessageContentMask(sv, &in->networkMessageContentMask);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_dataSetMessageContentMask", sv);
	pack_UA_UadpDataSetMessageContentMask(sv, &in->dataSetMessageContentMask);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_publishingInterval", sv);
	pack_UA_Double(sv, &in->publishingInterval);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_receiveOffset", sv);
	pack_UA_Double(sv, &in->receiveOffset);

	sv = newSV(0);
	hv_stores(hv, "UadpDataSetReaderMessageDataType_processingOffset", sv);
	pack_UA_Double(sv, &in->processingOffset);

	return;
}

static void
unpack_UA_UadpDataSetReaderMessageDataType(UA_UadpDataSetReaderMessageDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UadpDataSetReaderMessageDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_groupVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->groupVersion, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_networkMessageNumber", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->networkMessageNumber, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_dataSetOffset", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->dataSetOffset, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_dataSetClassId", 0);
	if (svp != NULL)
		unpack_UA_Guid(&out->dataSetClassId, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_networkMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_UadpNetworkMessageContentMask(&out->networkMessageContentMask, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_dataSetMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_UadpDataSetMessageContentMask(&out->dataSetMessageContentMask, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_publishingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->publishingInterval, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_receiveOffset", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->receiveOffset, *svp);

	svp = hv_fetchs(hv, "UadpDataSetReaderMessageDataType_processingOffset", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->processingOffset, *svp);

	return;
}
#endif

/* JsonNetworkMessageContentMask */
#ifdef UA_TYPES_JSONNETWORKMESSAGECONTENTMASK
static void pack_UA_JsonNetworkMessageContentMask(SV *out, const UA_JsonNetworkMessageContentMask *in);
static void unpack_UA_JsonNetworkMessageContentMask(UA_JsonNetworkMessageContentMask *out, SV *in);

static void
pack_UA_JsonNetworkMessageContentMask(SV *out, const UA_JsonNetworkMessageContentMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_JsonNetworkMessageContentMask(UA_JsonNetworkMessageContentMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* JsonWriterGroupMessageDataType */
#ifdef UA_TYPES_JSONWRITERGROUPMESSAGEDATATYPE
static void pack_UA_JsonWriterGroupMessageDataType(SV *out, const UA_JsonWriterGroupMessageDataType *in);
static void unpack_UA_JsonWriterGroupMessageDataType(UA_JsonWriterGroupMessageDataType *out, SV *in);

static void
pack_UA_JsonWriterGroupMessageDataType(SV *out, const UA_JsonWriterGroupMessageDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "JsonWriterGroupMessageDataType_networkMessageContentMask", sv);
	pack_UA_JsonNetworkMessageContentMask(sv, &in->networkMessageContentMask);

	return;
}

static void
unpack_UA_JsonWriterGroupMessageDataType(UA_JsonWriterGroupMessageDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_JsonWriterGroupMessageDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "JsonWriterGroupMessageDataType_networkMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_JsonNetworkMessageContentMask(&out->networkMessageContentMask, *svp);

	return;
}
#endif

/* JsonDataSetMessageContentMask */
#ifdef UA_TYPES_JSONDATASETMESSAGECONTENTMASK
static void pack_UA_JsonDataSetMessageContentMask(SV *out, const UA_JsonDataSetMessageContentMask *in);
static void unpack_UA_JsonDataSetMessageContentMask(UA_JsonDataSetMessageContentMask *out, SV *in);

static void
pack_UA_JsonDataSetMessageContentMask(SV *out, const UA_JsonDataSetMessageContentMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_JsonDataSetMessageContentMask(UA_JsonDataSetMessageContentMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* JsonDataSetWriterMessageDataType */
#ifdef UA_TYPES_JSONDATASETWRITERMESSAGEDATATYPE
static void pack_UA_JsonDataSetWriterMessageDataType(SV *out, const UA_JsonDataSetWriterMessageDataType *in);
static void unpack_UA_JsonDataSetWriterMessageDataType(UA_JsonDataSetWriterMessageDataType *out, SV *in);

static void
pack_UA_JsonDataSetWriterMessageDataType(SV *out, const UA_JsonDataSetWriterMessageDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "JsonDataSetWriterMessageDataType_dataSetMessageContentMask", sv);
	pack_UA_JsonDataSetMessageContentMask(sv, &in->dataSetMessageContentMask);

	return;
}

static void
unpack_UA_JsonDataSetWriterMessageDataType(UA_JsonDataSetWriterMessageDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_JsonDataSetWriterMessageDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "JsonDataSetWriterMessageDataType_dataSetMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_JsonDataSetMessageContentMask(&out->dataSetMessageContentMask, *svp);

	return;
}
#endif

/* JsonDataSetReaderMessageDataType */
#ifdef UA_TYPES_JSONDATASETREADERMESSAGEDATATYPE
static void pack_UA_JsonDataSetReaderMessageDataType(SV *out, const UA_JsonDataSetReaderMessageDataType *in);
static void unpack_UA_JsonDataSetReaderMessageDataType(UA_JsonDataSetReaderMessageDataType *out, SV *in);

static void
pack_UA_JsonDataSetReaderMessageDataType(SV *out, const UA_JsonDataSetReaderMessageDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "JsonDataSetReaderMessageDataType_networkMessageContentMask", sv);
	pack_UA_JsonNetworkMessageContentMask(sv, &in->networkMessageContentMask);

	sv = newSV(0);
	hv_stores(hv, "JsonDataSetReaderMessageDataType_dataSetMessageContentMask", sv);
	pack_UA_JsonDataSetMessageContentMask(sv, &in->dataSetMessageContentMask);

	return;
}

static void
unpack_UA_JsonDataSetReaderMessageDataType(UA_JsonDataSetReaderMessageDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_JsonDataSetReaderMessageDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "JsonDataSetReaderMessageDataType_networkMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_JsonNetworkMessageContentMask(&out->networkMessageContentMask, *svp);

	svp = hv_fetchs(hv, "JsonDataSetReaderMessageDataType_dataSetMessageContentMask", 0);
	if (svp != NULL)
		unpack_UA_JsonDataSetMessageContentMask(&out->dataSetMessageContentMask, *svp);

	return;
}
#endif

/* DatagramConnectionTransportDataType */
#ifdef UA_TYPES_DATAGRAMCONNECTIONTRANSPORTDATATYPE
static void pack_UA_DatagramConnectionTransportDataType(SV *out, const UA_DatagramConnectionTransportDataType *in);
static void unpack_UA_DatagramConnectionTransportDataType(UA_DatagramConnectionTransportDataType *out, SV *in);

static void
pack_UA_DatagramConnectionTransportDataType(SV *out, const UA_DatagramConnectionTransportDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DatagramConnectionTransportDataType_discoveryAddress", sv);
	pack_UA_ExtensionObject(sv, &in->discoveryAddress);

	return;
}

static void
unpack_UA_DatagramConnectionTransportDataType(UA_DatagramConnectionTransportDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DatagramConnectionTransportDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DatagramConnectionTransportDataType_discoveryAddress", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->discoveryAddress, *svp);

	return;
}
#endif

/* DatagramWriterGroupTransportDataType */
#ifdef UA_TYPES_DATAGRAMWRITERGROUPTRANSPORTDATATYPE
static void pack_UA_DatagramWriterGroupTransportDataType(SV *out, const UA_DatagramWriterGroupTransportDataType *in);
static void unpack_UA_DatagramWriterGroupTransportDataType(UA_DatagramWriterGroupTransportDataType *out, SV *in);

static void
pack_UA_DatagramWriterGroupTransportDataType(SV *out, const UA_DatagramWriterGroupTransportDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DatagramWriterGroupTransportDataType_messageRepeatCount", sv);
	pack_UA_Byte(sv, &in->messageRepeatCount);

	sv = newSV(0);
	hv_stores(hv, "DatagramWriterGroupTransportDataType_messageRepeatDelay", sv);
	pack_UA_Double(sv, &in->messageRepeatDelay);

	return;
}

static void
unpack_UA_DatagramWriterGroupTransportDataType(UA_DatagramWriterGroupTransportDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DatagramWriterGroupTransportDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DatagramWriterGroupTransportDataType_messageRepeatCount", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->messageRepeatCount, *svp);

	svp = hv_fetchs(hv, "DatagramWriterGroupTransportDataType_messageRepeatDelay", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->messageRepeatDelay, *svp);

	return;
}
#endif

/* BrokerConnectionTransportDataType */
#ifdef UA_TYPES_BROKERCONNECTIONTRANSPORTDATATYPE
static void pack_UA_BrokerConnectionTransportDataType(SV *out, const UA_BrokerConnectionTransportDataType *in);
static void unpack_UA_BrokerConnectionTransportDataType(UA_BrokerConnectionTransportDataType *out, SV *in);

static void
pack_UA_BrokerConnectionTransportDataType(SV *out, const UA_BrokerConnectionTransportDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrokerConnectionTransportDataType_resourceUri", sv);
	pack_UA_String(sv, &in->resourceUri);

	sv = newSV(0);
	hv_stores(hv, "BrokerConnectionTransportDataType_authenticationProfileUri", sv);
	pack_UA_String(sv, &in->authenticationProfileUri);

	return;
}

static void
unpack_UA_BrokerConnectionTransportDataType(UA_BrokerConnectionTransportDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrokerConnectionTransportDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrokerConnectionTransportDataType_resourceUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->resourceUri, *svp);

	svp = hv_fetchs(hv, "BrokerConnectionTransportDataType_authenticationProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->authenticationProfileUri, *svp);

	return;
}
#endif

/* BrokerTransportQualityOfService */
#ifdef UA_TYPES_BROKERTRANSPORTQUALITYOFSERVICE
static void pack_UA_BrokerTransportQualityOfService(SV *out, const UA_BrokerTransportQualityOfService *in);
static void unpack_UA_BrokerTransportQualityOfService(UA_BrokerTransportQualityOfService *out, SV *in);

static void
pack_UA_BrokerTransportQualityOfService(SV *out, const UA_BrokerTransportQualityOfService *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_BrokerTransportQualityOfService(UA_BrokerTransportQualityOfService *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* BrokerWriterGroupTransportDataType */
#ifdef UA_TYPES_BROKERWRITERGROUPTRANSPORTDATATYPE
static void pack_UA_BrokerWriterGroupTransportDataType(SV *out, const UA_BrokerWriterGroupTransportDataType *in);
static void unpack_UA_BrokerWriterGroupTransportDataType(UA_BrokerWriterGroupTransportDataType *out, SV *in);

static void
pack_UA_BrokerWriterGroupTransportDataType(SV *out, const UA_BrokerWriterGroupTransportDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrokerWriterGroupTransportDataType_queueName", sv);
	pack_UA_String(sv, &in->queueName);

	sv = newSV(0);
	hv_stores(hv, "BrokerWriterGroupTransportDataType_resourceUri", sv);
	pack_UA_String(sv, &in->resourceUri);

	sv = newSV(0);
	hv_stores(hv, "BrokerWriterGroupTransportDataType_authenticationProfileUri", sv);
	pack_UA_String(sv, &in->authenticationProfileUri);

	sv = newSV(0);
	hv_stores(hv, "BrokerWriterGroupTransportDataType_requestedDeliveryGuarantee", sv);
	pack_UA_BrokerTransportQualityOfService(sv, &in->requestedDeliveryGuarantee);

	return;
}

static void
unpack_UA_BrokerWriterGroupTransportDataType(UA_BrokerWriterGroupTransportDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrokerWriterGroupTransportDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrokerWriterGroupTransportDataType_queueName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->queueName, *svp);

	svp = hv_fetchs(hv, "BrokerWriterGroupTransportDataType_resourceUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->resourceUri, *svp);

	svp = hv_fetchs(hv, "BrokerWriterGroupTransportDataType_authenticationProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->authenticationProfileUri, *svp);

	svp = hv_fetchs(hv, "BrokerWriterGroupTransportDataType_requestedDeliveryGuarantee", 0);
	if (svp != NULL)
		unpack_UA_BrokerTransportQualityOfService(&out->requestedDeliveryGuarantee, *svp);

	return;
}
#endif

/* BrokerDataSetWriterTransportDataType */
#ifdef UA_TYPES_BROKERDATASETWRITERTRANSPORTDATATYPE
static void pack_UA_BrokerDataSetWriterTransportDataType(SV *out, const UA_BrokerDataSetWriterTransportDataType *in);
static void unpack_UA_BrokerDataSetWriterTransportDataType(UA_BrokerDataSetWriterTransportDataType *out, SV *in);

static void
pack_UA_BrokerDataSetWriterTransportDataType(SV *out, const UA_BrokerDataSetWriterTransportDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetWriterTransportDataType_queueName", sv);
	pack_UA_String(sv, &in->queueName);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetWriterTransportDataType_resourceUri", sv);
	pack_UA_String(sv, &in->resourceUri);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetWriterTransportDataType_authenticationProfileUri", sv);
	pack_UA_String(sv, &in->authenticationProfileUri);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetWriterTransportDataType_requestedDeliveryGuarantee", sv);
	pack_UA_BrokerTransportQualityOfService(sv, &in->requestedDeliveryGuarantee);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetWriterTransportDataType_metaDataQueueName", sv);
	pack_UA_String(sv, &in->metaDataQueueName);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetWriterTransportDataType_metaDataUpdateTime", sv);
	pack_UA_Double(sv, &in->metaDataUpdateTime);

	return;
}

static void
unpack_UA_BrokerDataSetWriterTransportDataType(UA_BrokerDataSetWriterTransportDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrokerDataSetWriterTransportDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrokerDataSetWriterTransportDataType_queueName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->queueName, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetWriterTransportDataType_resourceUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->resourceUri, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetWriterTransportDataType_authenticationProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->authenticationProfileUri, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetWriterTransportDataType_requestedDeliveryGuarantee", 0);
	if (svp != NULL)
		unpack_UA_BrokerTransportQualityOfService(&out->requestedDeliveryGuarantee, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetWriterTransportDataType_metaDataQueueName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->metaDataQueueName, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetWriterTransportDataType_metaDataUpdateTime", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->metaDataUpdateTime, *svp);

	return;
}
#endif

/* BrokerDataSetReaderTransportDataType */
#ifdef UA_TYPES_BROKERDATASETREADERTRANSPORTDATATYPE
static void pack_UA_BrokerDataSetReaderTransportDataType(SV *out, const UA_BrokerDataSetReaderTransportDataType *in);
static void unpack_UA_BrokerDataSetReaderTransportDataType(UA_BrokerDataSetReaderTransportDataType *out, SV *in);

static void
pack_UA_BrokerDataSetReaderTransportDataType(SV *out, const UA_BrokerDataSetReaderTransportDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetReaderTransportDataType_queueName", sv);
	pack_UA_String(sv, &in->queueName);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetReaderTransportDataType_resourceUri", sv);
	pack_UA_String(sv, &in->resourceUri);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetReaderTransportDataType_authenticationProfileUri", sv);
	pack_UA_String(sv, &in->authenticationProfileUri);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetReaderTransportDataType_requestedDeliveryGuarantee", sv);
	pack_UA_BrokerTransportQualityOfService(sv, &in->requestedDeliveryGuarantee);

	sv = newSV(0);
	hv_stores(hv, "BrokerDataSetReaderTransportDataType_metaDataQueueName", sv);
	pack_UA_String(sv, &in->metaDataQueueName);

	return;
}

static void
unpack_UA_BrokerDataSetReaderTransportDataType(UA_BrokerDataSetReaderTransportDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrokerDataSetReaderTransportDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrokerDataSetReaderTransportDataType_queueName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->queueName, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetReaderTransportDataType_resourceUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->resourceUri, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetReaderTransportDataType_authenticationProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->authenticationProfileUri, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetReaderTransportDataType_requestedDeliveryGuarantee", 0);
	if (svp != NULL)
		unpack_UA_BrokerTransportQualityOfService(&out->requestedDeliveryGuarantee, *svp);

	svp = hv_fetchs(hv, "BrokerDataSetReaderTransportDataType_metaDataQueueName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->metaDataQueueName, *svp);

	return;
}
#endif

/* DiagnosticsLevel */
#ifdef UA_TYPES_DIAGNOSTICSLEVEL
static void pack_UA_DiagnosticsLevel(SV *out, const UA_DiagnosticsLevel *in);
static void unpack_UA_DiagnosticsLevel(UA_DiagnosticsLevel *out, SV *in);

static void
pack_UA_DiagnosticsLevel(SV *out, const UA_DiagnosticsLevel *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_DiagnosticsLevel(UA_DiagnosticsLevel *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* PubSubDiagnosticsCounterClassification */
#ifdef UA_TYPES_PUBSUBDIAGNOSTICSCOUNTERCLASSIFICATION
static void pack_UA_PubSubDiagnosticsCounterClassification(SV *out, const UA_PubSubDiagnosticsCounterClassification *in);
static void unpack_UA_PubSubDiagnosticsCounterClassification(UA_PubSubDiagnosticsCounterClassification *out, SV *in);

static void
pack_UA_PubSubDiagnosticsCounterClassification(SV *out, const UA_PubSubDiagnosticsCounterClassification *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_PubSubDiagnosticsCounterClassification(UA_PubSubDiagnosticsCounterClassification *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* AliasNameDataType */
#ifdef UA_TYPES_ALIASNAMEDATATYPE
static void pack_UA_AliasNameDataType(SV *out, const UA_AliasNameDataType *in);
static void unpack_UA_AliasNameDataType(UA_AliasNameDataType *out, SV *in);

static void
pack_UA_AliasNameDataType(SV *out, const UA_AliasNameDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AliasNameDataType_aliasName", sv);
	pack_UA_QualifiedName(sv, &in->aliasName);

	av = newAV();
	hv_stores(hv, "AliasNameDataType_referencedNodes", newRV_noinc((SV*)av));
	av_extend(av, in->referencedNodesSize);
	for (i = 0; i < in->referencedNodesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ExpandedNodeId(sv, &in->referencedNodes[i]);
	}

	return;
}

static void
unpack_UA_AliasNameDataType(UA_AliasNameDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AliasNameDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AliasNameDataType_aliasName", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->aliasName, *svp);

	svp = hv_fetchs(hv, "AliasNameDataType_referencedNodes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AliasNameDataType_referencedNodes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->referencedNodes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXPANDEDNODEID]);
		if (out->referencedNodes == NULL)
			CROAKE("UA_Array_new");
		out->referencedNodesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ExpandedNodeId(&out->referencedNodes[i], *svp);
		}
	}

	return;
}
#endif

/* Duplex */
#ifdef UA_TYPES_DUPLEX
static void pack_UA_Duplex(SV *out, const UA_Duplex *in);
static void unpack_UA_Duplex(UA_Duplex *out, SV *in);

static void
pack_UA_Duplex(SV *out, const UA_Duplex *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_Duplex(UA_Duplex *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* InterfaceAdminStatus */
#ifdef UA_TYPES_INTERFACEADMINSTATUS
static void pack_UA_InterfaceAdminStatus(SV *out, const UA_InterfaceAdminStatus *in);
static void unpack_UA_InterfaceAdminStatus(UA_InterfaceAdminStatus *out, SV *in);

static void
pack_UA_InterfaceAdminStatus(SV *out, const UA_InterfaceAdminStatus *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_InterfaceAdminStatus(UA_InterfaceAdminStatus *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* InterfaceOperStatus */
#ifdef UA_TYPES_INTERFACEOPERSTATUS
static void pack_UA_InterfaceOperStatus(SV *out, const UA_InterfaceOperStatus *in);
static void unpack_UA_InterfaceOperStatus(UA_InterfaceOperStatus *out, SV *in);

static void
pack_UA_InterfaceOperStatus(SV *out, const UA_InterfaceOperStatus *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_InterfaceOperStatus(UA_InterfaceOperStatus *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* NegotiationStatus */
#ifdef UA_TYPES_NEGOTIATIONSTATUS
static void pack_UA_NegotiationStatus(SV *out, const UA_NegotiationStatus *in);
static void unpack_UA_NegotiationStatus(UA_NegotiationStatus *out, SV *in);

static void
pack_UA_NegotiationStatus(SV *out, const UA_NegotiationStatus *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_NegotiationStatus(UA_NegotiationStatus *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* TsnFailureCode */
#ifdef UA_TYPES_TSNFAILURECODE
static void pack_UA_TsnFailureCode(SV *out, const UA_TsnFailureCode *in);
static void unpack_UA_TsnFailureCode(UA_TsnFailureCode *out, SV *in);

static void
pack_UA_TsnFailureCode(SV *out, const UA_TsnFailureCode *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_TsnFailureCode(UA_TsnFailureCode *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* TsnStreamState */
#ifdef UA_TYPES_TSNSTREAMSTATE
static void pack_UA_TsnStreamState(SV *out, const UA_TsnStreamState *in);
static void unpack_UA_TsnStreamState(UA_TsnStreamState *out, SV *in);

static void
pack_UA_TsnStreamState(SV *out, const UA_TsnStreamState *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_TsnStreamState(UA_TsnStreamState *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* TsnTalkerStatus */
#ifdef UA_TYPES_TSNTALKERSTATUS
static void pack_UA_TsnTalkerStatus(SV *out, const UA_TsnTalkerStatus *in);
static void unpack_UA_TsnTalkerStatus(UA_TsnTalkerStatus *out, SV *in);

static void
pack_UA_TsnTalkerStatus(SV *out, const UA_TsnTalkerStatus *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_TsnTalkerStatus(UA_TsnTalkerStatus *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* TsnListenerStatus */
#ifdef UA_TYPES_TSNLISTENERSTATUS
static void pack_UA_TsnListenerStatus(SV *out, const UA_TsnListenerStatus *in);
static void unpack_UA_TsnListenerStatus(UA_TsnListenerStatus *out, SV *in);

static void
pack_UA_TsnListenerStatus(SV *out, const UA_TsnListenerStatus *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_TsnListenerStatus(UA_TsnListenerStatus *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* UnsignedRationalNumber */
#ifdef UA_TYPES_UNSIGNEDRATIONALNUMBER
static void pack_UA_UnsignedRationalNumber(SV *out, const UA_UnsignedRationalNumber *in);
static void unpack_UA_UnsignedRationalNumber(UA_UnsignedRationalNumber *out, SV *in);

static void
pack_UA_UnsignedRationalNumber(SV *out, const UA_UnsignedRationalNumber *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UnsignedRationalNumber_numerator", sv);
	pack_UA_UInt32(sv, &in->numerator);

	sv = newSV(0);
	hv_stores(hv, "UnsignedRationalNumber_denominator", sv);
	pack_UA_UInt32(sv, &in->denominator);

	return;
}

static void
unpack_UA_UnsignedRationalNumber(UA_UnsignedRationalNumber *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UnsignedRationalNumber_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UnsignedRationalNumber_numerator", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->numerator, *svp);

	svp = hv_fetchs(hv, "UnsignedRationalNumber_denominator", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->denominator, *svp);

	return;
}
#endif

/* IdType */
#ifdef UA_TYPES_IDTYPE
static void pack_UA_IdType(SV *out, const UA_IdType *in);
static void unpack_UA_IdType(UA_IdType *out, SV *in);

static void
pack_UA_IdType(SV *out, const UA_IdType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_IdType(UA_IdType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* NodeClass */
#ifdef UA_TYPES_NODECLASS
static void pack_UA_NodeClass(SV *out, const UA_NodeClass *in);
static void unpack_UA_NodeClass(UA_NodeClass *out, SV *in);

static void
pack_UA_NodeClass(SV *out, const UA_NodeClass *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_NodeClass(UA_NodeClass *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* PermissionType */
#ifdef UA_TYPES_PERMISSIONTYPE
static void pack_UA_PermissionType(SV *out, const UA_PermissionType *in);
static void unpack_UA_PermissionType(UA_PermissionType *out, SV *in);

static void
pack_UA_PermissionType(SV *out, const UA_PermissionType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_PermissionType(UA_PermissionType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* AccessLevelType */
#ifdef UA_TYPES_ACCESSLEVELTYPE
static void pack_UA_AccessLevelType(SV *out, const UA_AccessLevelType *in);
static void unpack_UA_AccessLevelType(UA_AccessLevelType *out, SV *in);

static void
pack_UA_AccessLevelType(SV *out, const UA_AccessLevelType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_AccessLevelType(UA_AccessLevelType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* AccessLevelExType */
#ifdef UA_TYPES_ACCESSLEVELEXTYPE
static void pack_UA_AccessLevelExType(SV *out, const UA_AccessLevelExType *in);
static void unpack_UA_AccessLevelExType(UA_AccessLevelExType *out, SV *in);

static void
pack_UA_AccessLevelExType(SV *out, const UA_AccessLevelExType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_AccessLevelExType(UA_AccessLevelExType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* EventNotifierType */
#ifdef UA_TYPES_EVENTNOTIFIERTYPE
static void pack_UA_EventNotifierType(SV *out, const UA_EventNotifierType *in);
static void unpack_UA_EventNotifierType(UA_EventNotifierType *out, SV *in);

static void
pack_UA_EventNotifierType(SV *out, const UA_EventNotifierType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_EventNotifierType(UA_EventNotifierType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* AccessRestrictionType */
#ifdef UA_TYPES_ACCESSRESTRICTIONTYPE
static void pack_UA_AccessRestrictionType(SV *out, const UA_AccessRestrictionType *in);
static void unpack_UA_AccessRestrictionType(UA_AccessRestrictionType *out, SV *in);

static void
pack_UA_AccessRestrictionType(SV *out, const UA_AccessRestrictionType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_AccessRestrictionType(UA_AccessRestrictionType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* RolePermissionType */
#ifdef UA_TYPES_ROLEPERMISSIONTYPE
static void pack_UA_RolePermissionType(SV *out, const UA_RolePermissionType *in);
static void unpack_UA_RolePermissionType(UA_RolePermissionType *out, SV *in);

static void
pack_UA_RolePermissionType(SV *out, const UA_RolePermissionType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RolePermissionType_roleId", sv);
	pack_UA_NodeId(sv, &in->roleId);

	sv = newSV(0);
	hv_stores(hv, "RolePermissionType_permissions", sv);
	pack_UA_PermissionType(sv, &in->permissions);

	return;
}

static void
unpack_UA_RolePermissionType(UA_RolePermissionType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RolePermissionType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RolePermissionType_roleId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->roleId, *svp);

	svp = hv_fetchs(hv, "RolePermissionType_permissions", 0);
	if (svp != NULL)
		unpack_UA_PermissionType(&out->permissions, *svp);

	return;
}
#endif

/* StructureType */
#ifdef UA_TYPES_STRUCTURETYPE
static void pack_UA_StructureType(SV *out, const UA_StructureType *in);
static void unpack_UA_StructureType(UA_StructureType *out, SV *in);

static void
pack_UA_StructureType(SV *out, const UA_StructureType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_StructureType(UA_StructureType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* StructureField */
#ifdef UA_TYPES_STRUCTUREFIELD
static void pack_UA_StructureField(SV *out, const UA_StructureField *in);
static void unpack_UA_StructureField(UA_StructureField *out, SV *in);

static void
pack_UA_StructureField(SV *out, const UA_StructureField *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "StructureField_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "StructureField_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "StructureField_dataType", sv);
	pack_UA_NodeId(sv, &in->dataType);

	sv = newSV(0);
	hv_stores(hv, "StructureField_valueRank", sv);
	pack_UA_Int32(sv, &in->valueRank);

	av = newAV();
	hv_stores(hv, "StructureField_arrayDimensions", newRV_noinc((SV*)av));
	av_extend(av, in->arrayDimensionsSize);
	for (i = 0; i < in->arrayDimensionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->arrayDimensions[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "StructureField_maxStringLength", sv);
	pack_UA_UInt32(sv, &in->maxStringLength);

	sv = newSV(0);
	hv_stores(hv, "StructureField_isOptional", sv);
	pack_UA_Boolean(sv, &in->isOptional);

	return;
}

static void
unpack_UA_StructureField(UA_StructureField *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_StructureField_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "StructureField_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "StructureField_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "StructureField_dataType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataType, *svp);

	svp = hv_fetchs(hv, "StructureField_valueRank", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->valueRank, *svp);

	svp = hv_fetchs(hv, "StructureField_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for StructureField_arrayDimensions");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->arrayDimensions == NULL)
			CROAKE("UA_Array_new");
		out->arrayDimensionsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->arrayDimensions[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "StructureField_maxStringLength", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxStringLength, *svp);

	svp = hv_fetchs(hv, "StructureField_isOptional", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isOptional, *svp);

	return;
}
#endif

/* StructureDefinition */
#ifdef UA_TYPES_STRUCTUREDEFINITION
static void pack_UA_StructureDefinition(SV *out, const UA_StructureDefinition *in);
static void unpack_UA_StructureDefinition(UA_StructureDefinition *out, SV *in);

static void
pack_UA_StructureDefinition(SV *out, const UA_StructureDefinition *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "StructureDefinition_defaultEncodingId", sv);
	pack_UA_NodeId(sv, &in->defaultEncodingId);

	sv = newSV(0);
	hv_stores(hv, "StructureDefinition_baseDataType", sv);
	pack_UA_NodeId(sv, &in->baseDataType);

	sv = newSV(0);
	hv_stores(hv, "StructureDefinition_structureType", sv);
	pack_UA_StructureType(sv, &in->structureType);

	av = newAV();
	hv_stores(hv, "StructureDefinition_fields", newRV_noinc((SV*)av));
	av_extend(av, in->fieldsSize);
	for (i = 0; i < in->fieldsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StructureField(sv, &in->fields[i]);
	}

	return;
}

static void
unpack_UA_StructureDefinition(UA_StructureDefinition *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_StructureDefinition_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "StructureDefinition_defaultEncodingId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->defaultEncodingId, *svp);

	svp = hv_fetchs(hv, "StructureDefinition_baseDataType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->baseDataType, *svp);

	svp = hv_fetchs(hv, "StructureDefinition_structureType", 0);
	if (svp != NULL)
		unpack_UA_StructureType(&out->structureType, *svp);

	svp = hv_fetchs(hv, "StructureDefinition_fields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for StructureDefinition_fields");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->fields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRUCTUREFIELD]);
		if (out->fields == NULL)
			CROAKE("UA_Array_new");
		out->fieldsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StructureField(&out->fields[i], *svp);
		}
	}

	return;
}
#endif

/* ReferenceNode */
#ifdef UA_TYPES_REFERENCENODE
static void pack_UA_ReferenceNode(SV *out, const UA_ReferenceNode *in);
static void unpack_UA_ReferenceNode(UA_ReferenceNode *out, SV *in);

static void
pack_UA_ReferenceNode(SV *out, const UA_ReferenceNode *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReferenceNode_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "ReferenceNode_isInverse", sv);
	pack_UA_Boolean(sv, &in->isInverse);

	sv = newSV(0);
	hv_stores(hv, "ReferenceNode_targetId", sv);
	pack_UA_ExpandedNodeId(sv, &in->targetId);

	return;
}

static void
unpack_UA_ReferenceNode(UA_ReferenceNode *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReferenceNode_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReferenceNode_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "ReferenceNode_isInverse", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isInverse, *svp);

	svp = hv_fetchs(hv, "ReferenceNode_targetId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->targetId, *svp);

	return;
}
#endif

/* Argument */
#ifdef UA_TYPES_ARGUMENT
static void pack_UA_Argument(SV *out, const UA_Argument *in);
static void unpack_UA_Argument(UA_Argument *out, SV *in);

static void
pack_UA_Argument(SV *out, const UA_Argument *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "Argument_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "Argument_dataType", sv);
	pack_UA_NodeId(sv, &in->dataType);

	sv = newSV(0);
	hv_stores(hv, "Argument_valueRank", sv);
	pack_UA_Int32(sv, &in->valueRank);

	av = newAV();
	hv_stores(hv, "Argument_arrayDimensions", newRV_noinc((SV*)av));
	av_extend(av, in->arrayDimensionsSize);
	for (i = 0; i < in->arrayDimensionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->arrayDimensions[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "Argument_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	return;
}

static void
unpack_UA_Argument(UA_Argument *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_Argument_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "Argument_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "Argument_dataType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataType, *svp);

	svp = hv_fetchs(hv, "Argument_valueRank", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->valueRank, *svp);

	svp = hv_fetchs(hv, "Argument_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for Argument_arrayDimensions");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->arrayDimensions == NULL)
			CROAKE("UA_Array_new");
		out->arrayDimensionsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->arrayDimensions[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "Argument_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	return;
}
#endif

/* EnumValueType */
#ifdef UA_TYPES_ENUMVALUETYPE
static void pack_UA_EnumValueType(SV *out, const UA_EnumValueType *in);
static void unpack_UA_EnumValueType(UA_EnumValueType *out, SV *in);

static void
pack_UA_EnumValueType(SV *out, const UA_EnumValueType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EnumValueType_value", sv);
	pack_UA_Int64(sv, &in->value);

	sv = newSV(0);
	hv_stores(hv, "EnumValueType_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "EnumValueType_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	return;
}

static void
unpack_UA_EnumValueType(UA_EnumValueType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EnumValueType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EnumValueType_value", 0);
	if (svp != NULL)
		unpack_UA_Int64(&out->value, *svp);

	svp = hv_fetchs(hv, "EnumValueType_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "EnumValueType_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	return;
}
#endif

/* EnumField */
#ifdef UA_TYPES_ENUMFIELD
static void pack_UA_EnumField(SV *out, const UA_EnumField *in);
static void unpack_UA_EnumField(UA_EnumField *out, SV *in);

static void
pack_UA_EnumField(SV *out, const UA_EnumField *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EnumField_value", sv);
	pack_UA_Int64(sv, &in->value);

	sv = newSV(0);
	hv_stores(hv, "EnumField_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "EnumField_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "EnumField_name", sv);
	pack_UA_String(sv, &in->name);

	return;
}

static void
unpack_UA_EnumField(UA_EnumField *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EnumField_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EnumField_value", 0);
	if (svp != NULL)
		unpack_UA_Int64(&out->value, *svp);

	svp = hv_fetchs(hv, "EnumField_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "EnumField_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "EnumField_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	return;
}
#endif

/* OptionSet */
#ifdef UA_TYPES_OPTIONSET
static void pack_UA_OptionSet(SV *out, const UA_OptionSet *in);
static void unpack_UA_OptionSet(UA_OptionSet *out, SV *in);

static void
pack_UA_OptionSet(SV *out, const UA_OptionSet *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "OptionSet_value", sv);
	pack_UA_ByteString(sv, &in->value);

	sv = newSV(0);
	hv_stores(hv, "OptionSet_validBits", sv);
	pack_UA_ByteString(sv, &in->validBits);

	return;
}

static void
unpack_UA_OptionSet(UA_OptionSet *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_OptionSet_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "OptionSet_value", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->value, *svp);

	svp = hv_fetchs(hv, "OptionSet_validBits", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->validBits, *svp);

	return;
}
#endif

/* NormalizedString */
#ifdef UA_TYPES_NORMALIZEDSTRING
static void pack_UA_NormalizedString(SV *out, const UA_NormalizedString *in);
static void unpack_UA_NormalizedString(UA_NormalizedString *out, SV *in);

static void
pack_UA_NormalizedString(SV *out, const UA_NormalizedString *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_NormalizedString(UA_NormalizedString *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* DecimalString */
#ifdef UA_TYPES_DECIMALSTRING
static void pack_UA_DecimalString(SV *out, const UA_DecimalString *in);
static void unpack_UA_DecimalString(UA_DecimalString *out, SV *in);

static void
pack_UA_DecimalString(SV *out, const UA_DecimalString *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_DecimalString(UA_DecimalString *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* DurationString */
#ifdef UA_TYPES_DURATIONSTRING
static void pack_UA_DurationString(SV *out, const UA_DurationString *in);
static void unpack_UA_DurationString(UA_DurationString *out, SV *in);

static void
pack_UA_DurationString(SV *out, const UA_DurationString *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_DurationString(UA_DurationString *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* TimeString */
#ifdef UA_TYPES_TIMESTRING
static void pack_UA_TimeString(SV *out, const UA_TimeString *in);
static void unpack_UA_TimeString(UA_TimeString *out, SV *in);

static void
pack_UA_TimeString(SV *out, const UA_TimeString *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_TimeString(UA_TimeString *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* DateString */
#ifdef UA_TYPES_DATESTRING
static void pack_UA_DateString(SV *out, const UA_DateString *in);
static void unpack_UA_DateString(UA_DateString *out, SV *in);

static void
pack_UA_DateString(SV *out, const UA_DateString *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_DateString(UA_DateString *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* Duration */
#ifdef UA_TYPES_DURATION
static void pack_UA_Duration(SV *out, const UA_Duration *in);
static void unpack_UA_Duration(UA_Duration *out, SV *in);

static void
pack_UA_Duration(SV *out, const UA_Duration *in)
{
	dTHX;
	pack_UA_Double(out, in);
}

static void
unpack_UA_Duration(UA_Duration *out, SV *in)
{
	dTHX;
	unpack_UA_Double(out, in);
}
#endif

/* UtcTime */
#ifdef UA_TYPES_UTCTIME
static void pack_UA_UtcTime(SV *out, const UA_UtcTime *in);
static void unpack_UA_UtcTime(UA_UtcTime *out, SV *in);

static void
pack_UA_UtcTime(SV *out, const UA_UtcTime *in)
{
	dTHX;
	pack_UA_DateTime(out, in);
}

static void
unpack_UA_UtcTime(UA_UtcTime *out, SV *in)
{
	dTHX;
	unpack_UA_DateTime(out, in);
}
#endif

/* Time */
#ifdef UA_TYPES_TIME
static void pack_UA_Time(SV *out, const UA_Time *in);
static void unpack_UA_Time(UA_Time *out, SV *in);

static void
pack_UA_Time(SV *out, const UA_Time *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_Time(UA_Time *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* Date */
#ifdef UA_TYPES_DATE
static void pack_UA_Date(SV *out, const UA_Date *in);
static void unpack_UA_Date(UA_Date *out, SV *in);

static void
pack_UA_Date(SV *out, const UA_Date *in)
{
	dTHX;
	pack_UA_DateTime(out, in);
}

static void
unpack_UA_Date(UA_Date *out, SV *in)
{
	dTHX;
	unpack_UA_DateTime(out, in);
}
#endif

/* LocaleId */
#ifdef UA_TYPES_LOCALEID
static void pack_UA_LocaleId(SV *out, const UA_LocaleId *in);
static void unpack_UA_LocaleId(UA_LocaleId *out, SV *in);

static void
pack_UA_LocaleId(SV *out, const UA_LocaleId *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_LocaleId(UA_LocaleId *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* TimeZoneDataType */
#ifdef UA_TYPES_TIMEZONEDATATYPE
static void pack_UA_TimeZoneDataType(SV *out, const UA_TimeZoneDataType *in);
static void unpack_UA_TimeZoneDataType(UA_TimeZoneDataType *out, SV *in);

static void
pack_UA_TimeZoneDataType(SV *out, const UA_TimeZoneDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "TimeZoneDataType_offset", sv);
	pack_UA_Int16(sv, &in->offset);

	sv = newSV(0);
	hv_stores(hv, "TimeZoneDataType_daylightSavingInOffset", sv);
	pack_UA_Boolean(sv, &in->daylightSavingInOffset);

	return;
}

static void
unpack_UA_TimeZoneDataType(UA_TimeZoneDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TimeZoneDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TimeZoneDataType_offset", 0);
	if (svp != NULL)
		unpack_UA_Int16(&out->offset, *svp);

	svp = hv_fetchs(hv, "TimeZoneDataType_daylightSavingInOffset", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->daylightSavingInOffset, *svp);

	return;
}
#endif

/* Index */
#ifdef UA_TYPES_INDEX
static void pack_UA_Index(SV *out, const UA_Index *in);
static void unpack_UA_Index(UA_Index *out, SV *in);

static void
pack_UA_Index(SV *out, const UA_Index *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_Index(UA_Index *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* IntegerId */
#ifdef UA_TYPES_INTEGERID
static void pack_UA_IntegerId(SV *out, const UA_IntegerId *in);
static void unpack_UA_IntegerId(UA_IntegerId *out, SV *in);

static void
pack_UA_IntegerId(SV *out, const UA_IntegerId *in)
{
	dTHX;
	pack_UA_UInt32(out, in);
}

static void
unpack_UA_IntegerId(UA_IntegerId *out, SV *in)
{
	dTHX;
	unpack_UA_UInt32(out, in);
}
#endif

/* ApplicationType */
#ifdef UA_TYPES_APPLICATIONTYPE
static void pack_UA_ApplicationType(SV *out, const UA_ApplicationType *in);
static void unpack_UA_ApplicationType(UA_ApplicationType *out, SV *in);

static void
pack_UA_ApplicationType(SV *out, const UA_ApplicationType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_ApplicationType(UA_ApplicationType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ApplicationDescription */
#ifdef UA_TYPES_APPLICATIONDESCRIPTION
static void pack_UA_ApplicationDescription(SV *out, const UA_ApplicationDescription *in);
static void unpack_UA_ApplicationDescription(UA_ApplicationDescription *out, SV *in);

static void
pack_UA_ApplicationDescription(SV *out, const UA_ApplicationDescription *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ApplicationDescription_applicationUri", sv);
	pack_UA_String(sv, &in->applicationUri);

	sv = newSV(0);
	hv_stores(hv, "ApplicationDescription_productUri", sv);
	pack_UA_String(sv, &in->productUri);

	sv = newSV(0);
	hv_stores(hv, "ApplicationDescription_applicationName", sv);
	pack_UA_LocalizedText(sv, &in->applicationName);

	sv = newSV(0);
	hv_stores(hv, "ApplicationDescription_applicationType", sv);
	pack_UA_ApplicationType(sv, &in->applicationType);

	sv = newSV(0);
	hv_stores(hv, "ApplicationDescription_gatewayServerUri", sv);
	pack_UA_String(sv, &in->gatewayServerUri);

	sv = newSV(0);
	hv_stores(hv, "ApplicationDescription_discoveryProfileUri", sv);
	pack_UA_String(sv, &in->discoveryProfileUri);

	av = newAV();
	hv_stores(hv, "ApplicationDescription_discoveryUrls", newRV_noinc((SV*)av));
	av_extend(av, in->discoveryUrlsSize);
	for (i = 0; i < in->discoveryUrlsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->discoveryUrls[i]);
	}

	return;
}

static void
unpack_UA_ApplicationDescription(UA_ApplicationDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ApplicationDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ApplicationDescription_applicationUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->applicationUri, *svp);

	svp = hv_fetchs(hv, "ApplicationDescription_productUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->productUri, *svp);

	svp = hv_fetchs(hv, "ApplicationDescription_applicationName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->applicationName, *svp);

	svp = hv_fetchs(hv, "ApplicationDescription_applicationType", 0);
	if (svp != NULL)
		unpack_UA_ApplicationType(&out->applicationType, *svp);

	svp = hv_fetchs(hv, "ApplicationDescription_gatewayServerUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->gatewayServerUri, *svp);

	svp = hv_fetchs(hv, "ApplicationDescription_discoveryProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->discoveryProfileUri, *svp);

	svp = hv_fetchs(hv, "ApplicationDescription_discoveryUrls", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ApplicationDescription_discoveryUrls");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->discoveryUrls = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->discoveryUrls == NULL)
			CROAKE("UA_Array_new");
		out->discoveryUrlsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->discoveryUrls[i], *svp);
		}
	}

	return;
}
#endif

/* RequestHeader */
#ifdef UA_TYPES_REQUESTHEADER
static void pack_UA_RequestHeader(SV *out, const UA_RequestHeader *in);
static void unpack_UA_RequestHeader(UA_RequestHeader *out, SV *in);

static void
pack_UA_RequestHeader(SV *out, const UA_RequestHeader *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RequestHeader_authenticationToken", sv);
	pack_UA_NodeId(sv, &in->authenticationToken);

	sv = newSV(0);
	hv_stores(hv, "RequestHeader_timestamp", sv);
	pack_UA_DateTime(sv, &in->timestamp);

	sv = newSV(0);
	hv_stores(hv, "RequestHeader_requestHandle", sv);
	pack_UA_UInt32(sv, &in->requestHandle);

	sv = newSV(0);
	hv_stores(hv, "RequestHeader_returnDiagnostics", sv);
	pack_UA_UInt32(sv, &in->returnDiagnostics);

	sv = newSV(0);
	hv_stores(hv, "RequestHeader_auditEntryId", sv);
	pack_UA_String(sv, &in->auditEntryId);

	sv = newSV(0);
	hv_stores(hv, "RequestHeader_timeoutHint", sv);
	pack_UA_UInt32(sv, &in->timeoutHint);

	sv = newSV(0);
	hv_stores(hv, "RequestHeader_additionalHeader", sv);
	pack_UA_ExtensionObject(sv, &in->additionalHeader);

	return;
}

static void
unpack_UA_RequestHeader(UA_RequestHeader *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RequestHeader_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RequestHeader_authenticationToken", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->authenticationToken, *svp);

	svp = hv_fetchs(hv, "RequestHeader_timestamp", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->timestamp, *svp);

	svp = hv_fetchs(hv, "RequestHeader_requestHandle", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestHandle, *svp);

	svp = hv_fetchs(hv, "RequestHeader_returnDiagnostics", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->returnDiagnostics, *svp);

	svp = hv_fetchs(hv, "RequestHeader_auditEntryId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->auditEntryId, *svp);

	svp = hv_fetchs(hv, "RequestHeader_timeoutHint", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->timeoutHint, *svp);

	svp = hv_fetchs(hv, "RequestHeader_additionalHeader", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->additionalHeader, *svp);

	return;
}
#endif

/* ResponseHeader */
#ifdef UA_TYPES_RESPONSEHEADER
static void pack_UA_ResponseHeader(SV *out, const UA_ResponseHeader *in);
static void unpack_UA_ResponseHeader(UA_ResponseHeader *out, SV *in);

static void
pack_UA_ResponseHeader(SV *out, const UA_ResponseHeader *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ResponseHeader_timestamp", sv);
	pack_UA_DateTime(sv, &in->timestamp);

	sv = newSV(0);
	hv_stores(hv, "ResponseHeader_requestHandle", sv);
	pack_UA_UInt32(sv, &in->requestHandle);

	sv = newSV(0);
	hv_stores(hv, "ResponseHeader_serviceResult", sv);
	pack_UA_StatusCode(sv, &in->serviceResult);

	sv = newSV(0);
	hv_stores(hv, "ResponseHeader_serviceDiagnostics", sv);
	pack_UA_DiagnosticInfo(sv, &in->serviceDiagnostics);

	av = newAV();
	hv_stores(hv, "ResponseHeader_stringTable", newRV_noinc((SV*)av));
	av_extend(av, in->stringTableSize);
	for (i = 0; i < in->stringTableSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->stringTable[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ResponseHeader_additionalHeader", sv);
	pack_UA_ExtensionObject(sv, &in->additionalHeader);

	return;
}

static void
unpack_UA_ResponseHeader(UA_ResponseHeader *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ResponseHeader_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ResponseHeader_timestamp", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->timestamp, *svp);

	svp = hv_fetchs(hv, "ResponseHeader_requestHandle", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestHandle, *svp);

	svp = hv_fetchs(hv, "ResponseHeader_serviceResult", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->serviceResult, *svp);

	svp = hv_fetchs(hv, "ResponseHeader_serviceDiagnostics", 0);
	if (svp != NULL)
		unpack_UA_DiagnosticInfo(&out->serviceDiagnostics, *svp);

	svp = hv_fetchs(hv, "ResponseHeader_stringTable", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ResponseHeader_stringTable");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->stringTable = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->stringTable == NULL)
			CROAKE("UA_Array_new");
		out->stringTableSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->stringTable[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ResponseHeader_additionalHeader", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->additionalHeader, *svp);

	return;
}
#endif

/* VersionTime */
#ifdef UA_TYPES_VERSIONTIME
static void pack_UA_VersionTime(SV *out, const UA_VersionTime *in);
static void unpack_UA_VersionTime(UA_VersionTime *out, SV *in);

static void
pack_UA_VersionTime(SV *out, const UA_VersionTime *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_VersionTime(UA_VersionTime *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* ServiceFault */
#ifdef UA_TYPES_SERVICEFAULT
static void pack_UA_ServiceFault(SV *out, const UA_ServiceFault *in);
static void unpack_UA_ServiceFault(UA_ServiceFault *out, SV *in);

static void
pack_UA_ServiceFault(SV *out, const UA_ServiceFault *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ServiceFault_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	return;
}

static void
unpack_UA_ServiceFault(UA_ServiceFault *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ServiceFault_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServiceFault_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	return;
}
#endif

/* SessionlessInvokeRequestType */
#ifdef UA_TYPES_SESSIONLESSINVOKEREQUESTTYPE
static void pack_UA_SessionlessInvokeRequestType(SV *out, const UA_SessionlessInvokeRequestType *in);
static void unpack_UA_SessionlessInvokeRequestType(UA_SessionlessInvokeRequestType *out, SV *in);

static void
pack_UA_SessionlessInvokeRequestType(SV *out, const UA_SessionlessInvokeRequestType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SessionlessInvokeRequestType_urisVersion", sv);
	pack_UA_UInt32(sv, &in->urisVersion);

	av = newAV();
	hv_stores(hv, "SessionlessInvokeRequestType_namespaceUris", newRV_noinc((SV*)av));
	av_extend(av, in->namespaceUrisSize);
	for (i = 0; i < in->namespaceUrisSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->namespaceUris[i]);
	}

	av = newAV();
	hv_stores(hv, "SessionlessInvokeRequestType_serverUris", newRV_noinc((SV*)av));
	av_extend(av, in->serverUrisSize);
	for (i = 0; i < in->serverUrisSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->serverUris[i]);
	}

	av = newAV();
	hv_stores(hv, "SessionlessInvokeRequestType_localeIds", newRV_noinc((SV*)av));
	av_extend(av, in->localeIdsSize);
	for (i = 0; i < in->localeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->localeIds[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "SessionlessInvokeRequestType_serviceId", sv);
	pack_UA_UInt32(sv, &in->serviceId);

	return;
}

static void
unpack_UA_SessionlessInvokeRequestType(UA_SessionlessInvokeRequestType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SessionlessInvokeRequestType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SessionlessInvokeRequestType_urisVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->urisVersion, *svp);

	svp = hv_fetchs(hv, "SessionlessInvokeRequestType_namespaceUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SessionlessInvokeRequestType_namespaceUris");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->namespaceUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->namespaceUris == NULL)
			CROAKE("UA_Array_new");
		out->namespaceUrisSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->namespaceUris[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SessionlessInvokeRequestType_serverUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SessionlessInvokeRequestType_serverUris");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->serverUris == NULL)
			CROAKE("UA_Array_new");
		out->serverUrisSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->serverUris[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SessionlessInvokeRequestType_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SessionlessInvokeRequestType_localeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->localeIds == NULL)
			CROAKE("UA_Array_new");
		out->localeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->localeIds[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SessionlessInvokeRequestType_serviceId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->serviceId, *svp);

	return;
}
#endif

/* SessionlessInvokeResponseType */
#ifdef UA_TYPES_SESSIONLESSINVOKERESPONSETYPE
static void pack_UA_SessionlessInvokeResponseType(SV *out, const UA_SessionlessInvokeResponseType *in);
static void unpack_UA_SessionlessInvokeResponseType(UA_SessionlessInvokeResponseType *out, SV *in);

static void
pack_UA_SessionlessInvokeResponseType(SV *out, const UA_SessionlessInvokeResponseType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "SessionlessInvokeResponseType_namespaceUris", newRV_noinc((SV*)av));
	av_extend(av, in->namespaceUrisSize);
	for (i = 0; i < in->namespaceUrisSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->namespaceUris[i]);
	}

	av = newAV();
	hv_stores(hv, "SessionlessInvokeResponseType_serverUris", newRV_noinc((SV*)av));
	av_extend(av, in->serverUrisSize);
	for (i = 0; i < in->serverUrisSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->serverUris[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "SessionlessInvokeResponseType_serviceId", sv);
	pack_UA_UInt32(sv, &in->serviceId);

	return;
}

static void
unpack_UA_SessionlessInvokeResponseType(UA_SessionlessInvokeResponseType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SessionlessInvokeResponseType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SessionlessInvokeResponseType_namespaceUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SessionlessInvokeResponseType_namespaceUris");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->namespaceUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->namespaceUris == NULL)
			CROAKE("UA_Array_new");
		out->namespaceUrisSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->namespaceUris[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SessionlessInvokeResponseType_serverUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SessionlessInvokeResponseType_serverUris");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->serverUris == NULL)
			CROAKE("UA_Array_new");
		out->serverUrisSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->serverUris[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SessionlessInvokeResponseType_serviceId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->serviceId, *svp);

	return;
}
#endif

/* FindServersRequest */
#ifdef UA_TYPES_FINDSERVERSREQUEST
static void pack_UA_FindServersRequest(SV *out, const UA_FindServersRequest *in);
static void unpack_UA_FindServersRequest(UA_FindServersRequest *out, SV *in);

static void
pack_UA_FindServersRequest(SV *out, const UA_FindServersRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "FindServersRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "FindServersRequest_endpointUrl", sv);
	pack_UA_String(sv, &in->endpointUrl);

	av = newAV();
	hv_stores(hv, "FindServersRequest_localeIds", newRV_noinc((SV*)av));
	av_extend(av, in->localeIdsSize);
	for (i = 0; i < in->localeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->localeIds[i]);
	}

	av = newAV();
	hv_stores(hv, "FindServersRequest_serverUris", newRV_noinc((SV*)av));
	av_extend(av, in->serverUrisSize);
	for (i = 0; i < in->serverUrisSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->serverUris[i]);
	}

	return;
}

static void
unpack_UA_FindServersRequest(UA_FindServersRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_FindServersRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "FindServersRequest_endpointUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->endpointUrl, *svp);

	svp = hv_fetchs(hv, "FindServersRequest_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for FindServersRequest_localeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->localeIds == NULL)
			CROAKE("UA_Array_new");
		out->localeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->localeIds[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "FindServersRequest_serverUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for FindServersRequest_serverUris");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->serverUris == NULL)
			CROAKE("UA_Array_new");
		out->serverUrisSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->serverUris[i], *svp);
		}
	}

	return;
}
#endif

/* FindServersResponse */
#ifdef UA_TYPES_FINDSERVERSRESPONSE
static void pack_UA_FindServersResponse(SV *out, const UA_FindServersResponse *in);
static void unpack_UA_FindServersResponse(UA_FindServersResponse *out, SV *in);

static void
pack_UA_FindServersResponse(SV *out, const UA_FindServersResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "FindServersResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "FindServersResponse_servers", newRV_noinc((SV*)av));
	av_extend(av, in->serversSize);
	for (i = 0; i < in->serversSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ApplicationDescription(sv, &in->servers[i]);
	}

	return;
}

static void
unpack_UA_FindServersResponse(UA_FindServersResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_FindServersResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "FindServersResponse_servers", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for FindServersResponse_servers");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->servers = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_APPLICATIONDESCRIPTION]);
		if (out->servers == NULL)
			CROAKE("UA_Array_new");
		out->serversSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ApplicationDescription(&out->servers[i], *svp);
		}
	}

	return;
}
#endif

/* ServerOnNetwork */
#ifdef UA_TYPES_SERVERONNETWORK
static void pack_UA_ServerOnNetwork(SV *out, const UA_ServerOnNetwork *in);
static void unpack_UA_ServerOnNetwork(UA_ServerOnNetwork *out, SV *in);

static void
pack_UA_ServerOnNetwork(SV *out, const UA_ServerOnNetwork *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ServerOnNetwork_recordId", sv);
	pack_UA_UInt32(sv, &in->recordId);

	sv = newSV(0);
	hv_stores(hv, "ServerOnNetwork_serverName", sv);
	pack_UA_String(sv, &in->serverName);

	sv = newSV(0);
	hv_stores(hv, "ServerOnNetwork_discoveryUrl", sv);
	pack_UA_String(sv, &in->discoveryUrl);

	av = newAV();
	hv_stores(hv, "ServerOnNetwork_serverCapabilities", newRV_noinc((SV*)av));
	av_extend(av, in->serverCapabilitiesSize);
	for (i = 0; i < in->serverCapabilitiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->serverCapabilities[i]);
	}

	return;
}

static void
unpack_UA_ServerOnNetwork(UA_ServerOnNetwork *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ServerOnNetwork_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServerOnNetwork_recordId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->recordId, *svp);

	svp = hv_fetchs(hv, "ServerOnNetwork_serverName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->serverName, *svp);

	svp = hv_fetchs(hv, "ServerOnNetwork_discoveryUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->discoveryUrl, *svp);

	svp = hv_fetchs(hv, "ServerOnNetwork_serverCapabilities", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ServerOnNetwork_serverCapabilities");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverCapabilities = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->serverCapabilities == NULL)
			CROAKE("UA_Array_new");
		out->serverCapabilitiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->serverCapabilities[i], *svp);
		}
	}

	return;
}
#endif

/* FindServersOnNetworkRequest */
#ifdef UA_TYPES_FINDSERVERSONNETWORKREQUEST
static void pack_UA_FindServersOnNetworkRequest(SV *out, const UA_FindServersOnNetworkRequest *in);
static void unpack_UA_FindServersOnNetworkRequest(UA_FindServersOnNetworkRequest *out, SV *in);

static void
pack_UA_FindServersOnNetworkRequest(SV *out, const UA_FindServersOnNetworkRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "FindServersOnNetworkRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "FindServersOnNetworkRequest_startingRecordId", sv);
	pack_UA_UInt32(sv, &in->startingRecordId);

	sv = newSV(0);
	hv_stores(hv, "FindServersOnNetworkRequest_maxRecordsToReturn", sv);
	pack_UA_UInt32(sv, &in->maxRecordsToReturn);

	av = newAV();
	hv_stores(hv, "FindServersOnNetworkRequest_serverCapabilityFilter", newRV_noinc((SV*)av));
	av_extend(av, in->serverCapabilityFilterSize);
	for (i = 0; i < in->serverCapabilityFilterSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->serverCapabilityFilter[i]);
	}

	return;
}

static void
unpack_UA_FindServersOnNetworkRequest(UA_FindServersOnNetworkRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_FindServersOnNetworkRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_startingRecordId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->startingRecordId, *svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_maxRecordsToReturn", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxRecordsToReturn, *svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_serverCapabilityFilter", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for FindServersOnNetworkRequest_serverCapabilityFilter");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverCapabilityFilter = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->serverCapabilityFilter == NULL)
			CROAKE("UA_Array_new");
		out->serverCapabilityFilterSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->serverCapabilityFilter[i], *svp);
		}
	}

	return;
}
#endif

/* FindServersOnNetworkResponse */
#ifdef UA_TYPES_FINDSERVERSONNETWORKRESPONSE
static void pack_UA_FindServersOnNetworkResponse(SV *out, const UA_FindServersOnNetworkResponse *in);
static void unpack_UA_FindServersOnNetworkResponse(UA_FindServersOnNetworkResponse *out, SV *in);

static void
pack_UA_FindServersOnNetworkResponse(SV *out, const UA_FindServersOnNetworkResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "FindServersOnNetworkResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "FindServersOnNetworkResponse_lastCounterResetTime", sv);
	pack_UA_DateTime(sv, &in->lastCounterResetTime);

	av = newAV();
	hv_stores(hv, "FindServersOnNetworkResponse_servers", newRV_noinc((SV*)av));
	av_extend(av, in->serversSize);
	for (i = 0; i < in->serversSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ServerOnNetwork(sv, &in->servers[i]);
	}

	return;
}

static void
unpack_UA_FindServersOnNetworkResponse(UA_FindServersOnNetworkResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_FindServersOnNetworkResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersOnNetworkResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkResponse_lastCounterResetTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->lastCounterResetTime, *svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkResponse_servers", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for FindServersOnNetworkResponse_servers");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->servers = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SERVERONNETWORK]);
		if (out->servers == NULL)
			CROAKE("UA_Array_new");
		out->serversSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ServerOnNetwork(&out->servers[i], *svp);
		}
	}

	return;
}
#endif

/* ApplicationInstanceCertificate */
#ifdef UA_TYPES_APPLICATIONINSTANCECERTIFICATE
static void pack_UA_ApplicationInstanceCertificate(SV *out, const UA_ApplicationInstanceCertificate *in);
static void unpack_UA_ApplicationInstanceCertificate(UA_ApplicationInstanceCertificate *out, SV *in);

static void
pack_UA_ApplicationInstanceCertificate(SV *out, const UA_ApplicationInstanceCertificate *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_ApplicationInstanceCertificate(UA_ApplicationInstanceCertificate *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* MessageSecurityMode */
#ifdef UA_TYPES_MESSAGESECURITYMODE
static void pack_UA_MessageSecurityMode(SV *out, const UA_MessageSecurityMode *in);
static void unpack_UA_MessageSecurityMode(UA_MessageSecurityMode *out, SV *in);

static void
pack_UA_MessageSecurityMode(SV *out, const UA_MessageSecurityMode *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_MessageSecurityMode(UA_MessageSecurityMode *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* UserTokenType */
#ifdef UA_TYPES_USERTOKENTYPE
static void pack_UA_UserTokenType(SV *out, const UA_UserTokenType *in);
static void unpack_UA_UserTokenType(UA_UserTokenType *out, SV *in);

static void
pack_UA_UserTokenType(SV *out, const UA_UserTokenType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_UserTokenType(UA_UserTokenType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* UserTokenPolicy */
#ifdef UA_TYPES_USERTOKENPOLICY
static void pack_UA_UserTokenPolicy(SV *out, const UA_UserTokenPolicy *in);
static void unpack_UA_UserTokenPolicy(UA_UserTokenPolicy *out, SV *in);

static void
pack_UA_UserTokenPolicy(SV *out, const UA_UserTokenPolicy *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UserTokenPolicy_policyId", sv);
	pack_UA_String(sv, &in->policyId);

	sv = newSV(0);
	hv_stores(hv, "UserTokenPolicy_tokenType", sv);
	pack_UA_UserTokenType(sv, &in->tokenType);

	sv = newSV(0);
	hv_stores(hv, "UserTokenPolicy_issuedTokenType", sv);
	pack_UA_String(sv, &in->issuedTokenType);

	sv = newSV(0);
	hv_stores(hv, "UserTokenPolicy_issuerEndpointUrl", sv);
	pack_UA_String(sv, &in->issuerEndpointUrl);

	sv = newSV(0);
	hv_stores(hv, "UserTokenPolicy_securityPolicyUri", sv);
	pack_UA_String(sv, &in->securityPolicyUri);

	return;
}

static void
unpack_UA_UserTokenPolicy(UA_UserTokenPolicy *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UserTokenPolicy_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UserTokenPolicy_policyId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->policyId, *svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_tokenType", 0);
	if (svp != NULL)
		unpack_UA_UserTokenType(&out->tokenType, *svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_issuedTokenType", 0);
	if (svp != NULL)
		unpack_UA_String(&out->issuedTokenType, *svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_issuerEndpointUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->issuerEndpointUrl, *svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_securityPolicyUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityPolicyUri, *svp);

	return;
}
#endif

/* EndpointDescription */
#ifdef UA_TYPES_ENDPOINTDESCRIPTION
static void pack_UA_EndpointDescription(SV *out, const UA_EndpointDescription *in);
static void unpack_UA_EndpointDescription(UA_EndpointDescription *out, SV *in);

static void
pack_UA_EndpointDescription(SV *out, const UA_EndpointDescription *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EndpointDescription_endpointUrl", sv);
	pack_UA_String(sv, &in->endpointUrl);

	sv = newSV(0);
	hv_stores(hv, "EndpointDescription_server", sv);
	pack_UA_ApplicationDescription(sv, &in->server);

	sv = newSV(0);
	hv_stores(hv, "EndpointDescription_serverCertificate", sv);
	pack_UA_ByteString(sv, &in->serverCertificate);

	sv = newSV(0);
	hv_stores(hv, "EndpointDescription_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "EndpointDescription_securityPolicyUri", sv);
	pack_UA_String(sv, &in->securityPolicyUri);

	av = newAV();
	hv_stores(hv, "EndpointDescription_userIdentityTokens", newRV_noinc((SV*)av));
	av_extend(av, in->userIdentityTokensSize);
	for (i = 0; i < in->userIdentityTokensSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UserTokenPolicy(sv, &in->userIdentityTokens[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "EndpointDescription_transportProfileUri", sv);
	pack_UA_String(sv, &in->transportProfileUri);

	sv = newSV(0);
	hv_stores(hv, "EndpointDescription_securityLevel", sv);
	pack_UA_Byte(sv, &in->securityLevel);

	return;
}

static void
unpack_UA_EndpointDescription(UA_EndpointDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EndpointDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EndpointDescription_endpointUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->endpointUrl, *svp);

	svp = hv_fetchs(hv, "EndpointDescription_server", 0);
	if (svp != NULL)
		unpack_UA_ApplicationDescription(&out->server, *svp);

	svp = hv_fetchs(hv, "EndpointDescription_serverCertificate", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->serverCertificate, *svp);

	svp = hv_fetchs(hv, "EndpointDescription_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "EndpointDescription_securityPolicyUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityPolicyUri, *svp);

	svp = hv_fetchs(hv, "EndpointDescription_userIdentityTokens", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EndpointDescription_userIdentityTokens");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->userIdentityTokens = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_USERTOKENPOLICY]);
		if (out->userIdentityTokens == NULL)
			CROAKE("UA_Array_new");
		out->userIdentityTokensSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UserTokenPolicy(&out->userIdentityTokens[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "EndpointDescription_transportProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->transportProfileUri, *svp);

	svp = hv_fetchs(hv, "EndpointDescription_securityLevel", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->securityLevel, *svp);

	return;
}
#endif

/* GetEndpointsRequest */
#ifdef UA_TYPES_GETENDPOINTSREQUEST
static void pack_UA_GetEndpointsRequest(SV *out, const UA_GetEndpointsRequest *in);
static void unpack_UA_GetEndpointsRequest(UA_GetEndpointsRequest *out, SV *in);

static void
pack_UA_GetEndpointsRequest(SV *out, const UA_GetEndpointsRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "GetEndpointsRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "GetEndpointsRequest_endpointUrl", sv);
	pack_UA_String(sv, &in->endpointUrl);

	av = newAV();
	hv_stores(hv, "GetEndpointsRequest_localeIds", newRV_noinc((SV*)av));
	av_extend(av, in->localeIdsSize);
	for (i = 0; i < in->localeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->localeIds[i]);
	}

	av = newAV();
	hv_stores(hv, "GetEndpointsRequest_profileUris", newRV_noinc((SV*)av));
	av_extend(av, in->profileUrisSize);
	for (i = 0; i < in->profileUrisSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->profileUris[i]);
	}

	return;
}

static void
unpack_UA_GetEndpointsRequest(UA_GetEndpointsRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_GetEndpointsRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GetEndpointsRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "GetEndpointsRequest_endpointUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->endpointUrl, *svp);

	svp = hv_fetchs(hv, "GetEndpointsRequest_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for GetEndpointsRequest_localeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->localeIds == NULL)
			CROAKE("UA_Array_new");
		out->localeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->localeIds[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "GetEndpointsRequest_profileUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for GetEndpointsRequest_profileUris");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->profileUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->profileUris == NULL)
			CROAKE("UA_Array_new");
		out->profileUrisSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->profileUris[i], *svp);
		}
	}

	return;
}
#endif

/* GetEndpointsResponse */
#ifdef UA_TYPES_GETENDPOINTSRESPONSE
static void pack_UA_GetEndpointsResponse(SV *out, const UA_GetEndpointsResponse *in);
static void unpack_UA_GetEndpointsResponse(UA_GetEndpointsResponse *out, SV *in);

static void
pack_UA_GetEndpointsResponse(SV *out, const UA_GetEndpointsResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "GetEndpointsResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "GetEndpointsResponse_endpoints", newRV_noinc((SV*)av));
	av_extend(av, in->endpointsSize);
	for (i = 0; i < in->endpointsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EndpointDescription(sv, &in->endpoints[i]);
	}

	return;
}

static void
unpack_UA_GetEndpointsResponse(UA_GetEndpointsResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_GetEndpointsResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GetEndpointsResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "GetEndpointsResponse_endpoints", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for GetEndpointsResponse_endpoints");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->endpoints = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out->endpoints == NULL)
			CROAKE("UA_Array_new");
		out->endpointsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EndpointDescription(&out->endpoints[i], *svp);
		}
	}

	return;
}
#endif

/* RegisteredServer */
#ifdef UA_TYPES_REGISTEREDSERVER
static void pack_UA_RegisteredServer(SV *out, const UA_RegisteredServer *in);
static void unpack_UA_RegisteredServer(UA_RegisteredServer *out, SV *in);

static void
pack_UA_RegisteredServer(SV *out, const UA_RegisteredServer *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RegisteredServer_serverUri", sv);
	pack_UA_String(sv, &in->serverUri);

	sv = newSV(0);
	hv_stores(hv, "RegisteredServer_productUri", sv);
	pack_UA_String(sv, &in->productUri);

	av = newAV();
	hv_stores(hv, "RegisteredServer_serverNames", newRV_noinc((SV*)av));
	av_extend(av, in->serverNamesSize);
	for (i = 0; i < in->serverNamesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_LocalizedText(sv, &in->serverNames[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "RegisteredServer_serverType", sv);
	pack_UA_ApplicationType(sv, &in->serverType);

	sv = newSV(0);
	hv_stores(hv, "RegisteredServer_gatewayServerUri", sv);
	pack_UA_String(sv, &in->gatewayServerUri);

	av = newAV();
	hv_stores(hv, "RegisteredServer_discoveryUrls", newRV_noinc((SV*)av));
	av_extend(av, in->discoveryUrlsSize);
	for (i = 0; i < in->discoveryUrlsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->discoveryUrls[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "RegisteredServer_semaphoreFilePath", sv);
	pack_UA_String(sv, &in->semaphoreFilePath);

	sv = newSV(0);
	hv_stores(hv, "RegisteredServer_isOnline", sv);
	pack_UA_Boolean(sv, &in->isOnline);

	return;
}

static void
unpack_UA_RegisteredServer(UA_RegisteredServer *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RegisteredServer_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisteredServer_serverUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->serverUri, *svp);

	svp = hv_fetchs(hv, "RegisteredServer_productUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->productUri, *svp);

	svp = hv_fetchs(hv, "RegisteredServer_serverNames", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RegisteredServer_serverNames");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverNames = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_LOCALIZEDTEXT]);
		if (out->serverNames == NULL)
			CROAKE("UA_Array_new");
		out->serverNamesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_LocalizedText(&out->serverNames[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "RegisteredServer_serverType", 0);
	if (svp != NULL)
		unpack_UA_ApplicationType(&out->serverType, *svp);

	svp = hv_fetchs(hv, "RegisteredServer_gatewayServerUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->gatewayServerUri, *svp);

	svp = hv_fetchs(hv, "RegisteredServer_discoveryUrls", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RegisteredServer_discoveryUrls");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->discoveryUrls = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->discoveryUrls == NULL)
			CROAKE("UA_Array_new");
		out->discoveryUrlsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->discoveryUrls[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "RegisteredServer_semaphoreFilePath", 0);
	if (svp != NULL)
		unpack_UA_String(&out->semaphoreFilePath, *svp);

	svp = hv_fetchs(hv, "RegisteredServer_isOnline", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isOnline, *svp);

	return;
}
#endif

/* RegisterServerRequest */
#ifdef UA_TYPES_REGISTERSERVERREQUEST
static void pack_UA_RegisterServerRequest(SV *out, const UA_RegisterServerRequest *in);
static void unpack_UA_RegisterServerRequest(UA_RegisterServerRequest *out, SV *in);

static void
pack_UA_RegisterServerRequest(SV *out, const UA_RegisterServerRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RegisterServerRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "RegisterServerRequest_server", sv);
	pack_UA_RegisteredServer(sv, &in->server);

	return;
}

static void
unpack_UA_RegisterServerRequest(UA_RegisterServerRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RegisterServerRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServerRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "RegisterServerRequest_server", 0);
	if (svp != NULL)
		unpack_UA_RegisteredServer(&out->server, *svp);

	return;
}
#endif

/* RegisterServerResponse */
#ifdef UA_TYPES_REGISTERSERVERRESPONSE
static void pack_UA_RegisterServerResponse(SV *out, const UA_RegisterServerResponse *in);
static void unpack_UA_RegisterServerResponse(UA_RegisterServerResponse *out, SV *in);

static void
pack_UA_RegisterServerResponse(SV *out, const UA_RegisterServerResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RegisterServerResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	return;
}

static void
unpack_UA_RegisterServerResponse(UA_RegisterServerResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RegisterServerResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServerResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	return;
}
#endif

/* MdnsDiscoveryConfiguration */
#ifdef UA_TYPES_MDNSDISCOVERYCONFIGURATION
static void pack_UA_MdnsDiscoveryConfiguration(SV *out, const UA_MdnsDiscoveryConfiguration *in);
static void unpack_UA_MdnsDiscoveryConfiguration(UA_MdnsDiscoveryConfiguration *out, SV *in);

static void
pack_UA_MdnsDiscoveryConfiguration(SV *out, const UA_MdnsDiscoveryConfiguration *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MdnsDiscoveryConfiguration_mdnsServerName", sv);
	pack_UA_String(sv, &in->mdnsServerName);

	av = newAV();
	hv_stores(hv, "MdnsDiscoveryConfiguration_serverCapabilities", newRV_noinc((SV*)av));
	av_extend(av, in->serverCapabilitiesSize);
	for (i = 0; i < in->serverCapabilitiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->serverCapabilities[i]);
	}

	return;
}

static void
unpack_UA_MdnsDiscoveryConfiguration(UA_MdnsDiscoveryConfiguration *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MdnsDiscoveryConfiguration_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MdnsDiscoveryConfiguration_mdnsServerName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->mdnsServerName, *svp);

	svp = hv_fetchs(hv, "MdnsDiscoveryConfiguration_serverCapabilities", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for MdnsDiscoveryConfiguration_serverCapabilities");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverCapabilities = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->serverCapabilities == NULL)
			CROAKE("UA_Array_new");
		out->serverCapabilitiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->serverCapabilities[i], *svp);
		}
	}

	return;
}
#endif

/* RegisterServer2Request */
#ifdef UA_TYPES_REGISTERSERVER2REQUEST
static void pack_UA_RegisterServer2Request(SV *out, const UA_RegisterServer2Request *in);
static void unpack_UA_RegisterServer2Request(UA_RegisterServer2Request *out, SV *in);

static void
pack_UA_RegisterServer2Request(SV *out, const UA_RegisterServer2Request *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RegisterServer2Request_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "RegisterServer2Request_server", sv);
	pack_UA_RegisteredServer(sv, &in->server);

	av = newAV();
	hv_stores(hv, "RegisterServer2Request_discoveryConfiguration", newRV_noinc((SV*)av));
	av_extend(av, in->discoveryConfigurationSize);
	for (i = 0; i < in->discoveryConfigurationSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ExtensionObject(sv, &in->discoveryConfiguration[i]);
	}

	return;
}

static void
unpack_UA_RegisterServer2Request(UA_RegisterServer2Request *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RegisterServer2Request_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServer2Request_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "RegisterServer2Request_server", 0);
	if (svp != NULL)
		unpack_UA_RegisteredServer(&out->server, *svp);

	svp = hv_fetchs(hv, "RegisterServer2Request_discoveryConfiguration", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RegisterServer2Request_discoveryConfiguration");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->discoveryConfiguration = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXTENSIONOBJECT]);
		if (out->discoveryConfiguration == NULL)
			CROAKE("UA_Array_new");
		out->discoveryConfigurationSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ExtensionObject(&out->discoveryConfiguration[i], *svp);
		}
	}

	return;
}
#endif

/* RegisterServer2Response */
#ifdef UA_TYPES_REGISTERSERVER2RESPONSE
static void pack_UA_RegisterServer2Response(SV *out, const UA_RegisterServer2Response *in);
static void unpack_UA_RegisterServer2Response(UA_RegisterServer2Response *out, SV *in);

static void
pack_UA_RegisterServer2Response(SV *out, const UA_RegisterServer2Response *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RegisterServer2Response_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "RegisterServer2Response_configurationResults", newRV_noinc((SV*)av));
	av_extend(av, in->configurationResultsSize);
	for (i = 0; i < in->configurationResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->configurationResults[i]);
	}

	av = newAV();
	hv_stores(hv, "RegisterServer2Response_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_RegisterServer2Response(UA_RegisterServer2Response *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RegisterServer2Response_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServer2Response_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "RegisterServer2Response_configurationResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RegisterServer2Response_configurationResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->configurationResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->configurationResults == NULL)
			CROAKE("UA_Array_new");
		out->configurationResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->configurationResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "RegisterServer2Response_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RegisterServer2Response_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* SecurityTokenRequestType */
#ifdef UA_TYPES_SECURITYTOKENREQUESTTYPE
static void pack_UA_SecurityTokenRequestType(SV *out, const UA_SecurityTokenRequestType *in);
static void unpack_UA_SecurityTokenRequestType(UA_SecurityTokenRequestType *out, SV *in);

static void
pack_UA_SecurityTokenRequestType(SV *out, const UA_SecurityTokenRequestType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_SecurityTokenRequestType(UA_SecurityTokenRequestType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ChannelSecurityToken */
#ifdef UA_TYPES_CHANNELSECURITYTOKEN
static void pack_UA_ChannelSecurityToken(SV *out, const UA_ChannelSecurityToken *in);
static void unpack_UA_ChannelSecurityToken(UA_ChannelSecurityToken *out, SV *in);

static void
pack_UA_ChannelSecurityToken(SV *out, const UA_ChannelSecurityToken *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ChannelSecurityToken_channelId", sv);
	pack_UA_UInt32(sv, &in->channelId);

	sv = newSV(0);
	hv_stores(hv, "ChannelSecurityToken_tokenId", sv);
	pack_UA_UInt32(sv, &in->tokenId);

	sv = newSV(0);
	hv_stores(hv, "ChannelSecurityToken_createdAt", sv);
	pack_UA_DateTime(sv, &in->createdAt);

	sv = newSV(0);
	hv_stores(hv, "ChannelSecurityToken_revisedLifetime", sv);
	pack_UA_UInt32(sv, &in->revisedLifetime);

	return;
}

static void
unpack_UA_ChannelSecurityToken(UA_ChannelSecurityToken *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ChannelSecurityToken_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ChannelSecurityToken_channelId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->channelId, *svp);

	svp = hv_fetchs(hv, "ChannelSecurityToken_tokenId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->tokenId, *svp);

	svp = hv_fetchs(hv, "ChannelSecurityToken_createdAt", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->createdAt, *svp);

	svp = hv_fetchs(hv, "ChannelSecurityToken_revisedLifetime", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->revisedLifetime, *svp);

	return;
}
#endif

/* OpenSecureChannelRequest */
#ifdef UA_TYPES_OPENSECURECHANNELREQUEST
static void pack_UA_OpenSecureChannelRequest(SV *out, const UA_OpenSecureChannelRequest *in);
static void unpack_UA_OpenSecureChannelRequest(UA_OpenSecureChannelRequest *out, SV *in);

static void
pack_UA_OpenSecureChannelRequest(SV *out, const UA_OpenSecureChannelRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelRequest_clientProtocolVersion", sv);
	pack_UA_UInt32(sv, &in->clientProtocolVersion);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelRequest_requestType", sv);
	pack_UA_SecurityTokenRequestType(sv, &in->requestType);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelRequest_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelRequest_clientNonce", sv);
	pack_UA_ByteString(sv, &in->clientNonce);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelRequest_requestedLifetime", sv);
	pack_UA_UInt32(sv, &in->requestedLifetime);

	return;
}

static void
unpack_UA_OpenSecureChannelRequest(UA_OpenSecureChannelRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_OpenSecureChannelRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_clientProtocolVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->clientProtocolVersion, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_requestType", 0);
	if (svp != NULL)
		unpack_UA_SecurityTokenRequestType(&out->requestType, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_clientNonce", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->clientNonce, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_requestedLifetime", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestedLifetime, *svp);

	return;
}
#endif

/* OpenSecureChannelResponse */
#ifdef UA_TYPES_OPENSECURECHANNELRESPONSE
static void pack_UA_OpenSecureChannelResponse(SV *out, const UA_OpenSecureChannelResponse *in);
static void unpack_UA_OpenSecureChannelResponse(UA_OpenSecureChannelResponse *out, SV *in);

static void
pack_UA_OpenSecureChannelResponse(SV *out, const UA_OpenSecureChannelResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelResponse_serverProtocolVersion", sv);
	pack_UA_UInt32(sv, &in->serverProtocolVersion);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelResponse_securityToken", sv);
	pack_UA_ChannelSecurityToken(sv, &in->securityToken);

	sv = newSV(0);
	hv_stores(hv, "OpenSecureChannelResponse_serverNonce", sv);
	pack_UA_ByteString(sv, &in->serverNonce);

	return;
}

static void
unpack_UA_OpenSecureChannelResponse(UA_OpenSecureChannelResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_OpenSecureChannelResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_serverProtocolVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->serverProtocolVersion, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_securityToken", 0);
	if (svp != NULL)
		unpack_UA_ChannelSecurityToken(&out->securityToken, *svp);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_serverNonce", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->serverNonce, *svp);

	return;
}
#endif

/* CloseSecureChannelRequest */
#ifdef UA_TYPES_CLOSESECURECHANNELREQUEST
static void pack_UA_CloseSecureChannelRequest(SV *out, const UA_CloseSecureChannelRequest *in);
static void unpack_UA_CloseSecureChannelRequest(UA_CloseSecureChannelRequest *out, SV *in);

static void
pack_UA_CloseSecureChannelRequest(SV *out, const UA_CloseSecureChannelRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CloseSecureChannelRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	return;
}

static void
unpack_UA_CloseSecureChannelRequest(UA_CloseSecureChannelRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CloseSecureChannelRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSecureChannelRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	return;
}
#endif

/* CloseSecureChannelResponse */
#ifdef UA_TYPES_CLOSESECURECHANNELRESPONSE
static void pack_UA_CloseSecureChannelResponse(SV *out, const UA_CloseSecureChannelResponse *in);
static void unpack_UA_CloseSecureChannelResponse(UA_CloseSecureChannelResponse *out, SV *in);

static void
pack_UA_CloseSecureChannelResponse(SV *out, const UA_CloseSecureChannelResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CloseSecureChannelResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	return;
}

static void
unpack_UA_CloseSecureChannelResponse(UA_CloseSecureChannelResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CloseSecureChannelResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSecureChannelResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	return;
}
#endif

/* SignedSoftwareCertificate */
#ifdef UA_TYPES_SIGNEDSOFTWARECERTIFICATE
static void pack_UA_SignedSoftwareCertificate(SV *out, const UA_SignedSoftwareCertificate *in);
static void unpack_UA_SignedSoftwareCertificate(UA_SignedSoftwareCertificate *out, SV *in);

static void
pack_UA_SignedSoftwareCertificate(SV *out, const UA_SignedSoftwareCertificate *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SignedSoftwareCertificate_certificateData", sv);
	pack_UA_ByteString(sv, &in->certificateData);

	sv = newSV(0);
	hv_stores(hv, "SignedSoftwareCertificate_signature", sv);
	pack_UA_ByteString(sv, &in->signature);

	return;
}

static void
unpack_UA_SignedSoftwareCertificate(UA_SignedSoftwareCertificate *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SignedSoftwareCertificate_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SignedSoftwareCertificate_certificateData", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->certificateData, *svp);

	svp = hv_fetchs(hv, "SignedSoftwareCertificate_signature", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->signature, *svp);

	return;
}
#endif

/* SessionAuthenticationToken */
#ifdef UA_TYPES_SESSIONAUTHENTICATIONTOKEN
static void pack_UA_SessionAuthenticationToken(SV *out, const UA_SessionAuthenticationToken *in);
static void unpack_UA_SessionAuthenticationToken(UA_SessionAuthenticationToken *out, SV *in);

static void
pack_UA_SessionAuthenticationToken(SV *out, const UA_SessionAuthenticationToken *in)
{
	dTHX;
	pack_UA_NodeId(out, in);
}

static void
unpack_UA_SessionAuthenticationToken(UA_SessionAuthenticationToken *out, SV *in)
{
	dTHX;
	unpack_UA_NodeId(out, in);
}
#endif

/* SignatureData */
#ifdef UA_TYPES_SIGNATUREDATA
static void pack_UA_SignatureData(SV *out, const UA_SignatureData *in);
static void unpack_UA_SignatureData(UA_SignatureData *out, SV *in);

static void
pack_UA_SignatureData(SV *out, const UA_SignatureData *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SignatureData_algorithm", sv);
	pack_UA_String(sv, &in->algorithm);

	sv = newSV(0);
	hv_stores(hv, "SignatureData_signature", sv);
	pack_UA_ByteString(sv, &in->signature);

	return;
}

static void
unpack_UA_SignatureData(UA_SignatureData *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SignatureData_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SignatureData_algorithm", 0);
	if (svp != NULL)
		unpack_UA_String(&out->algorithm, *svp);

	svp = hv_fetchs(hv, "SignatureData_signature", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->signature, *svp);

	return;
}
#endif

/* CreateSessionRequest */
#ifdef UA_TYPES_CREATESESSIONREQUEST
static void pack_UA_CreateSessionRequest(SV *out, const UA_CreateSessionRequest *in);
static void unpack_UA_CreateSessionRequest(UA_CreateSessionRequest *out, SV *in);

static void
pack_UA_CreateSessionRequest(SV *out, const UA_CreateSessionRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_clientDescription", sv);
	pack_UA_ApplicationDescription(sv, &in->clientDescription);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_serverUri", sv);
	pack_UA_String(sv, &in->serverUri);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_endpointUrl", sv);
	pack_UA_String(sv, &in->endpointUrl);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_sessionName", sv);
	pack_UA_String(sv, &in->sessionName);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_clientNonce", sv);
	pack_UA_ByteString(sv, &in->clientNonce);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_clientCertificate", sv);
	pack_UA_ByteString(sv, &in->clientCertificate);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_requestedSessionTimeout", sv);
	pack_UA_Double(sv, &in->requestedSessionTimeout);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionRequest_maxResponseMessageSize", sv);
	pack_UA_UInt32(sv, &in->maxResponseMessageSize);

	return;
}

static void
unpack_UA_CreateSessionRequest(UA_CreateSessionRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CreateSessionRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSessionRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_clientDescription", 0);
	if (svp != NULL)
		unpack_UA_ApplicationDescription(&out->clientDescription, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_serverUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->serverUri, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_endpointUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->endpointUrl, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_sessionName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->sessionName, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_clientNonce", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->clientNonce, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_clientCertificate", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->clientCertificate, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_requestedSessionTimeout", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->requestedSessionTimeout, *svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_maxResponseMessageSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxResponseMessageSize, *svp);

	return;
}
#endif

/* CreateSessionResponse */
#ifdef UA_TYPES_CREATESESSIONRESPONSE
static void pack_UA_CreateSessionResponse(SV *out, const UA_CreateSessionResponse *in);
static void unpack_UA_CreateSessionResponse(UA_CreateSessionResponse *out, SV *in);

static void
pack_UA_CreateSessionResponse(SV *out, const UA_CreateSessionResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_sessionId", sv);
	pack_UA_NodeId(sv, &in->sessionId);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_authenticationToken", sv);
	pack_UA_NodeId(sv, &in->authenticationToken);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_revisedSessionTimeout", sv);
	pack_UA_Double(sv, &in->revisedSessionTimeout);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_serverNonce", sv);
	pack_UA_ByteString(sv, &in->serverNonce);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_serverCertificate", sv);
	pack_UA_ByteString(sv, &in->serverCertificate);

	av = newAV();
	hv_stores(hv, "CreateSessionResponse_serverEndpoints", newRV_noinc((SV*)av));
	av_extend(av, in->serverEndpointsSize);
	for (i = 0; i < in->serverEndpointsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EndpointDescription(sv, &in->serverEndpoints[i]);
	}

	av = newAV();
	hv_stores(hv, "CreateSessionResponse_serverSoftwareCertificates", newRV_noinc((SV*)av));
	av_extend(av, in->serverSoftwareCertificatesSize);
	for (i = 0; i < in->serverSoftwareCertificatesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SignedSoftwareCertificate(sv, &in->serverSoftwareCertificates[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_serverSignature", sv);
	pack_UA_SignatureData(sv, &in->serverSignature);

	sv = newSV(0);
	hv_stores(hv, "CreateSessionResponse_maxRequestMessageSize", sv);
	pack_UA_UInt32(sv, &in->maxRequestMessageSize);

	return;
}

static void
unpack_UA_CreateSessionResponse(UA_CreateSessionResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CreateSessionResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSessionResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_sessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->sessionId, *svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_authenticationToken", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->authenticationToken, *svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_revisedSessionTimeout", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->revisedSessionTimeout, *svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_serverNonce", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->serverNonce, *svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_serverCertificate", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->serverCertificate, *svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_serverEndpoints", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CreateSessionResponse_serverEndpoints");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverEndpoints = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out->serverEndpoints == NULL)
			CROAKE("UA_Array_new");
		out->serverEndpointsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EndpointDescription(&out->serverEndpoints[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "CreateSessionResponse_serverSoftwareCertificates", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CreateSessionResponse_serverSoftwareCertificates");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->serverSoftwareCertificates = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIGNEDSOFTWARECERTIFICATE]);
		if (out->serverSoftwareCertificates == NULL)
			CROAKE("UA_Array_new");
		out->serverSoftwareCertificatesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SignedSoftwareCertificate(&out->serverSoftwareCertificates[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "CreateSessionResponse_serverSignature", 0);
	if (svp != NULL)
		unpack_UA_SignatureData(&out->serverSignature, *svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_maxRequestMessageSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxRequestMessageSize, *svp);

	return;
}
#endif

/* UserIdentityToken */
#ifdef UA_TYPES_USERIDENTITYTOKEN
static void pack_UA_UserIdentityToken(SV *out, const UA_UserIdentityToken *in);
static void unpack_UA_UserIdentityToken(UA_UserIdentityToken *out, SV *in);

static void
pack_UA_UserIdentityToken(SV *out, const UA_UserIdentityToken *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UserIdentityToken_policyId", sv);
	pack_UA_String(sv, &in->policyId);

	return;
}

static void
unpack_UA_UserIdentityToken(UA_UserIdentityToken *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UserIdentityToken_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UserIdentityToken_policyId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->policyId, *svp);

	return;
}
#endif

/* AnonymousIdentityToken */
#ifdef UA_TYPES_ANONYMOUSIDENTITYTOKEN
static void pack_UA_AnonymousIdentityToken(SV *out, const UA_AnonymousIdentityToken *in);
static void unpack_UA_AnonymousIdentityToken(UA_AnonymousIdentityToken *out, SV *in);

static void
pack_UA_AnonymousIdentityToken(SV *out, const UA_AnonymousIdentityToken *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AnonymousIdentityToken_policyId", sv);
	pack_UA_String(sv, &in->policyId);

	return;
}

static void
unpack_UA_AnonymousIdentityToken(UA_AnonymousIdentityToken *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AnonymousIdentityToken_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AnonymousIdentityToken_policyId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->policyId, *svp);

	return;
}
#endif

/* UserNameIdentityToken */
#ifdef UA_TYPES_USERNAMEIDENTITYTOKEN
static void pack_UA_UserNameIdentityToken(SV *out, const UA_UserNameIdentityToken *in);
static void unpack_UA_UserNameIdentityToken(UA_UserNameIdentityToken *out, SV *in);

static void
pack_UA_UserNameIdentityToken(SV *out, const UA_UserNameIdentityToken *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UserNameIdentityToken_policyId", sv);
	pack_UA_String(sv, &in->policyId);

	sv = newSV(0);
	hv_stores(hv, "UserNameIdentityToken_userName", sv);
	pack_UA_String(sv, &in->userName);

	sv = newSV(0);
	hv_stores(hv, "UserNameIdentityToken_password", sv);
	pack_UA_ByteString(sv, &in->password);

	sv = newSV(0);
	hv_stores(hv, "UserNameIdentityToken_encryptionAlgorithm", sv);
	pack_UA_String(sv, &in->encryptionAlgorithm);

	return;
}

static void
unpack_UA_UserNameIdentityToken(UA_UserNameIdentityToken *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UserNameIdentityToken_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UserNameIdentityToken_policyId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->policyId, *svp);

	svp = hv_fetchs(hv, "UserNameIdentityToken_userName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->userName, *svp);

	svp = hv_fetchs(hv, "UserNameIdentityToken_password", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->password, *svp);

	svp = hv_fetchs(hv, "UserNameIdentityToken_encryptionAlgorithm", 0);
	if (svp != NULL)
		unpack_UA_String(&out->encryptionAlgorithm, *svp);

	return;
}
#endif

/* X509IdentityToken */
#ifdef UA_TYPES_X509IDENTITYTOKEN
static void pack_UA_X509IdentityToken(SV *out, const UA_X509IdentityToken *in);
static void unpack_UA_X509IdentityToken(UA_X509IdentityToken *out, SV *in);

static void
pack_UA_X509IdentityToken(SV *out, const UA_X509IdentityToken *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "X509IdentityToken_policyId", sv);
	pack_UA_String(sv, &in->policyId);

	sv = newSV(0);
	hv_stores(hv, "X509IdentityToken_certificateData", sv);
	pack_UA_ByteString(sv, &in->certificateData);

	return;
}

static void
unpack_UA_X509IdentityToken(UA_X509IdentityToken *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_X509IdentityToken_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "X509IdentityToken_policyId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->policyId, *svp);

	svp = hv_fetchs(hv, "X509IdentityToken_certificateData", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->certificateData, *svp);

	return;
}
#endif

/* IssuedIdentityToken */
#ifdef UA_TYPES_ISSUEDIDENTITYTOKEN
static void pack_UA_IssuedIdentityToken(SV *out, const UA_IssuedIdentityToken *in);
static void unpack_UA_IssuedIdentityToken(UA_IssuedIdentityToken *out, SV *in);

static void
pack_UA_IssuedIdentityToken(SV *out, const UA_IssuedIdentityToken *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "IssuedIdentityToken_policyId", sv);
	pack_UA_String(sv, &in->policyId);

	sv = newSV(0);
	hv_stores(hv, "IssuedIdentityToken_tokenData", sv);
	pack_UA_ByteString(sv, &in->tokenData);

	sv = newSV(0);
	hv_stores(hv, "IssuedIdentityToken_encryptionAlgorithm", sv);
	pack_UA_String(sv, &in->encryptionAlgorithm);

	return;
}

static void
unpack_UA_IssuedIdentityToken(UA_IssuedIdentityToken *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_IssuedIdentityToken_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "IssuedIdentityToken_policyId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->policyId, *svp);

	svp = hv_fetchs(hv, "IssuedIdentityToken_tokenData", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->tokenData, *svp);

	svp = hv_fetchs(hv, "IssuedIdentityToken_encryptionAlgorithm", 0);
	if (svp != NULL)
		unpack_UA_String(&out->encryptionAlgorithm, *svp);

	return;
}
#endif

/* RsaEncryptedSecret */
#ifdef UA_TYPES_RSAENCRYPTEDSECRET
static void pack_UA_RsaEncryptedSecret(SV *out, const UA_RsaEncryptedSecret *in);
static void unpack_UA_RsaEncryptedSecret(UA_RsaEncryptedSecret *out, SV *in);

static void
pack_UA_RsaEncryptedSecret(SV *out, const UA_RsaEncryptedSecret *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_RsaEncryptedSecret(UA_RsaEncryptedSecret *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* EccEncryptedSecret */
#ifdef UA_TYPES_ECCENCRYPTEDSECRET
static void pack_UA_EccEncryptedSecret(SV *out, const UA_EccEncryptedSecret *in);
static void unpack_UA_EccEncryptedSecret(UA_EccEncryptedSecret *out, SV *in);

static void
pack_UA_EccEncryptedSecret(SV *out, const UA_EccEncryptedSecret *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_EccEncryptedSecret(UA_EccEncryptedSecret *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* ActivateSessionRequest */
#ifdef UA_TYPES_ACTIVATESESSIONREQUEST
static void pack_UA_ActivateSessionRequest(SV *out, const UA_ActivateSessionRequest *in);
static void unpack_UA_ActivateSessionRequest(UA_ActivateSessionRequest *out, SV *in);

static void
pack_UA_ActivateSessionRequest(SV *out, const UA_ActivateSessionRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ActivateSessionRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "ActivateSessionRequest_clientSignature", sv);
	pack_UA_SignatureData(sv, &in->clientSignature);

	av = newAV();
	hv_stores(hv, "ActivateSessionRequest_clientSoftwareCertificates", newRV_noinc((SV*)av));
	av_extend(av, in->clientSoftwareCertificatesSize);
	for (i = 0; i < in->clientSoftwareCertificatesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SignedSoftwareCertificate(sv, &in->clientSoftwareCertificates[i]);
	}

	av = newAV();
	hv_stores(hv, "ActivateSessionRequest_localeIds", newRV_noinc((SV*)av));
	av_extend(av, in->localeIdsSize);
	for (i = 0; i < in->localeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->localeIds[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ActivateSessionRequest_userIdentityToken", sv);
	pack_UA_ExtensionObject(sv, &in->userIdentityToken);

	sv = newSV(0);
	hv_stores(hv, "ActivateSessionRequest_userTokenSignature", sv);
	pack_UA_SignatureData(sv, &in->userTokenSignature);

	return;
}

static void
unpack_UA_ActivateSessionRequest(UA_ActivateSessionRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ActivateSessionRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ActivateSessionRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "ActivateSessionRequest_clientSignature", 0);
	if (svp != NULL)
		unpack_UA_SignatureData(&out->clientSignature, *svp);

	svp = hv_fetchs(hv, "ActivateSessionRequest_clientSoftwareCertificates", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ActivateSessionRequest_clientSoftwareCertificates");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->clientSoftwareCertificates = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIGNEDSOFTWARECERTIFICATE]);
		if (out->clientSoftwareCertificates == NULL)
			CROAKE("UA_Array_new");
		out->clientSoftwareCertificatesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SignedSoftwareCertificate(&out->clientSoftwareCertificates[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ActivateSessionRequest_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ActivateSessionRequest_localeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->localeIds == NULL)
			CROAKE("UA_Array_new");
		out->localeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->localeIds[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ActivateSessionRequest_userIdentityToken", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->userIdentityToken, *svp);

	svp = hv_fetchs(hv, "ActivateSessionRequest_userTokenSignature", 0);
	if (svp != NULL)
		unpack_UA_SignatureData(&out->userTokenSignature, *svp);

	return;
}
#endif

/* ActivateSessionResponse */
#ifdef UA_TYPES_ACTIVATESESSIONRESPONSE
static void pack_UA_ActivateSessionResponse(SV *out, const UA_ActivateSessionResponse *in);
static void unpack_UA_ActivateSessionResponse(UA_ActivateSessionResponse *out, SV *in);

static void
pack_UA_ActivateSessionResponse(SV *out, const UA_ActivateSessionResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ActivateSessionResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "ActivateSessionResponse_serverNonce", sv);
	pack_UA_ByteString(sv, &in->serverNonce);

	av = newAV();
	hv_stores(hv, "ActivateSessionResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "ActivateSessionResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_ActivateSessionResponse(UA_ActivateSessionResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ActivateSessionResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ActivateSessionResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "ActivateSessionResponse_serverNonce", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->serverNonce, *svp);

	svp = hv_fetchs(hv, "ActivateSessionResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ActivateSessionResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ActivateSessionResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ActivateSessionResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* CloseSessionRequest */
#ifdef UA_TYPES_CLOSESESSIONREQUEST
static void pack_UA_CloseSessionRequest(SV *out, const UA_CloseSessionRequest *in);
static void unpack_UA_CloseSessionRequest(UA_CloseSessionRequest *out, SV *in);

static void
pack_UA_CloseSessionRequest(SV *out, const UA_CloseSessionRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CloseSessionRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "CloseSessionRequest_deleteSubscriptions", sv);
	pack_UA_Boolean(sv, &in->deleteSubscriptions);

	return;
}

static void
unpack_UA_CloseSessionRequest(UA_CloseSessionRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CloseSessionRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSessionRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "CloseSessionRequest_deleteSubscriptions", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->deleteSubscriptions, *svp);

	return;
}
#endif

/* CloseSessionResponse */
#ifdef UA_TYPES_CLOSESESSIONRESPONSE
static void pack_UA_CloseSessionResponse(SV *out, const UA_CloseSessionResponse *in);
static void unpack_UA_CloseSessionResponse(UA_CloseSessionResponse *out, SV *in);

static void
pack_UA_CloseSessionResponse(SV *out, const UA_CloseSessionResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CloseSessionResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	return;
}

static void
unpack_UA_CloseSessionResponse(UA_CloseSessionResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CloseSessionResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSessionResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	return;
}
#endif

/* CancelRequest */
#ifdef UA_TYPES_CANCELREQUEST
static void pack_UA_CancelRequest(SV *out, const UA_CancelRequest *in);
static void unpack_UA_CancelRequest(UA_CancelRequest *out, SV *in);

static void
pack_UA_CancelRequest(SV *out, const UA_CancelRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CancelRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "CancelRequest_requestHandle", sv);
	pack_UA_UInt32(sv, &in->requestHandle);

	return;
}

static void
unpack_UA_CancelRequest(UA_CancelRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CancelRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CancelRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "CancelRequest_requestHandle", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestHandle, *svp);

	return;
}
#endif

/* CancelResponse */
#ifdef UA_TYPES_CANCELRESPONSE
static void pack_UA_CancelResponse(SV *out, const UA_CancelResponse *in);
static void unpack_UA_CancelResponse(UA_CancelResponse *out, SV *in);

static void
pack_UA_CancelResponse(SV *out, const UA_CancelResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CancelResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "CancelResponse_cancelCount", sv);
	pack_UA_UInt32(sv, &in->cancelCount);

	return;
}

static void
unpack_UA_CancelResponse(UA_CancelResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CancelResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CancelResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "CancelResponse_cancelCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->cancelCount, *svp);

	return;
}
#endif

/* NodeAttributesMask */
#ifdef UA_TYPES_NODEATTRIBUTESMASK
static void pack_UA_NodeAttributesMask(SV *out, const UA_NodeAttributesMask *in);
static void unpack_UA_NodeAttributesMask(UA_NodeAttributesMask *out, SV *in);

static void
pack_UA_NodeAttributesMask(SV *out, const UA_NodeAttributesMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_NodeAttributesMask(UA_NodeAttributesMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* NodeAttributes */
#ifdef UA_TYPES_NODEATTRIBUTES
static void pack_UA_NodeAttributes(SV *out, const UA_NodeAttributes *in);
static void unpack_UA_NodeAttributes(UA_NodeAttributes *out, SV *in);

static void
pack_UA_NodeAttributes(SV *out, const UA_NodeAttributes *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NodeAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "NodeAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "NodeAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "NodeAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "NodeAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	return;
}

static void
unpack_UA_NodeAttributes(UA_NodeAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NodeAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NodeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "NodeAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "NodeAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "NodeAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "NodeAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	return;
}
#endif

/* ObjectAttributes */
#ifdef UA_TYPES_OBJECTATTRIBUTES
static void pack_UA_ObjectAttributes(SV *out, const UA_ObjectAttributes *in);
static void unpack_UA_ObjectAttributes(UA_ObjectAttributes *out, SV *in);

static void
pack_UA_ObjectAttributes(SV *out, const UA_ObjectAttributes *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ObjectAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "ObjectAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "ObjectAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "ObjectAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "ObjectAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "ObjectAttributes_eventNotifier", sv);
	pack_UA_Byte(sv, &in->eventNotifier);

	return;
}

static void
unpack_UA_ObjectAttributes(UA_ObjectAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ObjectAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ObjectAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "ObjectAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "ObjectAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "ObjectAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "ObjectAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "ObjectAttributes_eventNotifier", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->eventNotifier, *svp);

	return;
}
#endif

/* VariableAttributes */
#ifdef UA_TYPES_VARIABLEATTRIBUTES
static void pack_UA_VariableAttributes(SV *out, const UA_VariableAttributes *in);
static void unpack_UA_VariableAttributes(UA_VariableAttributes *out, SV *in);

static void
pack_UA_VariableAttributes(SV *out, const UA_VariableAttributes *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_value", sv);
	pack_UA_Variant(sv, &in->value);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_dataType", sv);
	pack_UA_NodeId(sv, &in->dataType);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_valueRank", sv);
	pack_UA_Int32(sv, &in->valueRank);

	av = newAV();
	hv_stores(hv, "VariableAttributes_arrayDimensions", newRV_noinc((SV*)av));
	av_extend(av, in->arrayDimensionsSize);
	for (i = 0; i < in->arrayDimensionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->arrayDimensions[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_accessLevel", sv);
	pack_UA_Byte(sv, &in->accessLevel);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_userAccessLevel", sv);
	pack_UA_Byte(sv, &in->userAccessLevel);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_minimumSamplingInterval", sv);
	pack_UA_Double(sv, &in->minimumSamplingInterval);

	sv = newSV(0);
	hv_stores(hv, "VariableAttributes_historizing", sv);
	pack_UA_Boolean(sv, &in->historizing);

	return;
}

static void
unpack_UA_VariableAttributes(UA_VariableAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_VariableAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "VariableAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_value", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->value, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_dataType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataType, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_valueRank", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->valueRank, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for VariableAttributes_arrayDimensions");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->arrayDimensions == NULL)
			CROAKE("UA_Array_new");
		out->arrayDimensionsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->arrayDimensions[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "VariableAttributes_accessLevel", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->accessLevel, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_userAccessLevel", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->userAccessLevel, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_minimumSamplingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->minimumSamplingInterval, *svp);

	svp = hv_fetchs(hv, "VariableAttributes_historizing", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->historizing, *svp);

	return;
}
#endif

/* MethodAttributes */
#ifdef UA_TYPES_METHODATTRIBUTES
static void pack_UA_MethodAttributes(SV *out, const UA_MethodAttributes *in);
static void unpack_UA_MethodAttributes(UA_MethodAttributes *out, SV *in);

static void
pack_UA_MethodAttributes(SV *out, const UA_MethodAttributes *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MethodAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "MethodAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "MethodAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "MethodAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "MethodAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "MethodAttributes_executable", sv);
	pack_UA_Boolean(sv, &in->executable);

	sv = newSV(0);
	hv_stores(hv, "MethodAttributes_userExecutable", sv);
	pack_UA_Boolean(sv, &in->userExecutable);

	return;
}

static void
unpack_UA_MethodAttributes(UA_MethodAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MethodAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MethodAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "MethodAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "MethodAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "MethodAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "MethodAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "MethodAttributes_executable", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->executable, *svp);

	svp = hv_fetchs(hv, "MethodAttributes_userExecutable", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->userExecutable, *svp);

	return;
}
#endif

/* ObjectTypeAttributes */
#ifdef UA_TYPES_OBJECTTYPEATTRIBUTES
static void pack_UA_ObjectTypeAttributes(SV *out, const UA_ObjectTypeAttributes *in);
static void unpack_UA_ObjectTypeAttributes(UA_ObjectTypeAttributes *out, SV *in);

static void
pack_UA_ObjectTypeAttributes(SV *out, const UA_ObjectTypeAttributes *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ObjectTypeAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "ObjectTypeAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "ObjectTypeAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "ObjectTypeAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "ObjectTypeAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "ObjectTypeAttributes_isAbstract", sv);
	pack_UA_Boolean(sv, &in->isAbstract);

	return;
}

static void
unpack_UA_ObjectTypeAttributes(UA_ObjectTypeAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ObjectTypeAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isAbstract, *svp);

	return;
}
#endif

/* VariableTypeAttributes */
#ifdef UA_TYPES_VARIABLETYPEATTRIBUTES
static void pack_UA_VariableTypeAttributes(SV *out, const UA_VariableTypeAttributes *in);
static void unpack_UA_VariableTypeAttributes(UA_VariableTypeAttributes *out, SV *in);

static void
pack_UA_VariableTypeAttributes(SV *out, const UA_VariableTypeAttributes *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_value", sv);
	pack_UA_Variant(sv, &in->value);

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_dataType", sv);
	pack_UA_NodeId(sv, &in->dataType);

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_valueRank", sv);
	pack_UA_Int32(sv, &in->valueRank);

	av = newAV();
	hv_stores(hv, "VariableTypeAttributes_arrayDimensions", newRV_noinc((SV*)av));
	av_extend(av, in->arrayDimensionsSize);
	for (i = 0; i < in->arrayDimensionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->arrayDimensions[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "VariableTypeAttributes_isAbstract", sv);
	pack_UA_Boolean(sv, &in->isAbstract);

	return;
}

static void
unpack_UA_VariableTypeAttributes(UA_VariableTypeAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_VariableTypeAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "VariableTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_value", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->value, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_dataType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataType, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_valueRank", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->valueRank, *svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for VariableTypeAttributes_arrayDimensions");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->arrayDimensions == NULL)
			CROAKE("UA_Array_new");
		out->arrayDimensionsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->arrayDimensions[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "VariableTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isAbstract, *svp);

	return;
}
#endif

/* ReferenceTypeAttributes */
#ifdef UA_TYPES_REFERENCETYPEATTRIBUTES
static void pack_UA_ReferenceTypeAttributes(SV *out, const UA_ReferenceTypeAttributes *in);
static void unpack_UA_ReferenceTypeAttributes(UA_ReferenceTypeAttributes *out, SV *in);

static void
pack_UA_ReferenceTypeAttributes(SV *out, const UA_ReferenceTypeAttributes *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_isAbstract", sv);
	pack_UA_Boolean(sv, &in->isAbstract);

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_symmetric", sv);
	pack_UA_Boolean(sv, &in->symmetric);

	sv = newSV(0);
	hv_stores(hv, "ReferenceTypeAttributes_inverseName", sv);
	pack_UA_LocalizedText(sv, &in->inverseName);

	return;
}

static void
unpack_UA_ReferenceTypeAttributes(UA_ReferenceTypeAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReferenceTypeAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isAbstract, *svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_symmetric", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->symmetric, *svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_inverseName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->inverseName, *svp);

	return;
}
#endif

/* DataTypeAttributes */
#ifdef UA_TYPES_DATATYPEATTRIBUTES
static void pack_UA_DataTypeAttributes(SV *out, const UA_DataTypeAttributes *in);
static void unpack_UA_DataTypeAttributes(UA_DataTypeAttributes *out, SV *in);

static void
pack_UA_DataTypeAttributes(SV *out, const UA_DataTypeAttributes *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DataTypeAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "DataTypeAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "DataTypeAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "DataTypeAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "DataTypeAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "DataTypeAttributes_isAbstract", sv);
	pack_UA_Boolean(sv, &in->isAbstract);

	return;
}

static void
unpack_UA_DataTypeAttributes(UA_DataTypeAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataTypeAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isAbstract, *svp);

	return;
}
#endif

/* ViewAttributes */
#ifdef UA_TYPES_VIEWATTRIBUTES
static void pack_UA_ViewAttributes(SV *out, const UA_ViewAttributes *in);
static void unpack_UA_ViewAttributes(UA_ViewAttributes *out, SV *in);

static void
pack_UA_ViewAttributes(SV *out, const UA_ViewAttributes *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ViewAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "ViewAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "ViewAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "ViewAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "ViewAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	sv = newSV(0);
	hv_stores(hv, "ViewAttributes_containsNoLoops", sv);
	pack_UA_Boolean(sv, &in->containsNoLoops);

	sv = newSV(0);
	hv_stores(hv, "ViewAttributes_eventNotifier", sv);
	pack_UA_Byte(sv, &in->eventNotifier);

	return;
}

static void
unpack_UA_ViewAttributes(UA_ViewAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ViewAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ViewAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "ViewAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "ViewAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "ViewAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "ViewAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "ViewAttributes_containsNoLoops", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->containsNoLoops, *svp);

	svp = hv_fetchs(hv, "ViewAttributes_eventNotifier", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->eventNotifier, *svp);

	return;
}
#endif

/* GenericAttributeValue */
#ifdef UA_TYPES_GENERICATTRIBUTEVALUE
static void pack_UA_GenericAttributeValue(SV *out, const UA_GenericAttributeValue *in);
static void unpack_UA_GenericAttributeValue(UA_GenericAttributeValue *out, SV *in);

static void
pack_UA_GenericAttributeValue(SV *out, const UA_GenericAttributeValue *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "GenericAttributeValue_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "GenericAttributeValue_value", sv);
	pack_UA_Variant(sv, &in->value);

	return;
}

static void
unpack_UA_GenericAttributeValue(UA_GenericAttributeValue *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_GenericAttributeValue_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GenericAttributeValue_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "GenericAttributeValue_value", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->value, *svp);

	return;
}
#endif

/* GenericAttributes */
#ifdef UA_TYPES_GENERICATTRIBUTES
static void pack_UA_GenericAttributes(SV *out, const UA_GenericAttributes *in);
static void unpack_UA_GenericAttributes(UA_GenericAttributes *out, SV *in);

static void
pack_UA_GenericAttributes(SV *out, const UA_GenericAttributes *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "GenericAttributes_specifiedAttributes", sv);
	pack_UA_UInt32(sv, &in->specifiedAttributes);

	sv = newSV(0);
	hv_stores(hv, "GenericAttributes_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "GenericAttributes_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "GenericAttributes_writeMask", sv);
	pack_UA_UInt32(sv, &in->writeMask);

	sv = newSV(0);
	hv_stores(hv, "GenericAttributes_userWriteMask", sv);
	pack_UA_UInt32(sv, &in->userWriteMask);

	av = newAV();
	hv_stores(hv, "GenericAttributes_attributeValues", newRV_noinc((SV*)av));
	av_extend(av, in->attributeValuesSize);
	for (i = 0; i < in->attributeValuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_GenericAttributeValue(sv, &in->attributeValues[i]);
	}

	return;
}

static void
unpack_UA_GenericAttributes(UA_GenericAttributes *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_GenericAttributes_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GenericAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->specifiedAttributes, *svp);

	svp = hv_fetchs(hv, "GenericAttributes_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "GenericAttributes_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "GenericAttributes_writeMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->writeMask, *svp);

	svp = hv_fetchs(hv, "GenericAttributes_userWriteMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->userWriteMask, *svp);

	svp = hv_fetchs(hv, "GenericAttributes_attributeValues", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for GenericAttributes_attributeValues");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->attributeValues = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_GENERICATTRIBUTEVALUE]);
		if (out->attributeValues == NULL)
			CROAKE("UA_Array_new");
		out->attributeValuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_GenericAttributeValue(&out->attributeValues[i], *svp);
		}
	}

	return;
}
#endif

/* AddNodesItem */
#ifdef UA_TYPES_ADDNODESITEM
static void pack_UA_AddNodesItem(SV *out, const UA_AddNodesItem *in);
static void unpack_UA_AddNodesItem(UA_AddNodesItem *out, SV *in);

static void
pack_UA_AddNodesItem(SV *out, const UA_AddNodesItem *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AddNodesItem_parentNodeId", sv);
	pack_UA_ExpandedNodeId(sv, &in->parentNodeId);

	sv = newSV(0);
	hv_stores(hv, "AddNodesItem_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "AddNodesItem_requestedNewNodeId", sv);
	pack_UA_ExpandedNodeId(sv, &in->requestedNewNodeId);

	sv = newSV(0);
	hv_stores(hv, "AddNodesItem_browseName", sv);
	pack_UA_QualifiedName(sv, &in->browseName);

	sv = newSV(0);
	hv_stores(hv, "AddNodesItem_nodeClass", sv);
	pack_UA_NodeClass(sv, &in->nodeClass);

	sv = newSV(0);
	hv_stores(hv, "AddNodesItem_nodeAttributes", sv);
	pack_UA_ExtensionObject(sv, &in->nodeAttributes);

	sv = newSV(0);
	hv_stores(hv, "AddNodesItem_typeDefinition", sv);
	pack_UA_ExpandedNodeId(sv, &in->typeDefinition);

	return;
}

static void
unpack_UA_AddNodesItem(UA_AddNodesItem *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AddNodesItem_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesItem_parentNodeId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->parentNodeId, *svp);

	svp = hv_fetchs(hv, "AddNodesItem_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "AddNodesItem_requestedNewNodeId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->requestedNewNodeId, *svp);

	svp = hv_fetchs(hv, "AddNodesItem_browseName", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->browseName, *svp);

	svp = hv_fetchs(hv, "AddNodesItem_nodeClass", 0);
	if (svp != NULL)
		unpack_UA_NodeClass(&out->nodeClass, *svp);

	svp = hv_fetchs(hv, "AddNodesItem_nodeAttributes", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->nodeAttributes, *svp);

	svp = hv_fetchs(hv, "AddNodesItem_typeDefinition", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->typeDefinition, *svp);

	return;
}
#endif

/* AddNodesResult */
#ifdef UA_TYPES_ADDNODESRESULT
static void pack_UA_AddNodesResult(SV *out, const UA_AddNodesResult *in);
static void unpack_UA_AddNodesResult(UA_AddNodesResult *out, SV *in);

static void
pack_UA_AddNodesResult(SV *out, const UA_AddNodesResult *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AddNodesResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	sv = newSV(0);
	hv_stores(hv, "AddNodesResult_addedNodeId", sv);
	pack_UA_NodeId(sv, &in->addedNodeId);

	return;
}

static void
unpack_UA_AddNodesResult(UA_AddNodesResult *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AddNodesResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "AddNodesResult_addedNodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->addedNodeId, *svp);

	return;
}
#endif

/* AddNodesRequest */
#ifdef UA_TYPES_ADDNODESREQUEST
static void pack_UA_AddNodesRequest(SV *out, const UA_AddNodesRequest *in);
static void unpack_UA_AddNodesRequest(UA_AddNodesRequest *out, SV *in);

static void
pack_UA_AddNodesRequest(SV *out, const UA_AddNodesRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AddNodesRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "AddNodesRequest_nodesToAdd", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToAddSize);
	for (i = 0; i < in->nodesToAddSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_AddNodesItem(sv, &in->nodesToAdd[i]);
	}

	return;
}

static void
unpack_UA_AddNodesRequest(UA_AddNodesRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AddNodesRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "AddNodesRequest_nodesToAdd", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AddNodesRequest_nodesToAdd");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToAdd = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ADDNODESITEM]);
		if (out->nodesToAdd == NULL)
			CROAKE("UA_Array_new");
		out->nodesToAddSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_AddNodesItem(&out->nodesToAdd[i], *svp);
		}
	}

	return;
}
#endif

/* AddNodesResponse */
#ifdef UA_TYPES_ADDNODESRESPONSE
static void pack_UA_AddNodesResponse(SV *out, const UA_AddNodesResponse *in);
static void unpack_UA_AddNodesResponse(UA_AddNodesResponse *out, SV *in);

static void
pack_UA_AddNodesResponse(SV *out, const UA_AddNodesResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AddNodesResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "AddNodesResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_AddNodesResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "AddNodesResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_AddNodesResponse(UA_AddNodesResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AddNodesResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "AddNodesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AddNodesResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ADDNODESRESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_AddNodesResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "AddNodesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AddNodesResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* AddReferencesItem */
#ifdef UA_TYPES_ADDREFERENCESITEM
static void pack_UA_AddReferencesItem(SV *out, const UA_AddReferencesItem *in);
static void unpack_UA_AddReferencesItem(UA_AddReferencesItem *out, SV *in);

static void
pack_UA_AddReferencesItem(SV *out, const UA_AddReferencesItem *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AddReferencesItem_sourceNodeId", sv);
	pack_UA_NodeId(sv, &in->sourceNodeId);

	sv = newSV(0);
	hv_stores(hv, "AddReferencesItem_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "AddReferencesItem_isForward", sv);
	pack_UA_Boolean(sv, &in->isForward);

	sv = newSV(0);
	hv_stores(hv, "AddReferencesItem_targetServerUri", sv);
	pack_UA_String(sv, &in->targetServerUri);

	sv = newSV(0);
	hv_stores(hv, "AddReferencesItem_targetNodeId", sv);
	pack_UA_ExpandedNodeId(sv, &in->targetNodeId);

	sv = newSV(0);
	hv_stores(hv, "AddReferencesItem_targetNodeClass", sv);
	pack_UA_NodeClass(sv, &in->targetNodeClass);

	return;
}

static void
unpack_UA_AddReferencesItem(UA_AddReferencesItem *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AddReferencesItem_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddReferencesItem_sourceNodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->sourceNodeId, *svp);

	svp = hv_fetchs(hv, "AddReferencesItem_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "AddReferencesItem_isForward", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isForward, *svp);

	svp = hv_fetchs(hv, "AddReferencesItem_targetServerUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->targetServerUri, *svp);

	svp = hv_fetchs(hv, "AddReferencesItem_targetNodeId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->targetNodeId, *svp);

	svp = hv_fetchs(hv, "AddReferencesItem_targetNodeClass", 0);
	if (svp != NULL)
		unpack_UA_NodeClass(&out->targetNodeClass, *svp);

	return;
}
#endif

/* AddReferencesRequest */
#ifdef UA_TYPES_ADDREFERENCESREQUEST
static void pack_UA_AddReferencesRequest(SV *out, const UA_AddReferencesRequest *in);
static void unpack_UA_AddReferencesRequest(UA_AddReferencesRequest *out, SV *in);

static void
pack_UA_AddReferencesRequest(SV *out, const UA_AddReferencesRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AddReferencesRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "AddReferencesRequest_referencesToAdd", newRV_noinc((SV*)av));
	av_extend(av, in->referencesToAddSize);
	for (i = 0; i < in->referencesToAddSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_AddReferencesItem(sv, &in->referencesToAdd[i]);
	}

	return;
}

static void
unpack_UA_AddReferencesRequest(UA_AddReferencesRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AddReferencesRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddReferencesRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "AddReferencesRequest_referencesToAdd", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AddReferencesRequest_referencesToAdd");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->referencesToAdd = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ADDREFERENCESITEM]);
		if (out->referencesToAdd == NULL)
			CROAKE("UA_Array_new");
		out->referencesToAddSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_AddReferencesItem(&out->referencesToAdd[i], *svp);
		}
	}

	return;
}
#endif

/* AddReferencesResponse */
#ifdef UA_TYPES_ADDREFERENCESRESPONSE
static void pack_UA_AddReferencesResponse(SV *out, const UA_AddReferencesResponse *in);
static void unpack_UA_AddReferencesResponse(UA_AddReferencesResponse *out, SV *in);

static void
pack_UA_AddReferencesResponse(SV *out, const UA_AddReferencesResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AddReferencesResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "AddReferencesResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "AddReferencesResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_AddReferencesResponse(UA_AddReferencesResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AddReferencesResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddReferencesResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "AddReferencesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AddReferencesResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "AddReferencesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AddReferencesResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteNodesItem */
#ifdef UA_TYPES_DELETENODESITEM
static void pack_UA_DeleteNodesItem(SV *out, const UA_DeleteNodesItem *in);
static void unpack_UA_DeleteNodesItem(UA_DeleteNodesItem *out, SV *in);

static void
pack_UA_DeleteNodesItem(SV *out, const UA_DeleteNodesItem *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteNodesItem_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "DeleteNodesItem_deleteTargetReferences", sv);
	pack_UA_Boolean(sv, &in->deleteTargetReferences);

	return;
}

static void
unpack_UA_DeleteNodesItem(UA_DeleteNodesItem *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteNodesItem_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteNodesItem_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "DeleteNodesItem_deleteTargetReferences", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->deleteTargetReferences, *svp);

	return;
}
#endif

/* DeleteNodesRequest */
#ifdef UA_TYPES_DELETENODESREQUEST
static void pack_UA_DeleteNodesRequest(SV *out, const UA_DeleteNodesRequest *in);
static void unpack_UA_DeleteNodesRequest(UA_DeleteNodesRequest *out, SV *in);

static void
pack_UA_DeleteNodesRequest(SV *out, const UA_DeleteNodesRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteNodesRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "DeleteNodesRequest_nodesToDelete", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToDeleteSize);
	for (i = 0; i < in->nodesToDeleteSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DeleteNodesItem(sv, &in->nodesToDelete[i]);
	}

	return;
}

static void
unpack_UA_DeleteNodesRequest(UA_DeleteNodesRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteNodesRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteNodesRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "DeleteNodesRequest_nodesToDelete", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteNodesRequest_nodesToDelete");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToDelete = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DELETENODESITEM]);
		if (out->nodesToDelete == NULL)
			CROAKE("UA_Array_new");
		out->nodesToDeleteSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DeleteNodesItem(&out->nodesToDelete[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteNodesResponse */
#ifdef UA_TYPES_DELETENODESRESPONSE
static void pack_UA_DeleteNodesResponse(SV *out, const UA_DeleteNodesResponse *in);
static void unpack_UA_DeleteNodesResponse(UA_DeleteNodesResponse *out, SV *in);

static void
pack_UA_DeleteNodesResponse(SV *out, const UA_DeleteNodesResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteNodesResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "DeleteNodesResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "DeleteNodesResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_DeleteNodesResponse(UA_DeleteNodesResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteNodesResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteNodesResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "DeleteNodesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteNodesResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DeleteNodesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteNodesResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteReferencesItem */
#ifdef UA_TYPES_DELETEREFERENCESITEM
static void pack_UA_DeleteReferencesItem(SV *out, const UA_DeleteReferencesItem *in);
static void unpack_UA_DeleteReferencesItem(UA_DeleteReferencesItem *out, SV *in);

static void
pack_UA_DeleteReferencesItem(SV *out, const UA_DeleteReferencesItem *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteReferencesItem_sourceNodeId", sv);
	pack_UA_NodeId(sv, &in->sourceNodeId);

	sv = newSV(0);
	hv_stores(hv, "DeleteReferencesItem_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "DeleteReferencesItem_isForward", sv);
	pack_UA_Boolean(sv, &in->isForward);

	sv = newSV(0);
	hv_stores(hv, "DeleteReferencesItem_targetNodeId", sv);
	pack_UA_ExpandedNodeId(sv, &in->targetNodeId);

	sv = newSV(0);
	hv_stores(hv, "DeleteReferencesItem_deleteBidirectional", sv);
	pack_UA_Boolean(sv, &in->deleteBidirectional);

	return;
}

static void
unpack_UA_DeleteReferencesItem(UA_DeleteReferencesItem *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteReferencesItem_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteReferencesItem_sourceNodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->sourceNodeId, *svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_isForward", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isForward, *svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_targetNodeId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->targetNodeId, *svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_deleteBidirectional", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->deleteBidirectional, *svp);

	return;
}
#endif

/* DeleteReferencesRequest */
#ifdef UA_TYPES_DELETEREFERENCESREQUEST
static void pack_UA_DeleteReferencesRequest(SV *out, const UA_DeleteReferencesRequest *in);
static void unpack_UA_DeleteReferencesRequest(UA_DeleteReferencesRequest *out, SV *in);

static void
pack_UA_DeleteReferencesRequest(SV *out, const UA_DeleteReferencesRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteReferencesRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "DeleteReferencesRequest_referencesToDelete", newRV_noinc((SV*)av));
	av_extend(av, in->referencesToDeleteSize);
	for (i = 0; i < in->referencesToDeleteSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DeleteReferencesItem(sv, &in->referencesToDelete[i]);
	}

	return;
}

static void
unpack_UA_DeleteReferencesRequest(UA_DeleteReferencesRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteReferencesRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteReferencesRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "DeleteReferencesRequest_referencesToDelete", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteReferencesRequest_referencesToDelete");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->referencesToDelete = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DELETEREFERENCESITEM]);
		if (out->referencesToDelete == NULL)
			CROAKE("UA_Array_new");
		out->referencesToDeleteSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DeleteReferencesItem(&out->referencesToDelete[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteReferencesResponse */
#ifdef UA_TYPES_DELETEREFERENCESRESPONSE
static void pack_UA_DeleteReferencesResponse(SV *out, const UA_DeleteReferencesResponse *in);
static void unpack_UA_DeleteReferencesResponse(UA_DeleteReferencesResponse *out, SV *in);

static void
pack_UA_DeleteReferencesResponse(SV *out, const UA_DeleteReferencesResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteReferencesResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "DeleteReferencesResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "DeleteReferencesResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_DeleteReferencesResponse(UA_DeleteReferencesResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteReferencesResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteReferencesResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "DeleteReferencesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteReferencesResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DeleteReferencesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteReferencesResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* AttributeWriteMask */
#ifdef UA_TYPES_ATTRIBUTEWRITEMASK
static void pack_UA_AttributeWriteMask(SV *out, const UA_AttributeWriteMask *in);
static void unpack_UA_AttributeWriteMask(UA_AttributeWriteMask *out, SV *in);

static void
pack_UA_AttributeWriteMask(SV *out, const UA_AttributeWriteMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_AttributeWriteMask(UA_AttributeWriteMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* BrowseDirection */
#ifdef UA_TYPES_BROWSEDIRECTION
static void pack_UA_BrowseDirection(SV *out, const UA_BrowseDirection *in);
static void unpack_UA_BrowseDirection(UA_BrowseDirection *out, SV *in);

static void
pack_UA_BrowseDirection(SV *out, const UA_BrowseDirection *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_BrowseDirection(UA_BrowseDirection *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ViewDescription */
#ifdef UA_TYPES_VIEWDESCRIPTION
static void pack_UA_ViewDescription(SV *out, const UA_ViewDescription *in);
static void unpack_UA_ViewDescription(UA_ViewDescription *out, SV *in);

static void
pack_UA_ViewDescription(SV *out, const UA_ViewDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ViewDescription_viewId", sv);
	pack_UA_NodeId(sv, &in->viewId);

	sv = newSV(0);
	hv_stores(hv, "ViewDescription_timestamp", sv);
	pack_UA_DateTime(sv, &in->timestamp);

	sv = newSV(0);
	hv_stores(hv, "ViewDescription_viewVersion", sv);
	pack_UA_UInt32(sv, &in->viewVersion);

	return;
}

static void
unpack_UA_ViewDescription(UA_ViewDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ViewDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ViewDescription_viewId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->viewId, *svp);

	svp = hv_fetchs(hv, "ViewDescription_timestamp", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->timestamp, *svp);

	svp = hv_fetchs(hv, "ViewDescription_viewVersion", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->viewVersion, *svp);

	return;
}
#endif

/* BrowseDescription */
#ifdef UA_TYPES_BROWSEDESCRIPTION
static void pack_UA_BrowseDescription(SV *out, const UA_BrowseDescription *in);
static void unpack_UA_BrowseDescription(UA_BrowseDescription *out, SV *in);

static void
pack_UA_BrowseDescription(SV *out, const UA_BrowseDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowseDescription_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "BrowseDescription_browseDirection", sv);
	pack_UA_BrowseDirection(sv, &in->browseDirection);

	sv = newSV(0);
	hv_stores(hv, "BrowseDescription_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "BrowseDescription_includeSubtypes", sv);
	pack_UA_Boolean(sv, &in->includeSubtypes);

	sv = newSV(0);
	hv_stores(hv, "BrowseDescription_nodeClassMask", sv);
	pack_UA_UInt32(sv, &in->nodeClassMask);

	sv = newSV(0);
	hv_stores(hv, "BrowseDescription_resultMask", sv);
	pack_UA_UInt32(sv, &in->resultMask);

	return;
}

static void
unpack_UA_BrowseDescription(UA_BrowseDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowseDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseDescription_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "BrowseDescription_browseDirection", 0);
	if (svp != NULL)
		unpack_UA_BrowseDirection(&out->browseDirection, *svp);

	svp = hv_fetchs(hv, "BrowseDescription_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "BrowseDescription_includeSubtypes", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->includeSubtypes, *svp);

	svp = hv_fetchs(hv, "BrowseDescription_nodeClassMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->nodeClassMask, *svp);

	svp = hv_fetchs(hv, "BrowseDescription_resultMask", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->resultMask, *svp);

	return;
}
#endif

/* BrowseResultMask */
#ifdef UA_TYPES_BROWSERESULTMASK
static void pack_UA_BrowseResultMask(SV *out, const UA_BrowseResultMask *in);
static void unpack_UA_BrowseResultMask(UA_BrowseResultMask *out, SV *in);

static void
pack_UA_BrowseResultMask(SV *out, const UA_BrowseResultMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_BrowseResultMask(UA_BrowseResultMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ReferenceDescription */
#ifdef UA_TYPES_REFERENCEDESCRIPTION
static void pack_UA_ReferenceDescription(SV *out, const UA_ReferenceDescription *in);
static void unpack_UA_ReferenceDescription(UA_ReferenceDescription *out, SV *in);

static void
pack_UA_ReferenceDescription(SV *out, const UA_ReferenceDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReferenceDescription_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "ReferenceDescription_isForward", sv);
	pack_UA_Boolean(sv, &in->isForward);

	sv = newSV(0);
	hv_stores(hv, "ReferenceDescription_nodeId", sv);
	pack_UA_ExpandedNodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "ReferenceDescription_browseName", sv);
	pack_UA_QualifiedName(sv, &in->browseName);

	sv = newSV(0);
	hv_stores(hv, "ReferenceDescription_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "ReferenceDescription_nodeClass", sv);
	pack_UA_NodeClass(sv, &in->nodeClass);

	sv = newSV(0);
	hv_stores(hv, "ReferenceDescription_typeDefinition", sv);
	pack_UA_ExpandedNodeId(sv, &in->typeDefinition);

	return;
}

static void
unpack_UA_ReferenceDescription(UA_ReferenceDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReferenceDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReferenceDescription_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "ReferenceDescription_isForward", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isForward, *svp);

	svp = hv_fetchs(hv, "ReferenceDescription_nodeId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "ReferenceDescription_browseName", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->browseName, *svp);

	svp = hv_fetchs(hv, "ReferenceDescription_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "ReferenceDescription_nodeClass", 0);
	if (svp != NULL)
		unpack_UA_NodeClass(&out->nodeClass, *svp);

	svp = hv_fetchs(hv, "ReferenceDescription_typeDefinition", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->typeDefinition, *svp);

	return;
}
#endif

/* ContinuationPoint */
#ifdef UA_TYPES_CONTINUATIONPOINT
static void pack_UA_ContinuationPoint(SV *out, const UA_ContinuationPoint *in);
static void unpack_UA_ContinuationPoint(UA_ContinuationPoint *out, SV *in);

static void
pack_UA_ContinuationPoint(SV *out, const UA_ContinuationPoint *in)
{
	dTHX;
	pack_UA_ByteString(out, in);
}

static void
unpack_UA_ContinuationPoint(UA_ContinuationPoint *out, SV *in)
{
	dTHX;
	unpack_UA_ByteString(out, in);
}
#endif

/* BrowseResult */
#ifdef UA_TYPES_BROWSERESULT
static void pack_UA_BrowseResult(SV *out, const UA_BrowseResult *in);
static void unpack_UA_BrowseResult(UA_BrowseResult *out, SV *in);

static void
pack_UA_BrowseResult(SV *out, const UA_BrowseResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowseResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	sv = newSV(0);
	hv_stores(hv, "BrowseResult_continuationPoint", sv);
	pack_UA_ByteString(sv, &in->continuationPoint);

	av = newAV();
	hv_stores(hv, "BrowseResult_references", newRV_noinc((SV*)av));
	av_extend(av, in->referencesSize);
	for (i = 0; i < in->referencesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ReferenceDescription(sv, &in->references[i]);
	}

	return;
}

static void
unpack_UA_BrowseResult(UA_BrowseResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowseResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "BrowseResult_continuationPoint", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->continuationPoint, *svp);

	svp = hv_fetchs(hv, "BrowseResult_references", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowseResult_references");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->references = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_REFERENCEDESCRIPTION]);
		if (out->references == NULL)
			CROAKE("UA_Array_new");
		out->referencesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ReferenceDescription(&out->references[i], *svp);
		}
	}

	return;
}
#endif

/* BrowseRequest */
#ifdef UA_TYPES_BROWSEREQUEST
static void pack_UA_BrowseRequest(SV *out, const UA_BrowseRequest *in);
static void unpack_UA_BrowseRequest(UA_BrowseRequest *out, SV *in);

static void
pack_UA_BrowseRequest(SV *out, const UA_BrowseRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowseRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "BrowseRequest_view", sv);
	pack_UA_ViewDescription(sv, &in->view);

	sv = newSV(0);
	hv_stores(hv, "BrowseRequest_requestedMaxReferencesPerNode", sv);
	pack_UA_UInt32(sv, &in->requestedMaxReferencesPerNode);

	av = newAV();
	hv_stores(hv, "BrowseRequest_nodesToBrowse", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToBrowseSize);
	for (i = 0; i < in->nodesToBrowseSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_BrowseDescription(sv, &in->nodesToBrowse[i]);
	}

	return;
}

static void
unpack_UA_BrowseRequest(UA_BrowseRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowseRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "BrowseRequest_view", 0);
	if (svp != NULL)
		unpack_UA_ViewDescription(&out->view, *svp);

	svp = hv_fetchs(hv, "BrowseRequest_requestedMaxReferencesPerNode", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestedMaxReferencesPerNode, *svp);

	svp = hv_fetchs(hv, "BrowseRequest_nodesToBrowse", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowseRequest_nodesToBrowse");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToBrowse = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEDESCRIPTION]);
		if (out->nodesToBrowse == NULL)
			CROAKE("UA_Array_new");
		out->nodesToBrowseSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_BrowseDescription(&out->nodesToBrowse[i], *svp);
		}
	}

	return;
}
#endif

/* BrowseResponse */
#ifdef UA_TYPES_BROWSERESPONSE
static void pack_UA_BrowseResponse(SV *out, const UA_BrowseResponse *in);
static void unpack_UA_BrowseResponse(UA_BrowseResponse *out, SV *in);

static void
pack_UA_BrowseResponse(SV *out, const UA_BrowseResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowseResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "BrowseResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_BrowseResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "BrowseResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_BrowseResponse(UA_BrowseResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowseResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "BrowseResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowseResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSERESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_BrowseResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "BrowseResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowseResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* BrowseNextRequest */
#ifdef UA_TYPES_BROWSENEXTREQUEST
static void pack_UA_BrowseNextRequest(SV *out, const UA_BrowseNextRequest *in);
static void unpack_UA_BrowseNextRequest(UA_BrowseNextRequest *out, SV *in);

static void
pack_UA_BrowseNextRequest(SV *out, const UA_BrowseNextRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowseNextRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "BrowseNextRequest_releaseContinuationPoints", sv);
	pack_UA_Boolean(sv, &in->releaseContinuationPoints);

	av = newAV();
	hv_stores(hv, "BrowseNextRequest_continuationPoints", newRV_noinc((SV*)av));
	av_extend(av, in->continuationPointsSize);
	for (i = 0; i < in->continuationPointsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ByteString(sv, &in->continuationPoints[i]);
	}

	return;
}

static void
unpack_UA_BrowseNextRequest(UA_BrowseNextRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowseNextRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseNextRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "BrowseNextRequest_releaseContinuationPoints", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->releaseContinuationPoints, *svp);

	svp = hv_fetchs(hv, "BrowseNextRequest_continuationPoints", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowseNextRequest_continuationPoints");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->continuationPoints = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BYTESTRING]);
		if (out->continuationPoints == NULL)
			CROAKE("UA_Array_new");
		out->continuationPointsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ByteString(&out->continuationPoints[i], *svp);
		}
	}

	return;
}
#endif

/* BrowseNextResponse */
#ifdef UA_TYPES_BROWSENEXTRESPONSE
static void pack_UA_BrowseNextResponse(SV *out, const UA_BrowseNextResponse *in);
static void unpack_UA_BrowseNextResponse(UA_BrowseNextResponse *out, SV *in);

static void
pack_UA_BrowseNextResponse(SV *out, const UA_BrowseNextResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowseNextResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "BrowseNextResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_BrowseResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "BrowseNextResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_BrowseNextResponse(UA_BrowseNextResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowseNextResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseNextResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "BrowseNextResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowseNextResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSERESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_BrowseResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "BrowseNextResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowseNextResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* RelativePathElement */
#ifdef UA_TYPES_RELATIVEPATHELEMENT
static void pack_UA_RelativePathElement(SV *out, const UA_RelativePathElement *in);
static void unpack_UA_RelativePathElement(UA_RelativePathElement *out, SV *in);

static void
pack_UA_RelativePathElement(SV *out, const UA_RelativePathElement *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RelativePathElement_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "RelativePathElement_isInverse", sv);
	pack_UA_Boolean(sv, &in->isInverse);

	sv = newSV(0);
	hv_stores(hv, "RelativePathElement_includeSubtypes", sv);
	pack_UA_Boolean(sv, &in->includeSubtypes);

	sv = newSV(0);
	hv_stores(hv, "RelativePathElement_targetName", sv);
	pack_UA_QualifiedName(sv, &in->targetName);

	return;
}

static void
unpack_UA_RelativePathElement(UA_RelativePathElement *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RelativePathElement_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RelativePathElement_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "RelativePathElement_isInverse", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isInverse, *svp);

	svp = hv_fetchs(hv, "RelativePathElement_includeSubtypes", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->includeSubtypes, *svp);

	svp = hv_fetchs(hv, "RelativePathElement_targetName", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->targetName, *svp);

	return;
}
#endif

/* RelativePath */
#ifdef UA_TYPES_RELATIVEPATH
static void pack_UA_RelativePath(SV *out, const UA_RelativePath *in);
static void unpack_UA_RelativePath(UA_RelativePath *out, SV *in);

static void
pack_UA_RelativePath(SV *out, const UA_RelativePath *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "RelativePath_elements", newRV_noinc((SV*)av));
	av_extend(av, in->elementsSize);
	for (i = 0; i < in->elementsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_RelativePathElement(sv, &in->elements[i]);
	}

	return;
}

static void
unpack_UA_RelativePath(UA_RelativePath *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RelativePath_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RelativePath_elements", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RelativePath_elements");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->elements = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_RELATIVEPATHELEMENT]);
		if (out->elements == NULL)
			CROAKE("UA_Array_new");
		out->elementsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_RelativePathElement(&out->elements[i], *svp);
		}
	}

	return;
}
#endif

/* BrowsePath */
#ifdef UA_TYPES_BROWSEPATH
static void pack_UA_BrowsePath(SV *out, const UA_BrowsePath *in);
static void unpack_UA_BrowsePath(UA_BrowsePath *out, SV *in);

static void
pack_UA_BrowsePath(SV *out, const UA_BrowsePath *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowsePath_startingNode", sv);
	pack_UA_NodeId(sv, &in->startingNode);

	sv = newSV(0);
	hv_stores(hv, "BrowsePath_relativePath", sv);
	pack_UA_RelativePath(sv, &in->relativePath);

	return;
}

static void
unpack_UA_BrowsePath(UA_BrowsePath *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowsePath_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowsePath_startingNode", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->startingNode, *svp);

	svp = hv_fetchs(hv, "BrowsePath_relativePath", 0);
	if (svp != NULL)
		unpack_UA_RelativePath(&out->relativePath, *svp);

	return;
}
#endif

/* BrowsePathTarget */
#ifdef UA_TYPES_BROWSEPATHTARGET
static void pack_UA_BrowsePathTarget(SV *out, const UA_BrowsePathTarget *in);
static void unpack_UA_BrowsePathTarget(UA_BrowsePathTarget *out, SV *in);

static void
pack_UA_BrowsePathTarget(SV *out, const UA_BrowsePathTarget *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowsePathTarget_targetId", sv);
	pack_UA_ExpandedNodeId(sv, &in->targetId);

	sv = newSV(0);
	hv_stores(hv, "BrowsePathTarget_remainingPathIndex", sv);
	pack_UA_UInt32(sv, &in->remainingPathIndex);

	return;
}

static void
unpack_UA_BrowsePathTarget(UA_BrowsePathTarget *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowsePathTarget_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowsePathTarget_targetId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->targetId, *svp);

	svp = hv_fetchs(hv, "BrowsePathTarget_remainingPathIndex", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->remainingPathIndex, *svp);

	return;
}
#endif

/* BrowsePathResult */
#ifdef UA_TYPES_BROWSEPATHRESULT
static void pack_UA_BrowsePathResult(SV *out, const UA_BrowsePathResult *in);
static void unpack_UA_BrowsePathResult(UA_BrowsePathResult *out, SV *in);

static void
pack_UA_BrowsePathResult(SV *out, const UA_BrowsePathResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BrowsePathResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	av = newAV();
	hv_stores(hv, "BrowsePathResult_targets", newRV_noinc((SV*)av));
	av_extend(av, in->targetsSize);
	for (i = 0; i < in->targetsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_BrowsePathTarget(sv, &in->targets[i]);
	}

	return;
}

static void
unpack_UA_BrowsePathResult(UA_BrowsePathResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BrowsePathResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowsePathResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "BrowsePathResult_targets", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for BrowsePathResult_targets");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->targets = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEPATHTARGET]);
		if (out->targets == NULL)
			CROAKE("UA_Array_new");
		out->targetsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_BrowsePathTarget(&out->targets[i], *svp);
		}
	}

	return;
}
#endif

/* TranslateBrowsePathsToNodeIdsRequest */
#ifdef UA_TYPES_TRANSLATEBROWSEPATHSTONODEIDSREQUEST
static void pack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *out, const UA_TranslateBrowsePathsToNodeIdsRequest *in);
static void unpack_UA_TranslateBrowsePathsToNodeIdsRequest(UA_TranslateBrowsePathsToNodeIdsRequest *out, SV *in);

static void
pack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *out, const UA_TranslateBrowsePathsToNodeIdsRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsRequest_browsePaths", newRV_noinc((SV*)av));
	av_extend(av, in->browsePathsSize);
	for (i = 0; i < in->browsePathsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_BrowsePath(sv, &in->browsePaths[i]);
	}

	return;
}

static void
unpack_UA_TranslateBrowsePathsToNodeIdsRequest(UA_TranslateBrowsePathsToNodeIdsRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TranslateBrowsePathsToNodeIdsRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsRequest_browsePaths", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TranslateBrowsePathsToNodeIdsRequest_browsePaths");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->browsePaths = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEPATH]);
		if (out->browsePaths == NULL)
			CROAKE("UA_Array_new");
		out->browsePathsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_BrowsePath(&out->browsePaths[i], *svp);
		}
	}

	return;
}
#endif

/* TranslateBrowsePathsToNodeIdsResponse */
#ifdef UA_TYPES_TRANSLATEBROWSEPATHSTONODEIDSRESPONSE
static void pack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *out, const UA_TranslateBrowsePathsToNodeIdsResponse *in);
static void unpack_UA_TranslateBrowsePathsToNodeIdsResponse(UA_TranslateBrowsePathsToNodeIdsResponse *out, SV *in);

static void
pack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *out, const UA_TranslateBrowsePathsToNodeIdsResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_BrowsePathResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_TranslateBrowsePathsToNodeIdsResponse(UA_TranslateBrowsePathsToNodeIdsResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TranslateBrowsePathsToNodeIdsResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TranslateBrowsePathsToNodeIdsResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEPATHRESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_BrowsePathResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TranslateBrowsePathsToNodeIdsResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* RegisterNodesRequest */
#ifdef UA_TYPES_REGISTERNODESREQUEST
static void pack_UA_RegisterNodesRequest(SV *out, const UA_RegisterNodesRequest *in);
static void unpack_UA_RegisterNodesRequest(UA_RegisterNodesRequest *out, SV *in);

static void
pack_UA_RegisterNodesRequest(SV *out, const UA_RegisterNodesRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RegisterNodesRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "RegisterNodesRequest_nodesToRegister", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToRegisterSize);
	for (i = 0; i < in->nodesToRegisterSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_NodeId(sv, &in->nodesToRegister[i]);
	}

	return;
}

static void
unpack_UA_RegisterNodesRequest(UA_RegisterNodesRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RegisterNodesRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterNodesRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "RegisterNodesRequest_nodesToRegister", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RegisterNodesRequest_nodesToRegister");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToRegister = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out->nodesToRegister == NULL)
			CROAKE("UA_Array_new");
		out->nodesToRegisterSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_NodeId(&out->nodesToRegister[i], *svp);
		}
	}

	return;
}
#endif

/* RegisterNodesResponse */
#ifdef UA_TYPES_REGISTERNODESRESPONSE
static void pack_UA_RegisterNodesResponse(SV *out, const UA_RegisterNodesResponse *in);
static void unpack_UA_RegisterNodesResponse(UA_RegisterNodesResponse *out, SV *in);

static void
pack_UA_RegisterNodesResponse(SV *out, const UA_RegisterNodesResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RegisterNodesResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "RegisterNodesResponse_registeredNodeIds", newRV_noinc((SV*)av));
	av_extend(av, in->registeredNodeIdsSize);
	for (i = 0; i < in->registeredNodeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_NodeId(sv, &in->registeredNodeIds[i]);
	}

	return;
}

static void
unpack_UA_RegisterNodesResponse(UA_RegisterNodesResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RegisterNodesResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterNodesResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "RegisterNodesResponse_registeredNodeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for RegisterNodesResponse_registeredNodeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->registeredNodeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out->registeredNodeIds == NULL)
			CROAKE("UA_Array_new");
		out->registeredNodeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_NodeId(&out->registeredNodeIds[i], *svp);
		}
	}

	return;
}
#endif

/* UnregisterNodesRequest */
#ifdef UA_TYPES_UNREGISTERNODESREQUEST
static void pack_UA_UnregisterNodesRequest(SV *out, const UA_UnregisterNodesRequest *in);
static void unpack_UA_UnregisterNodesRequest(UA_UnregisterNodesRequest *out, SV *in);

static void
pack_UA_UnregisterNodesRequest(SV *out, const UA_UnregisterNodesRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UnregisterNodesRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "UnregisterNodesRequest_nodesToUnregister", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToUnregisterSize);
	for (i = 0; i < in->nodesToUnregisterSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_NodeId(sv, &in->nodesToUnregister[i]);
	}

	return;
}

static void
unpack_UA_UnregisterNodesRequest(UA_UnregisterNodesRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UnregisterNodesRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UnregisterNodesRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "UnregisterNodesRequest_nodesToUnregister", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UnregisterNodesRequest_nodesToUnregister");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToUnregister = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out->nodesToUnregister == NULL)
			CROAKE("UA_Array_new");
		out->nodesToUnregisterSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_NodeId(&out->nodesToUnregister[i], *svp);
		}
	}

	return;
}
#endif

/* UnregisterNodesResponse */
#ifdef UA_TYPES_UNREGISTERNODESRESPONSE
static void pack_UA_UnregisterNodesResponse(SV *out, const UA_UnregisterNodesResponse *in);
static void unpack_UA_UnregisterNodesResponse(UA_UnregisterNodesResponse *out, SV *in);

static void
pack_UA_UnregisterNodesResponse(SV *out, const UA_UnregisterNodesResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UnregisterNodesResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	return;
}

static void
unpack_UA_UnregisterNodesResponse(UA_UnregisterNodesResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UnregisterNodesResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UnregisterNodesResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	return;
}
#endif

/* Counter */
#ifdef UA_TYPES_COUNTER
static void pack_UA_Counter(SV *out, const UA_Counter *in);
static void unpack_UA_Counter(UA_Counter *out, SV *in);

static void
pack_UA_Counter(SV *out, const UA_Counter *in)
{
	dTHX;
	pack_UA_UInt32(out, in);
}

static void
unpack_UA_Counter(UA_Counter *out, SV *in)
{
	dTHX;
	unpack_UA_UInt32(out, in);
}
#endif

/* OpaqueNumericRange */
#ifdef UA_TYPES_OPAQUENUMERICRANGE
static void pack_UA_OpaqueNumericRange(SV *out, const UA_OpaqueNumericRange *in);
static void unpack_UA_OpaqueNumericRange(UA_OpaqueNumericRange *out, SV *in);

static void
pack_UA_OpaqueNumericRange(SV *out, const UA_OpaqueNumericRange *in)
{
	dTHX;
	pack_UA_String(out, in);
}

static void
unpack_UA_OpaqueNumericRange(UA_OpaqueNumericRange *out, SV *in)
{
	dTHX;
	unpack_UA_String(out, in);
}
#endif

/* EndpointConfiguration */
#ifdef UA_TYPES_ENDPOINTCONFIGURATION
static void pack_UA_EndpointConfiguration(SV *out, const UA_EndpointConfiguration *in);
static void unpack_UA_EndpointConfiguration(UA_EndpointConfiguration *out, SV *in);

static void
pack_UA_EndpointConfiguration(SV *out, const UA_EndpointConfiguration *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_operationTimeout", sv);
	pack_UA_Int32(sv, &in->operationTimeout);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_useBinaryEncoding", sv);
	pack_UA_Boolean(sv, &in->useBinaryEncoding);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_maxStringLength", sv);
	pack_UA_Int32(sv, &in->maxStringLength);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_maxByteStringLength", sv);
	pack_UA_Int32(sv, &in->maxByteStringLength);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_maxArrayLength", sv);
	pack_UA_Int32(sv, &in->maxArrayLength);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_maxMessageSize", sv);
	pack_UA_Int32(sv, &in->maxMessageSize);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_maxBufferSize", sv);
	pack_UA_Int32(sv, &in->maxBufferSize);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_channelLifetime", sv);
	pack_UA_Int32(sv, &in->channelLifetime);

	sv = newSV(0);
	hv_stores(hv, "EndpointConfiguration_securityTokenLifetime", sv);
	pack_UA_Int32(sv, &in->securityTokenLifetime);

	return;
}

static void
unpack_UA_EndpointConfiguration(UA_EndpointConfiguration *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EndpointConfiguration_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EndpointConfiguration_operationTimeout", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->operationTimeout, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_useBinaryEncoding", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->useBinaryEncoding, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_maxStringLength", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->maxStringLength, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_maxByteStringLength", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->maxByteStringLength, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_maxArrayLength", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->maxArrayLength, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_maxMessageSize", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->maxMessageSize, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_maxBufferSize", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->maxBufferSize, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_channelLifetime", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->channelLifetime, *svp);

	svp = hv_fetchs(hv, "EndpointConfiguration_securityTokenLifetime", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->securityTokenLifetime, *svp);

	return;
}
#endif

/* QueryDataDescription */
#ifdef UA_TYPES_QUERYDATADESCRIPTION
static void pack_UA_QueryDataDescription(SV *out, const UA_QueryDataDescription *in);
static void unpack_UA_QueryDataDescription(UA_QueryDataDescription *out, SV *in);

static void
pack_UA_QueryDataDescription(SV *out, const UA_QueryDataDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "QueryDataDescription_relativePath", sv);
	pack_UA_RelativePath(sv, &in->relativePath);

	sv = newSV(0);
	hv_stores(hv, "QueryDataDescription_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "QueryDataDescription_indexRange", sv);
	pack_UA_String(sv, &in->indexRange);

	return;
}

static void
unpack_UA_QueryDataDescription(UA_QueryDataDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_QueryDataDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QueryDataDescription_relativePath", 0);
	if (svp != NULL)
		unpack_UA_RelativePath(&out->relativePath, *svp);

	svp = hv_fetchs(hv, "QueryDataDescription_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "QueryDataDescription_indexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->indexRange, *svp);

	return;
}
#endif

/* NodeTypeDescription */
#ifdef UA_TYPES_NODETYPEDESCRIPTION
static void pack_UA_NodeTypeDescription(SV *out, const UA_NodeTypeDescription *in);
static void unpack_UA_NodeTypeDescription(UA_NodeTypeDescription *out, SV *in);

static void
pack_UA_NodeTypeDescription(SV *out, const UA_NodeTypeDescription *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NodeTypeDescription_typeDefinitionNode", sv);
	pack_UA_ExpandedNodeId(sv, &in->typeDefinitionNode);

	sv = newSV(0);
	hv_stores(hv, "NodeTypeDescription_includeSubTypes", sv);
	pack_UA_Boolean(sv, &in->includeSubTypes);

	av = newAV();
	hv_stores(hv, "NodeTypeDescription_dataToReturn", newRV_noinc((SV*)av));
	av_extend(av, in->dataToReturnSize);
	for (i = 0; i < in->dataToReturnSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_QueryDataDescription(sv, &in->dataToReturn[i]);
	}

	return;
}

static void
unpack_UA_NodeTypeDescription(UA_NodeTypeDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NodeTypeDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NodeTypeDescription_typeDefinitionNode", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->typeDefinitionNode, *svp);

	svp = hv_fetchs(hv, "NodeTypeDescription_includeSubTypes", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->includeSubTypes, *svp);

	svp = hv_fetchs(hv, "NodeTypeDescription_dataToReturn", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for NodeTypeDescription_dataToReturn");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataToReturn = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_QUERYDATADESCRIPTION]);
		if (out->dataToReturn == NULL)
			CROAKE("UA_Array_new");
		out->dataToReturnSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_QueryDataDescription(&out->dataToReturn[i], *svp);
		}
	}

	return;
}
#endif

/* FilterOperator */
#ifdef UA_TYPES_FILTEROPERATOR
static void pack_UA_FilterOperator(SV *out, const UA_FilterOperator *in);
static void unpack_UA_FilterOperator(UA_FilterOperator *out, SV *in);

static void
pack_UA_FilterOperator(SV *out, const UA_FilterOperator *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_FilterOperator(UA_FilterOperator *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* QueryDataSet */
#ifdef UA_TYPES_QUERYDATASET
static void pack_UA_QueryDataSet(SV *out, const UA_QueryDataSet *in);
static void unpack_UA_QueryDataSet(UA_QueryDataSet *out, SV *in);

static void
pack_UA_QueryDataSet(SV *out, const UA_QueryDataSet *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "QueryDataSet_nodeId", sv);
	pack_UA_ExpandedNodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "QueryDataSet_typeDefinitionNode", sv);
	pack_UA_ExpandedNodeId(sv, &in->typeDefinitionNode);

	av = newAV();
	hv_stores(hv, "QueryDataSet_values", newRV_noinc((SV*)av));
	av_extend(av, in->valuesSize);
	for (i = 0; i < in->valuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Variant(sv, &in->values[i]);
	}

	return;
}

static void
unpack_UA_QueryDataSet(UA_QueryDataSet *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_QueryDataSet_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QueryDataSet_nodeId", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "QueryDataSet_typeDefinitionNode", 0);
	if (svp != NULL)
		unpack_UA_ExpandedNodeId(&out->typeDefinitionNode, *svp);

	svp = hv_fetchs(hv, "QueryDataSet_values", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for QueryDataSet_values");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->values = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out->values == NULL)
			CROAKE("UA_Array_new");
		out->valuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Variant(&out->values[i], *svp);
		}
	}

	return;
}
#endif

/* NodeReference */
#ifdef UA_TYPES_NODEREFERENCE
static void pack_UA_NodeReference(SV *out, const UA_NodeReference *in);
static void unpack_UA_NodeReference(UA_NodeReference *out, SV *in);

static void
pack_UA_NodeReference(SV *out, const UA_NodeReference *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NodeReference_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "NodeReference_referenceTypeId", sv);
	pack_UA_NodeId(sv, &in->referenceTypeId);

	sv = newSV(0);
	hv_stores(hv, "NodeReference_isForward", sv);
	pack_UA_Boolean(sv, &in->isForward);

	av = newAV();
	hv_stores(hv, "NodeReference_referencedNodeIds", newRV_noinc((SV*)av));
	av_extend(av, in->referencedNodeIdsSize);
	for (i = 0; i < in->referencedNodeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_NodeId(sv, &in->referencedNodeIds[i]);
	}

	return;
}

static void
unpack_UA_NodeReference(UA_NodeReference *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NodeReference_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NodeReference_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "NodeReference_referenceTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->referenceTypeId, *svp);

	svp = hv_fetchs(hv, "NodeReference_isForward", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isForward, *svp);

	svp = hv_fetchs(hv, "NodeReference_referencedNodeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for NodeReference_referencedNodeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->referencedNodeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out->referencedNodeIds == NULL)
			CROAKE("UA_Array_new");
		out->referencedNodeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_NodeId(&out->referencedNodeIds[i], *svp);
		}
	}

	return;
}
#endif

/* ContentFilterElement */
#ifdef UA_TYPES_CONTENTFILTERELEMENT
static void pack_UA_ContentFilterElement(SV *out, const UA_ContentFilterElement *in);
static void unpack_UA_ContentFilterElement(UA_ContentFilterElement *out, SV *in);

static void
pack_UA_ContentFilterElement(SV *out, const UA_ContentFilterElement *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ContentFilterElement_filterOperator", sv);
	pack_UA_FilterOperator(sv, &in->filterOperator);

	av = newAV();
	hv_stores(hv, "ContentFilterElement_filterOperands", newRV_noinc((SV*)av));
	av_extend(av, in->filterOperandsSize);
	for (i = 0; i < in->filterOperandsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ExtensionObject(sv, &in->filterOperands[i]);
	}

	return;
}

static void
unpack_UA_ContentFilterElement(UA_ContentFilterElement *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ContentFilterElement_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilterElement_filterOperator", 0);
	if (svp != NULL)
		unpack_UA_FilterOperator(&out->filterOperator, *svp);

	svp = hv_fetchs(hv, "ContentFilterElement_filterOperands", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ContentFilterElement_filterOperands");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->filterOperands = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXTENSIONOBJECT]);
		if (out->filterOperands == NULL)
			CROAKE("UA_Array_new");
		out->filterOperandsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ExtensionObject(&out->filterOperands[i], *svp);
		}
	}

	return;
}
#endif

/* ContentFilter */
#ifdef UA_TYPES_CONTENTFILTER
static void pack_UA_ContentFilter(SV *out, const UA_ContentFilter *in);
static void unpack_UA_ContentFilter(UA_ContentFilter *out, SV *in);

static void
pack_UA_ContentFilter(SV *out, const UA_ContentFilter *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "ContentFilter_elements", newRV_noinc((SV*)av));
	av_extend(av, in->elementsSize);
	for (i = 0; i < in->elementsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ContentFilterElement(sv, &in->elements[i]);
	}

	return;
}

static void
unpack_UA_ContentFilter(UA_ContentFilter *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ContentFilter_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilter_elements", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ContentFilter_elements");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->elements = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CONTENTFILTERELEMENT]);
		if (out->elements == NULL)
			CROAKE("UA_Array_new");
		out->elementsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ContentFilterElement(&out->elements[i], *svp);
		}
	}

	return;
}
#endif

/* ElementOperand */
#ifdef UA_TYPES_ELEMENTOPERAND
static void pack_UA_ElementOperand(SV *out, const UA_ElementOperand *in);
static void unpack_UA_ElementOperand(UA_ElementOperand *out, SV *in);

static void
pack_UA_ElementOperand(SV *out, const UA_ElementOperand *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ElementOperand_index", sv);
	pack_UA_UInt32(sv, &in->index);

	return;
}

static void
unpack_UA_ElementOperand(UA_ElementOperand *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ElementOperand_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ElementOperand_index", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->index, *svp);

	return;
}
#endif

/* LiteralOperand */
#ifdef UA_TYPES_LITERALOPERAND
static void pack_UA_LiteralOperand(SV *out, const UA_LiteralOperand *in);
static void unpack_UA_LiteralOperand(UA_LiteralOperand *out, SV *in);

static void
pack_UA_LiteralOperand(SV *out, const UA_LiteralOperand *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "LiteralOperand_value", sv);
	pack_UA_Variant(sv, &in->value);

	return;
}

static void
unpack_UA_LiteralOperand(UA_LiteralOperand *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_LiteralOperand_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "LiteralOperand_value", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->value, *svp);

	return;
}
#endif

/* AttributeOperand */
#ifdef UA_TYPES_ATTRIBUTEOPERAND
static void pack_UA_AttributeOperand(SV *out, const UA_AttributeOperand *in);
static void unpack_UA_AttributeOperand(UA_AttributeOperand *out, SV *in);

static void
pack_UA_AttributeOperand(SV *out, const UA_AttributeOperand *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AttributeOperand_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "AttributeOperand_alias", sv);
	pack_UA_String(sv, &in->alias);

	sv = newSV(0);
	hv_stores(hv, "AttributeOperand_browsePath", sv);
	pack_UA_RelativePath(sv, &in->browsePath);

	sv = newSV(0);
	hv_stores(hv, "AttributeOperand_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "AttributeOperand_indexRange", sv);
	pack_UA_String(sv, &in->indexRange);

	return;
}

static void
unpack_UA_AttributeOperand(UA_AttributeOperand *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AttributeOperand_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AttributeOperand_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "AttributeOperand_alias", 0);
	if (svp != NULL)
		unpack_UA_String(&out->alias, *svp);

	svp = hv_fetchs(hv, "AttributeOperand_browsePath", 0);
	if (svp != NULL)
		unpack_UA_RelativePath(&out->browsePath, *svp);

	svp = hv_fetchs(hv, "AttributeOperand_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "AttributeOperand_indexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->indexRange, *svp);

	return;
}
#endif

/* SimpleAttributeOperand */
#ifdef UA_TYPES_SIMPLEATTRIBUTEOPERAND
static void pack_UA_SimpleAttributeOperand(SV *out, const UA_SimpleAttributeOperand *in);
static void unpack_UA_SimpleAttributeOperand(UA_SimpleAttributeOperand *out, SV *in);

static void
pack_UA_SimpleAttributeOperand(SV *out, const UA_SimpleAttributeOperand *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SimpleAttributeOperand_typeDefinitionId", sv);
	pack_UA_NodeId(sv, &in->typeDefinitionId);

	av = newAV();
	hv_stores(hv, "SimpleAttributeOperand_browsePath", newRV_noinc((SV*)av));
	av_extend(av, in->browsePathSize);
	for (i = 0; i < in->browsePathSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_QualifiedName(sv, &in->browsePath[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "SimpleAttributeOperand_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "SimpleAttributeOperand_indexRange", sv);
	pack_UA_String(sv, &in->indexRange);

	return;
}

static void
unpack_UA_SimpleAttributeOperand(UA_SimpleAttributeOperand *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SimpleAttributeOperand_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SimpleAttributeOperand_typeDefinitionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->typeDefinitionId, *svp);

	svp = hv_fetchs(hv, "SimpleAttributeOperand_browsePath", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SimpleAttributeOperand_browsePath");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->browsePath = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_QUALIFIEDNAME]);
		if (out->browsePath == NULL)
			CROAKE("UA_Array_new");
		out->browsePathSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_QualifiedName(&out->browsePath[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SimpleAttributeOperand_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "SimpleAttributeOperand_indexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->indexRange, *svp);

	return;
}
#endif

/* ContentFilterElementResult */
#ifdef UA_TYPES_CONTENTFILTERELEMENTRESULT
static void pack_UA_ContentFilterElementResult(SV *out, const UA_ContentFilterElementResult *in);
static void unpack_UA_ContentFilterElementResult(UA_ContentFilterElementResult *out, SV *in);

static void
pack_UA_ContentFilterElementResult(SV *out, const UA_ContentFilterElementResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ContentFilterElementResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	av = newAV();
	hv_stores(hv, "ContentFilterElementResult_operandStatusCodes", newRV_noinc((SV*)av));
	av_extend(av, in->operandStatusCodesSize);
	for (i = 0; i < in->operandStatusCodesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->operandStatusCodes[i]);
	}

	av = newAV();
	hv_stores(hv, "ContentFilterElementResult_operandDiagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->operandDiagnosticInfosSize);
	for (i = 0; i < in->operandDiagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->operandDiagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_ContentFilterElementResult(UA_ContentFilterElementResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ContentFilterElementResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilterElementResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "ContentFilterElementResult_operandStatusCodes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ContentFilterElementResult_operandStatusCodes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->operandStatusCodes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->operandStatusCodes == NULL)
			CROAKE("UA_Array_new");
		out->operandStatusCodesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->operandStatusCodes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ContentFilterElementResult_operandDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ContentFilterElementResult_operandDiagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->operandDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->operandDiagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->operandDiagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->operandDiagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* ContentFilterResult */
#ifdef UA_TYPES_CONTENTFILTERRESULT
static void pack_UA_ContentFilterResult(SV *out, const UA_ContentFilterResult *in);
static void unpack_UA_ContentFilterResult(UA_ContentFilterResult *out, SV *in);

static void
pack_UA_ContentFilterResult(SV *out, const UA_ContentFilterResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "ContentFilterResult_elementResults", newRV_noinc((SV*)av));
	av_extend(av, in->elementResultsSize);
	for (i = 0; i < in->elementResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ContentFilterElementResult(sv, &in->elementResults[i]);
	}

	av = newAV();
	hv_stores(hv, "ContentFilterResult_elementDiagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->elementDiagnosticInfosSize);
	for (i = 0; i < in->elementDiagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->elementDiagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_ContentFilterResult(UA_ContentFilterResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ContentFilterResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilterResult_elementResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ContentFilterResult_elementResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->elementResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CONTENTFILTERELEMENTRESULT]);
		if (out->elementResults == NULL)
			CROAKE("UA_Array_new");
		out->elementResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ContentFilterElementResult(&out->elementResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ContentFilterResult_elementDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ContentFilterResult_elementDiagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->elementDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->elementDiagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->elementDiagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->elementDiagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* ParsingResult */
#ifdef UA_TYPES_PARSINGRESULT
static void pack_UA_ParsingResult(SV *out, const UA_ParsingResult *in);
static void unpack_UA_ParsingResult(UA_ParsingResult *out, SV *in);

static void
pack_UA_ParsingResult(SV *out, const UA_ParsingResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ParsingResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	av = newAV();
	hv_stores(hv, "ParsingResult_dataStatusCodes", newRV_noinc((SV*)av));
	av_extend(av, in->dataStatusCodesSize);
	for (i = 0; i < in->dataStatusCodesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->dataStatusCodes[i]);
	}

	av = newAV();
	hv_stores(hv, "ParsingResult_dataDiagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->dataDiagnosticInfosSize);
	for (i = 0; i < in->dataDiagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->dataDiagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_ParsingResult(UA_ParsingResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ParsingResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ParsingResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "ParsingResult_dataStatusCodes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ParsingResult_dataStatusCodes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataStatusCodes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->dataStatusCodes == NULL)
			CROAKE("UA_Array_new");
		out->dataStatusCodesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->dataStatusCodes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ParsingResult_dataDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ParsingResult_dataDiagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->dataDiagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->dataDiagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->dataDiagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* QueryFirstRequest */
#ifdef UA_TYPES_QUERYFIRSTREQUEST
static void pack_UA_QueryFirstRequest(SV *out, const UA_QueryFirstRequest *in);
static void unpack_UA_QueryFirstRequest(UA_QueryFirstRequest *out, SV *in);

static void
pack_UA_QueryFirstRequest(SV *out, const UA_QueryFirstRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "QueryFirstRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "QueryFirstRequest_view", sv);
	pack_UA_ViewDescription(sv, &in->view);

	av = newAV();
	hv_stores(hv, "QueryFirstRequest_nodeTypes", newRV_noinc((SV*)av));
	av_extend(av, in->nodeTypesSize);
	for (i = 0; i < in->nodeTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_NodeTypeDescription(sv, &in->nodeTypes[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "QueryFirstRequest_filter", sv);
	pack_UA_ContentFilter(sv, &in->filter);

	sv = newSV(0);
	hv_stores(hv, "QueryFirstRequest_maxDataSetsToReturn", sv);
	pack_UA_UInt32(sv, &in->maxDataSetsToReturn);

	sv = newSV(0);
	hv_stores(hv, "QueryFirstRequest_maxReferencesToReturn", sv);
	pack_UA_UInt32(sv, &in->maxReferencesToReturn);

	return;
}

static void
unpack_UA_QueryFirstRequest(UA_QueryFirstRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_QueryFirstRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QueryFirstRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "QueryFirstRequest_view", 0);
	if (svp != NULL)
		unpack_UA_ViewDescription(&out->view, *svp);

	svp = hv_fetchs(hv, "QueryFirstRequest_nodeTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for QueryFirstRequest_nodeTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodeTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODETYPEDESCRIPTION]);
		if (out->nodeTypes == NULL)
			CROAKE("UA_Array_new");
		out->nodeTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_NodeTypeDescription(&out->nodeTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "QueryFirstRequest_filter", 0);
	if (svp != NULL)
		unpack_UA_ContentFilter(&out->filter, *svp);

	svp = hv_fetchs(hv, "QueryFirstRequest_maxDataSetsToReturn", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxDataSetsToReturn, *svp);

	svp = hv_fetchs(hv, "QueryFirstRequest_maxReferencesToReturn", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxReferencesToReturn, *svp);

	return;
}
#endif

/* QueryFirstResponse */
#ifdef UA_TYPES_QUERYFIRSTRESPONSE
static void pack_UA_QueryFirstResponse(SV *out, const UA_QueryFirstResponse *in);
static void unpack_UA_QueryFirstResponse(UA_QueryFirstResponse *out, SV *in);

static void
pack_UA_QueryFirstResponse(SV *out, const UA_QueryFirstResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "QueryFirstResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "QueryFirstResponse_queryDataSets", newRV_noinc((SV*)av));
	av_extend(av, in->queryDataSetsSize);
	for (i = 0; i < in->queryDataSetsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_QueryDataSet(sv, &in->queryDataSets[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "QueryFirstResponse_continuationPoint", sv);
	pack_UA_ByteString(sv, &in->continuationPoint);

	av = newAV();
	hv_stores(hv, "QueryFirstResponse_parsingResults", newRV_noinc((SV*)av));
	av_extend(av, in->parsingResultsSize);
	for (i = 0; i < in->parsingResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ParsingResult(sv, &in->parsingResults[i]);
	}

	av = newAV();
	hv_stores(hv, "QueryFirstResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "QueryFirstResponse_filterResult", sv);
	pack_UA_ContentFilterResult(sv, &in->filterResult);

	return;
}

static void
unpack_UA_QueryFirstResponse(UA_QueryFirstResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_QueryFirstResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QueryFirstResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "QueryFirstResponse_queryDataSets", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for QueryFirstResponse_queryDataSets");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->queryDataSets = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_QUERYDATASET]);
		if (out->queryDataSets == NULL)
			CROAKE("UA_Array_new");
		out->queryDataSetsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_QueryDataSet(&out->queryDataSets[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "QueryFirstResponse_continuationPoint", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->continuationPoint, *svp);

	svp = hv_fetchs(hv, "QueryFirstResponse_parsingResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for QueryFirstResponse_parsingResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->parsingResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_PARSINGRESULT]);
		if (out->parsingResults == NULL)
			CROAKE("UA_Array_new");
		out->parsingResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ParsingResult(&out->parsingResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "QueryFirstResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for QueryFirstResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "QueryFirstResponse_filterResult", 0);
	if (svp != NULL)
		unpack_UA_ContentFilterResult(&out->filterResult, *svp);

	return;
}
#endif

/* QueryNextRequest */
#ifdef UA_TYPES_QUERYNEXTREQUEST
static void pack_UA_QueryNextRequest(SV *out, const UA_QueryNextRequest *in);
static void unpack_UA_QueryNextRequest(UA_QueryNextRequest *out, SV *in);

static void
pack_UA_QueryNextRequest(SV *out, const UA_QueryNextRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "QueryNextRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "QueryNextRequest_releaseContinuationPoint", sv);
	pack_UA_Boolean(sv, &in->releaseContinuationPoint);

	sv = newSV(0);
	hv_stores(hv, "QueryNextRequest_continuationPoint", sv);
	pack_UA_ByteString(sv, &in->continuationPoint);

	return;
}

static void
unpack_UA_QueryNextRequest(UA_QueryNextRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_QueryNextRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QueryNextRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "QueryNextRequest_releaseContinuationPoint", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->releaseContinuationPoint, *svp);

	svp = hv_fetchs(hv, "QueryNextRequest_continuationPoint", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->continuationPoint, *svp);

	return;
}
#endif

/* QueryNextResponse */
#ifdef UA_TYPES_QUERYNEXTRESPONSE
static void pack_UA_QueryNextResponse(SV *out, const UA_QueryNextResponse *in);
static void unpack_UA_QueryNextResponse(UA_QueryNextResponse *out, SV *in);

static void
pack_UA_QueryNextResponse(SV *out, const UA_QueryNextResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "QueryNextResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "QueryNextResponse_queryDataSets", newRV_noinc((SV*)av));
	av_extend(av, in->queryDataSetsSize);
	for (i = 0; i < in->queryDataSetsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_QueryDataSet(sv, &in->queryDataSets[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "QueryNextResponse_revisedContinuationPoint", sv);
	pack_UA_ByteString(sv, &in->revisedContinuationPoint);

	return;
}

static void
unpack_UA_QueryNextResponse(UA_QueryNextResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_QueryNextResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QueryNextResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "QueryNextResponse_queryDataSets", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for QueryNextResponse_queryDataSets");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->queryDataSets = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_QUERYDATASET]);
		if (out->queryDataSets == NULL)
			CROAKE("UA_Array_new");
		out->queryDataSetsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_QueryDataSet(&out->queryDataSets[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "QueryNextResponse_revisedContinuationPoint", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->revisedContinuationPoint, *svp);

	return;
}
#endif

/* TimestampsToReturn */
#ifdef UA_TYPES_TIMESTAMPSTORETURN
static void pack_UA_TimestampsToReturn(SV *out, const UA_TimestampsToReturn *in);
static void unpack_UA_TimestampsToReturn(UA_TimestampsToReturn *out, SV *in);

static void
pack_UA_TimestampsToReturn(SV *out, const UA_TimestampsToReturn *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_TimestampsToReturn(UA_TimestampsToReturn *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ReadValueId */
#ifdef UA_TYPES_READVALUEID
static void pack_UA_ReadValueId(SV *out, const UA_ReadValueId *in);
static void unpack_UA_ReadValueId(UA_ReadValueId *out, SV *in);

static void
pack_UA_ReadValueId(SV *out, const UA_ReadValueId *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReadValueId_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "ReadValueId_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "ReadValueId_indexRange", sv);
	pack_UA_String(sv, &in->indexRange);

	sv = newSV(0);
	hv_stores(hv, "ReadValueId_dataEncoding", sv);
	pack_UA_QualifiedName(sv, &in->dataEncoding);

	return;
}

static void
unpack_UA_ReadValueId(UA_ReadValueId *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadValueId_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadValueId_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "ReadValueId_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "ReadValueId_indexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->indexRange, *svp);

	svp = hv_fetchs(hv, "ReadValueId_dataEncoding", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->dataEncoding, *svp);

	return;
}
#endif

/* ReadRequest */
#ifdef UA_TYPES_READREQUEST
static void pack_UA_ReadRequest(SV *out, const UA_ReadRequest *in);
static void unpack_UA_ReadRequest(UA_ReadRequest *out, SV *in);

static void
pack_UA_ReadRequest(SV *out, const UA_ReadRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReadRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "ReadRequest_maxAge", sv);
	pack_UA_Double(sv, &in->maxAge);

	sv = newSV(0);
	hv_stores(hv, "ReadRequest_timestampsToReturn", sv);
	pack_UA_TimestampsToReturn(sv, &in->timestampsToReturn);

	av = newAV();
	hv_stores(hv, "ReadRequest_nodesToRead", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToReadSize);
	for (i = 0; i < in->nodesToReadSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ReadValueId(sv, &in->nodesToRead[i]);
	}

	return;
}

static void
unpack_UA_ReadRequest(UA_ReadRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "ReadRequest_maxAge", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->maxAge, *svp);

	svp = hv_fetchs(hv, "ReadRequest_timestampsToReturn", 0);
	if (svp != NULL)
		unpack_UA_TimestampsToReturn(&out->timestampsToReturn, *svp);

	svp = hv_fetchs(hv, "ReadRequest_nodesToRead", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReadRequest_nodesToRead");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToRead = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_READVALUEID]);
		if (out->nodesToRead == NULL)
			CROAKE("UA_Array_new");
		out->nodesToReadSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ReadValueId(&out->nodesToRead[i], *svp);
		}
	}

	return;
}
#endif

/* ReadResponse */
#ifdef UA_TYPES_READRESPONSE
static void pack_UA_ReadResponse(SV *out, const UA_ReadResponse *in);
static void unpack_UA_ReadResponse(UA_ReadResponse *out, SV *in);

static void
pack_UA_ReadResponse(SV *out, const UA_ReadResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReadResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "ReadResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DataValue(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "ReadResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_ReadResponse(UA_ReadResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "ReadResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReadResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATAVALUE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DataValue(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ReadResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReadResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryReadValueId */
#ifdef UA_TYPES_HISTORYREADVALUEID
static void pack_UA_HistoryReadValueId(SV *out, const UA_HistoryReadValueId *in);
static void unpack_UA_HistoryReadValueId(UA_HistoryReadValueId *out, SV *in);

static void
pack_UA_HistoryReadValueId(SV *out, const UA_HistoryReadValueId *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryReadValueId_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadValueId_indexRange", sv);
	pack_UA_String(sv, &in->indexRange);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadValueId_dataEncoding", sv);
	pack_UA_QualifiedName(sv, &in->dataEncoding);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadValueId_continuationPoint", sv);
	pack_UA_ByteString(sv, &in->continuationPoint);

	return;
}

static void
unpack_UA_HistoryReadValueId(UA_HistoryReadValueId *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryReadValueId_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryReadValueId_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "HistoryReadValueId_indexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->indexRange, *svp);

	svp = hv_fetchs(hv, "HistoryReadValueId_dataEncoding", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->dataEncoding, *svp);

	svp = hv_fetchs(hv, "HistoryReadValueId_continuationPoint", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->continuationPoint, *svp);

	return;
}
#endif

/* HistoryReadResult */
#ifdef UA_TYPES_HISTORYREADRESULT
static void pack_UA_HistoryReadResult(SV *out, const UA_HistoryReadResult *in);
static void unpack_UA_HistoryReadResult(UA_HistoryReadResult *out, SV *in);

static void
pack_UA_HistoryReadResult(SV *out, const UA_HistoryReadResult *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryReadResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadResult_continuationPoint", sv);
	pack_UA_ByteString(sv, &in->continuationPoint);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadResult_historyData", sv);
	pack_UA_ExtensionObject(sv, &in->historyData);

	return;
}

static void
unpack_UA_HistoryReadResult(UA_HistoryReadResult *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryReadResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryReadResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "HistoryReadResult_continuationPoint", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->continuationPoint, *svp);

	svp = hv_fetchs(hv, "HistoryReadResult_historyData", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->historyData, *svp);

	return;
}
#endif

/* ReadRawModifiedDetails */
#ifdef UA_TYPES_READRAWMODIFIEDDETAILS
static void pack_UA_ReadRawModifiedDetails(SV *out, const UA_ReadRawModifiedDetails *in);
static void unpack_UA_ReadRawModifiedDetails(UA_ReadRawModifiedDetails *out, SV *in);

static void
pack_UA_ReadRawModifiedDetails(SV *out, const UA_ReadRawModifiedDetails *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReadRawModifiedDetails_isReadModified", sv);
	pack_UA_Boolean(sv, &in->isReadModified);

	sv = newSV(0);
	hv_stores(hv, "ReadRawModifiedDetails_startTime", sv);
	pack_UA_DateTime(sv, &in->startTime);

	sv = newSV(0);
	hv_stores(hv, "ReadRawModifiedDetails_endTime", sv);
	pack_UA_DateTime(sv, &in->endTime);

	sv = newSV(0);
	hv_stores(hv, "ReadRawModifiedDetails_numValuesPerNode", sv);
	pack_UA_UInt32(sv, &in->numValuesPerNode);

	sv = newSV(0);
	hv_stores(hv, "ReadRawModifiedDetails_returnBounds", sv);
	pack_UA_Boolean(sv, &in->returnBounds);

	return;
}

static void
unpack_UA_ReadRawModifiedDetails(UA_ReadRawModifiedDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadRawModifiedDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadRawModifiedDetails_isReadModified", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isReadModified, *svp);

	svp = hv_fetchs(hv, "ReadRawModifiedDetails_startTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->startTime, *svp);

	svp = hv_fetchs(hv, "ReadRawModifiedDetails_endTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->endTime, *svp);

	svp = hv_fetchs(hv, "ReadRawModifiedDetails_numValuesPerNode", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->numValuesPerNode, *svp);

	svp = hv_fetchs(hv, "ReadRawModifiedDetails_returnBounds", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->returnBounds, *svp);

	return;
}
#endif

/* ReadAtTimeDetails */
#ifdef UA_TYPES_READATTIMEDETAILS
static void pack_UA_ReadAtTimeDetails(SV *out, const UA_ReadAtTimeDetails *in);
static void unpack_UA_ReadAtTimeDetails(UA_ReadAtTimeDetails *out, SV *in);

static void
pack_UA_ReadAtTimeDetails(SV *out, const UA_ReadAtTimeDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "ReadAtTimeDetails_reqTimes", newRV_noinc((SV*)av));
	av_extend(av, in->reqTimesSize);
	for (i = 0; i < in->reqTimesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DateTime(sv, &in->reqTimes[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ReadAtTimeDetails_useSimpleBounds", sv);
	pack_UA_Boolean(sv, &in->useSimpleBounds);

	return;
}

static void
unpack_UA_ReadAtTimeDetails(UA_ReadAtTimeDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadAtTimeDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadAtTimeDetails_reqTimes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReadAtTimeDetails_reqTimes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->reqTimes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATETIME]);
		if (out->reqTimes == NULL)
			CROAKE("UA_Array_new");
		out->reqTimesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DateTime(&out->reqTimes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ReadAtTimeDetails_useSimpleBounds", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->useSimpleBounds, *svp);

	return;
}
#endif

/* ReadAnnotationDataDetails */
#ifdef UA_TYPES_READANNOTATIONDATADETAILS
static void pack_UA_ReadAnnotationDataDetails(SV *out, const UA_ReadAnnotationDataDetails *in);
static void unpack_UA_ReadAnnotationDataDetails(UA_ReadAnnotationDataDetails *out, SV *in);

static void
pack_UA_ReadAnnotationDataDetails(SV *out, const UA_ReadAnnotationDataDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "ReadAnnotationDataDetails_reqTimes", newRV_noinc((SV*)av));
	av_extend(av, in->reqTimesSize);
	for (i = 0; i < in->reqTimesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DateTime(sv, &in->reqTimes[i]);
	}

	return;
}

static void
unpack_UA_ReadAnnotationDataDetails(UA_ReadAnnotationDataDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadAnnotationDataDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadAnnotationDataDetails_reqTimes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReadAnnotationDataDetails_reqTimes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->reqTimes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATETIME]);
		if (out->reqTimes == NULL)
			CROAKE("UA_Array_new");
		out->reqTimesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DateTime(&out->reqTimes[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryData */
#ifdef UA_TYPES_HISTORYDATA
static void pack_UA_HistoryData(SV *out, const UA_HistoryData *in);
static void unpack_UA_HistoryData(UA_HistoryData *out, SV *in);

static void
pack_UA_HistoryData(SV *out, const UA_HistoryData *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "HistoryData_dataValues", newRV_noinc((SV*)av));
	av_extend(av, in->dataValuesSize);
	for (i = 0; i < in->dataValuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DataValue(sv, &in->dataValues[i]);
	}

	return;
}

static void
unpack_UA_HistoryData(UA_HistoryData *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryData_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryData_dataValues", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryData_dataValues");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataValues = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATAVALUE]);
		if (out->dataValues == NULL)
			CROAKE("UA_Array_new");
		out->dataValuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DataValue(&out->dataValues[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryReadRequest */
#ifdef UA_TYPES_HISTORYREADREQUEST
static void pack_UA_HistoryReadRequest(SV *out, const UA_HistoryReadRequest *in);
static void unpack_UA_HistoryReadRequest(UA_HistoryReadRequest *out, SV *in);

static void
pack_UA_HistoryReadRequest(SV *out, const UA_HistoryReadRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryReadRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadRequest_historyReadDetails", sv);
	pack_UA_ExtensionObject(sv, &in->historyReadDetails);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadRequest_timestampsToReturn", sv);
	pack_UA_TimestampsToReturn(sv, &in->timestampsToReturn);

	sv = newSV(0);
	hv_stores(hv, "HistoryReadRequest_releaseContinuationPoints", sv);
	pack_UA_Boolean(sv, &in->releaseContinuationPoints);

	av = newAV();
	hv_stores(hv, "HistoryReadRequest_nodesToRead", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToReadSize);
	for (i = 0; i < in->nodesToReadSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_HistoryReadValueId(sv, &in->nodesToRead[i]);
	}

	return;
}

static void
unpack_UA_HistoryReadRequest(UA_HistoryReadRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryReadRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryReadRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "HistoryReadRequest_historyReadDetails", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->historyReadDetails, *svp);

	svp = hv_fetchs(hv, "HistoryReadRequest_timestampsToReturn", 0);
	if (svp != NULL)
		unpack_UA_TimestampsToReturn(&out->timestampsToReturn, *svp);

	svp = hv_fetchs(hv, "HistoryReadRequest_releaseContinuationPoints", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->releaseContinuationPoints, *svp);

	svp = hv_fetchs(hv, "HistoryReadRequest_nodesToRead", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryReadRequest_nodesToRead");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToRead = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_HISTORYREADVALUEID]);
		if (out->nodesToRead == NULL)
			CROAKE("UA_Array_new");
		out->nodesToReadSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_HistoryReadValueId(&out->nodesToRead[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryReadResponse */
#ifdef UA_TYPES_HISTORYREADRESPONSE
static void pack_UA_HistoryReadResponse(SV *out, const UA_HistoryReadResponse *in);
static void unpack_UA_HistoryReadResponse(UA_HistoryReadResponse *out, SV *in);

static void
pack_UA_HistoryReadResponse(SV *out, const UA_HistoryReadResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryReadResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "HistoryReadResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_HistoryReadResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "HistoryReadResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_HistoryReadResponse(UA_HistoryReadResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryReadResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryReadResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "HistoryReadResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryReadResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_HISTORYREADRESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_HistoryReadResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "HistoryReadResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryReadResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* WriteValue */
#ifdef UA_TYPES_WRITEVALUE
static void pack_UA_WriteValue(SV *out, const UA_WriteValue *in);
static void unpack_UA_WriteValue(UA_WriteValue *out, SV *in);

static void
pack_UA_WriteValue(SV *out, const UA_WriteValue *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "WriteValue_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "WriteValue_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "WriteValue_indexRange", sv);
	pack_UA_String(sv, &in->indexRange);

	sv = newSV(0);
	hv_stores(hv, "WriteValue_value", sv);
	pack_UA_DataValue(sv, &in->value);

	return;
}

static void
unpack_UA_WriteValue(UA_WriteValue *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_WriteValue_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "WriteValue_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "WriteValue_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "WriteValue_indexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->indexRange, *svp);

	svp = hv_fetchs(hv, "WriteValue_value", 0);
	if (svp != NULL)
		unpack_UA_DataValue(&out->value, *svp);

	return;
}
#endif

/* WriteRequest */
#ifdef UA_TYPES_WRITEREQUEST
static void pack_UA_WriteRequest(SV *out, const UA_WriteRequest *in);
static void unpack_UA_WriteRequest(UA_WriteRequest *out, SV *in);

static void
pack_UA_WriteRequest(SV *out, const UA_WriteRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "WriteRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "WriteRequest_nodesToWrite", newRV_noinc((SV*)av));
	av_extend(av, in->nodesToWriteSize);
	for (i = 0; i < in->nodesToWriteSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_WriteValue(sv, &in->nodesToWrite[i]);
	}

	return;
}

static void
unpack_UA_WriteRequest(UA_WriteRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_WriteRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "WriteRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "WriteRequest_nodesToWrite", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for WriteRequest_nodesToWrite");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->nodesToWrite = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_WRITEVALUE]);
		if (out->nodesToWrite == NULL)
			CROAKE("UA_Array_new");
		out->nodesToWriteSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_WriteValue(&out->nodesToWrite[i], *svp);
		}
	}

	return;
}
#endif

/* WriteResponse */
#ifdef UA_TYPES_WRITERESPONSE
static void pack_UA_WriteResponse(SV *out, const UA_WriteResponse *in);
static void unpack_UA_WriteResponse(UA_WriteResponse *out, SV *in);

static void
pack_UA_WriteResponse(SV *out, const UA_WriteResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "WriteResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "WriteResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "WriteResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_WriteResponse(UA_WriteResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_WriteResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "WriteResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "WriteResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for WriteResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "WriteResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for WriteResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryUpdateDetails */
#ifdef UA_TYPES_HISTORYUPDATEDETAILS
static void pack_UA_HistoryUpdateDetails(SV *out, const UA_HistoryUpdateDetails *in);
static void unpack_UA_HistoryUpdateDetails(UA_HistoryUpdateDetails *out, SV *in);

static void
pack_UA_HistoryUpdateDetails(SV *out, const UA_HistoryUpdateDetails *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryUpdateDetails_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	return;
}

static void
unpack_UA_HistoryUpdateDetails(UA_HistoryUpdateDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryUpdateDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryUpdateDetails_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	return;
}
#endif

/* HistoryUpdateType */
#ifdef UA_TYPES_HISTORYUPDATETYPE
static void pack_UA_HistoryUpdateType(SV *out, const UA_HistoryUpdateType *in);
static void unpack_UA_HistoryUpdateType(UA_HistoryUpdateType *out, SV *in);

static void
pack_UA_HistoryUpdateType(SV *out, const UA_HistoryUpdateType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_HistoryUpdateType(UA_HistoryUpdateType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* PerformUpdateType */
#ifdef UA_TYPES_PERFORMUPDATETYPE
static void pack_UA_PerformUpdateType(SV *out, const UA_PerformUpdateType *in);
static void unpack_UA_PerformUpdateType(UA_PerformUpdateType *out, SV *in);

static void
pack_UA_PerformUpdateType(SV *out, const UA_PerformUpdateType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_PerformUpdateType(UA_PerformUpdateType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* UpdateDataDetails */
#ifdef UA_TYPES_UPDATEDATADETAILS
static void pack_UA_UpdateDataDetails(SV *out, const UA_UpdateDataDetails *in);
static void unpack_UA_UpdateDataDetails(UA_UpdateDataDetails *out, SV *in);

static void
pack_UA_UpdateDataDetails(SV *out, const UA_UpdateDataDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UpdateDataDetails_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "UpdateDataDetails_performInsertReplace", sv);
	pack_UA_PerformUpdateType(sv, &in->performInsertReplace);

	av = newAV();
	hv_stores(hv, "UpdateDataDetails_updateValues", newRV_noinc((SV*)av));
	av_extend(av, in->updateValuesSize);
	for (i = 0; i < in->updateValuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DataValue(sv, &in->updateValues[i]);
	}

	return;
}

static void
unpack_UA_UpdateDataDetails(UA_UpdateDataDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UpdateDataDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UpdateDataDetails_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "UpdateDataDetails_performInsertReplace", 0);
	if (svp != NULL)
		unpack_UA_PerformUpdateType(&out->performInsertReplace, *svp);

	svp = hv_fetchs(hv, "UpdateDataDetails_updateValues", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UpdateDataDetails_updateValues");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->updateValues = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATAVALUE]);
		if (out->updateValues == NULL)
			CROAKE("UA_Array_new");
		out->updateValuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DataValue(&out->updateValues[i], *svp);
		}
	}

	return;
}
#endif

/* UpdateStructureDataDetails */
#ifdef UA_TYPES_UPDATESTRUCTUREDATADETAILS
static void pack_UA_UpdateStructureDataDetails(SV *out, const UA_UpdateStructureDataDetails *in);
static void unpack_UA_UpdateStructureDataDetails(UA_UpdateStructureDataDetails *out, SV *in);

static void
pack_UA_UpdateStructureDataDetails(SV *out, const UA_UpdateStructureDataDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UpdateStructureDataDetails_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "UpdateStructureDataDetails_performInsertReplace", sv);
	pack_UA_PerformUpdateType(sv, &in->performInsertReplace);

	av = newAV();
	hv_stores(hv, "UpdateStructureDataDetails_updateValues", newRV_noinc((SV*)av));
	av_extend(av, in->updateValuesSize);
	for (i = 0; i < in->updateValuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DataValue(sv, &in->updateValues[i]);
	}

	return;
}

static void
unpack_UA_UpdateStructureDataDetails(UA_UpdateStructureDataDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UpdateStructureDataDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UpdateStructureDataDetails_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "UpdateStructureDataDetails_performInsertReplace", 0);
	if (svp != NULL)
		unpack_UA_PerformUpdateType(&out->performInsertReplace, *svp);

	svp = hv_fetchs(hv, "UpdateStructureDataDetails_updateValues", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UpdateStructureDataDetails_updateValues");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->updateValues = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATAVALUE]);
		if (out->updateValues == NULL)
			CROAKE("UA_Array_new");
		out->updateValuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DataValue(&out->updateValues[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteRawModifiedDetails */
#ifdef UA_TYPES_DELETERAWMODIFIEDDETAILS
static void pack_UA_DeleteRawModifiedDetails(SV *out, const UA_DeleteRawModifiedDetails *in);
static void unpack_UA_DeleteRawModifiedDetails(UA_DeleteRawModifiedDetails *out, SV *in);

static void
pack_UA_DeleteRawModifiedDetails(SV *out, const UA_DeleteRawModifiedDetails *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteRawModifiedDetails_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "DeleteRawModifiedDetails_isDeleteModified", sv);
	pack_UA_Boolean(sv, &in->isDeleteModified);

	sv = newSV(0);
	hv_stores(hv, "DeleteRawModifiedDetails_startTime", sv);
	pack_UA_DateTime(sv, &in->startTime);

	sv = newSV(0);
	hv_stores(hv, "DeleteRawModifiedDetails_endTime", sv);
	pack_UA_DateTime(sv, &in->endTime);

	return;
}

static void
unpack_UA_DeleteRawModifiedDetails(UA_DeleteRawModifiedDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteRawModifiedDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteRawModifiedDetails_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "DeleteRawModifiedDetails_isDeleteModified", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->isDeleteModified, *svp);

	svp = hv_fetchs(hv, "DeleteRawModifiedDetails_startTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->startTime, *svp);

	svp = hv_fetchs(hv, "DeleteRawModifiedDetails_endTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->endTime, *svp);

	return;
}
#endif

/* DeleteAtTimeDetails */
#ifdef UA_TYPES_DELETEATTIMEDETAILS
static void pack_UA_DeleteAtTimeDetails(SV *out, const UA_DeleteAtTimeDetails *in);
static void unpack_UA_DeleteAtTimeDetails(UA_DeleteAtTimeDetails *out, SV *in);

static void
pack_UA_DeleteAtTimeDetails(SV *out, const UA_DeleteAtTimeDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteAtTimeDetails_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	av = newAV();
	hv_stores(hv, "DeleteAtTimeDetails_reqTimes", newRV_noinc((SV*)av));
	av_extend(av, in->reqTimesSize);
	for (i = 0; i < in->reqTimesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DateTime(sv, &in->reqTimes[i]);
	}

	return;
}

static void
unpack_UA_DeleteAtTimeDetails(UA_DeleteAtTimeDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteAtTimeDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteAtTimeDetails_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "DeleteAtTimeDetails_reqTimes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteAtTimeDetails_reqTimes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->reqTimes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATETIME]);
		if (out->reqTimes == NULL)
			CROAKE("UA_Array_new");
		out->reqTimesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DateTime(&out->reqTimes[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteEventDetails */
#ifdef UA_TYPES_DELETEEVENTDETAILS
static void pack_UA_DeleteEventDetails(SV *out, const UA_DeleteEventDetails *in);
static void unpack_UA_DeleteEventDetails(UA_DeleteEventDetails *out, SV *in);

static void
pack_UA_DeleteEventDetails(SV *out, const UA_DeleteEventDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteEventDetails_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	av = newAV();
	hv_stores(hv, "DeleteEventDetails_eventIds", newRV_noinc((SV*)av));
	av_extend(av, in->eventIdsSize);
	for (i = 0; i < in->eventIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ByteString(sv, &in->eventIds[i]);
	}

	return;
}

static void
unpack_UA_DeleteEventDetails(UA_DeleteEventDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteEventDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteEventDetails_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "DeleteEventDetails_eventIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteEventDetails_eventIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->eventIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BYTESTRING]);
		if (out->eventIds == NULL)
			CROAKE("UA_Array_new");
		out->eventIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ByteString(&out->eventIds[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryUpdateResult */
#ifdef UA_TYPES_HISTORYUPDATERESULT
static void pack_UA_HistoryUpdateResult(SV *out, const UA_HistoryUpdateResult *in);
static void unpack_UA_HistoryUpdateResult(UA_HistoryUpdateResult *out, SV *in);

static void
pack_UA_HistoryUpdateResult(SV *out, const UA_HistoryUpdateResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryUpdateResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	av = newAV();
	hv_stores(hv, "HistoryUpdateResult_operationResults", newRV_noinc((SV*)av));
	av_extend(av, in->operationResultsSize);
	for (i = 0; i < in->operationResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->operationResults[i]);
	}

	av = newAV();
	hv_stores(hv, "HistoryUpdateResult_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_HistoryUpdateResult(UA_HistoryUpdateResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryUpdateResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryUpdateResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "HistoryUpdateResult_operationResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryUpdateResult_operationResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->operationResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->operationResults == NULL)
			CROAKE("UA_Array_new");
		out->operationResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->operationResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "HistoryUpdateResult_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryUpdateResult_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryUpdateRequest */
#ifdef UA_TYPES_HISTORYUPDATEREQUEST
static void pack_UA_HistoryUpdateRequest(SV *out, const UA_HistoryUpdateRequest *in);
static void unpack_UA_HistoryUpdateRequest(UA_HistoryUpdateRequest *out, SV *in);

static void
pack_UA_HistoryUpdateRequest(SV *out, const UA_HistoryUpdateRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryUpdateRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "HistoryUpdateRequest_historyUpdateDetails", newRV_noinc((SV*)av));
	av_extend(av, in->historyUpdateDetailsSize);
	for (i = 0; i < in->historyUpdateDetailsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ExtensionObject(sv, &in->historyUpdateDetails[i]);
	}

	return;
}

static void
unpack_UA_HistoryUpdateRequest(UA_HistoryUpdateRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryUpdateRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryUpdateRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "HistoryUpdateRequest_historyUpdateDetails", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryUpdateRequest_historyUpdateDetails");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->historyUpdateDetails = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXTENSIONOBJECT]);
		if (out->historyUpdateDetails == NULL)
			CROAKE("UA_Array_new");
		out->historyUpdateDetailsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ExtensionObject(&out->historyUpdateDetails[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryUpdateResponse */
#ifdef UA_TYPES_HISTORYUPDATERESPONSE
static void pack_UA_HistoryUpdateResponse(SV *out, const UA_HistoryUpdateResponse *in);
static void unpack_UA_HistoryUpdateResponse(UA_HistoryUpdateResponse *out, SV *in);

static void
pack_UA_HistoryUpdateResponse(SV *out, const UA_HistoryUpdateResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "HistoryUpdateResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "HistoryUpdateResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_HistoryUpdateResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "HistoryUpdateResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_HistoryUpdateResponse(UA_HistoryUpdateResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryUpdateResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryUpdateResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "HistoryUpdateResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryUpdateResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_HISTORYUPDATERESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_HistoryUpdateResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "HistoryUpdateResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryUpdateResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* CallMethodRequest */
#ifdef UA_TYPES_CALLMETHODREQUEST
static void pack_UA_CallMethodRequest(SV *out, const UA_CallMethodRequest *in);
static void unpack_UA_CallMethodRequest(UA_CallMethodRequest *out, SV *in);

static void
pack_UA_CallMethodRequest(SV *out, const UA_CallMethodRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CallMethodRequest_objectId", sv);
	pack_UA_NodeId(sv, &in->objectId);

	sv = newSV(0);
	hv_stores(hv, "CallMethodRequest_methodId", sv);
	pack_UA_NodeId(sv, &in->methodId);

	av = newAV();
	hv_stores(hv, "CallMethodRequest_inputArguments", newRV_noinc((SV*)av));
	av_extend(av, in->inputArgumentsSize);
	for (i = 0; i < in->inputArgumentsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Variant(sv, &in->inputArguments[i]);
	}

	return;
}

static void
unpack_UA_CallMethodRequest(UA_CallMethodRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CallMethodRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallMethodRequest_objectId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->objectId, *svp);

	svp = hv_fetchs(hv, "CallMethodRequest_methodId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->methodId, *svp);

	svp = hv_fetchs(hv, "CallMethodRequest_inputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CallMethodRequest_inputArguments");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->inputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out->inputArguments == NULL)
			CROAKE("UA_Array_new");
		out->inputArgumentsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Variant(&out->inputArguments[i], *svp);
		}
	}

	return;
}
#endif

/* CallMethodResult */
#ifdef UA_TYPES_CALLMETHODRESULT
static void pack_UA_CallMethodResult(SV *out, const UA_CallMethodResult *in);
static void unpack_UA_CallMethodResult(UA_CallMethodResult *out, SV *in);

static void
pack_UA_CallMethodResult(SV *out, const UA_CallMethodResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CallMethodResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	av = newAV();
	hv_stores(hv, "CallMethodResult_inputArgumentResults", newRV_noinc((SV*)av));
	av_extend(av, in->inputArgumentResultsSize);
	for (i = 0; i < in->inputArgumentResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->inputArgumentResults[i]);
	}

	av = newAV();
	hv_stores(hv, "CallMethodResult_inputArgumentDiagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->inputArgumentDiagnosticInfosSize);
	for (i = 0; i < in->inputArgumentDiagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->inputArgumentDiagnosticInfos[i]);
	}

	av = newAV();
	hv_stores(hv, "CallMethodResult_outputArguments", newRV_noinc((SV*)av));
	av_extend(av, in->outputArgumentsSize);
	for (i = 0; i < in->outputArgumentsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Variant(sv, &in->outputArguments[i]);
	}

	return;
}

static void
unpack_UA_CallMethodResult(UA_CallMethodResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CallMethodResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallMethodResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "CallMethodResult_inputArgumentResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CallMethodResult_inputArgumentResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->inputArgumentResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->inputArgumentResults == NULL)
			CROAKE("UA_Array_new");
		out->inputArgumentResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->inputArgumentResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "CallMethodResult_inputArgumentDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CallMethodResult_inputArgumentDiagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->inputArgumentDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->inputArgumentDiagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->inputArgumentDiagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->inputArgumentDiagnosticInfos[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "CallMethodResult_outputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CallMethodResult_outputArguments");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->outputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out->outputArguments == NULL)
			CROAKE("UA_Array_new");
		out->outputArgumentsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Variant(&out->outputArguments[i], *svp);
		}
	}

	return;
}
#endif

/* CallRequest */
#ifdef UA_TYPES_CALLREQUEST
static void pack_UA_CallRequest(SV *out, const UA_CallRequest *in);
static void unpack_UA_CallRequest(UA_CallRequest *out, SV *in);

static void
pack_UA_CallRequest(SV *out, const UA_CallRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CallRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "CallRequest_methodsToCall", newRV_noinc((SV*)av));
	av_extend(av, in->methodsToCallSize);
	for (i = 0; i < in->methodsToCallSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_CallMethodRequest(sv, &in->methodsToCall[i]);
	}

	return;
}

static void
unpack_UA_CallRequest(UA_CallRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CallRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "CallRequest_methodsToCall", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CallRequest_methodsToCall");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->methodsToCall = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CALLMETHODREQUEST]);
		if (out->methodsToCall == NULL)
			CROAKE("UA_Array_new");
		out->methodsToCallSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_CallMethodRequest(&out->methodsToCall[i], *svp);
		}
	}

	return;
}
#endif

/* CallResponse */
#ifdef UA_TYPES_CALLRESPONSE
static void pack_UA_CallResponse(SV *out, const UA_CallResponse *in);
static void unpack_UA_CallResponse(UA_CallResponse *out, SV *in);

static void
pack_UA_CallResponse(SV *out, const UA_CallResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CallResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "CallResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_CallMethodResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "CallResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_CallResponse(UA_CallResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CallResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "CallResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CallResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CALLMETHODRESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_CallMethodResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "CallResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CallResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* MonitoringMode */
#ifdef UA_TYPES_MONITORINGMODE
static void pack_UA_MonitoringMode(SV *out, const UA_MonitoringMode *in);
static void unpack_UA_MonitoringMode(UA_MonitoringMode *out, SV *in);

static void
pack_UA_MonitoringMode(SV *out, const UA_MonitoringMode *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_MonitoringMode(UA_MonitoringMode *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* DataChangeTrigger */
#ifdef UA_TYPES_DATACHANGETRIGGER
static void pack_UA_DataChangeTrigger(SV *out, const UA_DataChangeTrigger *in);
static void unpack_UA_DataChangeTrigger(UA_DataChangeTrigger *out, SV *in);

static void
pack_UA_DataChangeTrigger(SV *out, const UA_DataChangeTrigger *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_DataChangeTrigger(UA_DataChangeTrigger *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* DeadbandType */
#ifdef UA_TYPES_DEADBANDTYPE
static void pack_UA_DeadbandType(SV *out, const UA_DeadbandType *in);
static void unpack_UA_DeadbandType(UA_DeadbandType *out, SV *in);

static void
pack_UA_DeadbandType(SV *out, const UA_DeadbandType *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_DeadbandType(UA_DeadbandType *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* DataChangeFilter */
#ifdef UA_TYPES_DATACHANGEFILTER
static void pack_UA_DataChangeFilter(SV *out, const UA_DataChangeFilter *in);
static void unpack_UA_DataChangeFilter(UA_DataChangeFilter *out, SV *in);

static void
pack_UA_DataChangeFilter(SV *out, const UA_DataChangeFilter *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DataChangeFilter_trigger", sv);
	pack_UA_DataChangeTrigger(sv, &in->trigger);

	sv = newSV(0);
	hv_stores(hv, "DataChangeFilter_deadbandType", sv);
	pack_UA_UInt32(sv, &in->deadbandType);

	sv = newSV(0);
	hv_stores(hv, "DataChangeFilter_deadbandValue", sv);
	pack_UA_Double(sv, &in->deadbandValue);

	return;
}

static void
unpack_UA_DataChangeFilter(UA_DataChangeFilter *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataChangeFilter_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataChangeFilter_trigger", 0);
	if (svp != NULL)
		unpack_UA_DataChangeTrigger(&out->trigger, *svp);

	svp = hv_fetchs(hv, "DataChangeFilter_deadbandType", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->deadbandType, *svp);

	svp = hv_fetchs(hv, "DataChangeFilter_deadbandValue", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->deadbandValue, *svp);

	return;
}
#endif

/* EventFilter */
#ifdef UA_TYPES_EVENTFILTER
static void pack_UA_EventFilter(SV *out, const UA_EventFilter *in);
static void unpack_UA_EventFilter(UA_EventFilter *out, SV *in);

static void
pack_UA_EventFilter(SV *out, const UA_EventFilter *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "EventFilter_selectClauses", newRV_noinc((SV*)av));
	av_extend(av, in->selectClausesSize);
	for (i = 0; i < in->selectClausesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SimpleAttributeOperand(sv, &in->selectClauses[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "EventFilter_whereClause", sv);
	pack_UA_ContentFilter(sv, &in->whereClause);

	return;
}

static void
unpack_UA_EventFilter(UA_EventFilter *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EventFilter_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventFilter_selectClauses", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EventFilter_selectClauses");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->selectClauses = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIMPLEATTRIBUTEOPERAND]);
		if (out->selectClauses == NULL)
			CROAKE("UA_Array_new");
		out->selectClausesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SimpleAttributeOperand(&out->selectClauses[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "EventFilter_whereClause", 0);
	if (svp != NULL)
		unpack_UA_ContentFilter(&out->whereClause, *svp);

	return;
}
#endif

/* AggregateConfiguration */
#ifdef UA_TYPES_AGGREGATECONFIGURATION
static void pack_UA_AggregateConfiguration(SV *out, const UA_AggregateConfiguration *in);
static void unpack_UA_AggregateConfiguration(UA_AggregateConfiguration *out, SV *in);

static void
pack_UA_AggregateConfiguration(SV *out, const UA_AggregateConfiguration *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AggregateConfiguration_useServerCapabilitiesDefaults", sv);
	pack_UA_Boolean(sv, &in->useServerCapabilitiesDefaults);

	sv = newSV(0);
	hv_stores(hv, "AggregateConfiguration_treatUncertainAsBad", sv);
	pack_UA_Boolean(sv, &in->treatUncertainAsBad);

	sv = newSV(0);
	hv_stores(hv, "AggregateConfiguration_percentDataBad", sv);
	pack_UA_Byte(sv, &in->percentDataBad);

	sv = newSV(0);
	hv_stores(hv, "AggregateConfiguration_percentDataGood", sv);
	pack_UA_Byte(sv, &in->percentDataGood);

	sv = newSV(0);
	hv_stores(hv, "AggregateConfiguration_useSlopedExtrapolation", sv);
	pack_UA_Boolean(sv, &in->useSlopedExtrapolation);

	return;
}

static void
unpack_UA_AggregateConfiguration(UA_AggregateConfiguration *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AggregateConfiguration_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AggregateConfiguration_useServerCapabilitiesDefaults", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->useServerCapabilitiesDefaults, *svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_treatUncertainAsBad", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->treatUncertainAsBad, *svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_percentDataBad", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->percentDataBad, *svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_percentDataGood", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->percentDataGood, *svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_useSlopedExtrapolation", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->useSlopedExtrapolation, *svp);

	return;
}
#endif

/* AggregateFilter */
#ifdef UA_TYPES_AGGREGATEFILTER
static void pack_UA_AggregateFilter(SV *out, const UA_AggregateFilter *in);
static void unpack_UA_AggregateFilter(UA_AggregateFilter *out, SV *in);

static void
pack_UA_AggregateFilter(SV *out, const UA_AggregateFilter *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AggregateFilter_startTime", sv);
	pack_UA_DateTime(sv, &in->startTime);

	sv = newSV(0);
	hv_stores(hv, "AggregateFilter_aggregateType", sv);
	pack_UA_NodeId(sv, &in->aggregateType);

	sv = newSV(0);
	hv_stores(hv, "AggregateFilter_processingInterval", sv);
	pack_UA_Double(sv, &in->processingInterval);

	sv = newSV(0);
	hv_stores(hv, "AggregateFilter_aggregateConfiguration", sv);
	pack_UA_AggregateConfiguration(sv, &in->aggregateConfiguration);

	return;
}

static void
unpack_UA_AggregateFilter(UA_AggregateFilter *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AggregateFilter_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AggregateFilter_startTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->startTime, *svp);

	svp = hv_fetchs(hv, "AggregateFilter_aggregateType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->aggregateType, *svp);

	svp = hv_fetchs(hv, "AggregateFilter_processingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->processingInterval, *svp);

	svp = hv_fetchs(hv, "AggregateFilter_aggregateConfiguration", 0);
	if (svp != NULL)
		unpack_UA_AggregateConfiguration(&out->aggregateConfiguration, *svp);

	return;
}
#endif

/* EventFilterResult */
#ifdef UA_TYPES_EVENTFILTERRESULT
static void pack_UA_EventFilterResult(SV *out, const UA_EventFilterResult *in);
static void unpack_UA_EventFilterResult(UA_EventFilterResult *out, SV *in);

static void
pack_UA_EventFilterResult(SV *out, const UA_EventFilterResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "EventFilterResult_selectClauseResults", newRV_noinc((SV*)av));
	av_extend(av, in->selectClauseResultsSize);
	for (i = 0; i < in->selectClauseResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->selectClauseResults[i]);
	}

	av = newAV();
	hv_stores(hv, "EventFilterResult_selectClauseDiagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->selectClauseDiagnosticInfosSize);
	for (i = 0; i < in->selectClauseDiagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->selectClauseDiagnosticInfos[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "EventFilterResult_whereClauseResult", sv);
	pack_UA_ContentFilterResult(sv, &in->whereClauseResult);

	return;
}

static void
unpack_UA_EventFilterResult(UA_EventFilterResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EventFilterResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventFilterResult_selectClauseResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EventFilterResult_selectClauseResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->selectClauseResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->selectClauseResults == NULL)
			CROAKE("UA_Array_new");
		out->selectClauseResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->selectClauseResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "EventFilterResult_selectClauseDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EventFilterResult_selectClauseDiagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->selectClauseDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->selectClauseDiagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->selectClauseDiagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->selectClauseDiagnosticInfos[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "EventFilterResult_whereClauseResult", 0);
	if (svp != NULL)
		unpack_UA_ContentFilterResult(&out->whereClauseResult, *svp);

	return;
}
#endif

/* AggregateFilterResult */
#ifdef UA_TYPES_AGGREGATEFILTERRESULT
static void pack_UA_AggregateFilterResult(SV *out, const UA_AggregateFilterResult *in);
static void unpack_UA_AggregateFilterResult(UA_AggregateFilterResult *out, SV *in);

static void
pack_UA_AggregateFilterResult(SV *out, const UA_AggregateFilterResult *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AggregateFilterResult_revisedStartTime", sv);
	pack_UA_DateTime(sv, &in->revisedStartTime);

	sv = newSV(0);
	hv_stores(hv, "AggregateFilterResult_revisedProcessingInterval", sv);
	pack_UA_Double(sv, &in->revisedProcessingInterval);

	sv = newSV(0);
	hv_stores(hv, "AggregateFilterResult_revisedAggregateConfiguration", sv);
	pack_UA_AggregateConfiguration(sv, &in->revisedAggregateConfiguration);

	return;
}

static void
unpack_UA_AggregateFilterResult(UA_AggregateFilterResult *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AggregateFilterResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AggregateFilterResult_revisedStartTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->revisedStartTime, *svp);

	svp = hv_fetchs(hv, "AggregateFilterResult_revisedProcessingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->revisedProcessingInterval, *svp);

	svp = hv_fetchs(hv, "AggregateFilterResult_revisedAggregateConfiguration", 0);
	if (svp != NULL)
		unpack_UA_AggregateConfiguration(&out->revisedAggregateConfiguration, *svp);

	return;
}
#endif

/* MonitoringParameters */
#ifdef UA_TYPES_MONITORINGPARAMETERS
static void pack_UA_MonitoringParameters(SV *out, const UA_MonitoringParameters *in);
static void unpack_UA_MonitoringParameters(UA_MonitoringParameters *out, SV *in);

static void
pack_UA_MonitoringParameters(SV *out, const UA_MonitoringParameters *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MonitoringParameters_clientHandle", sv);
	pack_UA_UInt32(sv, &in->clientHandle);

	sv = newSV(0);
	hv_stores(hv, "MonitoringParameters_samplingInterval", sv);
	pack_UA_Double(sv, &in->samplingInterval);

	sv = newSV(0);
	hv_stores(hv, "MonitoringParameters_filter", sv);
	pack_UA_ExtensionObject(sv, &in->filter);

	sv = newSV(0);
	hv_stores(hv, "MonitoringParameters_queueSize", sv);
	pack_UA_UInt32(sv, &in->queueSize);

	sv = newSV(0);
	hv_stores(hv, "MonitoringParameters_discardOldest", sv);
	pack_UA_Boolean(sv, &in->discardOldest);

	return;
}

static void
unpack_UA_MonitoringParameters(UA_MonitoringParameters *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MonitoringParameters_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoringParameters_clientHandle", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->clientHandle, *svp);

	svp = hv_fetchs(hv, "MonitoringParameters_samplingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->samplingInterval, *svp);

	svp = hv_fetchs(hv, "MonitoringParameters_filter", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->filter, *svp);

	svp = hv_fetchs(hv, "MonitoringParameters_queueSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->queueSize, *svp);

	svp = hv_fetchs(hv, "MonitoringParameters_discardOldest", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->discardOldest, *svp);

	return;
}
#endif

/* MonitoredItemCreateRequest */
#ifdef UA_TYPES_MONITOREDITEMCREATEREQUEST
static void pack_UA_MonitoredItemCreateRequest(SV *out, const UA_MonitoredItemCreateRequest *in);
static void unpack_UA_MonitoredItemCreateRequest(UA_MonitoredItemCreateRequest *out, SV *in);

static void
pack_UA_MonitoredItemCreateRequest(SV *out, const UA_MonitoredItemCreateRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateRequest_itemToMonitor", sv);
	pack_UA_ReadValueId(sv, &in->itemToMonitor);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateRequest_monitoringMode", sv);
	pack_UA_MonitoringMode(sv, &in->monitoringMode);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateRequest_requestedParameters", sv);
	pack_UA_MonitoringParameters(sv, &in->requestedParameters);

	return;
}

static void
unpack_UA_MonitoredItemCreateRequest(UA_MonitoredItemCreateRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MonitoredItemCreateRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemCreateRequest_itemToMonitor", 0);
	if (svp != NULL)
		unpack_UA_ReadValueId(&out->itemToMonitor, *svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateRequest_monitoringMode", 0);
	if (svp != NULL)
		unpack_UA_MonitoringMode(&out->monitoringMode, *svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateRequest_requestedParameters", 0);
	if (svp != NULL)
		unpack_UA_MonitoringParameters(&out->requestedParameters, *svp);

	return;
}
#endif

/* MonitoredItemCreateResult */
#ifdef UA_TYPES_MONITOREDITEMCREATERESULT
static void pack_UA_MonitoredItemCreateResult(SV *out, const UA_MonitoredItemCreateResult *in);
static void unpack_UA_MonitoredItemCreateResult(UA_MonitoredItemCreateResult *out, SV *in);

static void
pack_UA_MonitoredItemCreateResult(SV *out, const UA_MonitoredItemCreateResult *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateResult_monitoredItemId", sv);
	pack_UA_UInt32(sv, &in->monitoredItemId);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateResult_revisedSamplingInterval", sv);
	pack_UA_Double(sv, &in->revisedSamplingInterval);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateResult_revisedQueueSize", sv);
	pack_UA_UInt32(sv, &in->revisedQueueSize);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemCreateResult_filterResult", sv);
	pack_UA_ExtensionObject(sv, &in->filterResult);

	return;
}

static void
unpack_UA_MonitoredItemCreateResult(UA_MonitoredItemCreateResult *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MonitoredItemCreateResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_monitoredItemId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->monitoredItemId, *svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_revisedSamplingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->revisedSamplingInterval, *svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_revisedQueueSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->revisedQueueSize, *svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_filterResult", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->filterResult, *svp);

	return;
}
#endif

/* CreateMonitoredItemsRequest */
#ifdef UA_TYPES_CREATEMONITOREDITEMSREQUEST
static void pack_UA_CreateMonitoredItemsRequest(SV *out, const UA_CreateMonitoredItemsRequest *in);
static void unpack_UA_CreateMonitoredItemsRequest(UA_CreateMonitoredItemsRequest *out, SV *in);

static void
pack_UA_CreateMonitoredItemsRequest(SV *out, const UA_CreateMonitoredItemsRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CreateMonitoredItemsRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "CreateMonitoredItemsRequest_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "CreateMonitoredItemsRequest_timestampsToReturn", sv);
	pack_UA_TimestampsToReturn(sv, &in->timestampsToReturn);

	av = newAV();
	hv_stores(hv, "CreateMonitoredItemsRequest_itemsToCreate", newRV_noinc((SV*)av));
	av_extend(av, in->itemsToCreateSize);
	for (i = 0; i < in->itemsToCreateSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_MonitoredItemCreateRequest(sv, &in->itemsToCreate[i]);
	}

	return;
}

static void
unpack_UA_CreateMonitoredItemsRequest(UA_CreateMonitoredItemsRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CreateMonitoredItemsRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_timestampsToReturn", 0);
	if (svp != NULL)
		unpack_UA_TimestampsToReturn(&out->timestampsToReturn, *svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_itemsToCreate", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CreateMonitoredItemsRequest_itemsToCreate");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->itemsToCreate = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMCREATEREQUEST]);
		if (out->itemsToCreate == NULL)
			CROAKE("UA_Array_new");
		out->itemsToCreateSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_MonitoredItemCreateRequest(&out->itemsToCreate[i], *svp);
		}
	}

	return;
}
#endif

/* CreateMonitoredItemsResponse */
#ifdef UA_TYPES_CREATEMONITOREDITEMSRESPONSE
static void pack_UA_CreateMonitoredItemsResponse(SV *out, const UA_CreateMonitoredItemsResponse *in);
static void unpack_UA_CreateMonitoredItemsResponse(UA_CreateMonitoredItemsResponse *out, SV *in);

static void
pack_UA_CreateMonitoredItemsResponse(SV *out, const UA_CreateMonitoredItemsResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CreateMonitoredItemsResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "CreateMonitoredItemsResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_MonitoredItemCreateResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "CreateMonitoredItemsResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_CreateMonitoredItemsResponse(UA_CreateMonitoredItemsResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CreateMonitoredItemsResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateMonitoredItemsResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CreateMonitoredItemsResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMCREATERESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_MonitoredItemCreateResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "CreateMonitoredItemsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for CreateMonitoredItemsResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* MonitoredItemModifyRequest */
#ifdef UA_TYPES_MONITOREDITEMMODIFYREQUEST
static void pack_UA_MonitoredItemModifyRequest(SV *out, const UA_MonitoredItemModifyRequest *in);
static void unpack_UA_MonitoredItemModifyRequest(UA_MonitoredItemModifyRequest *out, SV *in);

static void
pack_UA_MonitoredItemModifyRequest(SV *out, const UA_MonitoredItemModifyRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemModifyRequest_monitoredItemId", sv);
	pack_UA_UInt32(sv, &in->monitoredItemId);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemModifyRequest_requestedParameters", sv);
	pack_UA_MonitoringParameters(sv, &in->requestedParameters);

	return;
}

static void
unpack_UA_MonitoredItemModifyRequest(UA_MonitoredItemModifyRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MonitoredItemModifyRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemModifyRequest_monitoredItemId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->monitoredItemId, *svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyRequest_requestedParameters", 0);
	if (svp != NULL)
		unpack_UA_MonitoringParameters(&out->requestedParameters, *svp);

	return;
}
#endif

/* MonitoredItemModifyResult */
#ifdef UA_TYPES_MONITOREDITEMMODIFYRESULT
static void pack_UA_MonitoredItemModifyResult(SV *out, const UA_MonitoredItemModifyResult *in);
static void unpack_UA_MonitoredItemModifyResult(UA_MonitoredItemModifyResult *out, SV *in);

static void
pack_UA_MonitoredItemModifyResult(SV *out, const UA_MonitoredItemModifyResult *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemModifyResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemModifyResult_revisedSamplingInterval", sv);
	pack_UA_Double(sv, &in->revisedSamplingInterval);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemModifyResult_revisedQueueSize", sv);
	pack_UA_UInt32(sv, &in->revisedQueueSize);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemModifyResult_filterResult", sv);
	pack_UA_ExtensionObject(sv, &in->filterResult);

	return;
}

static void
unpack_UA_MonitoredItemModifyResult(UA_MonitoredItemModifyResult *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MonitoredItemModifyResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_revisedSamplingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->revisedSamplingInterval, *svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_revisedQueueSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->revisedQueueSize, *svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_filterResult", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->filterResult, *svp);

	return;
}
#endif

/* ModifyMonitoredItemsRequest */
#ifdef UA_TYPES_MODIFYMONITOREDITEMSREQUEST
static void pack_UA_ModifyMonitoredItemsRequest(SV *out, const UA_ModifyMonitoredItemsRequest *in);
static void unpack_UA_ModifyMonitoredItemsRequest(UA_ModifyMonitoredItemsRequest *out, SV *in);

static void
pack_UA_ModifyMonitoredItemsRequest(SV *out, const UA_ModifyMonitoredItemsRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ModifyMonitoredItemsRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "ModifyMonitoredItemsRequest_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "ModifyMonitoredItemsRequest_timestampsToReturn", sv);
	pack_UA_TimestampsToReturn(sv, &in->timestampsToReturn);

	av = newAV();
	hv_stores(hv, "ModifyMonitoredItemsRequest_itemsToModify", newRV_noinc((SV*)av));
	av_extend(av, in->itemsToModifySize);
	for (i = 0; i < in->itemsToModifySize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_MonitoredItemModifyRequest(sv, &in->itemsToModify[i]);
	}

	return;
}

static void
unpack_UA_ModifyMonitoredItemsRequest(UA_ModifyMonitoredItemsRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ModifyMonitoredItemsRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_timestampsToReturn", 0);
	if (svp != NULL)
		unpack_UA_TimestampsToReturn(&out->timestampsToReturn, *svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_itemsToModify", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ModifyMonitoredItemsRequest_itemsToModify");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->itemsToModify = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMMODIFYREQUEST]);
		if (out->itemsToModify == NULL)
			CROAKE("UA_Array_new");
		out->itemsToModifySize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_MonitoredItemModifyRequest(&out->itemsToModify[i], *svp);
		}
	}

	return;
}
#endif

/* ModifyMonitoredItemsResponse */
#ifdef UA_TYPES_MODIFYMONITOREDITEMSRESPONSE
static void pack_UA_ModifyMonitoredItemsResponse(SV *out, const UA_ModifyMonitoredItemsResponse *in);
static void unpack_UA_ModifyMonitoredItemsResponse(UA_ModifyMonitoredItemsResponse *out, SV *in);

static void
pack_UA_ModifyMonitoredItemsResponse(SV *out, const UA_ModifyMonitoredItemsResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ModifyMonitoredItemsResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "ModifyMonitoredItemsResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_MonitoredItemModifyResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "ModifyMonitoredItemsResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_ModifyMonitoredItemsResponse(UA_ModifyMonitoredItemsResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ModifyMonitoredItemsResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ModifyMonitoredItemsResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMMODIFYRESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_MonitoredItemModifyResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ModifyMonitoredItemsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ModifyMonitoredItemsResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* SetMonitoringModeRequest */
#ifdef UA_TYPES_SETMONITORINGMODEREQUEST
static void pack_UA_SetMonitoringModeRequest(SV *out, const UA_SetMonitoringModeRequest *in);
static void unpack_UA_SetMonitoringModeRequest(UA_SetMonitoringModeRequest *out, SV *in);

static void
pack_UA_SetMonitoringModeRequest(SV *out, const UA_SetMonitoringModeRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SetMonitoringModeRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "SetMonitoringModeRequest_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "SetMonitoringModeRequest_monitoringMode", sv);
	pack_UA_MonitoringMode(sv, &in->monitoringMode);

	av = newAV();
	hv_stores(hv, "SetMonitoringModeRequest_monitoredItemIds", newRV_noinc((SV*)av));
	av_extend(av, in->monitoredItemIdsSize);
	for (i = 0; i < in->monitoredItemIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->monitoredItemIds[i]);
	}

	return;
}

static void
unpack_UA_SetMonitoringModeRequest(UA_SetMonitoringModeRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SetMonitoringModeRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_monitoringMode", 0);
	if (svp != NULL)
		unpack_UA_MonitoringMode(&out->monitoringMode, *svp);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_monitoredItemIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetMonitoringModeRequest_monitoredItemIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->monitoredItemIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->monitoredItemIds == NULL)
			CROAKE("UA_Array_new");
		out->monitoredItemIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->monitoredItemIds[i], *svp);
		}
	}

	return;
}
#endif

/* SetMonitoringModeResponse */
#ifdef UA_TYPES_SETMONITORINGMODERESPONSE
static void pack_UA_SetMonitoringModeResponse(SV *out, const UA_SetMonitoringModeResponse *in);
static void unpack_UA_SetMonitoringModeResponse(UA_SetMonitoringModeResponse *out, SV *in);

static void
pack_UA_SetMonitoringModeResponse(SV *out, const UA_SetMonitoringModeResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SetMonitoringModeResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "SetMonitoringModeResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "SetMonitoringModeResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_SetMonitoringModeResponse(UA_SetMonitoringModeResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SetMonitoringModeResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetMonitoringModeResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "SetMonitoringModeResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetMonitoringModeResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SetMonitoringModeResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetMonitoringModeResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* SetTriggeringRequest */
#ifdef UA_TYPES_SETTRIGGERINGREQUEST
static void pack_UA_SetTriggeringRequest(SV *out, const UA_SetTriggeringRequest *in);
static void unpack_UA_SetTriggeringRequest(UA_SetTriggeringRequest *out, SV *in);

static void
pack_UA_SetTriggeringRequest(SV *out, const UA_SetTriggeringRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SetTriggeringRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "SetTriggeringRequest_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "SetTriggeringRequest_triggeringItemId", sv);
	pack_UA_UInt32(sv, &in->triggeringItemId);

	av = newAV();
	hv_stores(hv, "SetTriggeringRequest_linksToAdd", newRV_noinc((SV*)av));
	av_extend(av, in->linksToAddSize);
	for (i = 0; i < in->linksToAddSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->linksToAdd[i]);
	}

	av = newAV();
	hv_stores(hv, "SetTriggeringRequest_linksToRemove", newRV_noinc((SV*)av));
	av_extend(av, in->linksToRemoveSize);
	for (i = 0; i < in->linksToRemoveSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->linksToRemove[i]);
	}

	return;
}

static void
unpack_UA_SetTriggeringRequest(UA_SetTriggeringRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SetTriggeringRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetTriggeringRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "SetTriggeringRequest_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "SetTriggeringRequest_triggeringItemId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->triggeringItemId, *svp);

	svp = hv_fetchs(hv, "SetTriggeringRequest_linksToAdd", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetTriggeringRequest_linksToAdd");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->linksToAdd = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->linksToAdd == NULL)
			CROAKE("UA_Array_new");
		out->linksToAddSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->linksToAdd[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SetTriggeringRequest_linksToRemove", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetTriggeringRequest_linksToRemove");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->linksToRemove = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->linksToRemove == NULL)
			CROAKE("UA_Array_new");
		out->linksToRemoveSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->linksToRemove[i], *svp);
		}
	}

	return;
}
#endif

/* SetTriggeringResponse */
#ifdef UA_TYPES_SETTRIGGERINGRESPONSE
static void pack_UA_SetTriggeringResponse(SV *out, const UA_SetTriggeringResponse *in);
static void unpack_UA_SetTriggeringResponse(UA_SetTriggeringResponse *out, SV *in);

static void
pack_UA_SetTriggeringResponse(SV *out, const UA_SetTriggeringResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SetTriggeringResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "SetTriggeringResponse_addResults", newRV_noinc((SV*)av));
	av_extend(av, in->addResultsSize);
	for (i = 0; i < in->addResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->addResults[i]);
	}

	av = newAV();
	hv_stores(hv, "SetTriggeringResponse_addDiagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->addDiagnosticInfosSize);
	for (i = 0; i < in->addDiagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->addDiagnosticInfos[i]);
	}

	av = newAV();
	hv_stores(hv, "SetTriggeringResponse_removeResults", newRV_noinc((SV*)av));
	av_extend(av, in->removeResultsSize);
	for (i = 0; i < in->removeResultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->removeResults[i]);
	}

	av = newAV();
	hv_stores(hv, "SetTriggeringResponse_removeDiagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->removeDiagnosticInfosSize);
	for (i = 0; i < in->removeDiagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->removeDiagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_SetTriggeringResponse(UA_SetTriggeringResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SetTriggeringResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetTriggeringResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "SetTriggeringResponse_addResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetTriggeringResponse_addResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->addResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->addResults == NULL)
			CROAKE("UA_Array_new");
		out->addResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->addResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SetTriggeringResponse_addDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetTriggeringResponse_addDiagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->addDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->addDiagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->addDiagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->addDiagnosticInfos[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SetTriggeringResponse_removeResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetTriggeringResponse_removeResults");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->removeResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->removeResults == NULL)
			CROAKE("UA_Array_new");
		out->removeResultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->removeResults[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SetTriggeringResponse_removeDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetTriggeringResponse_removeDiagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->removeDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->removeDiagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->removeDiagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->removeDiagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteMonitoredItemsRequest */
#ifdef UA_TYPES_DELETEMONITOREDITEMSREQUEST
static void pack_UA_DeleteMonitoredItemsRequest(SV *out, const UA_DeleteMonitoredItemsRequest *in);
static void unpack_UA_DeleteMonitoredItemsRequest(UA_DeleteMonitoredItemsRequest *out, SV *in);

static void
pack_UA_DeleteMonitoredItemsRequest(SV *out, const UA_DeleteMonitoredItemsRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteMonitoredItemsRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "DeleteMonitoredItemsRequest_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	av = newAV();
	hv_stores(hv, "DeleteMonitoredItemsRequest_monitoredItemIds", newRV_noinc((SV*)av));
	av_extend(av, in->monitoredItemIdsSize);
	for (i = 0; i < in->monitoredItemIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->monitoredItemIds[i]);
	}

	return;
}

static void
unpack_UA_DeleteMonitoredItemsRequest(UA_DeleteMonitoredItemsRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteMonitoredItemsRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsRequest_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsRequest_monitoredItemIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteMonitoredItemsRequest_monitoredItemIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->monitoredItemIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->monitoredItemIds == NULL)
			CROAKE("UA_Array_new");
		out->monitoredItemIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->monitoredItemIds[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteMonitoredItemsResponse */
#ifdef UA_TYPES_DELETEMONITOREDITEMSRESPONSE
static void pack_UA_DeleteMonitoredItemsResponse(SV *out, const UA_DeleteMonitoredItemsResponse *in);
static void unpack_UA_DeleteMonitoredItemsResponse(UA_DeleteMonitoredItemsResponse *out, SV *in);

static void
pack_UA_DeleteMonitoredItemsResponse(SV *out, const UA_DeleteMonitoredItemsResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteMonitoredItemsResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "DeleteMonitoredItemsResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "DeleteMonitoredItemsResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_DeleteMonitoredItemsResponse(UA_DeleteMonitoredItemsResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteMonitoredItemsResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteMonitoredItemsResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DeleteMonitoredItemsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteMonitoredItemsResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* CreateSubscriptionRequest */
#ifdef UA_TYPES_CREATESUBSCRIPTIONREQUEST
static void pack_UA_CreateSubscriptionRequest(SV *out, const UA_CreateSubscriptionRequest *in);
static void unpack_UA_CreateSubscriptionRequest(UA_CreateSubscriptionRequest *out, SV *in);

static void
pack_UA_CreateSubscriptionRequest(SV *out, const UA_CreateSubscriptionRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionRequest_requestedPublishingInterval", sv);
	pack_UA_Double(sv, &in->requestedPublishingInterval);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionRequest_requestedLifetimeCount", sv);
	pack_UA_UInt32(sv, &in->requestedLifetimeCount);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionRequest_requestedMaxKeepAliveCount", sv);
	pack_UA_UInt32(sv, &in->requestedMaxKeepAliveCount);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionRequest_maxNotificationsPerPublish", sv);
	pack_UA_UInt32(sv, &in->maxNotificationsPerPublish);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionRequest_publishingEnabled", sv);
	pack_UA_Boolean(sv, &in->publishingEnabled);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionRequest_priority", sv);
	pack_UA_Byte(sv, &in->priority);

	return;
}

static void
unpack_UA_CreateSubscriptionRequest(UA_CreateSubscriptionRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CreateSubscriptionRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestedPublishingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->requestedPublishingInterval, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestedLifetimeCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestedLifetimeCount, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestedMaxKeepAliveCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestedMaxKeepAliveCount, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_maxNotificationsPerPublish", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxNotificationsPerPublish, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_publishingEnabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->publishingEnabled, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_priority", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->priority, *svp);

	return;
}
#endif

/* CreateSubscriptionResponse */
#ifdef UA_TYPES_CREATESUBSCRIPTIONRESPONSE
static void pack_UA_CreateSubscriptionResponse(SV *out, const UA_CreateSubscriptionResponse *in);
static void unpack_UA_CreateSubscriptionResponse(UA_CreateSubscriptionResponse *out, SV *in);

static void
pack_UA_CreateSubscriptionResponse(SV *out, const UA_CreateSubscriptionResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionResponse_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionResponse_revisedPublishingInterval", sv);
	pack_UA_Double(sv, &in->revisedPublishingInterval);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionResponse_revisedLifetimeCount", sv);
	pack_UA_UInt32(sv, &in->revisedLifetimeCount);

	sv = newSV(0);
	hv_stores(hv, "CreateSubscriptionResponse_revisedMaxKeepAliveCount", sv);
	pack_UA_UInt32(sv, &in->revisedMaxKeepAliveCount);

	return;
}

static void
unpack_UA_CreateSubscriptionResponse(UA_CreateSubscriptionResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_CreateSubscriptionResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_revisedPublishingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->revisedPublishingInterval, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_revisedLifetimeCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->revisedLifetimeCount, *svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_revisedMaxKeepAliveCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->revisedMaxKeepAliveCount, *svp);

	return;
}
#endif

/* ModifySubscriptionRequest */
#ifdef UA_TYPES_MODIFYSUBSCRIPTIONREQUEST
static void pack_UA_ModifySubscriptionRequest(SV *out, const UA_ModifySubscriptionRequest *in);
static void unpack_UA_ModifySubscriptionRequest(UA_ModifySubscriptionRequest *out, SV *in);

static void
pack_UA_ModifySubscriptionRequest(SV *out, const UA_ModifySubscriptionRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionRequest_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionRequest_requestedPublishingInterval", sv);
	pack_UA_Double(sv, &in->requestedPublishingInterval);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionRequest_requestedLifetimeCount", sv);
	pack_UA_UInt32(sv, &in->requestedLifetimeCount);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionRequest_requestedMaxKeepAliveCount", sv);
	pack_UA_UInt32(sv, &in->requestedMaxKeepAliveCount);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionRequest_maxNotificationsPerPublish", sv);
	pack_UA_UInt32(sv, &in->maxNotificationsPerPublish);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionRequest_priority", sv);
	pack_UA_Byte(sv, &in->priority);

	return;
}

static void
unpack_UA_ModifySubscriptionRequest(UA_ModifySubscriptionRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ModifySubscriptionRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestedPublishingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->requestedPublishingInterval, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestedLifetimeCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestedLifetimeCount, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestedMaxKeepAliveCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->requestedMaxKeepAliveCount, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_maxNotificationsPerPublish", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxNotificationsPerPublish, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_priority", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->priority, *svp);

	return;
}
#endif

/* ModifySubscriptionResponse */
#ifdef UA_TYPES_MODIFYSUBSCRIPTIONRESPONSE
static void pack_UA_ModifySubscriptionResponse(SV *out, const UA_ModifySubscriptionResponse *in);
static void unpack_UA_ModifySubscriptionResponse(UA_ModifySubscriptionResponse *out, SV *in);

static void
pack_UA_ModifySubscriptionResponse(SV *out, const UA_ModifySubscriptionResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionResponse_revisedPublishingInterval", sv);
	pack_UA_Double(sv, &in->revisedPublishingInterval);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionResponse_revisedLifetimeCount", sv);
	pack_UA_UInt32(sv, &in->revisedLifetimeCount);

	sv = newSV(0);
	hv_stores(hv, "ModifySubscriptionResponse_revisedMaxKeepAliveCount", sv);
	pack_UA_UInt32(sv, &in->revisedMaxKeepAliveCount);

	return;
}

static void
unpack_UA_ModifySubscriptionResponse(UA_ModifySubscriptionResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ModifySubscriptionResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_revisedPublishingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->revisedPublishingInterval, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_revisedLifetimeCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->revisedLifetimeCount, *svp);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_revisedMaxKeepAliveCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->revisedMaxKeepAliveCount, *svp);

	return;
}
#endif

/* SetPublishingModeRequest */
#ifdef UA_TYPES_SETPUBLISHINGMODEREQUEST
static void pack_UA_SetPublishingModeRequest(SV *out, const UA_SetPublishingModeRequest *in);
static void unpack_UA_SetPublishingModeRequest(UA_SetPublishingModeRequest *out, SV *in);

static void
pack_UA_SetPublishingModeRequest(SV *out, const UA_SetPublishingModeRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SetPublishingModeRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "SetPublishingModeRequest_publishingEnabled", sv);
	pack_UA_Boolean(sv, &in->publishingEnabled);

	av = newAV();
	hv_stores(hv, "SetPublishingModeRequest_subscriptionIds", newRV_noinc((SV*)av));
	av_extend(av, in->subscriptionIdsSize);
	for (i = 0; i < in->subscriptionIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->subscriptionIds[i]);
	}

	return;
}

static void
unpack_UA_SetPublishingModeRequest(UA_SetPublishingModeRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SetPublishingModeRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetPublishingModeRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "SetPublishingModeRequest_publishingEnabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->publishingEnabled, *svp);

	svp = hv_fetchs(hv, "SetPublishingModeRequest_subscriptionIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetPublishingModeRequest_subscriptionIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->subscriptionIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->subscriptionIds == NULL)
			CROAKE("UA_Array_new");
		out->subscriptionIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->subscriptionIds[i], *svp);
		}
	}

	return;
}
#endif

/* SetPublishingModeResponse */
#ifdef UA_TYPES_SETPUBLISHINGMODERESPONSE
static void pack_UA_SetPublishingModeResponse(SV *out, const UA_SetPublishingModeResponse *in);
static void unpack_UA_SetPublishingModeResponse(UA_SetPublishingModeResponse *out, SV *in);

static void
pack_UA_SetPublishingModeResponse(SV *out, const UA_SetPublishingModeResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SetPublishingModeResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "SetPublishingModeResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "SetPublishingModeResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_SetPublishingModeResponse(UA_SetPublishingModeResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SetPublishingModeResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetPublishingModeResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "SetPublishingModeResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetPublishingModeResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SetPublishingModeResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SetPublishingModeResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* NotificationMessage */
#ifdef UA_TYPES_NOTIFICATIONMESSAGE
static void pack_UA_NotificationMessage(SV *out, const UA_NotificationMessage *in);
static void unpack_UA_NotificationMessage(UA_NotificationMessage *out, SV *in);

static void
pack_UA_NotificationMessage(SV *out, const UA_NotificationMessage *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NotificationMessage_sequenceNumber", sv);
	pack_UA_UInt32(sv, &in->sequenceNumber);

	sv = newSV(0);
	hv_stores(hv, "NotificationMessage_publishTime", sv);
	pack_UA_DateTime(sv, &in->publishTime);

	av = newAV();
	hv_stores(hv, "NotificationMessage_notificationData", newRV_noinc((SV*)av));
	av_extend(av, in->notificationDataSize);
	for (i = 0; i < in->notificationDataSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ExtensionObject(sv, &in->notificationData[i]);
	}

	return;
}

static void
unpack_UA_NotificationMessage(UA_NotificationMessage *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NotificationMessage_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NotificationMessage_sequenceNumber", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->sequenceNumber, *svp);

	svp = hv_fetchs(hv, "NotificationMessage_publishTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->publishTime, *svp);

	svp = hv_fetchs(hv, "NotificationMessage_notificationData", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for NotificationMessage_notificationData");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->notificationData = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXTENSIONOBJECT]);
		if (out->notificationData == NULL)
			CROAKE("UA_Array_new");
		out->notificationDataSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ExtensionObject(&out->notificationData[i], *svp);
		}
	}

	return;
}
#endif

/* MonitoredItemNotification */
#ifdef UA_TYPES_MONITOREDITEMNOTIFICATION
static void pack_UA_MonitoredItemNotification(SV *out, const UA_MonitoredItemNotification *in);
static void unpack_UA_MonitoredItemNotification(UA_MonitoredItemNotification *out, SV *in);

static void
pack_UA_MonitoredItemNotification(SV *out, const UA_MonitoredItemNotification *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemNotification_clientHandle", sv);
	pack_UA_UInt32(sv, &in->clientHandle);

	sv = newSV(0);
	hv_stores(hv, "MonitoredItemNotification_value", sv);
	pack_UA_DataValue(sv, &in->value);

	return;
}

static void
unpack_UA_MonitoredItemNotification(UA_MonitoredItemNotification *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_MonitoredItemNotification_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemNotification_clientHandle", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->clientHandle, *svp);

	svp = hv_fetchs(hv, "MonitoredItemNotification_value", 0);
	if (svp != NULL)
		unpack_UA_DataValue(&out->value, *svp);

	return;
}
#endif

/* EventFieldList */
#ifdef UA_TYPES_EVENTFIELDLIST
static void pack_UA_EventFieldList(SV *out, const UA_EventFieldList *in);
static void unpack_UA_EventFieldList(UA_EventFieldList *out, SV *in);

static void
pack_UA_EventFieldList(SV *out, const UA_EventFieldList *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EventFieldList_clientHandle", sv);
	pack_UA_UInt32(sv, &in->clientHandle);

	av = newAV();
	hv_stores(hv, "EventFieldList_eventFields", newRV_noinc((SV*)av));
	av_extend(av, in->eventFieldsSize);
	for (i = 0; i < in->eventFieldsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Variant(sv, &in->eventFields[i]);
	}

	return;
}

static void
unpack_UA_EventFieldList(UA_EventFieldList *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EventFieldList_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventFieldList_clientHandle", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->clientHandle, *svp);

	svp = hv_fetchs(hv, "EventFieldList_eventFields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EventFieldList_eventFields");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->eventFields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out->eventFields == NULL)
			CROAKE("UA_Array_new");
		out->eventFieldsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Variant(&out->eventFields[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryEventFieldList */
#ifdef UA_TYPES_HISTORYEVENTFIELDLIST
static void pack_UA_HistoryEventFieldList(SV *out, const UA_HistoryEventFieldList *in);
static void unpack_UA_HistoryEventFieldList(UA_HistoryEventFieldList *out, SV *in);

static void
pack_UA_HistoryEventFieldList(SV *out, const UA_HistoryEventFieldList *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "HistoryEventFieldList_eventFields", newRV_noinc((SV*)av));
	av_extend(av, in->eventFieldsSize);
	for (i = 0; i < in->eventFieldsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Variant(sv, &in->eventFields[i]);
	}

	return;
}

static void
unpack_UA_HistoryEventFieldList(UA_HistoryEventFieldList *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryEventFieldList_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryEventFieldList_eventFields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryEventFieldList_eventFields");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->eventFields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out->eventFields == NULL)
			CROAKE("UA_Array_new");
		out->eventFieldsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Variant(&out->eventFields[i], *svp);
		}
	}

	return;
}
#endif

/* StatusChangeNotification */
#ifdef UA_TYPES_STATUSCHANGENOTIFICATION
static void pack_UA_StatusChangeNotification(SV *out, const UA_StatusChangeNotification *in);
static void unpack_UA_StatusChangeNotification(UA_StatusChangeNotification *out, SV *in);

static void
pack_UA_StatusChangeNotification(SV *out, const UA_StatusChangeNotification *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "StatusChangeNotification_status", sv);
	pack_UA_StatusCode(sv, &in->status);

	sv = newSV(0);
	hv_stores(hv, "StatusChangeNotification_diagnosticInfo", sv);
	pack_UA_DiagnosticInfo(sv, &in->diagnosticInfo);

	return;
}

static void
unpack_UA_StatusChangeNotification(UA_StatusChangeNotification *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_StatusChangeNotification_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "StatusChangeNotification_status", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->status, *svp);

	svp = hv_fetchs(hv, "StatusChangeNotification_diagnosticInfo", 0);
	if (svp != NULL)
		unpack_UA_DiagnosticInfo(&out->diagnosticInfo, *svp);

	return;
}
#endif

/* SubscriptionAcknowledgement */
#ifdef UA_TYPES_SUBSCRIPTIONACKNOWLEDGEMENT
static void pack_UA_SubscriptionAcknowledgement(SV *out, const UA_SubscriptionAcknowledgement *in);
static void unpack_UA_SubscriptionAcknowledgement(UA_SubscriptionAcknowledgement *out, SV *in);

static void
pack_UA_SubscriptionAcknowledgement(SV *out, const UA_SubscriptionAcknowledgement *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SubscriptionAcknowledgement_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionAcknowledgement_sequenceNumber", sv);
	pack_UA_UInt32(sv, &in->sequenceNumber);

	return;
}

static void
unpack_UA_SubscriptionAcknowledgement(UA_SubscriptionAcknowledgement *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SubscriptionAcknowledgement_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SubscriptionAcknowledgement_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "SubscriptionAcknowledgement_sequenceNumber", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->sequenceNumber, *svp);

	return;
}
#endif

/* PublishRequest */
#ifdef UA_TYPES_PUBLISHREQUEST
static void pack_UA_PublishRequest(SV *out, const UA_PublishRequest *in);
static void unpack_UA_PublishRequest(UA_PublishRequest *out, SV *in);

static void
pack_UA_PublishRequest(SV *out, const UA_PublishRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "PublishRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "PublishRequest_subscriptionAcknowledgements", newRV_noinc((SV*)av));
	av_extend(av, in->subscriptionAcknowledgementsSize);
	for (i = 0; i < in->subscriptionAcknowledgementsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SubscriptionAcknowledgement(sv, &in->subscriptionAcknowledgements[i]);
	}

	return;
}

static void
unpack_UA_PublishRequest(UA_PublishRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PublishRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "PublishRequest_subscriptionAcknowledgements", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishRequest_subscriptionAcknowledgements");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->subscriptionAcknowledgements = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SUBSCRIPTIONACKNOWLEDGEMENT]);
		if (out->subscriptionAcknowledgements == NULL)
			CROAKE("UA_Array_new");
		out->subscriptionAcknowledgementsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SubscriptionAcknowledgement(&out->subscriptionAcknowledgements[i], *svp);
		}
	}

	return;
}
#endif

/* PublishResponse */
#ifdef UA_TYPES_PUBLISHRESPONSE
static void pack_UA_PublishResponse(SV *out, const UA_PublishResponse *in);
static void unpack_UA_PublishResponse(UA_PublishResponse *out, SV *in);

static void
pack_UA_PublishResponse(SV *out, const UA_PublishResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "PublishResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "PublishResponse_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	av = newAV();
	hv_stores(hv, "PublishResponse_availableSequenceNumbers", newRV_noinc((SV*)av));
	av_extend(av, in->availableSequenceNumbersSize);
	for (i = 0; i < in->availableSequenceNumbersSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->availableSequenceNumbers[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "PublishResponse_moreNotifications", sv);
	pack_UA_Boolean(sv, &in->moreNotifications);

	sv = newSV(0);
	hv_stores(hv, "PublishResponse_notificationMessage", sv);
	pack_UA_NotificationMessage(sv, &in->notificationMessage);

	av = newAV();
	hv_stores(hv, "PublishResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "PublishResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_PublishResponse(UA_PublishResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PublishResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "PublishResponse_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "PublishResponse_availableSequenceNumbers", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishResponse_availableSequenceNumbers");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->availableSequenceNumbers = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->availableSequenceNumbers == NULL)
			CROAKE("UA_Array_new");
		out->availableSequenceNumbersSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->availableSequenceNumbers[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PublishResponse_moreNotifications", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->moreNotifications, *svp);

	svp = hv_fetchs(hv, "PublishResponse_notificationMessage", 0);
	if (svp != NULL)
		unpack_UA_NotificationMessage(&out->notificationMessage, *svp);

	svp = hv_fetchs(hv, "PublishResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PublishResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* RepublishRequest */
#ifdef UA_TYPES_REPUBLISHREQUEST
static void pack_UA_RepublishRequest(SV *out, const UA_RepublishRequest *in);
static void unpack_UA_RepublishRequest(UA_RepublishRequest *out, SV *in);

static void
pack_UA_RepublishRequest(SV *out, const UA_RepublishRequest *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RepublishRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	sv = newSV(0);
	hv_stores(hv, "RepublishRequest_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "RepublishRequest_retransmitSequenceNumber", sv);
	pack_UA_UInt32(sv, &in->retransmitSequenceNumber);

	return;
}

static void
unpack_UA_RepublishRequest(UA_RepublishRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RepublishRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RepublishRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "RepublishRequest_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "RepublishRequest_retransmitSequenceNumber", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->retransmitSequenceNumber, *svp);

	return;
}
#endif

/* RepublishResponse */
#ifdef UA_TYPES_REPUBLISHRESPONSE
static void pack_UA_RepublishResponse(SV *out, const UA_RepublishResponse *in);
static void unpack_UA_RepublishResponse(UA_RepublishResponse *out, SV *in);

static void
pack_UA_RepublishResponse(SV *out, const UA_RepublishResponse *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RepublishResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	sv = newSV(0);
	hv_stores(hv, "RepublishResponse_notificationMessage", sv);
	pack_UA_NotificationMessage(sv, &in->notificationMessage);

	return;
}

static void
unpack_UA_RepublishResponse(UA_RepublishResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RepublishResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RepublishResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "RepublishResponse_notificationMessage", 0);
	if (svp != NULL)
		unpack_UA_NotificationMessage(&out->notificationMessage, *svp);

	return;
}
#endif

/* TransferResult */
#ifdef UA_TYPES_TRANSFERRESULT
static void pack_UA_TransferResult(SV *out, const UA_TransferResult *in);
static void unpack_UA_TransferResult(UA_TransferResult *out, SV *in);

static void
pack_UA_TransferResult(SV *out, const UA_TransferResult *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "TransferResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	av = newAV();
	hv_stores(hv, "TransferResult_availableSequenceNumbers", newRV_noinc((SV*)av));
	av_extend(av, in->availableSequenceNumbersSize);
	for (i = 0; i < in->availableSequenceNumbersSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->availableSequenceNumbers[i]);
	}

	return;
}

static void
unpack_UA_TransferResult(UA_TransferResult *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TransferResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TransferResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "TransferResult_availableSequenceNumbers", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TransferResult_availableSequenceNumbers");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->availableSequenceNumbers = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->availableSequenceNumbers == NULL)
			CROAKE("UA_Array_new");
		out->availableSequenceNumbersSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->availableSequenceNumbers[i], *svp);
		}
	}

	return;
}
#endif

/* TransferSubscriptionsRequest */
#ifdef UA_TYPES_TRANSFERSUBSCRIPTIONSREQUEST
static void pack_UA_TransferSubscriptionsRequest(SV *out, const UA_TransferSubscriptionsRequest *in);
static void unpack_UA_TransferSubscriptionsRequest(UA_TransferSubscriptionsRequest *out, SV *in);

static void
pack_UA_TransferSubscriptionsRequest(SV *out, const UA_TransferSubscriptionsRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "TransferSubscriptionsRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "TransferSubscriptionsRequest_subscriptionIds", newRV_noinc((SV*)av));
	av_extend(av, in->subscriptionIdsSize);
	for (i = 0; i < in->subscriptionIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->subscriptionIds[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "TransferSubscriptionsRequest_sendInitialValues", sv);
	pack_UA_Boolean(sv, &in->sendInitialValues);

	return;
}

static void
unpack_UA_TransferSubscriptionsRequest(UA_TransferSubscriptionsRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TransferSubscriptionsRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TransferSubscriptionsRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "TransferSubscriptionsRequest_subscriptionIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TransferSubscriptionsRequest_subscriptionIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->subscriptionIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->subscriptionIds == NULL)
			CROAKE("UA_Array_new");
		out->subscriptionIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->subscriptionIds[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "TransferSubscriptionsRequest_sendInitialValues", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->sendInitialValues, *svp);

	return;
}
#endif

/* TransferSubscriptionsResponse */
#ifdef UA_TYPES_TRANSFERSUBSCRIPTIONSRESPONSE
static void pack_UA_TransferSubscriptionsResponse(SV *out, const UA_TransferSubscriptionsResponse *in);
static void unpack_UA_TransferSubscriptionsResponse(UA_TransferSubscriptionsResponse *out, SV *in);

static void
pack_UA_TransferSubscriptionsResponse(SV *out, const UA_TransferSubscriptionsResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "TransferSubscriptionsResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "TransferSubscriptionsResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_TransferResult(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "TransferSubscriptionsResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_TransferSubscriptionsResponse(UA_TransferSubscriptionsResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TransferSubscriptionsResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TransferSubscriptionsResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "TransferSubscriptionsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TransferSubscriptionsResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_TRANSFERRESULT]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_TransferResult(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "TransferSubscriptionsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TransferSubscriptionsResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteSubscriptionsRequest */
#ifdef UA_TYPES_DELETESUBSCRIPTIONSREQUEST
static void pack_UA_DeleteSubscriptionsRequest(SV *out, const UA_DeleteSubscriptionsRequest *in);
static void unpack_UA_DeleteSubscriptionsRequest(UA_DeleteSubscriptionsRequest *out, SV *in);

static void
pack_UA_DeleteSubscriptionsRequest(SV *out, const UA_DeleteSubscriptionsRequest *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteSubscriptionsRequest_requestHeader", sv);
	pack_UA_RequestHeader(sv, &in->requestHeader);

	av = newAV();
	hv_stores(hv, "DeleteSubscriptionsRequest_subscriptionIds", newRV_noinc((SV*)av));
	av_extend(av, in->subscriptionIdsSize);
	for (i = 0; i < in->subscriptionIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->subscriptionIds[i]);
	}

	return;
}

static void
unpack_UA_DeleteSubscriptionsRequest(UA_DeleteSubscriptionsRequest *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteSubscriptionsRequest_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteSubscriptionsRequest_requestHeader", 0);
	if (svp != NULL)
		unpack_UA_RequestHeader(&out->requestHeader, *svp);

	svp = hv_fetchs(hv, "DeleteSubscriptionsRequest_subscriptionIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteSubscriptionsRequest_subscriptionIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->subscriptionIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->subscriptionIds == NULL)
			CROAKE("UA_Array_new");
		out->subscriptionIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->subscriptionIds[i], *svp);
		}
	}

	return;
}
#endif

/* DeleteSubscriptionsResponse */
#ifdef UA_TYPES_DELETESUBSCRIPTIONSRESPONSE
static void pack_UA_DeleteSubscriptionsResponse(SV *out, const UA_DeleteSubscriptionsResponse *in);
static void unpack_UA_DeleteSubscriptionsResponse(UA_DeleteSubscriptionsResponse *out, SV *in);

static void
pack_UA_DeleteSubscriptionsResponse(SV *out, const UA_DeleteSubscriptionsResponse *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DeleteSubscriptionsResponse_responseHeader", sv);
	pack_UA_ResponseHeader(sv, &in->responseHeader);

	av = newAV();
	hv_stores(hv, "DeleteSubscriptionsResponse_results", newRV_noinc((SV*)av));
	av_extend(av, in->resultsSize);
	for (i = 0; i < in->resultsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StatusCode(sv, &in->results[i]);
	}

	av = newAV();
	hv_stores(hv, "DeleteSubscriptionsResponse_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_DeleteSubscriptionsResponse(UA_DeleteSubscriptionsResponse *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DeleteSubscriptionsResponse_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteSubscriptionsResponse_responseHeader", 0);
	if (svp != NULL)
		unpack_UA_ResponseHeader(&out->responseHeader, *svp);

	svp = hv_fetchs(hv, "DeleteSubscriptionsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteSubscriptionsResponse_results");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out->results == NULL)
			CROAKE("UA_Array_new");
		out->resultsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StatusCode(&out->results[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DeleteSubscriptionsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DeleteSubscriptionsResponse_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* BuildInfo */
#ifdef UA_TYPES_BUILDINFO
static void pack_UA_BuildInfo(SV *out, const UA_BuildInfo *in);
static void unpack_UA_BuildInfo(UA_BuildInfo *out, SV *in);

static void
pack_UA_BuildInfo(SV *out, const UA_BuildInfo *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "BuildInfo_productUri", sv);
	pack_UA_String(sv, &in->productUri);

	sv = newSV(0);
	hv_stores(hv, "BuildInfo_manufacturerName", sv);
	pack_UA_String(sv, &in->manufacturerName);

	sv = newSV(0);
	hv_stores(hv, "BuildInfo_productName", sv);
	pack_UA_String(sv, &in->productName);

	sv = newSV(0);
	hv_stores(hv, "BuildInfo_softwareVersion", sv);
	pack_UA_String(sv, &in->softwareVersion);

	sv = newSV(0);
	hv_stores(hv, "BuildInfo_buildNumber", sv);
	pack_UA_String(sv, &in->buildNumber);

	sv = newSV(0);
	hv_stores(hv, "BuildInfo_buildDate", sv);
	pack_UA_DateTime(sv, &in->buildDate);

	return;
}

static void
unpack_UA_BuildInfo(UA_BuildInfo *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_BuildInfo_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BuildInfo_productUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->productUri, *svp);

	svp = hv_fetchs(hv, "BuildInfo_manufacturerName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->manufacturerName, *svp);

	svp = hv_fetchs(hv, "BuildInfo_productName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->productName, *svp);

	svp = hv_fetchs(hv, "BuildInfo_softwareVersion", 0);
	if (svp != NULL)
		unpack_UA_String(&out->softwareVersion, *svp);

	svp = hv_fetchs(hv, "BuildInfo_buildNumber", 0);
	if (svp != NULL)
		unpack_UA_String(&out->buildNumber, *svp);

	svp = hv_fetchs(hv, "BuildInfo_buildDate", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->buildDate, *svp);

	return;
}
#endif

/* RedundancySupport */
#ifdef UA_TYPES_REDUNDANCYSUPPORT
static void pack_UA_RedundancySupport(SV *out, const UA_RedundancySupport *in);
static void unpack_UA_RedundancySupport(UA_RedundancySupport *out, SV *in);

static void
pack_UA_RedundancySupport(SV *out, const UA_RedundancySupport *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_RedundancySupport(UA_RedundancySupport *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ServerState */
#ifdef UA_TYPES_SERVERSTATE
static void pack_UA_ServerState(SV *out, const UA_ServerState *in);
static void unpack_UA_ServerState(UA_ServerState *out, SV *in);

static void
pack_UA_ServerState(SV *out, const UA_ServerState *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_ServerState(UA_ServerState *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* RedundantServerDataType */
#ifdef UA_TYPES_REDUNDANTSERVERDATATYPE
static void pack_UA_RedundantServerDataType(SV *out, const UA_RedundantServerDataType *in);
static void unpack_UA_RedundantServerDataType(UA_RedundantServerDataType *out, SV *in);

static void
pack_UA_RedundantServerDataType(SV *out, const UA_RedundantServerDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "RedundantServerDataType_serverId", sv);
	pack_UA_String(sv, &in->serverId);

	sv = newSV(0);
	hv_stores(hv, "RedundantServerDataType_serviceLevel", sv);
	pack_UA_Byte(sv, &in->serviceLevel);

	sv = newSV(0);
	hv_stores(hv, "RedundantServerDataType_serverState", sv);
	pack_UA_ServerState(sv, &in->serverState);

	return;
}

static void
unpack_UA_RedundantServerDataType(UA_RedundantServerDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_RedundantServerDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RedundantServerDataType_serverId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->serverId, *svp);

	svp = hv_fetchs(hv, "RedundantServerDataType_serviceLevel", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->serviceLevel, *svp);

	svp = hv_fetchs(hv, "RedundantServerDataType_serverState", 0);
	if (svp != NULL)
		unpack_UA_ServerState(&out->serverState, *svp);

	return;
}
#endif

/* EndpointUrlListDataType */
#ifdef UA_TYPES_ENDPOINTURLLISTDATATYPE
static void pack_UA_EndpointUrlListDataType(SV *out, const UA_EndpointUrlListDataType *in);
static void unpack_UA_EndpointUrlListDataType(UA_EndpointUrlListDataType *out, SV *in);

static void
pack_UA_EndpointUrlListDataType(SV *out, const UA_EndpointUrlListDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "EndpointUrlListDataType_endpointUrlList", newRV_noinc((SV*)av));
	av_extend(av, in->endpointUrlListSize);
	for (i = 0; i < in->endpointUrlListSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->endpointUrlList[i]);
	}

	return;
}

static void
unpack_UA_EndpointUrlListDataType(UA_EndpointUrlListDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EndpointUrlListDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EndpointUrlListDataType_endpointUrlList", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EndpointUrlListDataType_endpointUrlList");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->endpointUrlList = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->endpointUrlList == NULL)
			CROAKE("UA_Array_new");
		out->endpointUrlListSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->endpointUrlList[i], *svp);
		}
	}

	return;
}
#endif

/* NetworkGroupDataType */
#ifdef UA_TYPES_NETWORKGROUPDATATYPE
static void pack_UA_NetworkGroupDataType(SV *out, const UA_NetworkGroupDataType *in);
static void unpack_UA_NetworkGroupDataType(UA_NetworkGroupDataType *out, SV *in);

static void
pack_UA_NetworkGroupDataType(SV *out, const UA_NetworkGroupDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NetworkGroupDataType_serverUri", sv);
	pack_UA_String(sv, &in->serverUri);

	av = newAV();
	hv_stores(hv, "NetworkGroupDataType_networkPaths", newRV_noinc((SV*)av));
	av_extend(av, in->networkPathsSize);
	for (i = 0; i < in->networkPathsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EndpointUrlListDataType(sv, &in->networkPaths[i]);
	}

	return;
}

static void
unpack_UA_NetworkGroupDataType(UA_NetworkGroupDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NetworkGroupDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NetworkGroupDataType_serverUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->serverUri, *svp);

	svp = hv_fetchs(hv, "NetworkGroupDataType_networkPaths", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for NetworkGroupDataType_networkPaths");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->networkPaths = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTURLLISTDATATYPE]);
		if (out->networkPaths == NULL)
			CROAKE("UA_Array_new");
		out->networkPathsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EndpointUrlListDataType(&out->networkPaths[i], *svp);
		}
	}

	return;
}
#endif

/* SamplingIntervalDiagnosticsDataType */
#ifdef UA_TYPES_SAMPLINGINTERVALDIAGNOSTICSDATATYPE
static void pack_UA_SamplingIntervalDiagnosticsDataType(SV *out, const UA_SamplingIntervalDiagnosticsDataType *in);
static void unpack_UA_SamplingIntervalDiagnosticsDataType(UA_SamplingIntervalDiagnosticsDataType *out, SV *in);

static void
pack_UA_SamplingIntervalDiagnosticsDataType(SV *out, const UA_SamplingIntervalDiagnosticsDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SamplingIntervalDiagnosticsDataType_samplingInterval", sv);
	pack_UA_Double(sv, &in->samplingInterval);

	sv = newSV(0);
	hv_stores(hv, "SamplingIntervalDiagnosticsDataType_monitoredItemCount", sv);
	pack_UA_UInt32(sv, &in->monitoredItemCount);

	sv = newSV(0);
	hv_stores(hv, "SamplingIntervalDiagnosticsDataType_maxMonitoredItemCount", sv);
	pack_UA_UInt32(sv, &in->maxMonitoredItemCount);

	sv = newSV(0);
	hv_stores(hv, "SamplingIntervalDiagnosticsDataType_disabledMonitoredItemCount", sv);
	pack_UA_UInt32(sv, &in->disabledMonitoredItemCount);

	return;
}

static void
unpack_UA_SamplingIntervalDiagnosticsDataType(UA_SamplingIntervalDiagnosticsDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SamplingIntervalDiagnosticsDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SamplingIntervalDiagnosticsDataType_samplingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->samplingInterval, *svp);

	svp = hv_fetchs(hv, "SamplingIntervalDiagnosticsDataType_monitoredItemCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->monitoredItemCount, *svp);

	svp = hv_fetchs(hv, "SamplingIntervalDiagnosticsDataType_maxMonitoredItemCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxMonitoredItemCount, *svp);

	svp = hv_fetchs(hv, "SamplingIntervalDiagnosticsDataType_disabledMonitoredItemCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->disabledMonitoredItemCount, *svp);

	return;
}
#endif

/* ServerDiagnosticsSummaryDataType */
#ifdef UA_TYPES_SERVERDIAGNOSTICSSUMMARYDATATYPE
static void pack_UA_ServerDiagnosticsSummaryDataType(SV *out, const UA_ServerDiagnosticsSummaryDataType *in);
static void unpack_UA_ServerDiagnosticsSummaryDataType(UA_ServerDiagnosticsSummaryDataType *out, SV *in);

static void
pack_UA_ServerDiagnosticsSummaryDataType(SV *out, const UA_ServerDiagnosticsSummaryDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_serverViewCount", sv);
	pack_UA_UInt32(sv, &in->serverViewCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_currentSessionCount", sv);
	pack_UA_UInt32(sv, &in->currentSessionCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_cumulatedSessionCount", sv);
	pack_UA_UInt32(sv, &in->cumulatedSessionCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_securityRejectedSessionCount", sv);
	pack_UA_UInt32(sv, &in->securityRejectedSessionCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_rejectedSessionCount", sv);
	pack_UA_UInt32(sv, &in->rejectedSessionCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_sessionTimeoutCount", sv);
	pack_UA_UInt32(sv, &in->sessionTimeoutCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_sessionAbortCount", sv);
	pack_UA_UInt32(sv, &in->sessionAbortCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_currentSubscriptionCount", sv);
	pack_UA_UInt32(sv, &in->currentSubscriptionCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_cumulatedSubscriptionCount", sv);
	pack_UA_UInt32(sv, &in->cumulatedSubscriptionCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_publishingIntervalCount", sv);
	pack_UA_UInt32(sv, &in->publishingIntervalCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_securityRejectedRequestsCount", sv);
	pack_UA_UInt32(sv, &in->securityRejectedRequestsCount);

	sv = newSV(0);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_rejectedRequestsCount", sv);
	pack_UA_UInt32(sv, &in->rejectedRequestsCount);

	return;
}

static void
unpack_UA_ServerDiagnosticsSummaryDataType(UA_ServerDiagnosticsSummaryDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ServerDiagnosticsSummaryDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_serverViewCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->serverViewCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_currentSessionCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->currentSessionCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_cumulatedSessionCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->cumulatedSessionCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_securityRejectedSessionCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->securityRejectedSessionCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_rejectedSessionCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->rejectedSessionCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_sessionTimeoutCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->sessionTimeoutCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_sessionAbortCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->sessionAbortCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_currentSubscriptionCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->currentSubscriptionCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_cumulatedSubscriptionCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->cumulatedSubscriptionCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_publishingIntervalCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->publishingIntervalCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_securityRejectedRequestsCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->securityRejectedRequestsCount, *svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_rejectedRequestsCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->rejectedRequestsCount, *svp);

	return;
}
#endif

/* ServerStatusDataType */
#ifdef UA_TYPES_SERVERSTATUSDATATYPE
static void pack_UA_ServerStatusDataType(SV *out, const UA_ServerStatusDataType *in);
static void unpack_UA_ServerStatusDataType(UA_ServerStatusDataType *out, SV *in);

static void
pack_UA_ServerStatusDataType(SV *out, const UA_ServerStatusDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ServerStatusDataType_startTime", sv);
	pack_UA_DateTime(sv, &in->startTime);

	sv = newSV(0);
	hv_stores(hv, "ServerStatusDataType_currentTime", sv);
	pack_UA_DateTime(sv, &in->currentTime);

	sv = newSV(0);
	hv_stores(hv, "ServerStatusDataType_state", sv);
	pack_UA_ServerState(sv, &in->state);

	sv = newSV(0);
	hv_stores(hv, "ServerStatusDataType_buildInfo", sv);
	pack_UA_BuildInfo(sv, &in->buildInfo);

	sv = newSV(0);
	hv_stores(hv, "ServerStatusDataType_secondsTillShutdown", sv);
	pack_UA_UInt32(sv, &in->secondsTillShutdown);

	sv = newSV(0);
	hv_stores(hv, "ServerStatusDataType_shutdownReason", sv);
	pack_UA_LocalizedText(sv, &in->shutdownReason);

	return;
}

static void
unpack_UA_ServerStatusDataType(UA_ServerStatusDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ServerStatusDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServerStatusDataType_startTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->startTime, *svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_currentTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->currentTime, *svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_state", 0);
	if (svp != NULL)
		unpack_UA_ServerState(&out->state, *svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_buildInfo", 0);
	if (svp != NULL)
		unpack_UA_BuildInfo(&out->buildInfo, *svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_secondsTillShutdown", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->secondsTillShutdown, *svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_shutdownReason", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->shutdownReason, *svp);

	return;
}
#endif

/* SessionSecurityDiagnosticsDataType */
#ifdef UA_TYPES_SESSIONSECURITYDIAGNOSTICSDATATYPE
static void pack_UA_SessionSecurityDiagnosticsDataType(SV *out, const UA_SessionSecurityDiagnosticsDataType *in);
static void unpack_UA_SessionSecurityDiagnosticsDataType(UA_SessionSecurityDiagnosticsDataType *out, SV *in);

static void
pack_UA_SessionSecurityDiagnosticsDataType(SV *out, const UA_SessionSecurityDiagnosticsDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_sessionId", sv);
	pack_UA_NodeId(sv, &in->sessionId);

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_clientUserIdOfSession", sv);
	pack_UA_String(sv, &in->clientUserIdOfSession);

	av = newAV();
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_clientUserIdHistory", newRV_noinc((SV*)av));
	av_extend(av, in->clientUserIdHistorySize);
	for (i = 0; i < in->clientUserIdHistorySize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->clientUserIdHistory[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_authenticationMechanism", sv);
	pack_UA_String(sv, &in->authenticationMechanism);

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_encoding", sv);
	pack_UA_String(sv, &in->encoding);

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_transportProtocol", sv);
	pack_UA_String(sv, &in->transportProtocol);

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_securityPolicyUri", sv);
	pack_UA_String(sv, &in->securityPolicyUri);

	sv = newSV(0);
	hv_stores(hv, "SessionSecurityDiagnosticsDataType_clientCertificate", sv);
	pack_UA_ByteString(sv, &in->clientCertificate);

	return;
}

static void
unpack_UA_SessionSecurityDiagnosticsDataType(UA_SessionSecurityDiagnosticsDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SessionSecurityDiagnosticsDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_sessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->sessionId, *svp);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_clientUserIdOfSession", 0);
	if (svp != NULL)
		unpack_UA_String(&out->clientUserIdOfSession, *svp);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_clientUserIdHistory", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SessionSecurityDiagnosticsDataType_clientUserIdHistory");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->clientUserIdHistory = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->clientUserIdHistory == NULL)
			CROAKE("UA_Array_new");
		out->clientUserIdHistorySize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->clientUserIdHistory[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_authenticationMechanism", 0);
	if (svp != NULL)
		unpack_UA_String(&out->authenticationMechanism, *svp);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_encoding", 0);
	if (svp != NULL)
		unpack_UA_String(&out->encoding, *svp);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_transportProtocol", 0);
	if (svp != NULL)
		unpack_UA_String(&out->transportProtocol, *svp);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_securityPolicyUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityPolicyUri, *svp);

	svp = hv_fetchs(hv, "SessionSecurityDiagnosticsDataType_clientCertificate", 0);
	if (svp != NULL)
		unpack_UA_ByteString(&out->clientCertificate, *svp);

	return;
}
#endif

/* ServiceCounterDataType */
#ifdef UA_TYPES_SERVICECOUNTERDATATYPE
static void pack_UA_ServiceCounterDataType(SV *out, const UA_ServiceCounterDataType *in);
static void unpack_UA_ServiceCounterDataType(UA_ServiceCounterDataType *out, SV *in);

static void
pack_UA_ServiceCounterDataType(SV *out, const UA_ServiceCounterDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ServiceCounterDataType_totalCount", sv);
	pack_UA_UInt32(sv, &in->totalCount);

	sv = newSV(0);
	hv_stores(hv, "ServiceCounterDataType_errorCount", sv);
	pack_UA_UInt32(sv, &in->errorCount);

	return;
}

static void
unpack_UA_ServiceCounterDataType(UA_ServiceCounterDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ServiceCounterDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServiceCounterDataType_totalCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->totalCount, *svp);

	svp = hv_fetchs(hv, "ServiceCounterDataType_errorCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->errorCount, *svp);

	return;
}
#endif

/* StatusResult */
#ifdef UA_TYPES_STATUSRESULT
static void pack_UA_StatusResult(SV *out, const UA_StatusResult *in);
static void unpack_UA_StatusResult(UA_StatusResult *out, SV *in);

static void
pack_UA_StatusResult(SV *out, const UA_StatusResult *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "StatusResult_statusCode", sv);
	pack_UA_StatusCode(sv, &in->statusCode);

	sv = newSV(0);
	hv_stores(hv, "StatusResult_diagnosticInfo", sv);
	pack_UA_DiagnosticInfo(sv, &in->diagnosticInfo);

	return;
}

static void
unpack_UA_StatusResult(UA_StatusResult *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_StatusResult_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "StatusResult_statusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->statusCode, *svp);

	svp = hv_fetchs(hv, "StatusResult_diagnosticInfo", 0);
	if (svp != NULL)
		unpack_UA_DiagnosticInfo(&out->diagnosticInfo, *svp);

	return;
}
#endif

/* SubscriptionDiagnosticsDataType */
#ifdef UA_TYPES_SUBSCRIPTIONDIAGNOSTICSDATATYPE
static void pack_UA_SubscriptionDiagnosticsDataType(SV *out, const UA_SubscriptionDiagnosticsDataType *in);
static void unpack_UA_SubscriptionDiagnosticsDataType(UA_SubscriptionDiagnosticsDataType *out, SV *in);

static void
pack_UA_SubscriptionDiagnosticsDataType(SV *out, const UA_SubscriptionDiagnosticsDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_sessionId", sv);
	pack_UA_NodeId(sv, &in->sessionId);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_subscriptionId", sv);
	pack_UA_UInt32(sv, &in->subscriptionId);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_priority", sv);
	pack_UA_Byte(sv, &in->priority);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_publishingInterval", sv);
	pack_UA_Double(sv, &in->publishingInterval);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_maxKeepAliveCount", sv);
	pack_UA_UInt32(sv, &in->maxKeepAliveCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_maxLifetimeCount", sv);
	pack_UA_UInt32(sv, &in->maxLifetimeCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_maxNotificationsPerPublish", sv);
	pack_UA_UInt32(sv, &in->maxNotificationsPerPublish);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_publishingEnabled", sv);
	pack_UA_Boolean(sv, &in->publishingEnabled);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_modifyCount", sv);
	pack_UA_UInt32(sv, &in->modifyCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_enableCount", sv);
	pack_UA_UInt32(sv, &in->enableCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_disableCount", sv);
	pack_UA_UInt32(sv, &in->disableCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_republishRequestCount", sv);
	pack_UA_UInt32(sv, &in->republishRequestCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_republishMessageRequestCount", sv);
	pack_UA_UInt32(sv, &in->republishMessageRequestCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_republishMessageCount", sv);
	pack_UA_UInt32(sv, &in->republishMessageCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_transferRequestCount", sv);
	pack_UA_UInt32(sv, &in->transferRequestCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_transferredToAltClientCount", sv);
	pack_UA_UInt32(sv, &in->transferredToAltClientCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_transferredToSameClientCount", sv);
	pack_UA_UInt32(sv, &in->transferredToSameClientCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_publishRequestCount", sv);
	pack_UA_UInt32(sv, &in->publishRequestCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_dataChangeNotificationsCount", sv);
	pack_UA_UInt32(sv, &in->dataChangeNotificationsCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_eventNotificationsCount", sv);
	pack_UA_UInt32(sv, &in->eventNotificationsCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_notificationsCount", sv);
	pack_UA_UInt32(sv, &in->notificationsCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_latePublishRequestCount", sv);
	pack_UA_UInt32(sv, &in->latePublishRequestCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_currentKeepAliveCount", sv);
	pack_UA_UInt32(sv, &in->currentKeepAliveCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_currentLifetimeCount", sv);
	pack_UA_UInt32(sv, &in->currentLifetimeCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_unacknowledgedMessageCount", sv);
	pack_UA_UInt32(sv, &in->unacknowledgedMessageCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_discardedMessageCount", sv);
	pack_UA_UInt32(sv, &in->discardedMessageCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_monitoredItemCount", sv);
	pack_UA_UInt32(sv, &in->monitoredItemCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_disabledMonitoredItemCount", sv);
	pack_UA_UInt32(sv, &in->disabledMonitoredItemCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_monitoringQueueOverflowCount", sv);
	pack_UA_UInt32(sv, &in->monitoringQueueOverflowCount);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_nextSequenceNumber", sv);
	pack_UA_UInt32(sv, &in->nextSequenceNumber);

	sv = newSV(0);
	hv_stores(hv, "SubscriptionDiagnosticsDataType_eventQueueOverFlowCount", sv);
	pack_UA_UInt32(sv, &in->eventQueueOverFlowCount);

	return;
}

static void
unpack_UA_SubscriptionDiagnosticsDataType(UA_SubscriptionDiagnosticsDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SubscriptionDiagnosticsDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_sessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->sessionId, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_subscriptionId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->subscriptionId, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_priority", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->priority, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_publishingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->publishingInterval, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_maxKeepAliveCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxKeepAliveCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_maxLifetimeCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxLifetimeCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_maxNotificationsPerPublish", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxNotificationsPerPublish, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_publishingEnabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->publishingEnabled, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_modifyCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->modifyCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_enableCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->enableCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_disableCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->disableCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_republishRequestCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->republishRequestCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_republishMessageRequestCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->republishMessageRequestCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_republishMessageCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->republishMessageCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_transferRequestCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->transferRequestCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_transferredToAltClientCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->transferredToAltClientCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_transferredToSameClientCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->transferredToSameClientCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_publishRequestCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->publishRequestCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_dataChangeNotificationsCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->dataChangeNotificationsCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_eventNotificationsCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->eventNotificationsCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_notificationsCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->notificationsCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_latePublishRequestCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->latePublishRequestCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_currentKeepAliveCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->currentKeepAliveCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_currentLifetimeCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->currentLifetimeCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_unacknowledgedMessageCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->unacknowledgedMessageCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_discardedMessageCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->discardedMessageCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_monitoredItemCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->monitoredItemCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_disabledMonitoredItemCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->disabledMonitoredItemCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_monitoringQueueOverflowCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->monitoringQueueOverflowCount, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_nextSequenceNumber", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->nextSequenceNumber, *svp);

	svp = hv_fetchs(hv, "SubscriptionDiagnosticsDataType_eventQueueOverFlowCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->eventQueueOverFlowCount, *svp);

	return;
}
#endif

/* ModelChangeStructureVerbMask */
#ifdef UA_TYPES_MODELCHANGESTRUCTUREVERBMASK
static void pack_UA_ModelChangeStructureVerbMask(SV *out, const UA_ModelChangeStructureVerbMask *in);
static void unpack_UA_ModelChangeStructureVerbMask(UA_ModelChangeStructureVerbMask *out, SV *in);

static void
pack_UA_ModelChangeStructureVerbMask(SV *out, const UA_ModelChangeStructureVerbMask *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_ModelChangeStructureVerbMask(UA_ModelChangeStructureVerbMask *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ModelChangeStructureDataType */
#ifdef UA_TYPES_MODELCHANGESTRUCTUREDATATYPE
static void pack_UA_ModelChangeStructureDataType(SV *out, const UA_ModelChangeStructureDataType *in);
static void unpack_UA_ModelChangeStructureDataType(UA_ModelChangeStructureDataType *out, SV *in);

static void
pack_UA_ModelChangeStructureDataType(SV *out, const UA_ModelChangeStructureDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ModelChangeStructureDataType_affected", sv);
	pack_UA_NodeId(sv, &in->affected);

	sv = newSV(0);
	hv_stores(hv, "ModelChangeStructureDataType_affectedType", sv);
	pack_UA_NodeId(sv, &in->affectedType);

	sv = newSV(0);
	hv_stores(hv, "ModelChangeStructureDataType_verb", sv);
	pack_UA_Byte(sv, &in->verb);

	return;
}

static void
unpack_UA_ModelChangeStructureDataType(UA_ModelChangeStructureDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ModelChangeStructureDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModelChangeStructureDataType_affected", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->affected, *svp);

	svp = hv_fetchs(hv, "ModelChangeStructureDataType_affectedType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->affectedType, *svp);

	svp = hv_fetchs(hv, "ModelChangeStructureDataType_verb", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->verb, *svp);

	return;
}
#endif

/* SemanticChangeStructureDataType */
#ifdef UA_TYPES_SEMANTICCHANGESTRUCTUREDATATYPE
static void pack_UA_SemanticChangeStructureDataType(SV *out, const UA_SemanticChangeStructureDataType *in);
static void unpack_UA_SemanticChangeStructureDataType(UA_SemanticChangeStructureDataType *out, SV *in);

static void
pack_UA_SemanticChangeStructureDataType(SV *out, const UA_SemanticChangeStructureDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SemanticChangeStructureDataType_affected", sv);
	pack_UA_NodeId(sv, &in->affected);

	sv = newSV(0);
	hv_stores(hv, "SemanticChangeStructureDataType_affectedType", sv);
	pack_UA_NodeId(sv, &in->affectedType);

	return;
}

static void
unpack_UA_SemanticChangeStructureDataType(UA_SemanticChangeStructureDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SemanticChangeStructureDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SemanticChangeStructureDataType_affected", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->affected, *svp);

	svp = hv_fetchs(hv, "SemanticChangeStructureDataType_affectedType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->affectedType, *svp);

	return;
}
#endif

/* Range */
#ifdef UA_TYPES_RANGE
static void pack_UA_Range(SV *out, const UA_Range *in);
static void unpack_UA_Range(UA_Range *out, SV *in);

static void
pack_UA_Range(SV *out, const UA_Range *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "Range_low", sv);
	pack_UA_Double(sv, &in->low);

	sv = newSV(0);
	hv_stores(hv, "Range_high", sv);
	pack_UA_Double(sv, &in->high);

	return;
}

static void
unpack_UA_Range(UA_Range *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_Range_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "Range_low", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->low, *svp);

	svp = hv_fetchs(hv, "Range_high", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->high, *svp);

	return;
}
#endif

/* EUInformation */
#ifdef UA_TYPES_EUINFORMATION
static void pack_UA_EUInformation(SV *out, const UA_EUInformation *in);
static void unpack_UA_EUInformation(UA_EUInformation *out, SV *in);

static void
pack_UA_EUInformation(SV *out, const UA_EUInformation *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EUInformation_namespaceUri", sv);
	pack_UA_String(sv, &in->namespaceUri);

	sv = newSV(0);
	hv_stores(hv, "EUInformation_unitId", sv);
	pack_UA_Int32(sv, &in->unitId);

	sv = newSV(0);
	hv_stores(hv, "EUInformation_displayName", sv);
	pack_UA_LocalizedText(sv, &in->displayName);

	sv = newSV(0);
	hv_stores(hv, "EUInformation_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	return;
}

static void
unpack_UA_EUInformation(UA_EUInformation *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EUInformation_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EUInformation_namespaceUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->namespaceUri, *svp);

	svp = hv_fetchs(hv, "EUInformation_unitId", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->unitId, *svp);

	svp = hv_fetchs(hv, "EUInformation_displayName", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->displayName, *svp);

	svp = hv_fetchs(hv, "EUInformation_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	return;
}
#endif

/* AxisScaleEnumeration */
#ifdef UA_TYPES_AXISSCALEENUMERATION
static void pack_UA_AxisScaleEnumeration(SV *out, const UA_AxisScaleEnumeration *in);
static void unpack_UA_AxisScaleEnumeration(UA_AxisScaleEnumeration *out, SV *in);

static void
pack_UA_AxisScaleEnumeration(SV *out, const UA_AxisScaleEnumeration *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_AxisScaleEnumeration(UA_AxisScaleEnumeration *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* ComplexNumberType */
#ifdef UA_TYPES_COMPLEXNUMBERTYPE
static void pack_UA_ComplexNumberType(SV *out, const UA_ComplexNumberType *in);
static void unpack_UA_ComplexNumberType(UA_ComplexNumberType *out, SV *in);

static void
pack_UA_ComplexNumberType(SV *out, const UA_ComplexNumberType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ComplexNumberType_real", sv);
	pack_UA_Float(sv, &in->real);

	sv = newSV(0);
	hv_stores(hv, "ComplexNumberType_imaginary", sv);
	pack_UA_Float(sv, &in->imaginary);

	return;
}

static void
unpack_UA_ComplexNumberType(UA_ComplexNumberType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ComplexNumberType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ComplexNumberType_real", 0);
	if (svp != NULL)
		unpack_UA_Float(&out->real, *svp);

	svp = hv_fetchs(hv, "ComplexNumberType_imaginary", 0);
	if (svp != NULL)
		unpack_UA_Float(&out->imaginary, *svp);

	return;
}
#endif

/* DoubleComplexNumberType */
#ifdef UA_TYPES_DOUBLECOMPLEXNUMBERTYPE
static void pack_UA_DoubleComplexNumberType(SV *out, const UA_DoubleComplexNumberType *in);
static void unpack_UA_DoubleComplexNumberType(UA_DoubleComplexNumberType *out, SV *in);

static void
pack_UA_DoubleComplexNumberType(SV *out, const UA_DoubleComplexNumberType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DoubleComplexNumberType_real", sv);
	pack_UA_Double(sv, &in->real);

	sv = newSV(0);
	hv_stores(hv, "DoubleComplexNumberType_imaginary", sv);
	pack_UA_Double(sv, &in->imaginary);

	return;
}

static void
unpack_UA_DoubleComplexNumberType(UA_DoubleComplexNumberType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DoubleComplexNumberType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DoubleComplexNumberType_real", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->real, *svp);

	svp = hv_fetchs(hv, "DoubleComplexNumberType_imaginary", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->imaginary, *svp);

	return;
}
#endif

/* AxisInformation */
#ifdef UA_TYPES_AXISINFORMATION
static void pack_UA_AxisInformation(SV *out, const UA_AxisInformation *in);
static void unpack_UA_AxisInformation(UA_AxisInformation *out, SV *in);

static void
pack_UA_AxisInformation(SV *out, const UA_AxisInformation *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "AxisInformation_engineeringUnits", sv);
	pack_UA_EUInformation(sv, &in->engineeringUnits);

	sv = newSV(0);
	hv_stores(hv, "AxisInformation_eURange", sv);
	pack_UA_Range(sv, &in->eURange);

	sv = newSV(0);
	hv_stores(hv, "AxisInformation_title", sv);
	pack_UA_LocalizedText(sv, &in->title);

	sv = newSV(0);
	hv_stores(hv, "AxisInformation_axisScaleType", sv);
	pack_UA_AxisScaleEnumeration(sv, &in->axisScaleType);

	av = newAV();
	hv_stores(hv, "AxisInformation_axisSteps", newRV_noinc((SV*)av));
	av_extend(av, in->axisStepsSize);
	for (i = 0; i < in->axisStepsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Double(sv, &in->axisSteps[i]);
	}

	return;
}

static void
unpack_UA_AxisInformation(UA_AxisInformation *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_AxisInformation_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AxisInformation_engineeringUnits", 0);
	if (svp != NULL)
		unpack_UA_EUInformation(&out->engineeringUnits, *svp);

	svp = hv_fetchs(hv, "AxisInformation_eURange", 0);
	if (svp != NULL)
		unpack_UA_Range(&out->eURange, *svp);

	svp = hv_fetchs(hv, "AxisInformation_title", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->title, *svp);

	svp = hv_fetchs(hv, "AxisInformation_axisScaleType", 0);
	if (svp != NULL)
		unpack_UA_AxisScaleEnumeration(&out->axisScaleType, *svp);

	svp = hv_fetchs(hv, "AxisInformation_axisSteps", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for AxisInformation_axisSteps");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->axisSteps = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DOUBLE]);
		if (out->axisSteps == NULL)
			CROAKE("UA_Array_new");
		out->axisStepsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Double(&out->axisSteps[i], *svp);
		}
	}

	return;
}
#endif

/* XVType */
#ifdef UA_TYPES_XVTYPE
static void pack_UA_XVType(SV *out, const UA_XVType *in);
static void unpack_UA_XVType(UA_XVType *out, SV *in);

static void
pack_UA_XVType(SV *out, const UA_XVType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "XVType_x", sv);
	pack_UA_Double(sv, &in->x);

	sv = newSV(0);
	hv_stores(hv, "XVType_value", sv);
	pack_UA_Float(sv, &in->value);

	return;
}

static void
unpack_UA_XVType(UA_XVType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_XVType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "XVType_x", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->x, *svp);

	svp = hv_fetchs(hv, "XVType_value", 0);
	if (svp != NULL)
		unpack_UA_Float(&out->value, *svp);

	return;
}
#endif

/* ProgramDiagnosticDataType */
#ifdef UA_TYPES_PROGRAMDIAGNOSTICDATATYPE
static void pack_UA_ProgramDiagnosticDataType(SV *out, const UA_ProgramDiagnosticDataType *in);
static void unpack_UA_ProgramDiagnosticDataType(UA_ProgramDiagnosticDataType *out, SV *in);

static void
pack_UA_ProgramDiagnosticDataType(SV *out, const UA_ProgramDiagnosticDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_createSessionId", sv);
	pack_UA_NodeId(sv, &in->createSessionId);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_createClientName", sv);
	pack_UA_String(sv, &in->createClientName);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_invocationCreationTime", sv);
	pack_UA_DateTime(sv, &in->invocationCreationTime);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_lastTransitionTime", sv);
	pack_UA_DateTime(sv, &in->lastTransitionTime);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_lastMethodCall", sv);
	pack_UA_String(sv, &in->lastMethodCall);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_lastMethodSessionId", sv);
	pack_UA_NodeId(sv, &in->lastMethodSessionId);

	av = newAV();
	hv_stores(hv, "ProgramDiagnosticDataType_lastMethodInputArguments", newRV_noinc((SV*)av));
	av_extend(av, in->lastMethodInputArgumentsSize);
	for (i = 0; i < in->lastMethodInputArgumentsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Argument(sv, &in->lastMethodInputArguments[i]);
	}

	av = newAV();
	hv_stores(hv, "ProgramDiagnosticDataType_lastMethodOutputArguments", newRV_noinc((SV*)av));
	av_extend(av, in->lastMethodOutputArgumentsSize);
	for (i = 0; i < in->lastMethodOutputArgumentsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Argument(sv, &in->lastMethodOutputArguments[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_lastMethodCallTime", sv);
	pack_UA_DateTime(sv, &in->lastMethodCallTime);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnosticDataType_lastMethodReturnStatus", sv);
	pack_UA_StatusResult(sv, &in->lastMethodReturnStatus);

	return;
}

static void
unpack_UA_ProgramDiagnosticDataType(UA_ProgramDiagnosticDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ProgramDiagnosticDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_createSessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->createSessionId, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_createClientName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->createClientName, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_invocationCreationTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->invocationCreationTime, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_lastTransitionTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->lastTransitionTime, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_lastMethodCall", 0);
	if (svp != NULL)
		unpack_UA_String(&out->lastMethodCall, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_lastMethodSessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->lastMethodSessionId, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_lastMethodInputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ProgramDiagnosticDataType_lastMethodInputArguments");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->lastMethodInputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ARGUMENT]);
		if (out->lastMethodInputArguments == NULL)
			CROAKE("UA_Array_new");
		out->lastMethodInputArgumentsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Argument(&out->lastMethodInputArguments[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_lastMethodOutputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ProgramDiagnosticDataType_lastMethodOutputArguments");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->lastMethodOutputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ARGUMENT]);
		if (out->lastMethodOutputArguments == NULL)
			CROAKE("UA_Array_new");
		out->lastMethodOutputArgumentsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Argument(&out->lastMethodOutputArguments[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_lastMethodCallTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->lastMethodCallTime, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnosticDataType_lastMethodReturnStatus", 0);
	if (svp != NULL)
		unpack_UA_StatusResult(&out->lastMethodReturnStatus, *svp);

	return;
}
#endif

/* ProgramDiagnostic2DataType */
#ifdef UA_TYPES_PROGRAMDIAGNOSTIC2DATATYPE
static void pack_UA_ProgramDiagnostic2DataType(SV *out, const UA_ProgramDiagnostic2DataType *in);
static void unpack_UA_ProgramDiagnostic2DataType(UA_ProgramDiagnostic2DataType *out, SV *in);

static void
pack_UA_ProgramDiagnostic2DataType(SV *out, const UA_ProgramDiagnostic2DataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_createSessionId", sv);
	pack_UA_NodeId(sv, &in->createSessionId);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_createClientName", sv);
	pack_UA_String(sv, &in->createClientName);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_invocationCreationTime", sv);
	pack_UA_DateTime(sv, &in->invocationCreationTime);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_lastTransitionTime", sv);
	pack_UA_DateTime(sv, &in->lastTransitionTime);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodCall", sv);
	pack_UA_String(sv, &in->lastMethodCall);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodSessionId", sv);
	pack_UA_NodeId(sv, &in->lastMethodSessionId);

	av = newAV();
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodInputArguments", newRV_noinc((SV*)av));
	av_extend(av, in->lastMethodInputArgumentsSize);
	for (i = 0; i < in->lastMethodInputArgumentsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Argument(sv, &in->lastMethodInputArguments[i]);
	}

	av = newAV();
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodOutputArguments", newRV_noinc((SV*)av));
	av_extend(av, in->lastMethodOutputArgumentsSize);
	for (i = 0; i < in->lastMethodOutputArgumentsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Argument(sv, &in->lastMethodOutputArguments[i]);
	}

	av = newAV();
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodInputValues", newRV_noinc((SV*)av));
	av_extend(av, in->lastMethodInputValuesSize);
	for (i = 0; i < in->lastMethodInputValuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Variant(sv, &in->lastMethodInputValues[i]);
	}

	av = newAV();
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodOutputValues", newRV_noinc((SV*)av));
	av_extend(av, in->lastMethodOutputValuesSize);
	for (i = 0; i < in->lastMethodOutputValuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_Variant(sv, &in->lastMethodOutputValues[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodCallTime", sv);
	pack_UA_DateTime(sv, &in->lastMethodCallTime);

	sv = newSV(0);
	hv_stores(hv, "ProgramDiagnostic2DataType_lastMethodReturnStatus", sv);
	pack_UA_StatusCode(sv, &in->lastMethodReturnStatus);

	return;
}

static void
unpack_UA_ProgramDiagnostic2DataType(UA_ProgramDiagnostic2DataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ProgramDiagnostic2DataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_createSessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->createSessionId, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_createClientName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->createClientName, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_invocationCreationTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->invocationCreationTime, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastTransitionTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->lastTransitionTime, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodCall", 0);
	if (svp != NULL)
		unpack_UA_String(&out->lastMethodCall, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodSessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->lastMethodSessionId, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodInputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ProgramDiagnostic2DataType_lastMethodInputArguments");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->lastMethodInputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ARGUMENT]);
		if (out->lastMethodInputArguments == NULL)
			CROAKE("UA_Array_new");
		out->lastMethodInputArgumentsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Argument(&out->lastMethodInputArguments[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodOutputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ProgramDiagnostic2DataType_lastMethodOutputArguments");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->lastMethodOutputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ARGUMENT]);
		if (out->lastMethodOutputArguments == NULL)
			CROAKE("UA_Array_new");
		out->lastMethodOutputArgumentsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Argument(&out->lastMethodOutputArguments[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodInputValues", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ProgramDiagnostic2DataType_lastMethodInputValues");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->lastMethodInputValues = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out->lastMethodInputValues == NULL)
			CROAKE("UA_Array_new");
		out->lastMethodInputValuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Variant(&out->lastMethodInputValues[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodOutputValues", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ProgramDiagnostic2DataType_lastMethodOutputValues");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->lastMethodOutputValues = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out->lastMethodOutputValues == NULL)
			CROAKE("UA_Array_new");
		out->lastMethodOutputValuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_Variant(&out->lastMethodOutputValues[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodCallTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->lastMethodCallTime, *svp);

	svp = hv_fetchs(hv, "ProgramDiagnostic2DataType_lastMethodReturnStatus", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->lastMethodReturnStatus, *svp);

	return;
}
#endif

/* Annotation */
#ifdef UA_TYPES_ANNOTATION
static void pack_UA_Annotation(SV *out, const UA_Annotation *in);
static void unpack_UA_Annotation(UA_Annotation *out, SV *in);

static void
pack_UA_Annotation(SV *out, const UA_Annotation *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "Annotation_message", sv);
	pack_UA_String(sv, &in->message);

	sv = newSV(0);
	hv_stores(hv, "Annotation_userName", sv);
	pack_UA_String(sv, &in->userName);

	sv = newSV(0);
	hv_stores(hv, "Annotation_annotationTime", sv);
	pack_UA_DateTime(sv, &in->annotationTime);

	return;
}

static void
unpack_UA_Annotation(UA_Annotation *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_Annotation_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "Annotation_message", 0);
	if (svp != NULL)
		unpack_UA_String(&out->message, *svp);

	svp = hv_fetchs(hv, "Annotation_userName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->userName, *svp);

	svp = hv_fetchs(hv, "Annotation_annotationTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->annotationTime, *svp);

	return;
}
#endif

/* ExceptionDeviationFormat */
#ifdef UA_TYPES_EXCEPTIONDEVIATIONFORMAT
static void pack_UA_ExceptionDeviationFormat(SV *out, const UA_ExceptionDeviationFormat *in);
static void unpack_UA_ExceptionDeviationFormat(UA_ExceptionDeviationFormat *out, SV *in);

static void
pack_UA_ExceptionDeviationFormat(SV *out, const UA_ExceptionDeviationFormat *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_ExceptionDeviationFormat(UA_ExceptionDeviationFormat *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}
#endif

/* EndpointType */
#ifdef UA_TYPES_ENDPOINTTYPE
static void pack_UA_EndpointType(SV *out, const UA_EndpointType *in);
static void unpack_UA_EndpointType(UA_EndpointType *out, SV *in);

static void
pack_UA_EndpointType(SV *out, const UA_EndpointType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EndpointType_endpointUrl", sv);
	pack_UA_String(sv, &in->endpointUrl);

	sv = newSV(0);
	hv_stores(hv, "EndpointType_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "EndpointType_securityPolicyUri", sv);
	pack_UA_String(sv, &in->securityPolicyUri);

	sv = newSV(0);
	hv_stores(hv, "EndpointType_transportProfileUri", sv);
	pack_UA_String(sv, &in->transportProfileUri);

	return;
}

static void
unpack_UA_EndpointType(UA_EndpointType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EndpointType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EndpointType_endpointUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->endpointUrl, *svp);

	svp = hv_fetchs(hv, "EndpointType_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "EndpointType_securityPolicyUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityPolicyUri, *svp);

	svp = hv_fetchs(hv, "EndpointType_transportProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->transportProfileUri, *svp);

	return;
}
#endif

/* StructureDescription */
#ifdef UA_TYPES_STRUCTUREDESCRIPTION
static void pack_UA_StructureDescription(SV *out, const UA_StructureDescription *in);
static void unpack_UA_StructureDescription(UA_StructureDescription *out, SV *in);

static void
pack_UA_StructureDescription(SV *out, const UA_StructureDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "StructureDescription_dataTypeId", sv);
	pack_UA_NodeId(sv, &in->dataTypeId);

	sv = newSV(0);
	hv_stores(hv, "StructureDescription_name", sv);
	pack_UA_QualifiedName(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "StructureDescription_structureDefinition", sv);
	pack_UA_StructureDefinition(sv, &in->structureDefinition);

	return;
}

static void
unpack_UA_StructureDescription(UA_StructureDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_StructureDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "StructureDescription_dataTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataTypeId, *svp);

	svp = hv_fetchs(hv, "StructureDescription_name", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->name, *svp);

	svp = hv_fetchs(hv, "StructureDescription_structureDefinition", 0);
	if (svp != NULL)
		unpack_UA_StructureDefinition(&out->structureDefinition, *svp);

	return;
}
#endif

/* FieldMetaData */
#ifdef UA_TYPES_FIELDMETADATA
static void pack_UA_FieldMetaData(SV *out, const UA_FieldMetaData *in);
static void unpack_UA_FieldMetaData(UA_FieldMetaData *out, SV *in);

static void
pack_UA_FieldMetaData(SV *out, const UA_FieldMetaData *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_fieldFlags", sv);
	pack_UA_DataSetFieldFlags(sv, &in->fieldFlags);

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_builtInType", sv);
	pack_UA_Byte(sv, &in->builtInType);

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_dataType", sv);
	pack_UA_NodeId(sv, &in->dataType);

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_valueRank", sv);
	pack_UA_Int32(sv, &in->valueRank);

	av = newAV();
	hv_stores(hv, "FieldMetaData_arrayDimensions", newRV_noinc((SV*)av));
	av_extend(av, in->arrayDimensionsSize);
	for (i = 0; i < in->arrayDimensionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, &in->arrayDimensions[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_maxStringLength", sv);
	pack_UA_UInt32(sv, &in->maxStringLength);

	sv = newSV(0);
	hv_stores(hv, "FieldMetaData_dataSetFieldId", sv);
	pack_UA_Guid(sv, &in->dataSetFieldId);

	av = newAV();
	hv_stores(hv, "FieldMetaData_properties", newRV_noinc((SV*)av));
	av_extend(av, in->propertiesSize);
	for (i = 0; i < in->propertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->properties[i]);
	}

	return;
}

static void
unpack_UA_FieldMetaData(UA_FieldMetaData *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_FieldMetaData_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FieldMetaData_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_fieldFlags", 0);
	if (svp != NULL)
		unpack_UA_DataSetFieldFlags(&out->fieldFlags, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_builtInType", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->builtInType, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_dataType", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataType, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_valueRank", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->valueRank, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for FieldMetaData_arrayDimensions");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out->arrayDimensions == NULL)
			CROAKE("UA_Array_new");
		out->arrayDimensionsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_UInt32(&out->arrayDimensions[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "FieldMetaData_maxStringLength", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxStringLength, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_dataSetFieldId", 0);
	if (svp != NULL)
		unpack_UA_Guid(&out->dataSetFieldId, *svp);

	svp = hv_fetchs(hv, "FieldMetaData_properties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for FieldMetaData_properties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->properties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->properties == NULL)
			CROAKE("UA_Array_new");
		out->propertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->properties[i], *svp);
		}
	}

	return;
}
#endif

/* PublishedEventsDataType */
#ifdef UA_TYPES_PUBLISHEDEVENTSDATATYPE
static void pack_UA_PublishedEventsDataType(SV *out, const UA_PublishedEventsDataType *in);
static void unpack_UA_PublishedEventsDataType(UA_PublishedEventsDataType *out, SV *in);

static void
pack_UA_PublishedEventsDataType(SV *out, const UA_PublishedEventsDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "PublishedEventsDataType_eventNotifier", sv);
	pack_UA_NodeId(sv, &in->eventNotifier);

	av = newAV();
	hv_stores(hv, "PublishedEventsDataType_selectedFields", newRV_noinc((SV*)av));
	av_extend(av, in->selectedFieldsSize);
	for (i = 0; i < in->selectedFieldsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SimpleAttributeOperand(sv, &in->selectedFields[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "PublishedEventsDataType_filter", sv);
	pack_UA_ContentFilter(sv, &in->filter);

	return;
}

static void
unpack_UA_PublishedEventsDataType(UA_PublishedEventsDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PublishedEventsDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishedEventsDataType_eventNotifier", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->eventNotifier, *svp);

	svp = hv_fetchs(hv, "PublishedEventsDataType_selectedFields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishedEventsDataType_selectedFields");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->selectedFields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIMPLEATTRIBUTEOPERAND]);
		if (out->selectedFields == NULL)
			CROAKE("UA_Array_new");
		out->selectedFieldsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SimpleAttributeOperand(&out->selectedFields[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PublishedEventsDataType_filter", 0);
	if (svp != NULL)
		unpack_UA_ContentFilter(&out->filter, *svp);

	return;
}
#endif

/* PubSubGroupDataType */
#ifdef UA_TYPES_PUBSUBGROUPDATATYPE
static void pack_UA_PubSubGroupDataType(SV *out, const UA_PubSubGroupDataType *in);
static void unpack_UA_PubSubGroupDataType(UA_PubSubGroupDataType *out, SV *in);

static void
pack_UA_PubSubGroupDataType(SV *out, const UA_PubSubGroupDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "PubSubGroupDataType_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "PubSubGroupDataType_enabled", sv);
	pack_UA_Boolean(sv, &in->enabled);

	sv = newSV(0);
	hv_stores(hv, "PubSubGroupDataType_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "PubSubGroupDataType_securityGroupId", sv);
	pack_UA_String(sv, &in->securityGroupId);

	av = newAV();
	hv_stores(hv, "PubSubGroupDataType_securityKeyServices", newRV_noinc((SV*)av));
	av_extend(av, in->securityKeyServicesSize);
	for (i = 0; i < in->securityKeyServicesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EndpointDescription(sv, &in->securityKeyServices[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "PubSubGroupDataType_maxNetworkMessageSize", sv);
	pack_UA_UInt32(sv, &in->maxNetworkMessageSize);

	av = newAV();
	hv_stores(hv, "PubSubGroupDataType_groupProperties", newRV_noinc((SV*)av));
	av_extend(av, in->groupPropertiesSize);
	for (i = 0; i < in->groupPropertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->groupProperties[i]);
	}

	return;
}

static void
unpack_UA_PubSubGroupDataType(UA_PubSubGroupDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PubSubGroupDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PubSubGroupDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "PubSubGroupDataType_enabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->enabled, *svp);

	svp = hv_fetchs(hv, "PubSubGroupDataType_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "PubSubGroupDataType_securityGroupId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityGroupId, *svp);

	svp = hv_fetchs(hv, "PubSubGroupDataType_securityKeyServices", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PubSubGroupDataType_securityKeyServices");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->securityKeyServices = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out->securityKeyServices == NULL)
			CROAKE("UA_Array_new");
		out->securityKeyServicesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EndpointDescription(&out->securityKeyServices[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PubSubGroupDataType_maxNetworkMessageSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxNetworkMessageSize, *svp);

	svp = hv_fetchs(hv, "PubSubGroupDataType_groupProperties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PubSubGroupDataType_groupProperties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->groupProperties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->groupProperties == NULL)
			CROAKE("UA_Array_new");
		out->groupPropertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->groupProperties[i], *svp);
		}
	}

	return;
}
#endif

/* WriterGroupDataType */
#ifdef UA_TYPES_WRITERGROUPDATATYPE
static void pack_UA_WriterGroupDataType(SV *out, const UA_WriterGroupDataType *in);
static void unpack_UA_WriterGroupDataType(UA_WriterGroupDataType *out, SV *in);

static void
pack_UA_WriterGroupDataType(SV *out, const UA_WriterGroupDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_enabled", sv);
	pack_UA_Boolean(sv, &in->enabled);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_securityGroupId", sv);
	pack_UA_String(sv, &in->securityGroupId);

	av = newAV();
	hv_stores(hv, "WriterGroupDataType_securityKeyServices", newRV_noinc((SV*)av));
	av_extend(av, in->securityKeyServicesSize);
	for (i = 0; i < in->securityKeyServicesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EndpointDescription(sv, &in->securityKeyServices[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_maxNetworkMessageSize", sv);
	pack_UA_UInt32(sv, &in->maxNetworkMessageSize);

	av = newAV();
	hv_stores(hv, "WriterGroupDataType_groupProperties", newRV_noinc((SV*)av));
	av_extend(av, in->groupPropertiesSize);
	for (i = 0; i < in->groupPropertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->groupProperties[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_writerGroupId", sv);
	pack_UA_UInt16(sv, &in->writerGroupId);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_publishingInterval", sv);
	pack_UA_Double(sv, &in->publishingInterval);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_keepAliveTime", sv);
	pack_UA_Double(sv, &in->keepAliveTime);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_priority", sv);
	pack_UA_Byte(sv, &in->priority);

	av = newAV();
	hv_stores(hv, "WriterGroupDataType_localeIds", newRV_noinc((SV*)av));
	av_extend(av, in->localeIdsSize);
	for (i = 0; i < in->localeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->localeIds[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_headerLayoutUri", sv);
	pack_UA_String(sv, &in->headerLayoutUri);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_transportSettings", sv);
	pack_UA_ExtensionObject(sv, &in->transportSettings);

	sv = newSV(0);
	hv_stores(hv, "WriterGroupDataType_messageSettings", sv);
	pack_UA_ExtensionObject(sv, &in->messageSettings);

	av = newAV();
	hv_stores(hv, "WriterGroupDataType_dataSetWriters", newRV_noinc((SV*)av));
	av_extend(av, in->dataSetWritersSize);
	for (i = 0; i < in->dataSetWritersSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DataSetWriterDataType(sv, &in->dataSetWriters[i]);
	}

	return;
}

static void
unpack_UA_WriterGroupDataType(UA_WriterGroupDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_WriterGroupDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "WriterGroupDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_enabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->enabled, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_securityGroupId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityGroupId, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_securityKeyServices", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for WriterGroupDataType_securityKeyServices");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->securityKeyServices = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out->securityKeyServices == NULL)
			CROAKE("UA_Array_new");
		out->securityKeyServicesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EndpointDescription(&out->securityKeyServices[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "WriterGroupDataType_maxNetworkMessageSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxNetworkMessageSize, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_groupProperties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for WriterGroupDataType_groupProperties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->groupProperties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->groupProperties == NULL)
			CROAKE("UA_Array_new");
		out->groupPropertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->groupProperties[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "WriterGroupDataType_writerGroupId", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->writerGroupId, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_publishingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->publishingInterval, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_keepAliveTime", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->keepAliveTime, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_priority", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->priority, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for WriterGroupDataType_localeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->localeIds == NULL)
			CROAKE("UA_Array_new");
		out->localeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->localeIds[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "WriterGroupDataType_headerLayoutUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->headerLayoutUri, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_transportSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->transportSettings, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_messageSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->messageSettings, *svp);

	svp = hv_fetchs(hv, "WriterGroupDataType_dataSetWriters", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for WriterGroupDataType_dataSetWriters");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataSetWriters = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATASETWRITERDATATYPE]);
		if (out->dataSetWriters == NULL)
			CROAKE("UA_Array_new");
		out->dataSetWritersSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DataSetWriterDataType(&out->dataSetWriters[i], *svp);
		}
	}

	return;
}
#endif

/* FieldTargetDataType */
#ifdef UA_TYPES_FIELDTARGETDATATYPE
static void pack_UA_FieldTargetDataType(SV *out, const UA_FieldTargetDataType *in);
static void unpack_UA_FieldTargetDataType(UA_FieldTargetDataType *out, SV *in);

static void
pack_UA_FieldTargetDataType(SV *out, const UA_FieldTargetDataType *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "FieldTargetDataType_dataSetFieldId", sv);
	pack_UA_Guid(sv, &in->dataSetFieldId);

	sv = newSV(0);
	hv_stores(hv, "FieldTargetDataType_receiverIndexRange", sv);
	pack_UA_String(sv, &in->receiverIndexRange);

	sv = newSV(0);
	hv_stores(hv, "FieldTargetDataType_targetNodeId", sv);
	pack_UA_NodeId(sv, &in->targetNodeId);

	sv = newSV(0);
	hv_stores(hv, "FieldTargetDataType_attributeId", sv);
	pack_UA_UInt32(sv, &in->attributeId);

	sv = newSV(0);
	hv_stores(hv, "FieldTargetDataType_writeIndexRange", sv);
	pack_UA_String(sv, &in->writeIndexRange);

	sv = newSV(0);
	hv_stores(hv, "FieldTargetDataType_overrideValueHandling", sv);
	pack_UA_OverrideValueHandling(sv, &in->overrideValueHandling);

	sv = newSV(0);
	hv_stores(hv, "FieldTargetDataType_overrideValue", sv);
	pack_UA_Variant(sv, &in->overrideValue);

	return;
}

static void
unpack_UA_FieldTargetDataType(UA_FieldTargetDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_FieldTargetDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FieldTargetDataType_dataSetFieldId", 0);
	if (svp != NULL)
		unpack_UA_Guid(&out->dataSetFieldId, *svp);

	svp = hv_fetchs(hv, "FieldTargetDataType_receiverIndexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->receiverIndexRange, *svp);

	svp = hv_fetchs(hv, "FieldTargetDataType_targetNodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->targetNodeId, *svp);

	svp = hv_fetchs(hv, "FieldTargetDataType_attributeId", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->attributeId, *svp);

	svp = hv_fetchs(hv, "FieldTargetDataType_writeIndexRange", 0);
	if (svp != NULL)
		unpack_UA_String(&out->writeIndexRange, *svp);

	svp = hv_fetchs(hv, "FieldTargetDataType_overrideValueHandling", 0);
	if (svp != NULL)
		unpack_UA_OverrideValueHandling(&out->overrideValueHandling, *svp);

	svp = hv_fetchs(hv, "FieldTargetDataType_overrideValue", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->overrideValue, *svp);

	return;
}
#endif

/* SubscribedDataSetMirrorDataType */
#ifdef UA_TYPES_SUBSCRIBEDDATASETMIRRORDATATYPE
static void pack_UA_SubscribedDataSetMirrorDataType(SV *out, const UA_SubscribedDataSetMirrorDataType *in);
static void unpack_UA_SubscribedDataSetMirrorDataType(UA_SubscribedDataSetMirrorDataType *out, SV *in);

static void
pack_UA_SubscribedDataSetMirrorDataType(SV *out, const UA_SubscribedDataSetMirrorDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SubscribedDataSetMirrorDataType_parentNodeName", sv);
	pack_UA_String(sv, &in->parentNodeName);

	av = newAV();
	hv_stores(hv, "SubscribedDataSetMirrorDataType_rolePermissions", newRV_noinc((SV*)av));
	av_extend(av, in->rolePermissionsSize);
	for (i = 0; i < in->rolePermissionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_RolePermissionType(sv, &in->rolePermissions[i]);
	}

	return;
}

static void
unpack_UA_SubscribedDataSetMirrorDataType(UA_SubscribedDataSetMirrorDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SubscribedDataSetMirrorDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SubscribedDataSetMirrorDataType_parentNodeName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->parentNodeName, *svp);

	svp = hv_fetchs(hv, "SubscribedDataSetMirrorDataType_rolePermissions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SubscribedDataSetMirrorDataType_rolePermissions");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->rolePermissions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ROLEPERMISSIONTYPE]);
		if (out->rolePermissions == NULL)
			CROAKE("UA_Array_new");
		out->rolePermissionsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_RolePermissionType(&out->rolePermissions[i], *svp);
		}
	}

	return;
}
#endif

/* EnumDefinition */
#ifdef UA_TYPES_ENUMDEFINITION
static void pack_UA_EnumDefinition(SV *out, const UA_EnumDefinition *in);
static void unpack_UA_EnumDefinition(UA_EnumDefinition *out, SV *in);

static void
pack_UA_EnumDefinition(SV *out, const UA_EnumDefinition *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "EnumDefinition_fields", newRV_noinc((SV*)av));
	av_extend(av, in->fieldsSize);
	for (i = 0; i < in->fieldsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EnumField(sv, &in->fields[i]);
	}

	return;
}

static void
unpack_UA_EnumDefinition(UA_EnumDefinition *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EnumDefinition_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EnumDefinition_fields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EnumDefinition_fields");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->fields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENUMFIELD]);
		if (out->fields == NULL)
			CROAKE("UA_Array_new");
		out->fieldsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EnumField(&out->fields[i], *svp);
		}
	}

	return;
}
#endif

/* ReadEventDetails */
#ifdef UA_TYPES_READEVENTDETAILS
static void pack_UA_ReadEventDetails(SV *out, const UA_ReadEventDetails *in);
static void unpack_UA_ReadEventDetails(UA_ReadEventDetails *out, SV *in);

static void
pack_UA_ReadEventDetails(SV *out, const UA_ReadEventDetails *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReadEventDetails_numValuesPerNode", sv);
	pack_UA_UInt32(sv, &in->numValuesPerNode);

	sv = newSV(0);
	hv_stores(hv, "ReadEventDetails_startTime", sv);
	pack_UA_DateTime(sv, &in->startTime);

	sv = newSV(0);
	hv_stores(hv, "ReadEventDetails_endTime", sv);
	pack_UA_DateTime(sv, &in->endTime);

	sv = newSV(0);
	hv_stores(hv, "ReadEventDetails_filter", sv);
	pack_UA_EventFilter(sv, &in->filter);

	return;
}

static void
unpack_UA_ReadEventDetails(UA_ReadEventDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadEventDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadEventDetails_numValuesPerNode", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->numValuesPerNode, *svp);

	svp = hv_fetchs(hv, "ReadEventDetails_startTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->startTime, *svp);

	svp = hv_fetchs(hv, "ReadEventDetails_endTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->endTime, *svp);

	svp = hv_fetchs(hv, "ReadEventDetails_filter", 0);
	if (svp != NULL)
		unpack_UA_EventFilter(&out->filter, *svp);

	return;
}
#endif

/* ReadProcessedDetails */
#ifdef UA_TYPES_READPROCESSEDDETAILS
static void pack_UA_ReadProcessedDetails(SV *out, const UA_ReadProcessedDetails *in);
static void unpack_UA_ReadProcessedDetails(UA_ReadProcessedDetails *out, SV *in);

static void
pack_UA_ReadProcessedDetails(SV *out, const UA_ReadProcessedDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReadProcessedDetails_startTime", sv);
	pack_UA_DateTime(sv, &in->startTime);

	sv = newSV(0);
	hv_stores(hv, "ReadProcessedDetails_endTime", sv);
	pack_UA_DateTime(sv, &in->endTime);

	sv = newSV(0);
	hv_stores(hv, "ReadProcessedDetails_processingInterval", sv);
	pack_UA_Double(sv, &in->processingInterval);

	av = newAV();
	hv_stores(hv, "ReadProcessedDetails_aggregateType", newRV_noinc((SV*)av));
	av_extend(av, in->aggregateTypeSize);
	for (i = 0; i < in->aggregateTypeSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_NodeId(sv, &in->aggregateType[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ReadProcessedDetails_aggregateConfiguration", sv);
	pack_UA_AggregateConfiguration(sv, &in->aggregateConfiguration);

	return;
}

static void
unpack_UA_ReadProcessedDetails(UA_ReadProcessedDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReadProcessedDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadProcessedDetails_startTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->startTime, *svp);

	svp = hv_fetchs(hv, "ReadProcessedDetails_endTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->endTime, *svp);

	svp = hv_fetchs(hv, "ReadProcessedDetails_processingInterval", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->processingInterval, *svp);

	svp = hv_fetchs(hv, "ReadProcessedDetails_aggregateType", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReadProcessedDetails_aggregateType");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->aggregateType = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out->aggregateType == NULL)
			CROAKE("UA_Array_new");
		out->aggregateTypeSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_NodeId(&out->aggregateType[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ReadProcessedDetails_aggregateConfiguration", 0);
	if (svp != NULL)
		unpack_UA_AggregateConfiguration(&out->aggregateConfiguration, *svp);

	return;
}
#endif

/* ModificationInfo */
#ifdef UA_TYPES_MODIFICATIONINFO
static void pack_UA_ModificationInfo(SV *out, const UA_ModificationInfo *in);
static void unpack_UA_ModificationInfo(UA_ModificationInfo *out, SV *in);

static void
pack_UA_ModificationInfo(SV *out, const UA_ModificationInfo *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ModificationInfo_modificationTime", sv);
	pack_UA_DateTime(sv, &in->modificationTime);

	sv = newSV(0);
	hv_stores(hv, "ModificationInfo_updateType", sv);
	pack_UA_HistoryUpdateType(sv, &in->updateType);

	sv = newSV(0);
	hv_stores(hv, "ModificationInfo_userName", sv);
	pack_UA_String(sv, &in->userName);

	return;
}

static void
unpack_UA_ModificationInfo(UA_ModificationInfo *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ModificationInfo_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModificationInfo_modificationTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->modificationTime, *svp);

	svp = hv_fetchs(hv, "ModificationInfo_updateType", 0);
	if (svp != NULL)
		unpack_UA_HistoryUpdateType(&out->updateType, *svp);

	svp = hv_fetchs(hv, "ModificationInfo_userName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->userName, *svp);

	return;
}
#endif

/* HistoryModifiedData */
#ifdef UA_TYPES_HISTORYMODIFIEDDATA
static void pack_UA_HistoryModifiedData(SV *out, const UA_HistoryModifiedData *in);
static void unpack_UA_HistoryModifiedData(UA_HistoryModifiedData *out, SV *in);

static void
pack_UA_HistoryModifiedData(SV *out, const UA_HistoryModifiedData *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "HistoryModifiedData_dataValues", newRV_noinc((SV*)av));
	av_extend(av, in->dataValuesSize);
	for (i = 0; i < in->dataValuesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DataValue(sv, &in->dataValues[i]);
	}

	av = newAV();
	hv_stores(hv, "HistoryModifiedData_modificationInfos", newRV_noinc((SV*)av));
	av_extend(av, in->modificationInfosSize);
	for (i = 0; i < in->modificationInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ModificationInfo(sv, &in->modificationInfos[i]);
	}

	return;
}

static void
unpack_UA_HistoryModifiedData(UA_HistoryModifiedData *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryModifiedData_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryModifiedData_dataValues", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryModifiedData_dataValues");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataValues = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATAVALUE]);
		if (out->dataValues == NULL)
			CROAKE("UA_Array_new");
		out->dataValuesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DataValue(&out->dataValues[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "HistoryModifiedData_modificationInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryModifiedData_modificationInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->modificationInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MODIFICATIONINFO]);
		if (out->modificationInfos == NULL)
			CROAKE("UA_Array_new");
		out->modificationInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ModificationInfo(&out->modificationInfos[i], *svp);
		}
	}

	return;
}
#endif

/* HistoryEvent */
#ifdef UA_TYPES_HISTORYEVENT
static void pack_UA_HistoryEvent(SV *out, const UA_HistoryEvent *in);
static void unpack_UA_HistoryEvent(UA_HistoryEvent *out, SV *in);

static void
pack_UA_HistoryEvent(SV *out, const UA_HistoryEvent *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "HistoryEvent_events", newRV_noinc((SV*)av));
	av_extend(av, in->eventsSize);
	for (i = 0; i < in->eventsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_HistoryEventFieldList(sv, &in->events[i]);
	}

	return;
}

static void
unpack_UA_HistoryEvent(UA_HistoryEvent *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_HistoryEvent_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "HistoryEvent_events", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for HistoryEvent_events");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->events = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_HISTORYEVENTFIELDLIST]);
		if (out->events == NULL)
			CROAKE("UA_Array_new");
		out->eventsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_HistoryEventFieldList(&out->events[i], *svp);
		}
	}

	return;
}
#endif

/* UpdateEventDetails */
#ifdef UA_TYPES_UPDATEEVENTDETAILS
static void pack_UA_UpdateEventDetails(SV *out, const UA_UpdateEventDetails *in);
static void unpack_UA_UpdateEventDetails(UA_UpdateEventDetails *out, SV *in);

static void
pack_UA_UpdateEventDetails(SV *out, const UA_UpdateEventDetails *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "UpdateEventDetails_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "UpdateEventDetails_performInsertReplace", sv);
	pack_UA_PerformUpdateType(sv, &in->performInsertReplace);

	sv = newSV(0);
	hv_stores(hv, "UpdateEventDetails_filter", sv);
	pack_UA_EventFilter(sv, &in->filter);

	av = newAV();
	hv_stores(hv, "UpdateEventDetails_eventData", newRV_noinc((SV*)av));
	av_extend(av, in->eventDataSize);
	for (i = 0; i < in->eventDataSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_HistoryEventFieldList(sv, &in->eventData[i]);
	}

	return;
}

static void
unpack_UA_UpdateEventDetails(UA_UpdateEventDetails *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UpdateEventDetails_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UpdateEventDetails_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "UpdateEventDetails_performInsertReplace", 0);
	if (svp != NULL)
		unpack_UA_PerformUpdateType(&out->performInsertReplace, *svp);

	svp = hv_fetchs(hv, "UpdateEventDetails_filter", 0);
	if (svp != NULL)
		unpack_UA_EventFilter(&out->filter, *svp);

	svp = hv_fetchs(hv, "UpdateEventDetails_eventData", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UpdateEventDetails_eventData");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->eventData = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_HISTORYEVENTFIELDLIST]);
		if (out->eventData == NULL)
			CROAKE("UA_Array_new");
		out->eventDataSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_HistoryEventFieldList(&out->eventData[i], *svp);
		}
	}

	return;
}
#endif

/* DataChangeNotification */
#ifdef UA_TYPES_DATACHANGENOTIFICATION
static void pack_UA_DataChangeNotification(SV *out, const UA_DataChangeNotification *in);
static void unpack_UA_DataChangeNotification(UA_DataChangeNotification *out, SV *in);

static void
pack_UA_DataChangeNotification(SV *out, const UA_DataChangeNotification *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "DataChangeNotification_monitoredItems", newRV_noinc((SV*)av));
	av_extend(av, in->monitoredItemsSize);
	for (i = 0; i < in->monitoredItemsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_MonitoredItemNotification(sv, &in->monitoredItems[i]);
	}

	av = newAV();
	hv_stores(hv, "DataChangeNotification_diagnosticInfos", newRV_noinc((SV*)av));
	av_extend(av, in->diagnosticInfosSize);
	for (i = 0; i < in->diagnosticInfosSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DiagnosticInfo(sv, &in->diagnosticInfos[i]);
	}

	return;
}

static void
unpack_UA_DataChangeNotification(UA_DataChangeNotification *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataChangeNotification_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataChangeNotification_monitoredItems", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataChangeNotification_monitoredItems");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->monitoredItems = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMNOTIFICATION]);
		if (out->monitoredItems == NULL)
			CROAKE("UA_Array_new");
		out->monitoredItemsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_MonitoredItemNotification(&out->monitoredItems[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataChangeNotification_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataChangeNotification_diagnosticInfos");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out->diagnosticInfos == NULL)
			CROAKE("UA_Array_new");
		out->diagnosticInfosSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DiagnosticInfo(&out->diagnosticInfos[i], *svp);
		}
	}

	return;
}
#endif

/* EventNotificationList */
#ifdef UA_TYPES_EVENTNOTIFICATIONLIST
static void pack_UA_EventNotificationList(SV *out, const UA_EventNotificationList *in);
static void unpack_UA_EventNotificationList(UA_EventNotificationList *out, SV *in);

static void
pack_UA_EventNotificationList(SV *out, const UA_EventNotificationList *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "EventNotificationList_events", newRV_noinc((SV*)av));
	av_extend(av, in->eventsSize);
	for (i = 0; i < in->eventsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EventFieldList(sv, &in->events[i]);
	}

	return;
}

static void
unpack_UA_EventNotificationList(UA_EventNotificationList *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EventNotificationList_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventNotificationList_events", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for EventNotificationList_events");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->events = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EVENTFIELDLIST]);
		if (out->events == NULL)
			CROAKE("UA_Array_new");
		out->eventsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EventFieldList(&out->events[i], *svp);
		}
	}

	return;
}
#endif

/* SessionDiagnosticsDataType */
#ifdef UA_TYPES_SESSIONDIAGNOSTICSDATATYPE
static void pack_UA_SessionDiagnosticsDataType(SV *out, const UA_SessionDiagnosticsDataType *in);
static void unpack_UA_SessionDiagnosticsDataType(UA_SessionDiagnosticsDataType *out, SV *in);

static void
pack_UA_SessionDiagnosticsDataType(SV *out, const UA_SessionDiagnosticsDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_sessionId", sv);
	pack_UA_NodeId(sv, &in->sessionId);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_sessionName", sv);
	pack_UA_String(sv, &in->sessionName);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_clientDescription", sv);
	pack_UA_ApplicationDescription(sv, &in->clientDescription);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_serverUri", sv);
	pack_UA_String(sv, &in->serverUri);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_endpointUrl", sv);
	pack_UA_String(sv, &in->endpointUrl);

	av = newAV();
	hv_stores(hv, "SessionDiagnosticsDataType_localeIds", newRV_noinc((SV*)av));
	av_extend(av, in->localeIdsSize);
	for (i = 0; i < in->localeIdsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->localeIds[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_actualSessionTimeout", sv);
	pack_UA_Double(sv, &in->actualSessionTimeout);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_maxResponseMessageSize", sv);
	pack_UA_UInt32(sv, &in->maxResponseMessageSize);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_clientConnectionTime", sv);
	pack_UA_DateTime(sv, &in->clientConnectionTime);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_clientLastContactTime", sv);
	pack_UA_DateTime(sv, &in->clientLastContactTime);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_currentSubscriptionsCount", sv);
	pack_UA_UInt32(sv, &in->currentSubscriptionsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_currentMonitoredItemsCount", sv);
	pack_UA_UInt32(sv, &in->currentMonitoredItemsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_currentPublishRequestsInQueue", sv);
	pack_UA_UInt32(sv, &in->currentPublishRequestsInQueue);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_totalRequestCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->totalRequestCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_unauthorizedRequestCount", sv);
	pack_UA_UInt32(sv, &in->unauthorizedRequestCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_readCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->readCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_historyReadCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->historyReadCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_writeCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->writeCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_historyUpdateCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->historyUpdateCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_callCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->callCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_createMonitoredItemsCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->createMonitoredItemsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_modifyMonitoredItemsCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->modifyMonitoredItemsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_setMonitoringModeCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->setMonitoringModeCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_setTriggeringCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->setTriggeringCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_deleteMonitoredItemsCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->deleteMonitoredItemsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_createSubscriptionCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->createSubscriptionCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_modifySubscriptionCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->modifySubscriptionCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_setPublishingModeCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->setPublishingModeCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_publishCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->publishCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_republishCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->republishCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_transferSubscriptionsCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->transferSubscriptionsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_deleteSubscriptionsCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->deleteSubscriptionsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_addNodesCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->addNodesCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_addReferencesCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->addReferencesCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_deleteNodesCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->deleteNodesCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_deleteReferencesCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->deleteReferencesCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_browseCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->browseCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_browseNextCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->browseNextCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_translateBrowsePathsToNodeIdsCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->translateBrowsePathsToNodeIdsCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_queryFirstCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->queryFirstCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_queryNextCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->queryNextCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_registerNodesCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->registerNodesCount);

	sv = newSV(0);
	hv_stores(hv, "SessionDiagnosticsDataType_unregisterNodesCount", sv);
	pack_UA_ServiceCounterDataType(sv, &in->unregisterNodesCount);

	return;
}

static void
unpack_UA_SessionDiagnosticsDataType(UA_SessionDiagnosticsDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_SessionDiagnosticsDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_sessionId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->sessionId, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_sessionName", 0);
	if (svp != NULL)
		unpack_UA_String(&out->sessionName, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_clientDescription", 0);
	if (svp != NULL)
		unpack_UA_ApplicationDescription(&out->clientDescription, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_serverUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->serverUri, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_endpointUrl", 0);
	if (svp != NULL)
		unpack_UA_String(&out->endpointUrl, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for SessionDiagnosticsDataType_localeIds");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->localeIds == NULL)
			CROAKE("UA_Array_new");
		out->localeIdsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->localeIds[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_actualSessionTimeout", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->actualSessionTimeout, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_maxResponseMessageSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxResponseMessageSize, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_clientConnectionTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->clientConnectionTime, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_clientLastContactTime", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->clientLastContactTime, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_currentSubscriptionsCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->currentSubscriptionsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_currentMonitoredItemsCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->currentMonitoredItemsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_currentPublishRequestsInQueue", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->currentPublishRequestsInQueue, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_totalRequestCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->totalRequestCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_unauthorizedRequestCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->unauthorizedRequestCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_readCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->readCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_historyReadCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->historyReadCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_writeCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->writeCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_historyUpdateCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->historyUpdateCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_callCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->callCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_createMonitoredItemsCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->createMonitoredItemsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_modifyMonitoredItemsCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->modifyMonitoredItemsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_setMonitoringModeCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->setMonitoringModeCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_setTriggeringCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->setTriggeringCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_deleteMonitoredItemsCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->deleteMonitoredItemsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_createSubscriptionCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->createSubscriptionCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_modifySubscriptionCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->modifySubscriptionCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_setPublishingModeCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->setPublishingModeCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_publishCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->publishCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_republishCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->republishCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_transferSubscriptionsCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->transferSubscriptionsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_deleteSubscriptionsCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->deleteSubscriptionsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_addNodesCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->addNodesCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_addReferencesCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->addReferencesCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_deleteNodesCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->deleteNodesCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_deleteReferencesCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->deleteReferencesCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_browseCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->browseCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_browseNextCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->browseNextCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_translateBrowsePathsToNodeIdsCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->translateBrowsePathsToNodeIdsCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_queryFirstCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->queryFirstCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_queryNextCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->queryNextCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_registerNodesCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->registerNodesCount, *svp);

	svp = hv_fetchs(hv, "SessionDiagnosticsDataType_unregisterNodesCount", 0);
	if (svp != NULL)
		unpack_UA_ServiceCounterDataType(&out->unregisterNodesCount, *svp);

	return;
}
#endif

/* EnumDescription */
#ifdef UA_TYPES_ENUMDESCRIPTION
static void pack_UA_EnumDescription(SV *out, const UA_EnumDescription *in);
static void unpack_UA_EnumDescription(UA_EnumDescription *out, SV *in);

static void
pack_UA_EnumDescription(SV *out, const UA_EnumDescription *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "EnumDescription_dataTypeId", sv);
	pack_UA_NodeId(sv, &in->dataTypeId);

	sv = newSV(0);
	hv_stores(hv, "EnumDescription_name", sv);
	pack_UA_QualifiedName(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "EnumDescription_enumDefinition", sv);
	pack_UA_EnumDefinition(sv, &in->enumDefinition);

	sv = newSV(0);
	hv_stores(hv, "EnumDescription_builtInType", sv);
	pack_UA_Byte(sv, &in->builtInType);

	return;
}

static void
unpack_UA_EnumDescription(UA_EnumDescription *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_EnumDescription_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EnumDescription_dataTypeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->dataTypeId, *svp);

	svp = hv_fetchs(hv, "EnumDescription_name", 0);
	if (svp != NULL)
		unpack_UA_QualifiedName(&out->name, *svp);

	svp = hv_fetchs(hv, "EnumDescription_enumDefinition", 0);
	if (svp != NULL)
		unpack_UA_EnumDefinition(&out->enumDefinition, *svp);

	svp = hv_fetchs(hv, "EnumDescription_builtInType", 0);
	if (svp != NULL)
		unpack_UA_Byte(&out->builtInType, *svp);

	return;
}
#endif

/* UABinaryFileDataType */
#ifdef UA_TYPES_UABINARYFILEDATATYPE
static void pack_UA_UABinaryFileDataType(SV *out, const UA_UABinaryFileDataType *in);
static void unpack_UA_UABinaryFileDataType(UA_UABinaryFileDataType *out, SV *in);

static void
pack_UA_UABinaryFileDataType(SV *out, const UA_UABinaryFileDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "UABinaryFileDataType_namespaces", newRV_noinc((SV*)av));
	av_extend(av, in->namespacesSize);
	for (i = 0; i < in->namespacesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->namespaces[i]);
	}

	av = newAV();
	hv_stores(hv, "UABinaryFileDataType_structureDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->structureDataTypesSize);
	for (i = 0; i < in->structureDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StructureDescription(sv, &in->structureDataTypes[i]);
	}

	av = newAV();
	hv_stores(hv, "UABinaryFileDataType_enumDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->enumDataTypesSize);
	for (i = 0; i < in->enumDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EnumDescription(sv, &in->enumDataTypes[i]);
	}

	av = newAV();
	hv_stores(hv, "UABinaryFileDataType_simpleDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->simpleDataTypesSize);
	for (i = 0; i < in->simpleDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SimpleTypeDescription(sv, &in->simpleDataTypes[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "UABinaryFileDataType_schemaLocation", sv);
	pack_UA_String(sv, &in->schemaLocation);

	av = newAV();
	hv_stores(hv, "UABinaryFileDataType_fileHeader", newRV_noinc((SV*)av));
	av_extend(av, in->fileHeaderSize);
	for (i = 0; i < in->fileHeaderSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->fileHeader[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "UABinaryFileDataType_body", sv);
	pack_UA_Variant(sv, &in->body);

	return;
}

static void
unpack_UA_UABinaryFileDataType(UA_UABinaryFileDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UABinaryFileDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UABinaryFileDataType_namespaces", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UABinaryFileDataType_namespaces");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->namespaces = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->namespaces == NULL)
			CROAKE("UA_Array_new");
		out->namespacesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->namespaces[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "UABinaryFileDataType_structureDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UABinaryFileDataType_structureDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->structureDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRUCTUREDESCRIPTION]);
		if (out->structureDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->structureDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StructureDescription(&out->structureDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "UABinaryFileDataType_enumDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UABinaryFileDataType_enumDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->enumDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENUMDESCRIPTION]);
		if (out->enumDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->enumDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EnumDescription(&out->enumDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "UABinaryFileDataType_simpleDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UABinaryFileDataType_simpleDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->simpleDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIMPLETYPEDESCRIPTION]);
		if (out->simpleDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->simpleDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SimpleTypeDescription(&out->simpleDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "UABinaryFileDataType_schemaLocation", 0);
	if (svp != NULL)
		unpack_UA_String(&out->schemaLocation, *svp);

	svp = hv_fetchs(hv, "UABinaryFileDataType_fileHeader", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for UABinaryFileDataType_fileHeader");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->fileHeader = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->fileHeader == NULL)
			CROAKE("UA_Array_new");
		out->fileHeaderSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->fileHeader[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "UABinaryFileDataType_body", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->body, *svp);

	return;
}
#endif

/* DataSetMetaDataType */
#ifdef UA_TYPES_DATASETMETADATATYPE
static void pack_UA_DataSetMetaDataType(SV *out, const UA_DataSetMetaDataType *in);
static void unpack_UA_DataSetMetaDataType(UA_DataSetMetaDataType *out, SV *in);

static void
pack_UA_DataSetMetaDataType(SV *out, const UA_DataSetMetaDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "DataSetMetaDataType_namespaces", newRV_noinc((SV*)av));
	av_extend(av, in->namespacesSize);
	for (i = 0; i < in->namespacesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->namespaces[i]);
	}

	av = newAV();
	hv_stores(hv, "DataSetMetaDataType_structureDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->structureDataTypesSize);
	for (i = 0; i < in->structureDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StructureDescription(sv, &in->structureDataTypes[i]);
	}

	av = newAV();
	hv_stores(hv, "DataSetMetaDataType_enumDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->enumDataTypesSize);
	for (i = 0; i < in->enumDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EnumDescription(sv, &in->enumDataTypes[i]);
	}

	av = newAV();
	hv_stores(hv, "DataSetMetaDataType_simpleDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->simpleDataTypesSize);
	for (i = 0; i < in->simpleDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SimpleTypeDescription(sv, &in->simpleDataTypes[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "DataSetMetaDataType_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "DataSetMetaDataType_description", sv);
	pack_UA_LocalizedText(sv, &in->description);

	av = newAV();
	hv_stores(hv, "DataSetMetaDataType_fields", newRV_noinc((SV*)av));
	av_extend(av, in->fieldsSize);
	for (i = 0; i < in->fieldsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_FieldMetaData(sv, &in->fields[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "DataSetMetaDataType_dataSetClassId", sv);
	pack_UA_Guid(sv, &in->dataSetClassId);

	sv = newSV(0);
	hv_stores(hv, "DataSetMetaDataType_configurationVersion", sv);
	pack_UA_ConfigurationVersionDataType(sv, &in->configurationVersion);

	return;
}

static void
unpack_UA_DataSetMetaDataType(UA_DataSetMetaDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataSetMetaDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataSetMetaDataType_namespaces", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetMetaDataType_namespaces");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->namespaces = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->namespaces == NULL)
			CROAKE("UA_Array_new");
		out->namespacesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->namespaces[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetMetaDataType_structureDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetMetaDataType_structureDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->structureDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRUCTUREDESCRIPTION]);
		if (out->structureDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->structureDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StructureDescription(&out->structureDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetMetaDataType_enumDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetMetaDataType_enumDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->enumDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENUMDESCRIPTION]);
		if (out->enumDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->enumDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EnumDescription(&out->enumDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetMetaDataType_simpleDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetMetaDataType_simpleDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->simpleDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIMPLETYPEDESCRIPTION]);
		if (out->simpleDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->simpleDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SimpleTypeDescription(&out->simpleDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetMetaDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "DataSetMetaDataType_description", 0);
	if (svp != NULL)
		unpack_UA_LocalizedText(&out->description, *svp);

	svp = hv_fetchs(hv, "DataSetMetaDataType_fields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetMetaDataType_fields");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->fields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_FIELDMETADATA]);
		if (out->fields == NULL)
			CROAKE("UA_Array_new");
		out->fieldsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_FieldMetaData(&out->fields[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetMetaDataType_dataSetClassId", 0);
	if (svp != NULL)
		unpack_UA_Guid(&out->dataSetClassId, *svp);

	svp = hv_fetchs(hv, "DataSetMetaDataType_configurationVersion", 0);
	if (svp != NULL)
		unpack_UA_ConfigurationVersionDataType(&out->configurationVersion, *svp);

	return;
}
#endif

/* PublishedDataSetDataType */
#ifdef UA_TYPES_PUBLISHEDDATASETDATATYPE
static void pack_UA_PublishedDataSetDataType(SV *out, const UA_PublishedDataSetDataType *in);
static void unpack_UA_PublishedDataSetDataType(UA_PublishedDataSetDataType *out, SV *in);

static void
pack_UA_PublishedDataSetDataType(SV *out, const UA_PublishedDataSetDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "PublishedDataSetDataType_name", sv);
	pack_UA_String(sv, &in->name);

	av = newAV();
	hv_stores(hv, "PublishedDataSetDataType_dataSetFolder", newRV_noinc((SV*)av));
	av_extend(av, in->dataSetFolderSize);
	for (i = 0; i < in->dataSetFolderSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->dataSetFolder[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "PublishedDataSetDataType_dataSetMetaData", sv);
	pack_UA_DataSetMetaDataType(sv, &in->dataSetMetaData);

	av = newAV();
	hv_stores(hv, "PublishedDataSetDataType_extensionFields", newRV_noinc((SV*)av));
	av_extend(av, in->extensionFieldsSize);
	for (i = 0; i < in->extensionFieldsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->extensionFields[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "PublishedDataSetDataType_dataSetSource", sv);
	pack_UA_ExtensionObject(sv, &in->dataSetSource);

	return;
}

static void
unpack_UA_PublishedDataSetDataType(UA_PublishedDataSetDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PublishedDataSetDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishedDataSetDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "PublishedDataSetDataType_dataSetFolder", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishedDataSetDataType_dataSetFolder");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataSetFolder = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->dataSetFolder == NULL)
			CROAKE("UA_Array_new");
		out->dataSetFolderSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->dataSetFolder[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PublishedDataSetDataType_dataSetMetaData", 0);
	if (svp != NULL)
		unpack_UA_DataSetMetaDataType(&out->dataSetMetaData, *svp);

	svp = hv_fetchs(hv, "PublishedDataSetDataType_extensionFields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PublishedDataSetDataType_extensionFields");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->extensionFields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->extensionFields == NULL)
			CROAKE("UA_Array_new");
		out->extensionFieldsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->extensionFields[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PublishedDataSetDataType_dataSetSource", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->dataSetSource, *svp);

	return;
}
#endif

/* DataSetReaderDataType */
#ifdef UA_TYPES_DATASETREADERDATATYPE
static void pack_UA_DataSetReaderDataType(SV *out, const UA_DataSetReaderDataType *in);
static void unpack_UA_DataSetReaderDataType(UA_DataSetReaderDataType *out, SV *in);

static void
pack_UA_DataSetReaderDataType(SV *out, const UA_DataSetReaderDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_enabled", sv);
	pack_UA_Boolean(sv, &in->enabled);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_publisherId", sv);
	pack_UA_Variant(sv, &in->publisherId);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_writerGroupId", sv);
	pack_UA_UInt16(sv, &in->writerGroupId);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_dataSetWriterId", sv);
	pack_UA_UInt16(sv, &in->dataSetWriterId);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_dataSetMetaData", sv);
	pack_UA_DataSetMetaDataType(sv, &in->dataSetMetaData);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_dataSetFieldContentMask", sv);
	pack_UA_DataSetFieldContentMask(sv, &in->dataSetFieldContentMask);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_messageReceiveTimeout", sv);
	pack_UA_Double(sv, &in->messageReceiveTimeout);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_keyFrameCount", sv);
	pack_UA_UInt32(sv, &in->keyFrameCount);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_headerLayoutUri", sv);
	pack_UA_String(sv, &in->headerLayoutUri);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_securityGroupId", sv);
	pack_UA_String(sv, &in->securityGroupId);

	av = newAV();
	hv_stores(hv, "DataSetReaderDataType_securityKeyServices", newRV_noinc((SV*)av));
	av_extend(av, in->securityKeyServicesSize);
	for (i = 0; i < in->securityKeyServicesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EndpointDescription(sv, &in->securityKeyServices[i]);
	}

	av = newAV();
	hv_stores(hv, "DataSetReaderDataType_dataSetReaderProperties", newRV_noinc((SV*)av));
	av_extend(av, in->dataSetReaderPropertiesSize);
	for (i = 0; i < in->dataSetReaderPropertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->dataSetReaderProperties[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_transportSettings", sv);
	pack_UA_ExtensionObject(sv, &in->transportSettings);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_messageSettings", sv);
	pack_UA_ExtensionObject(sv, &in->messageSettings);

	sv = newSV(0);
	hv_stores(hv, "DataSetReaderDataType_subscribedDataSet", sv);
	pack_UA_ExtensionObject(sv, &in->subscribedDataSet);

	return;
}

static void
unpack_UA_DataSetReaderDataType(UA_DataSetReaderDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataSetReaderDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataSetReaderDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_enabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->enabled, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_publisherId", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->publisherId, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_writerGroupId", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->writerGroupId, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_dataSetWriterId", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->dataSetWriterId, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_dataSetMetaData", 0);
	if (svp != NULL)
		unpack_UA_DataSetMetaDataType(&out->dataSetMetaData, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_dataSetFieldContentMask", 0);
	if (svp != NULL)
		unpack_UA_DataSetFieldContentMask(&out->dataSetFieldContentMask, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_messageReceiveTimeout", 0);
	if (svp != NULL)
		unpack_UA_Double(&out->messageReceiveTimeout, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_keyFrameCount", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->keyFrameCount, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_headerLayoutUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->headerLayoutUri, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_securityGroupId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityGroupId, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_securityKeyServices", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetReaderDataType_securityKeyServices");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->securityKeyServices = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out->securityKeyServices == NULL)
			CROAKE("UA_Array_new");
		out->securityKeyServicesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EndpointDescription(&out->securityKeyServices[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetReaderDataType_dataSetReaderProperties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataSetReaderDataType_dataSetReaderProperties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataSetReaderProperties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->dataSetReaderProperties == NULL)
			CROAKE("UA_Array_new");
		out->dataSetReaderPropertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->dataSetReaderProperties[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataSetReaderDataType_transportSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->transportSettings, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_messageSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->messageSettings, *svp);

	svp = hv_fetchs(hv, "DataSetReaderDataType_subscribedDataSet", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->subscribedDataSet, *svp);

	return;
}
#endif

/* TargetVariablesDataType */
#ifdef UA_TYPES_TARGETVARIABLESDATATYPE
static void pack_UA_TargetVariablesDataType(SV *out, const UA_TargetVariablesDataType *in);
static void unpack_UA_TargetVariablesDataType(UA_TargetVariablesDataType *out, SV *in);

static void
pack_UA_TargetVariablesDataType(SV *out, const UA_TargetVariablesDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "TargetVariablesDataType_targetVariables", newRV_noinc((SV*)av));
	av_extend(av, in->targetVariablesSize);
	for (i = 0; i < in->targetVariablesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_FieldTargetDataType(sv, &in->targetVariables[i]);
	}

	return;
}

static void
unpack_UA_TargetVariablesDataType(UA_TargetVariablesDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_TargetVariablesDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TargetVariablesDataType_targetVariables", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for TargetVariablesDataType_targetVariables");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->targetVariables = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_FIELDTARGETDATATYPE]);
		if (out->targetVariables == NULL)
			CROAKE("UA_Array_new");
		out->targetVariablesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_FieldTargetDataType(&out->targetVariables[i], *svp);
		}
	}

	return;
}
#endif

/* DataTypeSchemaHeader */
#ifdef UA_TYPES_DATATYPESCHEMAHEADER
static void pack_UA_DataTypeSchemaHeader(SV *out, const UA_DataTypeSchemaHeader *in);
static void unpack_UA_DataTypeSchemaHeader(UA_DataTypeSchemaHeader *out, SV *in);

static void
pack_UA_DataTypeSchemaHeader(SV *out, const UA_DataTypeSchemaHeader *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "DataTypeSchemaHeader_namespaces", newRV_noinc((SV*)av));
	av_extend(av, in->namespacesSize);
	for (i = 0; i < in->namespacesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_String(sv, &in->namespaces[i]);
	}

	av = newAV();
	hv_stores(hv, "DataTypeSchemaHeader_structureDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->structureDataTypesSize);
	for (i = 0; i < in->structureDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_StructureDescription(sv, &in->structureDataTypes[i]);
	}

	av = newAV();
	hv_stores(hv, "DataTypeSchemaHeader_enumDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->enumDataTypesSize);
	for (i = 0; i < in->enumDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EnumDescription(sv, &in->enumDataTypes[i]);
	}

	av = newAV();
	hv_stores(hv, "DataTypeSchemaHeader_simpleDataTypes", newRV_noinc((SV*)av));
	av_extend(av, in->simpleDataTypesSize);
	for (i = 0; i < in->simpleDataTypesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_SimpleTypeDescription(sv, &in->simpleDataTypes[i]);
	}

	return;
}

static void
unpack_UA_DataTypeSchemaHeader(UA_DataTypeSchemaHeader *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataTypeSchemaHeader_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataTypeSchemaHeader_namespaces", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataTypeSchemaHeader_namespaces");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->namespaces = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out->namespaces == NULL)
			CROAKE("UA_Array_new");
		out->namespacesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_String(&out->namespaces[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataTypeSchemaHeader_structureDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataTypeSchemaHeader_structureDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->structureDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRUCTUREDESCRIPTION]);
		if (out->structureDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->structureDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_StructureDescription(&out->structureDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataTypeSchemaHeader_enumDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataTypeSchemaHeader_enumDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->enumDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENUMDESCRIPTION]);
		if (out->enumDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->enumDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EnumDescription(&out->enumDataTypes[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "DataTypeSchemaHeader_simpleDataTypes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for DataTypeSchemaHeader_simpleDataTypes");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->simpleDataTypes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIMPLETYPEDESCRIPTION]);
		if (out->simpleDataTypes == NULL)
			CROAKE("UA_Array_new");
		out->simpleDataTypesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_SimpleTypeDescription(&out->simpleDataTypes[i], *svp);
		}
	}

	return;
}
#endif

/* ReaderGroupDataType */
#ifdef UA_TYPES_READERGROUPDATATYPE
static void pack_UA_ReaderGroupDataType(SV *out, const UA_ReaderGroupDataType *in);
static void unpack_UA_ReaderGroupDataType(UA_ReaderGroupDataType *out, SV *in);

static void
pack_UA_ReaderGroupDataType(SV *out, const UA_ReaderGroupDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ReaderGroupDataType_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "ReaderGroupDataType_enabled", sv);
	pack_UA_Boolean(sv, &in->enabled);

	sv = newSV(0);
	hv_stores(hv, "ReaderGroupDataType_securityMode", sv);
	pack_UA_MessageSecurityMode(sv, &in->securityMode);

	sv = newSV(0);
	hv_stores(hv, "ReaderGroupDataType_securityGroupId", sv);
	pack_UA_String(sv, &in->securityGroupId);

	av = newAV();
	hv_stores(hv, "ReaderGroupDataType_securityKeyServices", newRV_noinc((SV*)av));
	av_extend(av, in->securityKeyServicesSize);
	for (i = 0; i < in->securityKeyServicesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_EndpointDescription(sv, &in->securityKeyServices[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ReaderGroupDataType_maxNetworkMessageSize", sv);
	pack_UA_UInt32(sv, &in->maxNetworkMessageSize);

	av = newAV();
	hv_stores(hv, "ReaderGroupDataType_groupProperties", newRV_noinc((SV*)av));
	av_extend(av, in->groupPropertiesSize);
	for (i = 0; i < in->groupPropertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->groupProperties[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "ReaderGroupDataType_transportSettings", sv);
	pack_UA_ExtensionObject(sv, &in->transportSettings);

	sv = newSV(0);
	hv_stores(hv, "ReaderGroupDataType_messageSettings", sv);
	pack_UA_ExtensionObject(sv, &in->messageSettings);

	av = newAV();
	hv_stores(hv, "ReaderGroupDataType_dataSetReaders", newRV_noinc((SV*)av));
	av_extend(av, in->dataSetReadersSize);
	for (i = 0; i < in->dataSetReadersSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_DataSetReaderDataType(sv, &in->dataSetReaders[i]);
	}

	return;
}

static void
unpack_UA_ReaderGroupDataType(UA_ReaderGroupDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ReaderGroupDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReaderGroupDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "ReaderGroupDataType_enabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->enabled, *svp);

	svp = hv_fetchs(hv, "ReaderGroupDataType_securityMode", 0);
	if (svp != NULL)
		unpack_UA_MessageSecurityMode(&out->securityMode, *svp);

	svp = hv_fetchs(hv, "ReaderGroupDataType_securityGroupId", 0);
	if (svp != NULL)
		unpack_UA_String(&out->securityGroupId, *svp);

	svp = hv_fetchs(hv, "ReaderGroupDataType_securityKeyServices", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReaderGroupDataType_securityKeyServices");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->securityKeyServices = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out->securityKeyServices == NULL)
			CROAKE("UA_Array_new");
		out->securityKeyServicesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_EndpointDescription(&out->securityKeyServices[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ReaderGroupDataType_maxNetworkMessageSize", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->maxNetworkMessageSize, *svp);

	svp = hv_fetchs(hv, "ReaderGroupDataType_groupProperties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReaderGroupDataType_groupProperties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->groupProperties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->groupProperties == NULL)
			CROAKE("UA_Array_new");
		out->groupPropertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->groupProperties[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "ReaderGroupDataType_transportSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->transportSettings, *svp);

	svp = hv_fetchs(hv, "ReaderGroupDataType_messageSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->messageSettings, *svp);

	svp = hv_fetchs(hv, "ReaderGroupDataType_dataSetReaders", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for ReaderGroupDataType_dataSetReaders");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->dataSetReaders = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATASETREADERDATATYPE]);
		if (out->dataSetReaders == NULL)
			CROAKE("UA_Array_new");
		out->dataSetReadersSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_DataSetReaderDataType(&out->dataSetReaders[i], *svp);
		}
	}

	return;
}
#endif

/* PubSubConnectionDataType */
#ifdef UA_TYPES_PUBSUBCONNECTIONDATATYPE
static void pack_UA_PubSubConnectionDataType(SV *out, const UA_PubSubConnectionDataType *in);
static void unpack_UA_PubSubConnectionDataType(UA_PubSubConnectionDataType *out, SV *in);

static void
pack_UA_PubSubConnectionDataType(SV *out, const UA_PubSubConnectionDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "PubSubConnectionDataType_name", sv);
	pack_UA_String(sv, &in->name);

	sv = newSV(0);
	hv_stores(hv, "PubSubConnectionDataType_enabled", sv);
	pack_UA_Boolean(sv, &in->enabled);

	sv = newSV(0);
	hv_stores(hv, "PubSubConnectionDataType_publisherId", sv);
	pack_UA_Variant(sv, &in->publisherId);

	sv = newSV(0);
	hv_stores(hv, "PubSubConnectionDataType_transportProfileUri", sv);
	pack_UA_String(sv, &in->transportProfileUri);

	sv = newSV(0);
	hv_stores(hv, "PubSubConnectionDataType_address", sv);
	pack_UA_ExtensionObject(sv, &in->address);

	av = newAV();
	hv_stores(hv, "PubSubConnectionDataType_connectionProperties", newRV_noinc((SV*)av));
	av_extend(av, in->connectionPropertiesSize);
	for (i = 0; i < in->connectionPropertiesSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_KeyValuePair(sv, &in->connectionProperties[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "PubSubConnectionDataType_transportSettings", sv);
	pack_UA_ExtensionObject(sv, &in->transportSettings);

	av = newAV();
	hv_stores(hv, "PubSubConnectionDataType_writerGroups", newRV_noinc((SV*)av));
	av_extend(av, in->writerGroupsSize);
	for (i = 0; i < in->writerGroupsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_WriterGroupDataType(sv, &in->writerGroups[i]);
	}

	av = newAV();
	hv_stores(hv, "PubSubConnectionDataType_readerGroups", newRV_noinc((SV*)av));
	av_extend(av, in->readerGroupsSize);
	for (i = 0; i < in->readerGroupsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_ReaderGroupDataType(sv, &in->readerGroups[i]);
	}

	return;
}

static void
unpack_UA_PubSubConnectionDataType(UA_PubSubConnectionDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PubSubConnectionDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PubSubConnectionDataType_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);

	svp = hv_fetchs(hv, "PubSubConnectionDataType_enabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->enabled, *svp);

	svp = hv_fetchs(hv, "PubSubConnectionDataType_publisherId", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->publisherId, *svp);

	svp = hv_fetchs(hv, "PubSubConnectionDataType_transportProfileUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->transportProfileUri, *svp);

	svp = hv_fetchs(hv, "PubSubConnectionDataType_address", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->address, *svp);

	svp = hv_fetchs(hv, "PubSubConnectionDataType_connectionProperties", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PubSubConnectionDataType_connectionProperties");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->connectionProperties = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_KEYVALUEPAIR]);
		if (out->connectionProperties == NULL)
			CROAKE("UA_Array_new");
		out->connectionPropertiesSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_KeyValuePair(&out->connectionProperties[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PubSubConnectionDataType_transportSettings", 0);
	if (svp != NULL)
		unpack_UA_ExtensionObject(&out->transportSettings, *svp);

	svp = hv_fetchs(hv, "PubSubConnectionDataType_writerGroups", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PubSubConnectionDataType_writerGroups");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->writerGroups = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_WRITERGROUPDATATYPE]);
		if (out->writerGroups == NULL)
			CROAKE("UA_Array_new");
		out->writerGroupsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_WriterGroupDataType(&out->writerGroups[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PubSubConnectionDataType_readerGroups", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PubSubConnectionDataType_readerGroups");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->readerGroups = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_READERGROUPDATATYPE]);
		if (out->readerGroups == NULL)
			CROAKE("UA_Array_new");
		out->readerGroupsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_ReaderGroupDataType(&out->readerGroups[i], *svp);
		}
	}

	return;
}
#endif

/* PubSubConfigurationDataType */
#ifdef UA_TYPES_PUBSUBCONFIGURATIONDATATYPE
static void pack_UA_PubSubConfigurationDataType(SV *out, const UA_PubSubConfigurationDataType *in);
static void unpack_UA_PubSubConfigurationDataType(UA_PubSubConfigurationDataType *out, SV *in);

static void
pack_UA_PubSubConfigurationDataType(SV *out, const UA_PubSubConfigurationDataType *in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	av = newAV();
	hv_stores(hv, "PubSubConfigurationDataType_publishedDataSets", newRV_noinc((SV*)av));
	av_extend(av, in->publishedDataSetsSize);
	for (i = 0; i < in->publishedDataSetsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_PublishedDataSetDataType(sv, &in->publishedDataSets[i]);
	}

	av = newAV();
	hv_stores(hv, "PubSubConfigurationDataType_connections", newRV_noinc((SV*)av));
	av_extend(av, in->connectionsSize);
	for (i = 0; i < in->connectionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_PubSubConnectionDataType(sv, &in->connections[i]);
	}

	sv = newSV(0);
	hv_stores(hv, "PubSubConfigurationDataType_enabled", sv);
	pack_UA_Boolean(sv, &in->enabled);

	return;
}

static void
unpack_UA_PubSubConfigurationDataType(UA_PubSubConfigurationDataType *out, SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_PubSubConfigurationDataType_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PubSubConfigurationDataType_publishedDataSets", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PubSubConfigurationDataType_publishedDataSets");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->publishedDataSets = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_PUBLISHEDDATASETDATATYPE]);
		if (out->publishedDataSets == NULL)
			CROAKE("UA_Array_new");
		out->publishedDataSetsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_PublishedDataSetDataType(&out->publishedDataSets[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PubSubConfigurationDataType_connections", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
			CROAK("No ARRAY reference for PubSubConfigurationDataType_connections");
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out->connections = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_PUBSUBCONNECTIONDATATYPE]);
		if (out->connections == NULL)
			CROAKE("UA_Array_new");
		out->connectionsSize = top + 1;
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL)
				unpack_UA_PubSubConnectionDataType(&out->connections[i], *svp);
		}
	}

	svp = hv_fetchs(hv, "PubSubConfigurationDataType_enabled", 0);
	if (svp != NULL)
		unpack_UA_Boolean(&out->enabled, *svp);

	return;
}
#endif
