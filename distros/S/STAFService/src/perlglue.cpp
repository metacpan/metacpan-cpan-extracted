
#include "perlglue.h"

#define PERL_NO_GET_CONTEXT     /* we want efficiency */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef malloc
#undef free
#define SYNC_DATA_HASH_KEY "STAFServiceSyncData"

struct PerlHolder {
	PerlInterpreter *perl;
	HV *data;
	SV *object;
	char *moduleName;
	SV *delayedAnswerSV;
};

void InitPerlEnviroment() {
	//PERL_SYS_INIT3(&argc,&argv,&env);
	PERL_SYS_INIT3(NULL, NULL, NULL);
}

void DestroyPerlEnviroment() {
	//PERL_SYS_TERM();
}

XS(STAFDelayedAnswerSub) {
	dXSARGS;
	if (items != 3)
		croak("Usage: STAF::DelayedAnswer(requestNumber, return code, answer)");
	SV** syncSV_ref = hv_fetch(PL_modglobal, SYNC_DATA_HASH_KEY, strlen(SYNC_DATA_HASH_KEY), 0);
	if (NULL == syncSV_ref) {
		fprintf(stderr, "DelayedAnswerRequest: Got NULL pointer as SyncData\n");
		croak("DelayedAnswerRequest: Got NULL pointer as SyncData\n");
		XSRETURN_NO;
	}
	SyncData *sd = (SyncData*)SvUV(*syncSV_ref);
	STRLEN len;
	const char *msg = SvPV(ST(2), len);
	PostSingleSyncByID(sd, SvUV(ST(0)), SvUV(ST(1)), msg, len);
	XSRETURN_YES;
}

const char *toChar(STAFString_t source, char **tmpString) {
	if (*tmpString!=NULL) {
		STAFStringFreeBuffer(*tmpString, NULL);
		*tmpString = NULL;
	}
	if (source==NULL)
		return NULL;
	unsigned int len;
	STAFRC_t ret;
	ret = STAFStringToCurrentCodePage(source, tmpString, &len, NULL);
	if (ret!=kSTAFOk)
		return NULL;
	return *tmpString;
}

void SetErrorBuffer(STAFString_t *pErrorBuffer, const char *err_str, unsigned int len) {
	STAFStringConstruct(pErrorBuffer, err_str, len, NULL);
}

/** my_eval_sv(code)
 ** kinda like eval_sv(), 
 ** but we pop the return value off the stack 
 **/
int my_eval_sv(pTHX_ SV *sv) {
    dSP;
    SV *retval;
    int ret_int;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
    eval_sv(sv, G_SCALAR);     
	SPAGAIN;
    retval = POPs;
    PUTBACK;     
	if (SvTRUE(ERRSV)) {
 		ret_int = 0;
		fprintf(stderr, "Perl Error: %s\n", SvPVX(ERRSV));
	} else {
		ret_int = 1;
	}
    FREETMPS;
    LEAVE;
	return ret_int;
}

