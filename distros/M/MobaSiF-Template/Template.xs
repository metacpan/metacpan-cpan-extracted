#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/mman.h>
#include <stdlib.h>

#define TPL_PLAIN   1
#define TPL_REPLACE 2
#define TPL_LOOP    3
#define TPL_IF      4
#define TPL_ELSE    5
#define TPL_QSA     6
#define TPL_LB      253
#define TPL_RB      254
#define TPL_END     255

/* define Modifier */
#define O_ENCODE 1  /* url encode */
#define O_HSCHRS 2  /* htmlspecialchars */
#define O_NL2BR  4  /* nl2br */

/* define Condition */
#define COND_EQ 0
#define COND_NE 1
#define COND_GT 2
#define COND_GE 3
#define COND_LT 4
#define COND_LE 5

#define ushort unsigned short
#define uint   unsigned int

typedef struct {
	uint type;
} TPL_DESC;

typedef struct {
	uint type;
	uint ofsText;
} TPL_DESC_PLAIN;

typedef struct {
	uint type;
	uint ofsKey;
	uint opt;
} TPL_DESC_REPLACE;

typedef struct {
	uint type;
	uint onTruePos;
	uint onFalsePos;
	uint ofsKey;
	uint ofsVal;
	uint condType;
} TPL_DESC_IF;

typedef struct {
	uint type;
	uint onTruePos;
	uint onFalsePos;
} TPL_DESC_ELSE;

typedef struct {
	uint type;
	uint ofsKey;
	uint onLoopEndPos;
} TPL_DESC_LOOP;

typedef struct {
	uint type;
	uint inout; /* 0:in 1:out */
} TPL_DESC_QSA;

typedef struct {
	uint type;
} TPL_DESC_LB;

typedef struct {
	uint type;
} TPL_DESC_RB;

typedef struct {
	uint type;
} TPL_DESC_END;

SV* template_insert(char* file, SV* rHash, SV* rHash2, SV* rHash3);

void template_process(
	SV* svHtml, void* pLines, void* pString, HV* pHash, HV* pHash2, HV* pHash3, void* ptr);

void process_replace(TPL_DESC_REPLACE* pDesc,
	SV* svHtml, char* pString, HV* pHash, HV* pHash2, HV* pHash3);
int process_if(TPL_DESC_IF* pDesc,
	            char* pString, HV* pHash, HV* pHash2, HV* pHash3);
void process_loop(TPL_DESC_LOOP* pDesc,
	SV* svHtml, char* pString, HV* pHash, HV* pHash2, HV* pHash3, void* pLines);

void cat_specialchars(SV* svHtml, char* in, int len, int f_nl2br);
void cat_encode(SV* svHtml, char* in, int len);
int  mmap_file(char* file, char** buf);

SV* template_insert(char* file, SV* rHash, SV* rHash2, SV* rHash3) {
	SV *svHtml;
	HV *pHash, *pHash2, *pHash3;
	void *pMem, *pLines;
	char *pString;
	int len;
	
	/* メモリの準備 */
	
	svHtml = newSVpv("", 0);
	len = mmap_file(file, (char**) &pMem);
	if (len == 0) return(&PL_sv_undef);
	pLines  = pMem + sizeof(int);
	pString = (char*) (pLines + *((int*) pMem));
	
	if (rHash  && SvROK(rHash)  && SvTYPE(SvRV(rHash))  == SVt_PVHV) {
		pHash = (HV*) SvRV(rHash);
	} else {
		pHash = NULL;
	}
	if (rHash2 && SvROK(rHash2) && SvTYPE(SvRV(rHash2)) == SVt_PVHV) {
		pHash2 = (HV*) SvRV(rHash2);
	} else {
		pHash2 = NULL;
	}
	if (rHash3 && SvROK(rHash3) && SvTYPE(SvRV(rHash3)) == SVt_PVHV) {
		pHash3 = (HV*) SvRV(rHash3);
	} else {
		pHash3 = NULL;
	}
	
	/* 処理 */
	
	template_process(svHtml, pLines, pString, pHash, pHash2, pHash3, pLines);
	
	/* 完了 */
	
	munmap(pMem, len);
	return(svHtml);
}

/*-------------------------------------------------------------------- */

