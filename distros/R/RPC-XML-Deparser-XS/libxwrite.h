#ifndef LBIXWRITE_H_INCLUDED
#define LBIXWRITE_H_INCLUDED
#include <glib.h>

/**
 * \mainpage
 * This is a simple and fast library to write XML documents.
 */

/**
 * \file  libxwrite.h
 * \brief An interface to libxwrite the simple fast XML writer.
 */

/**
 * \brief An opaque type to represent libxwrite context.
 */
typedef struct XWrite_ XWrite;

/**
 * \brief Create a new libxwrite context.
 *
 * The context should be destroyed with xwrite_free().
 *
 * \param indent The width of indentation.
 * \return The context.
 */
XWrite* xwrite_new(guint indent);

/**
 * \brief Destroy a libxwrite context.
 */
void xwrite_free(XWrite* this);

/**
 * \brief Return an XML string which has been generated so far.
 * 
 * \return The string. You have to destroy this string with g_free()
 *         later.
 */
gchar* xwrite_get_result(const XWrite* this);

/**
 * \brief Declare the beginning of XML stream.
 *
 * \param this The context.
 * \param xml_version XML version string. (optional; defaults to "1.0")
 * \param xml_encoding XML encoding type. Note that no encodings other
 *                     than "UTF-8" are currently
 *                     supported. (optional)
 * \param xml_standalone "yes" or "no". (optional)
 */
void xwrite_start_document(XWrite* this,
			   const gchar* xml_version,
			   const gchar* xml_encoding,
			   const gchar* xml_standalone);

/**
 * \brief Declare the end of XML stream.
 */
void xwrite_end_document(XWrite* this);

/**
 * \brief Declare a DOCTYPE.
 *
 * \param this The context.
 * \param name The name of root element.
 * \param pubid PUBLIC ID (optional)
 * \param sysid SYSTEM ID (optional only when pubid == NULL)
 * \param subset The subset. (optional)
 */
void xwrite_write_DTD(XWrite* this,
		      const gchar* name,
		      const gchar* pubid,
		      const gchar* sysid,
		      const gchar* subset);

/**
 * \brief Declare a processing instruction.
 *
 * \param this The context.
 * \param target The target of PI.
 * \param content The content of PI. (optional)
 */
void xwrite_write_PI(XWrite* this, const gchar* target, const gchar* content);

/**
 * \brief Declare a comment.
 *
 * \param this The context.
 * \param comment The comment in UTF-8.
 */
void xwrite_write_comment(XWrite* this, const gchar* comment);

/**
 * \brief Open an element.
 *
 * The element will be in incomplete state.
 *
 * \param this The context.
 * \param qname The name of element in UTF-8.
 */
void xwrite_start_element(XWrite* this, const gchar* qname);

/**
 * \brief Close an element.
 * 
 * \param this The context.
 * \param qname The name of element in UTF-8. Beware that it's your
 *              responsible to properly close the innermost element.
 */
void xwrite_end_element(XWrite* this, const gchar* qname);

/**
 * \brief Add an attribute to the innermost open element.
 *
 * This function must be called only while the open element is in
 * incomplete state.
 *
 * \param this The context.
 * \param qname The name of attribute in UTF-8.
 * \param value The value of attribute in UTF-8.
 */
void xwrite_add_attribute(XWrite* this, const gchar* qname, const gchar* value);

/**
 * \brief Add a text to the innermost open element.
 *
 * After the call of this function, the element will be in complete
 * state (i.e. you can't add attributes anymore).
 *
 * \param this The context.
 * \param str The text in UTF-8.
 * \see xwrite_add_base64()
 */
void xwrite_add_text(XWrite* this, const gchar* str);

/**
 * \brief Add an XML CDATA.
 *
 * \param this The context.
 * \param cdata The CDATA in UTF-8.
 */
void xwrite_add_CDATA(XWrite* this, const gchar* cdata);

/**
 * \brief Add a binary to the innermost open element with encoding in
 *        Base64.
 * 
 * \param this The context.
 * \param buf  The beginning address of region to be added.
 * \param len  The length of region.
 * \see xwrite_add_text()
 */
void xwrite_add_base64(XWrite* this, const gchar* buf, gsize len);

#endif
