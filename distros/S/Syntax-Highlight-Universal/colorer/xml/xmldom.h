#ifndef _COLORER_XMLDOM_H_
#define _COLORER_XMLDOM_H_

#include<common/Vector.h>
#include<common/Hashtable.h>
#include<common/io/InputSource.h>

/**
 * @addtogroup xml XMLDOM Parser
 * Simple DOM-based XML Parser.
 * Please refer to the w3c DOM API specification
 * for API review.
 */

class Node;
class Document;
class Element;
class ProcessingInstruction;
class CharacterData;
class Comment;
class Text;

/**
 * Basic XML Parser exception class
 * Contains information about exception and position of the
 * error in the text.
 */
class ParseException : public Exception
{
public:
  ParseException(const String &msg)
  {
    message->append(msg);
  }

  ParseException(const String &msg, int line, int pos)
  {
    message->append(DString("ParseException: ")) + msg;
    if (line > -1)
    {
      message->append(DString(" at line: ")) + SString(line);
    }
    if (pos > -1)
    {
      message->append(DString(", pos: ")) + SString(pos);
    }
  };
protected:
};

/**
 * Entity resolver, used to resolve addresses of the external entities
 */
class EntityResolver
{
public:
  virtual InputSource *resolveEntity(const String *publicId, const String *systemId) = 0;
};

/**
 * Default entity resolver class, uses InputSource object rules
 * to resolve relative addresses of the entities.
 */
class DefaultEntityResolver : public EntityResolver
{
public:
  DefaultEntityResolver(InputSource *_is) : is(_is){};
  InputSource *resolveEntity(const String *publicId, const String *systemId){
    return is->createRelative(systemId);
  }
private:
  InputSource *is;
};

/**
 * Document factory, used to build xml document tree from input stream.
 * Contains parser settings, can be used to generate multiple DOM trees.
 * Should not be used simultaneously from several threads.
 */
class DocumentBuilder
{
public:
  DocumentBuilder() : ignoreComments(true), whitespace(true),
           er(null), inputSource(null) {}

  /**
   * Setups this builder to ignore and not to include in DOM tree
   * XML comments
   */
  void setIgnoringComments(bool _ignoreComments){
    ignoreComments = _ignoreComments;
  }
  /**
   * Returns current Ignoring Comments status.
   */
  inline bool isIgnoringComments(){
    return ignoreComments;
  }
  /**
   * Ignores empty element's text content (content with only
   * spaces, tabs, CR/LF).
   */
  void setIgnoringElementContentWhitespace(bool _whitespace)
  {
    whitespace = _whitespace;
  }
  /**
   * Retrieves whitespace ignore state.
   */
  inline bool isIgnoringElementContentWhitespace()
  {
    return whitespace;
  }

  /**
   * Changes entity resolver, used while parsing external entity references.
   */
  void setEntityResolver(EntityResolver *_er){
    er = er;
  }

  /**
   * Allocates new document object.
   */
  Document *newDocument();

  /**
   * Parses input stream and creates DOM tree.
   */
  Document *parse(InputSource *is, const char *codepage = 0);

  /**
   * Parses input bytes in specified encoding and creates DOM tree.
   */
  Document *parse(const byte *bytes, int length, const char *codepage = 0);

  /**
   * Deletes all DOM tree structure.
   */
  void free(Document *doc);

protected:
  bool ignoreComments;
  bool whitespace;
  Hashtable<const String*> entitiesHash;
  Hashtable<const String*> extEntitiesHash;
private:
  int ppos, opos;
  DString src;
  String *src_overflow;
  Document *doc;
  EntityResolver *er;
  InputSource *inputSource;

  static bool getXMLNumber(const String &str, int *res);

  void consumeDocument();
  void consumeXmlDecl();
  void consumeDTD();
  bool isElement();
  void consumeElement(Node *root);
  void consumeContent(Node *root);

  void appendToLastTextNode(Node *root, String *stext);
  bool isCDataSection();
  void consumeCDataSection(Node *root);
  void consumeText(Node *root);
  bool isCharRef();
  wchar consumeCharRef();
  bool isEntityRef();
  String *consumeEntityRef(bool useExtEnt);

  void consumeSpaces(int mins = 0);
  String *consumeQoutedValue();
  String *consumeAttributeValue();
  String *consumeNCName();
  String *consumeName();
  bool isComment();
  void consumeComment(Node *root);
  bool isPI();
  void consumePI(Node *root);
  void consumeMisc(Node *root);
  void consume(String &s);
  void consume(char *s, int len = -1);
  void incDocumentLine();
  void setDocumentPos(int pos);
  void incDocumentPos();

  inline int peek(int offset = 0){
    if (src_overflow){
      if (opos+offset < src_overflow->length()){
        return (*src_overflow)[opos+offset];
      }else{
        offset -= (src_overflow->length() - opos);
      }
    }
    if (ppos+offset >= src.length()) return -1;
    return src[ppos+offset];
  }