void template_process(
	SV* svHtml, void* pLines, void* pString, HV* pHash, HV* pHash2, HV* pHash3, void* ptr) {
	
	STRLEN qsa_in, qsa_out;
	char *qschk_pos, *qschk_end;
	int qs_exists;
	int lastCond;
	
	lastCond = 0;
	
	while (1) {
	switch( ((TPL_DESC*)ptr)->type ) {
	
	case TPL_PLAIN:
		sv_catpv(svHtml, pString + ((TPL_DESC_PLAIN*)ptr)->ofsText);
		ptr += sizeof(TPL_DESC_PLAIN);
		lastCond = 1;
		break;
	
	case TPL_REPLACE:
		process_replace(
			(TPL_DESC_REPLACE*) ptr, svHtml, pString, pHash, pHash2, pHash3);
		ptr += sizeof(TPL_DESC_REPLACE);
		lastCond = 1;
		break;
	
	case TPL_QSA:
		if (((TPL_DESC_QSA*)ptr)->inout == 0) { /* in */
			qsa_in = SvPOK(svHtml) ? SvCUR(svHtml) : 0;
		} else { /* out */
			if (SvPOK(svHtml)) {
				qschk_pos  = SvPV(svHtml, qsa_out);
				qschk_end  = qschk_pos + qsa_out;
				qschk_pos += qsa_in;
				qs_exists  = 0;
				while (qschk_pos < qschk_end) {
					if (*qschk_pos == '?') {
						qs_exists = 1;
						break;
					}
					qschk_pos++;
				}
				if (qs_exists) {
					sv_catpvn(svHtml, "&", 1);
				} else {
					sv_catpvn(svHtml, "?", 1);
				}
			}
		}
		ptr += sizeof(TPL_DESC_QSA);
		lastCond = 1;
		break;
	
	case TPL_IF:
		lastCond = process_if(
			(TPL_DESC_IF*) ptr, pString, pHash, pHash2, pHash3);
		if (lastCond) {
			ptr = pLines + ((TPL_DESC_IF*)ptr)->onTruePos;
		} else {
			ptr = pLines + ((TPL_DESC_IF*)ptr)->onFalsePos;
		}
		break;
	
	case TPL_ELSE:
		if (lastCond) {
			ptr = pLines + ((TPL_DESC_ELSE*)ptr)->onFalsePos;
		} else {
			ptr = pLines + ((TPL_DESC_ELSE*)ptr)->onTruePos;
			lastCond = 1;
		}
		break;
	
	case TPL_LOOP:
		process_loop(
			(TPL_DESC_LOOP*) ptr, svHtml, pString, pHash, pHash2, pHash3, pLines);
		ptr = pLines + ((TPL_DESC_LOOP*)ptr)->onLoopEndPos + sizeof(TPL_DESC_RB);
		lastCond = 1;
		break;
	
	case TPL_LB:  ptr += sizeof(TPL_DESC_LB); break;
	case TPL_RB:  ptr += sizeof(TPL_DESC_RB); break;
	case TPL_END: lastCond = 1; return;
	}
	}
}

/*-------------------------------------------------------------------- */

void process_replace(TPL_DESC_REPLACE *pDesc,
	SV *svHtml, char *pString, HV *pHash, HV *pHash2, HV *pHash3) {
	
	SV **ppSV, *pSV;
	char *pStr;
	int len;
	
	/* パラメータ値を取得 */
	
	pStr = pString + pDesc->ofsKey; len = strlen(pStr);
	if        (pHash  && (ppSV = hv_fetch(pHash,  pStr, len, 0)) && SvOK(*ppSV)) {
		pStr = SvPV(*ppSV, len);
	} else if (pHash2 && (ppSV = hv_fetch(pHash2, pStr, len, 0)) && SvOK(*ppSV)) {
		pStr = SvPV(*ppSV, len);
	} else if (pHash3 && (ppSV = hv_fetch(pHash3, pStr, len, 0)) && SvOK(*ppSV)) {
		pStr = SvPV(*ppSV, len);
	} else {
		pStr = NULL;
	}
	if (!len || (pStr && *pStr == '\0')) pStr = NULL;
	
	if (pStr) {
		if (pDesc->opt & O_ENCODE) {
			cat_encode(svHtml, pStr, len);
		} else if (pDesc->opt & O_HSCHRS) {
			cat_specialchars(svHtml, pStr, len, pDesc->opt & O_NL2BR);
		} else {
			sv_catpv(svHtml, pStr);
		}
	}
}

/*-------------------------------------------------------------------- */

