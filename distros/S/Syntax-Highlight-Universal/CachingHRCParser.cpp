#include "CachingHRCParser.h"

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef keyword
#undef keyword
#endif

#define QUALIFY_SCHEME(name, scheme)  \
  {\
    if ((name) && !(scheme))\
    {\
      String *schemeName = qualifyForeignName((name), QNT_SCHEME, true);\
      if (schemeName != null)\
      {\
        (scheme) = schemeHash.get(schemeName);\
        delete schemeName;\
      }\
    }\
  }

void CachingHRCParser::loadFileType(FileType *filetype)
{
  if (buf)
  {
    FriendlyFileTypeImpl *f = (FriendlyFileTypeImpl*)filetype;
    if (!f->typeLoaded && f->baseScheme)
    {
      curFileType = f;
      int pos = (int)f->baseScheme;
      deserialize(pos, f->baseScheme);
      f->typeLoaded = TRUE;
      f->loadDone = TRUE;
    }
  }
  else
    HRCParserImpl::loadFileType(filetype);
}

void CachingHRCParser::serializeToFile(const char *filename)
{
  schemesSerialized.clear();
  regionsSerialized.clear();
  curPos = 0;
  dryRun = TRUE;
  serializePrimitive('HRCC');
  serializeVector(fileTypeVector);
  processQueue();

  file = fopen(filename, "wb");
  if (!file)
    croak("Couldn't open file %s for writing", filename);

  schemesSerialized.clear();
  regionsSerialized.clear();
  curPos = 0;
  dryRun = FALSE;
  serializePrimitive('HRCC');
  serializeVector(fileTypeVector);
  processQueue();

  fclose(file);
}

void CachingHRCParser::deserializeFromFile(const char *filename)
{
  file = fopen(filename, "rb");
  if (!file)
    croak("Couldn't open file %s for reading", filename);

  Stat_t s;
  if (fstat(fileno(file), &s) < 0)
  {
    fclose(file);
    croak("Couldn't stat file %s", filename);
  }

  bufSize = s.st_size;
  buf = new char[bufSize];
  fread(buf, sizeof(char), bufSize, file);
  fclose(file);

  int pos = 0;

  int magic;
  deserializePrimitive(pos, magic);
  if (magic != 'HRCC')
    croak("File %s has wrong format", filename);

  deserializeVector(pos, fileTypeVector);
}

void CachingHRCParser::serialize(const String *value)
{
  if (!value)
  {
    serializePrimitive((char)0xFF);
    return;
  }

  int len = value->length();
  if (len > 0xFFFF)
  {
    if (!dryRun)
      fclose(file);
    croak("Can't serialize a string that is longer than %i characters", 0xFFFF);
  }

  if (len <= 0xFD)
    serializePrimitive((char)len);
  else
  {
    serializePrimitive((char)0xFE);
    serializePrimitive((short)len);
  }

  if (!dryRun)
    fwrite(value->getChars(), sizeof(char), len, file);

  curPos += len;
}

void CachingHRCParser::deserialize(int &pos, String* &value)
{
  int len = *(unsigned char*)(buf + pos);
  pos += sizeof(unsigned char);
  if (len == 0xFF)
  {
    value = NULL;
    return;
  }
  else if (len == 0xFE)
  {
    len = *(unsigned short*)(buf + pos);
    pos += sizeof(unsigned short);
  }

  value = new DString(buf + pos, 0, len);
  pos += len;
}

void CachingHRCParser::deserialize(int &pos, const SString* &value)
{
  String* v;
  deserialize(pos, v);
  value = v ? new SString(v) : NULL;
}

void CachingHRCParser::serialize(const Vector<String*> &names, const Hashtable<String*> &values)
{
  int len = names.size();
  serializePrimitive(len);
  for (int i = 0; i < len; i++)
  {
    String *name = names.elementAt(i);
    serialize(name);
    serialize(values.get(name));
  }
}

void CachingHRCParser::deserialize(int &pos, Vector<String*> &names, Hashtable<String*> &values)
{
  int len;
  deserializePrimitive(pos, len);
  for (int i = 0; i < len; i++)
  {
    String *name, *value;
    deserialize(pos, name);
    deserialize(pos, value);
    names.addElement(name);
    values.put(name, value);
  }
}

void CachingHRCParser::serialize(const Region *value)
{
  if (regionsSerialized.get(value->getName()))
    return;

  regions.put(value->getName(), curPos);
  regionsSerialized.put(value->getName(), true);
  serializePrimitive((Region*)NULL);

  serialize(value->getName());
  serialize(value->getDescription());
  serializeQueued((Region*)value->getParent());
}

