#include <libxwrite.h>
#include <string.h>
#include "config.h"

/** The actual definition of struct XWrite_.
 *
 * \internal
 */
struct XWrite_ {
    /** Indentation width.
     */
    guint indentation;

    /** Current level of nested elements.
     */
    guint level;

    /** Is the current element in incomplete state?
     */
    gboolean element_is_incomplete;

    /** Has the current element any child nodes other than attributes?
     */
    gboolean element_has_children;

    /** Was the last node a text?
     */
    gboolean last_node_was_text;

    /** The resulting XML string.
     */
    GString* result;
};

static gboolean xwrite_is_escape_needed(const gchar* str) {
    const gchar* needle = str;

    for (; G_LIKELY(*needle != '\0'); needle++) {
	switch (*needle) {
	case '<':
	case '>':
	case '&':
	case '"':
	    return TRUE;
	}
    }

    return FALSE;
}

static inline void xwrite_copy(XWrite* this, const gchar* str) {
    g_string_append(this->result, str);
}

static inline void xwrite_escape(XWrite* this, const gchar* str) {
    if (G_UNLIKELY(xwrite_is_escape_needed(str))) {
	gchar* escaped = g_markup_escape_text(str, -1);
	g_string_append(this->result, escaped);
	g_free(escaped);
    }
    else {
	xwrite_copy(this, str);
    }
}

static inline void xwrite_newline(XWrite* this) {
    xwrite_copy(this, "\n");
}

static inline void xwrite_indent(XWrite* this) {
    if (G_LIKELY((this->indentation > 0 || this->level == 0) &&
		 this->last_node_was_text == FALSE)) {
	gint i;

	xwrite_newline(this);

	for (i = 0; i < this->indentation * this->level; i++) {
	    g_string_append_c(this->result, ' ');
	}
    }
}

static inline void xwrite_finish_element(XWrite* this) {
    if (G_UNLIKELY(this->element_is_incomplete)) {
	xwrite_copy(this, ">");
	this->element_is_incomplete = FALSE;
    }
}

XWrite* xwrite_new(guint indent) {
    XWrite* this;

    this = g_new(XWrite, 1);
    this->indentation           = indent;
    this->level                 = 0;
    this->element_is_incomplete = FALSE;
    this->element_has_children  = FALSE;
    this->last_node_was_text    = FALSE;
    this->result                = g_string_new("");

    return this;
}

void xwrite_free(XWrite* this) {
    g_string_free(this->result, TRUE);
    g_free(this);
}

gchar* xwrite_get_result(const XWrite* this) {
    return g_strdup(this->result->str);
}

void xwrite_start_document(XWrite* this,
			   const gchar* xml_version,
			   const gchar* xml_encoding,
			   const gchar* xml_standalone) {

    xwrite_copy(this, "<?xml version=\"");
    if (G_LIKELY(xml_version == NULL)) {
	xwrite_copy(this, "1.0");
    }
    else {
	xwrite_escape(this, xml_version);
    }
    xwrite_copy(this, "\"");

    if (G_UNLIKELY(xml_encoding != NULL)) {
	/* FIXME: charset conversion is not supported yet */
	g_assert(g_ascii_strcasecmp(xml_encoding, "UTF-8") == 0);

	xwrite_copy(this, " encoding=\"");
	xwrite_escape(this, xml_encoding);
	xwrite_copy(this, "\"");
    }

    if (G_UNLIKELY(xml_standalone != NULL)) {
	xwrite_copy(this, " standalone=\"");
	xwrite_escape(this, xml_standalone);
	xwrite_copy(this, "\"");
    }

    xwrite_copy(this, "?>");
}

void xwrite_end_document(XWrite* this) {
    g_assert(this->level == 0);
    xwrite_newline(this);
}

