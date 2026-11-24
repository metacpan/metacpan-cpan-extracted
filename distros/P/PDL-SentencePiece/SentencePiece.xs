#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sentencepiece_processor.h>
#include <string>
#include <vector>

using sentencepiece::SentencePieceProcessor;

MODULE = PDL::SentencePiece    PACKAGE = PDL::SentencePiece

PROTOTYPES: DISABLE

SV *
_new(klass)
    const char *klass
  CODE:
    SentencePieceProcessor *proc = new SentencePieceProcessor();
    RETVAL = sv_setref_pv(newSV(0), klass, (void *)proc);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (SvROK(self)) {
        SentencePieceProcessor *proc = INT2PTR(SentencePieceProcessor *, SvIV(SvRV(self)));
        delete proc;
    }

int
_load(self, filename)
    SV *self
    const char *filename
  CODE:
    SentencePieceProcessor *proc = INT2PTR(SentencePieceProcessor *, SvIV(SvRV(self)));
    auto status = proc->Load(filename);
    RETVAL = status.ok() ? 1 : 0;
  OUTPUT:
    RETVAL

int
piece_size(self)
    SV *self
  CODE:
    SentencePieceProcessor *proc = INT2PTR(SentencePieceProcessor *, SvIV(SvRV(self)));
    RETVAL = proc->GetPieceSize();
  OUTPUT:
    RETVAL

AV *
_encode_as_ids(self, text)
    SV *self
    const char *text
  CODE:
    SentencePieceProcessor *proc = INT2PTR(SentencePieceProcessor *, SvIV(SvRV(self)));
    std::vector<int> ids;
    auto status = proc->Encode(text, &ids);
    if (!status.ok()) {
        croak("SentencePiece::Encode failed: %s", status.ToString().c_str());
    }
    AV *av = newAV();
    av_extend(av, ids.size());
    for (int id : ids) {
        av_push(av, newSViv(id));
    }
    RETVAL = av;
  OUTPUT:
    RETVAL

SV *
_decode_ids(self, ids_av)
    SV *self
    AV *ids_av
  CODE:
    SentencePieceProcessor *proc = INT2PTR(SentencePieceProcessor *, SvIV(SvRV(self)));
    std::vector<int> ids;
    SSize_t len = av_len(ids_av) + 1;
    ids.reserve(len);
    for (SSize_t i = 0; i < len; i++) {
        SV **elem = av_fetch(ids_av, i, 0);
        ids.push_back(elem ? (int)SvIV(*elem) : 0);
    }
    std::string out;
    auto status = proc->Decode(ids, &out);
    if (!status.ok()) {
        croak("SentencePiece::Decode failed: %s", status.ToString().c_str());
    }
    RETVAL = newSVpvn(out.data(), out.size());
  OUTPUT:
    RETVAL
