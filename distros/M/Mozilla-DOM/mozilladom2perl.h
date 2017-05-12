/*
 * Copyright (C) 2005 by Scott Lanning
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
 * $CVSHeader: Mozilla-DOM/mozilladom2perl.h,v 1.18 2007-06-06 21:46:36 slanning Exp $
 */

#ifndef _MOZILLADOM2PERL_H_
#define _MOZILLADOM2PERL_H_


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


/* Procedure to add a new typemap (necessary if an XSUB returns
   something like nsIDOMEvent *)
   Add:
   0. header include below
   1. declaration macro below
   2. definition macro to the top of xs/DOM.xs
   3. MODULE section to xs/DOM.xs
      (e.g. Mozilla::DOM::Event for nsIDOMEvent)
   4. add item to Supports::QueryInterface in xs/DOM.xs
   5. T_MOZDOM_GENERIC_WRAPPER line to the TYPEMAP section
      in mozilladom.typemap
   6. entry to doctypes
   7. add package to DOM.pm
 */


/* XXX: would be nice if these includes could be
   put in the macros below - but how do you make
   a literal '#' in a macro, and does an include
   work in one? */

#include "nsEmbedString.h"
#include "nsIID.h"

#include "nsIWebBrowser.h"
#include "nsIWebNavigation.h"
#include "nsIURI.h"
#include "nsISelection.h"
#include "nsISupports.h"

#include "nsIDOMAbstractView.h"
#include "nsIDOMAttr.h"
#include "nsIDOMCharacterData.h"
#include "nsIDOMCDATASection.h"
#include "nsIDOMComment.h"
#include "nsIDOMDOMImplementation.h"
#include "nsIDOMDocument.h"
#include "nsIDOMNSDocument.h"
#include "nsIDOMDocumentEvent.h"
#include "nsIDOMDocumentFragment.h"
#include "nsIDOMDocumentRange.h"
#include "nsIDOMDocumentType.h"
#include "nsIDOMDocumentView.h"
#include "nsIDOMElement.h"
#include "nsIDOMEntity.h"
#include "nsIDOMEntityReference.h"
#include "nsIDOMNSEvent.h"
#include "nsIDOMEvent.h"
#include "nsIDOMEventListener.h"
#include "nsIDOMEventTarget.h"
#include "nsIDOMDOMException.h"
#include "nsIDOMKeyEvent.h"
#include "nsIDOMMouseEvent.h"
#include "nsIDOMMutationEvent.h"
#include "nsIDOMNamedNodeMap.h"
#include "nsIDOMNodeList.h"
#include "nsIDOMNotation.h"
#include "nsIDOMProcessingInstruction.h"
#include "nsIDOMRange.h"
#include "nsIDOMNSRange.h"
#include "nsIDOMText.h"
#include "nsIDOMUIEvent.h"
#include "nsIDOMNSUIEvent.h"
#include "nsIDOMWindow.h"
#include "nsIDOMWindow2.h"
#include "nsIDOMWindowInternal.h"
#include "nsIDOMWindowCollection.h"
#include "nsIDOMHistory.h"
#include "nsIDOMLocation.h"
#include "nsIDOMNavigator.h"
#include "nsIDOMScreen.h"

