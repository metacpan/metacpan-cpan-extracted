/*
 * pdfmake_x509.c — X.509 certificate parsing implementation
 *
 * Parse X.509 certificates for PDF digital signatures.
 */

#include "pdfmake_x509.h"
#include "pdfmake_asn1.h"
#include "pdfmake_arena.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <time.h>

/*============================================================================
 * Internal helpers
 *==========================================================================*/

/* Base64 decode table */
static const int8_t b64_table[256] = {
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
    52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-2,-1,-1,
    -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
    15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
    -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
    41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
};

/* Decode base64 to binary */
static size_t base64_decode(
    const char *src, size_t src_len,
    uint8_t *dst, size_t dst_len)
{
    size_t out = 0;
    uint32_t accum = 0;
    int bits = 0;
    size_t i;

    for (i = 0; i < src_len && out < dst_len; i++) {
        int8_t val = b64_table[(uint8_t)src[i]];
        if (val == -1) continue;  /* Skip whitespace */
        if (val == -2) break;     /* Padding '=' */
        
        accum = (accum << 6) | val;
        bits += 6;
        
        if (bits >= 8) {
            bits -= 8;
            dst[out++] = (accum >> bits) & 0xFF;
        }
    }
    
    return out;
}

/* Duplicate string to arena */
/* Convert bytes to hex string */
static char *bytes_to_hex(pdfmake_arena_t *arena, const uint8_t *data, size_t len)
{
    char *hex;
    char *p;
    size_t i;

    hex = pdfmake_arena_alloc(arena, len * 3 + 1);  /* "XX:" format */
    if (!hex) return NULL;
    
    p = hex;
    for (i = 0; i < len; i++) {
        if (i > 0) *p++ = ':';
        sprintf(p, "%02X", data[i]);
        p += 2;
    }
    *p = '\0';
    
    return hex;
}

/* Parse signature algorithm OID */
static pdfmake_sig_algorithm_t parse_sig_algorithm(const char *oid)
{
    if (!oid) return PDFMAKE_SIG_UNKNOWN;
    
    if (strcmp(oid, OID_RSA_MD5) == 0) return PDFMAKE_SIG_RSA_MD5;
    if (strcmp(oid, OID_RSA_SHA1) == 0) return PDFMAKE_SIG_RSA_SHA1;
    if (strcmp(oid, OID_RSA_SHA256) == 0) return PDFMAKE_SIG_RSA_SHA256;
    if (strcmp(oid, OID_RSA_SHA384) == 0) return PDFMAKE_SIG_RSA_SHA384;
    if (strcmp(oid, OID_RSA_SHA512) == 0) return PDFMAKE_SIG_RSA_SHA512;
    if (strcmp(oid, OID_ECDSA_SHA256) == 0) return PDFMAKE_SIG_ECDSA_SHA256;
    if (strcmp(oid, OID_ECDSA_SHA384) == 0) return PDFMAKE_SIG_ECDSA_SHA384;
    if (strcmp(oid, OID_ECDSA_SHA512) == 0) return PDFMAKE_SIG_ECDSA_SHA512;
    
    return PDFMAKE_SIG_UNKNOWN;
}

