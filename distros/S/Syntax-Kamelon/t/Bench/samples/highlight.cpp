/* This file is part of the KDE libraries
   Copyright (C) 2003, 2004 Anders Lund <anders@alweb.dk>
   Copyright (C) 2003 Hamish Rodda <rodda@kde.org>
   Copyright (C) 2001,2002 Joseph Wenninger <jowenn@kde.org>
   Copyright (C) 2001 Christoph Cullmann <cullmann@kde.org>
   Copyright (C) 1999 Jochen Wilhelmy <digisnap@cs.tu-berlin.de>


   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.
*/

//BEGIN INCLUDES
#include "katehighlight.h"
#include "katehighlight.moc"

#include <kstaticdeleter.h>
#include <kapplication.h>

#include <qstringlist.h>
#include <qtextstream.h>
//END

//BEGIN defines
// same as in kmimemagic, no need to feed more data
#define KATE_HL_HOWMANY 1024

// min. x seconds between two dynamic contexts reset
static const int KATE_DYNAMIC_CONTEXTS_RESET_DELAY = 30 * 1000;

// x is a QString. if x is "true" or "1" this expression returns "true"
#define IS_TRUE(x) x.lower() == QString("true") || x.toInt() == 1
//END defines

//BEGIN  Prviate HL classes

inline bool kateInsideString (const QString &str, QChar ch)
{
  for (uint i=0; i < str.length(); i++)
    if (*(str.unicode()+i) == ch)
      return true;

  return false;
}

class KateHlItem
{
  public:
    KateHlItem(int attribute, int context,signed char regionId, signed char regionId2);
    virtual ~KateHlItem();

  public:
    // caller must keep in mind: LEN > 0 is a must !!!!!!!!!!!!!!!!!!!!!1
    // Now, the function returns the offset detected, or 0 if no match is found.
    // bool linestart isn't needed, this is equivalent to offset == 0.
    virtual int checkHgl(const QString& text, int offset, int len) = 0;

    virtual bool lineContinue(){return false;}

    virtual QStringList *capturedTexts() {return 0;}
    virtual KateHlItem *clone(const QStringList *) {return this;}

    static void dynamicSubstitute(QString& str, const QStringList *args);

    QMemArray<KateHlItem*> subItems;
    int attr;
    int ctx;
    signed char region;

    // start enable flags, nicer than the virtual methodes
    // saves function calls
    bool alwaysStartEnable;
    bool customStartEnable;
};

class KateHlContext
{
  public:
    KateHlContext(const QString &_hlId, int attribute, int lineEndContext,int _lineBeginContext,
                  bool _fallthrough, int _fallthroughContext, bool _dynamic);
    virtual ~KateHlContext();
    KateHlContext *clone(const QStringList *args);

    QValueVector<KateHlItem*> items;
    QString hlId; ///< A unique highlight identifier. Used to look up correct properties.
    int attr;
    int ctx;
    int lineBeginContext;
    /** @internal anders: possible escape if no rules matches.
       false unless 'fallthrough="1|true"' (insensitive)
       if true, go to ftcxt w/o eating of string.
       ftctx is "fallthroughContext" in xml files, valid values are int or #pop[..]
       see in KateHighlighting::doHighlight */
    bool fallthrough;
    int ftctx; // where to go after no rules matched

    bool dynamic;
    bool dynamicChild;
};


//END

//BEGIN STATICS
KateHlManager *KateHlManager::s_self = 0;

static const bool trueBool = true;
static const QString stdDeliminator = QString (" \t.():!+,-<=>%&*/;?[]^{|}~\\");
//END

//BEGIN NON MEMBER FUNCTIONS
static KateHlItemData::ItemStyles getDefStyleNum(QString name)
{
  if (name=="dsNormal") return KateHlItemData::dsNormal;
  else if (name=="dsKeyword") return KateHlItemData::dsKeyword;
  else if (name=="dsDataType") return KateHlItemData::dsDataType;
  else if (name=="dsDecVal") return KateHlItemData::dsDecVal;
  else if (name=="dsBaseN") return KateHlItemData::dsBaseN;
  else if (name=="dsFloat") return KateHlItemData::dsFloat;
  else if (name=="dsChar") return KateHlItemData::dsChar;
  else if (name=="dsString") return KateHlItemData::dsString;
  else if (name=="dsComment") return KateHlItemData::dsComment;
  else if (name=="dsOthers")  return KateHlItemData::dsOthers;
  else if (name=="dsAlert") return KateHlItemData::dsAlert;
  else if (name=="dsFunction") return KateHlItemData::dsFunction;
  else if (name=="dsRegionMarker") return KateHlItemData::dsRegionMarker;
  else if (name=="dsError") return KateHlItemData::dsError;

  return KateHlItemData::dsNormal;
}
//END

