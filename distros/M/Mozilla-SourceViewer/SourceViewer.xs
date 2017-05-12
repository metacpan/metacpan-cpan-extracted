#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <nsCOMPtr.h>
#include <gtkmozembed2perl.h>
#include <nsIWebProgressListener.h>
#include <nsStringAPI.h>
#include <nsCRT.h>
#include <nsIWebBrowserPersist.h>
#include <nsILocalFile.h>
#include <nsIInputStream.h>
#include <nsIWebNavigation.h>
#include <nsISHistory.h>
#include <nsIHistoryEntry.h>
#include <nsISHEntry.h>

class PListener : public nsIWebProgressListener
{
public:
    PListener() : starts_(0), started_(0) {}
    
    NS_DECL_ISUPPORTS
    NS_DECL_NSIWEBPROGRESSLISTENER

	/* There is one start more than stop */
	int is_loading() const { return !this->started_ || this->starts_ > 1; }

private:
    int starts_;
    int started_;
};

NS_IMPL_ISUPPORTS1(PListener, nsIWebProgressListener)

NS_IMETHODIMP
PListener::OnStateChange(nsIWebProgress *aWebProgress,
			     nsIRequest     *aRequest,
			     PRUint32        flags,
			     nsresult        aStatus)
{
	this->started_ = 1;
	/*
	fprintf(stderr, "# %p OnStateChange: %x %d %d %d %d %d\n"
		, this, flags, flags & STATE_START, flags & STATE_STOP
		, this->starts_
		, !!(flags & STATE_IS_REQUEST)
		, !!(flags & STATE_IS_DOCUMENT));
	*/

	if (flags & STATE_START)
		this->starts_++;

	if (flags & STATE_STOP)
		this->starts_--;
	return NS_OK;
}

NS_IMETHODIMP
PListener::OnProgressChange(nsIWebProgress *aWebProgress,
				nsIRequest     *aRequest,
				PRInt32         aCurSelfProgress,
				PRInt32         aMaxSelfProgress,
				PRInt32         aCurTotalProgress,
				PRInt32         aMaxTotalProgress)
{
    return NS_OK;
}

NS_IMETHODIMP
PListener::OnLocationChange(nsIWebProgress *aWebProgress,
				nsIRequest     *aRequest,
				nsIURI         *aLocation)
{
    return NS_OK;
}



NS_IMETHODIMP
PListener::OnStatusChange(nsIWebProgress  *aWebProgress,
			      nsIRequest      *aRequest,
			      nsresult         aStatus,
			      const PRUnichar *aMessage)
{
    return NS_OK;
}



NS_IMETHODIMP
PListener::OnSecurityChange(nsIWebProgress *aWebProgress,
				nsIRequest     *aRequest,
				PRUint32         aState)
{
    return NS_OK;
}

MODULE = Mozilla::SourceViewer		PACKAGE = Mozilla::SourceViewer		

## Temporary - till it is fixed in Mozilla::DOM
void
Scroll_To (window, xScroll, yScroll)
	nsIDOMWindow *window;
	PRInt32 xScroll;
	PRInt32 yScroll;
    CODE:
	window->ScrollTo(xScroll, yScroll);
 
void
Get_Page_Source_Into_File(me, path)
	GtkMozEmbed *me;
	nsEmbedCString path;
	CODE:
		nsCOMPtr<nsIWebBrowser> bro;
		nsCOMPtr<nsIWebBrowserPersist> persist;
		nsCOMPtr<nsILocalFile> file;
		PListener *plis;
		nsCOMPtr<nsIWebProgressListener> lis;

		plis = new PListener;
		lis = static_cast<nsIWebProgressListener *>(plis);

		gtk_moz_embed_get_nsIWebBrowser(me, getter_AddRefs(bro));
		assert(bro);

		persist = do_QueryInterface(bro);
		assert(persist);

		persist->SetPersistFlags(
			nsIWebBrowserPersist::PERSIST_FLAGS_FROM_CACHE);
		NS_NewNativeLocalFile(path, TRUE, getter_AddRefs(file));
		persist->SetProgressListener(lis);

		nsCOMPtr<nsIInputStream> pdata;
		nsCOMPtr<nsIWebNavigation> wn(do_QueryInterface(bro));
		nsCOMPtr<nsISHistory> shist;
		wn->GetSessionHistory(getter_AddRefs(shist));
		nsCOMPtr<nsIHistoryEntry> he;
		PRInt32 sind;
		shist->GetIndex(&sind);
		shist->GetEntryAtIndex(sind, PR_FALSE , getter_AddRefs(he));
		nsCOMPtr<nsISHEntry> she(do_QueryInterface(he));
		if (she)
			she->GetPostData(getter_AddRefs(pdata));

		/*
		fprintf(stderr, "# SaveURI %p %d\n", plis, plis->is_loading());
		*/
                persist->SaveURI(nsnull, nsnull, nsnull, pdata, nsnull, file);
		do {
			while(gtk_events_pending()) {
				gtk_main_iteration();
			}
		} while (plis->is_loading());

