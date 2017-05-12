#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "speak_lib.h"
#include <stdlib.h>

#include "const-c.inc"

#include <string.h>

typedef espeak_EVENT Speech_eSpeak_Event;

static SV * perl_synthcallback = (SV*)NULL;
static SV * perl_uricallback = (SV*)NULL;

int c_uricallback(int type, const char *uri, const char *base)
{
}

int c_synthcallback(short *wav, int numsamples, SV* events)
{
/*
	printf("enter c_synthcallback\n");
	espeak_EVENT *event = (espeak_EVENT*) SvRV(events);
	printf("wav:, numsamples:%d, events:%d\n", numsamples, event->unique_identifier);
	if (perl_synthcallback == NULL) {
		printf("NULL\n");
	}

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpvn((char*)wav, numsamples)));
	XPUSHs(sv_2mortal(newSViv(numsamples)));
	XPUSHs(sv_2mortal(newSViv(event->type)));
	XPUSHs(sv_2mortal(newSViv(event->unique_identifier)));
	XPUSHs(sv_2mortal(newSViv(event->text_position)));
	XPUSHs(sv_2mortal(newSViv(event->audio_position)));
	XPUSHs(sv_2mortal(newSVsv(event->user_data)));
	if (event->type == espeakEVENT_WORD || event->type == espeakEVENT_SENTENCE || espeakEVENT_PHONEME) {
		XPUSHs(sv_2mortal(newSViv(event->id.number)));
	} else if (event->type == espeakEVENT_MARK || event->type == espeakEVENT_PLAY) {
		XPUSHs(sv_2mortal(newSVpv(event->id.name, 0)));
	}
	PUTBACK;

	call_sv(perl_synthcallback, G_SCALAR);
	FREETMPS;
	LEAVE;

	return 0;
*/
}

MODULE = Speech::eSpeak		PACKAGE = Speech::eSpeak		
INCLUDE: const-xs.inc

IV
espeakEVENT_LIST_TERMINATED()
	CODE:
		RETVAL = espeakEVENT_LIST_TERMINATED;
	OUTPUT:
		RETVAL

IV
espeakEVENT_WORD()
	CODE:
		RETVAL = espeakEVENT_WORD;
	OUTPUT:
		RETVAL

IV
espeakEVENT_SENTENCE()
	CODE:
		RETVAL = espeakEVENT_SENTENCE;
	OUTPUT:
		RETVAL

IV
espeakEVENT_MARK()
	CODE:
		RETVAL = espeakEVENT_MARK;
	OUTPUT:
		RETVAL

IV
espeakEVENT_PLAY()
	CODE:
		RETVAL = espeakEVENT_PLAY;
	OUTPUT:
		RETVAL

IV
espeakEVENT_END()
	CODE:
		RETVAL = espeakEVENT_END;
	OUTPUT:
		RETVAL

IV
espeakEVENT_MSG_TERMINATED()
	CODE:
		RETVAL = espeakEVENT_MSG_TERMINATED;
	OUTPUT:
		RETVAL

IV
espeakEVENT_PHONEME()
	CODE:
		RETVAL = espeakEVENT_PHONEME;
	OUTPUT:
		RETVAL

IV
POS_CHARACTER()
	CODE:
		RETVAL = POS_CHARACTER;
	OUTPUT:	
		RETVAL

IV
POS_WORD()
	CODE:
		RETVAL = POS_WORD;
	OUTPUT:
		RETVAL

IV
POS_SENTENCE()
	CODE:
		RETVAL = POS_SENTENCE;
	OUTPUT:
		RETVAL

IV
AUDIO_OUTPUT_PLAYBACK()
	CODE:
		RETVAL = AUDIO_OUTPUT_PLAYBACK;
	OUTPUT:
		RETVAL

IV
AUDIO_OUTPUT_RETRIEVAL()
	CODE:
		RETVAL = AUDIO_OUTPUT_RETRIEVAL;
	OUTPUT:
		RETVAL

IV
AUDIO_OUTPUT_SYNCHRONOUS()
	CODE:
		RETVAL = AUDIO_OUTPUT_SYNCHRONOUS;
	OUTPUT:
		RETVAL

