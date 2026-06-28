MODULE = PDF::Make  PACKAGE = PDF::Make::Filter
PROTOTYPES: ENABLE

SV *
_ascii85_encode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_ascii85_encode(in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("ascii85_encode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_ascii85_decode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_ascii85_decode(in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("ascii85_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_asciihex_encode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_asciihex_encode(in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("asciihex_encode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_asciihex_decode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_asciihex_decode(in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("asciihex_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_rle_encode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_rle_encode(in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("rle_encode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_rle_decode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_rle_decode(in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("rle_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_flate_encode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_flate_params_t params;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        pdfmake_flate_params_init(&params);
        err = pdfmake_flate_encode(in, in_len, &params, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("flate_encode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_flate_decode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_flate_params_t params;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        pdfmake_flate_params_init(&params);
        err = pdfmake_flate_decode(in, in_len, &params, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("flate_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_deflate_encode(in_sv, level)
    SV *in_sv
    int level
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_deflate_encode(in, in_len, level, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("deflate_encode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_deflate_decode(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_deflate_decode(in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("deflate_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

UV
_adler32(in_sv)
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        RETVAL = (UV)pdfmake_adler32(in, in_len);
    OUTPUT:
        RETVAL

SV *
_lzw_decode(in_sv, early_change = 1)
    SV *in_sv
    int early_change
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_flate_params_t params;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        pdfmake_flate_params_init(&params);
        params.early_change = early_change;
        err = pdfmake_lzw_decode(in, in_len, &params, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("lzw_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_predictor_encode(predictor, colors, bits, columns, in_sv)
    int predictor
    int colors
    int bits
    int columns
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_predictor_encode(predictor, colors, bits, columns, in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("predictor_encode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_predictor_decode(predictor, colors, bits, columns, in_sv)
    int predictor
    int colors
    int bits
    int columns
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_predictor_decode(predictor, colors, bits, columns, in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("predictor_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_tiff_predictor_encode(colors, bits, columns, in_sv)
    int colors
    int bits
    int columns
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_tiff_predictor_encode(colors, bits, columns, in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("tiff_predictor_encode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL

SV *
_tiff_predictor_decode(colors, bits, columns, in_sv)
    int colors
    int bits
    int columns
    SV *in_sv
    PREINIT:
        STRLEN in_len;
        const uint8_t *in;
        pdfmake_buf_t out;
        pdfmake_err_t err;
    CODE:
        in = (const uint8_t *)SvPVbyte(in_sv, in_len);
        if (pdfmake_buf_init(&out) != PDFMAKE_OK) croak("buf_init failed");
        err = pdfmake_tiff_predictor_decode(colors, bits, columns, in, in_len, &out);
        if (err != PDFMAKE_OK) { pdfmake_buf_free(&out); croak("tiff_predictor_decode: err=%d", err); }
        RETVAL = newSVpvn((char *)out.data, out.len);
        pdfmake_buf_free(&out);
    OUTPUT:
        RETVAL
