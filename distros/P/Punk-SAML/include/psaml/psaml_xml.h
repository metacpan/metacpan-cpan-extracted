#ifndef PSAML_XML_H
#define PSAML_XML_H

/* The XML escape for the three documents this dist writes, and the
 * finders over an frx tree by SAML namespace and local name.
 *
 * There is no writer here and there is not going to be one. This dist
 * emits an AuthnRequest, a LogoutRequest and its own SP metadata, all
 * three assembled as strings the way Punk-Feed assembles a feed, and a
 * general serialiser would be more code than the plugin. What that
 * needs from XML is one escape, and the escape is below.
 *
 * READING is the opposite: reading is what a signature is checked over,
 * and none of it happens here. It happens in File::Raw::XML, through
 * frx_abi.h, and the finders below are the only shape in which this dist
 * asks about a tree. Two finders by namespace and local name are the
 * whole of what SAML needs, which is the reason there is no XPath in
 * File::Raw::XML: an XPath transform is the classic signature-bypass
 * surface in XML-DSig, and the way not to have that surface is not to
 * have the language. */

#include "psaml_abi.h"

/* The namespaces, spelled once. A SAML document that uses a different
 * prefix for these is the normal case, not the exception, so nothing in
 * this dist may ever match on a prefix. */
#define PSAML_NS_PROTOCOL  "urn:oasis:names:tc:SAML:2.0:protocol"
#define PSAML_NS_ASSERTION "urn:oasis:names:tc:SAML:2.0:assertion"
#define PSAML_NS_METADATA  "urn:oasis:names:tc:SAML:2.0:metadata"
#define PSAML_NS_DSIG      "http://www.w3.org/2000/09/xmldsig#"
#define PSAML_NS_XENC      "http://www.w3.org/2001/04/xmlenc#"

/* ---- the escape ------------------------------------------------------ */

/* Worst case is six bytes out per byte in (`&quot;` and `&apos;`). */
PERL_STATIC_INLINE STRLEN psaml_xml_escaped_max(STRLEN n) {
  return n * 6;
}

/* One escaper for both text and attribute values.
 *
 * Separate escapers are what a canonicaliser needs, because c14n
 * escapes different sets in the two positions and the signature is over
 * the result. Nothing here is canonicalised: these are documents we
 * write and someone else reads, so the safe move is the opposite one,
 * escaping the union everywhere. `>` is escaped although only `]]>`
 * requires it, and quotes are escaped although text does not require
 * them, because an attribute value and a text node then cannot be got
 * wrong by using the wrong one. */
PERL_STATIC_INLINE STRLEN psaml_xml_escape(char *out, const char *in, STRLEN n) {
  char  *o = out;
  STRLEN i;
  for (i = 0; i < n; i++) {
    unsigned char c = (unsigned char)in[i];
    switch (c) {
      case '&':  memcpy(o, "&amp;",  5); o += 5; break;
      case '<':  memcpy(o, "&lt;",   4); o += 4; break;
      case '>':  memcpy(o, "&gt;",   4); o += 4; break;
      case '"':  memcpy(o, "&quot;", 6); o += 6; break;
      case '\'': memcpy(o, "&apos;", 6); o += 6; break;
      default:   *o++ = (char)c;                 break;
    }
  }
  return (STRLEN)(o - out);
}

/* ---- the finders ----------------------------------------------------- */

/* A direct child by namespace and local name, or NULL. `after` is the
 * previous match, so a caller iterating siblings allocates nothing;
 * pass NULL to start. */
PERL_STATIC_INLINE const frx_node *psaml_child(pTHX_ const frx_node *n, const char *ns,
                                   const char *local, const frx_node *after) {
  if (!n) return NULL;
  return psaml_frx(aTHX)->find(n, ns, local, after);
}

/* Exactly one direct child, or NULL if there are none or more than one.
 *
 * "More than one" is a refusal rather than a first-match, and that is
 * the whole point of this function existing next to psaml_child. A
 * Response with two Assertions, or an Assertion with two Subjects, is
 * the shape a wrapping attack takes: the verifier is invited to check
 * one and read the other. A caller that wants "the" element gets
 * nothing when the document does not contain exactly one, and phase 6
 * turns that into a named error code. */
PERL_STATIC_INLINE const frx_node *psaml_only_child(pTHX_ const frx_node *n,
                                        const char *ns, const char *local) {
  const frx_abi  *F = psaml_frx(aTHX);
  const frx_node *first, *second;
  if (!n) return NULL;
  first = F->find(n, ns, local, NULL);
  if (!first) return NULL;
  second = F->find(n, ns, local, first);
  return second ? NULL : first;
}

/* An attribute value by local name in any namespace, or NULL. SAML's
 * own attributes (ID, Version, Destination, InResponseTo) are all
 * unprefixed and unnamespaced, which is what "any namespace" means
 * here in practice. */
PERL_STATIC_INLINE const char *psaml_attr(pTHX_ const frx_node *n, const char *local,
                              STRLEN *len) {
  if (!n) return NULL;
  return psaml_frx(aTHX)->attr_value(n, NULL, local, len);
}

#endif /* PSAML_XML_H */