IV
AUDIO_OUTPUT_SYNCH_PLAYBACK()
	CODE:
		RETVAL = AUDIO_OUTPUT_SYNCH_PLAYBACK;
	OUTPUT:
		RETVAL

IV
EE_OK()
	CODE:
		RETVAL = EE_OK;
	OUTPUT:
		RETVAL

IV
EE_INTERNAL_ERROR()
	CODE:
		RETVAL = EE_INTERNAL_ERROR;
	OUTPUT:
		RETVAL

IV
EE_BUFFER_FULL()
	CODE:
		RETVAL = EE_BUFFER_FULL;
	OUTPUT:
		RETVAL

IV
EE_NOT_FOUND()
	CODE:
		RETVAL = EE_NOT_FOUND;
	OUTPUT:
		RETVAL

int
espeak_Initialize(output, buflength, path, options)
		IV		output
		int		buflength
		const char *	path
		int		options

void
espeak_SetSynthCallback(SynthCallback)
		SV*		SynthCallback
	CODE:
		if (perl_synthcallback == (SV*)NULL)
			perl_synthcallback = newSVsv((SV*)SynthCallback);
		else
			SvSetSV(perl_synthcallback, (SV*)SynthCallback);
		espeak_SetSynthCallback((t_espeak_callback*)c_synthcallback);

void
espeak_SetUriCallback(UriCallback)
		SV*		UriCallback
	CODE:
		if (perl_uricallback == (SV*)NULL)
			perl_uricallback = newSVsv((SV*)UriCallback);
		else
			SvSetSV(perl_uricallback, (SV*)UriCallback);
		espeak_SetUriCallback(c_uricallback);

IV
espeak_Synth(text, size, positon, position_type, end_position, flags, unique_identifier, user_data)
		const void *	text
		size_t		size
		unsigned int	positon
		IV		position_type
		unsigned int	end_position
		unsigned int	flags
		unsigned int *	unique_identifier
		void *		user_data

IV
espeak_Synth_Mark(text, size, index_mark, end_position, flags, unique_identifier, user_data)
		const void *	text
		size_t		size
		const char *	index_mark
		unsigned int	end_position
		unsigned int	flags
		unsigned int *	unique_identifier
		void *		user_data

IV
espeak_Key(key_name)
		const char *	key_name

IV
espeak_Char(character)
		wchar_t		character

IV
espeakSILENCE()
	CODE:
		RETVAL = espeakSILENCE;
	OUTPUT:
		RETVAL

IV
espeakRATE()
	CODE:
		RETVAL = espeakRATE;
	OUTPUT:
		RETVAL

IV
espeakVOLUME()
	CODE:
		RETVAL = espeakVOLUME;
	OUTPUT:
		RETVAL

IV
espeakPITCH()
	CODE:
		RETVAL = espeakPITCH;
	OUTPUT:
		RETVAL

IV
espeakRANGE()
	CODE:
		RETVAL = espeakRANGE;
	OUTPUT:
		RETVAL

IV
espeakPUNCTUATION()
	CODE:
		RETVAL = espeakPUNCTUATION;
	OUTPUT:
		RETVAL

IV
espeakCAPITALS()
	CODE:
		RETVAL = espeakCAPITALS;
	OUTPUT:
		RETVAL

IV
espeakEMPHASIS()
	CODE:
		RETVAL = espeakEMPHASIS;
	OUTPUT:
		RETVAL

IV
espeakLINELENGTH()
	CODE:
		RETVAL = espeakLINELENGTH;
	OUTPUT:
		RETVAL

IV
espeakVOICETYPE()
	CODE:
		RETVAL = espeakVOICETYPE;
	OUTPUT:
		RETVAL

IV
N_SPEECH_PARAM()
	CODE:
		RETVAL = N_SPEECH_PARAM;
	OUTPUT:
		RETVAL

IV
espeakPUNCT_NONE()
	CODE:
		RETVAL = espeakPUNCT_NONE;
	OUTPUT:
		RETVAL

