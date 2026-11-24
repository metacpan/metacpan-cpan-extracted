#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "pdl.h"
#include "pdlcore.h"
#include "arrow_bridge.h"

static Core* PDL;

static const char* pdl_name_from_datatype(int dt) {
    switch (dt) {
        case PDL_D:   return "double";
        case PDL_F:   return "float";
        case PDL_SB:  return "sbyte";
        case PDL_B:   return "byte";
        case PDL_S:   return "short";
        case PDL_US:  return "ushort";
        case PDL_L:   return "long";
        case PDL_UL:  return "ulong";
        case PDL_LL:  return "longlong";
        case PDL_ULL: return "ulonglong";
        case PDL_CF:  return "cfloat";
        case PDL_CD:  return "cdouble";
        default:      return NULL;
    }
}

MODULE = PDL::IO::Arrow    PACKAGE = PDL::IO::Arrow

PROTOTYPES: DISABLE

BOOT:
{
    SV* CoreSV = get_sv("PDL::SHARE", FALSE);
    if (CoreSV == NULL) {
        Perl_croak(aTHX_ "PDL::IO::Arrow requires PDL::Core to be loaded first");
    }
    PDL = INT2PTR(Core*, SvIV(CoreSV));
}

HV*
_xs_read_pdls(const char* path, int format, HV* type_map)
CODE:
    PdlArrowTable* tbl = pdl_arrow_read_file(path, format);
    if (!tbl) {
        croak("Out of memory in pdl_arrow_read_file");
    }
    if (tbl->error) {
        SV* err = sv_2mortal(newSVpv(tbl->error, 0));
        pdl_arrow_table_free(tbl);
        croak("%s", SvPV_nolen(err));
    }

    HV* out = newHV();
    for (size_t i = 0; i < tbl->num_columns; ++i) {
        const char* tname = tbl->columns[i].type_name;
        SV** dt_sv = hv_fetch(type_map, tname, (I32)strlen(tname), 0);
        if (!dt_sv || !SvOK(*dt_sv)) {
            pdl_arrow_table_free(tbl);
            croak("Unsupported PDL datatype: %s", tname);
        }
        pdl* p = PDL->pdlnew();
        p->datatype = (int)SvIV(*dt_sv);
        PDL_Indx dims[1];
        dims[0] = (PDL_Indx)tbl->columns[i].num_elements;
        PDL->setdims(p, dims, 1);
        PDL->allocdata(p);
        if (tbl->columns[i].data_len > 0 && p->data) {
            memcpy(p->data, tbl->columns[i].data, tbl->columns[i].data_len);
        }
        SV* sv = sv_newmortal();
        PDL->SetSV_PDL(sv, p);
        SvREFCNT_inc(sv);
        hv_store(out, tbl->columns[i].name, (I32)strlen(tbl->columns[i].name), sv, 0);
    }
    pdl_arrow_table_free(tbl);
    RETVAL = out;
OUTPUT:
    RETVAL

void
_xs_write_pdls(const char* path, int format, AV* names_av, AV* pdls_av)
CODE:
    SSize_t n = av_len(names_av) + 1;
    if (n <= 0 || av_len(pdls_av) + 1 != n) {
        croak("Column names and PDL arrays must be non-empty and equal length");
    }
    PdlArrowColumn* cols = NULL;
    Newxz(cols, n, PdlArrowColumn);

    for (SSize_t i = 0; i < n; ++i) {
        SV** sv_name = av_fetch(names_av, i, 0);
        SV** sv_pdl  = av_fetch(pdls_av,  i, 0);
        if (!sv_name || !sv_pdl) {
            Safefree(cols);
            croak("Missing column name or PDL at index %ld", (long)i);
        }
        pdl* p = PDL->SvPDLV(*sv_pdl);
        PDL->make_physical(p);
        const char* tname = pdl_name_from_datatype(p->datatype);
        if (!tname) {
            Safefree(cols);
            croak("Unsupported PDL datatype id %d for column %s", p->datatype, SvPV_nolen(*sv_name));
        }
        cols[i].name         = (char*)SvPV_nolen(*sv_name);
        cols[i].type_name    = (char*)tname;
        cols[i].data         = (uint8_t*)p->data;
        cols[i].num_elements = (int64_t)p->nvals;
        cols[i].data_len     = (size_t)(p->nvals * PDL->howbig(p->datatype));
    }

    char* err = pdl_arrow_write_file(path, format, cols, (size_t)n);
    Safefree(cols);
    if (err) {
        SV* err_sv = sv_2mortal(newSVpv(err, 0));
        free(err);
        croak("%s", SvPV_nolen(err_sv));
    }
