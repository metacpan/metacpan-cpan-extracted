/*
 * Generated by asn1c-0.9.23 (http://lionet.info/asn1c)
 * From ASN.1 module "MAP-MS-DataTypes"
 * 	found in "../asn1src/MAP-MS-DataTypes.asn"
 * 	`asn1c -gen-PER -fskeletons-copy -fnative-types`
 */

#ifndef	_EctData_H_
#define	_EctData_H_


#include <asn_application.h>

/* Including external dependencies */
#include "Ext-SS-Status.h"
#include <NULL.h>
#include <constr_SEQUENCE.h>

#ifdef __cplusplus
extern "C" {
#endif

/* EctData */
typedef struct EctData {
	Ext_SS_Status_t	 ss_Status;
	NULL_t	*notificationToCSE	/* OPTIONAL */;
	/*
	 * This type is extensible,
	 * possible extensions are below.
	 */
	
	/* Context for parsing across buffer boundaries */
	asn_struct_ctx_t _asn_ctx;
} EctData_t;

/* Implementation */
extern asn_TYPE_descriptor_t asn_DEF_EctData;

#ifdef __cplusplus
}
#endif

#endif	/* _EctData_H_ */
#include <asn_internal.h>