IV
espeakPUNCT_ALL()
	CODE:
		RETVAL = espeakPUNCT_ALL;
	OUTPUT:
		RETVAL

IV
espeakPUNCT_SOME()
	CODE:
		RETVAL = espeakPUNCT_SOME;
	OUTPUT:
		RETVAL

IV
espeak_SetParameter(parameter, value, relative)
		IV		parameter
		int		value
		int		relative

IV
espeak_GetParameter(parameter, current)
		IV		parameter
		int		current

IV
espeak_SetPunctuationList(punctlist)
		const wchar_t *	punctlist

void
espeak_SetPhonemeTrace(value, stream)
		int		value
		FILE *		stream

void
espeak_CompileDictionary(path, log, flags)
		const char *	path
		FILE *		log
    int flags

SV *
espeak_ListVoices(voice_spec)
		SV *		voice_spec
	INIT:
		AV * results;
		espeak_VOICE *voice = (espeak_VOICE *) malloc(sizeof(espeak_VOICE));
		STRLEN len;
		const espeak_VOICE ** voices;
		results = (AV *)sv_2mortal((SV *)newAV());
	CODE:
		if ((!SvROK(voice_spec))
		    || (SvTYPE(SvRV(voice_spec)) != SVt_PVHV)) {
			voices = espeak_ListVoices(NULL);
		} else {
			HV * spec = (HV *) SvRV(voice_spec);
			if (hv_exists(spec, "name", 4)) {
			voice->name = SvPV(newSVsv(*hv_fetch(spec, "name", 4, 1)
), len);
			} else {
				voice->name = "";
			}

	                if (hv_exists(spec, "languages", 9)) {
				voice->languages = SvPV(newSVsv(*hv_fetch(spec, "languages", 9, 1)), len);
                	} else {
                        	voice->languages = "";
	                } 

        	        if (hv_exists(spec, "identifier", 10)) {        
				voice->identifier = SvPV(newSVsv(*hv_fetch(spec, "identifier", 10, 1)), len);
	                } else {
        	                voice->identifier = "";
                	}

	                if (hv_exists(spec, "gender", 6)) {
				voice->gender = SvIV(newSVsv(*hv_fetch(spec, "gender", 6, 1)));
                	} else {
	                        voice->gender = 0;
        	        }

	                if (hv_exists(spec, "age", 3)) {
				voice->age = SvIV(newSVsv(*hv_fetch(spec, "age", 3, 1)));
                	} else {
                        	voice->age = 0;
	                }

        	        if (hv_exists(spec, "variant", 7)) {
				voice->variant = SvIV(newSVsv(*hv_fetch(spec, "variant", 7, 1)));
	                } else {
        	                voice->variant = 0;
                	}
			voices = espeak_ListVoices(voice);
		}

		int i = 0;
		while (voices[i]) {
			HV * vi = (HV *)sv_2mortal((SV *)newHV());
			hv_store(vi, "name", 4, newSVpv(voices[i]->name, 0), 0);
			hv_store(vi, "languages", 9, newSVpv(voices[i]->languages, 0), 0);
			hv_store(vi, "identifier", 10, newSVpv(voices[i]->identifier, 0), 0);
			hv_store(vi, "age", 3, newSViv(voices[i]->age), 0);
			hv_store(vi, "gender", 6, newSViv(voices[i]->gender), 0);
			hv_store(vi, "variant", 7, newSViv(voices[i]->variant), 0);

			av_push(results, newRV((SV *)vi));
			i++;
		}
		RETVAL = newRV((SV *)results);
	OUTPUT:
		RETVAL

IV
espeak_SetVoiceByName(name)
		const char *	name