#include "nsIDOMHTMLAreaElement.h"
#include "nsIDOMNSHTMLAreaElement.h"
#include "nsIDOMHTMLAnchorElement.h"
#include "nsIDOMNSHTMLAnchorElement.h"
#include "nsIDOMHTMLAppletElement.h"
#include "nsIDOMHTMLBRElement.h"
#include "nsIDOMHTMLBaseElement.h"
#include "nsIDOMHTMLBaseFontElement.h"
#include "nsIDOMHTMLBodyElement.h"
#include "nsIDOMHTMLButtonElement.h"
#include "nsIDOMNSHTMLButtonElement.h"
#include "nsIDOMHTMLCollection.h"
#include "nsIDOMHTMLDListElement.h"
#include "nsIDOMHTMLDirectoryElement.h"
#include "nsIDOMHTMLDivElement.h"
#include "nsIDOMNSHTMLDocument.h"
#include "nsIDOMHTMLElement.h"
#include "nsIDOMNSHTMLElement.h"
#include "nsIDOMHTMLEmbedElement.h"
#include "nsIDOMHTMLFieldSetElement.h"
#include "nsIDOMHTMLFontElement.h"
#include "nsIDOMHTMLFormElement.h"
#include "nsIDOMNSHTMLFormElement.h"
#include "nsIDOMHTMLFrameElement.h"
#include "nsIDOMNSHTMLFrameElement.h"
#include "nsIDOMHTMLFrameSetElement.h"
#include "nsIDOMHTMLHRElement.h"
#include "nsIDOMNSHTMLHRElement.h"
#include "nsIDOMHTMLHeadElement.h"
#include "nsIDOMHTMLHeadingElement.h"
#include "nsIDOMHTMLHtmlElement.h"
#include "nsIDOMHTMLIFrameElement.h"
#include "nsIDOMHTMLImageElement.h"
#include "nsIDOMNSHTMLImageElement.h"
#include "nsIDOMHTMLInputElement.h"
#include "nsIDOMNSHTMLInputElement.h"
#include "nsIDOMHTMLIsIndexElement.h"
#include "nsIDOMHTMLLIElement.h"
#include "nsIDOMHTMLLabelElement.h"
#include "nsIDOMHTMLLegendElement.h"
#include "nsIDOMHTMLLinkElement.h"
#include "nsIDOMHTMLMapElement.h"
#include "nsIDOMHTMLMenuElement.h"
#include "nsIDOMHTMLMetaElement.h"
#include "nsIDOMHTMLModElement.h"
#include "nsIDOMHTMLOListElement.h"
#include "nsIDOMHTMLObjectElement.h"
#include "nsIDOMHTMLOptGroupElement.h"
#include "nsIDOMHTMLOptionElement.h"
#include "nsIDOMNSHTMLOptionElement.h"
#include "nsIDOMHTMLOptionsCollection.h"
#include "nsIDOMHTMLParagraphElement.h"
#include "nsIDOMHTMLParamElement.h"
#include "nsIDOMHTMLPreElement.h"
#include "nsIDOMHTMLQuoteElement.h"
#include "nsIDOMHTMLScriptElement.h"
#include "nsIDOMHTMLSelectElement.h"
#include "nsIDOMNSHTMLSelectElement.h"
#include "nsIDOMHTMLStyleElement.h"
#include "nsIDOMHTMLTableCaptionElem.h"   /* grr */
#include "nsIDOMHTMLTableCellElement.h"
#include "nsIDOMHTMLTableColElement.h"
#include "nsIDOMHTMLTableElement.h"
#include "nsIDOMHTMLTableRowElement.h"
#include "nsIDOMHTMLTableSectionElem.h"   /* grr */
#include "nsIDOMHTMLTextAreaElement.h"
#include "nsIDOMNSHTMLTextAreaElement.h"
#include "nsIDOMHTMLTitleElement.h"
#include "nsIDOMHTMLUListElement.h"


#define MOZDOM_DECL_I_TYPEMAPPERS(name)                             \
SV * newSVnsI##name (nsI##name *);                                  \
nsI##name * SvnsI##name (SV *);

#define MOZDOM_DEF_I_TYPEMAPPERS(name)                              \
SV * newSVnsI##name (nsI##name * name) {                            \
	SV *sv = newSV(0);                                          \
	return sv_setref_pv (sv, "Mozilla::DOM::" #name, name);     \
}                                                                   \
nsI##name * SvnsI##name (SV * name) {                               \
	return INT2PTR (nsI##name *, SvIV(SvRV(name)));             \
}

#define MOZDOM_DECL_DOM_TYPEMAPPERS(name)                           \
SV * newSVnsIDOM##name (nsIDOM##name *);                            \
nsIDOM##name * SvnsIDOM##name (SV *);

#define MOZDOM_DEF_DOM_TYPEMAPPERS(name)                            \
SV * newSVnsIDOM##name (nsIDOM##name * name) {                      \
	SV *sv = newSV(0);                                          \
	return sv_setref_pv (sv, "Mozilla::DOM::" #name, name);     \
}                                                                   \
nsIDOM##name * SvnsIDOM##name (SV * name) {                         \
	return INT2PTR (nsIDOM##name *, SvIV(SvRV(name)));          \
}


MOZDOM_DECL_I_TYPEMAPPERS(WebBrowser)
MOZDOM_DECL_I_TYPEMAPPERS(WebNavigation)
MOZDOM_DECL_I_TYPEMAPPERS(URI)
MOZDOM_DECL_I_TYPEMAPPERS(Selection)
MOZDOM_DECL_I_TYPEMAPPERS(Supports)