void CachingHRCParser::deserialize(int &pos, Region* &value)
{
  int origPos = pos;

  deserializePrimitive(pos, value);
  if (value)
    return;

  String* regionName;
  deserialize(pos, regionName);

  String* regionDescr;
  deserialize(pos, regionDescr);

  FriendlyRegion* v = new FriendlyRegion(regionName, regionDescr, null, regionNamesVector.size());

  value = v;
  *(Region**)(buf + origPos) = value;
  regionNamesVector.addElement(value);
  regionNamesHash.put(regionName, value);
  delete regionName;
  delete regionDescr;

  Region* parent;
  deserializePointer(pos, parent);
  v->parent = parent;
}

void CachingHRCParser::serialize(VirtualEntry *value)
{
  QUALIFY_SCHEME(value->virtSchemeName, value->virtScheme);
  QUALIFY_SCHEME(value->substSchemeName, value->substScheme);

  serializeQueued(value->virtScheme);
  serializeQueued(value->substScheme);
}

void CachingHRCParser::deserialize(int &pos, VirtualEntry* &value)
{
  DString s("");
  value = new VirtualEntry(&s, &s);
  delete value->virtSchemeName;
  delete value->substSchemeName;
  value->virtSchemeName = null;
  value->substSchemeName = null;

  deserializePointer(pos, value->virtScheme);
  deserializePointer(pos, value->substScheme);
}

void CachingHRCParser::serialize(const KeywordInfo *value)
{
  serialize((String*)value->keyword);
  serializePrimitive((char)(value->isSymbol ? 1 : 0));
  serializeQueued((Region*)value->region);
}

void CachingHRCParser::deserialize(int &pos, KeywordInfo* value)
{
  deserialize(pos, value->keyword);

  char isSymbol;
  deserializePrimitive(pos, isSymbol);
  value->isSymbol = isSymbol;

  Region* region;
  deserializePointer(pos, region);
  value->region = region;
}

void CachingHRCParser::serialize(const KeywordList *value)
{
  if (!value || !value->num)
  {
    serializePrimitive((int)0);
    return;
  }

  serializePrimitive(value->num);
  serializePrimitive((char)(value->matchCase ? 1 : 0));
  for (int i = 0; i < value->num; i++)
    serialize(value->kwList + i);
}

void CachingHRCParser::deserialize(int &pos, KeywordList* &value)
{
  int num;
  deserializePrimitive(pos, num);
  if (!num)
  {
    value = NULL;
    return;
  }

  value = new KeywordList();
  value->firstChar = new CharacterClass();
  value->num = num;
  value->kwList = new KeywordInfo[num];
  value->minKeywordLength = 0x10000;

  char matchCase;
  deserializePrimitive(pos, matchCase);
  value->matchCase = matchCase;

  for (int i = 0; i < num; i++)
  {
    deserialize(pos, value->kwList + i);
    if (value->kwList[i].keyword)
    {
      value->firstChar->addChar((*value->kwList[i].keyword)[0]);
      if (!value->matchCase)
      {
        value->firstChar->addChar(Character::toLowerCase((*value->kwList[i].keyword)[0]));
        value->firstChar->addChar(Character::toUpperCase((*value->kwList[i].keyword)[0]));
        value->firstChar->addChar(Character::toTitleCase((*value->kwList[i].keyword)[0]));
      }
      if (value->minKeywordLength > value->kwList[i].keyword->length())
        value->minKeywordLength = value->kwList[i].keyword->length();
    }
  }
}

void CachingHRCParser::serialize(SchemeNode *value)
{
  serializePrimitive((char)value->type);

  if (value->type == SNT_SCHEME || value->type == SNT_INHERIT)
  {
    QUALIFY_SCHEME(value->schemeName, value->scheme);
    serializeQueued(value->scheme);
  }

  serializeVector(value->virtualEntryVector);

  if (value->type == SNT_KEYWORDS)
  {
    serialize(value->kwList);
    serialize(value->worddivString);
  }

  if (value->type == SNT_SCHEME || value->type == SNT_RE)
  {
    int i;

    serializeQueued((Region*)value->region);

    for (i = 0; i < REGIONS_NUM; i++)
      serializeQueued((Region*)value->regions[i]);

    for (i = 0; i < NAMED_REGIONS_NUM; i++)
      serializeQueued((Region*)value->regionsn[i]);

    if (value->type == SNT_SCHEME)
    {
      for (i = 0; i < REGIONS_NUM; i++)
        serializeQueued((Region*)value->regione[i]);

      for (i = 0; i < NAMED_REGIONS_NUM; i++)
        serializeQueued((Region*)value->regionen[i]);
    }

    serialize(value->startString);
    if (value->type == SNT_SCHEME)
      serialize(value->endString);
  }

  serializePrimitive((char)(value->lowPriority ? 1 : 0));
  serializePrimitive((char)(value->lowContentPriority ? 1 : 0));
}