int process_if(TPL_DESC_IF *pDesc,
	char *pString, HV *pHash, HV *pHash2, HV *pHash3) {
	
	SV **ppSV;
	char *pStr, *pStrSrc, *pStrDst;
	int len;
	uint srcVal, tgtVal;
	
	/* 文字列比較 */
	
	if (pDesc->condType == COND_EQ ||
	    pDesc->condType == COND_NE) {
		
		/* パラメータ値を取得 */
		
		pStr = pString + pDesc->ofsKey; len = strlen(pStr);
		if        (pHash  && (ppSV = hv_fetch(pHash,  pStr, len, 0)) && SvOK(*ppSV)) {
			pStrSrc = SvPV(*ppSV, len);
		} else if (pHash2 && (ppSV = hv_fetch(pHash2, pStr, len, 0)) && SvOK(*ppSV)) {
			pStrSrc = SvPV(*ppSV, len);
		} else if (pHash3 && (ppSV = hv_fetch(pHash3, pStr, len, 0)) && SvOK(*ppSV)) {
			pStrSrc = SvPV(*ppSV, len);
		} else {
			pStrSrc = NULL;
		}
		if (!len || (pStrSrc && *pStrSrc == '\0')) pStrSrc = NULL;
		
		/* 比較値を取得 */
		
		pStrDst = pString + pDesc->ofsVal;
		if (pStrDst && *pStrDst == '\0') {
			pStrDst = NULL;
		}
		
		/* 比較 */
		
		if (pStrSrc == NULL && pStrDst == NULL) {
			return (pDesc->condType == COND_EQ) ? 1 : 0;
		}
		if (pStrSrc == NULL || pStrDst == NULL) {
			return (pDesc->condType != COND_EQ) ? 1 : 0;
		}
		if (strEQ(pStrSrc, pStrDst)) {
			return (pDesc->condType == COND_EQ) ? 1 : 0;
		}
		return (pDesc->condType != COND_EQ);
	}
	
	/* 数値比較 */
	
	if (pDesc->condType == COND_GT ||
	    pDesc->condType == COND_GE ||
	    pDesc->condType == COND_LT ||
	    pDesc->condType == COND_LE) {
		
		/* パラメータ値を取得 */
		
		pStr = pString + pDesc->ofsKey; len = strlen(pStr);
		if        (pHash  && (ppSV = hv_fetch(pHash,  pStr, len, 0)) && SvOK(*ppSV)) {
			srcVal = (uint) SvIV(*ppSV);
		} else if (pHash2 && (ppSV = hv_fetch(pHash2, pStr, len, 0)) && SvOK(*ppSV)) {
			srcVal = (uint) SvIV(*ppSV);
		} else if (pHash3 && (ppSV = hv_fetch(pHash3, pStr, len, 0)) && SvOK(*ppSV)) {
			srcVal = (uint) SvIV(*ppSV);
		} else {
			srcVal = 0;
		}
		
		/* 比較値を取得 */
		
		tgtVal = (uint) pDesc->ofsVal;
		
		/* 比較 */
		
		if (srcVal < tgtVal) {
			return (pDesc->condType == COND_LE ||
			        pDesc->condType == COND_LT) ? 1 : 0;
		}
		if (srcVal > tgtVal) {
			return (pDesc->condType == COND_GE ||
			        pDesc->condType == COND_GT) ? 1 : 0;
		}
		return (pDesc->condType == COND_GE ||
		        pDesc->condType == COND_LE) ? 1 : 0;
	}
	return(0); /* dummy */
}

/*-------------------------------------------------------------------- */

void process_loop(TPL_DESC_LOOP *pDesc,
	SV *svHtml, char* pString, HV *pHash, HV *pHash2, HV *pHash3, void *pLines) {
	
	AV *av;
	HV *hv;
	SV **ppSV, *pSV;
	char *pStr;
	int len, loop_last, i;
	
	/* ループ配列への参照を取得 */
	
	pStr = pString + pDesc->ofsKey; len = strlen(pStr);
	ppSV = hv_fetch(pHash, pStr, len, 0);
	if (!ppSV || !SvROK(*ppSV)) return;
	
	/* ループ配列を取得 */
	
	pSV = SvRV(*ppSV);
	if (SvTYPE(pSV) != SVt_PVAV) return;
	av = (AV*) pSV;
	loop_last = av_len(av);
	
	/* 各ループを処理 */
	
	for (i = 0; i <= loop_last; i++) {
		ppSV = av_fetch(av, i, 0);
		if (ppSV && *ppSV && SvROK(*ppSV) &&
		    SvTYPE(SvRV(*ppSV)) == SVt_PVHV) {
			template_process(svHtml, pLines, pString,
				(HV*) SvRV(*ppSV), pHash2, pHash3,
				((void*) pDesc) + sizeof(TPL_DESC_LOOP));
		}
	}
}