MOZDOM_DECL_DOM_TYPEMAPPERS(AbstractView)
MOZDOM_DECL_DOM_TYPEMAPPERS(DocumentView)
MOZDOM_DECL_DOM_TYPEMAPPERS(Event)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSEvent)
MOZDOM_DECL_DOM_TYPEMAPPERS(UIEvent)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSUIEvent)
MOZDOM_DECL_DOM_TYPEMAPPERS(DocumentEvent)
MOZDOM_DECL_DOM_TYPEMAPPERS(MutationEvent)
MOZDOM_DECL_DOM_TYPEMAPPERS(KeyEvent)
MOZDOM_DECL_DOM_TYPEMAPPERS(MouseEvent)
MOZDOM_DECL_DOM_TYPEMAPPERS(EventTarget)
MOZDOM_DECL_DOM_TYPEMAPPERS(EventListener)
MOZDOM_DECL_DOM_TYPEMAPPERS(Window)
MOZDOM_DECL_DOM_TYPEMAPPERS(Window2)
MOZDOM_DECL_DOM_TYPEMAPPERS(WindowInternal)
MOZDOM_DECL_DOM_TYPEMAPPERS(WindowCollection)
MOZDOM_DECL_DOM_TYPEMAPPERS(Document)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSDocument)
MOZDOM_DECL_DOM_TYPEMAPPERS(DOMException)
MOZDOM_DECL_DOM_TYPEMAPPERS(DocumentFragment)
MOZDOM_DECL_DOM_TYPEMAPPERS(DocumentRange)
MOZDOM_DECL_DOM_TYPEMAPPERS(DocumentType)
MOZDOM_DECL_DOM_TYPEMAPPERS(Node)
MOZDOM_DECL_DOM_TYPEMAPPERS(NodeList)
MOZDOM_DECL_DOM_TYPEMAPPERS(NamedNodeMap)
MOZDOM_DECL_DOM_TYPEMAPPERS(Element)
MOZDOM_DECL_DOM_TYPEMAPPERS(Entity)
MOZDOM_DECL_DOM_TYPEMAPPERS(EntityReference)
MOZDOM_DECL_DOM_TYPEMAPPERS(Attr)
MOZDOM_DECL_DOM_TYPEMAPPERS(Notation)
MOZDOM_DECL_DOM_TYPEMAPPERS(ProcessingInstruction)
MOZDOM_DECL_DOM_TYPEMAPPERS(CDATASection)
MOZDOM_DECL_DOM_TYPEMAPPERS(Comment)
MOZDOM_DECL_DOM_TYPEMAPPERS(CharacterData)
MOZDOM_DECL_DOM_TYPEMAPPERS(Text)
MOZDOM_DECL_DOM_TYPEMAPPERS(DOMImplementation)
MOZDOM_DECL_DOM_TYPEMAPPERS(Range)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSRange)
MOZDOM_DECL_DOM_TYPEMAPPERS(History)
MOZDOM_DECL_DOM_TYPEMAPPERS(Location)
MOZDOM_DECL_DOM_TYPEMAPPERS(Navigator)
MOZDOM_DECL_DOM_TYPEMAPPERS(Screen)

MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLAreaElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLAreaElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLAnchorElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLAnchorElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLAppletElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLBRElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLBaseElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLBaseFontElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLBodyElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLButtonElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLButtonElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLCollection)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLDListElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLDirectoryElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLDivElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLDocument)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLEmbedElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLFieldSetElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLFontElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLFormElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLFormElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLFrameElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLFrameElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLFrameSetElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLHRElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLHRElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLHeadElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLHeadingElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLHtmlElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLIFrameElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLImageElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLImageElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLInputElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLInputElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLIsIndexElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLLIElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLLabelElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLLegendElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLLinkElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLMapElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLMenuElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLMetaElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLModElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLOListElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLObjectElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLOptGroupElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLOptionElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLOptionElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLOptionsCollection)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLParagraphElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLParamElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLPreElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLQuoteElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLScriptElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLSelectElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLSelectElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLStyleElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTableCaptionElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTableCellElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTableColElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTableElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTableRowElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTableSectionElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTextAreaElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(NSHTMLTextAreaElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLTitleElement)
MOZDOM_DECL_DOM_TYPEMAPPERS(HTMLUListElement)


#ifdef MDEXP_EVENT_LISTENER

class MozDomEventListener : public nsIDOMEventListener
{
public:
	NS_DECL_ISUPPORTS
	NS_DECL_NSIDOMEVENTLISTENER

	MozDomEventListener();
	MozDomEventListener(SV *handler);
	~MozDomEventListener();

private:
	SV *mHandler;
};

#endif


#include "mozilladom2perl-version.h"
/* #include "mozilladom2perl-autogen.h" */

#endif /* _MOZILLADOM2PERL_H_ */
