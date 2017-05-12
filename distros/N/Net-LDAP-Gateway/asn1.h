#ifndef ASN1_H_INCLUDED
#define ASN1_H_INCLUDED

#define  ASN1_UNIVERSAL        0x00
#define  ASN1_APPLICATION      0x40
#define  ASN1_CONTEXT_SPECIFIC 0x80
#define  ASN1_PRIVATE          0xc0
#define  ASN1_DOMAIN_MASK      0xc0

#define  ASN1_PRIMITIVE        0x00
#define  ASN1_CONSTRUCTED      0x20
#define  ASN1_TYPE_MASK        0xe0

#define  ASN1_BOOLEAN          0x01
#define  ASN1_INTEGER          0x02
#define  ASN1_OCTET_STRING     0x04
#define  ASN1_ENUMERATED       0x0a
#define  ASN1_SEQUENCE         0x10
#define  ASN1_SET              0x11

#endif