/* Parse X.500 Name (subject/issuer) */
static void parse_name(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *name_node,
    pdfmake_x509_name_t *name)
{
    char dn_buf[1024];
    char *dn_p;
    char *dn_end;
    pdfmake_asn1_node_t *rdn;

    if (!pdfmake_asn1_is_sequence(name_node)) {
        return;
    }
    
    /* Name is SEQUENCE of RDN (RelativeDistinguishedName) */
    /* Each RDN is a SET of AttributeTypeAndValue */
    /* AttributeTypeAndValue is SEQUENCE { type OID, value ANY } */
    
    /* Build DN string while parsing */
    dn_p = dn_buf;
    dn_end = dn_buf + sizeof(dn_buf) - 1;
    
    rdn = name_node->children;
    while (rdn) {
        if (pdfmake_asn1_is_set(rdn)) {
            pdfmake_asn1_node_t *atv = rdn->children;
            while (atv) {
                if (pdfmake_asn1_is_sequence(atv)) {
                    pdfmake_asn1_node_t *oid_node = pdfmake_asn1_child_at(atv, 0);
                    pdfmake_asn1_node_t *val_node = pdfmake_asn1_child_at(atv, 1);
                    
                    if (oid_node && val_node) {
                        char *oid = pdfmake_asn1_get_oid_string(arena, oid_node);
                        char *val = pdfmake_asn1_get_string(arena, val_node);
                        
                        if (oid && val) {
                            const char *attr_name = NULL;
                            char **target = NULL;
                            
                            if (strcmp(oid, OID_COMMON_NAME) == 0) {
                                attr_name = "CN";
                                target = &name->common_name;
                            } else if (strcmp(oid, OID_ORGANIZATION) == 0) {
                                attr_name = "O";
                                target = &name->organization;
                            } else if (strcmp(oid, OID_ORGANIZATIONAL_UNIT) == 0) {
                                attr_name = "OU";
                                target = &name->organizational_unit;
                            } else if (strcmp(oid, OID_COUNTRY) == 0) {
                                attr_name = "C";
                                target = &name->country;
                            } else if (strcmp(oid, OID_STATE) == 0) {
                                attr_name = "ST";
                                target = &name->state;
                            } else if (strcmp(oid, OID_LOCALITY) == 0) {
                                attr_name = "L";
                                target = &name->locality;
                            } else if (strcmp(oid, OID_EMAIL_ADDRESS) == 0) {
                                attr_name = "emailAddress";
                                target = &name->email;
                            } else if (strcmp(oid, OID_SERIAL_NUMBER) == 0) {
                                attr_name = "serialNumber";
                                target = &name->serial_number;
                            }
                            
                            if (target) {
                                *target = val;
                            }
                            
                            /* Append to DN string */
                            if (attr_name && dn_p < dn_end) {
                                if (dn_p > dn_buf) {
                                    dn_p += snprintf(dn_p, dn_end - dn_p, ", ");
                                }
                                dn_p += snprintf(dn_p, dn_end - dn_p, "%s=%s", attr_name, val);
                            }
                        }
                    }
                }
                atv = atv->next;
            }
        }
        rdn = rdn->next;
    }
    
    *dn_p = '\0';
    name->dn = pdfmake_arena_strdup(arena, dn_buf);
}

/* Parse AlgorithmIdentifier */
static char *parse_algorithm_id(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *alg_node)
{
    pdfmake_asn1_node_t *oid_node;

    if (!pdfmake_asn1_is_sequence(alg_node)) {
        return NULL;
    }
    
    oid_node = pdfmake_asn1_child_at(alg_node, 0);
    if (!oid_node) return NULL;
    
    return pdfmake_asn1_get_oid_string(arena, oid_node);
}

/* Parse SubjectPublicKeyInfo */
static void parse_pubkey_info(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *spki,
    pdfmake_pubkey_t *pubkey)
{
    pdfmake_asn1_node_t *alg_node;
    pdfmake_asn1_node_t *key_node;
    pdfmake_asn1_node_t *oid_node;
    char *oid;
    const uint8_t *bits;
    size_t bit_count;
    size_t pos;
    pdfmake_asn1_node_t *rsa_key;
    pdfmake_asn1_node_t *param;

    if (!pdfmake_asn1_is_sequence(spki)) {
        return;
    }
    
    /* SubjectPublicKeyInfo ::= SEQUENCE {
         algorithm AlgorithmIdentifier,
         subjectPublicKey BIT STRING } */
    
    alg_node = pdfmake_asn1_child_at(spki, 0);
    key_node = pdfmake_asn1_child_at(spki, 1);
    
    if (!alg_node || !key_node) return;
    
    /* Store raw for signature verification */
    pubkey->raw = spki->data;
    pubkey->raw_len = spki->length;
    
    /* Parse algorithm OID */
    oid_node = pdfmake_asn1_child_at(alg_node, 0);
    if (!oid_node) return;
    
    oid = pdfmake_asn1_get_oid_string(arena, oid_node);
    if (!oid) return;
    
    if (pdfmake_asn1_get_bit_string(key_node, &bits, &bit_count) != 0) {
        return;
    }
    
    if (strcmp(oid, OID_RSA_ENCRYPTION) == 0) {
        pubkey->algorithm = PDFMAKE_PK_RSA;
        
        /* RSA public key is DER-encoded in the bit string */
        /* RSAPublicKey ::= SEQUENCE { modulus INTEGER, publicExponent INTEGER } */
        pos = 0;
        rsa_key = pdfmake_asn1_parse_element(arena, bits, bit_count / 8, &pos);
        if (pdfmake_asn1_is_sequence(rsa_key)) {
            pdfmake_asn1_node_t *mod = pdfmake_asn1_child_at(rsa_key, 0);
            pdfmake_asn1_node_t *exp = pdfmake_asn1_child_at(rsa_key, 1);
            
            if (mod && exp) {
                pubkey->rsa.modulus = pdfmake_arena_memdup(arena, mod->data, mod->length);
                pubkey->rsa.modulus_len = mod->length;
                pubkey->rsa.exponent = pdfmake_arena_memdup(arena, exp->data, exp->length);
                pubkey->rsa.exponent_len = exp->length;
            }
        }
    } else if (strcmp(oid, OID_EC_PUBLIC_KEY) == 0) {
        pubkey->algorithm = PDFMAKE_PK_ECDSA;
        
        /* Get curve OID from algorithm parameters */
        param = pdfmake_asn1_child_at(alg_node, 1);
        if (param && param->tag == ASN1_TAG_OID) {
            pubkey->ecdsa.curve_oid = pdfmake_asn1_get_oid_string(arena, param);
            
            /* Determine curve size */
            if (pdfmake_asn1_oid_equals(param, OID_SECP256R1)) {
                pubkey->ecdsa.curve_bits = 256;
            } else if (pdfmake_asn1_oid_equals(param, OID_SECP384R1)) {
                pubkey->ecdsa.curve_bits = 384;
            } else if (pdfmake_asn1_oid_equals(param, OID_SECP521R1)) {
                pubkey->ecdsa.curve_bits = 521;
            }
        }
        
        /* EC point is the bit string content */
        pubkey->ecdsa.point = pdfmake_arena_memdup(arena, bits, bit_count / 8);
        pubkey->ecdsa.point_len = bit_count / 8;
    }
}

