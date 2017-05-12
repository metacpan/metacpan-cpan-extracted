#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include <nspr.h>
#include <nss.h>
#include <nssb64.h>
#include <secder.h>
#include <secmod.h>
#include <cert.h>
#include <prerror.h>
#include <unistd.h>

typedef CERTCertificate* Panda__NSS__Cert;

static const char NS_CERT_HEADER[]  = "-----BEGIN CERTIFICATE-----";
static const char NS_CERT_TRAILER[] = "-----END CERTIFICATE-----";
#define NS_CERT_HEADER_LEN  ((sizeof NS_CERT_HEADER) - 1)
#define NS_CERT_TRAILER_LEN ((sizeof NS_CERT_TRAILER) - 1)

static pid_t saved_pid = 0;

static
void
PNSS_croak() {
    PRErrorCode code = PR_GetError();
    const char* msg = PR_ErrorToString(code, PR_LANGUAGE_I_DEFAULT);
    SV* sv = newSVpv(msg, 0);
    croak_sv(sv_2mortal(sv));
}

MODULE = Panda::NSS     PACKAGE = Panda::NSS
PROTOTYPES: DISABLE

BOOT:
    HV *stash = gv_stashpv("Panda::NSS", GV_ADD);

    newCONSTSUB(stash, "CERTIFICATE_USAGE_CHECK_ALL_USAGES", newSViv(certificateUsageCheckAllUsages));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_CLIENT", newSViv(certificateUsageSSLClient));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_SERVER", newSViv(certificateUsageSSLServer));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_SERVER_WITH_STEP_UP", newSViv(certificateUsageSSLServerWithStepUp));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_CA", newSViv(certificateUsageSSLCA));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_EMAIL_SIGNER", newSViv(certificateUsageEmailSigner));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_EMAIL_RECIPIENT", newSViv(certificateUsageEmailRecipient));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_OBJECT_SIGNER", newSViv(certificateUsageObjectSigner));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_USER_CERT_IMPORT", newSViv(certificateUsageUserCertImport));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_VERIFY_CA", newSViv(certificateUsageVerifyCA));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_PROTECTED_OBJECT_SIGNER", newSViv(certificateUsageProtectedObjectSigner));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_STATUS_RESPONDER", newSViv(certificateUsageStatusResponder));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_ANY_CA", newSViv(certificateUsageAnyCA));

void
init(const char* configdir = NULL)
  CODE:
    if (!NSS_IsInitialized()) {
        SECStatus secStatus;
        if (configdir != NULL)
            secStatus = NSS_InitReadWrite(configdir);
        else
            secStatus = NSS_NoDB_Init(NULL);
        if (secStatus != SECSuccess) {
            PNSS_croak();
        }
        saved_pid = getpid();
    }

void
reinit()
  CODE:
    pid_t pid = getpid();
    if (saved_pid == pid) {
        XSRETURN(0);
    }
    SECStatus secStatus = SECMOD_RestartModules(PR_FALSE);
    if (secStatus != SECSuccess) {
        PNSS_croak();
    }
    saved_pid = pid;

void
END()
  CODE:
    if (NSS_IsInitialized()) {
        int mod_type;
        SECMOD_DeleteModule("Builtins", &mod_type);
        NSS_Shutdown();
        PR_Cleanup();
    }


MODULE = Panda::NSS     PACKAGE = Panda::NSS::SecMod
PROTOTYPES: DISABLE

void
add_new_module(const char* module_name, const char* dll_path)
  PREINIT:
    SECStatus status;
  CODE:
    status = SECMOD_AddNewModule(module_name, dll_path, 0, 0);
    if (status != SECSuccess) {
        PNSS_croak();
    }


MODULE = Panda::NSS     PACKAGE = Panda::NSS::Cert
PROTOTYPES: DISABLE