STAFRC_t RedirectPerlStdout(PHolder *ph, STAFString_t WriteLocation, STAFString_t ServiceName, unsigned int maxlogs, long maxlogsize, STAFString_t *pErrorBuffer) {
	dTHXa(ph->perl);
	const char *command_fmt = 
		"{; "
		  "my $write_location = '%s';\n"
		  "my $service_name = '%s';\n"
		  "my $maxlogsize = %d;\n"
		  "my $maxlogs = %d;\n"
		  "my $service_module = '%s';\n"
		  "\n"
		  "my $dir = $write_location.'/lang';\n"
		  "mkdir $dir unless -d $dir;\n"
		  "$dir .= '/perl';\n"
		  "mkdir $dir unless -d $dir;\n"
		  "$dir .= '/'.$service_name;\n"
		  "mkdir $dir unless -d $dir;\n"
		  "if ((-e $dir.'/PerlInterpreterLog.1') && (-s $dir.'/PerlInterpreterLog.1' > $maxlogsize)) {\n"
		    "unlink $dir.'/PerlInterpreterLog.'.$maxlogs if -e $dir.'/PerlInterpreterLog.'.$maxlogs;\n"
		    "for (my $ix=$maxlogs-1; $ix>0; $ix++) { \n"
			  "rename($dir.'/PerlInterpreterLog.'.$ix, $dir.'/PerlInterpreterLog.'.($ix+1)) }}\n"
		  // The open uses a global to prevent an error message on service unload
		  "open $STAFSERVICE::_REDIRECT_HANDLE, \">>\", $dir.'/PerlInterpreterLog.1' or die 'Failed to redirect';\n"
		  "select $STAFSERVICE::_REDIRECT_HANDLE;\n"
		  "print '*' x 80, \"\\n\";\n"
		  "print '*** ', scalar(localtime), ' - Start of Log for PerlServiceName: ', $service_name, \"\\n\";\n" 
		  "print '*** PerlService Executable: ', $service_module, \"\\n\";\n"
		  "$|=1;\n"
		"}\n";
	char *write_location = NULL;
	char *service_name = NULL;
	SV *command = newSVpvf(command_fmt, toChar(WriteLocation, &write_location), toChar(ServiceName, &service_name), 
							maxlogsize, maxlogs, ph->moduleName);
	toChar(NULL, &write_location);
	toChar(NULL, &service_name);
	int ret = my_eval_sv(aTHX_ command);
	SvREFCNT_dec(command);
	if (ret == 0) {
		const char *msg = "Error: Redirection failed!";
		SetErrorBuffer(pErrorBuffer, msg, strlen(msg));
		fprintf(stderr, msg);
		return kSTAFUnknownError;
	}
	return kSTAFOk;
}

void my_load_module(pTHX_ const char *module_name) {
	SV *sv_name = newSVpv(module_name, 0);
	load_module(PERL_LOADMOD_NOIMPORT, sv_name, Nullsv);
}

STAFRC_t PreparePerlInterpreter(PHolder *ph, STAFString_t library_name, STAFString_t *pErrorBuffer) {
	char *acsii_name;
	unsigned int i, len, rc;
	dTHXa(ph->perl);
	acsii_name = NULL;

	toChar(library_name, &acsii_name);
	len = strlen(acsii_name);
	for (i=0; i<len; i++) {
		char c = acsii_name[i];
		if (! ( ( c >= 'a' && c <= 'z' ) ||
				( c >= 'A' && c <= 'Z' ) ||
				( c >= '0' && c <= '9' ) ||
				( c == '_' || c == ':')
			  )) {
			toChar(NULL, &acsii_name);
			const char *msg = "Invalid library name";
			SetErrorBuffer(pErrorBuffer, msg, strlen(msg));
			fprintf(stderr, msg);
			return kSTAFUnknownError;
		}
	}
	
	SV *command = newSVpvf("require %s", acsii_name);
	toChar(NULL, &acsii_name);
    dSP;
    eval_sv(command, G_SCALAR);
    SPAGAIN;
    SV *sv = POPs;
    PUTBACK;
	
	if (SvTRUE(ERRSV)) {
		STRLEN len;
		const char *msg = SvPV(ERRSV, len);
		SetErrorBuffer(pErrorBuffer, msg, len);
		fprintf(stderr, "Error: %s", msg);
		rc = kSTAFUnknownError;
	} else {
		rc = kSTAFOk;
	}
	SvREFCNT_dec(command);
	return rc;
}

void storePV2HV(pTHX_ HV *hv, const char *key, const char *value) {
	hv_store(hv, key, strlen(key), newSVpv(value, 0), 0);
}

void storeIV2HV(pTHX_ HV *hv, const char *key, int value) {
	hv_store(hv, key, strlen(key), newSViv(value), 0);
}

void PopulatePerlHolder(PHolder *ph, STAFString_t service_name, STAFString_t library_name, STAFServiceType_t serviceType) {
	dTHXa(ph->perl);
	PERL_SET_CONTEXT(ph->perl);

	char *tmp = NULL;
	ph->object = NULL;
	ph->data = newHV();
	storePV2HV(aTHX_ ph->data, "ServiceName", toChar(service_name, &tmp));
	storeIV2HV(aTHX_ ph->data, "ServiceType", serviceType);

	toChar(library_name, &tmp);
	int len = strlen(tmp);
	ph->moduleName = (char *)malloc(len+1);
	strcpy(ph->moduleName, tmp);
	toChar(NULL, &tmp);
}