KateHlItem::~KateHlItem()
{
  //kdDebug(13010)<<"In hlItem::~KateHlItem()"<<endl;
  for (uint i=0; i < subItems.size(); i++)
    delete subItems[i];
}

void KateHlItem::dynamicSubstitute(QString &str, const QStringList *args)
{
  for (uint i = 0; i < str.length() - 1; ++i)
  {
    if (str[i] == '%')
    {
      char c = str[i + 1].latin1();
      if (c == '%')
        str.replace(i, 1, "");
      else if (c >= '0' && c <= '9')
      {
        if ((uint)(c - '0') < args->size())
        {
          str.replace(i, 2, (*args)[c - '0']);
          i += ((*args)[c - '0']).length() - 1;
        }
        else
        {
          str.replace(i, 2, "");
          --i;
        }
      }
    }
  }
}
//END


//BEGIN KateHlCStringChar
KateHlCStringChar::KateHlCStringChar(int attribute, int context,signed char regionId,signed char regionId2)
  : KateHlItem(attribute,context,regionId,regionId2) {
}

// checks for C escaped chars \n and escaped hex/octal chars
static int checkEscapedChar(const QString& text, int offset, int& len)
{
  int i;
  if (text[offset] == '\\' && len > 1)
  {
    offset++;
    len--;

    switch(text[offset])
    {
      case  'a': // checks for control chars
      case  'b': // we want to fall through
      case  'e':
      case  'f':

      case  'n':
      case  'r':
      case  't':
      case  'v':
      case '\'':
      case '\"':
      case '?' : // added ? ANSI C classifies this as an escaped char
      case '\\':
        offset++;
        len--;
        break;

      case 'x': // if it's like \xff
        offset++; // eat the x
        len--;
        // these for loops can probably be
        // replaced with something else but
        // for right now they work
        // check for hexdigits
        for (i = 0; (len > 0) && (i < 2) && (text[offset] >= '0' && text[offset] <= '9' || (text[offset] & 0xdf) >= 'A' && (text[offset] & 0xdf) <= 'F'); i++)
        {
          offset++;
          len--;
        }

        if (i == 0)
          return 0; // takes care of case '\x'

        break;

      case '0': case '1': case '2': case '3' :
      case '4': case '5': case '6': case '7' :
        for (i = 0; (len > 0) && (i < 3) && (text[offset] >='0'&& text[offset] <='7'); i++)
        {
          offset++;
          len--;
        }
        break;

      default:
        return 0;
    }

    return offset;
  }

  return 0;
}

int KateHlCStringChar::checkHgl(const QString& text, int offset, int len)
{
  return checkEscapedChar(text, offset, len);
}
//END

//BEGIN KateHlCChar
KateHlCChar::KateHlCChar(int attribute, int context,signed char regionId,signed char regionId2)
  : KateHlItem(attribute,context,regionId,regionId2) {
}

int KateHlCChar::checkHgl(const QString& text, int offset, int len)
{
  if ((len > 1) && (text[offset] == '\'') && (text[offset+1] != '\''))
  {
    int oldl;
    oldl = len;

    len--;

    int offset2 = checkEscapedChar(text, offset + 1, len);

    if (!offset2)
    {
      if (oldl > 2)
      {
        offset2 = offset + 2;
        len = oldl - 2;
      }
      else
      {
        return 0;
      }
    }

    if ((len > 0) && (text[offset2] == '\''))
      return ++offset2;
  }

  return 0;
}
//END

//BEGIN KateHl2CharDetect
KateHl2CharDetect::KateHl2CharDetect(int attribute, int context, signed char regionId,signed char regionId2, const QChar *s)
  : KateHlItem(attribute,context,regionId,regionId2) {
  sChar1 = s[0];
  sChar2 = s[1];
  }
//END KateHl2CharDetect

KateHlItemData::KateHlItemData(const QString  name, int defStyleNum)
  : name(name), defStyleNum(defStyleNum) {
}

KateHlData::KateHlData(const QString &wildcards, const QString &mimetypes, const QString &identifier, int priority)
  : wildcards(wildcards), mimetypes(mimetypes), identifier(identifier), priority(priority)
{
}

//BEGIN KateHlContext
KateHlContext::KateHlContext (const QString &_hlId, int attribute, int lineEndContext, int _lineBeginContext, bool _fallthrough, int _fallthroughContext, bool _dynamic)
{
  hlId = _hlId;
  attr = attribute;
  ctx = lineEndContext;
  lineBeginContext = _lineBeginContext;
  fallthrough = _fallthrough;
  ftctx = _fallthroughContext;
  dynamic = _dynamic;
  dynamicChild = false;
}

