#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <nsCOMPtr.h>
#include <nsIObserver.h>
#include <nsIObserverService.h>
#include <nsIServiceManager.h>
#include <nsServiceManagerUtils.h>
#include <nsIHttpChannel.h>
#include <nsEmbedString.h>
#include <nsIURI.h>

static const char *choose_subject_class(nsISupports *subj
		, const char *topic, void **res) {
	const nsID *id = 0;
	const char *subj_class = 0;

	*res = 0;
	if (!strcmp(topic, "http-on-examine-response")
			|| !strcmp(topic, "http-on-modify-request")) {
		id = &NS_GET_IID(nsIHttpChannel);
		subj_class = "Mozilla::ObserverService::nsIHttpChannel";
	}

	if (id)
		subj->QueryInterface(*id, res);

	return *res ? subj_class : 0;
}

static SV *wrap_subject(void *subj, const char *subj_class) {
	SV *obj_ref;
	SV *obj;

	obj_ref = newSViv(0);
	obj = newSVrv(obj_ref, subj_class);
	sv_setiv(obj, (IV) subj);
	SvREADONLY_on(obj);
	return obj_ref;
}

class MyObserver : public nsIObserver {
public:
	NS_DECL_ISUPPORTS
	NS_DECL_NSIOBSERVER

	SV *callbacks_;
};

static void remove_callback(nsIObserverService *os, MyObserver *obs
			, const char *key) {
	os->RemoveObserver(obs, key);
}

static void add_callback(nsIObserverService *os, MyObserver *obs
			, const char *key) {
	os->AddObserver(obs, key, PR_FALSE);
}

static int for_each_callback_do(SV *cbs, MyObserver *obs, void (*func) (
			nsIObserverService *os, MyObserver *obs
			, const char *key)) {
	nsCOMPtr<nsIObserverService> os;
	nsresult rv;
	const char *key;
	I32 klen;
	HV *hv;

	os = do_GetService("@mozilla.org/observer-service;1", &rv);
	if (NS_FAILED(rv))
		return rv;

	hv = (HV*) SvRV(cbs);
	hv_iterinit(hv);
	while (hv_iternextsv(hv, (char **) &key, &klen))
		func(os, obs, key);
	return rv;
}

NS_IMPL_ISUPPORTS1(MyObserver, nsIObserver)

NS_IMETHODIMP MyObserver::Observe(nsISupports *aSubject
		, const char *aTopic, const PRUnichar *aData)
{
	dSP;
	SV **cb;
	const char *subj_class;
	void *subj;

	cb = hv_fetch((HV *) SvRV(this->callbacks_)
			, aTopic, strlen(aTopic), FALSE);
	if (!cb)
		goto out;

	subj_class = choose_subject_class(aSubject, aTopic, &subj);

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	if (subj_class) {
		XPUSHs(sv_2mortal(wrap_subject(subj, subj_class)));
	}

	PUTBACK;
	call_sv(*cb, G_DISCARD);
out:
	return NS_OK;
}

MODULE = Mozilla::ObserverService	PACKAGE = Mozilla::ObserverService::nsIHttpChannel

unsigned int responseStatus(SV *obj)
	PREINIT:
		PRUint32 res;
	CODE:
		((nsIHttpChannel *) SvIV(SvRV(obj)))->GetResponseStatus(&res);
		RETVAL = res;
	OUTPUT:
		RETVAL

const char *uri(SV *obj)
	PREINIT:
		nsEmbedCString pre;
		nsEmbedCString path;
		nsCOMPtr<nsIURI> uri;
		nsresult rv;
		char res[1024];
	CODE:
		rv = ((nsIHttpChannel *) SvIV(SvRV(obj)))->GetURI(getter_AddRefs(uri));
		if (NS_FAILED(rv) || !uri)
			XSRETURN_UNDEF;

		rv = uri->GetPrePath(pre);
		if (NS_FAILED(rv))
			XSRETURN_UNDEF;
		rv = uri->GetPath(path);
		if (NS_FAILED(rv))
			XSRETURN_UNDEF;
		snprintf(res, sizeof(res), "%s%s", pre.get(), path.get());
		RETVAL = res;
	OUTPUT:
		RETVAL

MODULE = Mozilla::ObserverService		PACKAGE = Mozilla::ObserverService		

void *
Register(cbs)
	SV *cbs;
	INIT:
		nsresult rv;
		MyObserver *obs = 0;
		nsCOMPtr<nsIObserverService> os;
	CODE:
		obs = new MyObserver;
		if (!obs)
			XSRETURN_UNDEF;

		rv = for_each_callback_do(cbs, obs, add_callback);
		if (NS_FAILED(rv)) {
			delete obs;
			XSRETURN_UNDEF;
		}
		obs->callbacks_ = newSVsv(cbs);
out_retval:
		RETVAL = obs;
	OUTPUT:
		RETVAL

int 
Unregister(o_ptr)
	void *o_ptr;
	INIT:
		MyObserver *obs;
	CODE:
		obs = (MyObserver *) o_ptr;
		RETVAL = for_each_callback_do(obs->callbacks_, obs
			 	, remove_callback);
	OUTPUT:
		RETVAL