EXTERN_C void xs_init(pTHX);

PHolder *CreatePerl(SyncData *syncData) {
	InitPerlEnviroment();
    char *embedding[] = { "", "-e", "0" };
	char *file = __FILE__;

	PHolder *ph = (PHolder*)malloc(sizeof(PHolder));
	if (ph==NULL) return NULL;

    PerlInterpreter *pperl = perl_alloc();
	if (pperl==NULL) return NULL;
	PERL_SET_CONTEXT(pperl);

	dTHXa(pperl);
	PL_perl_destruct_level = 1;
    perl_construct( pperl );
	perl_parse(pperl, xs_init, 3, embedding, NULL);
	
	#ifdef PERL_EXIT_DESTRUCT_END
	// only in Perl 5.8 and up
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
	#endif
    perl_run(pperl);

	newXS("STAF::DelayedAnswer", STAFDelayedAnswerSub, file);

	my_load_module(aTHX_ "lib");
	
	// Preparing the interpreter to threaed resposes. includes:
	// 1. hiding the pointer to the SyncData inside a global hash
	// 2. making a special value $STAF::DelayedAnswer to mark that
	//    the answer will follow later.
	storeIV2HV(aTHX_ PL_modglobal, SYNC_DATA_HASH_KEY, (int)syncData);
	SV *delayAnswerMarker = get_sv("STAF::DelayedAnswer", TRUE);
	sv_setref_uv(delayAnswerMarker, Nullch, 42);
	SV *myNullSv = SvRV(delayAnswerMarker);
	
	ph->perl = pperl;
	ph->delayedAnswerSV = myNullSv;
	return ph;
}

void perl_uselib(PHolder *ph, STAFString_t path) {
	dTHXa(ph->perl);
	PERL_SET_CONTEXT(ph->perl);
	char *tmp = NULL;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv("lib", 0)));
	XPUSHs(sv_2mortal(newSVpv(toChar(path, &tmp), 0)));
	PUTBACK;
    call_method("import", G_DISCARD | G_EVAL);

    FREETMPS;
    LEAVE;
	toChar(NULL, &tmp);
}

SV *call_new(pTHX_ char *module_name, HV *hv, STAFString_t *pErrorBuffer) {
	SV *ret = NULL;
	int count;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(module_name, 0)));
	XPUSHs(sv_2mortal(newRV_inc((SV*)hv)));
	PUTBACK;
    count = call_method("new", G_SCALAR | G_EVAL);
    SPAGAIN;
	ret = POPs;
	if (SvTRUE(ERRSV)) {
		// There was an error
		STRLEN len;
		const char *msg = SvPV(ERRSV, len);
		SetErrorBuffer(pErrorBuffer, msg, len);
		ret = NULL;
    } else {
		if (!SvOK(ret)) {
			// undefined result?!
			const char *msg = "Unexpected Result Returned!";
			SetErrorBuffer(pErrorBuffer, msg, strlen(msg));
			ret = NULL;
		} else if (!sv_isobject(ret)) {
			// Not an object
			STRLEN len;
			const char *msg = SvPV(ret, len);
			SetErrorBuffer(pErrorBuffer, msg, len);
			ret = NULL;
		} else {
			SvREFCNT_inc(ret);
		}
    }
    FREETMPS;
    LEAVE;
    return ret;
}

STAFRC_t InitService(PHolder *ph, STAFString_t parms, STAFString_t writeLocation, STAFString_t *pErrorBuffer) {
	dTHXa(ph->perl);
	PERL_SET_CONTEXT(ph->perl);
	char *tmp = NULL;
	storePV2HV(aTHX_ ph->data, "WriteLocation", toChar(writeLocation, &tmp));
	storePV2HV(aTHX_ ph->data, "Params", toChar(parms, &tmp));
	SV *object = call_new(aTHX_ ph->moduleName, ph->data, pErrorBuffer);
	toChar(NULL, &tmp);
	if (object==NULL)
		return kSTAFUnknownError;
	ph->object = object;
	return kSTAFOk;
}