  inline wchar get(){
    if (src_overflow){
      if (opos == src_overflow->length()){
        delete src_overflow;
        src_overflow = null;
        opos = 0;
      }else{
        return (*src_overflow)[opos++];
      }
    }
    if (ppos >= src.length()){
      throw ParseException(DString("End of stream is reached"));
    }
    if (src[ppos] == '\n'){
      incDocumentLine();
      setDocumentPos(0);
    }
    incDocumentPos();
    return src[ppos++];
  }

  Node *next;
};

/**
 * Abstract DOM tree node.
 */
class Node
{
public:
  enum
  {
    COMMENT_NODE = 0,
    DOCUMENT_NODE = 1,
    ELEMENT_NODE = 2,
    PROCESSING_INSTRUCTION_NODE = 3,
    TEXT_NODE = 4
  };

  bool hasChildNodes()
  {
    return firstChild != null;
  }

  Node *getFirstChild()
  {
    return firstChild;
  }

  Node *getLastChild()
  {
    if (firstChild == null){
      return null;
    }else{
      return firstChild->prev;
    }
  }

  Node *getParent()
  {
    return parent;
  }

  Node *getNextSibling()
  {
    if (parent == null) return null;
    return next != parent->firstChild ? next : null;
  }

  Node *getPrevSibling()
  {
    if (parent == null) return null;
    return this != parent->firstChild ? prev : null;
  }

  const String *getNodeName()
  {
    return name;
  }

  virtual const Vector<const String*> *getAttributes()
  {
    return null;
  };

  short getNodeType()
  {
    return type;
  }

  Document *getOwnerDocument()
  {
    return ownerDocument;
  }

  virtual Node *appendChild(Node *newChild);

  //virtual Node *cloneNode(bool deep) = 0;

  virtual ~Node()
  {
    delete name;
  };
protected:
  int type;
  Node *next, *prev;
  Node *parent, *firstChild;
  const String *name;
  Document *ownerDocument;
  Node(int _type, const String *_name): type(_type), name(_name),
       next(null), prev(null), parent(null), firstChild(null) {};
  friend class DocumentBuilder;
};


/**
 * Document node.
 */
class Document : public Node
{
public:
  Element *getDocumentElement()
  {
    return documentElement;
  }

  Node *appendChild(Node *newChild){
    if (newChild->getNodeType() == Node::ELEMENT_NODE)
    {
      if (documentElement != null)
      {
        throw ParseException(DString("Invalid document root content"), line, pos);
      }
      documentElement = (Element*)newChild;
    };
    Node::appendChild(newChild);
    return newChild;
  }

  Element *createElement(const String *tagName);
  Text *createTextNode(const String *data);
  Comment *createComment(const String *data);
  ProcessingInstruction *createProcessingInstruction(const String *target, const String *data);

protected:
  int line, pos;
  Element *documentElement;
  Document() : Node(Node::DOCUMENT_NODE, new DString("#document")), documentElement(null) {};
  friend class DocumentBuilder;
};


/**
 * Element node.
 */
class Element : public Node
{
public:

  const String *getAttribute(const String&name)
  {
    return attributesHash.get(&name);
  }
  const String *getAttribute(const String*name)
  {
    return attributesHash.get(name);
  }

  const Vector<const String*> *getAttributes()
  {
    return &attributes;
  };

  void setAttribute(const String *name, const String *value);

protected:
  // TODO: static tagName index
  Vector<const String*> attributes;
  Hashtable<const String*> attributesHash;

  Element(const String *_tagName): Node(Node::ELEMENT_NODE, _tagName){};

  ~Element()
  {
    for(int idx = 0; idx < attributes.size(); idx++)
    {
      delete attributes.elementAt(idx);
    }
    for (const String* st = attributesHash.enumerate(); st != null; st = attributesHash.next())
    {
      delete st;
    }
  }

  friend class Document;
};

/**
 * Processing Instruction node.
 */
class ProcessingInstruction : public Node
{
public:
  const String *getData()
  {
    return data;
  }

  const String *getTarget()
  {
    return target;
  }

protected:

  const String *data;
  const String *target;

  ProcessingInstruction(const String *_target, const String *_data):
        Node(Node::PROCESSING_INSTRUCTION_NODE, new DString("#pi")),
        target(_target), data(_data) {}

  ~ProcessingInstruction()
  {
    delete data;
    delete target;
  };

  friend class Document;
};

/**
 * Abstract Text Data section node.
 */
class CharacterData : public Node
{
public:
  const String *getData()
  {
    return data;
  }

  int getLength()
  {
    return data->length();
  }

protected:

  const String *data;

  CharacterData(int type, const String *_data): Node(type, new DString("#cdata")), data(_data) {};
  ~CharacterData(){ delete data; };
  friend class Document;
};

/**
 * XML Comment node.
 */
class Comment : public CharacterData
{
public:
protected:
  Comment(const String *data): CharacterData(Node::COMMENT_NODE, data){};
  friend class Document;
};

/**
 * XML Text / CDATA node.
 */
class Text : public CharacterData
{
public:
protected:
  Text(const String *data): CharacterData(Node::TEXT_NODE, data){};
  friend class Document;
};

#endif
