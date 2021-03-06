/*
 * Generated by asn1c-0.9.23 (http://lionet.info/asn1c)
 * From ASN.1 module "MAP-SS-DataTypes"
 * 	found in "../asn1src/MAP-SS-DataTypes.asn"
 * 	`asn1c -gen-PER -fskeletons-copy -fnative-types`
 */

#include "RegisterCC-EntryArg.h"

static asn_TYPE_member_t asn_MBR_RegisterCC_EntryArg_1[] = {
	{ ATF_NOFLAGS, 0, offsetof(struct RegisterCC_EntryArg, ss_Code),
		(ASN_TAG_CLASS_CONTEXT | (0 << 2)),
		-1,	/* IMPLICIT tag at current level */
		&asn_DEF_SS_Code,
		0,	/* Defer constraints checking to the member type */
		0,	/* No PER visible constraints */
		0,
		"ss-Code"
		},
	{ ATF_POINTER, 1, offsetof(struct RegisterCC_EntryArg, ccbs_Data),
		(ASN_TAG_CLASS_CONTEXT | (1 << 2)),
		-1,	/* IMPLICIT tag at current level */
		&asn_DEF_CCBS_Data,
		0,	/* Defer constraints checking to the member type */
		0,	/* No PER visible constraints */
		0,
		"ccbs-Data"
		},
};
static int asn_MAP_RegisterCC_EntryArg_oms_1[] = { 1 };
static ber_tlv_tag_t asn_DEF_RegisterCC_EntryArg_tags_1[] = {
	(ASN_TAG_CLASS_UNIVERSAL | (16 << 2))
};
static asn_TYPE_tag2member_t asn_MAP_RegisterCC_EntryArg_tag2el_1[] = {
    { (ASN_TAG_CLASS_CONTEXT | (0 << 2)), 0, 0, 0 }, /* ss-Code at 299 */
    { (ASN_TAG_CLASS_CONTEXT | (1 << 2)), 1, 0, 0 } /* ccbs-Data at 300 */
};
static asn_SEQUENCE_specifics_t asn_SPC_RegisterCC_EntryArg_specs_1 = {
	sizeof(struct RegisterCC_EntryArg),
	offsetof(struct RegisterCC_EntryArg, _asn_ctx),
	asn_MAP_RegisterCC_EntryArg_tag2el_1,
	2,	/* Count of tags in the map */
	asn_MAP_RegisterCC_EntryArg_oms_1,	/* Optional members */
	1, 0,	/* Root/Additions */
	1,	/* Start extensions */
	3	/* Stop extensions */
};
asn_TYPE_descriptor_t asn_DEF_RegisterCC_EntryArg = {
	"RegisterCC-EntryArg",
	"RegisterCC-EntryArg",
	SEQUENCE_free,
	SEQUENCE_print,
	SEQUENCE_constraint,
	SEQUENCE_decode_ber,
	SEQUENCE_encode_der,
	SEQUENCE_decode_xer,
	SEQUENCE_encode_xer,
	SEQUENCE_decode_uper,
	SEQUENCE_encode_uper,
	0,	/* Use generic outmost tag fetcher */
	asn_DEF_RegisterCC_EntryArg_tags_1,
	sizeof(asn_DEF_RegisterCC_EntryArg_tags_1)
		/sizeof(asn_DEF_RegisterCC_EntryArg_tags_1[0]), /* 1 */
	asn_DEF_RegisterCC_EntryArg_tags_1,	/* Same as above */
	sizeof(asn_DEF_RegisterCC_EntryArg_tags_1)
		/sizeof(asn_DEF_RegisterCC_EntryArg_tags_1[0]), /* 1 */
	0,	/* No PER visible constraints */
	asn_MBR_RegisterCC_EntryArg_1,
	2,	/* Elements count */
	&asn_SPC_RegisterCC_EntryArg_specs_1	/* Additional specs */
};