STAFRC_t call_accept_request(pTHX_ SV *obj, SV *hash_ref, STAFString_t *pResultBuffer, SV *marker) {
	STAFRC_t ret_code = kSTAFOk;
	int count;
	I32 ax;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(obj);
	XPUSHs(hash_ref);
	PUTBACK;
    count = call_method("AcceptRequest", G_ARRAY | G_EVAL);
    SPAGAIN;
	SP -= count;
    ax = (SP - PL_stack_base) + 1;

	if (SvTRUE(ERRSV)) {
		// There was an error
		STRLEN len;
		const char *msg = SvPV(ERRSV, len);
		SetErrorBuffer(pResultBuffer, msg, len);
		ret_code = kSTAFUnknownError;
    } else if (count!=2) {
		// The call ended successed but did not return two items!
		if (count==1 && SvROK(ST(0)) && SvRV(ST(0)) == marker) {
			// a delayed answer.
			ret_code = 77;
			*pResultBuffer = NULL;
		} else {
			const char *msg = "AcceptRequest did not return two items";
			SetErrorBuffer(pResultBuffer, msg, strlen(msg));
			ret_code = kSTAFUnknownError;
		}
	} else {
		ret_code = SvIV(ST(0));
		STRLEN len;
		const char *msg = SvPV(ST(1), len);
		SetErrorBuffer(pResultBuffer, msg, len);
	}
    FREETMPS;
    LEAVE;
    return ret_code;
}

HV *ConvertRequestStruct(pTHX_ struct STAFServiceRequestLevel30 *request) {
	HV *ret = newHV();
	char *tmp = NULL;
	storePV2HV(aTHX_ ret, "stafInstanceUUID",	toChar(request->stafInstanceUUID, &tmp));
	storePV2HV(aTHX_ ret, "machine",			toChar(request->machine, &tmp));
	storePV2HV(aTHX_ ret, "machineNickname",	toChar(request->machineNickname, &tmp));
	storePV2HV(aTHX_ ret, "handleName",			toChar(request->handleName, &tmp));
	storePV2HV(aTHX_ ret, "request",			toChar(request->request, &tmp));
	storePV2HV(aTHX_ ret, "user",				toChar(request->user, &tmp));
	storePV2HV(aTHX_ ret, "endpoint",			toChar(request->endpoint, &tmp));
	storePV2HV(aTHX_ ret, "physicalInterfaceID",toChar(request->physicalInterfaceID, &tmp));
	storeIV2HV(aTHX_ ret, "trustLevel",			request->trustLevel); 
	storeIV2HV(aTHX_ ret, "isLocalRequest",		request->isLocalRequest); 
	storeIV2HV(aTHX_ ret, "diagEnabled",		request->diagEnabled); 
	storeIV2HV(aTHX_ ret, "trustLevel",			request->trustLevel); 
	storeIV2HV(aTHX_ ret, "requestNumber",		request->requestNumber); 
	storeIV2HV(aTHX_ ret, "handle",				request->handle);
	toChar(NULL, &tmp);
	return ret;
}

STAFRC_t ServeRequest(PHolder *ph, struct STAFServiceRequestLevel30 *request, STAFString_t *pResultBuffer) {
	dTHXa(ph->perl);
	PERL_SET_CONTEXT(ph->perl);
	HV *params = ConvertRequestStruct(aTHX_ request);
	SV *params_ref = newRV_noinc((SV*)params);
	STAFRC_t ret = call_accept_request(aTHX_ ph->object, params_ref, pResultBuffer, ph->delayedAnswerSV);
	SvREFCNT_dec(params_ref);
	return ret;
}

STAFRC_t Terminate(PHolder *ph) {
	dTHXa(ph->perl);
	PERL_SET_CONTEXT(ph->perl);
	if (ph->data!=NULL) {
		SvREFCNT_dec(ph->data);
		ph->data = NULL;
	}
	if (ph->object!=NULL) {
		SvREFCNT_dec(ph->object);
		ph->object = NULL;
	}
	return kSTAFOk;
}

STAFRC_t DestroyPerl(PHolder *ph) {
	PerlInterpreter *pperl = ph->perl;
	free(ph->moduleName);
	free(ph);
	dTHXa(pperl);
	PERL_SET_CONTEXT(pperl);
	PL_perl_destruct_level = 1;
	perl_destruct(pperl);
    perl_free(pperl);
	DestroyPerlEnviroment();
	return kSTAFOk;
}
