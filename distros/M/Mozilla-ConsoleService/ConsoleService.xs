#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <nsCOMPtr.h>
#include <nsIConsoleService.h>
#include <nsIConsoleListener.h>
#include <nsIConsoleMessage.h>
#include <nsIScriptError.h>
#include <nsIServiceManager.h>
#include <nsEmbedString.h>
#include <nsServiceManagerUtils.h>
#include "build/version.h"

#if MCS_MOZEMBED_VERSION < 1900
#define GetMessageMoz GetMessage
#endif /* MCS_MOZEMBED_VERSION */

static SV *wrap_unichar_string(const PRUnichar *uni_str) {
	nsEmbedString utf8;
	nsEmbedCString u8c;
	const char * u8str;

	utf8 = uni_str;
	NS_UTF16ToCString(utf8, NS_CSTRING_ENCODING_UTF8, u8c);

	u8str = u8c.get();
	return newSVpv(u8str, 0);
}

class MyListener : public nsIConsoleListener {
public:
	NS_DECL_ISUPPORTS
	NS_DECL_NSICONSOLELISTENER

	SV *callback_;
};

NS_IMPL_ISUPPORTS1(MyListener, nsIConsoleListener)

NS_IMETHODIMP MyListener::Observe(nsIConsoleMessage *msg) {
	dSP;
	PRUnichar *str;
	nsresult rv;
	const nsID id = NS_GET_IID(nsIScriptError);
	nsIScriptError *se = 0;
	SV *psv;
	nsEmbedCString u8c;

	msg->QueryInterface(id, (void **) &se);
	rv = se ? se->ToString(u8c) : msg->GetMessageMoz(&str);
	if (NS_FAILED(rv))
		goto out;

	if (u8c.get()) {
		psv = newSVpv(u8c.get(), 0);
	} else
		psv = wrap_unichar_string(str);


	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(psv));
	PUTBACK;
	call_sv(this->callback_, G_DISCARD);
out:
	return rv;
}

MODULE = Mozilla::ConsoleService		PACKAGE = Mozilla::ConsoleService		

SV *Register(cb)
	SV *cb;
	INIT:
		nsresult rv;
		nsCOMPtr<nsIConsoleService> os;
		nsCOMPtr<MyListener> lis;
	CODE:
		rv = !NS_OK;
		lis = new MyListener;
		if (!lis)
			goto out_retval;

		os = do_GetService("@mozilla.org/consoleservice;1", &rv);
		if (NS_FAILED(rv))
			goto out_retval;

		rv = os->RegisterListener(lis);
		if (NS_FAILED(rv))
			goto out_retval;

		lis->callback_ = newSVsv(cb);
out_retval:
		RETVAL = (rv == NS_OK) ? newSViv((IV) lis.get()) : NULL;
	OUTPUT:
		RETVAL

void Unregister(SV *handle)
	INIT:
		nsresult rv;
		nsCOMPtr<nsIConsoleService> os;
	CODE:
		os = do_GetService("@mozilla.org/consoleservice;1", &rv);
		os->UnregisterListener((MyListener *) SvIV(handle));