KateHlContext *KateHlContext::clone(const QStringList *args)
{
  KateHlContext *ret = new KateHlContext(hlId, attr, ctx, lineBeginContext, fallthrough, ftctx, false);

  for (uint n=0; n < items.size(); ++n)
  {
    KateHlItem *item = items[n];
    KateHlItem *i = (item->dynamic ? item->clone(args) : item);
    ret->items.append(i);
  }

  ret->dynamicChild = true;

  return ret;
}

KateHlContext::~KateHlContext()
{
  if (dynamicChild)
  {
    for (uint n=0; n < items.size(); ++n)
    {
      if (items[n]->dynamicChild)
        delete items[n];
    }
  }
}
//END

{
  KConfig *config = KateHlManager::self()->getKConfig();
  config->setGroup("Highlighting " + iName + " - Schema "
      + KateFactory::self()->schemaManager()->name(schema));

  QStringList settings;

  for (KateHlItemData *p = list.first(); p != 0L; p = list.next())
  {
    settings.clear();
    settings<<QString::number(p->defStyleNum,10);
    settings<<(p->itemSet(KateAttribute::TextColor)?QString::number(p->textColor().rgb(),16):"");
    settings<<(p->itemSet(KateAttribute::SelectedTextColor)?QString::number(p->selectedTextColor().rgb(),16):"");
    settings<<(p->itemSet(KateAttribute::Weight)?(p->bold()?"1":"0"):"");
    settings<<(p->itemSet(KateAttribute::Italic)?(p->italic()?"1":"0"):"");
    settings<<(p->itemSet(KateAttribute::StrikeOut)?(p->strikeOut()?"1":"0"):"");
    settings<<(p->itemSet(KateAttribute::Underline)?(p->underline()?"1":"0"):"");
    settings<<(p->itemSet(KateAttribute::BGColor)?QString::number(p->bgColor().rgb(),16):"");
    settings<<(p->itemSet(KateAttribute::SelectedBGColor)?QString::number(p->selectedBGColor().rgb(),16):"");
    settings<<"---";
    config->writeEntry(p->name,settings);
  }
}

/**
 * Increase the usage count, and trigger initialization if needed.
 */
void KateHighlighting::use()
{
  if (refCount == 0)
    init();

  refCount++;
}

/**
 * Decrease the usage count, and trigger cleanup if needed.
 */
void KateHighlighting::release()
{
  refCount--;

  if (refCount == 0)
    done();
}

/**
 * Initialize a context for the first time.
 */

void KateHighlighting::init()
{
  if (noHl)
    return;

  m_contexts.clear ();
  makeContextList();
}


/**
 * If the there is no document using the highlighting style free the complete
 * context structure.
 */
void KateHighlighting::done()
{
  if (noHl)
    return;

  m_contexts.clear ();
  internalIDList.clear();
}

/**
 * KateHighlighting - createKateHlItemData
 * This function reads the itemData entries from the config file, which specifies the
 * default attribute styles for matched items/contexts.
 *
 * @param list A reference to the internal list containing the parsed default config
 */
void KateHighlighting::createKateHlItemData(KateHlItemDataList &list)
{
  // If no highlighting is selected we need only one default.
  if (noHl)
  {
    list.append(new KateHlItemData(i18n("Normal Text"), KateHlItemData::dsNormal));
    return;
  }

  // If the internal list isn't already available read the config file
  if (internalIDList.isEmpty())
    makeContextList();

  list=internalIDList;
}


      bool dynamic = false;
      QString tmpDynamic = KateHlManager::self()->syntax->groupData(data, QString("dynamic") );
      if ( tmpDynamic.lower() == "true" ||  tmpDynamic.toInt() == 1 )
        dynamic = true;

      KateHlContext *ctxNew = new KateHlContext (
        ident,
        attr,
        context,
        (KateHlManager::self()->syntax->groupData(data,QString("lineBeginContext"))).isEmpty()?-1:
        (KateHlManager::self()->syntax->groupData(data,QString("lineBeginContext"))).toInt(),
        ft, ftc, dynamic);

      m_contexts.push_back (ctxNew);

      kdDebug(13010) << "INDEX: " << i << " LENGTH " << m_contexts.size()-1 << endl;

      //Let's create all items for the context
      while (KateHlManager::self()->syntax->nextItem(data))
      {
//    kdDebug(13010)<< "In make Contextlist: Item:"<<endl;

      // KateHlIncludeRules : add a pointer to each item in that context
        // TODO add a attrib includeAttrib
