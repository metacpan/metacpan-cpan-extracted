
#include<stdio.h>

#include<xml/xmldom.h>
#include<unicode/UnicodeTools.h>

Document *DocumentBuilder::parse(InputSource *is, const char *codepage)
{
  const byte *bytes = is->openStream();
  int length = is->length();

  DefaultEntityResolver der(is);
  EntityResolver *old_er = er;
  Document *_doc = null;

  er = &der;
  try{
    _doc = parse(bytes, length, codepage);
  }catch(ParseException &e){
    er = old_er;
    is->closeStream();
    throw e;
  }
  er = old_er;
  is->closeStream();
  return _doc;
}

Document *DocumentBuilder::parse(const byte *bytes, int length, const char *codepage)
{
  entitiesHash.clear();
  extEntitiesHash.clear();

  entitiesHash.put(&DString("amp"), new SString("&"));
  entitiesHash.put(&DString("lt"), new SString("<"));
  entitiesHash.put(&DString("gt"), new SString(">"));
  entitiesHash.put(&DString("quot"), new SString("\""));
  entitiesHash.put(&DString("apos"), new SString("\'"));

  doc = newDocument();
  doc->line = 0;
  doc->pos = 0;

  ppos = opos = 0;
  src = DString(bytes, length, Encodings::getEncodingIndex(codepage));
  src_overflow = null;
  if (src[0] == Encodings::ENC_UTF16_BOM){
    ppos++;
  }

  try{
    consumeDocument();
  }catch(ParseException &e){
    free(doc);
    throw ParseException(*e.getMessage(), doc->line, doc->pos);
  }

  const String* st;
  for (st = entitiesHash.enumerate(); st != null; st = entitiesHash.next()){
    delete st;
  }
  for (st = extEntitiesHash.enumerate(); st != null; st = extEntitiesHash.next()){
    delete st;
  }

  return doc;

}

void DocumentBuilder::consumeDocument(){
  consumeXmlDecl();
  consumeMisc(doc);
  consumeDTD();
  consumeMisc(doc);
  consumeElement(doc);
  consumeMisc(doc);
  if (peek() != -1){
    throw ParseException(DString("Extra markup after the root element"));
  }
}

void DocumentBuilder::consumeXmlDecl(){
  wchar c1 = peek(0);
  wchar c2 = peek(1);
  if (c1 != '<' || c2 != '?') return;

  consume("<?xml", 5);
  consumeSpaces(1);

  consume("version", 7);
  consumeSpaces();
  consume("=", 1);
  consumeSpaces();
  delete consumeQoutedValue();

  consumeSpaces();

  if (peek() == 'e'){
    consume("encoding", 8);
    consumeSpaces();
    consume("=", 1);
    consumeSpaces();
    delete consumeQoutedValue();
  }

  consumeSpaces();

  if (peek() == 's'){
    consume("standalone", 10);
    consumeSpaces();
    consume("=", 1);
    consumeSpaces();
    delete consumeQoutedValue();
  }

  consumeSpaces();
  consume("?>", 2);
}

void DocumentBuilder::consumeDTD(){
  wchar c1 = peek(0);
  wchar c2 = peek(1);
  if (c1 != '<' || c2 != '!') return;

  consume("<!DOCTYPE", 9);
  consumeSpaces(1);
  delete consumeNCName();

  consumeSpaces();
  if (peek() == 'S'){
    consume("SYSTEM", 6);
    consumeSpaces(1);
    delete consumeQoutedValue();
  }else if (peek() == 'P'){
    consume("PUBLIC", 6);
    consumeSpaces(1);
    delete consumeQoutedValue();
    consumeSpaces(1);
    delete consumeQoutedValue();
  }
  consumeSpaces();

  //markup decl
  if (peek() == '['){
    consume("[", 1);

    while(peek() != ']'){
      if (peek(0) == '<' && peek(1) == '!' && peek(2) == 'E'){
        consume("<!ENTITY", 8);
        consumeSpaces(1);
        String *entityName = consumeNCName();
        consumeSpaces(1);
        String *entityValue = null;
        String *extEntityValue = null;
        if (peek() == 'S'){
          consume("SYSTEM", 6);
          consumeSpaces(1);
          extEntityValue = consumeQoutedValue();
        }else if (peek() == 'P'){
          consume("PUBLIC", 6);
          consumeSpaces(1);
          delete consumeQoutedValue();
          consumeSpaces(1);
          extEntityValue = consumeQoutedValue();
        }else{
          entityValue = consumeQoutedValue();
        }
        if (entityValue != null){
          entitiesHash.put(entityName, entityValue);
        }
        if (extEntityValue != null){
          extEntitiesHash.put(entityName, extEntityValue);
        }
        delete entityName;

      }else if (isComment()){
        consumeComment(null);
      }
      get();
    }

    consume("]", 1);
    consumeSpaces();
  }


  consume(">", 1);

}

