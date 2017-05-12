/*
 * Copyright (C) 2005-2007 by Scott Lanning
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $CVSHeader: Mozilla-DOM/xs/DOM.xs,v 1.24 2007-06-06 21:47:36 slanning Exp $
 */

#include "mozilladom2perl.h"

/* ------------------------------------------------------------------------- */

/* conversion functions between Perl and C */

MOZDOM_DEF_I_TYPEMAPPERS(WebBrowser)
MOZDOM_DEF_I_TYPEMAPPERS(WebNavigation)
MOZDOM_DEF_I_TYPEMAPPERS(URI)
MOZDOM_DEF_I_TYPEMAPPERS(Selection)
MOZDOM_DEF_I_TYPEMAPPERS(Supports)

MOZDOM_DEF_DOM_TYPEMAPPERS(AbstractView)
MOZDOM_DEF_DOM_TYPEMAPPERS(DocumentView)
MOZDOM_DEF_DOM_TYPEMAPPERS(Event)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSEvent)
MOZDOM_DEF_DOM_TYPEMAPPERS(UIEvent)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSUIEvent)
MOZDOM_DEF_DOM_TYPEMAPPERS(DocumentEvent)
MOZDOM_DEF_DOM_TYPEMAPPERS(MutationEvent)
MOZDOM_DEF_DOM_TYPEMAPPERS(KeyEvent)
MOZDOM_DEF_DOM_TYPEMAPPERS(MouseEvent)
MOZDOM_DEF_DOM_TYPEMAPPERS(EventTarget)
MOZDOM_DEF_DOM_TYPEMAPPERS(EventListener)
MOZDOM_DEF_DOM_TYPEMAPPERS(Window)
MOZDOM_DEF_DOM_TYPEMAPPERS(Window2)
MOZDOM_DEF_DOM_TYPEMAPPERS(WindowInternal)
MOZDOM_DEF_DOM_TYPEMAPPERS(WindowCollection)
MOZDOM_DEF_DOM_TYPEMAPPERS(Document)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSDocument)
MOZDOM_DEF_DOM_TYPEMAPPERS(DocumentFragment)
MOZDOM_DEF_DOM_TYPEMAPPERS(DocumentRange)
MOZDOM_DEF_DOM_TYPEMAPPERS(DocumentType)
MOZDOM_DEF_DOM_TYPEMAPPERS(DOMException)
MOZDOM_DEF_DOM_TYPEMAPPERS(Node)
MOZDOM_DEF_DOM_TYPEMAPPERS(NodeList)
MOZDOM_DEF_DOM_TYPEMAPPERS(NamedNodeMap)
MOZDOM_DEF_DOM_TYPEMAPPERS(Element)
MOZDOM_DEF_DOM_TYPEMAPPERS(Entity)
MOZDOM_DEF_DOM_TYPEMAPPERS(EntityReference)
MOZDOM_DEF_DOM_TYPEMAPPERS(Attr)
MOZDOM_DEF_DOM_TYPEMAPPERS(Notation)
MOZDOM_DEF_DOM_TYPEMAPPERS(ProcessingInstruction)
MOZDOM_DEF_DOM_TYPEMAPPERS(CDATASection)
MOZDOM_DEF_DOM_TYPEMAPPERS(Comment)
MOZDOM_DEF_DOM_TYPEMAPPERS(CharacterData)
MOZDOM_DEF_DOM_TYPEMAPPERS(Text)
MOZDOM_DEF_DOM_TYPEMAPPERS(DOMImplementation)
MOZDOM_DEF_DOM_TYPEMAPPERS(Range)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSRange)
MOZDOM_DEF_DOM_TYPEMAPPERS(History)
MOZDOM_DEF_DOM_TYPEMAPPERS(Location)
MOZDOM_DEF_DOM_TYPEMAPPERS(Navigator)
MOZDOM_DEF_DOM_TYPEMAPPERS(Screen)

MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLAnchorElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLAnchorElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLAreaElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLAreaElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLAppletElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLBRElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLBaseElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLBaseFontElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLBodyElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLButtonElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLButtonElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLCollection)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLDListElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLDirectoryElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLDivElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLDocument)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLEmbedElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLFieldSetElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLFontElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLFormElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLFormElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLFrameElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLFrameElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLFrameSetElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLHRElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLHRElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLHeadElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLHeadingElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLHtmlElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLIFrameElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLImageElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLImageElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLInputElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLInputElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLIsIndexElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLLIElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLLabelElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLLegendElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLLinkElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLMapElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLMenuElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLMetaElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLModElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLOListElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLObjectElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLOptGroupElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLOptionElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLOptionElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLOptionsCollection)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLParagraphElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLParamElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLPreElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLQuoteElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLScriptElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLSelectElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLSelectElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLStyleElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTableCaptionElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTableCellElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTableColElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTableElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTableRowElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTableSectionElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTextAreaElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(NSHTMLTextAreaElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLTitleElement)
MOZDOM_DEF_DOM_TYPEMAPPERS(HTMLUListElement)


/* ------------------------------------------------------------------------- */

/* I'm not a C++ or XS whiz, so let me know if I'm doing something stupid.
   Support for this is "experimental". It will only be enabled if you
   do `perl Makefile.PL DEFINE=MDEXP_EVENT_LISTENER`. */

#ifdef MDEXP_EVENT_LISTENER

NS_IMPL_ISUPPORTS1(MozDomEventListener, nsIDOMEventListener)

MozDomEventListener::MozDomEventListener()
{
	return;
}

MozDomEventListener::MozDomEventListener(SV *handler)
	: mHandler(newSVsv(handler))
{
	return;
}

MozDomEventListener::~MozDomEventListener()
{
	/* XXX: do we need sv_free(mHandler) or SvREFCNT ? */
	return;
}

NS_IMETHODIMP MozDomEventListener::HandleEvent(nsIDOMEvent *event) {
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVnsIDOMEvent(event)));
	PUTBACK;

	/* call the subroutine passed to `new' */
	call_sv(mHandler, G_DISCARD);

	FREETMPS;
	LEAVE;
}

#endif /* MDEXP_EVENT_LISTENER */

/* ------------------------------------------------------------------------- */

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::AbstractView	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMAbstractView.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMABSTRACTVIEW_IID)
static nsIID
nsIDOMAbstractView::GetIID()
    CODE:
	const nsIID &id = nsIDOMAbstractView::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDocument(nsIDOMDocumentView * *aDocument)
nsIDOMDocumentView *
moz_dom_GetDocument (view)
	nsIDOMAbstractView *view;
    PREINIT:
	nsIDOMDocumentView *docview;
    CODE:
	view->GetDocument(&docview);
	RETVAL = docview;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::DocumentView	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDocumentView.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOCUMENTVIEW_IID)
static nsIID
nsIDOMDocumentView::GetIID()
    CODE:
	const nsIID &id = nsIDOMDocumentView::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDefaultView(nsIDOMAbstractView * *aDefaultView);
nsIDOMAbstractView *
moz_dom_GetDefaultView (docview)
	nsIDOMDocumentView *docview;
    PREINIT:
	nsIDOMAbstractView *view;
    CODE:
	docview->GetDefaultView(&view);
	RETVAL = view;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Event	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMEVENT_IID)
static nsIID
nsIDOMEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (event)
	nsIDOMEvent *event;
    PREINIT:
	nsEmbedString type;
    CODE:
	event->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## GetTarget(nsIDOMEventTarget * *aTarget), etc.
nsIDOMEventTarget *
moz_dom_GetTarget (event)
	nsIDOMEvent *event
    ALIAS:
	Mozilla::DOM::Event::GetCurrentTarget = 1
    PREINIT:
	nsIDOMEventTarget *target;
    CODE:
	switch (ix) {
		case 0: event->GetTarget(&target); break;
		case 1: event->GetCurrentTarget(&target); break;
		default: XSRETURN_UNDEF;
	}
	RETVAL = target;
    OUTPUT:
	RETVAL

## GetEventPhase(PRUint16 *aEventPhase)
PRUint16
moz_dom_GetEventPhase (event)
	nsIDOMEvent *event;
    PREINIT:
	PRUint16 phase;
    CODE:
	event->GetEventPhase(&phase);
	RETVAL = phase;
    OUTPUT:
	RETVAL

## GetBubbles(PRBool *aBubbles), etc.
PRBool
moz_dom_GetBubbles (event)
	nsIDOMEvent *event;
    ALIAS:
	Mozilla::DOM::Event::GetCancelable = 1
    PREINIT:
	PRBool can;
    CODE:
	switch (ix) {
		case 0: event->GetBubbles(&can); break;
		case 1: event->GetCancelable(&can); break;
		default: can = 0;
	}
	RETVAL = can;
    OUTPUT:
	RETVAL

## GetTimeStamp(DOMTimeStamp *aTimeStamp)
DOMTimeStamp
moz_dom_GetTimeStamp (event)
	nsIDOMEvent *event;
    PREINIT:
	DOMTimeStamp ts;
    CODE:
	event->GetTimeStamp(&ts);
	RETVAL = ts;
    OUTPUT:
	RETVAL

## StopPropagation(void), etc.
void
moz_dom_StopPropagation (event)
	nsIDOMEvent *event;
    ALIAS:
	Mozilla::DOM::Event::PreventDefault = 1
    CODE:
	switch (ix) {
		case 0: event->StopPropagation(); break;
		case 1: event->PreventDefault(); break;
		default: break;
	}

## InitEvent(const nsAString & eventTypeArg, PRBool canBubbleArg, PRBool cancelableArg)
void
moz_dom_InitEvent (event, eventtype, canbubble, cancelable)
	nsIDOMEvent *event;
	nsEmbedString eventtype;
	PRBool canbubble;
	PRBool cancelable;
    CODE:
	/* XXX: this can throw an exception, so should check... */
	event->InitEvent(eventtype, canbubble, cancelable);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSEvent	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSEVENT_IID)
static nsIID
nsIDOMNSEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetOriginalTarget(nsIDOMEventTarget * *aOriginalTarget)
nsIDOMEventTarget *
moz_dom_GetOriginalTarget (nsevent)
	nsIDOMNSEvent *nsevent;
    PREINIT:
	nsIDOMEventTarget * aOriginalTarget;
    CODE:
	nsevent->GetOriginalTarget(&aOriginalTarget);
	RETVAL = aOriginalTarget;
    OUTPUT:
	RETVAL

## GetExplicitOriginalTarget(nsIDOMEventTarget * *aExplicitOriginalTarget)
nsIDOMEventTarget *
moz_dom_GetExplicitOriginalTarget (nsevent)
	nsIDOMNSEvent *nsevent;
    PREINIT:
	nsIDOMEventTarget * aExplicitOriginalTarget;
    CODE:
	nsevent->GetExplicitOriginalTarget(&aExplicitOriginalTarget);
	RETVAL = aExplicitOriginalTarget;
    OUTPUT:
	RETVAL

## GetTmpRealOriginalTarget(nsIDOMEventTarget * *aTmpRealOriginalTarget)
nsIDOMEventTarget *
moz_dom_GetTmpRealOriginalTarget (nsevent)
	nsIDOMNSEvent *nsevent;
    PREINIT:
	nsIDOMEventTarget * aTmpRealOriginalTarget;
    CODE:
	nsevent->GetTmpRealOriginalTarget(&aTmpRealOriginalTarget);
	RETVAL = aTmpRealOriginalTarget;
    OUTPUT:
	RETVAL

## PreventBubble(void)
void
moz_dom_PreventBubble (nsevent)
	nsIDOMNSEvent *nsevent;
    CODE:
	nsevent->PreventBubble();

## PreventCapture(void)
void
moz_dom_PreventCapture (nsevent)
	nsIDOMNSEvent *nsevent;
    CODE:
	nsevent->PreventCapture();

## GetIsTrusted(PRBool *aIsTrusted)
PRBool
moz_dom_GetIsTrusted (nsevent)
	nsIDOMNSEvent *nsevent;
    PREINIT:
	PRBool aIsTrusted;
    CODE:
	nsevent->GetIsTrusted(&aIsTrusted);
	RETVAL = aIsTrusted;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::UIEvent	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMUIEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMUIEVENT_IID)
static nsIID
nsIDOMUIEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMUIEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDetail(PRInt32 *aDetail)
PRInt32
moz_dom_GetDetail (event)
	nsIDOMUIEvent *event;
    PREINIT:
	PRInt32 detail;
    CODE:
	event->GetDetail(&detail);
	RETVAL = detail;
    OUTPUT:
	RETVAL

## GetView(nsIDOMAbstractView * *aView)
nsIDOMAbstractView *
moz_dom_GetView (event)
	nsIDOMUIEvent *event;
    PREINIT:
	nsIDOMAbstractView *view;
    CODE:
	event->GetView(&view);
	RETVAL = view;
    OUTPUT:
	RETVAL

## InitUIEvent(const nsAString & typeArg, PRBool canBubbleArg, PRBool cancelableArg, nsIDOMAbstractView *viewArg, PRInt32 detailArg)
void
moz_dom_InitUIEvent (event, eventtype, canbubble, cancelable, detail)
	nsIDOMUIEvent *event;
	nsEmbedString eventtype;
	PRBool canbubble;
	PRBool cancelable;
	PRInt32 detail;
    CODE:
	event->InitUIEvent(eventtype, canbubble, cancelable, nsnull, detail);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSUIEvent	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSUIEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSUIEVENT_IID)
static nsIID
nsIDOMNSUIEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSUIEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetPreventDefault(PRBool *_retval)
PRBool
moz_dom_GetPreventDefault (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRBool _retval;
    CODE:
	nsuievent->GetPreventDefault(&_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## GetLayerX(PRInt32 *aLayerX)
PRInt32
moz_dom_GetLayerX (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRInt32 aLayerX;
    CODE:
	nsuievent->GetLayerX(&aLayerX);
	RETVAL = aLayerX;
    OUTPUT:
	RETVAL

## GetLayerY(PRInt32 *aLayerY)
PRInt32
moz_dom_GetLayerY (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRInt32 aLayerY;
    CODE:
	nsuievent->GetLayerY(&aLayerY);
	RETVAL = aLayerY;
    OUTPUT:
	RETVAL

## GetPageX(PRInt32 *aPageX)
PRInt32
moz_dom_GetPageX (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRInt32 aPageX;
    CODE:
	nsuievent->GetPageX(&aPageX);
	RETVAL = aPageX;
    OUTPUT:
	RETVAL

## GetPageY(PRInt32 *aPageY)
PRInt32
moz_dom_GetPageY (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRInt32 aPageY;
    CODE:
	nsuievent->GetPageY(&aPageY);
	RETVAL = aPageY;
    OUTPUT:
	RETVAL

## GetWhich(PRUint32 *aWhich)
PRUint32
moz_dom_GetWhich (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRUint32 aWhich;
    CODE:
	nsuievent->GetWhich(&aWhich);
	RETVAL = aWhich;
    OUTPUT:
	RETVAL

## GetRangeParent(nsIDOMNode * *aRangeParent)
nsIDOMNode *
moz_dom_GetRangeParent (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	nsIDOMNode * aRangeParent;
    CODE:
	nsuievent->GetRangeParent(&aRangeParent);
	RETVAL = aRangeParent;
    OUTPUT:
	RETVAL

## GetRangeOffset(PRInt32 *aRangeOffset)
PRInt32
moz_dom_GetRangeOffset (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRInt32 aRangeOffset;
    CODE:
	nsuievent->GetRangeOffset(&aRangeOffset);
	RETVAL = aRangeOffset;
    OUTPUT:
	RETVAL

## GetCancelBubble(PRBool *aCancelBubble)
PRBool
moz_dom_GetCancelBubble (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRBool aCancelBubble;
    CODE:
	nsuievent->GetCancelBubble(&aCancelBubble);
	RETVAL = aCancelBubble;
    OUTPUT:
	RETVAL

## SetCancelBubble(PRBool aCancelBubble)
void
moz_dom_SetCancelBubble (nsuievent, aCancelBubble)
	nsIDOMNSUIEvent *nsuievent;
	PRBool  aCancelBubble;
    CODE:
	nsuievent->SetCancelBubble(aCancelBubble);

## GetIsChar(PRBool *aIsChar)
PRBool
moz_dom_GetIsChar (nsuievent)
	nsIDOMNSUIEvent *nsuievent;
    PREINIT:
	PRBool aIsChar;
    CODE:
	nsuievent->GetIsChar(&aIsChar);
	RETVAL = aIsChar;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::DocumentEvent	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDocumentEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOCUMENTEVENT_IID)
static nsIID
nsIDOMDocumentEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMDocumentEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## CreateEvent(const nsAString & eventType, nsIDOMEvent **_retval)
nsIDOMEvent *
moz_dom_CreateEvent (docevent, eventtype)
	nsIDOMDocumentEvent *docevent;
	nsEmbedString eventtype;
    PREINIT:
	nsIDOMEvent *event;
    CODE:
	/* XXX: this can throw an exception, so should check... */
	docevent->CreateEvent(eventtype, &event);
	RETVAL = event;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::MouseEvent	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMMouseEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMMOUSEEVENT_IID)
static nsIID
nsIDOMMouseEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMMouseEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetScreenX(PRInt32 *aScreenX), etc.
PRInt32
moz_dom_GetScreenX (event)
	nsIDOMMouseEvent *event;
    ALIAS:
	Mozilla::DOM::MouseEvent::GetScreenY = 1
	Mozilla::DOM::MouseEvent::GetClientX = 2
	Mozilla::DOM::MouseEvent::GetClientY = 3
    PREINIT:
	PRInt32 pos;
    CODE:
	switch (ix) {
		case 0: event->GetScreenX(&pos); break;
		case 1: event->GetScreenY(&pos); break;
		case 2: event->GetClientX(&pos); break;
		case 3: event->GetClientY(&pos); break;
		default: pos = 0;
	}
	RETVAL = pos;
    OUTPUT:
	RETVAL

## GetCtrlKey(PRBool *aCtrlKey), etc.
PRBool
moz_dom_GetCtrlKey (event)
	nsIDOMMouseEvent *event;
    ALIAS:
	Mozilla::DOM::MouseEvent::GetShiftKey = 1
	Mozilla::DOM::MouseEvent::GetAltKey = 2
	Mozilla::DOM::MouseEvent::GetMetaKey = 3
    PREINIT:
	PRBool key;
    CODE:
	switch (ix) {
		case 0: event->GetCtrlKey(&key); break;
		case 1: event->GetShiftKey(&key); break;
		case 2: event->GetAltKey(&key); break;
		case 3: event->GetMetaKey(&key); break;
		default: key = 0;
	}
	RETVAL = key;
    OUTPUT:
	RETVAL

## GetButton(PRUint16 *aButton)
PRUint16
moz_dom_GetButton (event)
	nsIDOMMouseEvent *event;
    PREINIT:
	PRUint16 button;
    CODE:
	event->GetButton(&button);
	RETVAL = button;
    OUTPUT:
	RETVAL

## GetRelatedTarget(nsIDOMEventTarget * *aRelatedTarget)
nsIDOMEventTarget *
moz_dom_GetTarget (event)
	nsIDOMMouseEvent *event
    PREINIT:
	nsIDOMEventTarget *target;
    CODE:
	event->GetRelatedTarget(&target);
	RETVAL = target;
    OUTPUT:
	RETVAL

## InitMouseEvent(const nsAString & typeArg, PRBool canBubbleArg, PRBool cancelableArg, nsIDOMAbstractView *viewArg, PRInt32 detailArg, PRInt32 screenXArg, PRInt32 screenYArg, PRInt32 clientXArg, PRInt32 clientYArg, PRBool ctrlKeyArg, PRBool altKeyArg, PRBool shiftKeyArg, PRBool metaKeyArg, PRUint16 buttonArg, nsIDOMEventTarget *relatedTargetArg)
void
moz_dom_InitMouseEvent (event, eventtype, canbubble, cancelable, detail, screenx, screeny, clientx, clienty, ctrlkey, altkey, shiftkey, metakey, button, target)
	nsIDOMMouseEvent *event;
	nsEmbedString eventtype;
	PRBool canbubble;
	PRBool cancelable;
	PRInt32 detail;
	PRInt32 screenx;
	PRInt32 screeny;
	PRInt32 clientx;
	PRInt32 clienty;
	PRBool ctrlkey;
	PRBool altkey;
	PRBool shiftkey;
	PRBool metakey;
	PRUint16 button;
	nsIDOMEventTarget *target;
    CODE:
	event->InitMouseEvent(eventtype, canbubble, cancelable, nsnull, detail,
			      screenx, screeny, clientx, clienty,
			      ctrlkey, altkey, shiftkey, metakey,
 			      button, target);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::KeyEvent	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMKeyEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMKEYEVENT_IID)
static nsIID
nsIDOMKeyEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMKeyEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCharCode(PRUint32 *aCharCode), etc.
PRUint32
moz_dom_GetCharCode (event)
	nsIDOMKeyEvent *event;
    ALIAS:
	Mozilla::DOM::KeyEvent::GetKeyCode = 1
    PREINIT:
	PRUint32 code;
    CODE:
	switch (ix) {
		case 0: event->GetCharCode(&code); break;
		case 1: event->GetKeyCode(&code); break;
		default: code = 0;
	}
	RETVAL = code;
    OUTPUT:
	RETVAL

## GetCtrlKey(PRBool *aCtrlKey), etc.
PRBool
moz_dom_GetCtrlKey (event)
	nsIDOMKeyEvent *event;
    ALIAS:
	Mozilla::DOM::KeyEvent::GetShiftKey = 1
	Mozilla::DOM::KeyEvent::GetAltKey = 2
	Mozilla::DOM::KeyEvent::GetMetaKey = 3
    PREINIT:
	PRBool key;
    CODE:
	switch (ix) {
		case 0: event->GetCtrlKey(&key); break;
		case 1: event->GetShiftKey(&key); break;
		case 2: event->GetAltKey(&key); break;
		case 3: event->GetMetaKey(&key); break;
		default: key = 0;
	}
	RETVAL = key;
    OUTPUT:
	RETVAL

## InitKeyEvent(const nsAString & typeArg, PRBool canBubbleArg, PRBool cancelableArg, nsIDOMAbstractView *viewArg, PRBool ctrlKeyArg, PRBool altKeyArg, PRBool shiftKeyArg, PRBool metaKeyArg, PRUint32 keyCodeArg, PRUint32 charCodeArg)
void
moz_dom_InitKeyEvent (event, eventtype, canbubble, cancelable, ctrlkey, altkey, shiftkey, metakey, keycode, charcode)
	nsIDOMKeyEvent *event;
	nsEmbedString eventtype;
	PRBool canbubble;
	PRBool cancelable;
	PRBool ctrlkey;
	PRBool altkey;
	PRBool shiftkey;
	PRBool metakey;
	PRUint32 keycode;
	PRUint32 charcode;
    CODE:
	event->InitKeyEvent(eventtype, canbubble, cancelable, nsnull,
			    ctrlkey, altkey, shiftkey, metakey,
 			    keycode, charcode);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::MutationEvent	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMMutationEvent.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMMUTATIONEVENT_IID)
static nsIID
nsIDOMMutationEvent::GetIID()
    CODE:
	const nsIID &id = nsIDOMMutationEvent::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetRelatedNode(nsIDOMNode * *aRelatedNode)
nsIDOMNode *
moz_dom_GetRelatedNode (mutationevent)
	nsIDOMMutationEvent *mutationevent;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	mutationevent->GetRelatedNode(&node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetPrevValue(nsAString & aPrevValue)
nsEmbedString
moz_dom_GetPrevValue (mutationevent)
	nsIDOMMutationEvent *mutationevent;
    PREINIT:
	nsEmbedString value;
    CODE:
	mutationevent->GetPrevValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## GetNewValue(nsAString & aNewValue)
nsEmbedString
moz_dom_GetNewValue (mutationevent)
	nsIDOMMutationEvent *mutationevent;
    PREINIT:
	nsEmbedString value;
    CODE:
	mutationevent->GetNewValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## GetAttrName(nsAString & aAttrName)
nsEmbedString
moz_dom_GetAttrName (mutationevent)
	nsIDOMMutationEvent *mutationevent;
    PREINIT:
	nsEmbedString name;
    CODE:
	mutationevent->GetAttrName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## GetAttrChange(PRUint16 *aAttrChange)
PRUint16
moz_dom_GetAttrChange (mutationevent)
	nsIDOMMutationEvent *mutationevent;
    PREINIT:
	PRUint16 change;
    CODE:
	mutationevent->GetAttrChange(&change);
	RETVAL = change;
    OUTPUT:
	RETVAL

## InitMutationEvent(const nsAString & typeArg, PRBool canBubbleArg, PRBool cancelableArg, nsIDOMNode *relatedNodeArg, const nsAString & prevValueArg, const nsAString & newValueArg, const nsAString & attrNameArg, PRUint16 attrChangeArg)
void
moz_dom_InitMutationEvent (event, eventtype, canbubble, cancelable, node, prevval, newval, attrname, attrchange)
	nsIDOMMutationEvent *event;
	nsEmbedString eventtype;
	PRBool canbubble;
	PRBool cancelable;
	nsIDOMNode *node;
	nsEmbedString prevval;
	nsEmbedString newval;
	nsEmbedString attrname;
	PRUint16 attrchange;
    CODE:
	event->InitMutationEvent(eventtype, canbubble, cancelable,
				 node, prevval, newval, attrname, attrchange);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::EventTarget	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMEventTarget.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMEVENTTARGET_IID)
static nsIID
nsIDOMEventTarget::GetIID()
    CODE:
	const nsIID id = nsIDOMEventTarget::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

# INCLUDE: perl -pe 's/XXXXX/DOMEventTarget/g' GetIID.xsh |

#ifdef MDEXP_EVENT_LISTENER

## AddEventListener(const nsAString & type, nsIDOMEventListener *listener, PRBool useCapture)
## RemoveEventListener(const nsAString & type, nsIDOMEventListener *listener, PRBool useCapture)
void
moz_dom_AddEventListener (target, type, listener, usecapture)
	nsIDOMEventTarget *target;
	nsEmbedString type;
	MozDomEventListener *listener;
	PRBool usecapture;
    ALIAS:
	Mozilla::DOM::EventTarget::RemoveEventListener = 1
    CODE:
	switch (ix) {
		case 0:
			/* XXX: here is where we should probably actually create
				the MozDomEventListener */
			target->AddEventListener(type, listener, usecapture);
			break;
		case 1:
			target->RemoveEventListener(type, listener, usecapture);
			/* XXX: here is where we should probably actually destroy
				the MozDomEventListener */
			break;
		default: break;
	}

#endif /* MDEXP_EVENT_LISTENER */

## DispatchEvent(nsIDOMEvent *evt, PRBool *_retval)
PRBool
moz_dom_DispatchEvent (target, event)
	nsIDOMEventTarget *target;
	nsIDOMEvent *event;
    PREINIT:
	PRBool rv;
    CODE:
	target->DispatchEvent(event, &rv);
	RETVAL = rv;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::EventListener	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMEventListener.h

#ifdef MDEXP_EVENT_LISTENER

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMEVENTLISTENER_IID)
static nsIID
nsIDOMEventListener::GetIID()
    CODE:
	const nsIID &id = nsIDOMEventListener::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## See C++ class at the top of this file.
## MozDomEventListner isa nsIDOMEventListener.
MozDomEventListener *
MozDomEventListener::new(handler)
	SV *handler;
    PREINIT:
	MozDomEventListener *listener;
    CODE:
	listener = new MozDomEventListener(handler);
	RETVAL = listener;
    OUTPUT:
	RETVAL

void
MozDomEventListener::DESTROY()

## HandleEvent(nsIDOMEvent *event)
## See the C++ class at the top of this file

#endif /* MDEXP_EVENT_LISTENER */

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Window	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMWindow.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMWINDOW_IID)
static nsIID
nsIDOMWindow::GetIID()
    CODE:
	const nsIID &id = nsIDOMWindow::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (window)
	nsIDOMWindow *window;
    PREINIT:
	nsEmbedString name;
    CODE:
	window->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (window, name)
	nsIDOMWindow *window;
	nsEmbedString name;
    CODE:
	/* XXX: can this thrown an exception? */
	window->SetName(name);

## SizeToContent(void)
void
moz_dom_SizeToContent (window)
	nsIDOMWindow *window;
    CODE:
	window->SizeToContent();

## GetDocument(nsIDOMDocument * *aDocument)
nsIDOMDocument *
moz_dom_GetDocument (window)
	nsIDOMWindow *window;
    PREINIT:
	nsIDOMDocument *doc;
    CODE:
	window->GetDocument(&doc);
	RETVAL = doc;
    OUTPUT:
	RETVAL

## GetFrames(nsIDOMWindowCollection * *aFrames)
nsIDOMWindowCollection *
moz_dom_GetFrames_windowcollection (window)
	nsIDOMWindow *window;
    PREINIT:
	nsIDOMWindowCollection *frames;
    CODE:
	window->GetFrames(&frames);
	RETVAL = frames;
    OUTPUT:
	RETVAL

## GetParent(nsIDOMWindow * *aParent), etc.
nsIDOMWindow *
moz_dom_GetParent (window)
	nsIDOMWindow *window;
    ALIAS:
	Mozilla::DOM::Window::GetTop = 1
    PREINIT:
	nsIDOMWindow *retwindow;
    CODE:
	switch (ix) {
		case 0: window->GetParent(&retwindow); break;
		case 1: window->GetTop(&retwindow); break;
		default: break;
	}
	RETVAL = retwindow;
    OUTPUT:
	RETVAL

## GetTextZoom(float *aTextZoom)
float
moz_dom_GetTextZoom (window)
	nsIDOMWindow *window;
    PREINIT:
	float zoom;
    CODE:
	window->GetTextZoom(&zoom);
	RETVAL = zoom;
    OUTPUT:
	RETVAL

## SetTextZoom(float aTextZoom)
void
moz_dom_SetTextZoom (window, zoom)
	nsIDOMWindow *window;
	float zoom;
    CODE:
	window->SetTextZoom(zoom);

## GetSelection(nsISelection **_retval)
nsISelection *
moz_dom_GetSelection (window)
	nsIDOMWindow *window;
    PREINIT:
	nsISelection *sel;
    CODE:
	window->GetSelection(&sel);
	RETVAL = sel;
    OUTPUT:
	RETVAL

=begin comment

  /**
   * Accessor for the object that controls whether or not scrollbars
   * are shown in this window.
   *
   * This attribute is "replaceable" in JavaScript
   */
  /* readonly attribute nsIDOMBarProp scrollbars; */
#=for apidoc Mozilla::DOM::Window::GetScrollbars
#
#=for signature $window->GetScrollbars(nsIDOMBarProp * *aScrollbars)
#
#
#
#=cut
#
### GetScrollbars(nsIDOMBarProp * *aScrollbars)
#somereturn *
#moz_dom_GetScrollbars (window, aScrollbars)
#	nsIDOMWindow *window;
#	nsIDOMBarProp * *aScrollbars ;
#    PREINIT:
#	
#    CODE:
#	window->GetScrollbars(&);
#	RETVAL = ;
#    OUTPUT:
#	RETVAL

=end comment

=cut

## GetScrollX(PRInt32 *aScrollX)
PRInt32
moz_dom_GetScrollX (window)
	nsIDOMWindow *window;
    PREINIT:
	PRInt32 aScrollX;
    CODE:
	window->GetScrollX(&aScrollX);
	RETVAL = aScrollX;
    OUTPUT:
	RETVAL

## GetScrollY(PRInt32 *aScrollY)
PRInt32
moz_dom_GetScrollY (window)
	nsIDOMWindow *window;
    PREINIT:
	PRInt32 aScrollY;
    CODE:
	window->GetScrollY(&aScrollY);
	RETVAL = aScrollY;
    OUTPUT:
	RETVAL

## ScrollTo(PRInt32 xScroll, PRInt32 yScroll)
void
moz_dom_ScrollTo (window, xScroll, yScroll)
	nsIDOMWindow *window;
	PRInt32 xScroll;
	PRInt32 yScroll;
    CODE:
        window->ScrollTo(xScroll, yScroll);

## ScrollBy(PRInt32 xScrollDif, PRInt32 yScrollDif)
void
moz_dom_ScrollBy (window, xScrollDif, yScrollDif)
	nsIDOMWindow *window;
	PRInt32 xScrollDif;
	PRInt32 yScrollDif;
    CODE:
	window->ScrollBy(xScrollDif, yScrollDif);

## ScrollByLines(PRInt32 numLines)
void
moz_dom_ScrollByLines (window, numLines)
	nsIDOMWindow *window;
	PRInt32 numLines;
    CODE:
	window->ScrollByLines(numLines);

## ScrollByPages(PRInt32 numPages)
void
moz_dom_ScrollByPages (window, numPages)
	nsIDOMWindow *window;
	PRInt32 numPages;
    CODE:
	window->ScrollByPages(numPages);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Window2	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMWindow2.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMWINDOW2_IID)
static nsIID
nsIDOMWindow2::GetIID()
    CODE:
	const nsIID &id = nsIDOMWindow2::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetWindowRoot(nsIDOMEventTarget * *aWindowRoot)
nsIDOMEventTarget *
moz_dom_GetWindowRoot (window2)
	nsIDOMWindow2 *window2;
    PREINIT:
	nsIDOMEventTarget * aWindowRoot;
    CODE:
	window2->GetWindowRoot(&aWindowRoot);
	RETVAL = aWindowRoot;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::WindowInternal	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMWindowInternal.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMWINDOWINTERNAL_IID)
static nsIID
nsIDOMWindowInternal::GetIID()
    CODE:
	const nsIID &id = nsIDOMWindowInternal::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetWindow(nsIDOMWindowInternal * *aWindow)
nsIDOMWindowInternal *
moz_dom_GetWindow (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMWindowInternal * aWindow;
    CODE:
	windowinternal->GetWindow(&aWindow);
	RETVAL = aWindow;
    OUTPUT:
	RETVAL

## GetSelf(nsIDOMWindowInternal * *aSelf)
nsIDOMWindowInternal *
moz_dom_GetSelf (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMWindowInternal * aSelf;
    CODE:
	windowinternal->GetSelf(&aSelf);
	RETVAL = aSelf;
    OUTPUT:
	RETVAL

## GetNavigator(nsIDOMNavigator * *aNavigator)
nsIDOMNavigator *
moz_dom_GetNavigator (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMNavigator * aNavigator;
    CODE:
	windowinternal->GetNavigator(&aNavigator);
	RETVAL = aNavigator;
    OUTPUT:
	RETVAL

## GetScreen(nsIDOMScreen * *aScreen)
nsIDOMScreen *
moz_dom_GetScreen (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMScreen * aScreen;
    CODE:
	windowinternal->GetScreen(&aScreen);
	RETVAL = aScreen;
    OUTPUT:
	RETVAL

## GetHistory(nsIDOMHistory * *aHistory)
nsIDOMHistory *
moz_dom_GetHistory (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMHistory * aHistory;
    CODE:
	windowinternal->GetHistory(&aHistory);
	RETVAL = aHistory;
    OUTPUT:
	RETVAL

## GetContent(nsIDOMWindow * *aContent)
nsIDOMWindow *
moz_dom_GetContent (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMWindow * aContent;
    CODE:
	windowinternal->GetContent(&aContent);
	RETVAL = aContent;
    OUTPUT:
	RETVAL

#=for apidoc Mozilla::DOM::WindowInternal::GetPrompter
#
#=for signature $prompter = $windowinternal->GetPrompter()
#
#
#
#=cut
#
### GetPrompter(nsIPrompt * *aPrompter)
#nsIPrompt *
#moz_dom_GetPrompter (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIPrompt * aPrompter;
#    CODE:
#	windowinternal->GetPrompter(&aPrompter);
#	RETVAL = aPrompter;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetMenubar
#
#=for signature $menubar = $windowinternal->GetMenubar()
#
#
#
#=cut
#
### GetMenubar(nsIDOMBarProp * *aMenubar)
#nsIDOMBarProp *
#moz_dom_GetMenubar (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMBarProp * aMenubar;
#    CODE:
#	windowinternal->GetMenubar(&aMenubar);
#	RETVAL = aMenubar;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetToolbar
#
#=for signature $toolbar = $windowinternal->GetToolbar()
#
#
#
#=cut
#
### GetToolbar(nsIDOMBarProp * *aToolbar)
#nsIDOMBarProp *
#moz_dom_GetToolbar (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMBarProp * aToolbar;
#    CODE:
#	windowinternal->GetToolbar(&aToolbar);
#	RETVAL = aToolbar;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetLocationbar
#
#=for signature $locationbar = $windowinternal->GetLocationbar()
#
#
#
#=cut
#
### GetLocationbar(nsIDOMBarProp * *aLocationbar)
#nsIDOMBarProp *
#moz_dom_GetLocationbar (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMBarProp * aLocationbar;
#    CODE:
#	windowinternal->GetLocationbar(&aLocationbar);
#	RETVAL = aLocationbar;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetPersonalbar
#
#=for signature $personalbar = $windowinternal->GetPersonalbar()
#
#
#
#=cut
#
### GetPersonalbar(nsIDOMBarProp * *aPersonalbar)
#nsIDOMBarProp *
#moz_dom_GetPersonalbar (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMBarProp * aPersonalbar;
#    CODE:
#	windowinternal->GetPersonalbar(&aPersonalbar);
#	RETVAL = aPersonalbar;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetStatusbar
#
#=for signature $statusbar = $windowinternal->GetStatusbar()
#
#
#
#=cut
#
### GetStatusbar(nsIDOMBarProp * *aStatusbar)
#nsIDOMBarProp *
#moz_dom_GetStatusbar (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMBarProp * aStatusbar;
#    CODE:
#	windowinternal->GetStatusbar(&aStatusbar);
#	RETVAL = aStatusbar;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetDirectories
#
#=for signature $directories = $windowinternal->GetDirectories()
#
#
#
#=cut
#
### GetDirectories(nsIDOMBarProp * *aDirectories)
#nsIDOMBarProp *
#moz_dom_GetDirectories (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMBarProp * aDirectories;
#    CODE:
#	windowinternal->GetDirectories(&aDirectories);
#	RETVAL = aDirectories;
#    OUTPUT:
#	RETVAL

## GetClosed(PRBool *aClosed)
PRBool
moz_dom_GetClosed (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRBool aClosed;
    CODE:
	windowinternal->GetClosed(&aClosed);
	RETVAL = aClosed;
    OUTPUT:
	RETVAL

#=for apidoc Mozilla::DOM::WindowInternal::GetCrypto
#
#=for signature $crypto = $windowinternal->GetCrypto()
#
#
#
#=cut
#
### GetCrypto(nsIDOMCrypto * *aCrypto)
#nsIDOMCrypto *
#moz_dom_GetCrypto (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMCrypto * aCrypto;
#    CODE:
#	windowinternal->GetCrypto(&aCrypto);
#	RETVAL = aCrypto;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetPkcs11
#
#=for signature $pkcs11 = $windowinternal->GetPkcs11()
#
#
#
#=cut
#
### GetPkcs11(nsIDOMPkcs11 * *aPkcs11)
#nsIDOMPkcs11 *
#moz_dom_GetPkcs11 (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIDOMPkcs11 * aPkcs11;
#    CODE:
#	windowinternal->GetPkcs11(&aPkcs11);
#	RETVAL = aPkcs11;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WindowInternal::GetControllers
#
#=for signature $controllers = $windowinternal->GetControllers()
#
#
#
#=cut
#
### GetControllers(nsIControllers * *aControllers)
#nsIControllers *
#moz_dom_GetControllers (windowinternal)
#	nsIDOMWindowInternal *windowinternal;
#    PREINIT:
#	nsIControllers * aControllers;
#    CODE:
#	windowinternal->GetControllers(&aControllers);
#	RETVAL = aControllers;
#    OUTPUT:
#	RETVAL

## GetOpener(nsIDOMWindowInternal * *aOpener)
nsIDOMWindowInternal *
moz_dom_GetOpener (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMWindowInternal * aOpener;
    CODE:
	windowinternal->GetOpener(&aOpener);
	RETVAL = aOpener;
    OUTPUT:
	RETVAL

## SetOpener(nsIDOMWindowInternal * aOpener)
void
moz_dom_SetOpener (windowinternal, aOpener)
	nsIDOMWindowInternal *windowinternal;
	nsIDOMWindowInternal *  aOpener;
    CODE:
	windowinternal->SetOpener(aOpener);

## GetStatus(nsAString & aStatus)
nsEmbedString
moz_dom_GetStatus (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsEmbedString aStatus;
    CODE:
	windowinternal->GetStatus(aStatus);
	RETVAL = aStatus;
    OUTPUT:
	RETVAL

## SetStatus(const nsAString & aStatus)
void
moz_dom_SetStatus (windowinternal, aStatus)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString aStatus;
    CODE:
	windowinternal->SetStatus(aStatus);

## GetDefaultStatus(nsAString & aDefaultStatus)
nsEmbedString
moz_dom_GetDefaultStatus (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsEmbedString aDefaultStatus;
    CODE:
	windowinternal->GetDefaultStatus(aDefaultStatus);
	RETVAL = aDefaultStatus;
    OUTPUT:
	RETVAL

## SetDefaultStatus(const nsAString & aDefaultStatus)
void
moz_dom_SetDefaultStatus (windowinternal, aDefaultStatus)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString aDefaultStatus;
    CODE:
	windowinternal->SetDefaultStatus(aDefaultStatus);

## GetLocation(nsIDOMLocation * *aLocation)
nsIDOMLocation *
moz_dom_GetLocation (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMLocation * aLocation;
    CODE:
	windowinternal->GetLocation(&aLocation);
	RETVAL = aLocation;
    OUTPUT:
	RETVAL

## GetInnerWidth(PRInt32 *aInnerWidth)
PRInt32
moz_dom_GetInnerWidth (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aInnerWidth;
    CODE:
	windowinternal->GetInnerWidth(&aInnerWidth);
	RETVAL = aInnerWidth;
    OUTPUT:
	RETVAL

## SetInnerWidth(PRInt32 aInnerWidth)
void
moz_dom_SetInnerWidth (windowinternal, aInnerWidth)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  aInnerWidth;
    CODE:
	windowinternal->SetInnerWidth(aInnerWidth);

## GetInnerHeight(PRInt32 *aInnerHeight)
PRInt32
moz_dom_GetInnerHeight (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aInnerHeight;
    CODE:
	windowinternal->GetInnerHeight(&aInnerHeight);
	RETVAL = aInnerHeight;
    OUTPUT:
	RETVAL

## SetInnerHeight(PRInt32 aInnerHeight)
void
moz_dom_SetInnerHeight (windowinternal, aInnerHeight)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  aInnerHeight;
    CODE:
	windowinternal->SetInnerHeight(aInnerHeight);

## GetOuterWidth(PRInt32 *aOuterWidth)
PRInt32
moz_dom_GetOuterWidth (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aOuterWidth;
    CODE:
	windowinternal->GetOuterWidth(&aOuterWidth);
	RETVAL = aOuterWidth;
    OUTPUT:
	RETVAL

## SetOuterWidth(PRInt32 aOuterWidth)
void
moz_dom_SetOuterWidth (windowinternal, aOuterWidth)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  aOuterWidth;
    CODE:
	windowinternal->SetOuterWidth(aOuterWidth);

## GetOuterHeight(PRInt32 *aOuterHeight)
PRInt32
moz_dom_GetOuterHeight (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aOuterHeight;
    CODE:
	windowinternal->GetOuterHeight(&aOuterHeight);
	RETVAL = aOuterHeight;
    OUTPUT:
	RETVAL

## SetOuterHeight(PRInt32 aOuterHeight)
void
moz_dom_SetOuterHeight (windowinternal, aOuterHeight)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  aOuterHeight;
    CODE:
	windowinternal->SetOuterHeight(aOuterHeight);

## GetScreenX(PRInt32 *aScreenX)
PRInt32
moz_dom_GetScreenX (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aScreenX;
    CODE:
	windowinternal->GetScreenX(&aScreenX);
	RETVAL = aScreenX;
    OUTPUT:
	RETVAL

## SetScreenX(PRInt32 aScreenX)
void
moz_dom_SetScreenX (windowinternal, aScreenX)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  aScreenX;
    CODE:
	windowinternal->SetScreenX(aScreenX);

## GetScreenY(PRInt32 *aScreenY)
PRInt32
moz_dom_GetScreenY (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aScreenY;
    CODE:
	windowinternal->GetScreenY(&aScreenY);
	RETVAL = aScreenY;
    OUTPUT:
	RETVAL

## SetScreenY(PRInt32 aScreenY)
void
moz_dom_SetScreenY (windowinternal, aScreenY)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  aScreenY;
    CODE:
	windowinternal->SetScreenY(aScreenY);

## GetPageXOffset(PRInt32 *aPageXOffset)
PRInt32
moz_dom_GetPageXOffset (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aPageXOffset;
    CODE:
	windowinternal->GetPageXOffset(&aPageXOffset);
	RETVAL = aPageXOffset;
    OUTPUT:
	RETVAL

## GetPageYOffset(PRInt32 *aPageYOffset)
PRInt32
moz_dom_GetPageYOffset (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aPageYOffset;
    CODE:
	windowinternal->GetPageYOffset(&aPageYOffset);
	RETVAL = aPageYOffset;
    OUTPUT:
	RETVAL

## GetScrollMaxX(PRInt32 *aScrollMaxX)
PRInt32
moz_dom_GetScrollMaxX (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aScrollMaxX;
    CODE:
	windowinternal->GetScrollMaxX(&aScrollMaxX);
	RETVAL = aScrollMaxX;
    OUTPUT:
	RETVAL

## GetScrollMaxY(PRInt32 *aScrollMaxY)
PRInt32
moz_dom_GetScrollMaxY (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRInt32 aScrollMaxY;
    CODE:
	windowinternal->GetScrollMaxY(&aScrollMaxY);
	RETVAL = aScrollMaxY;
    OUTPUT:
	RETVAL

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRUint32 aLength;
    CODE:
	windowinternal->GetLength(&aLength);
	RETVAL = aLength;
    OUTPUT:
	RETVAL

## GetFullScreen(PRBool *aFullScreen)
PRBool
moz_dom_GetFullScreen (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	PRBool aFullScreen;
    CODE:
	windowinternal->GetFullScreen(&aFullScreen);
	RETVAL = aFullScreen;
    OUTPUT:
	RETVAL

## SetFullScreen(PRBool aFullScreen)
void
moz_dom_SetFullScreen (windowinternal, aFullScreen)
	nsIDOMWindowInternal *windowinternal;
	PRBool  aFullScreen;
    CODE:
	windowinternal->SetFullScreen(aFullScreen);

## Alert(const nsAString & text)
void
moz_dom_Alert (windowinternal, text)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString text;
    CODE:
	windowinternal->Alert(text);

## Confirm(const nsAString & text, PRBool *_retval)
PRBool
moz_dom_Confirm (windowinternal, text)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString text;
    PREINIT:
	PRBool _retval;
    CODE:
	windowinternal->Confirm(text, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Prompt(const nsAString & aMessage, const nsAString & aInitial, const nsAString & aTitle, PRUint32 aSavePassword, nsAString & _retval)
nsEmbedString
moz_dom_Prompt (windowinternal, aMessage, aInitial, aTitle, aSavePassword)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString aMessage;
	nsEmbedString aInitial;
	nsEmbedString aTitle;
	PRUint32  aSavePassword;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	windowinternal->Prompt(aMessage, aInitial, aTitle, aSavePassword, _retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Focus(void)
void
moz_dom_Focus (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Focus();

## Blur(void)
void
moz_dom_Blur (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Blur();

## Back(void)
void
moz_dom_Back (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Back();

## Forward(void)
void
moz_dom_Forward (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Forward();

## Home(void)
void
moz_dom_Home (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Home();

## Stop(void)
void
moz_dom_Stop (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Stop();

## Print(void)
void
moz_dom_Print (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Print();

## MoveTo(PRInt32 xPos, PRInt32 yPos)
void
moz_dom_MoveTo (windowinternal, xPos, yPos)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  xPos;
	PRInt32  yPos;
    CODE:
	windowinternal->MoveTo(xPos, yPos);

## MoveBy(PRInt32 xDif, PRInt32 yDif)
void
moz_dom_MoveBy (windowinternal, xDif, yDif)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  xDif;
	PRInt32  yDif;
    CODE:
	windowinternal->MoveBy(xDif, yDif);

## ResizeTo(PRInt32 width, PRInt32 height)
void
moz_dom_ResizeTo (windowinternal, width, height)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  width;
	PRInt32  height;
    CODE:
	windowinternal->ResizeTo(width, height);

## ResizeBy(PRInt32 widthDif, PRInt32 heightDif)
void
moz_dom_ResizeBy (windowinternal, widthDif, heightDif)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  widthDif;
	PRInt32  heightDif;
    CODE:
	windowinternal->ResizeBy(widthDif, heightDif);

## Scroll(PRInt32 xScroll, PRInt32 yScroll)
void
moz_dom_Scroll (windowinternal, xScroll, yScroll)
	nsIDOMWindowInternal *windowinternal;
	PRInt32  xScroll;
	PRInt32  yScroll;
    CODE:
	windowinternal->Scroll(xScroll, yScroll);

## Open(const nsAString & url, const nsAString & name, const nsAString & options, nsIDOMWindow **_retval)
nsIDOMWindow *
moz_dom_Open (windowinternal, url, name, options)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString url;
	nsEmbedString name;
	nsEmbedString options;
    PREINIT:
	nsIDOMWindow * _retval;
    CODE:
	windowinternal->Open(url, name, options, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## OpenDialog(const nsAString & url, const nsAString & name, const nsAString & options, nsISupports *aExtraArgument, nsIDOMWindow **_retval)
nsIDOMWindow *
moz_dom_OpenDialog (windowinternal, url, name, options, aExtraArgument)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString url;
	nsEmbedString name;
	nsEmbedString options;
	nsISupports * aExtraArgument;
    PREINIT:
	nsIDOMWindow * _retval;
    CODE:
	windowinternal->OpenDialog(url, name, options, aExtraArgument, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Close(void)
void
moz_dom_Close (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    CODE:
	windowinternal->Close();

## UpdateCommands(const nsAString & action)
void
moz_dom_UpdateCommands (windowinternal, action)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString action;
    CODE:
	windowinternal->UpdateCommands(action);

## Find(const nsAString & str, PRBool caseSensitive, PRBool backwards, PRBool wrapAround, PRBool wholeWord, PRBool searchInFrames, PRBool showDialog, PRBool *_retval)
PRBool
moz_dom_Find (windowinternal, str, caseSensitive, backwards, wrapAround, wholeWord, searchInFrames, showDialog)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString str;
	PRBool  caseSensitive;
	PRBool  backwards;
	PRBool  wrapAround;
	PRBool  wholeWord;
	PRBool  searchInFrames;
	PRBool  showDialog;
    PREINIT:
	PRBool _retval;
    CODE:
	windowinternal->Find(str, caseSensitive, backwards, wrapAround, wholeWord, searchInFrames, showDialog, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Atob(const nsAString & aAsciiString, nsAString & _retval)
nsEmbedString
moz_dom_Atob (windowinternal, aAsciiString)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString aAsciiString;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	windowinternal->Atob(aAsciiString, _retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Btoa(const nsAString & aBase64Data, nsAString & _retval)
nsEmbedString
moz_dom_Btoa (windowinternal, aBase64Data)
	nsIDOMWindowInternal *windowinternal;
	nsEmbedString aBase64Data;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	windowinternal->Btoa(aBase64Data, _retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## GetFrameElement(nsIDOMElement * *aFrameElement)
nsIDOMElement *
moz_dom_GetFrameElement (windowinternal)
	nsIDOMWindowInternal *windowinternal;
    PREINIT:
	nsIDOMElement * aFrameElement;
    CODE:
	windowinternal->GetFrameElement(&aFrameElement);
	RETVAL = aFrameElement;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::WindowCollection	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMWindowCollection.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMWINDOWCOLLECTION_IID)
static nsIID
nsIDOMWindowCollection::GetIID()
    CODE:
	const nsIID &id = nsIDOMWindowCollection::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (coll)
	nsIDOMWindowCollection *coll;
    PREINIT:
	PRUint32 len;
    CODE:
	coll->GetLength(&len);
	RETVAL = len;
    OUTPUT:
	RETVAL

## Item(PRUint32 index, nsIDOMWindow **_retval)
nsIDOMWindow *
moz_dom_Item (coll, i)
	nsIDOMWindowCollection *coll;
	PRUint32 i;
    PREINIT:
	nsIDOMWindow *window;
    CODE:
	coll->Item(i, &window);
	RETVAL = window;
    OUTPUT:
	RETVAL

## NamedItem(const nsAString & name, nsIDOMWindow **_retval)
nsIDOMWindow *
moz_dom_NamedItem (coll, name)
	nsIDOMWindowCollection *coll;
	nsEmbedString name;
    PREINIT:
	nsIDOMWindow *window;
    CODE:
	coll->NamedItem(name, &window);
	RETVAL = window;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Node	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMNode.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNODE_IID)
static nsIID
nsIDOMNode::GetIID()
    CODE:
	const nsIID &id = nsIDOMNode::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetNodeName(nsAString & aNodeName)
nsEmbedString
moz_dom_GetNodeName (node)
	nsIDOMNode *node;
    PREINIT:
	nsEmbedString name;
    CODE:
	node->GetNodeName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## GetNodeValue(nsAString & aNodeValue)
nsEmbedString
moz_dom_GetNodeValue (node)
	nsIDOMNode *node;
    PREINIT:
	nsEmbedString value;
    CODE:
	node->GetNodeValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetNodeValue(const nsAString & aNodeValue)
void
moz_dom_SetNodeValue (node, value)
	nsIDOMNode *node;
	nsEmbedString value;
    CODE:
	node->SetNodeValue(value);

## GetNodeType(PRUint16 *aNodeType)
PRUint16
moz_dom_GetNodeType (node)
	nsIDOMNode *node;
    PREINIT:
	PRUint16 type;
    CODE:
	node->GetNodeType(&type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## GetParentNode(nsIDOMNode * *aParentNode)
nsIDOMNode *
moz_dom_GetParentNode (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMNode *parent;
    CODE:
	node->GetParentNode(&parent);
	RETVAL = parent;
    OUTPUT:
	RETVAL

# GetChildNodes(nsIDOMNodeList * *aChildNodes)
nsIDOMNodeList *
moz_dom_GetChildNodes_nodelist (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMNodeList *nodelist;
    CODE:
	node->GetChildNodes(&nodelist);
	RETVAL = nodelist;
    OUTPUT:
	RETVAL

## GetFirstChild(nsIDOMNode * *aFirstChild)
nsIDOMNode *
moz_dom_GetFirstChild (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMNode *child;
    CODE:
	node->GetFirstChild(&child);
	RETVAL = child;
    OUTPUT:
	RETVAL

## GetLastChild(nsIDOMNode * *aLastChild)
nsIDOMNode *
moz_dom_GetLastChild (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMNode *child;
    CODE:
	node->GetLastChild(&child);
	RETVAL = child;
    OUTPUT:
	RETVAL

## GetPreviousSibling(nsIDOMNode * *aPreviousSibling)
nsIDOMNode *
moz_dom_GetPreviousSibling (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMNode *bro;
    CODE:
	node->GetPreviousSibling(&bro);
	RETVAL = bro;
    OUTPUT:
	RETVAL

## GetNextSibling(nsIDOMNode * *aNextSibling)
nsIDOMNode *
moz_dom_GetNextSibling (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMNode *bro;
    CODE:
	node->GetNextSibling(&bro);
	RETVAL = bro;
    OUTPUT:
	RETVAL

## GetAttributes(nsIDOMNamedNodeMap * *aAttributes)
nsIDOMNamedNodeMap *
moz_dom_GetAttributes_namednodemap (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMNamedNodeMap *nodemap;
    CODE:
	node->GetAttributes(&nodemap);
	RETVAL = nodemap;
    OUTPUT:
	RETVAL

## GetOwnerDocument(nsIDOMDocument * *aOwnerDocument)
nsIDOMDocument *
moz_dom_GetOwnerDocument (node)
	nsIDOMNode *node;
    PREINIT:
	nsIDOMDocument *doc;
    CODE:
	node->GetOwnerDocument(&doc);
	RETVAL = doc;
    OUTPUT:
	RETVAL

## InsertBefore(nsIDOMNode *newChild, nsIDOMNode *refChild, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_InsertBefore (node, newChild, refChild=0)
	nsIDOMNode *node;
	nsIDOMNode *newChild;
	nsIDOMNode *refChild;
    PREINIT:
	nsIDOMNode *insert;
    CODE:
	/* raises (DOMException) */
	node->InsertBefore(newChild, refChild, &insert);
	RETVAL = insert;
    OUTPUT:
	RETVAL

## ReplaceChild(nsIDOMNode *newChild, nsIDOMNode *oldChild, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_ReplaceChild (node, newChild, oldChild)
	nsIDOMNode *node;
	nsIDOMNode *newChild;
	nsIDOMNode *oldChild;
    PREINIT:
	nsIDOMNode *child;
    CODE:
	/* raises (DOMException) */
	node->ReplaceChild(newChild, oldChild, &child);
	RETVAL = child;
    OUTPUT:
	RETVAL

## RemoveChild(nsIDOMNode *oldChild, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_RemoveChild (node, oldChild)
	nsIDOMNode *node;
	nsIDOMNode *oldChild;
    PREINIT:
	nsIDOMNode *child;
    CODE:
	/* raises (DOMException) */
	node->RemoveChild(oldChild, &child);
	RETVAL = node;
    OUTPUT:
	RETVAL

## AppendChild(nsIDOMNode *newChild, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_AppendChild (node, newChild)
	nsIDOMNode *node;
	nsIDOMNode *newChild;
    PREINIT:
	nsIDOMNode *child;
    CODE:
	/* raises (DOMException) */
	node->AppendChild(newChild, &child);
	RETVAL = child;
    OUTPUT:
	RETVAL

## HasChildNodes(PRBool *_retval)
PRBool
moz_dom_HasChildNodes (node)
	nsIDOMNode *node;
    PREINIT:
	PRBool has;
    CODE:
	node->HasChildNodes(&has);
	RETVAL = has;
    OUTPUT:
	RETVAL

## CloneNode(PRBool deep, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_CloneNode (node, deep)
	nsIDOMNode *node;
	PRBool deep;
    PREINIT:
	nsIDOMNode *clone;
    CODE:
	node->CloneNode(deep, &clone);
	RETVAL = clone;
    OUTPUT:
	RETVAL

## Normalize(void)
void
moz_dom_Normalize (node)
	nsIDOMNode *node;
    CODE:
	node->Normalize();

## IsSupported(const nsAString & feature, const nsAString & version, PRBool *_retval)
PRBool
moz_dom_IsSupported (node, feature, version)
	nsIDOMNode *node;
	nsEmbedString feature;
	nsEmbedString version;
    PREINIT:
	PRBool is;
    CODE:
	node->IsSupported(feature, version, &is);
	RETVAL = is;
    OUTPUT:
	RETVAL

## GetNamespaceURI(nsAString & aNamespaceURI)
nsEmbedString
moz_dom_GetNamespaceURI (node)
	nsIDOMNode *node;
    PREINIT:
	nsEmbedString uri;
    CODE:
	node->GetNamespaceURI(uri);
	RETVAL = uri;
    OUTPUT:
	RETVAL

## GetPrefix(nsAString & aPrefix)
nsEmbedString
moz_dom_GetPrefix (node)
	nsIDOMNode *node;
    PREINIT:
	nsEmbedString aPrefix;
    CODE:
	node->GetPrefix(aPrefix);
	RETVAL = aPrefix;
    OUTPUT:
	RETVAL

## SetPrefix(const nsAString & aPrefix)
void
moz_dom_SetPrefix (node, aPrefix)
	nsIDOMNode *node;
	nsEmbedString aPrefix;
    CODE:
	node->SetPrefix(aPrefix);

## GetLocalName(nsAString & aLocalName)
nsEmbedString
moz_dom_GetLocalName (node)
	nsIDOMNode *node;
    PREINIT:
	nsEmbedString name;
    CODE:
	node->GetLocalName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## HasAttributes(PRBool *_retval)
PRBool
moz_dom_HasAttributes (node)
	nsIDOMNode *node;
    PREINIT:
	PRBool has;
    CODE:
	node->HasAttributes(&has);
	RETVAL = has;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NodeList	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMNodeList.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNODELIST_IID)
static nsIID
nsIDOMNodeList::GetIID()
    CODE:
	const nsIID &id = nsIDOMNodeList::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## Item(PRUint32 index, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_Item (nodelist, index)
	nsIDOMNodeList *nodelist;
	PRUint32 index;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	nodelist->Item(index, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (nodelist)
	nsIDOMNodeList *nodelist;
    PREINIT:
	PRUint32 len;
    CODE:
	nodelist->GetLength(&len);
	RETVAL = len;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NamedNodeMap	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMNamedNodeMap.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNAMEDNODEMAP_IID)
static nsIID
nsIDOMNamedNodeMap::GetIID()
    CODE:
	const nsIID &id = nsIDOMNamedNodeMap::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetNamedItem(const nsAString & name, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_GetNamedItem (namednodemap, name)
	nsIDOMNamedNodeMap *namednodemap;
	nsEmbedString name;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	namednodemap->GetNamedItem(name, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## SetNamedItem(nsIDOMNode *arg, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_SetNamedItem (namednodemap, arg)
	nsIDOMNamedNodeMap *namednodemap;
	nsIDOMNode *arg;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	/* raises (DOMException) */
	namednodemap->SetNamedItem(arg, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## RemoveNamedItem(const nsAString & name, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_RemoveNamedItem (namednodemap, name)
	nsIDOMNamedNodeMap *namednodemap;
	nsEmbedString name;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	/* raises (DOMException) */
	namednodemap->RemoveNamedItem(name, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## Item(PRUint32 index, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_Item (namednodemap, index)
	nsIDOMNamedNodeMap *namednodemap;
	PRUint32 index;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	namednodemap->Item(index, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (namednodemap)
	nsIDOMNamedNodeMap *namednodemap;
    PREINIT:
	PRUint32 len;
    CODE:
	namednodemap->GetLength(&len);
	RETVAL = len;
    OUTPUT:
	RETVAL

## GetNamedItemNS(const nsAString & namespaceURI, const nsAString & localName, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_GetNamedItemNS (namednodemap, namespaceURI, localName)
	nsIDOMNamedNodeMap *namednodemap;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	namednodemap->GetNamedItemNS(namespaceURI, localName, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## SetNamedItemNS(nsIDOMNode *arg, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_SetNamedItemNS (namednodemap, arg)
	nsIDOMNamedNodeMap *namednodemap;
	nsIDOMNode *arg;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	/* raises (DOMException) */
	namednodemap->SetNamedItemNS(arg, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## RemoveNamedItemNS(const nsAString & namespaceURI, const nsAString & localName, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_RemoveNamedItemNS (namednodemap, namespaceURI, localName)
	nsIDOMNamedNodeMap *namednodemap;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	/* raises (DOMException) */
	namednodemap->RemoveNamedItemNS(namespaceURI, localName, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Document	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDocument.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOCUMENT_IID)
static nsIID
nsIDOMDocument::GetIID()
    CODE:
	const nsIID &id = nsIDOMDocument::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDoctype(nsIDOMDocumentType * *aDoctype)
nsIDOMDocumentType *
moz_dom_GetDoctype (document)
	nsIDOMDocument *document;
    PREINIT:
	nsIDOMDocumentType *doctype ;
    CODE:
	document->GetDoctype(&doctype);
	RETVAL = doctype;
    OUTPUT:
	RETVAL

## GetImplementation(nsIDOMDOMImplementation * *aImplementation)
nsIDOMDOMImplementation *
moz_dom_GetImplementation (document)
	nsIDOMDocument *document;
    PREINIT:
	nsIDOMDOMImplementation *implementation;
    CODE:
	document->GetImplementation(&implementation);
	RETVAL = implementation;
    OUTPUT:
	RETVAL

## GetDocumentElement(nsIDOMElement * *aDocumentElement)
nsIDOMElement *
moz_dom_GetDocumentElement (document)
	nsIDOMDocument *document;
    PREINIT:
	nsIDOMElement *element;
    CODE:
	document->GetDocumentElement(&element);
	RETVAL = element;
    OUTPUT:
	RETVAL

## CreateElement(const nsAString & tagName, nsIDOMElement **_retval)
nsIDOMElement *
moz_dom_CreateElement (document, tagname)
	nsIDOMDocument *document;
	nsEmbedString tagname;
    PREINIT:
	nsIDOMElement *element;
    CODE:
	/* raises (DOMException) */
	document->CreateElement(tagname, &element);
	RETVAL = element;
    OUTPUT:
	RETVAL

## CreateDocumentFragment(nsIDOMDocumentFragment **_retval)
nsIDOMDocumentFragment *
moz_dom_CreateDocumentFragment (document)
	nsIDOMDocument *document;
    PREINIT:
	nsIDOMDocumentFragment *fragment;
    CODE:
	document->CreateDocumentFragment(&fragment);
	RETVAL = fragment;
    OUTPUT:
	RETVAL

## CreateTextNode(const nsAString & data, nsIDOMText **_retval)
nsIDOMText *
moz_dom_CreateTextNode (document, data)
	nsIDOMDocument *document;
	nsEmbedString data;
    PREINIT:
	nsIDOMText *node;
    CODE:
	document->CreateTextNode(data, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## CreateComment(const nsAString & data, nsIDOMComment **_retval)
nsIDOMComment *
moz_dom_CreateComment (document, data)
	nsIDOMDocument *document;
	nsEmbedString data;
    PREINIT:
	nsIDOMComment *comment;
    CODE:
	document->CreateComment(data, &comment);
	RETVAL = comment;
    OUTPUT:
	RETVAL

## CreateCDATASection(const nsAString & data, nsIDOMCDATASection **_retval)
nsIDOMCDATASection *
moz_dom_CreateCDATASection (document, data)
	nsIDOMDocument *document;
	nsEmbedString data;
    PREINIT:
	nsIDOMCDATASection *node;
    CODE:
	/* raises (DOMException) */
	document->CreateCDATASection(data, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## CreateProcessingInstruction(const nsAString & target, const nsAString & data, nsIDOMProcessingInstruction **_retval)
nsIDOMProcessingInstruction *
moz_dom_CreateProcessingInstruction (document, target, data)
	nsIDOMDocument *document;
	nsEmbedString target;
	nsEmbedString data;
    PREINIT:
	nsIDOMProcessingInstruction *node;
    CODE:
	/* raises (DOMException) */
	document->CreateProcessingInstruction(target, data, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## CreateAttribute(const nsAString & name, nsIDOMAttr **_retval)
nsIDOMAttr *
moz_dom_CreateAttribute (document, name)
	nsIDOMDocument *document;
	nsEmbedString name;
    PREINIT:
	nsIDOMAttr *node;
    CODE:
	/* raises (DOMException) */
	document->CreateAttribute(name, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## CreateEntityReference(const nsAString & name, nsIDOMEntityReference **_retval)
nsIDOMEntityReference *
moz_dom_CreateEntityReference (document, name)
	nsIDOMDocument *document;
	nsEmbedString name;
    PREINIT:
	nsIDOMEntityReference *node;
    CODE:
	/* raises (DOMException) */
	document->CreateEntityReference(name, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetElementsByTagName(const nsAString & tagname, nsIDOMNodeList **_retval)
nsIDOMNodeList *
moz_dom_GetElementsByTagName_nodelist (document, tagname)
	nsIDOMDocument *document;
	nsEmbedString tagname;
    PREINIT:
	nsIDOMNodeList *nodelist;
    CODE:
	document->GetElementsByTagName(tagname, &nodelist);
	RETVAL = nodelist;
    OUTPUT:
	RETVAL

## ImportNode(nsIDOMNode *importedNode, PRBool deep, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_ImportNode (document, importedNode, deep)
	nsIDOMDocument *document;
	nsIDOMNode *importedNode;
	PRBool deep;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	/* raises (DOMException) */
	document->ImportNode(importedNode, deep, &node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## CreateElementNS(const nsAString & namespaceURI, const nsAString & qualifiedName, nsIDOMElement **_retval)
nsIDOMElement *
moz_dom_CreateElementNS (document, namespaceURI, qualifiedName)
	nsIDOMDocument *document;
	nsEmbedString namespaceURI;
	nsEmbedString qualifiedName;
    PREINIT:
	nsIDOMElement *element;
    CODE:
	/* raises (DOMException) */
	document->CreateElementNS(namespaceURI, qualifiedName, &element);
	RETVAL = element;
    OUTPUT:
	RETVAL

## CreateAttributeNS(const nsAString & namespaceURI, const nsAString & qualifiedName, nsIDOMAttr **_retval)
nsIDOMAttr *
moz_dom_CreateAttributeNS (document, namespaceURI, qualifiedName)
	nsIDOMDocument *document;
	nsEmbedString namespaceURI;
	nsEmbedString qualifiedName;
    PREINIT:
	nsIDOMAttr *attr;
    CODE:
	/* raises (DOMException) */
	document->CreateAttributeNS(namespaceURI, qualifiedName, &attr);
	RETVAL = attr;
    OUTPUT:
	RETVAL

## GetElementsByTagNameNS(const nsAString & namespaceURI, const nsAString & localName, nsIDOMNodeList **_retval)
nsIDOMNodeList *
moz_dom_GetElementsByTagNameNS_nodelist (document, namespaceURI, localName)
	nsIDOMDocument *document;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    PREINIT:
	nsIDOMNodeList *nodelist;
    CODE:
	document->GetElementsByTagNameNS(namespaceURI, localName, &nodelist);
	RETVAL = nodelist;
    OUTPUT:
	RETVAL

## GetElementById(const nsAString & elementId, nsIDOMElement **_retval)
nsIDOMElement *
moz_dom_GetElementById (document, elementId)
	nsIDOMDocument *document;
	nsEmbedString elementId;
    PREINIT:
	nsIDOMElement *element;
    CODE:
	document->GetElementById(elementId, &element);
	RETVAL = element;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSDocument	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSDocument.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSDOCUMENT_IID)
static nsIID
nsIDOMNSDocument::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSDocument::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCharacterSet(nsAString & aCharacterSet)
nsEmbedString
moz_dom_GetCharacterSet (nsdocument)
	nsIDOMNSDocument *nsdocument;
    PREINIT:
	nsEmbedString aCharacterSet;
    CODE:
	nsdocument->GetCharacterSet(aCharacterSet);
	RETVAL = aCharacterSet;
    OUTPUT:
	RETVAL

## GetDir(nsAString & aDir)
nsEmbedString
moz_dom_GetDir (nsdocument)
	nsIDOMNSDocument *nsdocument;
    PREINIT:
	nsEmbedString aDir;
    CODE:
	nsdocument->GetDir(aDir);
	RETVAL = aDir;
    OUTPUT:
	RETVAL

## SetDir(const nsAString & aDir)
void
moz_dom_SetDir (nsdocument, aDir)
	nsIDOMNSDocument *nsdocument;
	nsEmbedString aDir;
    CODE:
	nsdocument->SetDir(aDir);

## GetLocation(nsIDOMLocation * *aLocation)
nsIDOMLocation *
moz_dom_GetLocation (nsdocument)
	nsIDOMNSDocument *nsdocument;
    PREINIT:
	nsIDOMLocation * aLocation;
    CODE:
	nsdocument->GetLocation(&aLocation);
	RETVAL = aLocation;
    OUTPUT:
	RETVAL

## GetTitle(nsAString & aTitle)
nsEmbedString
moz_dom_GetTitle (nsdocument)
	nsIDOMNSDocument *nsdocument;
    PREINIT:
	nsEmbedString aTitle;
    CODE:
	nsdocument->GetTitle(aTitle);
	RETVAL = aTitle;
    OUTPUT:
	RETVAL

## SetTitle(const nsAString & aTitle)
void
moz_dom_SetTitle (nsdocument, aTitle)
	nsIDOMNSDocument *nsdocument;
	nsEmbedString aTitle;
    CODE:
	nsdocument->SetTitle(aTitle);

## GetContentType(nsAString & aContentType)
nsEmbedString
moz_dom_GetContentType (nsdocument)
	nsIDOMNSDocument *nsdocument;
    PREINIT:
	nsEmbedString aContentType;
    CODE:
	nsdocument->GetContentType(aContentType);
	RETVAL = aContentType;
    OUTPUT:
	RETVAL

## GetLastModified(nsAString & aLastModified)
nsEmbedString
moz_dom_GetLastModified (nsdocument)
	nsIDOMNSDocument *nsdocument;
    PREINIT:
	nsEmbedString aLastModified;
    CODE:
	nsdocument->GetLastModified(aLastModified);
	RETVAL = aLastModified;
    OUTPUT:
	RETVAL

## GetReferrer(nsAString & aReferrer)
nsEmbedString
moz_dom_GetReferrer (nsdocument)
	nsIDOMNSDocument *nsdocument;
    PREINIT:
	nsEmbedString aReferrer;
    CODE:
	nsdocument->GetReferrer(aReferrer);
	RETVAL = aReferrer;
    OUTPUT:
	RETVAL

### GetBoxObjectFor(nsIDOMElement *elt, nsIBoxObject **_retval)
#nsIBoxObject *
#moz_dom_GetBoxObjectFor (nsdocument, elt)
#	nsIDOMNSDocument *nsdocument;
#	nsIDOMElement * elt;
#    PREINIT:
#	nsIBoxObject * _retval;
#    CODE:
#	nsdocument->GetBoxObjectFor(elt, &_retval);
#	RETVAL = _retval;
#    OUTPUT:
#	RETVAL
#
### SetBoxObjectFor(nsIDOMElement *elt, nsIBoxObject *boxObject)
#void
#moz_dom_SetBoxObjectFor (nsdocument, elt, boxObject)
#	nsIDOMNSDocument *nsdocument;
#	nsIDOMElement * elt;
#	nsIBoxObject * boxObject;
#    CODE:
#	nsdocument->SetBoxObjectFor(elt, boxObject);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Element	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMELEMENT_IID)
static nsIID
nsIDOMElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetTagName(nsAString & aTagName)
nsEmbedString
moz_dom_GetTagName (element)
	nsIDOMElement *element;
    PREINIT:
	nsEmbedString tagname;
    CODE:
	element->GetTagName(tagname);
	RETVAL = tagname;
    OUTPUT:
	RETVAL

## GetAttribute(const nsAString & name, nsAString & _retval)
nsEmbedString
moz_dom_GetAttribute (element, name)
	nsIDOMElement *element;
	nsEmbedString name;
    PREINIT:
	nsEmbedString attr;
    CODE:
	element->GetAttribute(name, attr);
	RETVAL = attr;
    OUTPUT:
	RETVAL

## SetAttribute(const nsAString & name, const nsAString & value)
void
moz_dom_SetAttribute (element, name, value)
	nsIDOMElement *element;
	nsEmbedString name;
	nsEmbedString value;
    CODE:
	/* raises (DOMException) */
	element->SetAttribute(name, value);

## RemoveAttribute(const nsAString & name)
void
moz_dom_RemoveAttribute (element, name)
	nsIDOMElement *element;
	nsEmbedString name;
    CODE:
	/* raises (DOMException) */
	element->RemoveAttribute(name);

## GetAttributeNode(const nsAString & name, nsIDOMAttr **_retval)
nsIDOMAttr *
moz_dom_GetAttributeNode (element, name)
	nsIDOMElement *element;
	nsEmbedString name;
    PREINIT:
	nsIDOMAttr *attrnode;
    CODE:
	element->GetAttributeNode(name, &attrnode);
	RETVAL = attrnode;
    OUTPUT:
	RETVAL

## SetAttributeNode(nsIDOMAttr *newAttr, nsIDOMAttr **_retval)
nsIDOMAttr *
moz_dom_SetAttributeNode (element, newAttr)
	nsIDOMElement *element;
	nsIDOMAttr *newAttr;
    PREINIT:
	nsIDOMAttr *attrnode;
    CODE:
	/* raises (DOMException) */
	element->SetAttributeNode(newAttr, &attrnode);
	RETVAL = attrnode;
    OUTPUT:
	RETVAL

## RemoveAttributeNode(nsIDOMAttr *oldAttr, nsIDOMAttr **_retval)
nsIDOMAttr *
moz_dom_RemoveAttributeNode (element, oldAttr)
	nsIDOMElement *element;
	nsIDOMAttr *oldAttr;
    PREINIT:
	nsIDOMAttr *attrnode;
    CODE:
	/* raises (DOMException) */
	element->RemoveAttributeNode(oldAttr, &attrnode);
	RETVAL = attrnode;
    OUTPUT:
	RETVAL

## GetElementsByTagName(const nsAString & name, nsIDOMNodeList **_retval)
nsIDOMNodeList *
moz_dom_GetElementsByTagName_nodelist (element, name)
	nsIDOMElement *element;
	nsEmbedString name;
    PREINIT:
	nsIDOMNodeList *nodelist;
    CODE:
	element->GetElementsByTagName(name, &nodelist);
	RETVAL = nodelist;
    OUTPUT:
	RETVAL

## GetAttributeNS(const nsAString & namespaceURI, const nsAString & localName, nsAString & _retval)
nsEmbedString
moz_dom_GetAttributeNS (element, namespaceURI, localName)
	nsIDOMElement *element;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    PREINIT:
	nsEmbedString attr;
    CODE:
	element->GetAttributeNS(namespaceURI, localName, attr);
	RETVAL = attr;
    OUTPUT:
	RETVAL

## SetAttributeNS(const nsAString & namespaceURI, const nsAString & qualifiedName, const nsAString & value)
void
moz_dom_SetAttributeNS (element, namespaceURI, qualifiedName, value)
	nsIDOMElement *element;
	nsEmbedString namespaceURI;
	nsEmbedString qualifiedName;
	nsEmbedString value;
    CODE:
	/* raises (DOMException) */
	element->SetAttributeNS(namespaceURI, qualifiedName, value);

## RemoveAttributeNS(const nsAString & namespaceURI, const nsAString & localName)
void
moz_dom_RemoveAttributeNS (element, namespaceURI, localName)
	nsIDOMElement *element;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    CODE:
	/* raises (DOMException) */
	element->RemoveAttributeNS(namespaceURI, localName);

## GetAttributeNodeNS(const nsAString & namespaceURI, const nsAString & localName, nsIDOMAttr **_retval)
nsIDOMAttr *
moz_dom_GetAttributeNodeNS (element, namespaceURI, localName)
	nsIDOMElement *element;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    PREINIT:
	nsIDOMAttr *attrnode;
	
    CODE:
	element->GetAttributeNodeNS(namespaceURI, localName, &attrnode);
	RETVAL = attrnode;
    OUTPUT:
	RETVAL

## SetAttributeNodeNS(nsIDOMAttr *newAttr, nsIDOMAttr **_retval)
nsIDOMAttr *
moz_dom_SetAttributeNodeNS (element, newAttr)
	nsIDOMElement *element;
	nsIDOMAttr *newAttr;
    PREINIT:
	nsIDOMAttr *attrnode;
    CODE:
	/* raises (DOMException) */
	element->SetAttributeNodeNS(newAttr, &attrnode);
	RETVAL = attrnode;
    OUTPUT:
	RETVAL

## GetElementsByTagNameNS(const nsAString & namespaceURI, const nsAString & localName, nsIDOMNodeList **_retval)
nsIDOMNodeList *
moz_dom_GetElementsByTagNameNS_nodelist (element, namespaceURI, localName)
	nsIDOMElement *element;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    PREINIT:
	nsIDOMNodeList *nodelist;
    CODE:
	element->GetElementsByTagNameNS(namespaceURI, localName, &nodelist);
	RETVAL = nodelist;
    OUTPUT:
	RETVAL

## HasAttribute(const nsAString & name, PRBool *_retval)
PRBool
moz_dom_HasAttribute (element, name)
	nsIDOMElement *element;
	nsEmbedString name;
    PREINIT:
	PRBool has;
    CODE:
	element->HasAttribute(name, &has);
	RETVAL = has;
    OUTPUT:
	RETVAL

## HasAttributeNS(const nsAString & namespaceURI, const nsAString & localName, PRBool *_retval)
PRBool
moz_dom_HasAttributeNS (element, namespaceURI, localName)
	nsIDOMElement *element;
	nsEmbedString namespaceURI;
	nsEmbedString localName;
    PREINIT:
	PRBool has;
    CODE:
	element->HasAttributeNS(namespaceURI, localName, &has);
	RETVAL = has;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Entity	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMEntity.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMENTITY_IID)
static nsIID
nsIDOMEntity::GetIID()
    CODE:
	const nsIID &id = nsIDOMEntity::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetPublicId(nsAString & aPublicId)
nsEmbedString
moz_dom_GetPublicId (entity)
	nsIDOMEntity *entity;
    PREINIT:
	nsEmbedString aPublicId;
    CODE:
	entity->GetPublicId(aPublicId);
	RETVAL = aPublicId;
    OUTPUT:
	RETVAL

## GetSystemId(nsAString & aSystemId)
nsEmbedString
moz_dom_GetSystemId (entity)
	nsIDOMEntity *entity;
    PREINIT:
	nsEmbedString aSystemId;
    CODE:
	entity->GetSystemId(aSystemId);
	RETVAL = aSystemId;
    OUTPUT:
	RETVAL

## GetNotationName(nsAString & aNotationName)
nsEmbedString
moz_dom_GetNotationName (entity)
	nsIDOMEntity *entity;
    PREINIT:
	nsEmbedString aNotationName;
    CODE:
	entity->GetNotationName(aNotationName);
	RETVAL = aNotationName;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::EntityReference	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMEntityReference.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMENTITYREFERENCE_IID)
static nsIID
nsIDOMEntityReference::GetIID()
    CODE:
	const nsIID &id = nsIDOMEntityReference::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Attr	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMAttr.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMATTR_IID)
static nsIID
nsIDOMAttr::GetIID()
    CODE:
	const nsIID &id = nsIDOMAttr::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (attr)
	nsIDOMAttr *attr;
    PREINIT:
	nsEmbedString name;
    CODE:
	attr->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## GetSpecified(PRBool *aSpecified)
PRBool
moz_dom_GetSpecified (attr)
	nsIDOMAttr *attr;
    PREINIT:
	PRBool spec;
    CODE:
	attr->GetSpecified(&spec);
	RETVAL = spec;
    OUTPUT:
	RETVAL

## GetValue(nsAString & aValue)
nsEmbedString
moz_dom_GetValue (attr)
	nsIDOMAttr *attr;
    PREINIT:
	nsEmbedString value;
    CODE:
	attr->GetValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(const nsAString & aValue)
void
moz_dom_SetValue (attr, value)
	nsIDOMAttr *attr;
	nsEmbedString value;
    CODE:
	attr->SetValue(value);

## GetOwnerElement(nsIDOMElement * *aOwnerElement)
nsIDOMElement *
moz_dom_GetOwnerElement (attr)
	nsIDOMAttr *attr;
    PREINIT:
	nsIDOMElement *element;
    CODE:
	attr->GetOwnerElement(&element);
	RETVAL = element;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Notation	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMNotation.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNOTATION_IID)
static nsIID
nsIDOMNotation::GetIID()
    CODE:
	const nsIID &id = nsIDOMNotation::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetPublicId(nsAString & aPublicId)
nsEmbedString
moz_dom_GetPublicId (notation)
	nsIDOMNotation *notation;
    PREINIT:
	nsEmbedString aPublicId;
    CODE:
	notation->GetPublicId(aPublicId);
	RETVAL = aPublicId;
    OUTPUT:
	RETVAL

## GetSystemId(nsAString & aSystemId)
nsEmbedString
moz_dom_GetSystemId (notation)
	nsIDOMNotation *notation;
    PREINIT:
	nsEmbedString aSystemId;
    CODE:
	notation->GetSystemId(aSystemId);
	RETVAL = aSystemId;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::ProcessingInstruction	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMProcessingInstruction.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMPROCESSINGINSTRUCTION_IID)
static nsIID
nsIDOMProcessingInstruction::GetIID()
    CODE:
	const nsIID &id = nsIDOMProcessingInstruction::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetTarget(nsAString & aTarget), etc..
nsEmbedString
moz_dom_GetTarget (pi)
	nsIDOMProcessingInstruction *pi;
    ALIAS:
	Mozilla::DOM::ProcessingInstruction::GetData = 1
    PREINIT:
	nsEmbedString str;
    CODE:
	switch (ix) {
		case 0: pi->GetTarget(str); break;
		case 1: pi->GetData(str); break;
		default: XSRETURN_UNDEF;
	}
	RETVAL = str;
    OUTPUT:
	RETVAL

## SetData(const nsAString & aData)
void
moz_dom_SetData (pi, data)
	nsIDOMProcessingInstruction *pi;
	nsEmbedString data;
    CODE:
	pi->SetData(data);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::CDATASection	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMCDATASection.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMCDATASECTION_IID)
static nsIID
nsIDOMCDATASection::GetIID()
    CODE:
	const nsIID &id = nsIDOMCDATASection::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Comment	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMComment.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMCOMMENT_IID)
static nsIID
nsIDOMComment::GetIID()
    CODE:
	const nsIID &id = nsIDOMComment::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::CharacterData	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMCharacterData.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMCHARACTERDATA_IID)
static nsIID
nsIDOMCharacterData::GetIID()
    CODE:
	const nsIID &id = nsIDOMCharacterData::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetData(nsAString & aData)
nsEmbedString
moz_dom_GetData (characterdata)
	nsIDOMCharacterData *characterdata;
    PREINIT:
	nsEmbedString data;
    CODE:
	characterdata->GetData(data);
	RETVAL = data;
    OUTPUT:
	RETVAL

## SetData(const nsAString & aData)
void
moz_dom_SetData (characterdata, data)
	nsIDOMCharacterData *characterdata;
	nsEmbedString data;
    CODE:
	characterdata->SetData(data);

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (characterdata)
	nsIDOMCharacterData *characterdata;
    PREINIT:
	PRUint32 len;
    CODE:
	characterdata->GetLength(&len);
	RETVAL = len;
    OUTPUT:
	RETVAL

## SubstringData(PRUint32 offset, PRUint32 count, nsAString & _retval)
nsEmbedString
moz_dom_SubstringData (characterdata, offset, count)
	nsIDOMCharacterData *characterdata;
	PRUint32 offset;
	PRUint32 count;
    PREINIT:
	nsEmbedString data;
    CODE:
	/* raises (DOMException) */
	characterdata->SubstringData(offset, count, data);
	RETVAL = data;
    OUTPUT:
	RETVAL

## AppendData(const nsAString & arg)
void
moz_dom_AppendData (characterdata, data)
	nsIDOMCharacterData *characterdata;
	nsEmbedString data;
    CODE:
	/* raises (DOMException) */
	characterdata->AppendData(data);

## InsertData(PRUint32 offset, const nsAString & arg)
void
moz_dom_InsertData (characterdata, offset, data)
	nsIDOMCharacterData *characterdata;
	PRUint32 offset;
	nsEmbedString data;
    CODE:
	/* raises (DOMException) */
	characterdata->InsertData(offset, data);

## DeleteData(PRUint32 offset, PRUint32 count)
void
moz_dom_DeleteData (characterdata, offset, count)
	nsIDOMCharacterData *characterdata;
	PRUint32 offset;
	PRUint32 count;
    CODE:
	/* raises (DOMException) */
	characterdata->DeleteData(offset, count);

## ReplaceData(PRUint32 offset, PRUint32 count, const nsAString & arg)
void
moz_dom_ReplaceData (characterdata, offset, count, data)
	nsIDOMCharacterData *characterdata;
	PRUint32 offset;
	PRUint32 count;
	nsEmbedString data;
    CODE:
	/* raises (DOMException) */
	characterdata->ReplaceData(offset, count, data);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Text	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMText.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMTEXT_IID)
static nsIID
nsIDOMText::GetIID()
    CODE:
	const nsIID &id = nsIDOMText::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## SplitText(PRUint32 offset, nsIDOMText **_retval)
nsIDOMText *
moz_dom_SplitText (text, offset)
	nsIDOMText *text;
	PRUint32 offset;
    PREINIT:
	nsIDOMText *splittext;
    CODE:
	/* raises (DOMException) */
	text->SplitText(offset, &splittext);
	RETVAL = splittext;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::DocumentFragment	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDocumentFragment.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOCUMENTFRAGMENT_IID)
static nsIID
nsIDOMDocumentFragment::GetIID()
    CODE:
	const nsIID &id = nsIDOMDocumentFragment::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::DocumentType	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDocumentType.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOCUMENTTYPE_IID)
static nsIID
nsIDOMDocumentType::GetIID()
    CODE:
	const nsIID &id = nsIDOMDocumentType::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (documenttype)
	nsIDOMDocumentType *documenttype;
    PREINIT:
	nsEmbedString name;
    CODE:
	documenttype->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## GetEntities(nsIDOMNamedNodeMap * *aEntities)
nsIDOMNamedNodeMap *
moz_dom_GetEntities_namednodemap (documenttype)
	nsIDOMDocumentType *documenttype;
    PREINIT:
	nsIDOMNamedNodeMap *nodemap;
    CODE:
	documenttype->GetEntities(&nodemap);
	RETVAL = nodemap;
    OUTPUT:
	RETVAL

## GetNotations(nsIDOMNamedNodeMap * *aNotations)
nsIDOMNamedNodeMap *
moz_dom_GetNotations_namednodemap (documenttype)
	nsIDOMDocumentType *documenttype;
    PREINIT:
	nsIDOMNamedNodeMap *nodemap;
    CODE:
	documenttype->GetNotations(&nodemap);
	RETVAL = nodemap;
    OUTPUT:
	RETVAL

## GetPublicId(nsAString & aPublicId)
nsEmbedString
moz_dom_GetPublicId (documenttype)
	nsIDOMDocumentType *documenttype;
    PREINIT:
	nsEmbedString id;
    CODE:
	documenttype->GetPublicId(id);
	RETVAL = id;
    OUTPUT:
	RETVAL

## GetSystemId(nsAString & aSystemId)
nsEmbedString
moz_dom_GetSystemId (documenttype)
	nsIDOMDocumentType *documenttype;
    PREINIT:
	nsEmbedString id;
    CODE:
	documenttype->GetSystemId(id);
	RETVAL = id;
    OUTPUT:
	RETVAL

## GetInternalSubset(nsAString & aInternalSubset)
nsEmbedString
moz_dom_GetInternalSubset (documenttype)
	nsIDOMDocumentType *documenttype;
    PREINIT:
	nsEmbedString subset;
    CODE:
	documenttype->GetInternalSubset(subset);
	RETVAL = subset;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::DOMImplementation	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDOMImplementation.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOMIMPLEMENTATION_IID)
static nsIID
nsIDOMDOMImplementation::GetIID()
    CODE:
	const nsIID &id = nsIDOMDOMImplementation::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## HasFeature(const nsAString & feature, const nsAString & version, PRBool *_retval)
PRBool
moz_dom_HasFeature (domimplementation, feature, version)
	nsIDOMDOMImplementation *domimplementation;
	nsEmbedString feature;
	nsEmbedString version;
    PREINIT:
	PRBool has;
    CODE:
	domimplementation->HasFeature(feature, version, &has);
	RETVAL = has;
    OUTPUT:
	RETVAL

## CreateDocumentType(const nsAString & qualifiedName, const nsAString & publicId, const nsAString & systemId, nsIDOMDocumentType **_retval)
nsIDOMDocumentType *
moz_dom_CreateDocumentType (domimplementation, qualifiedName, publicId, systemId)
	nsIDOMDOMImplementation *domimplementation;
	nsEmbedString qualifiedName;
	nsEmbedString publicId;
	nsEmbedString systemId;
    PREINIT:
	nsIDOMDocumentType *type;
    CODE:
	/* raises (DOMException) */
	domimplementation->CreateDocumentType(qualifiedName, publicId, systemId, &type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## CreateDocument(const nsAString & namespaceURI, const nsAString & qualifiedName, nsIDOMDocumentType *doctype, nsIDOMDocument **_retval)
nsIDOMDocument *
moz_dom_CreateDocument (domimplementation, namespaceURI, qualifiedName, doctype)
	nsIDOMDOMImplementation *domimplementation;
	nsEmbedString namespaceURI;
	nsEmbedString qualifiedName;
	nsIDOMDocumentType *doctype;
    PREINIT:
	nsIDOMDocument *doc;
    CODE:
	/* raises (DOMException) */
	domimplementation->CreateDocument(namespaceURI, qualifiedName, doctype, &doc);
	RETVAL = doc;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::DOMException	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDOMException.h

# XXX: this isn't supported yet here, as I've ignored catching
# any exceptions that are raised (though they are all noted
# in comments). Will soon.

#  If you want to throw an exception object, assign the object to $@ and then pass
#  "Nullch" to croak():
#
#    errsv = get_sv("@", TRUE);
#    sv_setsv(errsv, exception_object);
#    croak(Nullch);
#
#  But how do I create a nsIDOMDOMException object? Is one thrown
#  when an exception occurs? (I was under the impression that
#  methods generally just return error codes.)

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOMEXCEPTION_IID)
static nsIID
nsIDOMDOMException::GetIID()
    CODE:
	const nsIID &id = nsIDOMDOMException::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## found code:
##nsresult rv;
##rv=aTarget->GetValue(&Url);
##if (NS_FAILED(rv)) return 2;
##(also have NS_SUCCEEDED)

#  /* readonly attribute unsigned long code; */
#=for apidoc Mozilla::DOM::DOMException::GetCode
#
#=for signature $exception->GetCode(PRUint32 *aCode)
#
#
#
#=cut
#
### GetCode(PRUint32 *aCode)
#somereturn *
#moz_dom_GetCode (exception, aCode)
#	nsIDOMexception *exception;
#	PRUint32 *aCode ;
#    PREINIT:
#	
#    CODE:
#	exception->GetCode(&);
#	RETVAL = ;
#    OUTPUT:
#	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Selection	PREFIX = moz_dom_

# /usr/include/mozilla/nsISelection.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_ISELECTION_IID)
static nsIID
nsISelection::GetIID()
    CODE:
	const nsIID &id = nsISelection::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAnchorNode(nsIDOMNode * *aAnchorNode)
nsIDOMNode *
moz_dom_GetAnchorNode (selection)
	nsISelection *selection;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	selection->GetAnchorNode(&node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetAnchorOffset(PRInt32 *aAnchorOffset)
PRInt32
moz_dom_GetAnchorOffset (selection)
	nsISelection *selection;
    PREINIT:
	PRInt32 offset;
    CODE:
	selection->GetAnchorOffset(&offset);
	RETVAL = offset;
    OUTPUT:
	RETVAL

## GetFocusNode(nsIDOMNode * *aFocusNode)
nsIDOMNode *
moz_dom_GetFocusNode (selection)
	nsISelection *selection;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	selection->GetFocusNode(&node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetFocusOffset(PRInt32 *aFocusOffset)
PRInt32
moz_dom_GetFocusOffset (selection)
	nsISelection *selection;
    PREINIT:
	PRInt32 offset;
    CODE:
	selection->GetFocusOffset(&offset);
	RETVAL = offset;
    OUTPUT:
	RETVAL

## GetIsCollapsed(PRBool *aIsCollapsed)
PRBool
moz_dom_GetIsCollapsed (selection)
	nsISelection *selection;
    PREINIT:
	PRBool is;
    CODE:
	selection->GetIsCollapsed(&is);
	RETVAL = is;
    OUTPUT:
	RETVAL

## GetRangeCount(PRInt32 *aRangeCount)
PRInt32
moz_dom_GetRangeCount (selection)
	nsISelection *selection;
    PREINIT:
	PRInt32 count;
    CODE:
	selection->GetRangeCount(&count);
	RETVAL = count;
    OUTPUT:
	RETVAL

## GetRangeAt(PRInt32 index, nsIDOMRange **_retval)
nsIDOMRange *
moz_dom_GetRangeAt (selection, index)
	nsISelection *selection;
	PRInt32 index;
    PREINIT:
	nsIDOMRange *range;
    CODE:
	selection->GetRangeAt(index, &range);
	RETVAL = range;
    OUTPUT:
	RETVAL

## Collapse(nsIDOMNode *parentNode, PRInt32 offset)
void
moz_dom_Collapse (selection, parentNode, offset)
	nsISelection *selection;
	nsIDOMNode *parentNode;
	PRInt32 offset;
    CODE:
	selection->Collapse(parentNode, offset);

# Extend(nsIDOMNode *parentNode, PRInt32 offset)
void
moz_dom_Extend (selection, parentNode, offset)
	nsISelection *selection;
	nsIDOMNode *parentNode;
	PRInt32 offset;
    CODE:
	selection->Extend(parentNode, offset);

## CollapseToStart(void)
void
moz_dom_CollapseToStart (selection)
	nsISelection *selection;
    CODE:
	selection->CollapseToStart();

## CollapseToEnd(void)
void
moz_dom_CollapseToEnd (selection)
	nsISelection *selection;
    CODE:
	selection->CollapseToEnd();

## ContainsNode(nsIDOMNode *node, PRBool entirelyContained, PRBool *_retval)
PRBool
moz_dom_ContainsNode (selection, node, entirelyContained)
	nsISelection *selection;
	nsIDOMNode *node;
	PRBool entirelyContained;
    PREINIT:
	PRBool has;
    CODE:
	selection->ContainsNode(node, entirelyContained, &has);
	RETVAL = has;
    OUTPUT:
	RETVAL

## SelectAllChildren(nsIDOMNode *parentNode)
void
moz_dom_SelectAllChildren (selection, parentNode)
	nsISelection *selection;
	nsIDOMNode *parentNode;
    CODE:
	selection->SelectAllChildren(parentNode);

## AddRange(nsIDOMRange *range)
void
moz_dom_AddRange (selection, range)
	nsISelection *selection;
	nsIDOMRange *range;
    CODE:
	selection->AddRange(range);

## RemoveRange(nsIDOMRange *range)
void
moz_dom_RemoveRange (selection, range)
	nsISelection *selection;
	nsIDOMRange *range;
    CODE:
	selection->RemoveRange(range);

## RemoveAllRanges(void)
void
moz_dom_RemoveAllRanges (selection)
	nsISelection *selection;
    CODE:
	selection->RemoveAllRanges();

## DeleteFromDocument(void)
void
moz_dom_DeleteFromDocument (selection)
	nsISelection *selection;
    CODE:
	selection->DeleteFromDocument();

## SelectionLanguageChange(PRBool langRTL)
void
moz_dom_SelectionLanguageChange (selection, langRTL)
	nsISelection *selection;
	PRBool langRTL;
    CODE:
	selection->SelectionLanguageChange(langRTL);

## ToString(PRUnichar **_retval)
nsEmbedString
moz_dom_ToString (selection)
	nsISelection *selection;
    PREINIT:
	PRUnichar *u16str;
    CODE:
	selection->ToString(&u16str);
	nsEmbedString str(u16str);
	RETVAL = str;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::DocumentRange	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMDocumentRange.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMDOCUMENTRANGE_IID)
static nsIID
nsIDOMDocumentRange::GetIID()
    CODE:
	const nsIID &id = nsIDOMDocumentRange::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## CreateRange(nsIDOMRange **_retval)
nsIDOMRange *
moz_dom_CreateRange (documentrange)
	nsIDOMDocumentRange *documentrange;
    PREINIT:
	nsIDOMRange * _retval;
    CODE:
	documentrange->CreateRange(&_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Range	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMRange.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMRANGE_IID)
static nsIID
nsIDOMRange::GetIID()
    CODE:
	const nsIID &id = nsIDOMRange::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetStartContainer(nsIDOMNode * *aStartContainer)
nsIDOMNode *
moz_dom_GetStartContainer (range)
	nsIDOMRange *range;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	range->GetStartContainer(&node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetStartOffset(PRInt32 *aStartOffset)
PRInt32
moz_dom_GetStartOffset (range)
	nsIDOMRange *range;
    PREINIT:
	PRInt32 offset;
    CODE:
	range->GetStartOffset(&offset);
	RETVAL = offset;
    OUTPUT:
	RETVAL

## GetEndContainer(nsIDOMNode * *aEndContainer)
nsIDOMNode *
moz_dom_GetEndContainer (range)
	nsIDOMRange *range;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	range->GetEndContainer(&node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## GetEndOffset(PRInt32 *aEndOffset)
PRInt32
moz_dom_GetEndOffset (range)
	nsIDOMRange *range;
    PREINIT:
	PRInt32 offset;
    CODE:
	range->GetEndOffset(&offset);
	RETVAL = offset;
    OUTPUT:
	RETVAL

## GetCollapsed(PRBool *aCollapsed)
PRBool
moz_dom_GetCollapsed (range)
	nsIDOMRange *range;
    PREINIT:
	PRBool collapsed;
    CODE:
	range->GetCollapsed(&collapsed);
	RETVAL = collapsed;
    OUTPUT:
	RETVAL

## GetCommonAncestorContainer(nsIDOMNode * *aCommonAncestorContainer)
nsIDOMNode *
moz_dom_GetCommonAncestorContainer (range)
	nsIDOMRange *range;
    PREINIT:
	nsIDOMNode *node;
    CODE:
	range->GetCommonAncestorContainer(&node);
	RETVAL = node;
    OUTPUT:
	RETVAL

## SetStart(nsIDOMNode *refNode, PRInt32 offset)
void
moz_dom_SetStart (range, refNode, offset)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
	PRInt32 offset;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SetStart(refNode, offset);

## SetEnd(nsIDOMNode *refNode, PRInt32 offset)
void
moz_dom_SetEnd (range, refNode, offset)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
	PRInt32 offset;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SetEnd(refNode, offset);

## SetStartBefore(nsIDOMNode *refNode)
void
moz_dom_SetStartBefore (range, refNode)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SetStartBefore(refNode);

## SetStartAfter(nsIDOMNode *refNode)
void
moz_dom_SetStartAfter (range, refNode)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SetStartAfter(refNode);

## SetEndBefore(nsIDOMNode *refNode)
void
moz_dom_SetEndBefore (range, refNode)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SetEndBefore(refNode);

## SetEndAfter(nsIDOMNode *refNode)
void
moz_dom_SetEndAfter (range, refNode)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SetEndAfter(refNode);

## Collapse(PRBool toStart)
void
moz_dom_Collapse (range, toStart)
	nsIDOMRange *range;
	PRBool toStart;
    CODE:
	/* raises (DOMException) */
	range->Collapse(toStart);

## SelectNode(nsIDOMNode *refNode)
void
moz_dom_SelectNode (range, refNode)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SelectNode(refNode);

## SelectNodeContents(nsIDOMNode *refNode)
void
moz_dom_SelectNodeContents (range, refNode)
	nsIDOMRange *range;
	nsIDOMNode *refNode;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SelectNodeContents(refNode);

## CompareBoundaryPoints(PRUint16 how, nsIDOMRange *sourceRange, PRInt16 *_retval)
PRInt16
moz_dom_CompareBoundaryPoints (range, how, sourceRange)
	nsIDOMRange *range;
	PRUint16 how;
	nsIDOMRange *sourceRange;
    PREINIT:
	PRInt16 num;
    CODE:
	/* raises (DOMException) */
	range->CompareBoundaryPoints(how, sourceRange, &num);
	RETVAL = num;
    OUTPUT:
	RETVAL

## DeleteContents(void)
void
moz_dom_DeleteContents (range)
	nsIDOMRange *range;
    CODE:
	/* raises (DOMException) */
	range->DeleteContents();

## ExtractContents(nsIDOMDocumentFragment **_retval)
nsIDOMDocumentFragment *
moz_dom_ExtractContents (range)
	nsIDOMRange *range;
    PREINIT:
	nsIDOMDocumentFragment *frag;
    CODE:
	/* raises (DOMException) */
	range->ExtractContents(&frag);
	RETVAL = frag;
    OUTPUT:
	RETVAL

## CloneContents(nsIDOMDocumentFragment **_retval)
nsIDOMDocumentFragment *
moz_dom_CloneContents (range)
	nsIDOMRange *range;
    PREINIT:
	nsIDOMDocumentFragment *frag;
    CODE:
	/* raises (DOMException) */
	range->CloneContents(&frag);
	RETVAL = frag;
    OUTPUT:
	RETVAL

## InsertNode(nsIDOMNode *newNode)
void
moz_dom_InsertNode (range, newNode)
	nsIDOMRange *range;
	nsIDOMNode *newNode;
    CODE:
	/* raises (RangeException, DOMException) */
	range->InsertNode(newNode);

## SurroundContents(nsIDOMNode *newParent)
void
moz_dom_SurroundContents (range, newParent)
	nsIDOMRange *range;
	nsIDOMNode *newParent;
    CODE:
	/* raises (RangeException, DOMException) */
	range->SurroundContents(newParent);

## CloneRange(nsIDOMRange **_retval)
nsIDOMRange *
moz_dom_CloneRange (range)
	nsIDOMRange *range;
    PREINIT:
	nsIDOMRange *newrange;
    CODE:
	/* raises (DOMException) */
	range->CloneRange(&newrange);
	RETVAL = newrange;

## ToString(nsAString & _retval)
nsEmbedString
moz_dom_ToString (range)
	nsIDOMRange *range;
    PREINIT:
	nsEmbedString str;
    CODE:
	/* raises (DOMException) */
	range->ToString(str);
	RETVAL = str;
    OUTPUT:
	RETVAL

## Detach(void)
void
moz_dom_Detach (range)
	nsIDOMRange *range;
    CODE:
	/* raises (DOMException) */
	range->Detach();

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSRange	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSRange.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSRANGE_IID)
static nsIID
nsIDOMNSRange::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSRange::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## CreateContextualFragment(const nsAString & fragment, nsIDOMDocumentFragment **_retval)
nsIDOMDocumentFragment *
moz_dom_CreateContextualFragment (nsrange, fragment)
	nsIDOMNSRange *nsrange;
	nsEmbedString fragment;
    PREINIT:
	nsIDOMDocumentFragment * _retval;
    CODE:
	nsrange->CreateContextualFragment(fragment, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## IsPointInRange(nsIDOMNode *parent, PRInt32 offset, PRBool *_retval)
PRBool
moz_dom_IsPointInRange (nsrange, parent, offset)
	nsIDOMNSRange *nsrange;
	nsIDOMNode * parent;
	PRInt32  offset;
    PREINIT:
	PRBool _retval;
    CODE:
	nsrange->IsPointInRange(parent, offset, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## ComparePoint(nsIDOMNode *parent, PRInt32 offset, PRInt16 *_retval)
PRInt16
moz_dom_ComparePoint (nsrange, parent, offset)
	nsIDOMNSRange *nsrange;
	nsIDOMNode * parent;
	PRInt32  offset;
    PREINIT:
	PRInt16 _retval;
    CODE:
	nsrange->ComparePoint(parent, offset, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL


### see https://developer.mozilla.org/en/Gecko_1.9_Changes_affecting_websites

#ifdef NOT_SUPPORTED_ANYMORE

## IntersectsNode(nsIDOMNode *n, PRBool *_retval)
PRBool
moz_dom_IntersectsNode (nsrange, n)
	nsIDOMNSRange *nsrange;
	nsIDOMNode * n;
    PREINIT:
	PRBool _retval;
    CODE:
	nsrange->IntersectsNode(n, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## CompareNode(nsIDOMNode *n, PRUint16 *_retval)
PRUint16
moz_dom_CompareNode (nsrange, n)
	nsIDOMNSRange *nsrange;
	nsIDOMNode * n;
    PREINIT:
	PRUint16 _retval;
    CODE:
	nsrange->CompareNode(n, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## NSDetach(void)
void
moz_dom_NSDetach (nsrange)
	nsIDOMNSRange *nsrange;
    CODE:
	nsrange->NSDetach();

#endif


# -----------------------------------------------------------------------------


MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Supports	PREFIX = moz_dom_

# /usr/include/mozilla/nsISupports.h

## QueryInterface(const nsIID & uuid, void * *result)
SV *
moz_dom_QueryInterface (supports, uuid)
	nsISupports *supports;
	nsIID uuid;
    PREINIT:
	void *res;
	nsresult rv;
    CODE:
	rv = supports->QueryInterface((const nsIID)uuid, (void **)&res);
	if (NS_FAILED(rv))
		croak("QueryInterface failed, rv=%d\n", rv);

	/* XXX: let me know if there's a better way to do this... */
	if (uuid.Equals(nsIDOMAbstractView::GetIID())) {
		RETVAL = newSVnsIDOMAbstractView((nsIDOMAbstractView *)res);
	} else if (uuid.Equals(nsIDOMAttr::GetIID())) {
		RETVAL = newSVnsIDOMAttr((nsIDOMAttr *)res);
	} else if (uuid.Equals(nsIDOMCDATASection::GetIID())) {
		RETVAL = newSVnsIDOMCDATASection((nsIDOMCDATASection *)res);
	} else if (uuid.Equals(nsIDOMCharacterData::GetIID())) {
		RETVAL = newSVnsIDOMCharacterData((nsIDOMCharacterData *)res);
	} else if (uuid.Equals(nsIDOMComment::GetIID())) {
		RETVAL = newSVnsIDOMComment((nsIDOMComment *)res);
	} else if (uuid.Equals(nsIDOMDOMException::GetIID())) {
		RETVAL = newSVnsIDOMDOMException((nsIDOMDOMException *)res);
	} else if (uuid.Equals(nsIDOMDOMImplementation::GetIID())) {
		RETVAL = newSVnsIDOMDOMImplementation((nsIDOMDOMImplementation *)res);
	} else if (uuid.Equals(nsIDOMDocument::GetIID())) {
		RETVAL = newSVnsIDOMDocument((nsIDOMDocument *)res);
	} else if (uuid.Equals(nsIDOMNSDocument::GetIID())) {
		RETVAL = newSVnsIDOMNSDocument((nsIDOMNSDocument *)res);
	} else if (uuid.Equals(nsIDOMDocumentEvent::GetIID())) {
		RETVAL = newSVnsIDOMDocumentEvent((nsIDOMDocumentEvent *)res);
	} else if (uuid.Equals(nsIDOMDocumentFragment::GetIID())) {
		RETVAL = newSVnsIDOMDocumentFragment((nsIDOMDocumentFragment *)res);
	} else if (uuid.Equals(nsIDOMDocumentRange::GetIID())) {
		RETVAL = newSVnsIDOMDocumentRange((nsIDOMDocumentRange *)res);
	} else if (uuid.Equals(nsIDOMDocumentType::GetIID())) {
		RETVAL = newSVnsIDOMDocumentType((nsIDOMDocumentType *)res);
	} else if (uuid.Equals(nsIDOMDocumentView::GetIID())) {
		RETVAL = newSVnsIDOMDocumentView((nsIDOMDocumentView *)res);
	} else if (uuid.Equals(nsIDOMElement::GetIID())) {
		RETVAL = newSVnsIDOMElement((nsIDOMElement *)res);
	} else if (uuid.Equals(nsIDOMEntity::GetIID())) {
		RETVAL = newSVnsIDOMEntity((nsIDOMEntity *)res);
	} else if (uuid.Equals(nsIDOMEntityReference::GetIID())) {
		RETVAL = newSVnsIDOMEntityReference((nsIDOMEntityReference *)res);
	} else if (uuid.Equals(nsIDOMEvent::GetIID())) {
		RETVAL = newSVnsIDOMEvent((nsIDOMEvent *)res);
	} else if (uuid.Equals(nsIDOMNSEvent::GetIID())) {
		RETVAL = newSVnsIDOMNSEvent((nsIDOMNSEvent *)res);
	} else if (uuid.Equals(nsIDOMEventListener::GetIID())) {
		RETVAL = newSVnsIDOMEventListener((nsIDOMEventListener *)res);
	} else if (uuid.Equals(nsIDOMEventTarget::GetIID())) {
		RETVAL = newSVnsIDOMEventTarget((nsIDOMEventTarget *)res);
	} else if (uuid.Equals(nsIDOMKeyEvent::GetIID())) {
		RETVAL = newSVnsIDOMKeyEvent((nsIDOMKeyEvent *)res);
	} else if (uuid.Equals(nsIDOMMouseEvent::GetIID())) {
		RETVAL = newSVnsIDOMMouseEvent((nsIDOMMouseEvent *)res);
	} else if (uuid.Equals(nsIDOMMutationEvent::GetIID())) {
		RETVAL = newSVnsIDOMMutationEvent((nsIDOMMutationEvent *)res);
	} else if (uuid.Equals(nsIDOMNamedNodeMap::GetIID())) {
		RETVAL = newSVnsIDOMNamedNodeMap((nsIDOMNamedNodeMap *)res);
	} else if (uuid.Equals(nsIDOMNode::GetIID())) {
		RETVAL = newSVnsIDOMNode((nsIDOMNode *)res);
	} else if (uuid.Equals(nsIDOMNodeList::GetIID())) {
		RETVAL = newSVnsIDOMNodeList((nsIDOMNodeList *)res);
	} else if (uuid.Equals(nsIDOMNotation::GetIID())) {
		RETVAL = newSVnsIDOMNotation((nsIDOMNotation *)res);
	} else if (uuid.Equals(nsIDOMProcessingInstruction::GetIID())) {
		RETVAL = newSVnsIDOMProcessingInstruction((nsIDOMProcessingInstruction *)res);
	} else if (uuid.Equals(nsIDOMRange::GetIID())) {
		RETVAL = newSVnsIDOMRange((nsIDOMRange *)res);
	} else if (uuid.Equals(nsIDOMNSRange::GetIID())) {
		RETVAL = newSVnsIDOMNSRange((nsIDOMNSRange *)res);
	} else if (uuid.Equals(nsISelection::GetIID())) {
		RETVAL = newSVnsISelection((nsISelection *)res);
	} else if (uuid.Equals(nsIDOMText::GetIID())) {
		RETVAL = newSVnsIDOMText((nsIDOMText *)res);
	} else if (uuid.Equals(nsIDOMUIEvent::GetIID())) {
		RETVAL = newSVnsIDOMUIEvent((nsIDOMUIEvent *)res);
	} else if (uuid.Equals(nsIDOMNSUIEvent::GetIID())) {
		RETVAL = newSVnsIDOMNSUIEvent((nsIDOMNSUIEvent *)res);
	} else if (uuid.Equals(nsIWebBrowser::GetIID())) {
		RETVAL = newSVnsIWebBrowser((nsIWebBrowser *)res);
	} else if (uuid.Equals(nsIWebNavigation::GetIID())) {
		RETVAL = newSVnsIWebNavigation((nsIWebNavigation *)res);
	} else if (uuid.Equals(nsIURI::GetIID())) {
		RETVAL = newSVnsIURI((nsIURI *)res);
	} else if (uuid.Equals(nsIDOMWindow::GetIID())) {
		RETVAL = newSVnsIDOMWindow((nsIDOMWindow *)res);
	} else if (uuid.Equals(nsIDOMWindow2::GetIID())) {
		RETVAL = newSVnsIDOMWindow2((nsIDOMWindow2 *)res);
	} else if (uuid.Equals(nsIDOMWindowInternal::GetIID())) {
		RETVAL = newSVnsIDOMWindowInternal((nsIDOMWindowInternal *)res);
	} else if (uuid.Equals(nsIDOMWindowCollection::GetIID())) {
		RETVAL = newSVnsIDOMWindowCollection((nsIDOMWindowCollection *)res);
	} else if (uuid.Equals(nsIDOMHistory::GetIID())) {
		RETVAL = newSVnsIDOMHistory((nsIDOMHistory *)res);
	} else if (uuid.Equals(nsIDOMLocation::GetIID())) {
		RETVAL = newSVnsIDOMLocation((nsIDOMLocation *)res);
	} else if (uuid.Equals(nsIDOMNavigator::GetIID())) {
		RETVAL = newSVnsIDOMNavigator((nsIDOMNavigator *)res);
	} else if (uuid.Equals(nsIDOMScreen::GetIID())) {
		RETVAL = newSVnsIDOMScreen((nsIDOMScreen *)res);

	/* nsIDOMHTML* */
	} else if (uuid.Equals(nsIDOMHTMLAnchorElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLAnchorElement((nsIDOMHTMLAnchorElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLAnchorElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLAnchorElement((nsIDOMNSHTMLAnchorElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLAppletElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLAppletElement((nsIDOMHTMLAppletElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLAreaElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLAreaElement((nsIDOMHTMLAreaElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLAreaElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLAreaElement((nsIDOMNSHTMLAreaElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLBRElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLBRElement((nsIDOMHTMLBRElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLBaseElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLBaseElement((nsIDOMHTMLBaseElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLBaseFontElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLBaseFontElement((nsIDOMHTMLBaseFontElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLBodyElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLBodyElement((nsIDOMHTMLBodyElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLButtonElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLButtonElement((nsIDOMHTMLButtonElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLButtonElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLButtonElement((nsIDOMNSHTMLButtonElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLCollection::GetIID())) {
		RETVAL = newSVnsIDOMHTMLCollection((nsIDOMHTMLCollection *)res);
	} else if (uuid.Equals(nsIDOMHTMLDListElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLDListElement((nsIDOMHTMLDListElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLDirectoryElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLDirectoryElement((nsIDOMHTMLDirectoryElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLDivElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLDivElement((nsIDOMHTMLDivElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLDocument::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLDocument((nsIDOMNSHTMLDocument *)res);
	} else if (uuid.Equals(nsIDOMHTMLElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLElement((nsIDOMHTMLElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLElement((nsIDOMNSHTMLElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLEmbedElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLEmbedElement((nsIDOMHTMLEmbedElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLFieldSetElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLFieldSetElement((nsIDOMHTMLFieldSetElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLFontElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLFontElement((nsIDOMHTMLFontElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLFormElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLFormElement((nsIDOMHTMLFormElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLFormElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLFormElement((nsIDOMNSHTMLFormElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLFrameElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLFrameElement((nsIDOMHTMLFrameElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLFrameElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLFrameElement((nsIDOMNSHTMLFrameElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLFrameSetElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLFrameSetElement((nsIDOMHTMLFrameSetElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLHRElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLHRElement((nsIDOMHTMLHRElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLHRElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLHRElement((nsIDOMNSHTMLHRElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLHeadElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLHeadElement((nsIDOMHTMLHeadElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLHeadingElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLHeadingElement((nsIDOMHTMLHeadingElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLHtmlElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLHtmlElement((nsIDOMHTMLHtmlElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLIFrameElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLIFrameElement((nsIDOMHTMLIFrameElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLImageElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLImageElement((nsIDOMHTMLImageElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLImageElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLImageElement((nsIDOMNSHTMLImageElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLInputElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLInputElement((nsIDOMHTMLInputElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLInputElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLInputElement((nsIDOMNSHTMLInputElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLIsIndexElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLIsIndexElement((nsIDOMHTMLIsIndexElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLLIElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLLIElement((nsIDOMHTMLLIElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLLabelElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLLabelElement((nsIDOMHTMLLabelElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLLegendElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLLegendElement((nsIDOMHTMLLegendElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLLinkElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLLinkElement((nsIDOMHTMLLinkElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLMapElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLMapElement((nsIDOMHTMLMapElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLMenuElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLMenuElement((nsIDOMHTMLMenuElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLMetaElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLMetaElement((nsIDOMHTMLMetaElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLModElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLModElement((nsIDOMHTMLModElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLOListElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLOListElement((nsIDOMHTMLOListElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLObjectElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLObjectElement((nsIDOMHTMLObjectElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLOptGroupElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLOptGroupElement((nsIDOMHTMLOptGroupElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLOptionElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLOptionElement((nsIDOMHTMLOptionElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLOptionElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLOptionElement((nsIDOMNSHTMLOptionElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLOptionsCollection::GetIID())) {
		RETVAL = newSVnsIDOMHTMLOptionsCollection((nsIDOMHTMLOptionsCollection *)res);
	} else if (uuid.Equals(nsIDOMHTMLParagraphElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLParagraphElement((nsIDOMHTMLParagraphElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLParamElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLParamElement((nsIDOMHTMLParamElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLPreElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLPreElement((nsIDOMHTMLPreElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLQuoteElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLQuoteElement((nsIDOMHTMLQuoteElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLScriptElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLScriptElement((nsIDOMHTMLScriptElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLSelectElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLSelectElement((nsIDOMHTMLSelectElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLSelectElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLSelectElement((nsIDOMNSHTMLSelectElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLStyleElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLStyleElement((nsIDOMHTMLStyleElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTableCaptionElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTableCaptionElement((nsIDOMHTMLTableCaptionElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTableCellElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTableCellElement((nsIDOMHTMLTableCellElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTableColElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTableColElement((nsIDOMHTMLTableColElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTableElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTableElement((nsIDOMHTMLTableElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTableRowElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTableRowElement((nsIDOMHTMLTableRowElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTableSectionElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTableSectionElement((nsIDOMHTMLTableSectionElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTextAreaElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTextAreaElement((nsIDOMHTMLTextAreaElement *)res);
	} else if (uuid.Equals(nsIDOMNSHTMLTextAreaElement::GetIID())) {
		RETVAL = newSVnsIDOMNSHTMLTextAreaElement((nsIDOMNSHTMLTextAreaElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLTitleElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLTitleElement((nsIDOMHTMLTitleElement *)res);
	} else if (uuid.Equals(nsIDOMHTMLUListElement::GetIID())) {
		RETVAL = newSVnsIDOMHTMLUListElement((nsIDOMHTMLUListElement *)res);
	}
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::WebBrowser	PREFIX = moz_dom_

# /usr/include/mozilla/nsIWebBrowser.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IWEBBROWSER_IID)
static nsIID
nsIWebBrowser::GetIID()
    CODE:
	const nsIID &id = nsIWebBrowser::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

### AddWebBrowserListener(nsIWeakReference *aListener, const nsIID & aIID)
#void
#moz_dom_AddWebBrowserListener (webbrowser, aListener, aIID)
#	nsIWebBrowser *webbrowser;
#	nsIWeakReference * aListener;
#	const nsIID &  aIID;
#    CODE:
#	webbrowser->AddWebBrowserListener(aListener, aIID);
#
### RemoveWebBrowserListener(nsIWeakReference *aListener, const nsIID & aIID)
#void
#moz_dom_RemoveWebBrowserListener (webbrowser, aListener, aIID)
#	nsIWebBrowser *webbrowser;
#	nsIWeakReference * aListener;
#	const nsIID &  aIID;
#    CODE:
#	webbrowser->RemoveWebBrowserListener(aListener, aIID);

## GetContentDOMWindow(nsIDOMWindow * *aContentDOMWindow)
nsIDOMWindow *
moz_dom_GetContentDOMWindow (browser)
	nsIWebBrowser *browser
    PREINIT:
	nsIDOMWindow *window;
    CODE:
	browser->GetContentDOMWindow(&window);
	if (!window)
		XSRETURN_UNDEF;
	else
		RETVAL = window;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::WebNavigation	PREFIX = moz_dom_

# /usr/include/mozilla/docshell/nsIWebNavigation.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IWEBNAVIGATION_IID)
static nsIID
nsIWebNavigation::GetIID()
    CODE:
	const nsIID &id = nsIWebNavigation::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCanGoBack(PRBool *aCanGoBack)
PRBool
moz_dom_GetCanGoBack (webnavigation)
	nsIWebNavigation *webnavigation;
    PREINIT:
	PRBool aCanGoBack;
    CODE:
	webnavigation->GetCanGoBack(&aCanGoBack);
	RETVAL = aCanGoBack;
    OUTPUT:
	RETVAL

## GetCanGoForward(PRBool *aCanGoForward)
PRBool
moz_dom_GetCanGoForward (webnavigation)
	nsIWebNavigation *webnavigation;
    PREINIT:
	PRBool aCanGoForward;
    CODE:
	webnavigation->GetCanGoForward(&aCanGoForward);
	RETVAL = aCanGoForward;
    OUTPUT:
	RETVAL

## GoBack(void)
void
moz_dom_GoBack (webnavigation)
	nsIWebNavigation *webnavigation;
    CODE:
	webnavigation->GoBack();

## GoForward(void)
void
moz_dom_GoForward (webnavigation)
	nsIWebNavigation *webnavigation;
    CODE:
	webnavigation->GoForward();

## GotoIndex(PRInt32 index)
void
moz_dom_GotoIndex (webnavigation, index)
	nsIWebNavigation *webnavigation;
	PRInt32  index;
    CODE:
	webnavigation->GotoIndex(index);

# XXX: I really want this! (how do you get an nsIInputStream, though?)
# [see mailing-list/xpcom/12660.txt & embedding/6646.txt
#  g++ testdom.cpp `mozilla-config xpcom --cflags --libs` -I /usr/include/mozilla/content -I /usr/include/mozilla/necko -I /usr/include/mozilla/string -o testdom -Wall
# need to link to xpcom and #include "nsCOMPtr.h"
# ]

#=for apidoc Mozilla::DOM::WebNavigation::LoadURI
#
#=for signature $webnavigation->LoadURI($uri, $loadflags, $referrer, $postdata, $headers)
#
#  * Loads a given URI.  This will give priority to loading the requested URI
#  * in the object implementing	this interface.  If it can''t be loaded here
#  * however, the URL dispatcher will go through its normal process of content
#  * loading.
#  *
#  * @param uri       - The URI string to load.
#  * @param loadFlags - Flags modifying load behaviour. Generally you will pass
#  *                    LOAD_FLAGS_NONE for this parameter.
#  * @param referrer  - The referring URI.  If this argument is NULL, the
#  *                    referring URI will be inferred internally.
#  * @param postData  - nsIInputStream containing POST data for the request.
#
#Note: there is a similar method in Gtk2::MozEmbed:
#
#  $embed->load_url($url)
#
#=cut
#
### LoadURI(const PRUnichar *uri, PRUint32 loadFlags, nsIURI *referrer, nsIInputStream *postData, nsIInputStream *headers)
#void
#moz_dom_LoadURI (webnavigation, uri, loadFlags, referrer, postData, headers)
#	nsIWebNavigation *webnavigation;
#	const PRUnichar * uri;
#	PRUint32  loadFlags;
#	nsIURI * referrer;
#	nsIInputStream * postData;
#	nsIInputStream * headers;
#    CODE:
#	webnavigation->LoadURI(uri, loadFlags, referrer, postData, headers);

## Reload(PRUint32 reloadFlags)
void
moz_dom_Reload (webnavigation, reloadFlags)
	nsIWebNavigation *webnavigation;
	PRUint32  reloadFlags;
    CODE:
	webnavigation->Reload(reloadFlags);

## Stop(PRUint32 stopFlags)
void
moz_dom_Stop (webnavigation, stopFlags)
	nsIWebNavigation *webnavigation;
	PRUint32  stopFlags;
    CODE:
	webnavigation->Stop(stopFlags);

## GetDocument(nsIDOMDocument * *aDocument)
nsIDOMDocument *
moz_dom_GetDocument (webnavigation)
	nsIWebNavigation *webnavigation;
    PREINIT:
	nsIDOMDocument * aDocument;
    CODE:
	webnavigation->GetDocument(&aDocument);
	RETVAL = aDocument;
    OUTPUT:
	RETVAL

## GetCurrentURI(nsIURI * *aCurrentURI)
nsIURI *
moz_dom_GetCurrentURI (webnavigation)
	nsIWebNavigation *webnavigation;
    PREINIT:
	nsIURI * aCurrentURI;
    CODE:
	webnavigation->GetCurrentURI(&aCurrentURI);
	RETVAL = aCurrentURI;
    OUTPUT:
	RETVAL

## GetReferringURI(nsIURI * *aReferringURI)
nsIURI *
moz_dom_GetReferringURI (webnavigation)
	nsIWebNavigation *webnavigation;
    PREINIT:
	nsIURI * aReferringURI;
    CODE:
	webnavigation->GetReferringURI(&aReferringURI);
	RETVAL = aReferringURI;
    OUTPUT:
	RETVAL

#=for apidoc Mozilla::DOM::WebNavigation::GetSessionHistory
#
#=for signature $sessionhistory = $webnavigation->GetSessionHistory()
#
#  * The session history object used to store the session history for the
#  * session.
#
#=cut
#
### GetSessionHistory(nsISHistory * *aSessionHistory)
#nsISHistory *
#moz_dom_GetSessionHistory (webnavigation)
#	nsIWebNavigation *webnavigation;
#    PREINIT:
#	nsISHistory * aSessionHistory;
#    CODE:
#	webnavigation->GetSessionHistory(&aSessionHistory);
#	RETVAL = aSessionHistory;
#    OUTPUT:
#	RETVAL
#
#=for apidoc Mozilla::DOM::WebNavigation::SetSessionHistory
#
#=for signature $webnavigation->SetSessionHistory($sessionhistory)
#
#
#
#=cut
#
### SetSessionHistory(nsISHistory * aSessionHistory)
#void
#moz_dom_SetSessionHistory (webnavigation, aSessionHistory)
#	nsIWebNavigation *webnavigation;
#	nsISHistory *  aSessionHistory;
#    CODE:
#	webnavigation->SetSessionHistory(aSessionHistory);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::URI	PREFIX = moz_dom_

# /usr/include/mozilla/nsIURI.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IURI_IID)
static nsIID
nsIURI::GetIID()
    CODE:
	const nsIID &id = nsIURI::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetSpec(nsACString & aSpec)
nsEmbedCString
moz_dom_GetSpec (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aSpec;
    CODE:
	uri->GetSpec(aSpec);
	RETVAL = aSpec;
    OUTPUT:
	RETVAL

## SetSpec(const nsACString & aSpec)
void
moz_dom_SetSpec (uri, aSpec)
	nsIURI *uri;
	nsEmbedCString aSpec;
    CODE:
	uri->SetSpec(aSpec);

## GetPrePath(nsACString & aPrePath)
nsEmbedCString
moz_dom_GetPrePath (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aPrePath;
    CODE:
	uri->GetPrePath(aPrePath);
	RETVAL = aPrePath;
    OUTPUT:
	RETVAL

## GetScheme(nsACString & aScheme)
nsEmbedCString
moz_dom_GetScheme (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aScheme;
    CODE:
	uri->GetScheme(aScheme);
	RETVAL = aScheme;
    OUTPUT:
	RETVAL

## SetScheme(const nsACString & aScheme)
void
moz_dom_SetScheme (uri, aScheme)
	nsIURI *uri;
	nsEmbedCString aScheme;
    CODE:
	uri->SetScheme(aScheme);

## GetUserPass(nsACString & aUserPass)
nsEmbedCString
moz_dom_GetUserPass (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aUserPass;
    CODE:
	uri->GetUserPass(aUserPass);
	RETVAL = aUserPass;
    OUTPUT:
	RETVAL

## SetUserPass(const nsACString & aUserPass)
void
moz_dom_SetUserPass (uri, aUserPass)
	nsIURI *uri;
	nsEmbedCString aUserPass;
    CODE:
	uri->SetUserPass(aUserPass);

## GetUsername(nsACString & aUsername)
nsEmbedCString
moz_dom_GetUsername (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aUsername;
    CODE:
	uri->GetUsername(aUsername);
	RETVAL = aUsername;
    OUTPUT:
	RETVAL

## SetUsername(const nsACString & aUsername)
void
moz_dom_SetUsername (uri, aUsername)
	nsIURI *uri;
	nsEmbedCString aUsername;
    CODE:
	uri->SetUsername(aUsername);

## GetPassword(nsACString & aPassword)
nsEmbedCString
moz_dom_GetPassword (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aPassword;
    CODE:
	uri->GetPassword(aPassword);
	RETVAL = aPassword;
    OUTPUT:
	RETVAL

## SetPassword(const nsACString & aPassword)
void
moz_dom_SetPassword (uri, aPassword)
	nsIURI *uri;
	nsEmbedCString aPassword;
    CODE:
	uri->SetPassword(aPassword);

## GetHostPort(nsACString & aHostPort)
nsEmbedCString
moz_dom_GetHostPort (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aHostPort;
    CODE:
	uri->GetHostPort(aHostPort);
	RETVAL = aHostPort;
    OUTPUT:
	RETVAL

## SetHostPort(const nsACString & aHostPort)
void
moz_dom_SetHostPort (uri, aHostPort)
	nsIURI *uri;
	nsEmbedCString aHostPort;
    CODE:
	uri->SetHostPort(aHostPort);

## GetHost(nsACString & aHost)
nsEmbedCString
moz_dom_GetHost (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aHost;
    CODE:
	uri->GetHost(aHost);
	RETVAL = aHost;
    OUTPUT:
	RETVAL

## SetHost(const nsACString & aHost)
void
moz_dom_SetHost (uri, aHost)
	nsIURI *uri;
	nsEmbedCString aHost;
    CODE:
	uri->SetHost(aHost);

## GetPort(PRInt32 *aPort)
PRInt32
moz_dom_GetPort (uri)
	nsIURI *uri;
    PREINIT:
	PRInt32 aPort;
    CODE:
	uri->GetPort(&aPort);
	RETVAL = aPort;
    OUTPUT:
	RETVAL

## SetPort(PRInt32 aPort)
void
moz_dom_SetPort (uri, aPort)
	nsIURI *uri;
	PRInt32  aPort;
    CODE:
	uri->SetPort(aPort);

## GetPath(nsACString & aPath)
nsEmbedCString
moz_dom_GetPath (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aPath;
    CODE:
	uri->GetPath(aPath);
	RETVAL = aPath;
    OUTPUT:
	RETVAL

## SetPath(const nsACString & aPath)
void
moz_dom_SetPath (uri, aPath)
	nsIURI *uri;
	nsEmbedCString aPath;
    CODE:
	uri->SetPath(aPath);

## Equals(nsIURI *other, PRBool *_retval)
PRBool
moz_dom_Equals (uri, other)
	nsIURI *uri;
	nsIURI * other;
    PREINIT:
	PRBool _retval;
    CODE:
	uri->Equals(other, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## SchemeIs(const char *scheme, PRBool *_retval)
PRBool
moz_dom_SchemeIs (uri, scheme)
	nsIURI *uri;
	const char * scheme;
    PREINIT:
	PRBool _retval;
    CODE:
	uri->SchemeIs(scheme, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Clone(nsIURI **_retval)
nsIURI *
moz_dom_Clone (uri)
	nsIURI *uri;
    PREINIT:
	nsIURI * _retval;
    CODE:
	uri->Clone(&_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Resolve(const nsACString & relativePath, nsACString & _retval)
nsEmbedCString
moz_dom_Resolve (uri, relativePath)
	nsIURI *uri;
	nsEmbedCString relativePath;
    PREINIT:
	nsEmbedCString _retval;
    CODE:
	uri->Resolve(relativePath, _retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## GetAsciiSpec(nsACString & aAsciiSpec)
nsEmbedCString
moz_dom_GetAsciiSpec (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aAsciiSpec;
    CODE:
	uri->GetAsciiSpec(aAsciiSpec);
	RETVAL = aAsciiSpec;
    OUTPUT:
	RETVAL

## GetAsciiHost(nsACString & aAsciiHost)
nsEmbedCString
moz_dom_GetAsciiHost (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aAsciiHost;
    CODE:
	uri->GetAsciiHost(aAsciiHost);
	RETVAL = aAsciiHost;
    OUTPUT:
	RETVAL

## GetOriginCharset(nsACString & aOriginCharset)
nsEmbedCString
moz_dom_GetOriginCharset (uri)
	nsIURI *uri;
    PREINIT:
	nsEmbedCString aOriginCharset;
    CODE:
	uri->GetOriginCharset(aOriginCharset);
	RETVAL = aOriginCharset;
    OUTPUT:
	RETVAL


# -----------------------------------------------------------------------------
# nsIDOMHTML*Element !
# -----------------------------------------------------------------------------


MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLAnchorElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLAnchorElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLANCHORELEMENT_IID)
static nsIID
nsIDOMHTMLAnchorElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLAnchorElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAccessKey(nsAString & aAccessKey)
nsEmbedString
moz_dom_GetAccessKey (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString accesskey;
    CODE:
	htmlanchorelement->GetAccessKey(accesskey);
	RETVAL = accesskey;
    OUTPUT:
	RETVAL

## SetAccessKey(const nsAString & aAccessKey)
void
moz_dom_SetAccessKey (htmlanchorelement, accesskey)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString accesskey;
    CODE:
	htmlanchorelement->SetAccessKey(accesskey);

## GetCharset(nsAString & aCharset)
nsEmbedString
moz_dom_GetCharset (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString charset;
    CODE:
	htmlanchorelement->GetCharset(charset);
	RETVAL = charset;
    OUTPUT:
	RETVAL

## SetCharset(const nsAString & aCharset)
void
moz_dom_SetCharset (htmlanchorelement, charset)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString charset;
    CODE:
	htmlanchorelement->SetCharset(charset);

## GetCoords(nsAString & aCoords)
nsEmbedString
moz_dom_GetCoords (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString coords;
    CODE:
	htmlanchorelement->GetCoords(coords);
	RETVAL = coords;
    OUTPUT:
	RETVAL

## SetCoords(const nsAString & aCoords)
void
moz_dom_SetCoords (htmlanchorelement, coords)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString coords;
    CODE:
	htmlanchorelement->SetCoords(coords);

## GetHref(nsAString & aHref)
nsEmbedString
moz_dom_GetHref (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString href;
    CODE:
	htmlanchorelement->GetHref(href);
	RETVAL = href;
    OUTPUT:
	RETVAL

## SetHref(const nsAString & aHref)
void
moz_dom_SetHref (htmlanchorelement, href)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString href;
    CODE:
	htmlanchorelement->SetHref(href);

## GetHreflang(nsAString & aHreflang)
nsEmbedString
moz_dom_GetHreflang (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString hreflang;
    CODE:
	htmlanchorelement->GetHreflang(hreflang);
	RETVAL = hreflang;
    OUTPUT:
	RETVAL

## SetHreflang(const nsAString & aHreflang)
void
moz_dom_SetHreflang (htmlanchorelement, hreflang)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString hreflang;
    CODE:
	htmlanchorelement->SetHreflang(hreflang);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlanchorelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlanchorelement, name)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString name;
    CODE:
	htmlanchorelement->SetName(name);

## GetRel(nsAString & aRel)
nsEmbedString
moz_dom_GetRel (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString rel;
    CODE:
	htmlanchorelement->GetRel(rel);
	RETVAL = rel;
    OUTPUT:
	RETVAL

## SetRel(const nsAString & aRel)
void
moz_dom_SetRel (htmlanchorelement, rel)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString rel;
    CODE:
	htmlanchorelement->SetRel(rel);

## GetRev(nsAString & aRev)
nsEmbedString
moz_dom_GetRev (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString rev;
    CODE:
	htmlanchorelement->GetRev(rev);
	RETVAL = rev;
    OUTPUT:
	RETVAL

## SetRev(const nsAString & aRev)
void
moz_dom_SetRev (htmlanchorelement, rev)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString rev;
    CODE:
	htmlanchorelement->SetRev(rev);

## GetShape(nsAString & aShape)
nsEmbedString
moz_dom_GetShape (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString shape;
    CODE:
	htmlanchorelement->GetShape(shape);
	RETVAL = shape;
    OUTPUT:
	RETVAL

## SetShape(const nsAString & aShape)
void
moz_dom_SetShape (htmlanchorelement, shape)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString shape;
    CODE:
	htmlanchorelement->SetShape(shape);

## GetTabIndex(PRInt32 *aTabIndex)
PRInt32
moz_dom_GetTabIndex (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	PRInt32 tabindex;
    CODE:
	htmlanchorelement->GetTabIndex(&tabindex);
	RETVAL = tabindex;
    OUTPUT:
	RETVAL

## SetTabIndex(PRInt32 aTabIndex)
void
moz_dom_SetTabIndex (htmlanchorelement, tabindex)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	PRInt32  tabindex;
    CODE:
	htmlanchorelement->SetTabIndex(tabindex);

## GetTarget(nsAString & aTarget)
nsEmbedString
moz_dom_GetTarget (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString target;
    CODE:
	htmlanchorelement->GetTarget(target);
	RETVAL = target;
    OUTPUT:
	RETVAL

## SetTarget(const nsAString & aTarget)
void
moz_dom_SetTarget (htmlanchorelement, target)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString target;
    CODE:
	htmlanchorelement->SetTarget(target);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlanchorelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlanchorelement, type)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
	nsEmbedString type;
    CODE:
	htmlanchorelement->SetType(type);

## Blur(void)
void
moz_dom_Blur (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    CODE:
	htmlanchorelement->Blur();

## Focus(void)
void
moz_dom_Focus (htmlanchorelement)
	nsIDOMHTMLAnchorElement *htmlanchorelement;
    CODE:
	htmlanchorelement->Focus();

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLAppletElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLAppletElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLAPPLETELEMENT_IID)
static nsIID
nsIDOMHTMLAppletElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLAppletElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlappletelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlappletelement, align)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString align;
    CODE:
	htmlappletelement->SetAlign(align);

## GetAlt(nsAString & aAlt)
nsEmbedString
moz_dom_GetAlt (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString alt;
    CODE:
	htmlappletelement->GetAlt(alt);
	RETVAL = alt;
    OUTPUT:
	RETVAL

## SetAlt(const nsAString & aAlt)
void
moz_dom_SetAlt (htmlappletelement, alt)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString alt;
    CODE:
	htmlappletelement->SetAlt(alt);

## GetArchive(nsAString & aArchive)
nsEmbedString
moz_dom_GetArchive (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString archive;
    CODE:
	htmlappletelement->GetArchive(archive);
	RETVAL = archive;
    OUTPUT:
	RETVAL

## SetArchive(const nsAString & aArchive)
void
moz_dom_SetArchive (htmlappletelement, archive)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString archive;
    CODE:
	htmlappletelement->SetArchive(archive);

## GetCode(nsAString & aCode)
nsEmbedString
moz_dom_GetCode (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString code;
    CODE:
	htmlappletelement->GetCode(code);
	RETVAL = code;
    OUTPUT:
	RETVAL

## SetCode(const nsAString & aCode)
void
moz_dom_SetCode (htmlappletelement, code)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString code;
    CODE:
	htmlappletelement->SetCode(code);

## GetCodeBase(nsAString & aCodeBase)
nsEmbedString
moz_dom_GetCodeBase (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString codebase;
    CODE:
	htmlappletelement->GetCodeBase(codebase);
	RETVAL = codebase;
    OUTPUT:
	RETVAL

## SetCodeBase(const nsAString & aCodeBase)
void
moz_dom_SetCodeBase (htmlappletelement, codebase)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString codebase;
    CODE:
	htmlappletelement->SetCodeBase(codebase);

## GetHeight(nsAString & aHeight)
nsEmbedString
moz_dom_GetHeight (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString height;
    CODE:
	htmlappletelement->GetHeight(height);
	RETVAL = height;
    OUTPUT:
	RETVAL

## SetHeight(const nsAString & aHeight)
void
moz_dom_SetHeight (htmlappletelement, height)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString height;
    CODE:
	htmlappletelement->SetHeight(height);

## GetHspace(PRInt32 *aHspace)
PRInt32
moz_dom_GetHspace (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	PRInt32 hspace;
    CODE:
	htmlappletelement->GetHspace(&hspace);
	RETVAL = hspace;
    OUTPUT:
	RETVAL

## SetHspace(PRInt32 aHspace)
void
moz_dom_SetHspace (htmlappletelement, hspace)
	nsIDOMHTMLAppletElement *htmlappletelement;
	PRInt32  hspace;
    CODE:
	htmlappletelement->SetHspace(hspace);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlappletelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlappletelement, name)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString name;
    CODE:
	htmlappletelement->SetName(name);

## GetObject(nsAString & aObject)
nsEmbedString
moz_dom_GetObject (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString object;
    CODE:
	htmlappletelement->GetObject(object);
	RETVAL = object;
    OUTPUT:
	RETVAL

## SetObject(const nsAString & aObject)
void
moz_dom_SetObject (htmlappletelement, object)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString object;
    CODE:
	htmlappletelement->SetObject(object);

## GetVspace(PRInt32 *aVspace)
PRInt32
moz_dom_GetVspace (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	PRInt32 vspace;
    CODE:
	htmlappletelement->GetVspace(&vspace);
	RETVAL = vspace;
    OUTPUT:
	RETVAL

## SetVspace(PRInt32 aVspace)
void
moz_dom_SetVspace (htmlappletelement, vspace)
	nsIDOMHTMLAppletElement *htmlappletelement;
	PRInt32  vspace;
    CODE:
	htmlappletelement->SetVspace(vspace);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmlappletelement)
	nsIDOMHTMLAppletElement *htmlappletelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmlappletelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmlappletelement, width)
	nsIDOMHTMLAppletElement *htmlappletelement;
	nsEmbedString width;
    CODE:
	htmlappletelement->SetWidth(width);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLAreaElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLAreaElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLAREAELEMENT_IID)
static nsIID
nsIDOMHTMLAreaElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLAreaElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAccessKey(nsAString & aAccessKey)
nsEmbedString
moz_dom_GetAccessKey (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	nsEmbedString accesskey;
    CODE:
	htmlareaelement->GetAccessKey(accesskey);
	RETVAL = accesskey;
    OUTPUT:
	RETVAL

## SetAccessKey(const nsAString & aAccessKey)
void
moz_dom_SetAccessKey (htmlareaelement, accesskey)
	nsIDOMHTMLAreaElement *htmlareaelement;
	nsEmbedString accesskey;
    CODE:
	htmlareaelement->SetAccessKey(accesskey);

## GetAlt(nsAString & aAlt)
nsEmbedString
moz_dom_GetAlt (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	nsEmbedString alt;
    CODE:
	htmlareaelement->GetAlt(alt);
	RETVAL = alt;
    OUTPUT:
	RETVAL

## SetAlt(const nsAString & aAlt)
void
moz_dom_SetAlt (htmlareaelement, alt)
	nsIDOMHTMLAreaElement *htmlareaelement;
	nsEmbedString alt;
    CODE:
	htmlareaelement->SetAlt(alt);

## GetCoords(nsAString & aCoords)
nsEmbedString
moz_dom_GetCoords (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	nsEmbedString coords;
    CODE:
	htmlareaelement->GetCoords(coords);
	RETVAL = coords;
    OUTPUT:
	RETVAL

## SetCoords(const nsAString & aCoords)
void
moz_dom_SetCoords (htmlareaelement, coords)
	nsIDOMHTMLAreaElement *htmlareaelement;
	nsEmbedString coords;
    CODE:
	htmlareaelement->SetCoords(coords);

## GetHref(nsAString & aHref)
nsEmbedString
moz_dom_GetHref (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	nsEmbedString href;
    CODE:
	htmlareaelement->GetHref(href);
	RETVAL = href;
    OUTPUT:
	RETVAL

## SetHref(const nsAString & aHref)
void
moz_dom_SetHref (htmlareaelement, href)
	nsIDOMHTMLAreaElement *htmlareaelement;
	nsEmbedString href;
    CODE:
	htmlareaelement->SetHref(href);

## GetNoHref(PRBool *aNoHref)
PRBool
moz_dom_GetNoHref (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	PRBool nohref;
    CODE:
	htmlareaelement->GetNoHref(&nohref);
	RETVAL = nohref;
    OUTPUT:
	RETVAL

## SetNoHref(PRBool aNoHref)
void
moz_dom_SetNoHref (htmlareaelement, nohref)
	nsIDOMHTMLAreaElement *htmlareaelement;
	PRBool  nohref;
    CODE:
	htmlareaelement->SetNoHref(nohref);

## GetShape(nsAString & aShape)
nsEmbedString
moz_dom_GetShape (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	nsEmbedString shape;
    CODE:
	htmlareaelement->GetShape(shape);
	RETVAL = shape;
    OUTPUT:
	RETVAL

## SetShape(const nsAString & aShape)
void
moz_dom_SetShape (htmlareaelement, shape)
	nsIDOMHTMLAreaElement *htmlareaelement;
	nsEmbedString shape;
    CODE:
	htmlareaelement->SetShape(shape);

## GetTabIndex(PRInt32 *aTabIndex)
PRInt32
moz_dom_GetTabIndex (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	PRInt32 tabindex;
    CODE:
	htmlareaelement->GetTabIndex(&tabindex);
	RETVAL = tabindex;
    OUTPUT:
	RETVAL

## SetTabIndex(PRInt32 aTabIndex)
void
moz_dom_SetTabIndex (htmlareaelement, tabindex)
	nsIDOMHTMLAreaElement *htmlareaelement;
	PRInt32  tabindex;
    CODE:
	htmlareaelement->SetTabIndex(tabindex);

## GetTarget(nsAString & aTarget)
nsEmbedString
moz_dom_GetTarget (htmlareaelement)
	nsIDOMHTMLAreaElement *htmlareaelement;
    PREINIT:
	nsEmbedString target;
    CODE:
	htmlareaelement->GetTarget(target);
	RETVAL = target;
    OUTPUT:
	RETVAL

## SetTarget(const nsAString & aTarget)
void
moz_dom_SetTarget (htmlareaelement, target)
	nsIDOMHTMLAreaElement *htmlareaelement;
	nsEmbedString target;
    CODE:
	htmlareaelement->SetTarget(target);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLBRElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLBRElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLBRELEMENT_IID)
static nsIID
nsIDOMHTMLBRElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLBRElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetClear(nsAString & aClear)
nsEmbedString
moz_dom_GetClear (htmlbrelement)
	nsIDOMHTMLBRElement *htmlbrelement;
    PREINIT:
	nsEmbedString clear;
    CODE:
	htmlbrelement->GetClear(clear);
	RETVAL = clear;
    OUTPUT:
	RETVAL

## SetClear(const nsAString & aClear)
void
moz_dom_SetClear (htmlbrelement, clear)
	nsIDOMHTMLBRElement *htmlbrelement;
	nsEmbedString clear;
    CODE:
	htmlbrelement->SetClear(clear);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLBaseElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLBaseElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLBASEELEMENT_IID)
static nsIID
nsIDOMHTMLBaseElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLBaseElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetHref(nsAString & aHref)
nsEmbedString
moz_dom_GetHref (htmlbaseelement)
	nsIDOMHTMLBaseElement *htmlbaseelement;
    PREINIT:
	nsEmbedString href;
    CODE:
	htmlbaseelement->GetHref(href);
	RETVAL = href;
    OUTPUT:
	RETVAL

## SetHref(const nsAString & aHref)
void
moz_dom_SetHref (htmlbaseelement, href)
	nsIDOMHTMLBaseElement *htmlbaseelement;
	nsEmbedString href;
    CODE:
	htmlbaseelement->SetHref(href);

## GetTarget(nsAString & aTarget)
nsEmbedString
moz_dom_GetTarget (htmlbaseelement)
	nsIDOMHTMLBaseElement *htmlbaseelement;
    PREINIT:
	nsEmbedString target;
    CODE:
	htmlbaseelement->GetTarget(target);
	RETVAL = target;
    OUTPUT:
	RETVAL

## SetTarget(const nsAString & aTarget)
void
moz_dom_SetTarget (htmlbaseelement, target)
	nsIDOMHTMLBaseElement *htmlbaseelement;
	nsEmbedString target;
    CODE:
	htmlbaseelement->SetTarget(target);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLBaseFontElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLBaseFontElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLBASEFONTELEMENT_IID)
static nsIID
nsIDOMHTMLBaseFontElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLBaseFontElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetColor(nsAString & aColor)
nsEmbedString
moz_dom_GetColor (htmlbasefontelement)
	nsIDOMHTMLBaseFontElement *htmlbasefontelement;
    PREINIT:
	nsEmbedString color;
    CODE:
	htmlbasefontelement->GetColor(color);
	RETVAL = color;
    OUTPUT:
	RETVAL

## SetColor(const nsAString & aColor)
void
moz_dom_SetColor (htmlbasefontelement, color)
	nsIDOMHTMLBaseFontElement *htmlbasefontelement;
	nsEmbedString color;
    CODE:
	htmlbasefontelement->SetColor(color);

## GetFace(nsAString & aFace)
nsEmbedString
moz_dom_GetFace (htmlbasefontelement)
	nsIDOMHTMLBaseFontElement *htmlbasefontelement;
    PREINIT:
	nsEmbedString face;
    CODE:
	htmlbasefontelement->GetFace(face);
	RETVAL = face;
    OUTPUT:
	RETVAL

## SetFace(const nsAString & aFace)
void
moz_dom_SetFace (htmlbasefontelement, face)
	nsIDOMHTMLBaseFontElement *htmlbasefontelement;
	nsEmbedString face;
    CODE:
	htmlbasefontelement->SetFace(face);

## GetSize(PRInt32 *aSize)
PRInt32
moz_dom_GetSize (htmlbasefontelement)
	nsIDOMHTMLBaseFontElement *htmlbasefontelement;
    PREINIT:
	PRInt32 size;
    CODE:
	htmlbasefontelement->GetSize(&size);
	RETVAL = size;
    OUTPUT:
	RETVAL

## SetSize(PRInt32 aSize)
void
moz_dom_SetSize (htmlbasefontelement, size)
	nsIDOMHTMLBaseFontElement *htmlbasefontelement;
	PRInt32  size;
    CODE:
	htmlbasefontelement->SetSize(size);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLBodyElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLBodyElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLBODYELEMENT_IID)
static nsIID
nsIDOMHTMLBodyElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLBodyElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetALink(nsAString & aALink)
nsEmbedString
moz_dom_GetALink (htmlbodyelement)
	nsIDOMHTMLBodyElement *htmlbodyelement;
    PREINIT:
	nsEmbedString alink;
    CODE:
	htmlbodyelement->GetALink(alink);
	RETVAL = alink;
    OUTPUT:
	RETVAL

## SetALink(const nsAString & aALink)
void
moz_dom_SetALink (htmlbodyelement, alink)
	nsIDOMHTMLBodyElement *htmlbodyelement;
	nsEmbedString alink;
    CODE:
	htmlbodyelement->SetALink(alink);

## GetBackground(nsAString & aBackground)
nsEmbedString
moz_dom_GetBackground (htmlbodyelement)
	nsIDOMHTMLBodyElement *htmlbodyelement;
    PREINIT:
	nsEmbedString background;
    CODE:
	htmlbodyelement->GetBackground(background);
	RETVAL = background;
    OUTPUT:
	RETVAL

## SetBackground(const nsAString & aBackground)
void
moz_dom_SetBackground (htmlbodyelement, background)
	nsIDOMHTMLBodyElement *htmlbodyelement;
	nsEmbedString background;
    CODE:
	htmlbodyelement->SetBackground(background);

## GetBgColor(nsAString & aBgColor)
nsEmbedString
moz_dom_GetBgColor (htmlbodyelement)
	nsIDOMHTMLBodyElement *htmlbodyelement;
    PREINIT:
	nsEmbedString bgcolor;
    CODE:
	htmlbodyelement->GetBgColor(bgcolor);
	RETVAL = bgcolor;
    OUTPUT:
	RETVAL

## SetBgColor(const nsAString & aBgColor)
void
moz_dom_SetBgColor (htmlbodyelement, bgcolor)
	nsIDOMHTMLBodyElement *htmlbodyelement;
	nsEmbedString bgcolor;
    CODE:
	htmlbodyelement->SetBgColor(bgcolor);

## GetLink(nsAString & aLink)
nsEmbedString
moz_dom_GetLink (htmlbodyelement)
	nsIDOMHTMLBodyElement *htmlbodyelement;
    PREINIT:
	nsEmbedString link;
    CODE:
	htmlbodyelement->GetLink(link);
	RETVAL = link;
    OUTPUT:
	RETVAL

## SetLink(const nsAString & aLink)
void
moz_dom_SetLink (htmlbodyelement, link)
	nsIDOMHTMLBodyElement *htmlbodyelement;
	nsEmbedString link;
    CODE:
	htmlbodyelement->SetLink(link);

## GetText(nsAString & aText)
nsEmbedString
moz_dom_GetText (htmlbodyelement)
	nsIDOMHTMLBodyElement *htmlbodyelement;
    PREINIT:
	nsEmbedString text;
    CODE:
	htmlbodyelement->GetText(text);
	RETVAL = text;
    OUTPUT:
	RETVAL

## SetText(const nsAString & aText)
void
moz_dom_SetText (htmlbodyelement, text)
	nsIDOMHTMLBodyElement *htmlbodyelement;
	nsEmbedString text;
    CODE:
	htmlbodyelement->SetText(text);

## GetVLink(nsAString & aVLink)
nsEmbedString
moz_dom_GetVLink (htmlbodyelement)
	nsIDOMHTMLBodyElement *htmlbodyelement;
    PREINIT:
	nsEmbedString vlink;
    CODE:
	htmlbodyelement->GetVLink(vlink);
	RETVAL = vlink;
    OUTPUT:
	RETVAL

## SetVLink(const nsAString & aVLink)
void
moz_dom_SetVLink (htmlbodyelement, vlink)
	nsIDOMHTMLBodyElement *htmlbodyelement;
	nsEmbedString vlink;
    CODE:
	htmlbodyelement->SetVLink(vlink);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLButtonElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLButtonElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLBUTTONELEMENT_IID)
static nsIID
nsIDOMHTMLButtonElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLButtonElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmlbuttonelement)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmlbuttonelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetAccessKey(nsAString & aAccessKey)
nsEmbedString
moz_dom_GetAccessKey (htmlbuttonelement)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
    PREINIT:
	nsEmbedString accesskey;
    CODE:
	htmlbuttonelement->GetAccessKey(accesskey);
	RETVAL = accesskey;
    OUTPUT:
	RETVAL

## SetAccessKey(const nsAString & aAccessKey)
void
moz_dom_SetAccessKey (htmlbuttonelement, accesskey)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
	nsEmbedString accesskey;
    CODE:
	htmlbuttonelement->SetAccessKey(accesskey);

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmlbuttonelement)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmlbuttonelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmlbuttonelement, disabled)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
	PRBool  disabled;
    CODE:
	htmlbuttonelement->SetDisabled(disabled);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlbuttonelement)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlbuttonelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlbuttonelement, name)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
	nsEmbedString name;
    CODE:
	htmlbuttonelement->SetName(name);

## GetTabIndex(PRInt32 *aTabIndex)
PRInt32
moz_dom_GetTabIndex (htmlbuttonelement)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
    PREINIT:
	PRInt32 tabindex;
    CODE:
	htmlbuttonelement->GetTabIndex(&tabindex);
	RETVAL = tabindex;
    OUTPUT:
	RETVAL

## SetTabIndex(PRInt32 aTabIndex)
void
moz_dom_SetTabIndex (htmlbuttonelement, tabindex)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
	PRInt32  tabindex;
    CODE:
	htmlbuttonelement->SetTabIndex(tabindex);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlbuttonelement)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlbuttonelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## GetValue(nsAString & aValue)
nsEmbedString
moz_dom_GetValue (htmlbuttonelement)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
    PREINIT:
	nsEmbedString value;
    CODE:
	htmlbuttonelement->GetValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(const nsAString & aValue)
void
moz_dom_SetValue (htmlbuttonelement, value)
	nsIDOMHTMLButtonElement *htmlbuttonelement;
	nsEmbedString value;
    CODE:
	htmlbuttonelement->SetValue(value);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLCollection	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLCollection.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLCOLLECTION_IID)
static nsIID
nsIDOMHTMLCollection::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLCollection::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (htmlcollection)
	nsIDOMHTMLCollection *htmlcollection;
    PREINIT:
	PRUint32 length;
    CODE:
	htmlcollection->GetLength(&length);
	RETVAL = length;
    OUTPUT:
	RETVAL

## Item(PRUint32 index, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_Item (htmlcollection, index)
	nsIDOMHTMLCollection *htmlcollection;
	PRUint32  index;
    PREINIT:
	nsIDOMNode * retval;
    CODE:
	htmlcollection->Item(index, &retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## NamedItem(const nsAString & name, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_NamedItem (htmlcollection, name)
	nsIDOMHTMLCollection *htmlcollection;
	nsEmbedString name;
    PREINIT:
	nsIDOMNode * retval;
    CODE:
	htmlcollection->NamedItem(name, &retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLDListElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLDListElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLDLISTELEMENT_IID)
static nsIID
nsIDOMHTMLDListElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLDListElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCompact(PRBool *aCompact)
PRBool
moz_dom_GetCompact (htmldlistelement)
	nsIDOMHTMLDListElement *htmldlistelement;
    PREINIT:
	PRBool compact;
    CODE:
	htmldlistelement->GetCompact(&compact);
	RETVAL = compact;
    OUTPUT:
	RETVAL

## SetCompact(PRBool aCompact)
void
moz_dom_SetCompact (htmldlistelement, compact)
	nsIDOMHTMLDListElement *htmldlistelement;
	PRBool  compact;
    CODE:
	htmldlistelement->SetCompact(compact);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLDirectoryElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLDirectoryElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLDIRECTORYELEMENT_IID)
static nsIID
nsIDOMHTMLDirectoryElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLDirectoryElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCompact(PRBool *aCompact)
PRBool
moz_dom_GetCompact (htmldirectoryelement)
	nsIDOMHTMLDirectoryElement *htmldirectoryelement;
    PREINIT:
	PRBool compact;
    CODE:
	htmldirectoryelement->GetCompact(&compact);
	RETVAL = compact;
    OUTPUT:
	RETVAL

## SetCompact(PRBool aCompact)
void
moz_dom_SetCompact (htmldirectoryelement, compact)
	nsIDOMHTMLDirectoryElement *htmldirectoryelement;
	PRBool  compact;
    CODE:
	htmldirectoryelement->SetCompact(compact);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLDivElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLDivElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLDIVELEMENT_IID)
static nsIID
nsIDOMHTMLDivElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLDivElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmldivelement)
	nsIDOMHTMLDivElement *htmldivelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmldivelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmldivelement, align)
	nsIDOMHTMLDivElement *htmldivelement;
	nsEmbedString align;
    CODE:
	htmldivelement->SetAlign(align);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLELEMENT_IID)
static nsIID
nsIDOMHTMLElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetId(nsAString & aId)
nsEmbedString
moz_dom_GetId (htmlelement)
	nsIDOMHTMLElement *htmlelement;
    PREINIT:
	nsEmbedString id;
    CODE:
	htmlelement->GetId(id);
	RETVAL = id;
    OUTPUT:
	RETVAL

## SetId(const nsAString & aId)
void
moz_dom_SetId (htmlelement, id)
	nsIDOMHTMLElement *htmlelement;
	nsEmbedString id;
    CODE:
	htmlelement->SetId(id);

## GetTitle(nsAString & aTitle)
nsEmbedString
moz_dom_GetTitle (htmlelement)
	nsIDOMHTMLElement *htmlelement;
    PREINIT:
	nsEmbedString title;
    CODE:
	htmlelement->GetTitle(title);
	RETVAL = title;
    OUTPUT:
	RETVAL

## SetTitle(const nsAString & aTitle)
void
moz_dom_SetTitle (htmlelement, title)
	nsIDOMHTMLElement *htmlelement;
	nsEmbedString title;
    CODE:
	htmlelement->SetTitle(title);

## GetLang(nsAString & aLang)
nsEmbedString
moz_dom_GetLang (htmlelement)
	nsIDOMHTMLElement *htmlelement;
    PREINIT:
	nsEmbedString lang;
    CODE:
	htmlelement->GetLang(lang);
	RETVAL = lang;
    OUTPUT:
	RETVAL

## SetLang(const nsAString & aLang)
void
moz_dom_SetLang (htmlelement, lang)
	nsIDOMHTMLElement *htmlelement;
	nsEmbedString lang;
    CODE:
	htmlelement->SetLang(lang);

## GetDir(nsAString & aDir)
nsEmbedString
moz_dom_GetDir (htmlelement)
	nsIDOMHTMLElement *htmlelement;
    PREINIT:
	nsEmbedString dir;
    CODE:
	htmlelement->GetDir(dir);
	RETVAL = dir;
    OUTPUT:
	RETVAL

## SetDir(const nsAString & aDir)
void
moz_dom_SetDir (htmlelement, dir)
	nsIDOMHTMLElement *htmlelement;
	nsEmbedString dir;
    CODE:
	htmlelement->SetDir(dir);

## GetClassName(nsAString & aClassName)
nsEmbedString
moz_dom_GetClassName (htmlelement)
	nsIDOMHTMLElement *htmlelement;
    PREINIT:
	nsEmbedString classname;
    CODE:
	htmlelement->GetClassName(classname);
	RETVAL = classname;
    OUTPUT:
	RETVAL

## SetClassName(const nsAString & aClassName)
void
moz_dom_SetClassName (htmlelement, classname)
	nsIDOMHTMLElement *htmlelement;
	nsEmbedString classname;
    CODE:
	htmlelement->SetClassName(classname);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLELEMENT_IID)
static nsIID
nsIDOMNSHTMLElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetOffsetTop(PRInt32 *aOffsetTop)
PRInt32
moz_dom_GetOffsetTop (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aOffsetTop;
    CODE:
	nshtmlelement->GetOffsetTop(&aOffsetTop);
	RETVAL = aOffsetTop;
    OUTPUT:
	RETVAL

## GetOffsetLeft(PRInt32 *aOffsetLeft)
PRInt32
moz_dom_GetOffsetLeft (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aOffsetLeft;
    CODE:
	nshtmlelement->GetOffsetLeft(&aOffsetLeft);
	RETVAL = aOffsetLeft;
    OUTPUT:
	RETVAL

## GetOffsetWidth(PRInt32 *aOffsetWidth)
PRInt32
moz_dom_GetOffsetWidth (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aOffsetWidth;
    CODE:
	nshtmlelement->GetOffsetWidth(&aOffsetWidth);
	RETVAL = aOffsetWidth;
    OUTPUT:
	RETVAL

## GetOffsetHeight(PRInt32 *aOffsetHeight)
PRInt32
moz_dom_GetOffsetHeight (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aOffsetHeight;
    CODE:
	nshtmlelement->GetOffsetHeight(&aOffsetHeight);
	RETVAL = aOffsetHeight;
    OUTPUT:
	RETVAL

## GetOffsetParent(nsIDOMElement * *aOffsetParent)
nsIDOMElement *
moz_dom_GetOffsetParent (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	nsIDOMElement * aOffsetParent;
    CODE:
	nshtmlelement->GetOffsetParent(&aOffsetParent);
	RETVAL = aOffsetParent;
    OUTPUT:
	RETVAL

## GetInnerHTML(nsAString & aInnerHTML)
nsEmbedString
moz_dom_GetInnerHTML (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	nsEmbedString aInnerHTML;
    CODE:
	nshtmlelement->GetInnerHTML(aInnerHTML);
	RETVAL = aInnerHTML;
    OUTPUT:
	RETVAL

## SetInnerHTML(const nsAString & aInnerHTML)
void
moz_dom_SetInnerHTML (nshtmlelement, aInnerHTML)
	nsIDOMNSHTMLElement *nshtmlelement;
	nsEmbedString aInnerHTML;
    CODE:
	nshtmlelement->SetInnerHTML(aInnerHTML);

## GetScrollTop(PRInt32 *aScrollTop)
PRInt32
moz_dom_GetScrollTop (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aScrollTop;
    CODE:
	nshtmlelement->GetScrollTop(&aScrollTop);
	RETVAL = aScrollTop;
    OUTPUT:
	RETVAL

## SetScrollTop(PRInt32 aScrollTop)
void
moz_dom_SetScrollTop (nshtmlelement, aScrollTop)
	nsIDOMNSHTMLElement *nshtmlelement;
	PRInt32  aScrollTop;
    CODE:
	nshtmlelement->SetScrollTop(aScrollTop);

## GetScrollLeft(PRInt32 *aScrollLeft)
PRInt32
moz_dom_GetScrollLeft (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aScrollLeft;
    CODE:
	nshtmlelement->GetScrollLeft(&aScrollLeft);
	RETVAL = aScrollLeft;
    OUTPUT:
	RETVAL

## SetScrollLeft(PRInt32 aScrollLeft)
void
moz_dom_SetScrollLeft (nshtmlelement, aScrollLeft)
	nsIDOMNSHTMLElement *nshtmlelement;
	PRInt32  aScrollLeft;
    CODE:
	nshtmlelement->SetScrollLeft(aScrollLeft);

## GetScrollHeight(PRInt32 *aScrollHeight)
PRInt32
moz_dom_GetScrollHeight (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aScrollHeight;
    CODE:
	nshtmlelement->GetScrollHeight(&aScrollHeight);
	RETVAL = aScrollHeight;
    OUTPUT:
	RETVAL

## GetScrollWidth(PRInt32 *aScrollWidth)
PRInt32
moz_dom_GetScrollWidth (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aScrollWidth;
    CODE:
	nshtmlelement->GetScrollWidth(&aScrollWidth);
	RETVAL = aScrollWidth;
    OUTPUT:
	RETVAL

## GetClientHeight(PRInt32 *aClientHeight)
PRInt32
moz_dom_GetClientHeight (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aClientHeight;
    CODE:
	nshtmlelement->GetClientHeight(&aClientHeight);
	RETVAL = aClientHeight;
    OUTPUT:
	RETVAL

## GetClientWidth(PRInt32 *aClientWidth)
PRInt32
moz_dom_GetClientWidth (nshtmlelement)
	nsIDOMNSHTMLElement *nshtmlelement;
    PREINIT:
	PRInt32 aClientWidth;
    CODE:
	nshtmlelement->GetClientWidth(&aClientWidth);
	RETVAL = aClientWidth;
    OUTPUT:
	RETVAL

## ScrollIntoView(PRBool top)
void
moz_dom_ScrollIntoView (nshtmlelement, top)
	nsIDOMNSHTMLElement *nshtmlelement;
	PRBool  top;
    CODE:
	nshtmlelement->ScrollIntoView(top);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLEmbedElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLEmbedElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLEMBEDELEMENT_IID)
static nsIID
nsIDOMHTMLEmbedElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLEmbedElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlembedelement)
	nsIDOMHTMLEmbedElement *htmlembedelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlembedelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlembedelement, align)
	nsIDOMHTMLEmbedElement *htmlembedelement;
	nsEmbedString align;
    CODE:
	htmlembedelement->SetAlign(align);

## GetHeight(nsAString & aHeight)
nsEmbedString
moz_dom_GetHeight (htmlembedelement)
	nsIDOMHTMLEmbedElement *htmlembedelement;
    PREINIT:
	nsEmbedString height;
    CODE:
	htmlembedelement->GetHeight(height);
	RETVAL = height;
    OUTPUT:
	RETVAL

## SetHeight(const nsAString & aHeight)
void
moz_dom_SetHeight (htmlembedelement, height)
	nsIDOMHTMLEmbedElement *htmlembedelement;
	nsEmbedString height;
    CODE:
	htmlembedelement->SetHeight(height);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlembedelement)
	nsIDOMHTMLEmbedElement *htmlembedelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlembedelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlembedelement, name)
	nsIDOMHTMLEmbedElement *htmlembedelement;
	nsEmbedString name;
    CODE:
	htmlembedelement->SetName(name);

## GetSrc(nsAString & aSrc)
nsEmbedString
moz_dom_GetSrc (htmlembedelement)
	nsIDOMHTMLEmbedElement *htmlembedelement;
    PREINIT:
	nsEmbedString src;
    CODE:
	htmlembedelement->GetSrc(src);
	RETVAL = src;
    OUTPUT:
	RETVAL

## SetSrc(const nsAString & aSrc)
void
moz_dom_SetSrc (htmlembedelement, src)
	nsIDOMHTMLEmbedElement *htmlembedelement;
	nsEmbedString src;
    CODE:
	htmlembedelement->SetSrc(src);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlembedelement)
	nsIDOMHTMLEmbedElement *htmlembedelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlembedelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlembedelement, type)
	nsIDOMHTMLEmbedElement *htmlembedelement;
	nsEmbedString type;
    CODE:
	htmlembedelement->SetType(type);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmlembedelement)
	nsIDOMHTMLEmbedElement *htmlembedelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmlembedelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmlembedelement, width)
	nsIDOMHTMLEmbedElement *htmlembedelement;
	nsEmbedString width;
    CODE:
	htmlembedelement->SetWidth(width);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLFieldSetElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLFieldSetElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLFIELDSETELEMENT_IID)
static nsIID
nsIDOMHTMLFieldSetElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLFieldSetElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmlfieldsetelement)
	nsIDOMHTMLFieldSetElement *htmlfieldsetelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmlfieldsetelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLFontElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLFontElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLFONTELEMENT_IID)
static nsIID
nsIDOMHTMLFontElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLFontElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetColor(nsAString & aColor)
nsEmbedString
moz_dom_GetColor (htmlfontelement)
	nsIDOMHTMLFontElement *htmlfontelement;
    PREINIT:
	nsEmbedString color;
    CODE:
	htmlfontelement->GetColor(color);
	RETVAL = color;
    OUTPUT:
	RETVAL

## SetColor(const nsAString & aColor)
void
moz_dom_SetColor (htmlfontelement, color)
	nsIDOMHTMLFontElement *htmlfontelement;
	nsEmbedString color;
    CODE:
	htmlfontelement->SetColor(color);

## GetFace(nsAString & aFace)
nsEmbedString
moz_dom_GetFace (htmlfontelement)
	nsIDOMHTMLFontElement *htmlfontelement;
    PREINIT:
	nsEmbedString face;
    CODE:
	htmlfontelement->GetFace(face);
	RETVAL = face;
    OUTPUT:
	RETVAL

## SetFace(const nsAString & aFace)
void
moz_dom_SetFace (htmlfontelement, face)
	nsIDOMHTMLFontElement *htmlfontelement;
	nsEmbedString face;
    CODE:
	htmlfontelement->SetFace(face);

## GetSize(nsAString & aSize)
nsEmbedString
moz_dom_GetSize (htmlfontelement)
	nsIDOMHTMLFontElement *htmlfontelement;
    PREINIT:
	nsEmbedString size;
    CODE:
	htmlfontelement->GetSize(size);
	RETVAL = size;
    OUTPUT:
	RETVAL

## SetSize(const nsAString & aSize)
void
moz_dom_SetSize (htmlfontelement, size)
	nsIDOMHTMLFontElement *htmlfontelement;
	nsEmbedString size;
    CODE:
	htmlfontelement->SetSize(size);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLFormElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLFormElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLFORMELEMENT_IID)
static nsIID
nsIDOMHTMLFormElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLFormElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetElements(nsIDOMHTMLCollection * *aElements)
nsIDOMHTMLCollection *
moz_dom_GetElements_htmlcollection (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	nsIDOMHTMLCollection * elements;
    CODE:
	htmlformelement->GetElements(&elements);
	RETVAL = elements;
    OUTPUT:
	RETVAL

## GetLength(PRInt32 *aLength)
PRInt32
moz_dom_GetLength (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	PRInt32 length;
    CODE:
	htmlformelement->GetLength(&length);
	RETVAL = length;
    OUTPUT:
	RETVAL

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlformelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlformelement, name)
	nsIDOMHTMLFormElement *htmlformelement;
	nsEmbedString name;
    CODE:
	htmlformelement->SetName(name);

## GetAcceptCharset(nsAString & aAcceptCharset)
nsEmbedString
moz_dom_GetAcceptCharset (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	nsEmbedString acceptcharset;
    CODE:
	htmlformelement->GetAcceptCharset(acceptcharset);
	RETVAL = acceptcharset;
    OUTPUT:
	RETVAL

## SetAcceptCharset(const nsAString & aAcceptCharset)
void
moz_dom_SetAcceptCharset (htmlformelement, acceptcharset)
	nsIDOMHTMLFormElement *htmlformelement;
	nsEmbedString acceptcharset;
    CODE:
	htmlformelement->SetAcceptCharset(acceptcharset);

## GetAction(nsAString & aAction)
nsEmbedString
moz_dom_GetAction (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	nsEmbedString action;
    CODE:
	htmlformelement->GetAction(action);
	RETVAL = action;
    OUTPUT:
	RETVAL

## SetAction(const nsAString & aAction)
void
moz_dom_SetAction (htmlformelement, action)
	nsIDOMHTMLFormElement *htmlformelement;
	nsEmbedString action;
    CODE:
	htmlformelement->SetAction(action);

## GetEnctype(nsAString & aEnctype)
nsEmbedString
moz_dom_GetEnctype (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	nsEmbedString enctype;
    CODE:
	htmlformelement->GetEnctype(enctype);
	RETVAL = enctype;
    OUTPUT:
	RETVAL

## SetEnctype(const nsAString & aEnctype)
void
moz_dom_SetEnctype (htmlformelement, enctype)
	nsIDOMHTMLFormElement *htmlformelement;
	nsEmbedString enctype;
    CODE:
	htmlformelement->SetEnctype(enctype);

## GetMethod(nsAString & aMethod)
nsEmbedString
moz_dom_GetMethod (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	nsEmbedString method;
    CODE:
	htmlformelement->GetMethod(method);
	RETVAL = method;
    OUTPUT:
	RETVAL

## SetMethod(const nsAString & aMethod)
void
moz_dom_SetMethod (htmlformelement, method)
	nsIDOMHTMLFormElement *htmlformelement;
	nsEmbedString method;
    CODE:
	htmlformelement->SetMethod(method);

## GetTarget(nsAString & aTarget)
nsEmbedString
moz_dom_GetTarget (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    PREINIT:
	nsEmbedString target;
    CODE:
	htmlformelement->GetTarget(target);
	RETVAL = target;
    OUTPUT:
	RETVAL

## SetTarget(const nsAString & aTarget)
void
moz_dom_SetTarget (htmlformelement, target)
	nsIDOMHTMLFormElement *htmlformelement;
	nsEmbedString target;
    CODE:
	htmlformelement->SetTarget(target);

## Submit(void)
void
moz_dom_Submit (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    CODE:
	htmlformelement->Submit();

## Reset(void)
void
moz_dom_Reset (htmlformelement)
	nsIDOMHTMLFormElement *htmlformelement;
    CODE:
	htmlformelement->Reset();

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLFrameElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLFrameElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLFRAMEELEMENT_IID)
static nsIID
nsIDOMHTMLFrameElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLFrameElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetFrameBorder(nsAString & aFrameBorder)
nsEmbedString
moz_dom_GetFrameBorder (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsEmbedString frameborder;
    CODE:
	htmlframeelement->GetFrameBorder(frameborder);
	RETVAL = frameborder;
    OUTPUT:
	RETVAL

## SetFrameBorder(const nsAString & aFrameBorder)
void
moz_dom_SetFrameBorder (htmlframeelement, frameborder)
	nsIDOMHTMLFrameElement *htmlframeelement;
	nsEmbedString frameborder;
    CODE:
	htmlframeelement->SetFrameBorder(frameborder);

## GetLongDesc(nsAString & aLongDesc)
nsEmbedString
moz_dom_GetLongDesc (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsEmbedString longdesc;
    CODE:
	htmlframeelement->GetLongDesc(longdesc);
	RETVAL = longdesc;
    OUTPUT:
	RETVAL

## SetLongDesc(const nsAString & aLongDesc)
void
moz_dom_SetLongDesc (htmlframeelement, longdesc)
	nsIDOMHTMLFrameElement *htmlframeelement;
	nsEmbedString longdesc;
    CODE:
	htmlframeelement->SetLongDesc(longdesc);

## GetMarginHeight(nsAString & aMarginHeight)
nsEmbedString
moz_dom_GetMarginHeight (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsEmbedString marginheight;
    CODE:
	htmlframeelement->GetMarginHeight(marginheight);
	RETVAL = marginheight;
    OUTPUT:
	RETVAL

## SetMarginHeight(const nsAString & aMarginHeight)
void
moz_dom_SetMarginHeight (htmlframeelement, marginheight)
	nsIDOMHTMLFrameElement *htmlframeelement;
	nsEmbedString marginheight;
    CODE:
	htmlframeelement->SetMarginHeight(marginheight);

## GetMarginWidth(nsAString & aMarginWidth)
nsEmbedString
moz_dom_GetMarginWidth (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsEmbedString marginwidth;
    CODE:
	htmlframeelement->GetMarginWidth(marginwidth);
	RETVAL = marginwidth;
    OUTPUT:
	RETVAL

## SetMarginWidth(const nsAString & aMarginWidth)
void
moz_dom_SetMarginWidth (htmlframeelement, marginwidth)
	nsIDOMHTMLFrameElement *htmlframeelement;
	nsEmbedString marginwidth;
    CODE:
	htmlframeelement->SetMarginWidth(marginwidth);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlframeelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlframeelement, name)
	nsIDOMHTMLFrameElement *htmlframeelement;
	nsEmbedString name;
    CODE:
	htmlframeelement->SetName(name);

## GetNoResize(PRBool *aNoResize)
PRBool
moz_dom_GetNoResize (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	PRBool noresize;
    CODE:
	htmlframeelement->GetNoResize(&noresize);
	RETVAL = noresize;
    OUTPUT:
	RETVAL

## SetNoResize(PRBool aNoResize)
void
moz_dom_SetNoResize (htmlframeelement, noresize)
	nsIDOMHTMLFrameElement *htmlframeelement;
	PRBool  noresize;
    CODE:
	htmlframeelement->SetNoResize(noresize);

## GetScrolling(nsAString & aScrolling)
nsEmbedString
moz_dom_GetScrolling (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsEmbedString scrolling;
    CODE:
	htmlframeelement->GetScrolling(scrolling);
	RETVAL = scrolling;
    OUTPUT:
	RETVAL

## SetScrolling(const nsAString & aScrolling)
void
moz_dom_SetScrolling (htmlframeelement, scrolling)
	nsIDOMHTMLFrameElement *htmlframeelement;
	nsEmbedString scrolling;
    CODE:
	htmlframeelement->SetScrolling(scrolling);

## GetSrc(nsAString & aSrc)
nsEmbedString
moz_dom_GetSrc (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsEmbedString src;
    CODE:
	htmlframeelement->GetSrc(src);
	RETVAL = src;
    OUTPUT:
	RETVAL

## SetSrc(const nsAString & aSrc)
void
moz_dom_SetSrc (htmlframeelement, src)
	nsIDOMHTMLFrameElement *htmlframeelement;
	nsEmbedString src;
    CODE:
	htmlframeelement->SetSrc(src);

## GetContentDocument(nsIDOMDocument * *aContentDocument)
nsIDOMDocument *
moz_dom_GetContentDocument (htmlframeelement)
	nsIDOMHTMLFrameElement *htmlframeelement;
    PREINIT:
	nsIDOMDocument * contentdocument;
    CODE:
	htmlframeelement->GetContentDocument(&contentdocument);
	RETVAL = contentdocument;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLFrameSetElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLFrameSetElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLFRAMESETELEMENT_IID)
static nsIID
nsIDOMHTMLFrameSetElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLFrameSetElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCols(nsAString & aCols)
nsEmbedString
moz_dom_GetCols (htmlframesetelement)
	nsIDOMHTMLFrameSetElement *htmlframesetelement;
    PREINIT:
	nsEmbedString cols;
    CODE:
	htmlframesetelement->GetCols(cols);
	RETVAL = cols;
    OUTPUT:
	RETVAL

## SetCols(const nsAString & aCols)
void
moz_dom_SetCols (htmlframesetelement, cols)
	nsIDOMHTMLFrameSetElement *htmlframesetelement;
	nsEmbedString cols;
    CODE:
	htmlframesetelement->SetCols(cols);

## GetRows(nsAString & aRows)
nsEmbedString
moz_dom_GetRows (htmlframesetelement)
	nsIDOMHTMLFrameSetElement *htmlframesetelement;
    PREINIT:
	nsEmbedString rows;
    CODE:
	htmlframesetelement->GetRows(rows);
	RETVAL = rows;
    OUTPUT:
	RETVAL

## SetRows(const nsAString & aRows)
void
moz_dom_SetRows (htmlframesetelement, rows)
	nsIDOMHTMLFrameSetElement *htmlframesetelement;
	nsEmbedString rows;
    CODE:
	htmlframesetelement->SetRows(rows);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLHRElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLHRElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLHRELEMENT_IID)
static nsIID
nsIDOMHTMLHRElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLHRElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlhrelement)
	nsIDOMHTMLHRElement *htmlhrelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlhrelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlhrelement, align)
	nsIDOMHTMLHRElement *htmlhrelement;
	nsEmbedString align;
    CODE:
	htmlhrelement->SetAlign(align);

## GetNoShade(PRBool *aNoShade)
PRBool
moz_dom_GetNoShade (htmlhrelement)
	nsIDOMHTMLHRElement *htmlhrelement;
    PREINIT:
	PRBool noshade;
    CODE:
	htmlhrelement->GetNoShade(&noshade);
	RETVAL = noshade;
    OUTPUT:
	RETVAL

## SetNoShade(PRBool aNoShade)
void
moz_dom_SetNoShade (htmlhrelement, noshade)
	nsIDOMHTMLHRElement *htmlhrelement;
	PRBool  noshade;
    CODE:
	htmlhrelement->SetNoShade(noshade);

## GetSize(nsAString & aSize)
nsEmbedString
moz_dom_GetSize (htmlhrelement)
	nsIDOMHTMLHRElement *htmlhrelement;
    PREINIT:
	nsEmbedString size;
    CODE:
	htmlhrelement->GetSize(size);
	RETVAL = size;
    OUTPUT:
	RETVAL

## SetSize(const nsAString & aSize)
void
moz_dom_SetSize (htmlhrelement, size)
	nsIDOMHTMLHRElement *htmlhrelement;
	nsEmbedString size;
    CODE:
	htmlhrelement->SetSize(size);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmlhrelement)
	nsIDOMHTMLHRElement *htmlhrelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmlhrelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmlhrelement, width)
	nsIDOMHTMLHRElement *htmlhrelement;
	nsEmbedString width;
    CODE:
	htmlhrelement->SetWidth(width);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLHeadElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLHeadElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLHEADELEMENT_IID)
static nsIID
nsIDOMHTMLHeadElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLHeadElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetProfile(nsAString & aProfile)
nsEmbedString
moz_dom_GetProfile (htmlheadelement)
	nsIDOMHTMLHeadElement *htmlheadelement;
    PREINIT:
	nsEmbedString profile;
    CODE:
	htmlheadelement->GetProfile(profile);
	RETVAL = profile;
    OUTPUT:
	RETVAL

## SetProfile(const nsAString & aProfile)
void
moz_dom_SetProfile (htmlheadelement, profile)
	nsIDOMHTMLHeadElement *htmlheadelement;
	nsEmbedString profile;
    CODE:
	htmlheadelement->SetProfile(profile);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLHeadingElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLHeadingElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLHEADINGELEMENT_IID)
static nsIID
nsIDOMHTMLHeadingElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLHeadingElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlheadingelement)
	nsIDOMHTMLHeadingElement *htmlheadingelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlheadingelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlheadingelement, align)
	nsIDOMHTMLHeadingElement *htmlheadingelement;
	nsEmbedString align;
    CODE:
	htmlheadingelement->SetAlign(align);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLHtmlElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLHtmlElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLHTMLELEMENT_IID)
static nsIID
nsIDOMHTMLHtmlElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLHtmlElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetVersion(nsAString & aVersion)
nsEmbedString
moz_dom_GetVersion (htmlhtmlelement)
	nsIDOMHTMLHtmlElement *htmlhtmlelement;
    PREINIT:
	nsEmbedString version;
    CODE:
	htmlhtmlelement->GetVersion(version);
	RETVAL = version;
    OUTPUT:
	RETVAL

## SetVersion(const nsAString & aVersion)
void
moz_dom_SetVersion (htmlhtmlelement, version)
	nsIDOMHTMLHtmlElement *htmlhtmlelement;
	nsEmbedString version;
    CODE:
	htmlhtmlelement->SetVersion(version);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLIFrameElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLIFrameElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLIFRAMEELEMENT_IID)
static nsIID
nsIDOMHTMLIFrameElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLIFrameElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmliframeelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmliframeelement, align)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString align;
    CODE:
	htmliframeelement->SetAlign(align);

## GetFrameBorder(nsAString & aFrameBorder)
nsEmbedString
moz_dom_GetFrameBorder (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString frameborder;
    CODE:
	htmliframeelement->GetFrameBorder(frameborder);
	RETVAL = frameborder;
    OUTPUT:
	RETVAL

## SetFrameBorder(const nsAString & aFrameBorder)
void
moz_dom_SetFrameBorder (htmliframeelement, frameborder)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString frameborder;
    CODE:
	htmliframeelement->SetFrameBorder(frameborder);

## GetHeight(nsAString & aHeight)
nsEmbedString
moz_dom_GetHeight (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString height;
    CODE:
	htmliframeelement->GetHeight(height);
	RETVAL = height;
    OUTPUT:
	RETVAL

## SetHeight(const nsAString & aHeight)
void
moz_dom_SetHeight (htmliframeelement, height)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString height;
    CODE:
	htmliframeelement->SetHeight(height);

## GetLongDesc(nsAString & aLongDesc)
nsEmbedString
moz_dom_GetLongDesc (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString longdesc;
    CODE:
	htmliframeelement->GetLongDesc(longdesc);
	RETVAL = longdesc;
    OUTPUT:
	RETVAL

## SetLongDesc(const nsAString & aLongDesc)
void
moz_dom_SetLongDesc (htmliframeelement, longdesc)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString longdesc;
    CODE:
	htmliframeelement->SetLongDesc(longdesc);

## GetMarginHeight(nsAString & aMarginHeight)
nsEmbedString
moz_dom_GetMarginHeight (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString marginheight;
    CODE:
	htmliframeelement->GetMarginHeight(marginheight);
	RETVAL = marginheight;
    OUTPUT:
	RETVAL

## SetMarginHeight(const nsAString & aMarginHeight)
void
moz_dom_SetMarginHeight (htmliframeelement, marginheight)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString marginheight;
    CODE:
	htmliframeelement->SetMarginHeight(marginheight);

## GetMarginWidth(nsAString & aMarginWidth)
nsEmbedString
moz_dom_GetMarginWidth (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString marginwidth;
    CODE:
	htmliframeelement->GetMarginWidth(marginwidth);
	RETVAL = marginwidth;
    OUTPUT:
	RETVAL

## SetMarginWidth(const nsAString & aMarginWidth)
void
moz_dom_SetMarginWidth (htmliframeelement, marginwidth)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString marginwidth;
    CODE:
	htmliframeelement->SetMarginWidth(marginwidth);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmliframeelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmliframeelement, name)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString name;
    CODE:
	htmliframeelement->SetName(name);

## GetScrolling(nsAString & aScrolling)
nsEmbedString
moz_dom_GetScrolling (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString scrolling;
    CODE:
	htmliframeelement->GetScrolling(scrolling);
	RETVAL = scrolling;
    OUTPUT:
	RETVAL

## SetScrolling(const nsAString & aScrolling)
void
moz_dom_SetScrolling (htmliframeelement, scrolling)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString scrolling;
    CODE:
	htmliframeelement->SetScrolling(scrolling);

## GetSrc(nsAString & aSrc)
nsEmbedString
moz_dom_GetSrc (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString src;
    CODE:
	htmliframeelement->GetSrc(src);
	RETVAL = src;
    OUTPUT:
	RETVAL

## SetSrc(const nsAString & aSrc)
void
moz_dom_SetSrc (htmliframeelement, src)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString src;
    CODE:
	htmliframeelement->SetSrc(src);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmliframeelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmliframeelement, width)
	nsIDOMHTMLIFrameElement *htmliframeelement;
	nsEmbedString width;
    CODE:
	htmliframeelement->SetWidth(width);

## GetContentDocument(nsIDOMDocument * *aContentDocument)
nsIDOMDocument *
moz_dom_GetContentDocument (htmliframeelement)
	nsIDOMHTMLIFrameElement *htmliframeelement;
    PREINIT:
	nsIDOMDocument * contentdocument;
    CODE:
	htmliframeelement->GetContentDocument(&contentdocument);
	RETVAL = contentdocument;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLImageElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLImageElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLIMAGEELEMENT_IID)
static nsIID
nsIDOMHTMLImageElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLImageElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlimageelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlimageelement, name)
	nsIDOMHTMLImageElement *htmlimageelement;
	nsEmbedString name;
    CODE:
	htmlimageelement->SetName(name);

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlimageelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlimageelement, align)
	nsIDOMHTMLImageElement *htmlimageelement;
	nsEmbedString align;
    CODE:
	htmlimageelement->SetAlign(align);

## GetAlt(nsAString & aAlt)
nsEmbedString
moz_dom_GetAlt (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	nsEmbedString alt;
    CODE:
	htmlimageelement->GetAlt(alt);
	RETVAL = alt;
    OUTPUT:
	RETVAL

## SetAlt(const nsAString & aAlt)
void
moz_dom_SetAlt (htmlimageelement, alt)
	nsIDOMHTMLImageElement *htmlimageelement;
	nsEmbedString alt;
    CODE:
	htmlimageelement->SetAlt(alt);

## GetBorder(nsAString & aBorder)
nsEmbedString
moz_dom_GetBorder (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	nsEmbedString border;
    CODE:
	htmlimageelement->GetBorder(border);
	RETVAL = border;
    OUTPUT:
	RETVAL

## SetBorder(const nsAString & aBorder)
void
moz_dom_SetBorder (htmlimageelement, border)
	nsIDOMHTMLImageElement *htmlimageelement;
	nsEmbedString border;
    CODE:
	htmlimageelement->SetBorder(border);

## GetHeight(PRInt32 *aHeight)
PRInt32
moz_dom_GetHeight (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	PRInt32 height;
    CODE:
	htmlimageelement->GetHeight(&height);
	RETVAL = height;
    OUTPUT:
	RETVAL

## SetHeight(PRInt32 aHeight)
void
moz_dom_SetHeight (htmlimageelement, height)
	nsIDOMHTMLImageElement *htmlimageelement;
	PRInt32  height;
    CODE:
	htmlimageelement->SetHeight(height);

## GetHspace(PRInt32 *aHspace)
PRInt32
moz_dom_GetHspace (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	PRInt32 hspace;
    CODE:
	htmlimageelement->GetHspace(&hspace);
	RETVAL = hspace;
    OUTPUT:
	RETVAL

## SetHspace(PRInt32 aHspace)
void
moz_dom_SetHspace (htmlimageelement, hspace)
	nsIDOMHTMLImageElement *htmlimageelement;
	PRInt32  hspace;
    CODE:
	htmlimageelement->SetHspace(hspace);

## GetIsMap(PRBool *aIsMap)
PRBool
moz_dom_GetIsMap (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	PRBool ismap;
    CODE:
	htmlimageelement->GetIsMap(&ismap);
	RETVAL = ismap;
    OUTPUT:
	RETVAL

## SetIsMap(PRBool aIsMap)
void
moz_dom_SetIsMap (htmlimageelement, ismap)
	nsIDOMHTMLImageElement *htmlimageelement;
	PRBool  ismap;
    CODE:
	htmlimageelement->SetIsMap(ismap);

## GetLongDesc(nsAString & aLongDesc)
nsEmbedString
moz_dom_GetLongDesc (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	nsEmbedString longdesc;
    CODE:
	htmlimageelement->GetLongDesc(longdesc);
	RETVAL = longdesc;
    OUTPUT:
	RETVAL

## SetLongDesc(const nsAString & aLongDesc)
void
moz_dom_SetLongDesc (htmlimageelement, longdesc)
	nsIDOMHTMLImageElement *htmlimageelement;
	nsEmbedString longdesc;
    CODE:
	htmlimageelement->SetLongDesc(longdesc);

## GetSrc(nsAString & aSrc)
nsEmbedString
moz_dom_GetSrc (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	nsEmbedString src;
    CODE:
	htmlimageelement->GetSrc(src);
	RETVAL = src;
    OUTPUT:
	RETVAL

## SetSrc(const nsAString & aSrc)
void
moz_dom_SetSrc (htmlimageelement, src)
	nsIDOMHTMLImageElement *htmlimageelement;
	nsEmbedString src;
    CODE:
	htmlimageelement->SetSrc(src);

## GetUseMap(nsAString & aUseMap)
nsEmbedString
moz_dom_GetUseMap (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	nsEmbedString usemap;
    CODE:
	htmlimageelement->GetUseMap(usemap);
	RETVAL = usemap;
    OUTPUT:
	RETVAL

## SetUseMap(const nsAString & aUseMap)
void
moz_dom_SetUseMap (htmlimageelement, usemap)
	nsIDOMHTMLImageElement *htmlimageelement;
	nsEmbedString usemap;
    CODE:
	htmlimageelement->SetUseMap(usemap);

## GetVspace(PRInt32 *aVspace)
PRInt32
moz_dom_GetVspace (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	PRInt32 vspace;
    CODE:
	htmlimageelement->GetVspace(&vspace);
	RETVAL = vspace;
    OUTPUT:
	RETVAL

## SetVspace(PRInt32 aVspace)
void
moz_dom_SetVspace (htmlimageelement, vspace)
	nsIDOMHTMLImageElement *htmlimageelement;
	PRInt32  vspace;
    CODE:
	htmlimageelement->SetVspace(vspace);

## GetWidth(PRInt32 *aWidth)
PRInt32
moz_dom_GetWidth (htmlimageelement)
	nsIDOMHTMLImageElement *htmlimageelement;
    PREINIT:
	PRInt32 width;
    CODE:
	htmlimageelement->GetWidth(&width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(PRInt32 aWidth)
void
moz_dom_SetWidth (htmlimageelement, width)
	nsIDOMHTMLImageElement *htmlimageelement;
	PRInt32  width;
    CODE:
	htmlimageelement->SetWidth(width);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLInputElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLInputElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLINPUTELEMENT_IID)
static nsIID
nsIDOMHTMLInputElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLInputElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDefaultValue(nsAString & aDefaultValue)
nsEmbedString
moz_dom_GetDefaultValue (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString defaultvalue;
    CODE:
	htmlinputelement->GetDefaultValue(defaultvalue);
	RETVAL = defaultvalue;
    OUTPUT:
	RETVAL

## SetDefaultValue(const nsAString & aDefaultValue)
void
moz_dom_SetDefaultValue (htmlinputelement, defaultvalue)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString defaultvalue;
    CODE:
	htmlinputelement->SetDefaultValue(defaultvalue);

## GetDefaultChecked(PRBool *aDefaultChecked)
PRBool
moz_dom_GetDefaultChecked (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	PRBool defaultchecked;
    CODE:
	htmlinputelement->GetDefaultChecked(&defaultchecked);
	RETVAL = defaultchecked;
    OUTPUT:
	RETVAL

## SetDefaultChecked(PRBool aDefaultChecked)
void
moz_dom_SetDefaultChecked (htmlinputelement, defaultchecked)
	nsIDOMHTMLInputElement *htmlinputelement;
	PRBool  defaultchecked;
    CODE:
	htmlinputelement->SetDefaultChecked(defaultchecked);

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmlinputelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetAccept(nsAString & aAccept)
nsEmbedString
moz_dom_GetAccept (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString accept;
    CODE:
	htmlinputelement->GetAccept(accept);
	RETVAL = accept;
    OUTPUT:
	RETVAL

## SetAccept(const nsAString & aAccept)
void
moz_dom_SetAccept (htmlinputelement, accept)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString accept;
    CODE:
	htmlinputelement->SetAccept(accept);

## GetAccessKey(nsAString & aAccessKey)
nsEmbedString
moz_dom_GetAccessKey (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString accesskey;
    CODE:
	htmlinputelement->GetAccessKey(accesskey);
	RETVAL = accesskey;
    OUTPUT:
	RETVAL

## SetAccessKey(const nsAString & aAccessKey)
void
moz_dom_SetAccessKey (htmlinputelement, accesskey)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString accesskey;
    CODE:
	htmlinputelement->SetAccessKey(accesskey);

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlinputelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlinputelement, align)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString align;
    CODE:
	htmlinputelement->SetAlign(align);

## GetAlt(nsAString & aAlt)
nsEmbedString
moz_dom_GetAlt (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString alt;
    CODE:
	htmlinputelement->GetAlt(alt);
	RETVAL = alt;
    OUTPUT:
	RETVAL

## SetAlt(const nsAString & aAlt)
void
moz_dom_SetAlt (htmlinputelement, alt)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString alt;
    CODE:
	htmlinputelement->SetAlt(alt);

## GetChecked(PRBool *aChecked)
PRBool
moz_dom_GetChecked (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	PRBool checked;
    CODE:
	htmlinputelement->GetChecked(&checked);
	RETVAL = checked;
    OUTPUT:
	RETVAL

## SetChecked(PRBool aChecked)
void
moz_dom_SetChecked (htmlinputelement, checked)
	nsIDOMHTMLInputElement *htmlinputelement;
	PRBool  checked;
    CODE:
	htmlinputelement->SetChecked(checked);

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmlinputelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmlinputelement, disabled)
	nsIDOMHTMLInputElement *htmlinputelement;
	PRBool  disabled;
    CODE:
	htmlinputelement->SetDisabled(disabled);

## GetMaxLength(PRInt32 *aMaxLength)
PRInt32
moz_dom_GetMaxLength (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	PRInt32 maxlength;
    CODE:
	htmlinputelement->GetMaxLength(&maxlength);
	RETVAL = maxlength;
    OUTPUT:
	RETVAL

## SetMaxLength(PRInt32 aMaxLength)
void
moz_dom_SetMaxLength (htmlinputelement, maxlength)
	nsIDOMHTMLInputElement *htmlinputelement;
	PRInt32  maxlength;
    CODE:
	htmlinputelement->SetMaxLength(maxlength);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlinputelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlinputelement, name)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString name;
    CODE:
	htmlinputelement->SetName(name);

## GetReadOnly(PRBool *aReadOnly)
PRBool
moz_dom_GetReadOnly (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	PRBool readonly;
    CODE:
	htmlinputelement->GetReadOnly(&readonly);
	RETVAL = readonly;
    OUTPUT:
	RETVAL

## SetReadOnly(PRBool aReadOnly)
void
moz_dom_SetReadOnly (htmlinputelement, readonly)
	nsIDOMHTMLInputElement *htmlinputelement;
	PRBool  readonly;
    CODE:
	htmlinputelement->SetReadOnly(readonly);

## GetSize(PRUint32 *aSize)
PRUint32
moz_dom_GetSize (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	PRUint32 size;
    CODE:
	htmlinputelement->GetSize(&size);
	RETVAL = size;
    OUTPUT:
	RETVAL

## SetSize(PRUint32 aSize)
void
moz_dom_SetSize (htmlinputelement, size)
	nsIDOMHTMLInputElement *htmlinputelement;
	PRUint32  size;
    CODE:
	htmlinputelement->SetSize(size);

## GetSrc(nsAString & aSrc)
nsEmbedString
moz_dom_GetSrc (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString src;
    CODE:
	htmlinputelement->GetSrc(src);
	RETVAL = src;
    OUTPUT:
	RETVAL

## SetSrc(const nsAString & aSrc)
void
moz_dom_SetSrc (htmlinputelement, src)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString src;
    CODE:
	htmlinputelement->SetSrc(src);

## GetTabIndex(PRInt32 *aTabIndex)
PRInt32
moz_dom_GetTabIndex (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	PRInt32 tabindex;
    CODE:
	htmlinputelement->GetTabIndex(&tabindex);
	RETVAL = tabindex;
    OUTPUT:
	RETVAL

## SetTabIndex(PRInt32 aTabIndex)
void
moz_dom_SetTabIndex (htmlinputelement, tabindex)
	nsIDOMHTMLInputElement *htmlinputelement;
	PRInt32  tabindex;
    CODE:
	htmlinputelement->SetTabIndex(tabindex);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlinputelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlinputelement, type)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString type;
    CODE:
	htmlinputelement->SetType(type);

## GetUseMap(nsAString & aUseMap)
nsEmbedString
moz_dom_GetUseMap (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString usemap;
    CODE:
	htmlinputelement->GetUseMap(usemap);
	RETVAL = usemap;
    OUTPUT:
	RETVAL

## SetUseMap(const nsAString & aUseMap)
void
moz_dom_SetUseMap (htmlinputelement, usemap)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString usemap;
    CODE:
	htmlinputelement->SetUseMap(usemap);

## GetValue(nsAString & aValue)
nsEmbedString
moz_dom_GetValue (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    PREINIT:
	nsEmbedString value;
    CODE:
	htmlinputelement->GetValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(const nsAString & aValue)
void
moz_dom_SetValue (htmlinputelement, value)
	nsIDOMHTMLInputElement *htmlinputelement;
	nsEmbedString value;
    CODE:
	htmlinputelement->SetValue(value);

## Blur(void)
void
moz_dom_Blur (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    CODE:
	htmlinputelement->Blur();

## Focus(void)
void
moz_dom_Focus (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    CODE:
	htmlinputelement->Focus();

## Select(void)
void
moz_dom_Select (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    CODE:
	htmlinputelement->Select();

## Click(void)
void
moz_dom_Click (htmlinputelement)
	nsIDOMHTMLInputElement *htmlinputelement;
    CODE:
	htmlinputelement->Click();

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLIsIndexElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLIsIndexElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLISINDEXELEMENT_IID)
static nsIID
nsIDOMHTMLIsIndexElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLIsIndexElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmlisindexelement)
	nsIDOMHTMLIsIndexElement *htmlisindexelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmlisindexelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetPrompt(nsAString & aPrompt)
nsEmbedString
moz_dom_GetPrompt (htmlisindexelement)
	nsIDOMHTMLIsIndexElement *htmlisindexelement;
    PREINIT:
	nsEmbedString prompt;
    CODE:
	htmlisindexelement->GetPrompt(prompt);
	RETVAL = prompt;
    OUTPUT:
	RETVAL

## SetPrompt(const nsAString & aPrompt)
void
moz_dom_SetPrompt (htmlisindexelement, prompt)
	nsIDOMHTMLIsIndexElement *htmlisindexelement;
	nsEmbedString prompt;
    CODE:
	htmlisindexelement->SetPrompt(prompt);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLLIElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLLIElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLLIELEMENT_IID)
static nsIID
nsIDOMHTMLLIElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLLIElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmllielement)
	nsIDOMHTMLLIElement *htmllielement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmllielement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmllielement, type)
	nsIDOMHTMLLIElement *htmllielement;
	nsEmbedString type;
    CODE:
	htmllielement->SetType(type);

## GetValue(PRInt32 *aValue)
PRInt32
moz_dom_GetValue (htmllielement)
	nsIDOMHTMLLIElement *htmllielement;
    PREINIT:
	PRInt32 value;
    CODE:
	htmllielement->GetValue(&value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(PRInt32 aValue)
void
moz_dom_SetValue (htmllielement, value)
	nsIDOMHTMLLIElement *htmllielement;
	PRInt32  value;
    CODE:
	htmllielement->SetValue(value);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLLabelElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLLabelElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLLABELELEMENT_IID)
static nsIID
nsIDOMHTMLLabelElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLLabelElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmllabelelement)
	nsIDOMHTMLLabelElement *htmllabelelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmllabelelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetAccessKey(nsAString & aAccessKey)
nsEmbedString
moz_dom_GetAccessKey (htmllabelelement)
	nsIDOMHTMLLabelElement *htmllabelelement;
    PREINIT:
	nsEmbedString accesskey;
    CODE:
	htmllabelelement->GetAccessKey(accesskey);
	RETVAL = accesskey;
    OUTPUT:
	RETVAL

## SetAccessKey(const nsAString & aAccessKey)
void
moz_dom_SetAccessKey (htmllabelelement, accesskey)
	nsIDOMHTMLLabelElement *htmllabelelement;
	nsEmbedString accesskey;
    CODE:
	htmllabelelement->SetAccessKey(accesskey);

## GetHtmlFor(nsAString & aHtmlFor)
nsEmbedString
moz_dom_GetHtmlFor (htmllabelelement)
	nsIDOMHTMLLabelElement *htmllabelelement;
    PREINIT:
	nsEmbedString htmlfor;
    CODE:
	htmllabelelement->GetHtmlFor(htmlfor);
	RETVAL = htmlfor;
    OUTPUT:
	RETVAL

## SetHtmlFor(const nsAString & aHtmlFor)
void
moz_dom_SetHtmlFor (htmllabelelement, htmlfor)
	nsIDOMHTMLLabelElement *htmllabelelement;
	nsEmbedString htmlfor;
    CODE:
	htmllabelelement->SetHtmlFor(htmlfor);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLLegendElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLLegendElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLLEGENDELEMENT_IID)
static nsIID
nsIDOMHTMLLegendElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLLegendElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmllegendelement)
	nsIDOMHTMLLegendElement *htmllegendelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmllegendelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetAccessKey(nsAString & aAccessKey)
nsEmbedString
moz_dom_GetAccessKey (htmllegendelement)
	nsIDOMHTMLLegendElement *htmllegendelement;
    PREINIT:
	nsEmbedString accesskey;
    CODE:
	htmllegendelement->GetAccessKey(accesskey);
	RETVAL = accesskey;
    OUTPUT:
	RETVAL

## SetAccessKey(const nsAString & aAccessKey)
void
moz_dom_SetAccessKey (htmllegendelement, accesskey)
	nsIDOMHTMLLegendElement *htmllegendelement;
	nsEmbedString accesskey;
    CODE:
	htmllegendelement->SetAccessKey(accesskey);

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmllegendelement)
	nsIDOMHTMLLegendElement *htmllegendelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmllegendelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmllegendelement, align)
	nsIDOMHTMLLegendElement *htmllegendelement;
	nsEmbedString align;
    CODE:
	htmllegendelement->SetAlign(align);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLLinkElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLLinkElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLLINKELEMENT_IID)
static nsIID
nsIDOMHTMLLinkElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLLinkElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmllinkelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmllinkelement, disabled)
	nsIDOMHTMLLinkElement *htmllinkelement;
	PRBool  disabled;
    CODE:
	htmllinkelement->SetDisabled(disabled);

## GetCharset(nsAString & aCharset)
nsEmbedString
moz_dom_GetCharset (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString charset;
    CODE:
	htmllinkelement->GetCharset(charset);
	RETVAL = charset;
    OUTPUT:
	RETVAL

## SetCharset(const nsAString & aCharset)
void
moz_dom_SetCharset (htmllinkelement, charset)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString charset;
    CODE:
	htmllinkelement->SetCharset(charset);

## GetHref(nsAString & aHref)
nsEmbedString
moz_dom_GetHref (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString href;
    CODE:
	htmllinkelement->GetHref(href);
	RETVAL = href;
    OUTPUT:
	RETVAL

## SetHref(const nsAString & aHref)
void
moz_dom_SetHref (htmllinkelement, href)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString href;
    CODE:
	htmllinkelement->SetHref(href);

## GetHreflang(nsAString & aHreflang)
nsEmbedString
moz_dom_GetHreflang (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString hreflang;
    CODE:
	htmllinkelement->GetHreflang(hreflang);
	RETVAL = hreflang;
    OUTPUT:
	RETVAL

## SetHreflang(const nsAString & aHreflang)
void
moz_dom_SetHreflang (htmllinkelement, hreflang)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString hreflang;
    CODE:
	htmllinkelement->SetHreflang(hreflang);

## GetMedia(nsAString & aMedia)
nsEmbedString
moz_dom_GetMedia (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString media;
    CODE:
	htmllinkelement->GetMedia(media);
	RETVAL = media;
    OUTPUT:
	RETVAL

## SetMedia(const nsAString & aMedia)
void
moz_dom_SetMedia (htmllinkelement, media)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString media;
    CODE:
	htmllinkelement->SetMedia(media);

## GetRel(nsAString & aRel)
nsEmbedString
moz_dom_GetRel (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString rel;
    CODE:
	htmllinkelement->GetRel(rel);
	RETVAL = rel;
    OUTPUT:
	RETVAL

## SetRel(const nsAString & aRel)
void
moz_dom_SetRel (htmllinkelement, rel)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString rel;
    CODE:
	htmllinkelement->SetRel(rel);

## GetRev(nsAString & aRev)
nsEmbedString
moz_dom_GetRev (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString rev;
    CODE:
	htmllinkelement->GetRev(rev);
	RETVAL = rev;
    OUTPUT:
	RETVAL

## SetRev(const nsAString & aRev)
void
moz_dom_SetRev (htmllinkelement, rev)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString rev;
    CODE:
	htmllinkelement->SetRev(rev);

## GetTarget(nsAString & aTarget)
nsEmbedString
moz_dom_GetTarget (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString target;
    CODE:
	htmllinkelement->GetTarget(target);
	RETVAL = target;
    OUTPUT:
	RETVAL

## SetTarget(const nsAString & aTarget)
void
moz_dom_SetTarget (htmllinkelement, target)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString target;
    CODE:
	htmllinkelement->SetTarget(target);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmllinkelement)
	nsIDOMHTMLLinkElement *htmllinkelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmllinkelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmllinkelement, type)
	nsIDOMHTMLLinkElement *htmllinkelement;
	nsEmbedString type;
    CODE:
	htmllinkelement->SetType(type);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLMapElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLMapElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLMAPELEMENT_IID)
static nsIID
nsIDOMHTMLMapElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLMapElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAreas(nsIDOMHTMLCollection * *aAreas)
nsIDOMHTMLCollection *
moz_dom_GetAreas_htmlcollection (htmlmapelement)
	nsIDOMHTMLMapElement *htmlmapelement;
    PREINIT:
	nsIDOMHTMLCollection * areas;
    CODE:
	htmlmapelement->GetAreas(&areas);
	RETVAL = areas;
    OUTPUT:
	RETVAL

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlmapelement)
	nsIDOMHTMLMapElement *htmlmapelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlmapelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlmapelement, name)
	nsIDOMHTMLMapElement *htmlmapelement;
	nsEmbedString name;
    CODE:
	htmlmapelement->SetName(name);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLMenuElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLMenuElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLMENUELEMENT_IID)
static nsIID
nsIDOMHTMLMenuElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLMenuElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCompact(PRBool *aCompact)
PRBool
moz_dom_GetCompact (htmlmenuelement)
	nsIDOMHTMLMenuElement *htmlmenuelement;
    PREINIT:
	PRBool compact;
    CODE:
	htmlmenuelement->GetCompact(&compact);
	RETVAL = compact;
    OUTPUT:
	RETVAL

## SetCompact(PRBool aCompact)
void
moz_dom_SetCompact (htmlmenuelement, compact)
	nsIDOMHTMLMenuElement *htmlmenuelement;
	PRBool  compact;
    CODE:
	htmlmenuelement->SetCompact(compact);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLMetaElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLMetaElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLMETAELEMENT_IID)
static nsIID
nsIDOMHTMLMetaElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLMetaElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetContent(nsAString & aContent)
nsEmbedString
moz_dom_GetContent (htmlmetaelement)
	nsIDOMHTMLMetaElement *htmlmetaelement;
    PREINIT:
	nsEmbedString content;
    CODE:
	htmlmetaelement->GetContent(content);
	RETVAL = content;
    OUTPUT:
	RETVAL

## SetContent(const nsAString & aContent)
void
moz_dom_SetContent (htmlmetaelement, content)
	nsIDOMHTMLMetaElement *htmlmetaelement;
	nsEmbedString content;
    CODE:
	htmlmetaelement->SetContent(content);

## GetHttpEquiv(nsAString & aHttpEquiv)
nsEmbedString
moz_dom_GetHttpEquiv (htmlmetaelement)
	nsIDOMHTMLMetaElement *htmlmetaelement;
    PREINIT:
	nsEmbedString httpequiv;
    CODE:
	htmlmetaelement->GetHttpEquiv(httpequiv);
	RETVAL = httpequiv;
    OUTPUT:
	RETVAL

## SetHttpEquiv(const nsAString & aHttpEquiv)
void
moz_dom_SetHttpEquiv (htmlmetaelement, httpequiv)
	nsIDOMHTMLMetaElement *htmlmetaelement;
	nsEmbedString httpequiv;
    CODE:
	htmlmetaelement->SetHttpEquiv(httpequiv);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlmetaelement)
	nsIDOMHTMLMetaElement *htmlmetaelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlmetaelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlmetaelement, name)
	nsIDOMHTMLMetaElement *htmlmetaelement;
	nsEmbedString name;
    CODE:
	htmlmetaelement->SetName(name);

## GetScheme(nsAString & aScheme)
nsEmbedString
moz_dom_GetScheme (htmlmetaelement)
	nsIDOMHTMLMetaElement *htmlmetaelement;
    PREINIT:
	nsEmbedString scheme;
    CODE:
	htmlmetaelement->GetScheme(scheme);
	RETVAL = scheme;
    OUTPUT:
	RETVAL

## SetScheme(const nsAString & aScheme)
void
moz_dom_SetScheme (htmlmetaelement, scheme)
	nsIDOMHTMLMetaElement *htmlmetaelement;
	nsEmbedString scheme;
    CODE:
	htmlmetaelement->SetScheme(scheme);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLModElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLModElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLMODELEMENT_IID)
static nsIID
nsIDOMHTMLModElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLModElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCite(nsAString & aCite)
nsEmbedString
moz_dom_GetCite (htmlmodelement)
	nsIDOMHTMLModElement *htmlmodelement;
    PREINIT:
	nsEmbedString cite;
    CODE:
	htmlmodelement->GetCite(cite);
	RETVAL = cite;
    OUTPUT:
	RETVAL

## SetCite(const nsAString & aCite)
void
moz_dom_SetCite (htmlmodelement, cite)
	nsIDOMHTMLModElement *htmlmodelement;
	nsEmbedString cite;
    CODE:
	htmlmodelement->SetCite(cite);

## GetDateTime(nsAString & aDateTime)
nsEmbedString
moz_dom_GetDateTime (htmlmodelement)
	nsIDOMHTMLModElement *htmlmodelement;
    PREINIT:
	nsEmbedString datetime;
    CODE:
	htmlmodelement->GetDateTime(datetime);
	RETVAL = datetime;
    OUTPUT:
	RETVAL

## SetDateTime(const nsAString & aDateTime)
void
moz_dom_SetDateTime (htmlmodelement, datetime)
	nsIDOMHTMLModElement *htmlmodelement;
	nsEmbedString datetime;
    CODE:
	htmlmodelement->SetDateTime(datetime);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLOListElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLOListElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLOLISTELEMENT_IID)
static nsIID
nsIDOMHTMLOListElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLOListElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCompact(PRBool *aCompact)
PRBool
moz_dom_GetCompact (htmlolistelement)
	nsIDOMHTMLOListElement *htmlolistelement;
    PREINIT:
	PRBool compact;
    CODE:
	htmlolistelement->GetCompact(&compact);
	RETVAL = compact;
    OUTPUT:
	RETVAL

## SetCompact(PRBool aCompact)
void
moz_dom_SetCompact (htmlolistelement, compact)
	nsIDOMHTMLOListElement *htmlolistelement;
	PRBool  compact;
    CODE:
	htmlolistelement->SetCompact(compact);

## GetStart(PRInt32 *aStart)
PRInt32
moz_dom_GetStart (htmlolistelement)
	nsIDOMHTMLOListElement *htmlolistelement;
    PREINIT:
	PRInt32 start;
    CODE:
	htmlolistelement->GetStart(&start);
	RETVAL = start;
    OUTPUT:
	RETVAL

## SetStart(PRInt32 aStart)
void
moz_dom_SetStart (htmlolistelement, start)
	nsIDOMHTMLOListElement *htmlolistelement;
	PRInt32  start;
    CODE:
	htmlolistelement->SetStart(start);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlolistelement)
	nsIDOMHTMLOListElement *htmlolistelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlolistelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlolistelement, type)
	nsIDOMHTMLOListElement *htmlolistelement;
	nsEmbedString type;
    CODE:
	htmlolistelement->SetType(type);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLObjectElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLObjectElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLOBJECTELEMENT_IID)
static nsIID
nsIDOMHTMLObjectElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLObjectElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmlobjectelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetCode(nsAString & aCode)
nsEmbedString
moz_dom_GetCode (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString code;
    CODE:
	htmlobjectelement->GetCode(code);
	RETVAL = code;
    OUTPUT:
	RETVAL

## SetCode(const nsAString & aCode)
void
moz_dom_SetCode (htmlobjectelement, code)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString code;
    CODE:
	htmlobjectelement->SetCode(code);

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlobjectelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlobjectelement, align)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString align;
    CODE:
	htmlobjectelement->SetAlign(align);

## GetArchive(nsAString & aArchive)
nsEmbedString
moz_dom_GetArchive (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString archive;
    CODE:
	htmlobjectelement->GetArchive(archive);
	RETVAL = archive;
    OUTPUT:
	RETVAL

## SetArchive(const nsAString & aArchive)
void
moz_dom_SetArchive (htmlobjectelement, archive)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString archive;
    CODE:
	htmlobjectelement->SetArchive(archive);

## GetBorder(nsAString & aBorder)
nsEmbedString
moz_dom_GetBorder (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString border;
    CODE:
	htmlobjectelement->GetBorder(border);
	RETVAL = border;
    OUTPUT:
	RETVAL

## SetBorder(const nsAString & aBorder)
void
moz_dom_SetBorder (htmlobjectelement, border)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString border;
    CODE:
	htmlobjectelement->SetBorder(border);

## GetCodeBase(nsAString & aCodeBase)
nsEmbedString
moz_dom_GetCodeBase (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString codebase;
    CODE:
	htmlobjectelement->GetCodeBase(codebase);
	RETVAL = codebase;
    OUTPUT:
	RETVAL

## SetCodeBase(const nsAString & aCodeBase)
void
moz_dom_SetCodeBase (htmlobjectelement, codebase)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString codebase;
    CODE:
	htmlobjectelement->SetCodeBase(codebase);

## GetCodeType(nsAString & aCodeType)
nsEmbedString
moz_dom_GetCodeType (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString codetype;
    CODE:
	htmlobjectelement->GetCodeType(codetype);
	RETVAL = codetype;
    OUTPUT:
	RETVAL

## SetCodeType(const nsAString & aCodeType)
void
moz_dom_SetCodeType (htmlobjectelement, codetype)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString codetype;
    CODE:
	htmlobjectelement->SetCodeType(codetype);

## GetData(nsAString & aData)
nsEmbedString
moz_dom_GetData (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString data;
    CODE:
	htmlobjectelement->GetData(data);
	RETVAL = data;
    OUTPUT:
	RETVAL

## SetData(const nsAString & aData)
void
moz_dom_SetData (htmlobjectelement, data)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString data;
    CODE:
	htmlobjectelement->SetData(data);

## GetDeclare(PRBool *aDeclare)
PRBool
moz_dom_GetDeclare (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	PRBool declare;
    CODE:
	htmlobjectelement->GetDeclare(&declare);
	RETVAL = declare;
    OUTPUT:
	RETVAL

## SetDeclare(PRBool aDeclare)
void
moz_dom_SetDeclare (htmlobjectelement, declare)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	PRBool  declare;
    CODE:
	htmlobjectelement->SetDeclare(declare);

## GetHeight(nsAString & aHeight)
nsEmbedString
moz_dom_GetHeight (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString height;
    CODE:
	htmlobjectelement->GetHeight(height);
	RETVAL = height;
    OUTPUT:
	RETVAL

## SetHeight(const nsAString & aHeight)
void
moz_dom_SetHeight (htmlobjectelement, height)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString height;
    CODE:
	htmlobjectelement->SetHeight(height);

## GetHspace(PRInt32 *aHspace)
PRInt32
moz_dom_GetHspace (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	PRInt32 hspace;
    CODE:
	htmlobjectelement->GetHspace(&hspace);
	RETVAL = hspace;
    OUTPUT:
	RETVAL

## SetHspace(PRInt32 aHspace)
void
moz_dom_SetHspace (htmlobjectelement, hspace)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	PRInt32  hspace;
    CODE:
	htmlobjectelement->SetHspace(hspace);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlobjectelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlobjectelement, name)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString name;
    CODE:
	htmlobjectelement->SetName(name);

## GetStandby(nsAString & aStandby)
nsEmbedString
moz_dom_GetStandby (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString standby;
    CODE:
	htmlobjectelement->GetStandby(standby);
	RETVAL = standby;
    OUTPUT:
	RETVAL

## SetStandby(const nsAString & aStandby)
void
moz_dom_SetStandby (htmlobjectelement, standby)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString standby;
    CODE:
	htmlobjectelement->SetStandby(standby);

## GetTabIndex(PRInt32 *aTabIndex)
PRInt32
moz_dom_GetTabIndex (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	PRInt32 tabindex;
    CODE:
	htmlobjectelement->GetTabIndex(&tabindex);
	RETVAL = tabindex;
    OUTPUT:
	RETVAL

## SetTabIndex(PRInt32 aTabIndex)
void
moz_dom_SetTabIndex (htmlobjectelement, tabindex)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	PRInt32  tabindex;
    CODE:
	htmlobjectelement->SetTabIndex(tabindex);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlobjectelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlobjectelement, type)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString type;
    CODE:
	htmlobjectelement->SetType(type);

## GetUseMap(nsAString & aUseMap)
nsEmbedString
moz_dom_GetUseMap (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString usemap;
    CODE:
	htmlobjectelement->GetUseMap(usemap);
	RETVAL = usemap;
    OUTPUT:
	RETVAL

## SetUseMap(const nsAString & aUseMap)
void
moz_dom_SetUseMap (htmlobjectelement, usemap)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString usemap;
    CODE:
	htmlobjectelement->SetUseMap(usemap);

## GetVspace(PRInt32 *aVspace)
PRInt32
moz_dom_GetVspace (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	PRInt32 vspace;
    CODE:
	htmlobjectelement->GetVspace(&vspace);
	RETVAL = vspace;
    OUTPUT:
	RETVAL

## SetVspace(PRInt32 aVspace)
void
moz_dom_SetVspace (htmlobjectelement, vspace)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	PRInt32  vspace;
    CODE:
	htmlobjectelement->SetVspace(vspace);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmlobjectelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmlobjectelement, width)
	nsIDOMHTMLObjectElement *htmlobjectelement;
	nsEmbedString width;
    CODE:
	htmlobjectelement->SetWidth(width);

## GetContentDocument(nsIDOMDocument * *aContentDocument)
nsIDOMDocument *
moz_dom_GetContentDocument (htmlobjectelement)
	nsIDOMHTMLObjectElement *htmlobjectelement;
    PREINIT:
	nsIDOMDocument * contentdocument;
    CODE:
	htmlobjectelement->GetContentDocument(&contentdocument);
	RETVAL = contentdocument;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLOptGroupElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLOptGroupElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLOPTGROUPELEMENT_IID)
static nsIID
nsIDOMHTMLOptGroupElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLOptGroupElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmloptgroupelement)
	nsIDOMHTMLOptGroupElement *htmloptgroupelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmloptgroupelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmloptgroupelement, disabled)
	nsIDOMHTMLOptGroupElement *htmloptgroupelement;
	PRBool  disabled;
    CODE:
	htmloptgroupelement->SetDisabled(disabled);

## GetLabel(nsAString & aLabel)
nsEmbedString
moz_dom_GetLabel (htmloptgroupelement)
	nsIDOMHTMLOptGroupElement *htmloptgroupelement;
    PREINIT:
	nsEmbedString label;
    CODE:
	htmloptgroupelement->GetLabel(label);
	RETVAL = label;
    OUTPUT:
	RETVAL

## SetLabel(const nsAString & aLabel)
void
moz_dom_SetLabel (htmloptgroupelement, label)
	nsIDOMHTMLOptGroupElement *htmloptgroupelement;
	nsEmbedString label;
    CODE:
	htmloptgroupelement->SetLabel(label);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLOptionElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLOptionElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLOPTIONELEMENT_IID)
static nsIID
nsIDOMHTMLOptionElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLOptionElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmloptionelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetDefaultSelected(PRBool *aDefaultSelected)
PRBool
moz_dom_GetDefaultSelected (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	PRBool defaultselected;
    CODE:
	htmloptionelement->GetDefaultSelected(&defaultselected);
	RETVAL = defaultselected;
    OUTPUT:
	RETVAL

## SetDefaultSelected(PRBool aDefaultSelected)
void
moz_dom_SetDefaultSelected (htmloptionelement, defaultselected)
	nsIDOMHTMLOptionElement *htmloptionelement;
	PRBool  defaultselected;
    CODE:
	htmloptionelement->SetDefaultSelected(defaultselected);

## GetText(nsAString & aText)
nsEmbedString
moz_dom_GetText (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	nsEmbedString text;
    CODE:
	htmloptionelement->GetText(text);
	RETVAL = text;
    OUTPUT:
	RETVAL

## GetIndex(PRInt32 *aIndex)
PRInt32
moz_dom_GetIndex (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	PRInt32 index;
    CODE:
	htmloptionelement->GetIndex(&index);
	RETVAL = index;
    OUTPUT:
	RETVAL

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmloptionelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmloptionelement, disabled)
	nsIDOMHTMLOptionElement *htmloptionelement;
	PRBool  disabled;
    CODE:
	htmloptionelement->SetDisabled(disabled);

## GetLabel(nsAString & aLabel)
nsEmbedString
moz_dom_GetLabel (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	nsEmbedString label;
    CODE:
	htmloptionelement->GetLabel(label);
	RETVAL = label;
    OUTPUT:
	RETVAL

## SetLabel(const nsAString & aLabel)
void
moz_dom_SetLabel (htmloptionelement, label)
	nsIDOMHTMLOptionElement *htmloptionelement;
	nsEmbedString label;
    CODE:
	htmloptionelement->SetLabel(label);

## GetSelected(PRBool *aSelected)
PRBool
moz_dom_GetSelected (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	PRBool selected;
    CODE:
	htmloptionelement->GetSelected(&selected);
	RETVAL = selected;
    OUTPUT:
	RETVAL

## SetSelected(PRBool aSelected)
void
moz_dom_SetSelected (htmloptionelement, selected)
	nsIDOMHTMLOptionElement *htmloptionelement;
	PRBool  selected;
    CODE:
	htmloptionelement->SetSelected(selected);

## GetValue(nsAString & aValue)
nsEmbedString
moz_dom_GetValue (htmloptionelement)
	nsIDOMHTMLOptionElement *htmloptionelement;
    PREINIT:
	nsEmbedString value;
    CODE:
	htmloptionelement->GetValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(const nsAString & aValue)
void
moz_dom_SetValue (htmloptionelement, value)
	nsIDOMHTMLOptionElement *htmloptionelement;
	nsEmbedString value;
    CODE:
	htmloptionelement->SetValue(value);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLOptionsCollection	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLOptionsCollection.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLOPTIONSCOLLECTION_IID)
static nsIID
nsIDOMHTMLOptionsCollection::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLOptionsCollection::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (htmloptionscollection)
	nsIDOMHTMLOptionsCollection *htmloptionscollection;
    PREINIT:
	PRUint32 length;
    CODE:
	htmloptionscollection->GetLength(&length);
	RETVAL = length;
    OUTPUT:
	RETVAL

## SetLength(PRUint32 aLength)
void
moz_dom_SetLength (htmloptionscollection, length)
	nsIDOMHTMLOptionsCollection *htmloptionscollection;
	PRUint32  length;
    CODE:
	htmloptionscollection->SetLength(length);

## Item(PRUint32 index, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_Item (htmloptionscollection, index)
	nsIDOMHTMLOptionsCollection *htmloptionscollection;
	PRUint32  index;
    PREINIT:
	nsIDOMNode * retval;
    CODE:
	htmloptionscollection->Item(index, &retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## NamedItem(const nsAString & name, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_NamedItem (htmloptionscollection, name)
	nsIDOMHTMLOptionsCollection *htmloptionscollection;
	nsEmbedString name;
    PREINIT:
	nsIDOMNode * retval;
    CODE:
	htmloptionscollection->NamedItem(name, &retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLParagraphElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLParagraphElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLPARAGRAPHELEMENT_IID)
static nsIID
nsIDOMHTMLParagraphElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLParagraphElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmlparagraphelement)
	nsIDOMHTMLParagraphElement *htmlparagraphelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmlparagraphelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmlparagraphelement, align)
	nsIDOMHTMLParagraphElement *htmlparagraphelement;
	nsEmbedString align;
    CODE:
	htmlparagraphelement->SetAlign(align);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLParamElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLParamElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLPARAMELEMENT_IID)
static nsIID
nsIDOMHTMLParamElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLParamElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlparamelement)
	nsIDOMHTMLParamElement *htmlparamelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlparamelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlparamelement, name)
	nsIDOMHTMLParamElement *htmlparamelement;
	nsEmbedString name;
    CODE:
	htmlparamelement->SetName(name);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlparamelement)
	nsIDOMHTMLParamElement *htmlparamelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlparamelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlparamelement, type)
	nsIDOMHTMLParamElement *htmlparamelement;
	nsEmbedString type;
    CODE:
	htmlparamelement->SetType(type);

## GetValue(nsAString & aValue)
nsEmbedString
moz_dom_GetValue (htmlparamelement)
	nsIDOMHTMLParamElement *htmlparamelement;
    PREINIT:
	nsEmbedString value;
    CODE:
	htmlparamelement->GetValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(const nsAString & aValue)
void
moz_dom_SetValue (htmlparamelement, value)
	nsIDOMHTMLParamElement *htmlparamelement;
	nsEmbedString value;
    CODE:
	htmlparamelement->SetValue(value);

## GetValueType(nsAString & aValueType)
nsEmbedString
moz_dom_GetValueType (htmlparamelement)
	nsIDOMHTMLParamElement *htmlparamelement;
    PREINIT:
	nsEmbedString valuetype;
    CODE:
	htmlparamelement->GetValueType(valuetype);
	RETVAL = valuetype;
    OUTPUT:
	RETVAL

## SetValueType(const nsAString & aValueType)
void
moz_dom_SetValueType (htmlparamelement, valuetype)
	nsIDOMHTMLParamElement *htmlparamelement;
	nsEmbedString valuetype;
    CODE:
	htmlparamelement->SetValueType(valuetype);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLPreElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLPreElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLPREELEMENT_IID)
static nsIID
nsIDOMHTMLPreElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLPreElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetWidth(PRInt32 *aWidth)
PRInt32
moz_dom_GetWidth (htmlpreelement)
	nsIDOMHTMLPreElement *htmlpreelement;
    PREINIT:
	PRInt32 width;
    CODE:
	htmlpreelement->GetWidth(&width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(PRInt32 aWidth)
void
moz_dom_SetWidth (htmlpreelement, width)
	nsIDOMHTMLPreElement *htmlpreelement;
	PRInt32  width;
    CODE:
	htmlpreelement->SetWidth(width);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLQuoteElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLQuoteElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLQUOTEELEMENT_IID)
static nsIID
nsIDOMHTMLQuoteElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLQuoteElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCite(nsAString & aCite)
nsEmbedString
moz_dom_GetCite (htmlquoteelement)
	nsIDOMHTMLQuoteElement *htmlquoteelement;
    PREINIT:
	nsEmbedString cite;
    CODE:
	htmlquoteelement->GetCite(cite);
	RETVAL = cite;
    OUTPUT:
	RETVAL

## SetCite(const nsAString & aCite)
void
moz_dom_SetCite (htmlquoteelement, cite)
	nsIDOMHTMLQuoteElement *htmlquoteelement;
	nsEmbedString cite;
    CODE:
	htmlquoteelement->SetCite(cite);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLScriptElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLScriptElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLSCRIPTELEMENT_IID)
static nsIID
nsIDOMHTMLScriptElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLScriptElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetText(nsAString & aText)
nsEmbedString
moz_dom_GetText (htmlscriptelement)
	nsIDOMHTMLScriptElement *htmlscriptelement;
    PREINIT:
	nsEmbedString text;
    CODE:
	htmlscriptelement->GetText(text);
	RETVAL = text;
    OUTPUT:
	RETVAL

## SetText(const nsAString & aText)
void
moz_dom_SetText (htmlscriptelement, text)
	nsIDOMHTMLScriptElement *htmlscriptelement;
	nsEmbedString text;
    CODE:
	htmlscriptelement->SetText(text);

## GetHtmlFor(nsAString & aHtmlFor)
nsEmbedString
moz_dom_GetHtmlFor (htmlscriptelement)
	nsIDOMHTMLScriptElement *htmlscriptelement;
    PREINIT:
	nsEmbedString htmlfor;
    CODE:
	htmlscriptelement->GetHtmlFor(htmlfor);
	RETVAL = htmlfor;
    OUTPUT:
	RETVAL

## SetHtmlFor(const nsAString & aHtmlFor)
void
moz_dom_SetHtmlFor (htmlscriptelement, htmlfor)
	nsIDOMHTMLScriptElement *htmlscriptelement;
	nsEmbedString htmlfor;
    CODE:
	htmlscriptelement->SetHtmlFor(htmlfor);

## GetEvent(nsAString & aEvent)
nsEmbedString
moz_dom_GetEvent (htmlscriptelement)
	nsIDOMHTMLScriptElement *htmlscriptelement;
    PREINIT:
	nsEmbedString event;
    CODE:
	htmlscriptelement->GetEvent(event);
	RETVAL = event;
    OUTPUT:
	RETVAL

## SetEvent(const nsAString & aEvent)
void
moz_dom_SetEvent (htmlscriptelement, event)
	nsIDOMHTMLScriptElement *htmlscriptelement;
	nsEmbedString event;
    CODE:
	htmlscriptelement->SetEvent(event);

## GetCharset(nsAString & aCharset)
nsEmbedString
moz_dom_GetCharset (htmlscriptelement)
	nsIDOMHTMLScriptElement *htmlscriptelement;
    PREINIT:
	nsEmbedString charset;
    CODE:
	htmlscriptelement->GetCharset(charset);
	RETVAL = charset;
    OUTPUT:
	RETVAL

## SetCharset(const nsAString & aCharset)
void
moz_dom_SetCharset (htmlscriptelement, charset)
	nsIDOMHTMLScriptElement *htmlscriptelement;
	nsEmbedString charset;
    CODE:
	htmlscriptelement->SetCharset(charset);

## GetDefer(PRBool *aDefer)
PRBool
moz_dom_GetDefer (htmlscriptelement)
	nsIDOMHTMLScriptElement *htmlscriptelement;
    PREINIT:
	PRBool defer;
    CODE:
	htmlscriptelement->GetDefer(&defer);
	RETVAL = defer;
    OUTPUT:
	RETVAL

## SetDefer(PRBool aDefer)
void
moz_dom_SetDefer (htmlscriptelement, defer)
	nsIDOMHTMLScriptElement *htmlscriptelement;
	PRBool  defer;
    CODE:
	htmlscriptelement->SetDefer(defer);

## GetSrc(nsAString & aSrc)
nsEmbedString
moz_dom_GetSrc (htmlscriptelement)
	nsIDOMHTMLScriptElement *htmlscriptelement;
    PREINIT:
	nsEmbedString src;
    CODE:
	htmlscriptelement->GetSrc(src);
	RETVAL = src;
    OUTPUT:
	RETVAL

## SetSrc(const nsAString & aSrc)
void
moz_dom_SetSrc (htmlscriptelement, src)
	nsIDOMHTMLScriptElement *htmlscriptelement;
	nsEmbedString src;
    CODE:
	htmlscriptelement->SetSrc(src);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlscriptelement)
	nsIDOMHTMLScriptElement *htmlscriptelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlscriptelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlscriptelement, type)
	nsIDOMHTMLScriptElement *htmlscriptelement;
	nsEmbedString type;
    CODE:
	htmlscriptelement->SetType(type);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLSelectElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLSelectElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLSELECTELEMENT_IID)
static nsIID
nsIDOMHTMLSelectElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLSelectElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlselectelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## GetSelectedIndex(PRInt32 *aSelectedIndex)
PRInt32
moz_dom_GetSelectedIndex (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	PRInt32 selectedindex;
    CODE:
	htmlselectelement->GetSelectedIndex(&selectedindex);
	RETVAL = selectedindex;
    OUTPUT:
	RETVAL

## SetSelectedIndex(PRInt32 aSelectedIndex)
void
moz_dom_SetSelectedIndex (htmlselectelement, selectedindex)
	nsIDOMHTMLSelectElement *htmlselectelement;
	PRInt32  selectedindex;
    CODE:
	htmlselectelement->SetSelectedIndex(selectedindex);

## GetValue(nsAString & aValue)
nsEmbedString
moz_dom_GetValue (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	nsEmbedString value;
    CODE:
	htmlselectelement->GetValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(const nsAString & aValue)
void
moz_dom_SetValue (htmlselectelement, value)
	nsIDOMHTMLSelectElement *htmlselectelement;
	nsEmbedString value;
    CODE:
	htmlselectelement->SetValue(value);

## GetLength(PRUint32 *aLength)
PRUint32
moz_dom_GetLength (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	PRUint32 length;
    CODE:
	htmlselectelement->GetLength(&length);
	RETVAL = length;
    OUTPUT:
	RETVAL

## SetLength(PRUint32 aLength)
void
moz_dom_SetLength (htmlselectelement, length)
	nsIDOMHTMLSelectElement *htmlselectelement;
	PRUint32  length;
    CODE:
	htmlselectelement->SetLength(length);

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmlselectelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetOptions(nsIDOMHTMLOptionsCollection * *aOptions)
nsIDOMHTMLOptionsCollection *
moz_dom_GetOptions_optionscollection (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	nsIDOMHTMLOptionsCollection * options;
    CODE:
	htmlselectelement->GetOptions(&options);
	RETVAL = options;
    OUTPUT:
	RETVAL

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmlselectelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmlselectelement, disabled)
	nsIDOMHTMLSelectElement *htmlselectelement;
	PRBool  disabled;
    CODE:
	htmlselectelement->SetDisabled(disabled);

## GetMultiple(PRBool *aMultiple)
PRBool
moz_dom_GetMultiple (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	PRBool multiple;
    CODE:
	htmlselectelement->GetMultiple(&multiple);
	RETVAL = multiple;
    OUTPUT:
	RETVAL

## SetMultiple(PRBool aMultiple)
void
moz_dom_SetMultiple (htmlselectelement, multiple)
	nsIDOMHTMLSelectElement *htmlselectelement;
	PRBool  multiple;
    CODE:
	htmlselectelement->SetMultiple(multiple);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmlselectelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmlselectelement, name)
	nsIDOMHTMLSelectElement *htmlselectelement;
	nsEmbedString name;
    CODE:
	htmlselectelement->SetName(name);

## GetSize(PRInt32 *aSize)
PRInt32
moz_dom_GetSize (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	PRInt32 size;
    CODE:
	htmlselectelement->GetSize(&size);
	RETVAL = size;
    OUTPUT:
	RETVAL

## SetSize(PRInt32 aSize)
void
moz_dom_SetSize (htmlselectelement, size)
	nsIDOMHTMLSelectElement *htmlselectelement;
	PRInt32  size;
    CODE:
	htmlselectelement->SetSize(size);

## GetTabIndex(PRInt32 *aTabIndex)
PRInt32
moz_dom_GetTabIndex (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    PREINIT:
	PRInt32 tabindex;
    CODE:
	htmlselectelement->GetTabIndex(&tabindex);
	RETVAL = tabindex;
    OUTPUT:
	RETVAL

## SetTabIndex(PRInt32 aTabIndex)
void
moz_dom_SetTabIndex (htmlselectelement, tabindex)
	nsIDOMHTMLSelectElement *htmlselectelement;
	PRInt32  tabindex;
    CODE:
	htmlselectelement->SetTabIndex(tabindex);

## Add(nsIDOMHTMLElement *element, nsIDOMHTMLElement *before)
void
moz_dom_Add (htmlselectelement, element, before)
	nsIDOMHTMLSelectElement *htmlselectelement;
	nsIDOMHTMLElement * element;
	nsIDOMHTMLElement * before;
    CODE:
	htmlselectelement->Add(element, before);

## Remove(PRInt32 index)
void
moz_dom_Remove (htmlselectelement, index)
	nsIDOMHTMLSelectElement *htmlselectelement;
	PRInt32  index;
    CODE:
	htmlselectelement->Remove(index);

## Blur(void)
void
moz_dom_Blur (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    CODE:
	htmlselectelement->Blur();

## Focus(void)
void
moz_dom_Focus (htmlselectelement)
	nsIDOMHTMLSelectElement *htmlselectelement;
    CODE:
	htmlselectelement->Focus();

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLStyleElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLStyleElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLSTYLEELEMENT_IID)
static nsIID
nsIDOMHTMLStyleElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLStyleElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmlstyleelement)
	nsIDOMHTMLStyleElement *htmlstyleelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmlstyleelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmlstyleelement, disabled)
	nsIDOMHTMLStyleElement *htmlstyleelement;
	PRBool  disabled;
    CODE:
	htmlstyleelement->SetDisabled(disabled);

## GetMedia(nsAString & aMedia)
nsEmbedString
moz_dom_GetMedia (htmlstyleelement)
	nsIDOMHTMLStyleElement *htmlstyleelement;
    PREINIT:
	nsEmbedString media;
    CODE:
	htmlstyleelement->GetMedia(media);
	RETVAL = media;
    OUTPUT:
	RETVAL

## SetMedia(const nsAString & aMedia)
void
moz_dom_SetMedia (htmlstyleelement, media)
	nsIDOMHTMLStyleElement *htmlstyleelement;
	nsEmbedString media;
    CODE:
	htmlstyleelement->SetMedia(media);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlstyleelement)
	nsIDOMHTMLStyleElement *htmlstyleelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlstyleelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlstyleelement, type)
	nsIDOMHTMLStyleElement *htmlstyleelement;
	nsEmbedString type;
    CODE:
	htmlstyleelement->SetType(type);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTableCaptionElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTableCaptionElem.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTABLECAPTIONELEMENT_IID)
static nsIID
nsIDOMHTMLTableCaptionElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTableCaptionElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmltablecaptionelement)
	nsIDOMHTMLTableCaptionElement *htmltablecaptionelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmltablecaptionelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmltablecaptionelement, align)
	nsIDOMHTMLTableCaptionElement *htmltablecaptionelement;
	nsEmbedString align;
    CODE:
	htmltablecaptionelement->SetAlign(align);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTableCellElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTableCellElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTABLECELLELEMENT_IID)
static nsIID
nsIDOMHTMLTableCellElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTableCellElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCellIndex(PRInt32 *aCellIndex)
PRInt32
moz_dom_GetCellIndex (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	PRInt32 cellindex;
    CODE:
	htmltablecellelement->GetCellIndex(&cellindex);
	RETVAL = cellindex;
    OUTPUT:
	RETVAL

## GetAbbr(nsAString & aAbbr)
nsEmbedString
moz_dom_GetAbbr (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString abbr;
    CODE:
	htmltablecellelement->GetAbbr(abbr);
	RETVAL = abbr;
    OUTPUT:
	RETVAL

## SetAbbr(const nsAString & aAbbr)
void
moz_dom_SetAbbr (htmltablecellelement, abbr)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString abbr;
    CODE:
	htmltablecellelement->SetAbbr(abbr);

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmltablecellelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmltablecellelement, align)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString align;
    CODE:
	htmltablecellelement->SetAlign(align);

## GetAxis(nsAString & aAxis)
nsEmbedString
moz_dom_GetAxis (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString axis;
    CODE:
	htmltablecellelement->GetAxis(axis);
	RETVAL = axis;
    OUTPUT:
	RETVAL

## SetAxis(const nsAString & aAxis)
void
moz_dom_SetAxis (htmltablecellelement, axis)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString axis;
    CODE:
	htmltablecellelement->SetAxis(axis);

## GetBgColor(nsAString & aBgColor)
nsEmbedString
moz_dom_GetBgColor (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString bgcolor;
    CODE:
	htmltablecellelement->GetBgColor(bgcolor);
	RETVAL = bgcolor;
    OUTPUT:
	RETVAL

## SetBgColor(const nsAString & aBgColor)
void
moz_dom_SetBgColor (htmltablecellelement, bgcolor)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString bgcolor;
    CODE:
	htmltablecellelement->SetBgColor(bgcolor);

## GetCh(nsAString & aCh)
nsEmbedString
moz_dom_GetCh (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString ch;
    CODE:
	htmltablecellelement->GetCh(ch);
	RETVAL = ch;
    OUTPUT:
	RETVAL

## SetCh(const nsAString & aCh)
void
moz_dom_SetCh (htmltablecellelement, ch)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString ch;
    CODE:
	htmltablecellelement->SetCh(ch);

## GetChOff(nsAString & aChOff)
nsEmbedString
moz_dom_GetChOff (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString choff;
    CODE:
	htmltablecellelement->GetChOff(choff);
	RETVAL = choff;
    OUTPUT:
	RETVAL

## SetChOff(const nsAString & aChOff)
void
moz_dom_SetChOff (htmltablecellelement, choff)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString choff;
    CODE:
	htmltablecellelement->SetChOff(choff);

## GetColSpan(PRInt32 *aColSpan)
PRInt32
moz_dom_GetColSpan (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	PRInt32 colspan;
    CODE:
	htmltablecellelement->GetColSpan(&colspan);
	RETVAL = colspan;
    OUTPUT:
	RETVAL

## SetColSpan(PRInt32 aColSpan)
void
moz_dom_SetColSpan (htmltablecellelement, colspan)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	PRInt32  colspan;
    CODE:
	htmltablecellelement->SetColSpan(colspan);

## GetHeaders(nsAString & aHeaders)
nsEmbedString
moz_dom_GetHeaders (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString headers;
    CODE:
	htmltablecellelement->GetHeaders(headers);
	RETVAL = headers;
    OUTPUT:
	RETVAL

## SetHeaders(const nsAString & aHeaders)
void
moz_dom_SetHeaders (htmltablecellelement, headers)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString headers;
    CODE:
	htmltablecellelement->SetHeaders(headers);

## GetHeight(nsAString & aHeight)
nsEmbedString
moz_dom_GetHeight (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString height;
    CODE:
	htmltablecellelement->GetHeight(height);
	RETVAL = height;
    OUTPUT:
	RETVAL

## SetHeight(const nsAString & aHeight)
void
moz_dom_SetHeight (htmltablecellelement, height)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString height;
    CODE:
	htmltablecellelement->SetHeight(height);

## GetNoWrap(PRBool *aNoWrap)
PRBool
moz_dom_GetNoWrap (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	PRBool nowrap;
    CODE:
	htmltablecellelement->GetNoWrap(&nowrap);
	RETVAL = nowrap;
    OUTPUT:
	RETVAL

## SetNoWrap(PRBool aNoWrap)
void
moz_dom_SetNoWrap (htmltablecellelement, nowrap)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	PRBool  nowrap;
    CODE:
	htmltablecellelement->SetNoWrap(nowrap);

## GetRowSpan(PRInt32 *aRowSpan)
PRInt32
moz_dom_GetRowSpan (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	PRInt32 rowspan;
    CODE:
	htmltablecellelement->GetRowSpan(&rowspan);
	RETVAL = rowspan;
    OUTPUT:
	RETVAL

## SetRowSpan(PRInt32 aRowSpan)
void
moz_dom_SetRowSpan (htmltablecellelement, rowspan)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	PRInt32  rowspan;
    CODE:
	htmltablecellelement->SetRowSpan(rowspan);

## GetScope(nsAString & aScope)
nsEmbedString
moz_dom_GetScope (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString scope;
    CODE:
	htmltablecellelement->GetScope(scope);
	RETVAL = scope;
    OUTPUT:
	RETVAL

## SetScope(const nsAString & aScope)
void
moz_dom_SetScope (htmltablecellelement, scope)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString scope;
    CODE:
	htmltablecellelement->SetScope(scope);

## GetVAlign(nsAString & aVAlign)
nsEmbedString
moz_dom_GetVAlign (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString valign;
    CODE:
	htmltablecellelement->GetVAlign(valign);
	RETVAL = valign;
    OUTPUT:
	RETVAL

## SetVAlign(const nsAString & aVAlign)
void
moz_dom_SetVAlign (htmltablecellelement, valign)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString valign;
    CODE:
	htmltablecellelement->SetVAlign(valign);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmltablecellelement)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmltablecellelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmltablecellelement, width)
	nsIDOMHTMLTableCellElement *htmltablecellelement;
	nsEmbedString width;
    CODE:
	htmltablecellelement->SetWidth(width);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTableColElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTableColElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTABLECOLELEMENT_IID)
static nsIID
nsIDOMHTMLTableColElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTableColElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmltablecolelement)
	nsIDOMHTMLTableColElement *htmltablecolelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmltablecolelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmltablecolelement, align)
	nsIDOMHTMLTableColElement *htmltablecolelement;
	nsEmbedString align;
    CODE:
	htmltablecolelement->SetAlign(align);

## GetCh(nsAString & aCh)
nsEmbedString
moz_dom_GetCh (htmltablecolelement)
	nsIDOMHTMLTableColElement *htmltablecolelement;
    PREINIT:
	nsEmbedString ch;
    CODE:
	htmltablecolelement->GetCh(ch);
	RETVAL = ch;
    OUTPUT:
	RETVAL

## SetCh(const nsAString & aCh)
void
moz_dom_SetCh (htmltablecolelement, ch)
	nsIDOMHTMLTableColElement *htmltablecolelement;
	nsEmbedString ch;
    CODE:
	htmltablecolelement->SetCh(ch);

## GetChOff(nsAString & aChOff)
nsEmbedString
moz_dom_GetChOff (htmltablecolelement)
	nsIDOMHTMLTableColElement *htmltablecolelement;
    PREINIT:
	nsEmbedString choff;
    CODE:
	htmltablecolelement->GetChOff(choff);
	RETVAL = choff;
    OUTPUT:
	RETVAL

## SetChOff(const nsAString & aChOff)
void
moz_dom_SetChOff (htmltablecolelement, choff)
	nsIDOMHTMLTableColElement *htmltablecolelement;
	nsEmbedString choff;
    CODE:
	htmltablecolelement->SetChOff(choff);

## GetSpan(PRInt32 *aSpan)
PRInt32
moz_dom_GetSpan (htmltablecolelement)
	nsIDOMHTMLTableColElement *htmltablecolelement;
    PREINIT:
	PRInt32 span;
    CODE:
	htmltablecolelement->GetSpan(&span);
	RETVAL = span;
    OUTPUT:
	RETVAL

## SetSpan(PRInt32 aSpan)
void
moz_dom_SetSpan (htmltablecolelement, span)
	nsIDOMHTMLTableColElement *htmltablecolelement;
	PRInt32  span;
    CODE:
	htmltablecolelement->SetSpan(span);

## GetVAlign(nsAString & aVAlign)
nsEmbedString
moz_dom_GetVAlign (htmltablecolelement)
	nsIDOMHTMLTableColElement *htmltablecolelement;
    PREINIT:
	nsEmbedString valign;
    CODE:
	htmltablecolelement->GetVAlign(valign);
	RETVAL = valign;
    OUTPUT:
	RETVAL

## SetVAlign(const nsAString & aVAlign)
void
moz_dom_SetVAlign (htmltablecolelement, valign)
	nsIDOMHTMLTableColElement *htmltablecolelement;
	nsEmbedString valign;
    CODE:
	htmltablecolelement->SetVAlign(valign);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmltablecolelement)
	nsIDOMHTMLTableColElement *htmltablecolelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmltablecolelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmltablecolelement, width)
	nsIDOMHTMLTableColElement *htmltablecolelement;
	nsEmbedString width;
    CODE:
	htmltablecolelement->SetWidth(width);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTableElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTableElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTABLEELEMENT_IID)
static nsIID
nsIDOMHTMLTableElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTableElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCaption(nsIDOMHTMLTableCaptionElement * *aCaption)
nsIDOMHTMLTableCaptionElement *
moz_dom_GetCaption (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLTableCaptionElement * caption;
    CODE:
	htmltableelement->GetCaption(&caption);
	RETVAL = caption;
    OUTPUT:
	RETVAL

## SetCaption(nsIDOMHTMLTableCaptionElement * aCaption)
void
moz_dom_SetCaption (htmltableelement, caption)
	nsIDOMHTMLTableElement *htmltableelement;
	nsIDOMHTMLTableCaptionElement *  caption;
    CODE:
	htmltableelement->SetCaption(caption);

## GetTHead(nsIDOMHTMLTableSectionElement * *aTHead)
nsIDOMHTMLTableSectionElement *
moz_dom_GetTHead (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLTableSectionElement * thead;
    CODE:
	htmltableelement->GetTHead(&thead);
	RETVAL = thead;
    OUTPUT:
	RETVAL

## SetTHead(nsIDOMHTMLTableSectionElement * aTHead)
void
moz_dom_SetTHead (htmltableelement, thead)
	nsIDOMHTMLTableElement *htmltableelement;
	nsIDOMHTMLTableSectionElement *  thead;
    CODE:
	htmltableelement->SetTHead(thead);

## GetTFoot(nsIDOMHTMLTableSectionElement * *aTFoot)
nsIDOMHTMLTableSectionElement *
moz_dom_GetTFoot (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLTableSectionElement * tfoot;
    CODE:
	htmltableelement->GetTFoot(&tfoot);
	RETVAL = tfoot;
    OUTPUT:
	RETVAL

## SetTFoot(nsIDOMHTMLTableSectionElement * aTFoot)
void
moz_dom_SetTFoot (htmltableelement, tfoot)
	nsIDOMHTMLTableElement *htmltableelement;
	nsIDOMHTMLTableSectionElement *  tfoot;
    CODE:
	htmltableelement->SetTFoot(tfoot);

## GetRows(nsIDOMHTMLCollection * *aRows)
nsIDOMHTMLCollection *
moz_dom_GetRows_htmlcollection (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLCollection * rows;
    CODE:
	htmltableelement->GetRows(&rows);
	RETVAL = rows;
    OUTPUT:
	RETVAL

## GetTBodies(nsIDOMHTMLCollection * *aTBodies)
nsIDOMHTMLCollection *
moz_dom_GetTBodies_htmlcollection (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLCollection * tbodies;
    CODE:
	htmltableelement->GetTBodies(&tbodies);
	RETVAL = tbodies;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmltableelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmltableelement, align)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString align;
    CODE:
	htmltableelement->SetAlign(align);

## GetBgColor(nsAString & aBgColor)
nsEmbedString
moz_dom_GetBgColor (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString bgcolor;
    CODE:
	htmltableelement->GetBgColor(bgcolor);
	RETVAL = bgcolor;
    OUTPUT:
	RETVAL

## SetBgColor(const nsAString & aBgColor)
void
moz_dom_SetBgColor (htmltableelement, bgcolor)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString bgcolor;
    CODE:
	htmltableelement->SetBgColor(bgcolor);

## GetBorder(nsAString & aBorder)
nsEmbedString
moz_dom_GetBorder (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString border;
    CODE:
	htmltableelement->GetBorder(border);
	RETVAL = border;
    OUTPUT:
	RETVAL

## SetBorder(const nsAString & aBorder)
void
moz_dom_SetBorder (htmltableelement, border)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString border;
    CODE:
	htmltableelement->SetBorder(border);

## GetCellPadding(nsAString & aCellPadding)
nsEmbedString
moz_dom_GetCellPadding (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString cellpadding;
    CODE:
	htmltableelement->GetCellPadding(cellpadding);
	RETVAL = cellpadding;
    OUTPUT:
	RETVAL

## SetCellPadding(const nsAString & aCellPadding)
void
moz_dom_SetCellPadding (htmltableelement, cellpadding)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString cellpadding;
    CODE:
	htmltableelement->SetCellPadding(cellpadding);

## GetCellSpacing(nsAString & aCellSpacing)
nsEmbedString
moz_dom_GetCellSpacing (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString cellspacing;
    CODE:
	htmltableelement->GetCellSpacing(cellspacing);
	RETVAL = cellspacing;
    OUTPUT:
	RETVAL

## SetCellSpacing(const nsAString & aCellSpacing)
void
moz_dom_SetCellSpacing (htmltableelement, cellspacing)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString cellspacing;
    CODE:
	htmltableelement->SetCellSpacing(cellspacing);

## GetFrame(nsAString & aFrame)
nsEmbedString
moz_dom_GetFrame (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString frame;
    CODE:
	htmltableelement->GetFrame(frame);
	RETVAL = frame;
    OUTPUT:
	RETVAL

## SetFrame(const nsAString & aFrame)
void
moz_dom_SetFrame (htmltableelement, frame)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString frame;
    CODE:
	htmltableelement->SetFrame(frame);

## GetRules(nsAString & aRules)
nsEmbedString
moz_dom_GetRules (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString rules;
    CODE:
	htmltableelement->GetRules(rules);
	RETVAL = rules;
    OUTPUT:
	RETVAL

## SetRules(const nsAString & aRules)
void
moz_dom_SetRules (htmltableelement, rules)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString rules;
    CODE:
	htmltableelement->SetRules(rules);

## GetSummary(nsAString & aSummary)
nsEmbedString
moz_dom_GetSummary (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString summary;
    CODE:
	htmltableelement->GetSummary(summary);
	RETVAL = summary;
    OUTPUT:
	RETVAL

## SetSummary(const nsAString & aSummary)
void
moz_dom_SetSummary (htmltableelement, summary)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString summary;
    CODE:
	htmltableelement->SetSummary(summary);

## GetWidth(nsAString & aWidth)
nsEmbedString
moz_dom_GetWidth (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsEmbedString width;
    CODE:
	htmltableelement->GetWidth(width);
	RETVAL = width;
    OUTPUT:
	RETVAL

## SetWidth(const nsAString & aWidth)
void
moz_dom_SetWidth (htmltableelement, width)
	nsIDOMHTMLTableElement *htmltableelement;
	nsEmbedString width;
    CODE:
	htmltableelement->SetWidth(width);

## CreateTHead(nsIDOMHTMLElement **_retval)
nsIDOMHTMLElement *
moz_dom_CreateTHead (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLElement * retval;
    CODE:
	htmltableelement->CreateTHead(&retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## DeleteTHead(void)
void
moz_dom_DeleteTHead (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    CODE:
	htmltableelement->DeleteTHead();

## CreateTFoot(nsIDOMHTMLElement **_retval)
nsIDOMHTMLElement *
moz_dom_CreateTFoot (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLElement * retval;
    CODE:
	htmltableelement->CreateTFoot(&retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## DeleteTFoot(void)
void
moz_dom_DeleteTFoot (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    CODE:
	htmltableelement->DeleteTFoot();

## CreateCaption(nsIDOMHTMLElement **_retval)
nsIDOMHTMLElement *
moz_dom_CreateCaption (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    PREINIT:
	nsIDOMHTMLElement * retval;
    CODE:
	htmltableelement->CreateCaption(&retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## DeleteCaption(void)
void
moz_dom_DeleteCaption (htmltableelement)
	nsIDOMHTMLTableElement *htmltableelement;
    CODE:
	htmltableelement->DeleteCaption();

## InsertRow(PRInt32 index, nsIDOMHTMLElement **_retval)
nsIDOMHTMLElement *
moz_dom_InsertRow (htmltableelement, index)
	nsIDOMHTMLTableElement *htmltableelement;
	PRInt32  index;
    PREINIT:
	nsIDOMHTMLElement * retval;
    CODE:
	htmltableelement->InsertRow(index, &retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## DeleteRow(PRInt32 index)
void
moz_dom_DeleteRow (htmltableelement, index)
	nsIDOMHTMLTableElement *htmltableelement;
	PRInt32  index;
    CODE:
	htmltableelement->DeleteRow(index);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTableRowElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTableRowElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTABLEROWELEMENT_IID)
static nsIID
nsIDOMHTMLTableRowElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTableRowElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetRowIndex(PRInt32 *aRowIndex)
PRInt32
moz_dom_GetRowIndex (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	PRInt32 rowindex;
    CODE:
	htmltablerowelement->GetRowIndex(&rowindex);
	RETVAL = rowindex;
    OUTPUT:
	RETVAL

## GetSectionRowIndex(PRInt32 *aSectionRowIndex)
PRInt32
moz_dom_GetSectionRowIndex (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	PRInt32 sectionrowindex;
    CODE:
	htmltablerowelement->GetSectionRowIndex(&sectionrowindex);
	RETVAL = sectionrowindex;
    OUTPUT:
	RETVAL

## GetCells(nsIDOMHTMLCollection * *aCells)
nsIDOMHTMLCollection *
moz_dom_GetCells_htmlcollection (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	nsIDOMHTMLCollection * cells;
    CODE:
	htmltablerowelement->GetCells(&cells);
	RETVAL = cells;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmltablerowelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmltablerowelement, align)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
	nsEmbedString align;
    CODE:
	htmltablerowelement->SetAlign(align);

## GetBgColor(nsAString & aBgColor)
nsEmbedString
moz_dom_GetBgColor (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	nsEmbedString bgcolor;
    CODE:
	htmltablerowelement->GetBgColor(bgcolor);
	RETVAL = bgcolor;
    OUTPUT:
	RETVAL

## SetBgColor(const nsAString & aBgColor)
void
moz_dom_SetBgColor (htmltablerowelement, bgcolor)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
	nsEmbedString bgcolor;
    CODE:
	htmltablerowelement->SetBgColor(bgcolor);

## GetCh(nsAString & aCh)
nsEmbedString
moz_dom_GetCh (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	nsEmbedString ch;
    CODE:
	htmltablerowelement->GetCh(ch);
	RETVAL = ch;
    OUTPUT:
	RETVAL

## SetCh(const nsAString & aCh)
void
moz_dom_SetCh (htmltablerowelement, ch)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
	nsEmbedString ch;
    CODE:
	htmltablerowelement->SetCh(ch);

## GetChOff(nsAString & aChOff)
nsEmbedString
moz_dom_GetChOff (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	nsEmbedString choff;
    CODE:
	htmltablerowelement->GetChOff(choff);
	RETVAL = choff;
    OUTPUT:
	RETVAL

## SetChOff(const nsAString & aChOff)
void
moz_dom_SetChOff (htmltablerowelement, choff)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
	nsEmbedString choff;
    CODE:
	htmltablerowelement->SetChOff(choff);

## GetVAlign(nsAString & aVAlign)
nsEmbedString
moz_dom_GetVAlign (htmltablerowelement)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
    PREINIT:
	nsEmbedString valign;
    CODE:
	htmltablerowelement->GetVAlign(valign);
	RETVAL = valign;
    OUTPUT:
	RETVAL

## SetVAlign(const nsAString & aVAlign)
void
moz_dom_SetVAlign (htmltablerowelement, valign)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
	nsEmbedString valign;
    CODE:
	htmltablerowelement->SetVAlign(valign);

## InsertCell(PRInt32 index, nsIDOMHTMLElement **_retval)
nsIDOMHTMLElement *
moz_dom_InsertCell (htmltablerowelement, index)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
	PRInt32  index;
    PREINIT:
	nsIDOMHTMLElement * retval;
    CODE:
	htmltablerowelement->InsertCell(index, &retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## DeleteCell(PRInt32 index)
void
moz_dom_DeleteCell (htmltablerowelement, index)
	nsIDOMHTMLTableRowElement *htmltablerowelement;
	PRInt32  index;
    CODE:
	htmltablerowelement->DeleteCell(index);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTableSectionElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTableSectionElem.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTABLESECTIONELEMENT_IID)
static nsIID
nsIDOMHTMLTableSectionElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTableSectionElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAlign(nsAString & aAlign)
nsEmbedString
moz_dom_GetAlign (htmltablesectionelement)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
    PREINIT:
	nsEmbedString align;
    CODE:
	htmltablesectionelement->GetAlign(align);
	RETVAL = align;
    OUTPUT:
	RETVAL

## SetAlign(const nsAString & aAlign)
void
moz_dom_SetAlign (htmltablesectionelement, align)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
	nsEmbedString align;
    CODE:
	htmltablesectionelement->SetAlign(align);

## GetCh(nsAString & aCh)
nsEmbedString
moz_dom_GetCh (htmltablesectionelement)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
    PREINIT:
	nsEmbedString ch;
    CODE:
	htmltablesectionelement->GetCh(ch);
	RETVAL = ch;
    OUTPUT:
	RETVAL

## SetCh(const nsAString & aCh)
void
moz_dom_SetCh (htmltablesectionelement, ch)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
	nsEmbedString ch;
    CODE:
	htmltablesectionelement->SetCh(ch);

## GetChOff(nsAString & aChOff)
nsEmbedString
moz_dom_GetChOff (htmltablesectionelement)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
    PREINIT:
	nsEmbedString choff;
    CODE:
	htmltablesectionelement->GetChOff(choff);
	RETVAL = choff;
    OUTPUT:
	RETVAL

## SetChOff(const nsAString & aChOff)
void
moz_dom_SetChOff (htmltablesectionelement, choff)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
	nsEmbedString choff;
    CODE:
	htmltablesectionelement->SetChOff(choff);

## GetVAlign(nsAString & aVAlign)
nsEmbedString
moz_dom_GetVAlign (htmltablesectionelement)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
    PREINIT:
	nsEmbedString valign;
    CODE:
	htmltablesectionelement->GetVAlign(valign);
	RETVAL = valign;
    OUTPUT:
	RETVAL

## SetVAlign(const nsAString & aVAlign)
void
moz_dom_SetVAlign (htmltablesectionelement, valign)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
	nsEmbedString valign;
    CODE:
	htmltablesectionelement->SetVAlign(valign);

## GetRows(nsIDOMHTMLCollection * *aRows)
nsIDOMHTMLCollection *
moz_dom_GetRows_htmlcollection (htmltablesectionelement)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
    PREINIT:
	nsIDOMHTMLCollection * rows;
    CODE:
	htmltablesectionelement->GetRows(&rows);
	RETVAL = rows;
    OUTPUT:
	RETVAL

## InsertRow(PRInt32 index, nsIDOMHTMLElement **_retval)
nsIDOMHTMLElement *
moz_dom_InsertRow (htmltablesectionelement, index)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
	PRInt32  index;
    PREINIT:
	nsIDOMHTMLElement * retval;
    CODE:
	htmltablesectionelement->InsertRow(index, &retval);
	RETVAL = retval;
    OUTPUT:
	RETVAL

## DeleteRow(PRInt32 index)
void
moz_dom_DeleteRow (htmltablesectionelement, index)
	nsIDOMHTMLTableSectionElement *htmltablesectionelement;
	PRInt32  index;
    CODE:
	htmltablesectionelement->DeleteRow(index);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTextAreaElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTextAreaElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTEXTAREAELEMENT_IID)
static nsIID
nsIDOMHTMLTextAreaElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTextAreaElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetDefaultValue(nsAString & aDefaultValue)
nsEmbedString
moz_dom_GetDefaultValue (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	nsEmbedString defaultvalue;
    CODE:
	htmltextareaelement->GetDefaultValue(defaultvalue);
	RETVAL = defaultvalue;
    OUTPUT:
	RETVAL

## SetDefaultValue(const nsAString & aDefaultValue)
void
moz_dom_SetDefaultValue (htmltextareaelement, defaultvalue)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	nsEmbedString defaultvalue;
    CODE:
	htmltextareaelement->SetDefaultValue(defaultvalue);

## GetForm(nsIDOMHTMLFormElement * *aForm)
nsIDOMHTMLFormElement *
moz_dom_GetForm (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	nsIDOMHTMLFormElement * form;
    CODE:
	htmltextareaelement->GetForm(&form);
	RETVAL = form;
    OUTPUT:
	RETVAL

## GetAccessKey(nsAString & aAccessKey)
nsEmbedString
moz_dom_GetAccessKey (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	nsEmbedString accesskey;
    CODE:
	htmltextareaelement->GetAccessKey(accesskey);
	RETVAL = accesskey;
    OUTPUT:
	RETVAL

## SetAccessKey(const nsAString & aAccessKey)
void
moz_dom_SetAccessKey (htmltextareaelement, accesskey)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	nsEmbedString accesskey;
    CODE:
	htmltextareaelement->SetAccessKey(accesskey);

## GetCols(PRInt32 *aCols)
PRInt32
moz_dom_GetCols (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	PRInt32 cols;
    CODE:
	htmltextareaelement->GetCols(&cols);
	RETVAL = cols;
    OUTPUT:
	RETVAL

## SetCols(PRInt32 aCols)
void
moz_dom_SetCols (htmltextareaelement, cols)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	PRInt32  cols;
    CODE:
	htmltextareaelement->SetCols(cols);

## GetDisabled(PRBool *aDisabled)
PRBool
moz_dom_GetDisabled (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	PRBool disabled;
    CODE:
	htmltextareaelement->GetDisabled(&disabled);
	RETVAL = disabled;
    OUTPUT:
	RETVAL

## SetDisabled(PRBool aDisabled)
void
moz_dom_SetDisabled (htmltextareaelement, disabled)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	PRBool  disabled;
    CODE:
	htmltextareaelement->SetDisabled(disabled);

## GetName(nsAString & aName)
nsEmbedString
moz_dom_GetName (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	nsEmbedString name;
    CODE:
	htmltextareaelement->GetName(name);
	RETVAL = name;
    OUTPUT:
	RETVAL

## SetName(const nsAString & aName)
void
moz_dom_SetName (htmltextareaelement, name)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	nsEmbedString name;
    CODE:
	htmltextareaelement->SetName(name);

## GetReadOnly(PRBool *aReadOnly)
PRBool
moz_dom_GetReadOnly (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	PRBool readonly;
    CODE:
	htmltextareaelement->GetReadOnly(&readonly);
	RETVAL = readonly;
    OUTPUT:
	RETVAL

## SetReadOnly(PRBool aReadOnly)
void
moz_dom_SetReadOnly (htmltextareaelement, readonly)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	PRBool  readonly;
    CODE:
	htmltextareaelement->SetReadOnly(readonly);

## GetRows(PRInt32 *aRows)
PRInt32
moz_dom_GetRows (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	PRInt32 rows;
    CODE:
	htmltextareaelement->GetRows(&rows);
	RETVAL = rows;
    OUTPUT:
	RETVAL

## SetRows(PRInt32 aRows)
void
moz_dom_SetRows (htmltextareaelement, rows)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	PRInt32  rows;
    CODE:
	htmltextareaelement->SetRows(rows);

## GetTabIndex(PRInt32 *aTabIndex)
PRInt32
moz_dom_GetTabIndex (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	PRInt32 tabindex;
    CODE:
	htmltextareaelement->GetTabIndex(&tabindex);
	RETVAL = tabindex;
    OUTPUT:
	RETVAL

## SetTabIndex(PRInt32 aTabIndex)
void
moz_dom_SetTabIndex (htmltextareaelement, tabindex)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	PRInt32  tabindex;
    CODE:
	htmltextareaelement->SetTabIndex(tabindex);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmltextareaelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## GetValue(nsAString & aValue)
nsEmbedString
moz_dom_GetValue (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    PREINIT:
	nsEmbedString value;
    CODE:
	htmltextareaelement->GetValue(value);
	RETVAL = value;
    OUTPUT:
	RETVAL

## SetValue(const nsAString & aValue)
void
moz_dom_SetValue (htmltextareaelement, value)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
	nsEmbedString value;
    CODE:
	htmltextareaelement->SetValue(value);

## Blur(void)
void
moz_dom_Blur (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    CODE:
	htmltextareaelement->Blur();

## Focus(void)
void
moz_dom_Focus (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    CODE:
	htmltextareaelement->Focus();

## Select(void)
void
moz_dom_Select (htmltextareaelement)
	nsIDOMHTMLTextAreaElement *htmltextareaelement;
    CODE:
	htmltextareaelement->Select();

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLTitleElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLTitleElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLTITLEELEMENT_IID)
static nsIID
nsIDOMHTMLTitleElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLTitleElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetText(nsAString & aText)
nsEmbedString
moz_dom_GetText (htmltitleelement)
	nsIDOMHTMLTitleElement *htmltitleelement;
    PREINIT:
	nsEmbedString text;
    CODE:
	htmltitleelement->GetText(text);
	RETVAL = text;
    OUTPUT:
	RETVAL

## SetText(const nsAString & aText)
void
moz_dom_SetText (htmltitleelement, text)
	nsIDOMHTMLTitleElement *htmltitleelement;
	nsEmbedString text;
    CODE:
	htmltitleelement->SetText(text);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::HTMLUListElement	PREFIX = moz_dom_

# /usr/include/mozilla/nsIDOMHTMLUListElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHTMLULISTELEMENT_IID)
static nsIID
nsIDOMHTMLUListElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMHTMLUListElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetCompact(PRBool *aCompact)
PRBool
moz_dom_GetCompact (htmlulistelement)
	nsIDOMHTMLUListElement *htmlulistelement;
    PREINIT:
	PRBool compact;
    CODE:
	htmlulistelement->GetCompact(&compact);
	RETVAL = compact;
    OUTPUT:
	RETVAL

## SetCompact(PRBool aCompact)
void
moz_dom_SetCompact (htmlulistelement, compact)
	nsIDOMHTMLUListElement *htmlulistelement;
	PRBool  compact;
    CODE:
	htmlulistelement->SetCompact(compact);

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (htmlulistelement)
	nsIDOMHTMLUListElement *htmlulistelement;
    PREINIT:
	nsEmbedString type;
    CODE:
	htmlulistelement->GetType(type);
	RETVAL = type;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (htmlulistelement, type)
	nsIDOMHTMLUListElement *htmlulistelement;
	nsEmbedString type;
    CODE:
	htmlulistelement->SetType(type);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLAnchorElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLAnchorElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLANCHORELEMENT_IID)
static nsIID
nsIDOMNSHTMLAnchorElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLAnchorElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetProtocol(nsAString & aProtocol)
nsEmbedString
moz_dom_GetProtocol (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aProtocol;
    CODE:
	nshtmlanchorelement->GetProtocol(aProtocol);
	RETVAL = aProtocol;
    OUTPUT:
	RETVAL

## SetProtocol(const nsAString & aProtocol)
void
moz_dom_SetProtocol (nshtmlanchorelement, aProtocol)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
	nsEmbedString aProtocol;
    CODE:
	nshtmlanchorelement->SetProtocol(aProtocol);

## GetHost(nsAString & aHost)
nsEmbedString
moz_dom_GetHost (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aHost;
    CODE:
	nshtmlanchorelement->GetHost(aHost);
	RETVAL = aHost;
    OUTPUT:
	RETVAL

## SetHost(const nsAString & aHost)
void
moz_dom_SetHost (nshtmlanchorelement, aHost)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
	nsEmbedString aHost;
    CODE:
	nshtmlanchorelement->SetHost(aHost);

## GetHostname(nsAString & aHostname)
nsEmbedString
moz_dom_GetHostname (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aHostname;
    CODE:
	nshtmlanchorelement->GetHostname(aHostname);
	RETVAL = aHostname;
    OUTPUT:
	RETVAL

## SetHostname(const nsAString & aHostname)
void
moz_dom_SetHostname (nshtmlanchorelement, aHostname)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
	nsEmbedString aHostname;
    CODE:
	nshtmlanchorelement->SetHostname(aHostname);

## GetPathname(nsAString & aPathname)
nsEmbedString
moz_dom_GetPathname (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aPathname;
    CODE:
	nshtmlanchorelement->GetPathname(aPathname);
	RETVAL = aPathname;
    OUTPUT:
	RETVAL

## SetPathname(const nsAString & aPathname)
void
moz_dom_SetPathname (nshtmlanchorelement, aPathname)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
	nsEmbedString aPathname;
    CODE:
	nshtmlanchorelement->SetPathname(aPathname);

## GetSearch(nsAString & aSearch)
nsEmbedString
moz_dom_GetSearch (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aSearch;
    CODE:
	nshtmlanchorelement->GetSearch(aSearch);
	RETVAL = aSearch;
    OUTPUT:
	RETVAL

## SetSearch(const nsAString & aSearch)
void
moz_dom_SetSearch (nshtmlanchorelement, aSearch)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
	nsEmbedString aSearch;
    CODE:
	nshtmlanchorelement->SetSearch(aSearch);

## GetPort(nsAString & aPort)
nsEmbedString
moz_dom_GetPort (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aPort;
    CODE:
	nshtmlanchorelement->GetPort(aPort);
	RETVAL = aPort;
    OUTPUT:
	RETVAL

## SetPort(const nsAString & aPort)
void
moz_dom_SetPort (nshtmlanchorelement, aPort)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
	nsEmbedString aPort;
    CODE:
	nshtmlanchorelement->SetPort(aPort);

## GetHash(nsAString & aHash)
nsEmbedString
moz_dom_GetHash (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aHash;
    CODE:
	nshtmlanchorelement->GetHash(aHash);
	RETVAL = aHash;
    OUTPUT:
	RETVAL

## SetHash(const nsAString & aHash)
void
moz_dom_SetHash (nshtmlanchorelement, aHash)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
	nsEmbedString aHash;
    CODE:
	nshtmlanchorelement->SetHash(aHash);

## GetText(nsAString & aText)
nsEmbedString
moz_dom_GetText (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString aText;
    CODE:
	nshtmlanchorelement->GetText(aText);
	RETVAL = aText;
    OUTPUT:
	RETVAL

## ToString(nsAString & _retval)
nsEmbedString
moz_dom_ToString (nshtmlanchorelement)
	nsIDOMNSHTMLAnchorElement *nshtmlanchorelement;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	nshtmlanchorelement->ToString(_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLAreaElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLAreaElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLAREAELEMENT_IID)
static nsIID
nsIDOMNSHTMLAreaElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLAreaElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetProtocol(nsAString & aProtocol)
nsEmbedString
moz_dom_GetProtocol (nshtmlareaelement)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
    PREINIT:
	nsEmbedString aProtocol;
    CODE:
	nshtmlareaelement->GetProtocol(aProtocol);
	RETVAL = aProtocol;
    OUTPUT:
	RETVAL

## SetProtocol(const nsAString & aProtocol)
void
moz_dom_SetProtocol (nshtmlareaelement, aProtocol)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
	nsEmbedString aProtocol;
    CODE:
	nshtmlareaelement->SetProtocol(aProtocol);

## GetHost(nsAString & aHost)
nsEmbedString
moz_dom_GetHost (nshtmlareaelement)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
    PREINIT:
	nsEmbedString aHost;
    CODE:
	nshtmlareaelement->GetHost(aHost);
	RETVAL = aHost;
    OUTPUT:
	RETVAL

## SetHost(const nsAString & aHost)
void
moz_dom_SetHost (nshtmlareaelement, aHost)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
	nsEmbedString aHost;
    CODE:
	nshtmlareaelement->SetHost(aHost);

## GetHostname(nsAString & aHostname)
nsEmbedString
moz_dom_GetHostname (nshtmlareaelement)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
    PREINIT:
	nsEmbedString aHostname;
    CODE:
	nshtmlareaelement->GetHostname(aHostname);
	RETVAL = aHostname;
    OUTPUT:
	RETVAL

## SetHostname(const nsAString & aHostname)
void
moz_dom_SetHostname (nshtmlareaelement, aHostname)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
	nsEmbedString aHostname;
    CODE:
	nshtmlareaelement->SetHostname(aHostname);

## GetPathname(nsAString & aPathname)
nsEmbedString
moz_dom_GetPathname (nshtmlareaelement)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
    PREINIT:
	nsEmbedString aPathname;
    CODE:
	nshtmlareaelement->GetPathname(aPathname);
	RETVAL = aPathname;
    OUTPUT:
	RETVAL

## SetPathname(const nsAString & aPathname)
void
moz_dom_SetPathname (nshtmlareaelement, aPathname)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
	nsEmbedString aPathname;
    CODE:
	nshtmlareaelement->SetPathname(aPathname);

## GetSearch(nsAString & aSearch)
nsEmbedString
moz_dom_GetSearch (nshtmlareaelement)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
    PREINIT:
	nsEmbedString aSearch;
    CODE:
	nshtmlareaelement->GetSearch(aSearch);
	RETVAL = aSearch;
    OUTPUT:
	RETVAL

## SetSearch(const nsAString & aSearch)
void
moz_dom_SetSearch (nshtmlareaelement, aSearch)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
	nsEmbedString aSearch;
    CODE:
	nshtmlareaelement->SetSearch(aSearch);

## GetPort(nsAString & aPort)
nsEmbedString
moz_dom_GetPort (nshtmlareaelement)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
    PREINIT:
	nsEmbedString aPort;
    CODE:
	nshtmlareaelement->GetPort(aPort);
	RETVAL = aPort;
    OUTPUT:
	RETVAL

## SetPort(const nsAString & aPort)
void
moz_dom_SetPort (nshtmlareaelement, aPort)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
	nsEmbedString aPort;
    CODE:
	nshtmlareaelement->SetPort(aPort);

## GetHash(nsAString & aHash)
nsEmbedString
moz_dom_GetHash (nshtmlareaelement)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
    PREINIT:
	nsEmbedString aHash;
    CODE:
	nshtmlareaelement->GetHash(aHash);
	RETVAL = aHash;
    OUTPUT:
	RETVAL

## SetHash(const nsAString & aHash)
void
moz_dom_SetHash (nshtmlareaelement, aHash)
	nsIDOMNSHTMLAreaElement *nshtmlareaelement;
	nsEmbedString aHash;
    CODE:
	nshtmlareaelement->SetHash(aHash);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLButtonElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLButtonElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLBUTTONELEMENT_IID)
static nsIID
nsIDOMNSHTMLButtonElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLButtonElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## Blur(void)
void
moz_dom_Blur (nshtmlbuttonelement)
	nsIDOMNSHTMLButtonElement *nshtmlbuttonelement;
    CODE:
	nshtmlbuttonelement->Blur();

## Focus(void)
void
moz_dom_Focus (nshtmlbuttonelement)
	nsIDOMNSHTMLButtonElement *nshtmlbuttonelement;
    CODE:
	nshtmlbuttonelement->Focus();

## Click(void)
void
moz_dom_Click (nshtmlbuttonelement)
	nsIDOMNSHTMLButtonElement *nshtmlbuttonelement;
    CODE:
	nshtmlbuttonelement->Click();

## GetType(nsAString & aType)
nsEmbedString
moz_dom_GetType (nshtmlbuttonelement)
	nsIDOMNSHTMLButtonElement *nshtmlbuttonelement;
    PREINIT:
	nsEmbedString aType;
    CODE:
	nshtmlbuttonelement->GetType(aType);
	RETVAL = aType;
    OUTPUT:
	RETVAL

## SetType(const nsAString & aType)
void
moz_dom_SetType (nshtmlbuttonelement, aType)
	nsIDOMNSHTMLButtonElement *nshtmlbuttonelement;
	nsEmbedString aType;
    CODE:
	nshtmlbuttonelement->SetType(aType);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLDocument	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLDocument.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLDOCUMENT_IID)
static nsIID
nsIDOMNSHTMLDocument::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLDocument::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetWidth(PRInt32 *aWidth)
PRInt32
moz_dom_GetWidth (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	PRInt32 aWidth;
    CODE:
	nshtmldocument->GetWidth(&aWidth);
	RETVAL = aWidth;
    OUTPUT:
	RETVAL

## GetHeight(PRInt32 *aHeight)
PRInt32
moz_dom_GetHeight (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	PRInt32 aHeight;
    CODE:
	nshtmldocument->GetHeight(&aHeight);
	RETVAL = aHeight;
    OUTPUT:
	RETVAL

## GetAlinkColor(nsAString & aAlinkColor)
nsEmbedString
moz_dom_GetAlinkColor (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aAlinkColor;
    CODE:
	nshtmldocument->GetAlinkColor(aAlinkColor);
	RETVAL = aAlinkColor;
    OUTPUT:
	RETVAL

## SetAlinkColor(const nsAString & aAlinkColor)
void
moz_dom_SetAlinkColor (nshtmldocument, aAlinkColor)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString aAlinkColor;
    CODE:
	nshtmldocument->SetAlinkColor(aAlinkColor);

## GetLinkColor(nsAString & aLinkColor)
nsEmbedString
moz_dom_GetLinkColor (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aLinkColor;
    CODE:
	nshtmldocument->GetLinkColor(aLinkColor);
	RETVAL = aLinkColor;
    OUTPUT:
	RETVAL

## SetLinkColor(const nsAString & aLinkColor)
void
moz_dom_SetLinkColor (nshtmldocument, aLinkColor)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString aLinkColor;
    CODE:
	nshtmldocument->SetLinkColor(aLinkColor);

## GetVlinkColor(nsAString & aVlinkColor)
nsEmbedString
moz_dom_GetVlinkColor (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aVlinkColor;
    CODE:
	nshtmldocument->GetVlinkColor(aVlinkColor);
	RETVAL = aVlinkColor;
    OUTPUT:
	RETVAL

## SetVlinkColor(const nsAString & aVlinkColor)
void
moz_dom_SetVlinkColor (nshtmldocument, aVlinkColor)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString aVlinkColor;
    CODE:
	nshtmldocument->SetVlinkColor(aVlinkColor);

## GetBgColor(nsAString & aBgColor)
nsEmbedString
moz_dom_GetBgColor (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aBgColor;
    CODE:
	nshtmldocument->GetBgColor(aBgColor);
	RETVAL = aBgColor;
    OUTPUT:
	RETVAL

## SetBgColor(const nsAString & aBgColor)
void
moz_dom_SetBgColor (nshtmldocument, aBgColor)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString aBgColor;
    CODE:
	nshtmldocument->SetBgColor(aBgColor);

## GetFgColor(nsAString & aFgColor)
nsEmbedString
moz_dom_GetFgColor (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aFgColor;
    CODE:
	nshtmldocument->GetFgColor(aFgColor);
	RETVAL = aFgColor;
    OUTPUT:
	RETVAL

## SetFgColor(const nsAString & aFgColor)
void
moz_dom_SetFgColor (nshtmldocument, aFgColor)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString aFgColor;
    CODE:
	nshtmldocument->SetFgColor(aFgColor);

## GetDomain(nsAString & aDomain)
nsEmbedString
moz_dom_GetDomain (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aDomain;
    CODE:
	nshtmldocument->GetDomain(aDomain);
	RETVAL = aDomain;
    OUTPUT:
	RETVAL

## SetDomain(const nsAString & aDomain)
void
moz_dom_SetDomain (nshtmldocument, aDomain)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString aDomain;
    CODE:
	nshtmldocument->SetDomain(aDomain);

## GetEmbeds(nsIDOMHTMLCollection * *aEmbeds)
nsIDOMHTMLCollection *
moz_dom_GetEmbeds_htmlcollection (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsIDOMHTMLCollection * aEmbeds;
    CODE:
	nshtmldocument->GetEmbeds(&aEmbeds);
	RETVAL = aEmbeds;
    OUTPUT:
	RETVAL

## GetSelection(nsAString & _retval)
nsEmbedString
moz_dom_GetSelection (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	nshtmldocument->GetSelection(_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Open(nsIDOMDocument **_retval)
## was: moz_dom_Open (nshtmldocument), nshtmldocument->Open(&_retval);
nsIDOMDocument *
moz_dom_Open (nshtmldocument, nsEmbedCString & contentType , PRBool & replace)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsIDOMDocument * _retval;
    CODE:
        nshtmldocument->Open(contentType, replace, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## Write(void)
void
moz_dom_Write (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    CODE:
	nshtmldocument->Write();

## Writeln(void)
void
moz_dom_Writeln (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    CODE:
	nshtmldocument->Writeln();

## Clear(void)
void
moz_dom_Clear (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    CODE:
	nshtmldocument->Clear();


## see https://developer.mozilla.org/en/Gecko_1.9_Changes_affecting_websites

#ifdef NOT_SUPPORTED_ANYMORE

## CaptureEvents(PRInt32 eventFlags)
void
moz_dom_CaptureEvents (nshtmldocument, eventFlags)
	nsIDOMNSHTMLDocument *nshtmldocument;
	PRInt32  eventFlags;
    CODE:
	nshtmldocument->CaptureEvents(eventFlags);

## ReleaseEvents(PRInt32 eventFlags)
void
moz_dom_ReleaseEvents (nshtmldocument, eventFlags)
	nsIDOMNSHTMLDocument *nshtmldocument;
	PRInt32  eventFlags;
    CODE:
	nshtmldocument->ReleaseEvents(eventFlags);

## RouteEvent(nsIDOMEvent *evt)
void
moz_dom_RouteEvent (nshtmldocument, evt)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsIDOMEvent * evt;
    CODE:
	nshtmldocument->RouteEvent(evt);

#endif

## GetCompatMode(nsAString & aCompatMode)
nsEmbedString
moz_dom_GetCompatMode (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aCompatMode;
    CODE:
	nshtmldocument->GetCompatMode(aCompatMode);
	RETVAL = aCompatMode;
    OUTPUT:
	RETVAL

## GetPlugins(nsIDOMHTMLCollection * *aPlugins)
nsIDOMHTMLCollection *
moz_dom_GetPlugins_htmlcollection (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsIDOMHTMLCollection * aPlugins;
    CODE:
	nshtmldocument->GetPlugins(&aPlugins);
	RETVAL = aPlugins;
    OUTPUT:
	RETVAL

## GetDesignMode(nsAString & aDesignMode)
nsEmbedString
moz_dom_GetDesignMode (nshtmldocument)
	nsIDOMNSHTMLDocument *nshtmldocument;
    PREINIT:
	nsEmbedString aDesignMode;
    CODE:
	nshtmldocument->GetDesignMode(aDesignMode);
	RETVAL = aDesignMode;
    OUTPUT:
	RETVAL

## SetDesignMode(const nsAString & aDesignMode)
void
moz_dom_SetDesignMode (nshtmldocument, aDesignMode)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString aDesignMode;
    CODE:
	nshtmldocument->SetDesignMode(aDesignMode);

## ExecCommand(const nsAString & commandID, PRBool doShowUI, const nsAString & value, PRBool *_retval)
PRBool
moz_dom_ExecCommand (nshtmldocument, commandID, doShowUI, value)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
	PRBool  doShowUI;
	nsEmbedString value;
    PREINIT:
	PRBool _retval;
    CODE:
	nshtmldocument->ExecCommand(commandID, doShowUI, value, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## ExecCommandShowHelp(const nsAString & commandID, PRBool *_retval)
PRBool
moz_dom_ExecCommandShowHelp (nshtmldocument, commandID)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
    PREINIT:
	PRBool _retval;
    CODE:
	nshtmldocument->ExecCommandShowHelp(commandID, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## QueryCommandEnabled(const nsAString & commandID, PRBool *_retval)
PRBool
moz_dom_QueryCommandEnabled (nshtmldocument, commandID)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
    PREINIT:
	PRBool _retval;
    CODE:
	nshtmldocument->QueryCommandEnabled(commandID, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## QueryCommandIndeterm(const nsAString & commandID, PRBool *_retval)
PRBool
moz_dom_QueryCommandIndeterm (nshtmldocument, commandID)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
    PREINIT:
	PRBool _retval;
    CODE:
	nshtmldocument->QueryCommandIndeterm(commandID, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## QueryCommandState(const nsAString & commandID, PRBool *_retval)
PRBool
moz_dom_QueryCommandState (nshtmldocument, commandID)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
    PREINIT:
	PRBool _retval;
    CODE:
	nshtmldocument->QueryCommandState(commandID, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## QueryCommandSupported(const nsAString & commandID, PRBool *_retval)
PRBool
moz_dom_QueryCommandSupported (nshtmldocument, commandID)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
    PREINIT:
	PRBool _retval;
    CODE:
	nshtmldocument->QueryCommandSupported(commandID, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## QueryCommandText(const nsAString & commandID, nsAString & _retval)
nsEmbedString
moz_dom_QueryCommandText (nshtmldocument, commandID)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	nshtmldocument->QueryCommandText(commandID, _retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## QueryCommandValue(const nsAString & commandID, nsAString & _retval)
nsEmbedString
moz_dom_QueryCommandValue (nshtmldocument, commandID)
	nsIDOMNSHTMLDocument *nshtmldocument;
	nsEmbedString commandID;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	nshtmldocument->QueryCommandValue(commandID, _retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLFormElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLFormElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLFORMELEMENT_IID)
static nsIID
nsIDOMNSHTMLFormElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLFormElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetEncoding(nsAString & aEncoding)
nsEmbedString
moz_dom_GetEncoding (nshtmlformelement)
	nsIDOMNSHTMLFormElement *nshtmlformelement;
    PREINIT:
	nsEmbedString aEncoding;
    CODE:
	nshtmlformelement->GetEncoding(aEncoding);
	RETVAL = aEncoding;
    OUTPUT:
	RETVAL

## SetEncoding(const nsAString & aEncoding)
void
moz_dom_SetEncoding (nshtmlformelement, aEncoding)
	nsIDOMNSHTMLFormElement *nshtmlformelement;
	nsEmbedString aEncoding;
    CODE:
	nshtmlformelement->SetEncoding(aEncoding);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLFrameElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLFrameElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLFRAMEELEMENT_IID)
static nsIID
nsIDOMNSHTMLFrameElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLFrameElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetContentWindow(nsIDOMWindow * *aContentWindow)
nsIDOMWindow *
moz_dom_GetContentWindow (nshtmlframeelement)
	nsIDOMNSHTMLFrameElement *nshtmlframeelement;
    PREINIT:
	nsIDOMWindow * aContentWindow;
    CODE:
	nshtmlframeelement->GetContentWindow(&aContentWindow);
	RETVAL = aContentWindow;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLHRElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLHRElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLHRELEMENT_IID)
static nsIID
nsIDOMNSHTMLHRElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLHRElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetColor(nsAString & aColor)
nsEmbedString
moz_dom_GetColor (nshtmlhrelement)
	nsIDOMNSHTMLHRElement *nshtmlhrelement;
    PREINIT:
	nsEmbedString aColor;
    CODE:
	nshtmlhrelement->GetColor(aColor);
	RETVAL = aColor;
    OUTPUT:
	RETVAL

## SetColor(const nsAString & aColor)
void
moz_dom_SetColor (nshtmlhrelement, aColor)
	nsIDOMNSHTMLHRElement *nshtmlhrelement;
	nsEmbedString aColor;
    CODE:
	nshtmlhrelement->SetColor(aColor);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLImageElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLImageElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLIMAGEELEMENT_IID)
static nsIID
nsIDOMNSHTMLImageElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLImageElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetLowsrc(nsAString & aLowsrc)
nsEmbedString
moz_dom_GetLowsrc (nshtmlimageelement)
	nsIDOMNSHTMLImageElement *nshtmlimageelement;
    PREINIT:
	nsEmbedString aLowsrc;
    CODE:
	nshtmlimageelement->GetLowsrc(aLowsrc);
	RETVAL = aLowsrc;
    OUTPUT:
	RETVAL

## SetLowsrc(const nsAString & aLowsrc)
void
moz_dom_SetLowsrc (nshtmlimageelement, aLowsrc)
	nsIDOMNSHTMLImageElement *nshtmlimageelement;
	nsEmbedString aLowsrc;
    CODE:
	nshtmlimageelement->SetLowsrc(aLowsrc);

## GetComplete(PRBool *aComplete)
PRBool
moz_dom_GetComplete (nshtmlimageelement)
	nsIDOMNSHTMLImageElement *nshtmlimageelement;
    PREINIT:
	PRBool aComplete;
    CODE:
	nshtmlimageelement->GetComplete(&aComplete);
	RETVAL = aComplete;
    OUTPUT:
	RETVAL

## GetNaturalHeight(PRInt32 *aNaturalHeight)
PRInt32
moz_dom_GetNaturalHeight (nshtmlimageelement)
	nsIDOMNSHTMLImageElement *nshtmlimageelement;
    PREINIT:
	PRInt32 aNaturalHeight;
    CODE:
	nshtmlimageelement->GetNaturalHeight(&aNaturalHeight);
	RETVAL = aNaturalHeight;
    OUTPUT:
	RETVAL

## GetNaturalWidth(PRInt32 *aNaturalWidth)
PRInt32
moz_dom_GetNaturalWidth (nshtmlimageelement)
	nsIDOMNSHTMLImageElement *nshtmlimageelement;
    PREINIT:
	PRInt32 aNaturalWidth;
    CODE:
	nshtmlimageelement->GetNaturalWidth(&aNaturalWidth);
	RETVAL = aNaturalWidth;
    OUTPUT:
	RETVAL

## GetX(PRInt32 *aX)
PRInt32
moz_dom_GetX (nshtmlimageelement)
	nsIDOMNSHTMLImageElement *nshtmlimageelement;
    PREINIT:
	PRInt32 aX;
    CODE:
	nshtmlimageelement->GetX(&aX);
	RETVAL = aX;
    OUTPUT:
	RETVAL

## GetY(PRInt32 *aY)
PRInt32
moz_dom_GetY (nshtmlimageelement)
	nsIDOMNSHTMLImageElement *nshtmlimageelement;
    PREINIT:
	PRInt32 aY;
    CODE:
	nshtmlimageelement->GetY(&aY);
	RETVAL = aY;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLInputElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLInputElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLINPUTELEMENT_IID)
static nsIID
nsIDOMNSHTMLInputElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLInputElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

### GetControllers(nsIControllers * *aControllers)
#nsIControllers *
#moz_dom_GetControllers (nshtmlinputelement)
#	nsIDOMNSHTMLInputElement *nshtmlinputelement;
#    PREINIT:
#	nsIControllers * aControllers;
#    CODE:
#	nshtmlinputelement->GetControllers(&aControllers);
#	RETVAL = aControllers;
#    OUTPUT:
#	RETVAL

## GetTextLength(PRInt32 *aTextLength)
PRInt32
moz_dom_GetTextLength (nshtmlinputelement)
	nsIDOMNSHTMLInputElement *nshtmlinputelement;
    PREINIT:
	PRInt32 aTextLength;
    CODE:
	nshtmlinputelement->GetTextLength(&aTextLength);
	RETVAL = aTextLength;
    OUTPUT:
	RETVAL

## GetSelectionStart(PRInt32 *aSelectionStart)
PRInt32
moz_dom_GetSelectionStart (nshtmlinputelement)
	nsIDOMNSHTMLInputElement *nshtmlinputelement;
    PREINIT:
	PRInt32 aSelectionStart;
    CODE:
	nshtmlinputelement->GetSelectionStart(&aSelectionStart);
	RETVAL = aSelectionStart;
    OUTPUT:
	RETVAL

## SetSelectionStart(PRInt32 aSelectionStart)
void
moz_dom_SetSelectionStart (nshtmlinputelement, aSelectionStart)
	nsIDOMNSHTMLInputElement *nshtmlinputelement;
	PRInt32  aSelectionStart;
    CODE:
	nshtmlinputelement->SetSelectionStart(aSelectionStart);

## GetSelectionEnd(PRInt32 *aSelectionEnd)
PRInt32
moz_dom_GetSelectionEnd (nshtmlinputelement)
	nsIDOMNSHTMLInputElement *nshtmlinputelement;
    PREINIT:
	PRInt32 aSelectionEnd;
    CODE:
	nshtmlinputelement->GetSelectionEnd(&aSelectionEnd);
	RETVAL = aSelectionEnd;
    OUTPUT:
	RETVAL

## SetSelectionEnd(PRInt32 aSelectionEnd)
void
moz_dom_SetSelectionEnd (nshtmlinputelement, aSelectionEnd)
	nsIDOMNSHTMLInputElement *nshtmlinputelement;
	PRInt32  aSelectionEnd;
    CODE:
	nshtmlinputelement->SetSelectionEnd(aSelectionEnd);

## SetSelectionRange(PRInt32 selectionStart, PRInt32 selectionEnd)
void
moz_dom_SetSelectionRange (nshtmlinputelement, selectionStart, selectionEnd)
	nsIDOMNSHTMLInputElement *nshtmlinputelement;
	PRInt32  selectionStart;
	PRInt32  selectionEnd;
    CODE:
	nshtmlinputelement->SetSelectionRange(selectionStart, selectionEnd);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLOptionElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLOptionElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLOPTIONELEMENT_IID)
static nsIID
nsIDOMNSHTMLOptionElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLOptionElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetText(nsAString & aText)
nsEmbedString
moz_dom_GetText (nshtmloptionelement)
	nsIDOMNSHTMLOptionElement *nshtmloptionelement;
    PREINIT:
	nsEmbedString aText;
    CODE:
	nshtmloptionelement->GetText(aText);
	RETVAL = aText;
    OUTPUT:
	RETVAL

## SetText(const nsAString & aText)
void
moz_dom_SetText (nshtmloptionelement, aText)
	nsIDOMNSHTMLOptionElement *nshtmloptionelement;
	nsEmbedString aText;
    CODE:
	nshtmloptionelement->SetText(aText);

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLSelectElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLSelectElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLSELECTELEMENT_IID)
static nsIID
nsIDOMNSHTMLSelectElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLSelectElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## Item(PRUint32 index, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_Item (nshtmlselectelement, index)
	nsIDOMNSHTMLSelectElement *nshtmlselectelement;
	PRUint32  index;
    PREINIT:
	nsIDOMNode * _retval;
    CODE:
	nshtmlselectelement->Item(index, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## NamedItem(const nsAString & name, nsIDOMNode **_retval)
nsIDOMNode *
moz_dom_NamedItem (nshtmlselectelement, name)
	nsIDOMNSHTMLSelectElement *nshtmlselectelement;
	nsEmbedString name;
    PREINIT:
	nsIDOMNode * _retval;
    CODE:
	nshtmlselectelement->NamedItem(name, &_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::NSHTMLTextAreaElement	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNSHTMLTextAreaElement.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNSHTMLTEXTAREAELEMENT_IID)
static nsIID
nsIDOMNSHTMLTextAreaElement::GetIID()
    CODE:
	const nsIID &id = nsIDOMNSHTMLTextAreaElement::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

### GetControllers(nsIControllers * *aControllers)
#nsIControllers *
#moz_dom_GetControllers (nshtmltextareaelement)
#	nsIDOMNSHTMLTextAreaElement *nshtmltextareaelement;
#    PREINIT:
#	nsIControllers * aControllers;
#    CODE:
#	nshtmltextareaelement->GetControllers(&aControllers);
#	RETVAL = aControllers;
#    OUTPUT:
#	RETVAL

## GetTextLength(PRInt32 *aTextLength)
PRInt32
moz_dom_GetTextLength (nshtmltextareaelement)
	nsIDOMNSHTMLTextAreaElement *nshtmltextareaelement;
    PREINIT:
	PRInt32 aTextLength;
    CODE:
	nshtmltextareaelement->GetTextLength(&aTextLength);
	RETVAL = aTextLength;
    OUTPUT:
	RETVAL

## GetSelectionStart(PRInt32 *aSelectionStart)
PRInt32
moz_dom_GetSelectionStart (nshtmltextareaelement)
	nsIDOMNSHTMLTextAreaElement *nshtmltextareaelement;
    PREINIT:
	PRInt32 aSelectionStart;
    CODE:
	nshtmltextareaelement->GetSelectionStart(&aSelectionStart);
	RETVAL = aSelectionStart;
    OUTPUT:
	RETVAL

## SetSelectionStart(PRInt32 aSelectionStart)
void
moz_dom_SetSelectionStart (nshtmltextareaelement, aSelectionStart)
	nsIDOMNSHTMLTextAreaElement *nshtmltextareaelement;
	PRInt32  aSelectionStart;
    CODE:
	nshtmltextareaelement->SetSelectionStart(aSelectionStart);

## GetSelectionEnd(PRInt32 *aSelectionEnd)
PRInt32
moz_dom_GetSelectionEnd (nshtmltextareaelement)
	nsIDOMNSHTMLTextAreaElement *nshtmltextareaelement;
    PREINIT:
	PRInt32 aSelectionEnd;
    CODE:
	nshtmltextareaelement->GetSelectionEnd(&aSelectionEnd);
	RETVAL = aSelectionEnd;
    OUTPUT:
	RETVAL

## SetSelectionEnd(PRInt32 aSelectionEnd)
void
moz_dom_SetSelectionEnd (nshtmltextareaelement, aSelectionEnd)
	nsIDOMNSHTMLTextAreaElement *nshtmltextareaelement;
	PRInt32  aSelectionEnd;
    CODE:
	nshtmltextareaelement->SetSelectionEnd(aSelectionEnd);

## SetSelectionRange(PRInt32 selectionStart, PRInt32 selectionEnd)
void
moz_dom_SetSelectionRange (nshtmltextareaelement, selectionStart, selectionEnd)
	nsIDOMNSHTMLTextAreaElement *nshtmltextareaelement;
	PRInt32  selectionStart;
	PRInt32  selectionEnd;
    CODE:
	nshtmltextareaelement->SetSelectionRange(selectionStart, selectionEnd);


# -----------------------------------------------------------------------------


MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Navigator	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMNavigator.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMNAVIGATOR_IID)
static nsIID
nsIDOMNavigator::GetIID()
    CODE:
	const nsIID &id = nsIDOMNavigator::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetAppCodeName(nsAString & aAppCodeName)
nsEmbedString
moz_dom_GetAppCodeName (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aAppCodeName;
    CODE:
	navigator->GetAppCodeName(aAppCodeName);
	RETVAL = aAppCodeName;
    OUTPUT:
	RETVAL

## GetAppName(nsAString & aAppName)
nsEmbedString
moz_dom_GetAppName (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aAppName;
    CODE:
	navigator->GetAppName(aAppName);
	RETVAL = aAppName;
    OUTPUT:
	RETVAL

## GetAppVersion(nsAString & aAppVersion)
nsEmbedString
moz_dom_GetAppVersion (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aAppVersion;
    CODE:
	navigator->GetAppVersion(aAppVersion);
	RETVAL = aAppVersion;
    OUTPUT:
	RETVAL

## GetLanguage(nsAString & aLanguage)
nsEmbedString
moz_dom_GetLanguage (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aLanguage;
    CODE:
	navigator->GetLanguage(aLanguage);
	RETVAL = aLanguage;
    OUTPUT:
	RETVAL

### GetMimeTypes(nsIDOMMimeTypeArray * *aMimeTypes)
#nsIDOMMimeTypeArray *
#moz_dom_GetMimeTypes (navigator)
#	nsIDOMNavigator *navigator;
#    PREINIT:
#	nsIDOMMimeTypeArray * aMimeTypes;
#    CODE:
#	navigator->GetMimeTypes(&aMimeTypes);
#	RETVAL = aMimeTypes;
#    OUTPUT:
#	RETVAL

## GetPlatform(nsAString & aPlatform)
nsEmbedString
moz_dom_GetPlatform (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aPlatform;
    CODE:
	navigator->GetPlatform(aPlatform);
	RETVAL = aPlatform;
    OUTPUT:
	RETVAL

## GetOscpu(nsAString & aOscpu)
nsEmbedString
moz_dom_GetOscpu (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aOscpu;
    CODE:
	navigator->GetOscpu(aOscpu);
	RETVAL = aOscpu;
    OUTPUT:
	RETVAL

## GetVendor(nsAString & aVendor)
nsEmbedString
moz_dom_GetVendor (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aVendor;
    CODE:
	navigator->GetVendor(aVendor);
	RETVAL = aVendor;
    OUTPUT:
	RETVAL

## GetVendorSub(nsAString & aVendorSub)
nsEmbedString
moz_dom_GetVendorSub (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aVendorSub;
    CODE:
	navigator->GetVendorSub(aVendorSub);
	RETVAL = aVendorSub;
    OUTPUT:
	RETVAL

## GetProduct(nsAString & aProduct)
nsEmbedString
moz_dom_GetProduct (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aProduct;
    CODE:
	navigator->GetProduct(aProduct);
	RETVAL = aProduct;
    OUTPUT:
	RETVAL

## GetProductSub(nsAString & aProductSub)
nsEmbedString
moz_dom_GetProductSub (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aProductSub;
    CODE:
	navigator->GetProductSub(aProductSub);
	RETVAL = aProductSub;
    OUTPUT:
	RETVAL

### GetPlugins(nsIDOMPluginArray * *aPlugins)
#nsIDOMPluginArray *
#moz_dom_GetPlugins (navigator)
#	nsIDOMNavigator *navigator;
#    PREINIT:
#	nsIDOMPluginArray * aPlugins;
#    CODE:
#	navigator->GetPlugins(&aPlugins);
#	RETVAL = aPlugins;
#    OUTPUT:
#	RETVAL

## GetSecurityPolicy(nsAString & aSecurityPolicy)
nsEmbedString
moz_dom_GetSecurityPolicy (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aSecurityPolicy;
    CODE:
	navigator->GetSecurityPolicy(aSecurityPolicy);
	RETVAL = aSecurityPolicy;
    OUTPUT:
	RETVAL

## GetUserAgent(nsAString & aUserAgent)
nsEmbedString
moz_dom_GetUserAgent (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	nsEmbedString aUserAgent;
    CODE:
	navigator->GetUserAgent(aUserAgent);
	RETVAL = aUserAgent;
    OUTPUT:
	RETVAL

## GetCookieEnabled(PRBool *aCookieEnabled)
PRBool
moz_dom_GetCookieEnabled (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	PRBool aCookieEnabled;
    CODE:
	navigator->GetCookieEnabled(&aCookieEnabled);
	RETVAL = aCookieEnabled;
    OUTPUT:
	RETVAL

## JavaEnabled(PRBool *_retval)
PRBool
moz_dom_JavaEnabled (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	PRBool _retval;
    CODE:
	navigator->JavaEnabled(&_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

## TaintEnabled(PRBool *_retval)
PRBool
moz_dom_TaintEnabled (navigator)
	nsIDOMNavigator *navigator;
    PREINIT:
	PRBool _retval;
    CODE:
	navigator->TaintEnabled(&_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::History	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMHistory.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMHISTORY_IID)
static nsIID
nsIDOMHistory::GetIID()
    CODE:
	const nsIID &id = nsIDOMHistory::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetLength(PRInt32 *aLength)
PRInt32
moz_dom_GetLength (history)
	nsIDOMHistory *history;
    PREINIT:
	PRInt32 aLength;
    CODE:
	history->GetLength(&aLength);
	RETVAL = aLength;
    OUTPUT:
	RETVAL

## GetCurrent(nsAString & aCurrent)
nsEmbedString
moz_dom_GetCurrent (history)
	nsIDOMHistory *history;
    PREINIT:
	nsEmbedString aCurrent;
    CODE:
	history->GetCurrent(aCurrent);
	RETVAL = aCurrent;
    OUTPUT:
	RETVAL

## GetPrevious(nsAString & aPrevious)
nsEmbedString
moz_dom_GetPrevious (history)
	nsIDOMHistory *history;
    PREINIT:
	nsEmbedString aPrevious;
    CODE:
	history->GetPrevious(aPrevious);
	RETVAL = aPrevious;
    OUTPUT:
	RETVAL

## GetNext(nsAString & aNext)
nsEmbedString
moz_dom_GetNext (history)
	nsIDOMHistory *history;
    PREINIT:
	nsEmbedString aNext;
    CODE:
	history->GetNext(aNext);
	RETVAL = aNext;
    OUTPUT:
	RETVAL

## Back(void)
void
moz_dom_Back (history)
	nsIDOMHistory *history;
    CODE:
	history->Back();

## Forward(void)
void
moz_dom_Forward (history)
	nsIDOMHistory *history;
    CODE:
	history->Forward();

## Go(PRInt32 aDelta)
void
moz_dom_Go (history, aDelta)
	nsIDOMHistory *history;
	PRInt32  aDelta;
    CODE:
	history->Go(aDelta);

## Item(PRUint32 index, nsAString & _retval)
nsEmbedString
moz_dom_Item (history, index)
	nsIDOMHistory *history;
	PRUint32  index;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	history->Item(index, _retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Location	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMLocation.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMLOCATION_IID)
static nsIID
nsIDOMLocation::GetIID()
    CODE:
	const nsIID &id = nsIDOMLocation::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetHash(nsAString & aHash)
nsEmbedString
moz_dom_GetHash (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aHash;
    CODE:
	location->GetHash(aHash);
	RETVAL = aHash;
    OUTPUT:
	RETVAL

## SetHash(const nsAString & aHash)
void
moz_dom_SetHash (location, aHash)
	nsIDOMLocation *location;
	nsEmbedString aHash;
    CODE:
	location->SetHash(aHash);

## GetHost(nsAString & aHost)
nsEmbedString
moz_dom_GetHost (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aHost;
    CODE:
	location->GetHost(aHost);
	RETVAL = aHost;
    OUTPUT:
	RETVAL

## SetHost(const nsAString & aHost)
void
moz_dom_SetHost (location, aHost)
	nsIDOMLocation *location;
	nsEmbedString aHost;
    CODE:
	location->SetHost(aHost);

## GetHostname(nsAString & aHostname)
nsEmbedString
moz_dom_GetHostname (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aHostname;
    CODE:
	location->GetHostname(aHostname);
	RETVAL = aHostname;
    OUTPUT:
	RETVAL

## SetHostname(const nsAString & aHostname)
void
moz_dom_SetHostname (location, aHostname)
	nsIDOMLocation *location;
	nsEmbedString aHostname;
    CODE:
	location->SetHostname(aHostname);

## GetHref(nsAString & aHref)
nsEmbedString
moz_dom_GetHref (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aHref;
    CODE:
	location->GetHref(aHref);
	RETVAL = aHref;
    OUTPUT:
	RETVAL

## SetHref(const nsAString & aHref)
void
moz_dom_SetHref (location, aHref)
	nsIDOMLocation *location;
	nsEmbedString aHref;
    CODE:
	location->SetHref(aHref);

## GetPathname(nsAString & aPathname)
nsEmbedString
moz_dom_GetPathname (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aPathname;
    CODE:
	location->GetPathname(aPathname);
	RETVAL = aPathname;
    OUTPUT:
	RETVAL

## SetPathname(const nsAString & aPathname)
void
moz_dom_SetPathname (location, aPathname)
	nsIDOMLocation *location;
	nsEmbedString aPathname;
    CODE:
	location->SetPathname(aPathname);

## GetPort(nsAString & aPort)
nsEmbedString
moz_dom_GetPort (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aPort;
    CODE:
	location->GetPort(aPort);
	RETVAL = aPort;
    OUTPUT:
	RETVAL

## SetPort(const nsAString & aPort)
void
moz_dom_SetPort (location, aPort)
	nsIDOMLocation *location;
	nsEmbedString aPort;
    CODE:
	location->SetPort(aPort);

## GetProtocol(nsAString & aProtocol)
nsEmbedString
moz_dom_GetProtocol (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aProtocol;
    CODE:
	location->GetProtocol(aProtocol);
	RETVAL = aProtocol;
    OUTPUT:
	RETVAL

## SetProtocol(const nsAString & aProtocol)
void
moz_dom_SetProtocol (location, aProtocol)
	nsIDOMLocation *location;
	nsEmbedString aProtocol;
    CODE:
	location->SetProtocol(aProtocol);

## GetSearch(nsAString & aSearch)
nsEmbedString
moz_dom_GetSearch (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString aSearch;
    CODE:
	location->GetSearch(aSearch);
	RETVAL = aSearch;
    OUTPUT:
	RETVAL

## SetSearch(const nsAString & aSearch)
void
moz_dom_SetSearch (location, aSearch)
	nsIDOMLocation *location;
	nsEmbedString aSearch;
    CODE:
	location->SetSearch(aSearch);

## Reload(PRBool forceget)
void
moz_dom_Reload (location, forceget)
	nsIDOMLocation *location;
	PRBool  forceget;
    CODE:
	location->Reload(forceget);

## Replace(const nsAString & url)
void
moz_dom_Replace (location, url)
	nsIDOMLocation *location;
	nsEmbedString url;
    CODE:
	location->Replace(url);

## Assign(const nsAString & url)
void
moz_dom_Assign (location, url)
	nsIDOMLocation *location;
	nsEmbedString url;
    CODE:
	location->Assign(url);

## ToString(nsAString & _retval)
nsEmbedString
moz_dom_ToString (location)
	nsIDOMLocation *location;
    PREINIT:
	nsEmbedString _retval;
    CODE:
	location->ToString(_retval);
	RETVAL = _retval;
    OUTPUT:
	RETVAL

# -----------------------------------------------------------------------------

MODULE = Mozilla::DOM	PACKAGE = Mozilla::DOM::Screen	PREFIX = moz_dom_

# /usr/include/mozilla/dom/nsIDOMScreen.h

## NS_DEFINE_STATIC_IID_ACCESSOR(NS_IDOMSCREEN_IID)
static nsIID
nsIDOMScreen::GetIID()
    CODE:
	const nsIID &id = nsIDOMScreen::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

## GetTop(PRInt32 *aTop)
PRInt32
moz_dom_GetTop (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aTop;
    CODE:
	screen->GetTop(&aTop);
	RETVAL = aTop;
    OUTPUT:
	RETVAL

## GetLeft(PRInt32 *aLeft)
PRInt32
moz_dom_GetLeft (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aLeft;
    CODE:
	screen->GetLeft(&aLeft);
	RETVAL = aLeft;
    OUTPUT:
	RETVAL

## GetWidth(PRInt32 *aWidth)
PRInt32
moz_dom_GetWidth (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aWidth;
    CODE:
	screen->GetWidth(&aWidth);
	RETVAL = aWidth;
    OUTPUT:
	RETVAL

## GetHeight(PRInt32 *aHeight)
PRInt32
moz_dom_GetHeight (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aHeight;
    CODE:
	screen->GetHeight(&aHeight);
	RETVAL = aHeight;
    OUTPUT:
	RETVAL

## GetPixelDepth(PRInt32 *aPixelDepth)
PRInt32
moz_dom_GetPixelDepth (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aPixelDepth;
    CODE:
	screen->GetPixelDepth(&aPixelDepth);
	RETVAL = aPixelDepth;
    OUTPUT:
	RETVAL

## GetColorDepth(PRInt32 *aColorDepth)
PRInt32
moz_dom_GetColorDepth (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aColorDepth;
    CODE:
	screen->GetColorDepth(&aColorDepth);
	RETVAL = aColorDepth;
    OUTPUT:
	RETVAL

## GetAvailWidth(PRInt32 *aAvailWidth)
PRInt32
moz_dom_GetAvailWidth (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aAvailWidth;
    CODE:
	screen->GetAvailWidth(&aAvailWidth);
	RETVAL = aAvailWidth;
    OUTPUT:
	RETVAL

## GetAvailHeight(PRInt32 *aAvailHeight)
PRInt32
moz_dom_GetAvailHeight (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aAvailHeight;
    CODE:
	screen->GetAvailHeight(&aAvailHeight);
	RETVAL = aAvailHeight;
    OUTPUT:
	RETVAL

## GetAvailLeft(PRInt32 *aAvailLeft)
PRInt32
moz_dom_GetAvailLeft (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aAvailLeft;
    CODE:
	screen->GetAvailLeft(&aAvailLeft);
	RETVAL = aAvailLeft;
    OUTPUT:
	RETVAL

## GetAvailTop(PRInt32 *aAvailTop)
PRInt32
moz_dom_GetAvailTop (screen)
	nsIDOMScreen *screen;
    PREINIT:
	PRInt32 aAvailTop;
    CODE:
	screen->GetAvailTop(&aAvailTop);
	RETVAL = aAvailTop;
    OUTPUT:
	RETVAL
