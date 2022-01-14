#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "build/vosk-api/src/vosk_api.h"

int
Vosk_model_find_word(SV* model, const char *word) {
    return vosk_model_find_word((VoskModel*)SvIV(model), word);
}

SV*
Vosk_model_new(SV* modelname) {
    VoskModel* model;
    SV* res;
    model = vosk_model_new(SvPV_nolen(modelname));
    res = newSViv((IV) model); /* We store the pointer as an int in our result */

    return res;
}

void
Vosk_model_free(SV* model) {
    vosk_model_free((VoskModel*)SvIV(model));
}

SV*
Vosk_recognizer_new(SV* model, double sample_rate) {
    VoskRecognizer* recognizer;
    SV* res;

    // XXX Keep a reference to the model in our recognizer for housekeeping

    recognizer = vosk_recognizer_new((VoskModel*)SvIV(model), sample_rate);

    res = newSViv((IV) recognizer);
    return res;
}

/* Implicitly also releases the model! */
void
Vosk_recognizer_free(SV *recognizer) {
    vosk_recognizer_free((VoskRecognizer*) SvIV(recognizer));
}

void
Vosk_recognizer_set_words(SV *recognizer, int words) {
    vosk_recognizer_set_words((VoskRecognizer*)SvIV(recognizer), words);
}

bool
Vosk_recognizer_accept_waveform(SV* recognizer, SV* buf) {
    char* payload;
    STRLEN strlen;
    bool final;

    payload = SvPVbyte(buf,strlen);
    VoskRecognizer* r;

    r = (VoskRecognizer*)SvIV(recognizer);
    final = vosk_recognizer_accept_waveform(r, payload, strlen);

    return final;
}

char*
Vosk_recognizer_partial_result(SV* recognizer) {
    return vosk_recognizer_partial_result((VoskRecognizer*)SvIV(recognizer));
}

char*
Vosk_recognizer_result(SV* recognizer) {
    return vosk_recognizer_result((VoskRecognizer*)SvIV(recognizer));
}

char*
Vosk_recognizer_final_result(SV* recognizer) {
    return vosk_recognizer_final_result((VoskRecognizer*)SvIV(recognizer));
}

void
Vosk_set_log_level(int log_level) {
    vosk_set_log_level(log_level);
}

MODULE = Speech::Recognition::Vosk  PACKAGE = Speech::Recognition::Vosk  PREFIX = Vosk_

PROTOTYPES: DISABLE


int
Vosk_model_find_word (model, word)
	SV *	model
	const char *	word

SV *
Vosk_model_new (modelname)
	SV *	modelname

void
Vosk_model_free (model)
	SV *	model
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Vosk_model_free(model);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Vosk_recognizer_new (model, sample_rate)
	SV *	model
	double	sample_rate

void
Vosk_recognizer_free (recognizer)
	SV *	recognizer
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Vosk_recognizer_free(recognizer);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Vosk_recognizer_set_words (recognizer, words)
	SV *	recognizer
	int	words
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Vosk_recognizer_set_words(recognizer, words);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

bool
Vosk_recognizer_accept_waveform (recognizer, buf)
	SV *	recognizer
	SV *	buf

char *
Vosk_recognizer_partial_result (recognizer)
	SV *	recognizer

char *
Vosk_recognizer_result (recognizer)
	SV *	recognizer

char *
Vosk_recognizer_final_result (recognizer)
	SV *	recognizer

void
Vosk_set_log_level(log_level)
    int log_level
        PPCODE:
        vosk_set_log_level(log_level);
        return;