bool DocumentBuilder::isElement(){
  return (peek(0) == '<' && (Character::isLetter(peek(1)) ||
                             peek(1) == '_' || peek(1) == ':'));
}

void DocumentBuilder::consumeElement(Node *root){

  consume("<", 1);
  String *name = consumeName();
  Element *el = doc->createElement(name);
  root->appendChild(el);

  if (peek(0) == '/' && peek(1) == '>' || peek(0) == '>'){
    // no attributes
  }else{
    consumeSpaces(1);
    while(!(peek(0) == '/' && peek(1) == '>' || peek(0) == '>')){
      consumeSpaces();
      String *aname = consumeName();
      consumeSpaces();
      consume("=", 1);
      consumeSpaces();
      String *aval = consumeAttributeValue();
      consumeSpaces();
      el->setAttribute(aname, aval);
    }
  }

  if (peek(0) == '/' && peek(1) == '>'){
    consume("/>", 1);
  }else{
    consume(">", 1);

    consumeContent(el);

    consume("</", 2);
    consume(*name);
    consumeSpaces();
    consume(">", 1);
  }
}

void DocumentBuilder::consumeContent(Node *root){
  while(peek() != -1){
    consumeText(root);
    if (isElement()){
      consumeElement(root);
      continue;
    }
    if (isComment()){
      consumeComment(root);
      continue;
    }
    if (isCDataSection()){
      consumeCDataSection(root);
      continue;
    }
    if(isPI()){
      consumePI(root);
      continue;
    }
    if (isCharRef()){
      StringBuffer *sb = new StringBuffer(2);
      sb->append(consumeCharRef());
      appendToLastTextNode(root, sb);
      continue;
    }
    if (isEntityRef()){
      String *entext = consumeEntityRef(true);
      appendToLastTextNode(root, entext);
      continue;
    }
    if (peek(0) == '<') break;
  };
}

void DocumentBuilder::appendToLastTextNode(Node *root, String *stext){
  if (stext == null) return;
  Node *last = root->getLastChild();
  Text *text = null;
  if (last == null || last->getNodeType() != Node::TEXT_NODE){
    root->appendChild(doc->createTextNode(stext));
  }else{
    StringBuffer *sb = (StringBuffer*)((Text*)last)->getData();
    sb->append(stext);
    delete stext;
  }
}

bool DocumentBuilder::isCDataSection(){
  return (peek(0) == '<' && peek(1) == '!' && peek(2) == '[');
}

void DocumentBuilder::consumeCDataSection(Node *root){
  StringBuffer *sb = new StringBuffer();
  consume("<![CDATA[", 9);
  while(peek(0) != ']' || peek(1) != ']' || peek(2) != '>'){
    if (peek(0) == -1){
      get();
    }
    sb->append(get());
  }
  appendToLastTextNode(root, sb);
  consume("]]>", 3);
}

void DocumentBuilder::consumeText(Node *root){
  StringBuffer *sb = new StringBuffer(40);
  bool solews = true;
  while(true){
    int c = peek();
    if (c == -1 || c == '<' || c == '&'){
      break;
    }
    get();
    sb->append(c);
    if (isIgnoringElementContentWhitespace() && solews && !Character::isWhitespace(c)){
      solews = false;
    }
  };
  if (isIgnoringElementContentWhitespace() && solews){
    delete sb;
  }else{
    appendToLastTextNode(root, sb);
  };
}

bool DocumentBuilder::isCharRef(){
  return (peek(0) == '&' && peek(1) == '#');
}

wchar DocumentBuilder::consumeCharRef(){
  if (!(peek(0) == '&' && peek(1) == '#')){
    throw ParseException(DString("&# syntax of Character Reference is required"));
  };
  consume("&#", 2);
  StringBuffer *sb = new StringBuffer("#");
  while(peek() != ';'){
    sb->append(get());
  }
  get();

  int c = -1;
  bool b = getXMLNumber(*sb, &c);
  delete sb;
  if (!b || c > 0xFFFF || c < 0){
    throw ParseException(DString("Invalid Character Reference numeric value"));
  }
  return (wchar)c;
}

bool DocumentBuilder::isEntityRef(){
  return (peek(0) == '&' && peek(1) != '#');
}