/* Parse extension value */
static void parse_extension(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *ext,
    pdfmake_x509_cert_t *cert)
{
    pdfmake_asn1_node_t *oid_node;
    pdfmake_asn1_node_t *value_node = NULL;
    pdfmake_asn1_node_t *child;
    size_t pos;
    pdfmake_asn1_node_t *ext_value;

    /* Extension ::= SEQUENCE { extnID OID, critical BOOLEAN DEFAULT FALSE, extnValue OCTET STRING } */
    
    oid_node = pdfmake_asn1_child_at(ext, 0);
    if (!oid_node) return;
    
    /* Find the extension value (OCTET STRING, may be preceded by critical BOOLEAN) */
    child = oid_node->next;
    while (child) {
        if (child->tag == ASN1_TAG_OCTET_STRING) {
            value_node = child;
            break;
        }
        child = child->next;
    }
    if (!value_node) return;
    
    /* Parse the OCTET STRING content as ASN.1 */
    pos = 0;
    ext_value = pdfmake_asn1_parse_element(arena, value_node->data, value_node->length, &pos);
    if (!ext_value) return;
    
    /* Basic Constraints */
    if (pdfmake_asn1_oid_equals(oid_node, OID_BASIC_CONSTRAINTS)) {
        /* BasicConstraints ::= SEQUENCE { cA BOOLEAN DEFAULT FALSE, pathLenConstraint INTEGER OPTIONAL } */
        cert->path_len_constraint = -1;
        if (pdfmake_asn1_is_sequence(ext_value)) {
            pdfmake_asn1_node_t *ca_node = pdfmake_asn1_find_tag(ext_value, ASN1_TAG_BOOLEAN);
            pdfmake_asn1_node_t *path_node = pdfmake_asn1_find_tag(ext_value, ASN1_TAG_INTEGER);
            
            if (ca_node) {
                int is_ca;
                if (pdfmake_asn1_get_bool(ca_node, &is_ca) == 0) {
                    cert->is_ca = is_ca;
                }
            }
            if (path_node) {
                int64_t path_len;
                if (pdfmake_asn1_get_int64(path_node, &path_len) == 0) {
                    cert->path_len_constraint = (int)path_len;
                }
            }
        }
    }
    /* Key Usage */
    else if (pdfmake_asn1_oid_equals(oid_node, OID_KEY_USAGE)) {
        /* KeyUsage ::= BIT STRING */
        if (ext_value->tag == ASN1_TAG_BIT_STRING) {
            const uint8_t *bits;
            size_t bit_count;
            if (pdfmake_asn1_get_bit_string(ext_value, &bits, &bit_count) == 0 && bit_count > 0) {
                /* Key usage bits are in order from MSB */
                uint16_t ku = 0;
                if (bit_count > 0) ku |= (bits[0] & 0x80) ? PDFMAKE_KU_DIGITAL_SIGNATURE : 0;
                if (bit_count > 1) ku |= (bits[0] & 0x40) ? PDFMAKE_KU_NON_REPUDIATION : 0;
                if (bit_count > 2) ku |= (bits[0] & 0x20) ? PDFMAKE_KU_KEY_ENCIPHERMENT : 0;
                if (bit_count > 3) ku |= (bits[0] & 0x10) ? PDFMAKE_KU_DATA_ENCIPHERMENT : 0;
                if (bit_count > 4) ku |= (bits[0] & 0x08) ? PDFMAKE_KU_KEY_AGREEMENT : 0;
                if (bit_count > 5) ku |= (bits[0] & 0x04) ? PDFMAKE_KU_KEY_CERT_SIGN : 0;
                if (bit_count > 6) ku |= (bits[0] & 0x02) ? PDFMAKE_KU_CRL_SIGN : 0;
                if (bit_count > 7) ku |= (bits[0] & 0x01) ? PDFMAKE_KU_ENCIPHER_ONLY : 0;
                cert->key_usage = ku;
            }
        }
    }
    /* Extended Key Usage */
    else if (pdfmake_asn1_oid_equals(oid_node, OID_EXT_KEY_USAGE)) {
        /* ExtKeyUsageSyntax ::= SEQUENCE OF KeyPurposeId */
        if (pdfmake_asn1_is_sequence(ext_value)) {
            pdfmake_asn1_node_t *eku = ext_value->children;
            while (eku) {
                if (eku->tag == ASN1_TAG_OID) {
                    if (pdfmake_asn1_oid_equals(eku, OID_EKU_SERVER_AUTH)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_SERVER_AUTH;
                    } else if (pdfmake_asn1_oid_equals(eku, OID_EKU_CLIENT_AUTH)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_CLIENT_AUTH;
                    } else if (pdfmake_asn1_oid_equals(eku, OID_EKU_CODE_SIGNING)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_CODE_SIGNING;
                    } else if (pdfmake_asn1_oid_equals(eku, OID_EKU_EMAIL_PROTECTION)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_EMAIL_PROTECTION;
                    } else if (pdfmake_asn1_oid_equals(eku, OID_EKU_TIME_STAMPING)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_TIME_STAMPING;
                    } else if (pdfmake_asn1_oid_equals(eku, OID_EKU_OCSP_SIGNING)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_OCSP_SIGNING;
                    } else if (pdfmake_asn1_oid_equals(eku, OID_EKU_PDF_SIGNING)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_PDF_SIGNING;
                    } else if (pdfmake_asn1_oid_equals(eku, OID_EKU_DOCUMENT_SIGNING)) {
                        cert->ext_key_usage |= PDFMAKE_EKU_DOCUMENT_SIGNING;
                    }
                }
                eku = eku->next;
            }
        }
    }
    /* Subject Key Identifier */
    else if (pdfmake_asn1_oid_equals(oid_node, OID_SUBJECT_KEY_ID)) {
        /* SubjectKeyIdentifier ::= OCTET STRING */
        if (ext_value->tag == ASN1_TAG_OCTET_STRING) {
            cert->subject_key_id = pdfmake_arena_memdup(arena, ext_value->data, ext_value->length);
            cert->subject_key_id_len = ext_value->length;
        }
    }
    /* Authority Key Identifier */
    else if (pdfmake_asn1_oid_equals(oid_node, OID_AUTHORITY_KEY_ID)) {
        /* AuthorityKeyIdentifier ::= SEQUENCE { keyIdentifier [0] IMPLICIT OCTET STRING OPTIONAL, ... } */
        if (pdfmake_asn1_is_sequence(ext_value)) {
            pdfmake_asn1_node_t *kid = ext_value->children;
            while (kid) {
                if ((kid->tag & 0x1F) == 0 && (kid->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT) {
                    /* [0] keyIdentifier */
                    cert->authority_key_id = pdfmake_arena_memdup(arena, kid->data, kid->length);
                    cert->authority_key_id_len = kid->length;
                    break;
                }
                kid = kid->next;
            }
        }
    }
    /* Authority Info Access */
    else if (pdfmake_asn1_oid_equals(oid_node, OID_AUTHORITY_INFO_ACCESS)) {
        /* AuthorityInfoAccessSyntax ::= SEQUENCE OF AccessDescription
           AccessDescription ::= SEQUENCE { accessMethod OID, accessLocation GeneralName } */
        if (pdfmake_asn1_is_sequence(ext_value)) {
            pdfmake_asn1_node_t *ad = ext_value->children;
            while (ad) {
                if (pdfmake_asn1_is_sequence(ad)) {
                    pdfmake_asn1_node_t *method = pdfmake_asn1_child_at(ad, 0);
                    pdfmake_asn1_node_t *location = pdfmake_asn1_child_at(ad, 1);
                    
                    if (method && location && pdfmake_asn1_oid_equals(method, OID_OCSP)) {
                        /* OCSP responder URL in [6] uniformResourceIdentifier */
                        if ((location->tag & 0x1F) == 6 && 
                            (location->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT) {
                            char *url = pdfmake_arena_alloc(arena, location->length + 1);
                            if (url) {
                                memcpy(url, location->data, location->length);
                                url[location->length] = '\0';
                                cert->ocsp_responder = url;
                            }
                        }
                    }
                }
                ad = ad->next;
            }
        }
    }
    /* CRL Distribution Points */
    else if (pdfmake_asn1_oid_equals(oid_node, OID_CRL_DISTRIBUTION)) {
        /* CRLDistributionPoints ::= SEQUENCE OF DistributionPoint */
        if (pdfmake_asn1_is_sequence(ext_value)) {
            pdfmake_asn1_node_t *dp = ext_value->children;
            while (dp && !cert->crl_distribution) {
                if (pdfmake_asn1_is_sequence(dp)) {
                    /* DistributionPoint has [0] distributionPoint CHOICE */
                    pdfmake_asn1_node_t *dpname = dp->children;
                    while (dpname && !cert->crl_distribution) {
                        if ((dpname->tag & 0x1F) == 0 && 
                            (dpname->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT &&
                            (dpname->tag & ASN1_CONSTRUCTED)) {
                            /* [0] fullName GeneralNames */
                            pdfmake_asn1_node_t *gn = dpname->children;
                            while (gn && !cert->crl_distribution) {
                                /* GeneralName: [6] uniformResourceIdentifier */
                                if ((gn->tag & 0x1F) == 6 && 
                                    (gn->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT) {
                                    char *url = pdfmake_arena_alloc(arena, gn->length + 1);
                                    if (url) {
                                        memcpy(url, gn->data, gn->length);
                                        url[gn->length] = '\0';
                                        cert->crl_distribution = url;
                                    }
                                }
                                gn = gn->next;
                            }
                        }
                        dpname = dpname->next;
                    }
                }
                dp = dp->next;
            }
        }
    }
}

/* Parse extensions */
static void parse_extensions(
    pdfmake_arena_t *arena,
    const pdfmake_asn1_node_t *extensions,
    pdfmake_x509_cert_t *cert)
{
    pdfmake_asn1_node_t *ext;

    if (!extensions) return;
    
    /* Extensions is SEQUENCE of Extension */
    ext = extensions->children;
    while (ext) {
        if (pdfmake_asn1_is_sequence(ext)) {
            parse_extension(arena, ext, cert);
        }
        ext = ext->next;
    }
}

/*============================================================================
 * Public API
 *==========================================================================*/

pdfmake_x509_cert_t *pdfmake_x509_parse_der(
    pdfmake_arena_t *arena,
    const uint8_t *der,
    size_t len)
{
    pdfmake_asn1_node_t *root;
    pdfmake_asn1_node_t *tbs;
    pdfmake_asn1_node_t *sig_alg;
    pdfmake_asn1_node_t *sig_val;
    pdfmake_x509_cert_t *cert;
    size_t tbs_offset;
    const uint8_t *sig_bits;
    size_t sig_bit_count;
    pdfmake_asn1_node_t *field;

    if (!arena || !der || len == 0) return NULL;
    
    /* Parse the certificate ASN.1 */
    root = pdfmake_asn1_parse(arena, der, len);
    if (!pdfmake_asn1_is_sequence(root)) {
        return NULL;
    }
    
    /* Certificate ::= SEQUENCE {
         tbsCertificate TBSCertificate,
         signatureAlgorithm AlgorithmIdentifier,
         signatureValue BIT STRING } */
    
    tbs = pdfmake_asn1_child_at(root, 0);
    sig_alg = pdfmake_asn1_child_at(root, 1);
    sig_val = pdfmake_asn1_child_at(root, 2);
    
    if (!tbs || !sig_alg || !sig_val) {
        return NULL;
    }
    
    /* Allocate certificate */
    cert = pdfmake_arena_alloc(arena, sizeof(pdfmake_x509_cert_t));
    if (!cert) return NULL;
    memset(cert, 0, sizeof(pdfmake_x509_cert_t));
    
    cert->arena = arena;
    cert->der = der;
    cert->der_len = len;
    cert->path_len_constraint = -1;
    
    /* Store TBS certificate for signature verification */
    /* We need to find the raw bytes of the TBS certificate */
    cert->tbs_certificate = tbs->data - 1;  /* Include tag byte (approximate) */
    cert->tbs_certificate_len = tbs->length + 2 + (tbs->length < 0x80 ? 0 : 
                                                   tbs->length < 0x100 ? 1 : 
                                                   tbs->length < 0x10000 ? 2 : 3);
    
    /* Actually, we need to recalculate properly - get offset from start */
    /* For now, use the first child's data pointer minus some offset */
    tbs_offset = (tbs->children ? tbs->children->data : tbs->data) - der;
    /* Back up to find the SEQUENCE tag */
    while (tbs_offset > 0 && der[tbs_offset - 1] != (ASN1_TAG_SEQUENCE | ASN1_CONSTRUCTED)) {
        tbs_offset--;
    }
    if (tbs_offset > 0) tbs_offset--;
    cert->tbs_certificate = der + tbs_offset;
    /* Find length by looking at sig_alg position */
    cert->tbs_certificate_len = (sig_alg->data - cert->tbs_certificate - 1);
    
    /* Parse signature algorithm */
    cert->sig_algorithm_oid = parse_algorithm_id(arena, sig_alg);
    cert->sig_algorithm = parse_sig_algorithm(cert->sig_algorithm_oid);
    
    /* Parse signature value */
    if (pdfmake_asn1_get_bit_string(sig_val, &sig_bits, &sig_bit_count) == 0) {
        cert->signature = sig_bits;
        cert->signature_len = sig_bit_count / 8;
    }
    
    /* Parse TBSCertificate */
    /* TBSCertificate ::= SEQUENCE {
         version [0] EXPLICIT Version DEFAULT v1,
         serialNumber CertificateSerialNumber,
         signature AlgorithmIdentifier,
         issuer Name,
         validity Validity,
         subject Name,
         subjectPublicKeyInfo SubjectPublicKeyInfo,
         ... extensions [3] EXPLICIT Extensions OPTIONAL } */
    
    if (!pdfmake_asn1_is_sequence(tbs)) {
        return NULL;
    }
    
    field = tbs->children;
    
    /* Version (optional, [0] EXPLICIT) */
    if (field && (field->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT && 
        (field->tag & 0x1F) == 0) {
        pdfmake_asn1_node_t *ver = field->children;
        if (ver) {
            int64_t v;
            if (pdfmake_asn1_get_int64(ver, &v) == 0) {
                cert->version = (int)v;
            }
        }
        field = field->next;
    }
    
    /* Serial number */
    if (field && field->tag == ASN1_TAG_INTEGER) {
        cert->serial = pdfmake_arena_memdup(arena, field->data, field->length);
        cert->serial_len = field->length;
        cert->serial_hex = bytes_to_hex(arena, field->data, field->length);
        field = field->next;
    }
    
    /* Signature algorithm (skip, same as outer) */
    if (field) {
        field = field->next;
    }
    
    /* Issuer */
    if (field) {
        parse_name(arena, field, &cert->issuer);
        field = field->next;
    }
    
    /* Validity */
    if (pdfmake_asn1_is_sequence(field)) {
        pdfmake_asn1_node_t *not_before = pdfmake_asn1_child_at(field, 0);
        pdfmake_asn1_node_t *not_after = pdfmake_asn1_child_at(field, 1);
        
        if (not_before) pdfmake_asn1_get_time(not_before, &cert->not_before);
        if (not_after) pdfmake_asn1_get_time(not_after, &cert->not_after);
        
        field = field->next;
    }
    
    /* Subject */
    if (field) {
        parse_name(arena, field, &cert->subject);
        field = field->next;
    }
    
    /* Subject Public Key Info */
    if (field) {
        parse_pubkey_info(arena, field, &cert->pubkey);
        field = field->next;
    }
    
    /* Skip issuerUniqueID [1] and subjectUniqueID [2] if present */
    while (field && (field->tag & ASN1_CLASS_MASK) == ASN1_CLASS_CONTEXT) {
        if ((field->tag & 0x1F) == 3) {
            /* Extensions [3] */
            if (field->children) {
                parse_extensions(arena, field->children, cert);
            }
        }
        field = field->next;
    }
    
    /* Check if self-signed */
    if (cert->issuer.dn && cert->subject.dn && 
        strcmp(cert->issuer.dn, cert->subject.dn) == 0) {
        cert->is_self_signed = 1;
    }
    
    return cert;
}

pdfmake_x509_cert_t *pdfmake_x509_parse_pem(
    pdfmake_arena_t *arena,
    const char *pem,
    size_t len)
{
    const char *begin;
    const char *end;
    size_t b64_len;
    size_t max_der_len;
    uint8_t *der;
    size_t der_len;

    if (!arena || !pem || len == 0) return NULL;
    
    /* Find BEGIN marker */
    begin = strstr(pem, "-----BEGIN CERTIFICATE-----");
    if (!begin) return NULL;
    begin += 27;  /* Skip marker */
    
    /* Find END marker */
    end = strstr(begin, "-----END CERTIFICATE-----");
    if (!end) return NULL;
    
    /* Allocate buffer for decoded data */
    b64_len = end - begin;
    max_der_len = (b64_len * 3) / 4 + 4;
    der = pdfmake_arena_alloc(arena, max_der_len);
    if (!der) return NULL;
    
    /* Decode base64 */
    der_len = base64_decode(begin, b64_len, der, max_der_len);
    if (der_len == 0) return NULL;
    
    return pdfmake_x509_parse_der(arena, der, der_len);
}

pdfmake_cert_chain_t *pdfmake_x509_parse_pem_chain(
    pdfmake_arena_t *arena,
    const char *pem,
    size_t len)
{
    pdfmake_cert_chain_t *chain;
    const char *p;
    const char *end;
    pdfmake_x509_cert_t *last;
    const char *begin;
    const char *cert_end;
    pdfmake_x509_cert_t *cert;

    if (!arena || !pem || len == 0) return NULL;
    
    chain = pdfmake_arena_alloc(arena, sizeof(pdfmake_cert_chain_t));
    if (!chain) return NULL;
    memset(chain, 0, sizeof(pdfmake_cert_chain_t));
    chain->arena = arena;
    
    p = pem;
    end = pem + len;
    last = NULL;
    
    while (p < end) {
        begin = strstr(p, "-----BEGIN CERTIFICATE-----");
        if (!begin || begin >= end) break;
        
        cert_end = strstr(begin, "-----END CERTIFICATE-----");
        if (!cert_end || cert_end >= end) break;
        cert_end += 25;  /* Include end marker */
        
        cert = pdfmake_x509_parse_pem(arena, begin, cert_end - begin);
        if (cert) {
            if (last) {
                last->next = cert;
            } else {
                chain->certs = cert;
            }
            last = cert;
            chain->count++;
        }
        
        p = cert_end;
    }
    
    return chain;
}

pdfmake_x509_cert_t *pdfmake_x509_load_file(
    pdfmake_arena_t *arena,
    const char *path)
{
    FILE *f;
    long size;
    uint8_t *data;

    if (!arena || !path) return NULL;
    
    f = fopen(path, "rb");
    if (!f) return NULL;
    
    /* Get file size */
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (size <= 0 || size > 1024 * 1024) {  /* Max 1MB */
        fclose(f);
        return NULL;
    }
    
    /* Read file */
    data = pdfmake_arena_alloc(arena, size);
    if (!data) {
        fclose(f);
        return NULL;
    }
    
    if (fread(data, 1, size, f) != (size_t)size) {
        fclose(f);
        return NULL;
    }
    fclose(f);
    
    /* Check for PEM format */
    if (size > 27 && memcmp(data, "-----BEGIN", 10) == 0) {
        return pdfmake_x509_parse_pem(arena, (const char *)data, size);
    }
    
    /* Assume DER */
    return pdfmake_x509_parse_der(arena, data, size);
}

int pdfmake_x509_is_valid(
    const pdfmake_x509_cert_t *cert,
    int64_t check_time)
{
    if (!cert) return 0;
    
    if (check_time == 0) {
        check_time = time(NULL);
    }
    
    return (check_time >= cert->not_before && check_time <= cert->not_after);
}

int pdfmake_x509_can_sign_documents(const pdfmake_x509_cert_t *cert)
{
    if (!cert) return 0;
    
    /* Check key usage if present */
    if (cert->key_usage != 0) {
        /* Need digitalSignature or nonRepudiation */
        if (!(cert->key_usage & (PDFMAKE_KU_DIGITAL_SIGNATURE | PDFMAKE_KU_NON_REPUDIATION))) {
            return 0;
        }
    }
    
    /* Check extended key usage if present */
    if (cert->ext_key_usage != 0) {
        /* Need one of: document signing, PDF signing, email protection, or code signing */
        uint32_t signing_ekus = PDFMAKE_EKU_DOCUMENT_SIGNING | PDFMAKE_EKU_PDF_SIGNING |
                               PDFMAKE_EKU_EMAIL_PROTECTION | PDFMAKE_EKU_CODE_SIGNING;
        if (!(cert->ext_key_usage & signing_ekus)) {
            return 0;
        }
    }
    
    return 1;
}

char *pdfmake_x509_format_name(
    pdfmake_arena_t *arena,
    const pdfmake_x509_name_t *name)
{
    char buf[512];
    char *p;
    char *end;

    if (!arena || !name) return NULL;
    
    /* Already have DN string */
    if (name->dn) {
        return pdfmake_arena_strdup(arena, name->dn);
    }
    
    /* Build from components */
    p = buf;
    end = buf + sizeof(buf) - 1;
    
    if (name->common_name) {
        p += snprintf(p, end - p, "CN=%s", name->common_name);
    }
    if (name->organization && p < end) {
        if (p > buf) p += snprintf(p, end - p, ", ");
        p += snprintf(p, end - p, "O=%s", name->organization);
    }
    if (name->organizational_unit && p < end) {
        if (p > buf) p += snprintf(p, end - p, ", ");
        p += snprintf(p, end - p, "OU=%s", name->organizational_unit);
    }
    if (name->locality && p < end) {
        if (p > buf) p += snprintf(p, end - p, ", ");
        p += snprintf(p, end - p, "L=%s", name->locality);
    }
    if (name->state && p < end) {
        if (p > buf) p += snprintf(p, end - p, ", ");
        p += snprintf(p, end - p, "ST=%s", name->state);
    }
    if (name->country && p < end) {
        if (p > buf) p += snprintf(p, end - p, ", ");
        p += snprintf(p, end - p, "C=%s", name->country);
    }
    
    *p = '\0';
    return pdfmake_arena_strdup(arena, buf);
}

const char *pdfmake_x509_sig_algorithm_name(pdfmake_sig_algorithm_t alg)
{
    switch (alg) {
        case PDFMAKE_SIG_RSA_MD5:      return "RSA-MD5";
        case PDFMAKE_SIG_RSA_SHA1:     return "RSA-SHA1";
        case PDFMAKE_SIG_RSA_SHA256:   return "RSA-SHA256";
        case PDFMAKE_SIG_RSA_SHA384:   return "RSA-SHA384";
        case PDFMAKE_SIG_RSA_SHA512:   return "RSA-SHA512";
        case PDFMAKE_SIG_ECDSA_SHA256: return "ECDSA-SHA256";
        case PDFMAKE_SIG_ECDSA_SHA384: return "ECDSA-SHA384";
        case PDFMAKE_SIG_ECDSA_SHA512: return "ECDSA-SHA512";
        case PDFMAKE_SIG_ED25519:      return "Ed25519";
        case PDFMAKE_SIG_ED448:        return "Ed448";
        default:                       return "Unknown";
    }
}

const char *pdfmake_x509_pk_algorithm_name(pdfmake_pk_algorithm_t alg)
{
    switch (alg) {
        case PDFMAKE_PK_RSA:     return "RSA";
        case PDFMAKE_PK_DSA:     return "DSA";
        case PDFMAKE_PK_ECDSA:   return "ECDSA";
        case PDFMAKE_PK_ED25519: return "Ed25519";
        case PDFMAKE_PK_ED448:   return "Ed448";
        default:                 return "Unknown";
    }
}

pdfmake_err_t pdfmake_x509_verify_signature(
    const pdfmake_x509_cert_t *cert,
    const pdfmake_x509_cert_t *issuer)
{
    /* TODO: Implement actual cryptographic verification */
    /* This requires RSA/ECDSA signature verification with the issuer's public key */
    /* For now, just return success for self-signed certs with matching issuer/subject */
    
    if (!cert) return PDFMAKE_EINVAL;
    
    if (!issuer && cert->is_self_signed) {
        /* Self-signed certificate - would verify with own public key */
        return PDFMAKE_OK;
    }
    
    if (issuer) {
        /* Would verify cert->signature against cert->tbs_certificate
         * using issuer->pubkey */
        return PDFMAKE_OK;
    }
    
    return PDFMAKE_EINVAL;
}

pdfmake_err_t pdfmake_x509_verify_chain(
    const pdfmake_cert_chain_t *chain,
    const pdfmake_cert_chain_t *trust_anchors)
{
    pdfmake_x509_cert_t *cert;

    /* TODO: Implement full chain verification */
    /* 1. Verify each cert is signed by the next in chain */
    /* 2. Verify the last cert is in trust_anchors or is self-signed */
    /* 3. Check validity periods */
    /* 4. Check basic constraints (CA flag) */
    
    if (!chain || chain->count == 0) return PDFMAKE_EINVAL;
    (void)trust_anchors;
    
    /* For now, basic validity check */
    cert = chain->certs;
    while (cert) {
        if (!pdfmake_x509_is_valid(cert, 0)) {
            return PDFMAKE_EINVAL;  /* Certificate expired */
        }
        cert = cert->next;
    }
    
    return PDFMAKE_OK;
}

void pdfmake_x509_cert_free(pdfmake_x509_cert_t *cert)
{
    /* If allocated from arena, arena cleanup handles this */
    (void)cert;
}

void pdfmake_cert_chain_free(pdfmake_cert_chain_t *chain)
{
    /* If allocated from arena, arena cleanup handles this */
    (void)chain;
}