IV
espeak_SetVoiceByProperties(voice_spec)
		SV *		voice_spec
	INIT:
		espeak_VOICE *voice = (espeak_VOICE *) malloc(sizeof(espeak_VOICE));
		if ((!SvROK(voice_spec))
		    || (SvTYPE(SvRV(voice_spec)) != SVt_PVHV)) {
			XSRETURN_UNDEF;
		}
		HV * spec = (HV *) SvRV(voice_spec);
		STRLEN len;
	CODE:
		if (hv_exists(spec, "name", 4)) {
			voice->name = SvPV(newSVsv(*hv_fetch(spec, "name", 4, 1)), len);
		} else {
			voice->name = "";
		}

		if (hv_exists(spec, "languages", 9)) {
			voice->languages = SvPV(newSVsv(*hv_fetch(spec, "languages", 9, 1)), len);
		} else {
			voice->languages = "";
		} 

		if (hv_exists(spec, "identifier", 10)) {	
			voice->identifier = SvPV(newSVsv(*hv_fetch(spec, "identifier", 10, 1)), len);
		} else {
			voice->identifier = "";
		}

		if (hv_exists(spec, "gender", 6)) {
			voice->gender = SvIV(newSVsv(*hv_fetch(spec, "gender", 6, 1)));
		} else {
			voice->gender = 0;
		}

		if (hv_exists(spec, "age", 3)) {
			voice->age = SvIV(newSVsv(*hv_fetch(spec, "age", 3, 1)));
		} else {
			voice->age = 0;
		}

		if (hv_exists(spec, "variant", 7)) {
			voice->variant = SvIV(newSVsv(*hv_fetch(spec, "variant", 7, 1)));
		} else {
			voice->variant = 0;
		}

		RETVAL = espeak_SetVoiceByProperties(voice);
		free(voice);
	OUTPUT:
		RETVAL
		

HV *
espeak_GetCurrentVoice()
	INIT:
		HV * result = (HV *)sv_2mortal((SV *)newHV());
	CODE:
		espeak_VOICE *voice = espeak_GetCurrentVoice();
		hv_store(result, "name", 4, newSVpv(voice->name, 0), 0);
		hv_store(result, "languages", 9, newSVpv(voice->languages, 0), 0);
		hv_store(result, "identifier", 10, newSVpv(voice->identifier, 0), 0);
		hv_store(result, "age", 3, newSViv(voice->age), 0);
		hv_store(result, "gender", 6, newSViv(voice->gender), 0);
		hv_store(result, "variant", 7, newSViv(voice->variant), 0);
		RETVAL = result;
	OUTPUT:
		RETVAL

IV
espeak_Cancel()

int
espeak_IsPlaying()

IV
espeak_Synchronize()

IV
espeak_Terminate()

const char *
espeak_Info(ptr)
		void *		ptr

MODULE = Speech::eSpeak  PACKAGE = Speech::eSpeak::EventPtr  PREFIX = event_

void
event_DESTROY(self)
		Speech_eSpeak_Event *	self
	CODE:
		free(self);

IV
event_type(self)
		Speech_eSpeak_Event * self
        CODE:
                RETVAL = self->type;
        OUTPUT:
                RETVAL

unsigned int
event_unique_identifier(self)
                Speech_eSpeak_Event *	self
        CODE:
                RETVAL = self->unique_identifier;
        OUTPUT:
                RETVAL

int
event_text_position(self)
                Speech_eSpeak_Event *   self
        CODE:
                RETVAL = self->text_position;
        OUTPUT:
                RETVAL

int
event_length(self)
                Speech_eSpeak_Event *   self
        CODE:
                RETVAL = self->length;
        OUTPUT:
                RETVAL

int
event_audio_position(self)
                Speech_eSpeak_Event *   self
        CODE:
                RETVAL = self->audio_position;
        OUTPUT:
                RETVAL

int
event_sample(self)
                Speech_eSpeak_Event *   self
        CODE:
                RETVAL = self->sample;
        OUTPUT:
                RETVAL

void *
event_user_data(self)
                Speech_eSpeak_Event *   self
        CODE:
                RETVAL = self->user_data;
        OUTPUT:
                RETVAL

int
event_number(self)
                Speech_eSpeak_Event *   self
        CODE:
                RETVAL = (self->id).number;
        OUTPUT:
                RETVAL

const char *
event_name(self)
                Speech_eSpeak_Event *   self
        CODE:
                RETVAL = (self->id).name;
        OUTPUT:
                RETVAL