String *DocumentBuilder::consumeEntityRef(bool useExtEnt){
  consume("&", 1);
  StringBuffer *sb = new StringBuffer(10);
  while(peek() != ';'){
    sb->append(get());
  }
  get();

  const String *ent = entitiesHash.get(sb);
  const String *extEnt = null;
  if (useExtEnt){
    extEnt = extEntitiesHash.get(sb);
  };
  delete sb;

  if (ent == null && extEnt == null){
    throw ParseException(DString("Undefined Entity Reference"));
  }
  if (ent != null){
    return new StringBuffer(ent);
  }
  if (extEnt != null){
    if (er == null) return null;
    InputSource *is = er->resolveEntity(null, extEnt);
    const byte *bytes = is->openStream();
    int length = is->length();
    src_overflow = new SString(DString(bytes, length));
    delete is;
    return null;
  }
  return null;
}

void DocumentBuilder::consumeSpaces(int mins){
  while(Character::isWhitespace(peek())){
    get();
    mins--;
  }
  if (mins > 0){
    throw ParseException(DString("Space is required"));
  }
}

String *DocumentBuilder::consumeAttributeValue(){
  wchar qc = get();
  if (qc != '"' && qc != '\''){
    throw ParseException(DString("Qoute character is required here"));
  }
  StringBuffer *sb = new StringBuffer();
  while(true){
    if (isCharRef()){
      sb->append(consumeCharRef());
      continue;
    }
    if (isEntityRef()){
      String *entext = consumeEntityRef(false);
      if (entext){
        sb->append(entext);
        delete entext;
      }
      continue;
    }
    wchar qc2 = peek();
    if (qc2 == -1){
      delete sb;
    }
    get();
    if (qc2 == qc) return sb;
    sb->append(qc2);
  }
}

String *DocumentBuilder::consumeQoutedValue(){
  wchar qc = get();
  if (qc != '"' && qc != '\''){
    throw ParseException(DString("Qoute character is required here"));
  }
  StringBuffer *sb = new StringBuffer();
  while(true){
    wchar qc2 = peek();
    if (qc2 == -1){
      delete sb;
    }
    get();
    if (qc2 == qc) return sb;
    sb->append(qc2);
  }
}

String *DocumentBuilder::consumeName(){
  StringBuffer *sb = new StringBuffer(10);
  bool start = true;
  while(true){
    int c = peek();
    // first char
    if ((start && !Character::isLetter(c) && c != '_' && c != ':') || c == -1){
      delete sb;
      throw ParseException(DString("Name is required here"));
    }
    start = false;
    if (!Character::isLetterOrDigit(c) &&
         c != '_' && c != ':' && c != '.' && c != '-'){
      break;
    }
    get();
    sb->append(c);
  }
  return sb;
}

String *DocumentBuilder::consumeNCName(){
  StringBuffer *sb = new StringBuffer(10);
  bool start = true;
  while(true){
    int c = peek();
    // first char
    if ((start && !Character::isLetter(c)) || c == -1){
      delete sb;
      throw ParseException(DString("NCName required here"));
    }
    start = false;
    if (!Character::isLetterOrDigit(c) && c != '_' && c != '-'){
      break;
    }
    get();
    sb->append(c);
  }
  return sb;
}

bool DocumentBuilder::isPI(){
  return (peek(0) == '<' && peek(1) == '?');
}

void DocumentBuilder::consumePI(Node *root){
  StringBuffer *sb = sb = new StringBuffer(40);
  consume("<?", 2);
  String * target = consumeNCName();
  consumeSpaces(1);
  while(peek(0) != '?' || peek(1) != '>'){
    if (peek(0) == -1){
      delete sb;
      get();
    }
    sb->append(get());
  }
  consume("?>", 2);
  root->appendChild(doc->createProcessingInstruction(target, sb));
}

bool DocumentBuilder::isComment(){
  return (peek(0) == '<' && peek(1) == '!' && peek(2) == '-');
}

void DocumentBuilder::consumeComment(Node *root){
  StringBuffer *sb = null;
  if (root != null && !isIgnoringComments()){
    sb = new StringBuffer();
  }
  consume("<!--", 4);
  while(peek(0) != '-' || peek(1) != '-' || peek(2) != '>'){
    if (peek(0) == -1){
      delete sb;
      get();
    }
    if (root && !isIgnoringComments()){
      sb->append(get());
    }else{
      get();
    }
  }
  consume("-->", 3);
  if (root != null && !isIgnoringComments()){
    root->appendChild(doc->createComment(sb));
  }
}