void xwrite_write_DTD(XWrite* this,
		      const gchar* name,
		      const gchar* pubid,
		      const gchar* sysid,
		      const gchar* subset) {
    g_assert(this->level == 0);

    xwrite_indent(this);
    xwrite_copy(this, "<!DOCTYPE ");
    xwrite_copy(this, name);

    if (G_LIKELY(pubid != NULL)) {
	g_assert(sysid != NULL);

	xwrite_copy(this, this->indentation ? "\n" : " ");
	xwrite_copy(this, "PUBLIC \"");
	xwrite_copy(this, pubid);
	xwrite_copy(this, "\"");
    }

    if (G_LIKELY(sysid != NULL)) {
	if (G_UNLIKELY(pubid == NULL)) {
	    xwrite_copy(this, this->indentation ? "\n" : " ");
	    xwrite_copy(this, "SYSTEM ");
	}
	else {
	    xwrite_copy(this, this->indentation ? "\n       " : " ");
	}

	xwrite_copy(this, "\"");
	xwrite_copy(this, sysid);
	xwrite_copy(this, "\"");
    }

    if (G_UNLIKELY(subset != NULL && *subset != '\0')) {
	xwrite_copy(this, " ");
	xwrite_copy(this, subset);
    }
    xwrite_copy(this, ">");
}

void xwrite_write_PI(XWrite* this, const gchar* target, const gchar* content) {
    g_assert(this->level == 0);

    xwrite_indent(this);
    xwrite_copy(this, "<?");
    xwrite_copy(this, target);

    if (G_LIKELY(content != NULL && *content != '\0')) {
	xwrite_copy(this, " ");
	xwrite_copy(this, content);
    }

    xwrite_copy(this, "?>");
}

void xwrite_write_comment(XWrite* this, const gchar* comment) {

#if HAVE_STRSTR
    g_assert(strstr(comment, "--") == NULL);
#endif

    xwrite_finish_element(this);
    xwrite_indent(this);
    xwrite_copy(this, "<!-- ");
    xwrite_copy(this, comment);
    xwrite_copy(this, " -->");

    this->element_has_children = TRUE;
    this->last_node_was_text   = FALSE;
}

void xwrite_start_element(XWrite* this, const gchar* qname) {
    xwrite_finish_element(this);

    xwrite_indent(this);
    xwrite_copy(this, "<");
    xwrite_copy(this, qname);

    this->level++;
    this->element_is_incomplete = TRUE;
    this->element_has_children  = FALSE;
    this->last_node_was_text    = FALSE;
}

void xwrite_end_element(XWrite* this, const gchar* qname) {
    g_assert(this->level > 0);
    
    this->level--;

    if (G_LIKELY(this->element_has_children)) {
	xwrite_finish_element(this);
	xwrite_indent(this);
	xwrite_copy(this, "</");
	xwrite_copy(this, qname);
	xwrite_copy(this, ">");
    }
    else {
	this->element_is_incomplete = FALSE;
	xwrite_copy(this, "/>");
    }

    this->last_node_was_text = FALSE;

    if (G_LIKELY(this->level > 0)) {
	this->element_has_children = TRUE;
    }
}

void xwrite_add_attribute(XWrite* this, const gchar* qname, const gchar* value) {
    g_assert(this->element_is_incomplete);

    xwrite_copy(this, " ");
    xwrite_copy(this, qname);
    xwrite_copy(this, "=\"");
    xwrite_escape(this, value);
    xwrite_copy(this, "\"");
}

void xwrite_add_text(XWrite* this, const gchar* str) {
    xwrite_finish_element(this);
    xwrite_escape(this, str);
    
    this->element_has_children = TRUE;
    this->last_node_was_text   = TRUE;
}

void xwrite_add_CDATA(XWrite* this, const gchar* cdata) {

#if HAVE_STRSTR
    g_assert(strstr(cdata, "]]>") == NULL);
#endif

    xwrite_finish_element(this);
    xwrite_copy(this, "<![CDATA[");
    xwrite_copy(this, cdata);
    xwrite_copy(this, "]]>");

    this->element_has_children = TRUE;
    this->last_node_was_text   = TRUE;
}

void xwrite_add_base64(XWrite* this, const gchar* str, gsize len) {
    gchar* encoded = g_base64_encode(str, len);
    
    xwrite_add_text(this, encoded);
    g_free(encoded);
}
