#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdl.h"
#include "pdlcore.h"

#include "faiss_bridge.h"

static Core* PDL;
static SV*   CoreSV;

static SV* bless_index(pTHX_ PdlFaissIndex* idx) {
    if (!idx) {
        croak("PDL::FAISS error: %s", pdl_faiss_last_error());
    }
    SV* iv  = newSViv(PTR2IV(idx));
    SV* ref = newRV_noinc(iv);
    sv_bless(ref, gv_stashpv("PDL::FAISS::Index", GV_ADD));
    return ref;
}

static PdlFaissIndex* sv_to_index(pTHX_ SV* sv) {
    if (!sv_isobject(sv) || !sv_derived_from(sv, "PDL::FAISS::Index")) {
        croak("Expected a PDL::FAISS::Index object");
    }
    IV ptr = SvIV(SvRV(sv));
    if (!ptr) {
        croak("PDL::FAISS::Index has already been destroyed");
    }
    return INT2PTR(PdlFaissIndex*, ptr);
}

MODULE = PDL::FAISS    PACKAGE = PDL::FAISS

PROTOTYPES: DISABLE

BOOT:
{
    CoreSV = get_sv("PDL::SHARE", FALSE);
    if (!CoreSV) {
        croak("PDL::FAISS requires PDL::Core to be loaded first");
    }
    PDL = INT2PTR(Core*, SvIV(CoreSV));
    if (PDL->Version != PDL_CORE_VERSION) {
        croak("PDL::FAISS needs to be recompiled against the newly installed PDL");
    }
}

SV*
flat_l2(int dim)
CODE:
    RETVAL = bless_index(aTHX_ pdl_faiss_new_flat_l2(dim));
OUTPUT:
    RETVAL

SV*
flat_ip(int dim)
CODE:
    RETVAL = bless_index(aTHX_ pdl_faiss_new_flat_ip(dim));
OUTPUT:
    RETVAL

MODULE = PDL::FAISS    PACKAGE = PDL::FAISS::Index

int
dim(SV* self)
CODE:
    RETVAL = pdl_faiss_dim(sv_to_index(aTHX_ self));
OUTPUT:
    RETVAL

IV
ntotal(SV* self)
CODE:
    RETVAL = (IV)pdl_faiss_ntotal(sv_to_index(aTHX_ self));
OUTPUT:
    RETVAL

void
_xs_add(SV* self, SV* pdl_sv)
CODE:
    PdlFaissIndex* idx = sv_to_index(aTHX_ self);
    pdl* p = PDL->SvPDLV(pdl_sv);
    PDL->make_physical(p);
    PDL->make_physdims(p);

    if (p->datatype != PDL_F || p->ndims != 2) {
        croak("PDL::FAISS::Index::add requires a 2D float (dim x n) ndarray");
    }
    if ((int)p->dims[0] != pdl_faiss_dim(idx)) {
        croak("Vector dimension mismatch: got %ld, expected %d", (long)p->dims[0], pdl_faiss_dim(idx));
    }
    if (!pdl_faiss_add(idx, (int64_t)p->dims[1], (const float*)p->data)) {
        croak("PDL::FAISS add failed: %s", pdl_faiss_last_error());
    }

void
_xs_search(SV* self, SV* query_sv, int k)
PPCODE:
    PdlFaissIndex* idx = sv_to_index(aTHX_ self);
    pdl* q = PDL->SvPDLV(query_sv);
    PDL->make_physical(q);
    PDL->make_physdims(q);

    if (q->datatype != PDL_F || q->ndims != 2) {
        croak("PDL::FAISS::Index::search requires a 2D float (dim x nq) ndarray");
    }
    int64_t nq = (int64_t)q->dims[1];

    pdl* dist_pdl = PDL->pdlnew();
    dist_pdl->datatype = PDL_F;
    PDL_Indx ddims[2] = { (PDL_Indx)k, (PDL_Indx)nq };
    PDL->setdims(dist_pdl, ddims, 2);
    PDL->allocdata(dist_pdl);

    pdl* idx_pdl = PDL->pdlnew();
    idx_pdl->datatype = PDL_LL;
    PDL->setdims(idx_pdl, ddims, 2);
    PDL->allocdata(idx_pdl);

    if (!pdl_faiss_search(idx, nq, (const float*)q->data, k, (float*)dist_pdl->data, (int64_t*)idx_pdl->data)) {
        croak("PDL::FAISS search failed: %s", pdl_faiss_last_error());
    }

    SV* sv_d = sv_2mortal(newSV(0));
    SV* sv_i = sv_2mortal(newSV(0));
    PDL->SetSV_PDL(sv_d, dist_pdl);
    PDL->SetSV_PDL(sv_i, idx_pdl);

    EXTEND(SP, 2);
    PUSHs(sv_d);
    PUSHs(sv_i);

void
DESTROY(SV* self)
CODE:
    if (SvROK(self)) {
        SV* iv = SvRV(self);
        IV ptr = SvIV(iv);
        if (ptr) {
            pdl_faiss_free(INT2PTR(PdlFaissIndex*, ptr));
            sv_setiv(iv, 0);
        }
    }