void DocumentBuilder::consumeMisc(Node *root){
  consumeSpaces();
  bool hasTokens = true;
  while(hasTokens){
    if(isComment()){
      consumeComment(root);
      consumeSpaces();
    }else if(isPI()){
      consumePI(root);
      consumeSpaces();
    }else{
      hasTokens = false;
    }
  }
}

void DocumentBuilder::consume(String &s){
  int idx;
  for(idx = 0; idx < s.length() && peek() == s[idx]; idx++){
    get();
  }
  if (idx < s.length()){
    throw ParseException(StringBuffer("Invalid sequence. waiting for '")+s+"'");
  }
}

void DocumentBuilder::consume(char *s, int len){
  int idx;
  if (len == -1){
    len = strlen(s);
  }
  for(idx = 0; idx < len && peek() == s[idx]; idx++){
    get();
  }
  if (idx < len){
    throw ParseException(StringBuffer("Invalid sequence. waiting for '")+s+"'");
  }
}
void DocumentBuilder::incDocumentLine(){
  doc->line++;
}
void DocumentBuilder::setDocumentPos(int pos){
  doc->pos = pos;
}
void DocumentBuilder::incDocumentPos(){
  doc->pos++;
}

Document *DocumentBuilder::newDocument()
{
  return new Document();
}

void DocumentBuilder::free(Document *doc)
{
  bool skip_childred = false;

  Node *rmnext = doc->getFirstChild();
  while(rmnext != doc && rmnext != null)
  {
    if (!skip_childred){
      while(rmnext->getFirstChild() != null){
        rmnext = rmnext->getFirstChild();
      }
    };
    skip_childred = false;

    Node *el = rmnext->getNextSibling();
    if(el == null){
      el = rmnext->getParent();
      skip_childred = true;
    }
    delete rmnext;
    rmnext = el;
  }
  delete doc;
}

/**  #123  #xABCD */
bool DocumentBuilder::getXMLNumber(const String &str, int *res)
{
int type, num;
int s, e, i, j, k;
long r;

  e = str.length();
  if (!e) return false;

  if (str[0] != '#') return false;

  s = 1;
  type = 0;

  if(str[1] == 'x'){
    s = 2;
    type = 1;
  };

  switch(type){
    case 0:
      num = 0;
      i = e-1;
      while(i >= s){
        j = str[i];
        if((j < '0') || (j > '9'))
          return false;
        j &= 15;
        k = e-i-1;
        r = (long)j;
        while(k){
          k--;
          r *= 10;
        };
        num += r;
        i--;
      };
      *res = num;
      break;
    case 1:
      num = 0;
      i = e-1;
      while(i >= s){
        j = str[i];
        if(((j < 0x30) || (j > 0x39)) &&
          ((j < 'a') || (j > 'f')) &&
          ((j < 'A') || (j > 'F')))
            return false;
        if (j > 0x60) j -= 0x27;
        if (j > 0x40) j -= 0x7;
        j &= 15;
        if(i > e-9)
          num |= (j << ((e-i-1)*4) );
        i--;
      };
      *res = num;
      break;
  };
  return true;
};


Node *Node::appendChild(Node *newChild)
{
  newChild->parent = this;

  if (firstChild == null)
  {
    firstChild = newChild;
    firstChild->prev = firstChild->next = newChild;
    return firstChild;
  }
  newChild->prev = firstChild->prev->next;
  firstChild->prev->next = newChild;
  firstChild->prev = newChild;
  newChild->next = firstChild;
  newChild->parent = this;
  return newChild;
}

void Element::setAttribute(const String *name, const String *value)
{
  if (attributesHash.get(name) != null){
    for(int idx = 0; idx < attributes.size(); idx++){
      if (attributes.elementAt(idx)->equals(name)){
        delete attributes.elementAt(idx);
        delete attributesHash.get(name);
        attributes.removeElementAt(idx);
        break;
      }
    }
  }
  attributes.addElement(name);
  attributesHash.put(name, value);
}

ProcessingInstruction *Document::createProcessingInstruction(const String *target, const String *data)
{
  ProcessingInstruction *pi = new ProcessingInstruction(target, data);
  pi->ownerDocument = this;
  return pi;
}

Element *Document::createElement(const String *tagName)
{
  Element *elem = new Element(tagName);
  elem->ownerDocument = this;
  return elem;
}

Comment *Document::createComment(const String *data)
{
  Comment *comment = new Comment(data);
  comment->ownerDocument = this;
  return comment;
}

Text *Document::createTextNode(const String *data)
{
  Text *text = new Text(data);
  text->ownerDocument = this;
  return text;
}