Panda::NSS::Cert
new(klass, SV* cert_sv)
  PREINIT:
    CERTCertificate *cert;

  CODE:
    STRLEN len;
    char* data = SvPV(cert_sv, len);
    SECItem der = {siBuffer, NULL, 0};

    if (len == 0) {
        croak("No data");
    }

    /* Autodetect Base64 encoded der */
    if (data[0] == '-') {
        int found = 0;
        char* cbegin = NULL;
        char* cend = NULL;
        char* cp = data;
        STRLEN cl = len;

        if ( cl > NS_CERT_HEADER_LEN && PORT_Strncasecmp(cp, NS_CERT_HEADER, NS_CERT_HEADER_LEN) == 0 ) {
            cp += NS_CERT_HEADER_LEN; cl -= NS_CERT_HEADER_LEN;
            found = 1;
        }
        if (found) {
            /* skip to next eol */
            while ( cl && ( *cp != '\n' )) {
                cp++; cl--;
            } 
            /* skip all blank lines */
            while ( cl && ( *cp == '\n' || *cp == '\r' )) {
                cp++; cl--;
            }
            if (cl) cbegin = cp;
            if (cbegin) {
                /* find the ending marker */
                while ( cl >= NS_CERT_TRAILER_LEN ) {
                    if ( PORT_Strncasecmp(cp, NS_CERT_TRAILER, NS_CERT_TRAILER_LEN) == 0 ) {
                        cend = cp;
                        break;
                    }
                    /* skip to next eol */
                    while ( cl && ( *cp != '\n' )) {
                        cp++; cl--;
                    }
                    /* skip all blank lines */
                    while ( cl && ( *cp == '\n' || *cp == '\r' )) {
                        cp++; cl--;
                    }
                }
                if (cend) {
                    STRLEN clen = cend - cbegin;
                    SECItem* ok = NSSBase64_DecodeBuffer(NULL, &der, cbegin, clen);
                    if (!ok) {
                        SECITEM_FreeItem(&der, PR_FALSE);
                        PNSS_croak();
                    }
                }
            }
        }
    }

    /* If not filled, then try binary DER */
    if (der.len == 0) {
        der.data = (unsigned char*)PORT_Alloc(len);
        der.len = len;
        PORT_Memcpy(der.data, data, len);
    }

    /* CERT_NewTempCertificate( defaultDB, item, nickname, isPerm, copyDER) */
    cert = CERT_NewTempCertificate(CERT_GetDefaultCertDB(), &der, NULL, PR_FALSE, PR_TRUE);
    
    SECITEM_FreeItem(&der, PR_FALSE);
    if (!cert) {
        PNSS_croak();
    }

    RETVAL = cert;
  OUTPUT:
    RETVAL


int
version(Panda::NSS::Cert cert)
  CODE:
    if (cert->version.len > 0) {
        RETVAL = DER_GetInteger(&cert->version) + 1;
    }
    else {
        RETVAL = 1;
    }
  OUTPUT:
    RETVAL


SV*
serial_number(Panda::NSS::Cert cert)
  CODE:
    RETVAL = newSVpvn_flags((const char*)cert->serialNumber.data, cert->serialNumber.len, 0);
  OUTPUT:
    RETVAL


SV*
serial_number_hex(Panda::NSS::Cert cert)
  CODE:
    ST(0) = sv_newmortal();
    const char* str_hex = CERT_Hexify(&cert->serialNumber, 0);
    if (str_hex != NULL) {
        sv_setpv(ST(0), str_hex);
        PORT_Free((void*)str_hex);
    }


char*
subject(Panda::NSS::Cert cert)
  CODE:
    RETVAL = cert->subjectName;
  OUTPUT:
    RETVAL


char*
issuer(Panda::NSS::Cert cert)
  CODE:
    RETVAL = cert->issuerName;
  OUTPUT:
    RETVAL


SV*
common_name(Panda::NSS::Cert cert)
  CODE:
    char* str = CERT_GetCommonName(&cert->subject);
    RETVAL = newSVpv( str, 0);
    PORT_Free(str);
  OUTPUT:
    RETVAL


SV*
country_name(Panda::NSS::Cert cert)
  CODE:
    char* str = CERT_GetCountryName(&cert->subject);
    RETVAL = newSVpv( str, 0);
    PORT_Free(str);
  OUTPUT:
    RETVAL


SV*
locality_name(Panda::NSS::Cert cert)
  CODE:
    char* str = CERT_GetLocalityName(&cert->subject);
    RETVAL = newSVpv( str, 0);
    PORT_Free(str);
  OUTPUT:
    RETVAL


SV*
state_name(Panda::NSS::Cert cert)
  CODE:
    char* str = CERT_GetStateName(&cert->subject);
    RETVAL = newSVpv( str, 0);
    PORT_Free(str);
  OUTPUT:
    RETVAL


SV*
org_name(Panda::NSS::Cert cert)
  CODE:
    char* str = CERT_GetOrgName(&cert->subject);
    RETVAL = newSVpv( str, 0);
    PORT_Free(str);
  OUTPUT:
    RETVAL


SV*
org_unit_name(Panda::NSS::Cert cert)
  CODE:
    char* str = CERT_GetOrgUnitName(&cert->subject);
    RETVAL = newSVpv( str, 0);
    PORT_Free(str);
  OUTPUT:
    RETVAL


