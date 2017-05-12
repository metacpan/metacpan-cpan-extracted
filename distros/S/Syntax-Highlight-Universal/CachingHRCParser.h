#include <stdio.h>

#include <common/Vector.h>
#include <colorer/parsers/HRCParserImpl.h>
#include <colorer/parsers/helpers/HRCParserHelpers.h>

class CachingHRCParser : public HRCParserImpl
{
public:
  CachingHRCParser() : buf(null) {}
  ~CachingHRCParser()
  {
    if (buf)
      delete(buf);
  }

  void serializeToFile(const char *filename);
  void deserializeFromFile(const char *filename);
protected:
  void loadFileType(FileType *filetype);

  template<typename T>
  void serializePrimitive(const T value)
  {
    if (!dryRun)
      fwrite(&value, sizeof(value), 1, file);

    curPos += sizeof(value);
  }

  template<typename T>
  void deserializePrimitive(int &pos, T &value)
  {
    value = *(T*)(buf + pos);
    pos += sizeof(value);
  }

  template<typename T>
  void serializeVector(const Vector<T> &value)
  {
    int len = value.size();
    serializePrimitive(len);

    for (int i = 0; i < len; i++)
      serialize(value.elementAt(i));
  }

  template<typename T>
  void deserializeVector(int &pos, Vector<T> &value)
  {
    int len;
    deserializePrimitive(pos, len);

    for (int i = 0; i < len; i++)
    {
      T element;
      deserialize(pos, element);
      value.addElement(element);
    }
  }

  template <typename T>
  void deserializePointer(int &pos, T* &value)
  {
    int pointer;
    deserializePrimitive(pos, pointer);
    if (pointer)
      deserialize(pointer, value);
    else
      value = NULL;
  }

  void serialize(const String *value);
  void deserialize(int &pos, String* &value);
  void deserialize(int &pos, const SString* &value);
  void serialize(const Vector<String*> &names, const Hashtable<String*> &values);
  void deserialize(int &pos, Vector<String*> &names, Hashtable<String*> &values);
  void serialize(const Region *value);
  void deserialize(int &pos, Region* &value);
  void serialize(VirtualEntry *value);
  void deserialize(int &pos, VirtualEntry* &value);
  void serialize(const KeywordInfo *value);
  void deserialize(int &pos, KeywordInfo* value);
  void serialize(const KeywordList *value);
  void deserialize(int &pos, KeywordList* &value);
  void serialize(SchemeNode *value);
  void deserialize(int &pos, SchemeNode* &value);
  void serialize(const SchemeImpl *value);
  void deserialize(int &pos, SchemeImpl* &value);
  void serialize(const FileTypeImpl *value);
  void deserialize(int &pos, FileTypeImpl* &value);
  void serializeQueued(SchemeImpl *value);
  void serializeQueued(Region *value);
  void processQueue();

  FILE *file;
  int curPos;
  bool dryRun;
  Hashtable<int> schemes;
  Hashtable<int> regions;
  Hashtable<bool> schemesSerialized;
  Hashtable<bool> regionsSerialized;
  Vector<SchemeImpl*> schemeQueue;
  Vector<Region*> regionQueue;

  char* buf;
  int bufSize;
  FileTypeImpl* curFileType;
};

class FriendlyFileTypeImpl : public FileTypeImpl
{
  friend class CachingHRCParser;

private:
  FriendlyFileTypeImpl(HRCParserImpl* hrcParser) : FileTypeImpl(hrcParser) {}
};

class FriendlySchemeImpl : public SchemeImpl
{
  friend class CachingHRCParser;

private:
  FriendlySchemeImpl(const String* str) : SchemeImpl(str) {}
};

class FriendlyRegion: public Region
{
  friend class CachingHRCParser;
private:
  FriendlyRegion(const String* name, const String* description, const Region* parent, int id) : Region(name, description, parent, id) {}
};