/*---------------------------------------------------------- */

void cat_encode(SV* svHtml, char* in, int len) {
	unsigned char *pi, *po, *out, *tail, c, d, esc;
	SV* sv;
	
	New(0, out, len * 3 + 1, unsigned char);
	po = out;
	pi = in;
	tail = in + len - 1;
	
	while (pi <= tail) {
		c = *pi; pi++;
		if (c >= '0' && c <= '9' ||
		    c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z') {
			*po = c; po++;
		} else {
			*po = '%'; po++;
			*po = (c         >= 0xa0) ?
				((c >>   4) + 'A'-10) : ((c >>   4) | '0'); po++;
			*po = ((c & 0x0f) >= 0x0a) ?
				((c & 0x0f) + 'A'-10) : ((c & 0x0f) | '0'); po++;
		}
	}
	*po = '\0';
	
	sv_catpv(svHtml, out);
	Safefree(out);
}

/*---------------------------------------------------------- */

void cat_specialchars(SV* svHtml, char* in, int len, int f_nl2br) {
	unsigned char *pi, *po, *out, *tail, c;
	int len2, vemoji;
	SV* sv;
	
	pi = in;
	tail = pi + len - 1;
	
	len2 = len;
	while (pi <= tail) {
		switch (*pi) {
		case '>'  : len2 += 3; break;
		case '<'  : len2 += 3; break;
		case '&'  : len2 += 4; break;
		case '"'  : len2 += 5; break;
		case '\n' :
			if (f_nl2br) len2 += 5;
			break;
		}
		pi++;
	}
	if (len == len2) {
		sv_catpv(svHtml, in);
		return;
	}
	
	New(0, out, len2 + 1, char);
	po = out;
	
	vemoji = 0;
	pi = in;
	while (pi <= tail) {
		c = *pi; pi++;
		
		if (vemoji) {
			if (vemoji <= 2) {
				vemoji--;
				*po = c; po++; continue;
			} else if (vemoji == 3) {
				if (c == 0x24) {
					vemoji = 4;
					*po = c; po++; continue;
				} else {
					vemoji = 0;
				}
			} else if (vemoji == 4) {
				if (c == 0x0f) vemoji = 0;
				*po = c; po++; continue;
			}
		}
		switch (c) {
		case 0x0b : vemoji = 2; *po = c; po++; break;
		case 0x1b : vemoji = 3; *po = c; po++; break;
		case '>'  :
			*po = '&'; po++; *po = 'g'; po++;
			*po = 't'; po++; *po = ';'; po++;
			break;
		case '<'  :
			*po = '&'; po++; *po = 'l'; po++;
			*po = 't'; po++; *po = ';'; po++;
			break;
		case '&'  :
			*po = '&'; po++; *po = 'a'; po++;
			*po = 'm'; po++; *po = 'p'; po++;
			*po = ';'; po++;
			break;
		case '"'  :
			*po = '&'; po++; *po = 'q'; po++;
			*po = 'u'; po++; *po = 'o'; po++;
			*po = 't'; po++; *po = ';'; po++;
			break;
		case '\n' :
			if (f_nl2br) {
				*po = '<'; po++; *po = 'b'; po++;
				*po = 'r'; po++; *po = ' '; po++;
				*po = '/'; po++; *po = '>'; po++;
			} else {
				*po = '\n'; po++;
			}
			break;
		default:
			*po = c; po++;
		}
	}
	*po = '\0';
	
	sv_catpv(svHtml, out);
	Safefree(out);
}

/*-------------------------------------------------------------------- */

int mmap_file(char* file, char** buf) {
	int len;
	size_t l;
	FILE* fd;
	
	fd = fopen(file, "rb");
	if (fd == NULL) return(0);
	fseek(fd, 0, SEEK_END);
	len = ftell(fd);
	fseek(fd, 0, SEEK_SET);
	
	*buf = (char*) mmap(0, len, PROT_READ, MAP_SHARED, fileno(fd), 0);
	fclose(fd);
	return(len);
}

/*-------------------------------------------------------------------- */

MODULE = MobaSiF::Template PACKAGE = MobaSiF::Template

SV*
insert(file, rHash, rHash2=NULL, rHash3=NULL)
	char* file
	SV*   rHash
	SV*   rHash2
	SV*   rHash3
	CODE:
	RETVAL = template_insert(file, rHash, rHash2, rHash3);
	OUTPUT:
	RETVAL