void CachingHRCParser::deserialize(int &pos, SchemeNode* &value)
{
  value = new SchemeNode();

  char type;
  deserializePrimitive(pos, type);
  value->type = (SchemeNodeType)type;

  if (value->type == SNT_SCHEME || value->type == SNT_INHERIT)
  {
    deserializePointer(pos, value->scheme);
    value->schemeName = NULL;
  }

  deserializeVector(pos, value->virtualEntryVector);

  if (value->type == SNT_KEYWORDS)
  {
    deserialize(pos, value->kwList);

    deserialize(pos, value->worddivString);
    value->worddiv = value->worddivString ? CharacterClass::createCharClass(*value->worddivString, 0, null) : null;
  }

  if (value->type == SNT_SCHEME || value->type == SNT_RE)
  {
    Region* region;
    int i;

    deserializePointer(pos, region);
    value->region = region;

    for (i = 0; i < REGIONS_NUM; i++)
    {
      deserializePointer(pos, region);
      value->regions[i] = region;
    }

    for (i = 0; i < NAMED_REGIONS_NUM; i++)
    {
      deserializePointer(pos, region);
      value->regionsn[i] = region;
    }

    if (value->type == SNT_SCHEME)
    {
      for (i = 0; i < REGIONS_NUM; i++)
      {
        deserializePointer(pos, region);
        value->regione[i] = region;
      }

      for (i = 0; i < NAMED_REGIONS_NUM; i++)
      {
        deserializePointer(pos, region);
        value->regionen[i] = region;
      }
    }

    deserialize(pos, value->startString);
    value->start = value->startString ? new CRegExp(value->startString) : null;
    value->start->setPositionMoves(FALSE);

    if (value->type == SNT_SCHEME)
    {
      deserialize(pos, value->endString);
      if (value->endString)
      {
        value->end = new CRegExp();
        value->end->setPositionMoves(TRUE);
        value->end->setBackRE(value->start);
        value->end->setRE(value->endString);
      }
      else
        value->end = null;
    }
  }

  char priority;
  deserializePrimitive(pos, priority);
  value->lowPriority = priority;
  deserializePrimitive(pos, priority);
  value->lowContentPriority = priority;
}

void CachingHRCParser::serialize(const SchemeImpl *value)
{
  if (schemesSerialized.get(value->getName()))
    return;

  schemes.put(value->getName(), curPos);
  schemesSerialized.put(value->getName(), true);
  serializePrimitive((SchemeImpl*)NULL);

  FriendlySchemeImpl *v = (FriendlySchemeImpl*)value;
  serialize(v->schemeName);
  serializeVector(v->nodes);

  processQueue();
}

void CachingHRCParser::deserialize(int &pos, SchemeImpl* &value)
{
  int origPos = pos;

  deserializePrimitive(pos, value);
  if (value)
    return;

  String* schemeName;
  deserialize(pos, schemeName);

  FriendlySchemeImpl *v = new FriendlySchemeImpl(schemeName);
  v->fileType = curFileType;

  value = v;
  *(SchemeImpl**)(buf + origPos) = value;
  schemeHash.put(schemeName, value);
  delete schemeName;

  deserializeVector(pos, v->nodes);
}

void CachingHRCParser::serialize(const FileTypeImpl *value)
{
  FriendlyFileTypeImpl *v = (FriendlyFileTypeImpl*) value;

  serialize(v->name);

  v->getBaseScheme();
  serializeQueued(v->baseScheme);

  serialize(v->paramVector, v->paramDefaultHash);
}

void CachingHRCParser::deserialize(int &pos, FileTypeImpl* &value)
{
  FriendlyFileTypeImpl *v = new FriendlyFileTypeImpl(this);

  deserialize(pos, v->name);

  int baseScheme;
  deserializePrimitive(pos, baseScheme);
  v->baseScheme = (SchemeImpl*)baseScheme;

  deserialize(pos, v->paramVector, v->paramDefaultHash);

  v->protoLoaded = TRUE;
  v->typeLoaded = FALSE;
  v->loadDone = FALSE;
  v->loadBroken = FALSE;

  value = v;
  fileTypeHash.put(v->name, value);
}

void CachingHRCParser::serializeQueued(SchemeImpl *value)
{
  if (value)
  {
    if (!schemesSerialized.get(value->getName()))
      schemeQueue.addElement(value);

    serializePrimitive(schemes.get(value->getName()));
  }
  else
    serializePrimitive((int)0);
}

void CachingHRCParser::serializeQueued(Region *value)
{
  if (value)
  {
    if (!regionsSerialized.get(value->getName()))
      regionQueue.addElement(value);

    serializePrimitive(regions.get(value->getName()));
  }
  else
    serializePrimitive((int)0);

}

void CachingHRCParser::processQueue()
{
  while (regionQueue.size())
  {
    int i = regionQueue.size() - 1;
    Region* region = regionQueue.elementAt(i);
    regionQueue.removeElementAt(i);
    serialize(region);
  }

  while (schemeQueue.size())
  {
    int i = schemeQueue.size() - 1;
    SchemeImpl* scheme = schemeQueue.elementAt(i);
    schemeQueue.removeElementAt(i);
    serialize(scheme);
  }
}
