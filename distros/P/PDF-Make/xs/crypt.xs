MODULE = PDF::Make::Crypt  PACKAGE = PDF::Make::Crypt  PREFIX = crypt_

PROTOTYPES: DISABLE

#===============================================================================
# Constructor / Destructor
#===============================================================================

pdfmake_crypt_xs_t *
crypt_new(class)
    SV *class
CODE:
    PERL_UNUSED_VAR(class);
    Newxz(RETVAL, 1, pdfmake_crypt_xs_t);
    pdfmake_crypt_init(&RETVAL->ctx);
OUTPUT:
    RETVAL

void
crypt_DESTROY(self)
    pdfmake_crypt_xs_t *self
CODE:
    Safefree(self);

#===============================================================================
# Setup for encryption
#===============================================================================

int
crypt_setup(self, algorithm, user_passwd, owner_passwd, permissions, doc_id)
    pdfmake_crypt_xs_t *self
    const char *algorithm
    const char *user_passwd
    SV *owner_passwd
    int32_t permissions
    SV *doc_id
PREINIT:
    pdfmake_crypt_algo_t algo;
    const char *owner_str = NULL;
    const uint8_t *id_bytes = NULL;
    STRLEN id_len = 0;
CODE:
    /* Parse algorithm string */
    if (strEQ(algorithm, "RC4-40") || strEQ(algorithm, "rc4-40")) {
        algo = PDFMAKE_CRYPT_RC4_40;
    } else if (strEQ(algorithm, "RC4-128") || strEQ(algorithm, "rc4-128")) {
        algo = PDFMAKE_CRYPT_RC4_128;
    } else if (strEQ(algorithm, "AES-128") || strEQ(algorithm, "aes-128")) {
        algo = PDFMAKE_CRYPT_AES_128;
    } else if (strEQ(algorithm, "AES-256") || strEQ(algorithm, "aes-256")) {
        algo = PDFMAKE_CRYPT_AES_256;
    } else {
        croak("Unknown encryption algorithm: %s", algorithm);
    }
    
    /* Get owner password (may be undef) */
    if (SvOK(owner_passwd)) {
        owner_str = SvPV_nolen(owner_passwd);
    }
    
    /* Get document ID */
    if (SvOK(doc_id)) {
        id_bytes = (const uint8_t *)SvPV(doc_id, id_len);
    }
    
    RETVAL = pdfmake_crypt_setup(&self->ctx, algo,
                                  user_passwd, owner_str,
                                  permissions,
                                  id_bytes, id_len) == 0 ? 1 : 0;
OUTPUT:
    RETVAL

#===============================================================================
# Load encryption parameters from parsed PDF
#===============================================================================

int
crypt_load(self, V, R, key_length, O, U, OE, UE, Perms, P, doc_id, encrypt_metadata)
    pdfmake_crypt_xs_t *self
    int V
    int R
    int key_length
    SV *O
    SV *U
    SV *OE
    SV *UE
    SV *Perms
    int32_t P
    SV *doc_id
    int encrypt_metadata
PREINIT:
    const uint8_t *O_bytes = NULL, *U_bytes = NULL;
    const uint8_t *OE_bytes = NULL, *UE_bytes = NULL;
    const uint8_t *Perms_bytes = NULL, *id_bytes = NULL;
    STRLEN O_len = 0, U_len = 0, OE_len = 0, UE_len = 0, Perms_len = 0, id_len = 0;
CODE:
    if (SvOK(O)) O_bytes = (const uint8_t *)SvPV(O, O_len);
    if (SvOK(U)) U_bytes = (const uint8_t *)SvPV(U, U_len);
    if (SvOK(OE)) OE_bytes = (const uint8_t *)SvPV(OE, OE_len);
    if (SvOK(UE)) UE_bytes = (const uint8_t *)SvPV(UE, UE_len);
    if (SvOK(Perms)) Perms_bytes = (const uint8_t *)SvPV(Perms, Perms_len);
    if (SvOK(doc_id)) id_bytes = (const uint8_t *)SvPV(doc_id, id_len);
    
    RETVAL = pdfmake_crypt_load(&self->ctx, V, R, key_length,
                                 O_bytes, O_len, U_bytes, U_len,
                                 OE_bytes, OE_len, UE_bytes, UE_len,
                                 Perms_bytes, Perms_len,
                                 P, id_bytes, id_len, encrypt_metadata);
OUTPUT:
    RETVAL

#===============================================================================
# Authentication
#===============================================================================

int
crypt_authenticate(self, password)
    pdfmake_crypt_xs_t *self
    const char *password
CODE:
    RETVAL = pdfmake_crypt_authenticate(&self->ctx, password);
OUTPUT:
    RETVAL

