#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <smapi.h>


#define VOCWORD_MAXLEN 1024
int msgsock = -1;
int bListening = 0;
SV* recognizedWord = &PL_sv_undef;
IV recognitionScore = -1;

/* forward decls */
int NotifierCallback(int so, int (*rcv)(), void* data, void* cinfo);


/*------------------------------------*/
/* setup API */

/*	return value of 0 indicates success
 */
int connectEngine()
{
	SM_MSG msg;
	SmArg args[3];
	int rc;
	char buf[1024];

	setenv("SPCH_BIN", VVDIR "/bin", 1);
	sprintf(buf, "%s/viavoice/temp", getenv("HOME"));
	setenv("SPCH_TRN", buf, 1);
	setenv("SPCH_RO", VVDIR "/vocabs", 1);
	setenv("SPCH_LOC", "vl1", 1);
	setenv("SPCH_PATH", VVDIR "/vocabs/langs/" LOCALE "/pools", 1);
	sprintf(buf, "%s/viavoice", getenv("HOME"));
	setenv("SPCH_RW", buf, 1);
	sprintf(buf, "%s/viavoice/temp", getenv("HOME"));
	setenv("SPCH_RUN", buf, 1);
	sprintf(buf, "%s/viavoice/temp/tmp", getenv("HOME"));
	setenv("SPCH_DIR", buf, 1);

	rc = SmOpen(0, NULL);
	if (rc == SM_RC_OK) {
		SmSetArg(args[0], SmNrecognize, 1);
		SmSetArg(args[1], SmNexternalNotifier, NotifierCallback);
		rc = SmConnect(2, args, &msg);
	}

	return rc;
}

/*	return value of 0 indicates success
 */
int defineVocab(char* vocabName, SV* sv_words)
{
	SM_MSG msg;
	SM_VOCWORD** words;
	AV* av_words;
	int i, rc, alen;

	if (!SvROK(sv_words)) {
		if (SvTYPE(SvRV(sv_words)) != SVt_PVAV) {
			return -1;
		}
	}
	av_words = (AV*) SvRV(sv_words);
	alen = av_len(av_words) + 1;
	words = (SM_VOCWORD**) malloc(sizeof(SM_VOCWORD*) * (av_len(av_words) + 1));

	for (i = 0; i < alen; i++) {
		SV** svp = av_fetch(av_words, i, 0);
		if (NULL != svp) {
			char* word = sv_pv(*svp);
			if (NULL != word) {
				words[i] = (SM_VOCWORD*) malloc(sizeof(SM_VOCWORD));
				words[i]->flags = 0;
				words[i]->spelling_size = strnlen(word, VOCWORD_MAXLEN);
				words[i]->spelling = word;
			}
		}
	}
	rc = SmDefineVocab(vocabName, alen, words, &msg);
	if (rc == SM_RC_OK) {
		rc = SmEnableVocab(vocabName, &msg);
	}

	for (i = 0; i < alen; i++) {
		free(words[i]);
	}
	free(words);

	return rc;
}


/*	return value of 0 indicates success
 */
int startListening()
{
	SM_MSG msg;
	int rc;
	
	rc = SmMicOn(&msg);
	if (rc == SM_RC_OK) {
		bListening = 1;
	}
	return rc;
}


/*	return value of 0 indicates success
 */
int stopListening()
{
	SM_MSG msg;
	int rc = SmMicOff(&msg);
	if (rc == SM_RC_OK) {
		bListening = 0;
	}
	return rc;
}


/*	return value of 0 indicates success
 * 	performed stopListening() if not already done
 */
int disconnectEngine()
{
	SM_MSG msg;
	int rc = SM_RC_OK;

	if (bListening) {
		rc = stopListening();
	}

	if (rc == SM_RC_OK) {
		rc = SmDisconnect(0, NULL, &msg);
	}
	return rc;
}


/*------------------------------------*/
/* recognition API */

int recognize()
{
	SM_MSG msg;
	int rc;
	int typ;

	rc = SmRecognizeNextWord(&msg);

	typ = 0;
	while (rc == SM_RC_OK
			&& (typ != SM_RECOGNIZED_WORD
				&& typ != SM_RECOGNIZED_PHRASE
				&& typ != SM_RECOGNIZED_TEXT
				&& typ != SM_COMMAND_WORD)) {
		/* wait for input */
		fd_set fds;
		FD_ZERO(&fds);
		FD_SET(msgsock, &fds);
		if (select(msgsock + 1, &fds, NULL, NULL, NULL) < 0) {
			fprintf(stderr, "select failed on response socket\n");
			rc = -1;

		} else if (FD_ISSET(msgsock, &fds)) {
			rc = SmReceiveMsg(0, &msg);
			if (rc == SM_RC_OK) {
				rc = SmGetMsgType(msg, &typ);
			}
		}
	}

	if (rc == SM_RC_OK) {
		if (rc == SM_RC_OK) {
			unsigned long n;
			SM_WORD* vwords;
			rc = SmGetFirmWords(msg, &n, &vwords);
			/* delete [] vwords; */

			recognitionScore = (IV)vwords[0].score;
			if (n > 0 && recognitionScore > 0) {
				/* if (&PL_sv_undef == recognizedWord) {
					recognizedWord = sv_newmortal();
				} */
				recognizedWord = newSVpv(vwords[0].spelling, strnlen(vwords[0].spelling, 1024));
			} else {
				recognizedWord = &PL_sv_undef;
			}
		}

	}

	if (rc != SM_RC_OK) {
		recognizedWord = &PL_sv_undef;
		recognitionScore = -1;
	}
	return rc;
}


SV* getWord()
{
	return recognizedWord;
}

IV getScore()
{
	return recognitionScore;
}


/* AV* getAlternatives(); */




/*------------------------------------*/
/* private stuff */
int NotifierCallback(int so, int (*rcv)(), void* data, void* cinfo)
{
	msgsock = so;
}

MODULE = Speech::Recognizer::ViaVoice		PACKAGE = Speech::Recognizer::ViaVoice		

int
connectEngine()

int
defineVocab(vocabName, sv_words)
	char* vocabName
	SV* sv_words

int
startListening()

int
stopListening()

int
disconnectEngine()

int
recognize()

SV*
getWord()

IV
getScore()