SV*
domain_component_name(Panda::NSS::Cert cert)
  CODE:
    char* str = CERT_GetDomainComponentName(&cert->subject);
    RETVAL = newSVpv( str, 0);
    PORT_Free(str);
  OUTPUT:
    RETVAL


int
simple_verify(Panda::NSS::Cert cert, int usage_iv = 0, double time_nv = 0)
  CODE:
    /* In params */
    CERTValInParam cvin[4];
    int cvinIdx = 0;

    SECCertificateUsage certUsage = usage_iv;

    if (certUsage < 0 || certUsage > certificateUsageHighest) {
        croak("Incorrect certificate usage value");
    }

    if (time_nv > 0) {
        time_nv *= 1000000;
        PRTime pr_time;
        LL_D2L(pr_time, time_nv);
        cvin[cvinIdx].type = cert_pi_date;
        cvin[cvinIdx].value.scalar.time = pr_time;
        ++cvinIdx;
    }

    cvin[cvinIdx].type = cert_pi_useAIACertFetch;
    cvin[cvinIdx].value.scalar.b = PR_TRUE;
    ++cvinIdx;

    cvin[cvinIdx].type = cert_pi_revocationFlags;
    cvin[cvinIdx].value.pointer.revocation = CERT_GetPKIXVerifyNistRevocationPolicy();
    ++cvinIdx;

    cvin[cvinIdx].type = cert_pi_end;

    /* Out params */
    CERTValOutParam cvout[4];
    int cvoutIdx = 0;

    cvout[cvoutIdx].type = cert_po_trustAnchor;
    cvout[cvoutIdx].value.pointer.cert = NULL;
    ++cvoutIdx;

    cvout[cvoutIdx].type = cert_po_certList;
    cvout[cvoutIdx].value.pointer.chain = NULL;
    ++cvoutIdx;

    CERTVerifyLog log;
    log.arena = PORT_NewArena(512);
    log.head = log.tail = NULL;
    log.count = 0;

    cvout[cvoutIdx].type = cert_po_errorLog;
    cvout[cvoutIdx].value.pointer.log = &log;
    ++cvoutIdx;

    cvout[cvoutIdx].type = cert_po_end;

    SECStatus secStatus = CERT_PKIXVerifyCert(cert, certUsage, cvin, cvout, NULL);
    if (secStatus == SECSuccess) {
        RETVAL = 1;
    }
    else {
        RETVAL = 0;
    }

    CERTCertificate* issuerCert = cvout[0].value.pointer.cert;
    if (issuerCert) {
        CERT_DestroyCertificate(issuerCert);
    }

    CERTCertList* builtChain = cvout[1].value.pointer.chain;
    if (builtChain) {
        CERT_DestroyCertList(builtChain);
    }

    CERTVerifyLogNode* node = log.head;
    while (node) {
        if (node->cert) CERT_DestroyCertificate(node->cert);
        node = node->next;
    }

    PORT_FreeArena(log.arena, PR_FALSE);

  OUTPUT:
    RETVAL


int
verify_signed_data(Panda::NSS::Cert cert, SV* payload, SV* signature, double time_nv = 0)
  CODE:
    PLArenaPool* arena = PORT_NewArena(512);

    PRTime pr_time = 0;
    if (time_nv > 0) {
        time_nv *= 1000000;
        LL_D2L(pr_time, time_nv);
    }
    else {
        pr_time = PR_Now();
    }

    STRLEN payload_len;
    unsigned char* payload_pv = (unsigned char*)SvPV(payload, payload_len);
    STRLEN signature_len;
    unsigned char* signature_pv = (unsigned char*)SvPV(signature, signature_len);

    SECStatus rv;
    CERTSignedData sd;
    PORT_Memset(&sd, 0, sizeof(sd));

    sd.data.data = payload_pv;
    sd.data.len = payload_len;
    sd.signature.data = signature_pv;
    sd.signature.len = signature_len << 3; // Convert to bit counter
    rv = SECOID_CopyAlgorithmID(arena, &sd.signatureAlgorithm, &cert->subjectPublicKeyInfo.algorithm);
    if (rv) {
        PORT_FreeArena(arena, PR_FALSE);
        PNSS_croak();
    }

    rv = CERT_VerifySignedData(&sd, cert, pr_time, NULL);
    if (rv == SECSuccess) {
        RETVAL = 1;
    }
    else {
        RETVAL = 0;
    }
    
    PORT_FreeArena(arena, PR_FALSE);

  OUTPUT:
    RETVAL


void
DESTROY(Panda::NSS::Cert cert)
  CODE:
    CERT_DestroyCertificate(cert);
    cert = NULL;