int
crypt_is_authenticated(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = pdfmake_crypt_is_authenticated(&self->ctx);
OUTPUT:
    RETVAL

int
crypt_is_owner(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = pdfmake_crypt_is_owner(&self->ctx);
OUTPUT:
    RETVAL

#===============================================================================
# Encryption / Decryption
#===============================================================================

SV *
crypt_encrypt_string(self, obj_num, gen_num, data)
    pdfmake_crypt_xs_t *self
    int obj_num
    int gen_num
    SV *data
PREINIT:
    const uint8_t *in;
    STRLEN in_len;
    uint8_t *out;
    int out_len;
CODE:
    in = (const uint8_t *)SvPV(data, in_len);
    
    /* Allocate output buffer (max size for AES: 16 + in_len + 16) */
    Newx(out, in_len + 32, uint8_t);
    
    out_len = pdfmake_crypt_encrypt_string(&self->ctx, obj_num, gen_num,
                                            in, in_len, out);
    
    if (out_len < 0) {
        Safefree(out);
        RETVAL = &PL_sv_undef;
    } else {
        RETVAL = newSVpvn((char *)out, out_len);
        Safefree(out);
    }
OUTPUT:
    RETVAL

SV *
crypt_decrypt_string(self, obj_num, gen_num, data)
    pdfmake_crypt_xs_t *self
    int obj_num
    int gen_num
    SV *data
PREINIT:
    const uint8_t *in;
    STRLEN in_len;
    uint8_t *out;
    int out_len;
CODE:
    in = (const uint8_t *)SvPV(data, in_len);
    
    /* Output is at most input length */
    Newx(out, in_len, uint8_t);
    
    out_len = pdfmake_crypt_decrypt_string(&self->ctx, obj_num, gen_num,
                                            in, in_len, out);
    
    if (out_len < 0) {
        Safefree(out);
        RETVAL = &PL_sv_undef;
    } else {
        RETVAL = newSVpvn((char *)out, out_len);
        Safefree(out);
    }
OUTPUT:
    RETVAL

SV *
crypt_encrypt_stream(self, data, obj_num, gen_num)
    pdfmake_crypt_xs_t *self
    SV *data
    int obj_num
    int gen_num
PREINIT:
    const uint8_t *in;
    STRLEN in_len;
    uint8_t *out = NULL;
    size_t out_len = 0;
    int rc;
CODE:
    in = (const uint8_t *)SvPV(data, in_len);
    
    rc = pdfmake_crypt_encrypt_stream(&self->ctx, obj_num, gen_num,
                                       in, in_len, &out, &out_len);

    if (rc != 0 || out == NULL) {
        if (out) pdfmake_cfree(out);
        RETVAL = &PL_sv_undef;
    } else {
        RETVAL = newSVpvn((char *)out, out_len);
        pdfmake_cfree(out);
    }
OUTPUT:
    RETVAL

SV *
crypt_decrypt_stream(self, data, obj_num, gen_num)
    pdfmake_crypt_xs_t *self
    SV *data
    int obj_num
    int gen_num
PREINIT:
    const uint8_t *in;
    STRLEN in_len;
    uint8_t *out = NULL;
    size_t out_len = 0;
    int rc;
CODE:
    in = (const uint8_t *)SvPV(data, in_len);
    
    rc = pdfmake_crypt_decrypt_stream(&self->ctx, obj_num, gen_num,
                                       in, in_len, &out, &out_len);

    if (rc != 0 || out == NULL) {
        if (out) pdfmake_cfree(out);
        RETVAL = &PL_sv_undef;
    } else {
        RETVAL = newSVpvn((char *)out, out_len);
        pdfmake_cfree(out);
    }
OUTPUT:
    RETVAL

#===============================================================================
# Permission checking
#===============================================================================

int
crypt_has_permission(self, perm)
    pdfmake_crypt_xs_t *self
    int32_t perm
CODE:
    RETVAL = pdfmake_crypt_has_permission(&self->ctx, perm);
OUTPUT:
    RETVAL

int32_t
crypt_get_permissions(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = pdfmake_crypt_get_permissions(&self->ctx);
OUTPUT:
    RETVAL

#===============================================================================
# Getters for encryption parameters (for writing /Encrypt dict)
#===============================================================================

int
crypt_get_V(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = self->ctx.V;
OUTPUT:
    RETVAL

int
crypt_get_R(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = self->ctx.R;
OUTPUT:
    RETVAL

int
crypt_get_key_length(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = self->ctx.key_length * 8;  /* Return in bits */
OUTPUT:
    RETVAL

SV *
crypt_get_O(self)
    pdfmake_crypt_xs_t *self
CODE:
    if (self->ctx.R >= 6) {
        RETVAL = newSVpvn((char *)self->ctx.O, 48);
    } else {
        RETVAL = newSVpvn((char *)self->ctx.O, 32);
    }
OUTPUT:
    RETVAL

SV *
crypt_get_U(self)
    pdfmake_crypt_xs_t *self
CODE:
    if (self->ctx.R >= 6) {
        RETVAL = newSVpvn((char *)self->ctx.U, 48);
    } else {
        RETVAL = newSVpvn((char *)self->ctx.U, 32);
    }
OUTPUT:
    RETVAL

SV *
crypt_get_OE(self)
    pdfmake_crypt_xs_t *self
CODE:
    if (self->ctx.R >= 6) {
        RETVAL = newSVpvn((char *)self->ctx.OE, 32);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV *
crypt_get_UE(self)
    pdfmake_crypt_xs_t *self
CODE:
    if (self->ctx.R >= 6) {
        RETVAL = newSVpvn((char *)self->ctx.UE, 32);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV *
crypt_get_Perms(self)
    pdfmake_crypt_xs_t *self
CODE:
    if (self->ctx.R >= 6) {
        RETVAL = newSVpvn((char *)self->ctx.Perms, 16);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

int32_t
crypt_get_P(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = self->ctx.P;
OUTPUT:
    RETVAL

int
crypt_get_encrypt_metadata(self)
    pdfmake_crypt_xs_t *self
CODE:
    RETVAL = self->ctx.encrypt_metadata;
OUTPUT:
    RETVAL

void
crypt_set_encrypt_metadata(self, value)
    pdfmake_crypt_xs_t *self
    int value
CODE:
    self->ctx.encrypt_metadata = value;

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Crypt", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "version",          pdfmake_crypt_xs_t, ctx.V,                PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "revision",         pdfmake_crypt_xs_t, ctx.R,                PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "permissions",      pdfmake_crypt_xs_t, ctx.P,                PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "encrypt_metadata", pdfmake_crypt_xs_t, ctx.encrypt_metadata, PDFMAKE_FIELD_INT);
}
