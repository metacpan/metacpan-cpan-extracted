MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2

# _http_json($ua, $method, $url, $headers_or_undef, $body_or_undef)
# -> ($status, $data_or_undef). Request building and JSON decode in C
# over fetch_abi (or the Perl-object test seam).
void
_http_json(ua, method, url, headers, body)
        SV *ua
        SV *method
        SV *url
        SV *headers
        SV *body
    PPCODE:
        HV *hv = (SvROK(headers) && SvTYPE(SvRV(headers)) == SVt_PVHV)
            ? (HV *)SvRV(headers) : NULL;
        int status = 0;
        SV *data = pox_http_json(aTHX_ ua, SvPV_nolen(method),
                                 SvPV_nolen(url), hv,
                                 SvOK(body) ? body : NULL, &status);
        EXTEND(SP, 2);
        mPUSHi(status);
        PUSHs(data ? data : &PL_sv_undef);
