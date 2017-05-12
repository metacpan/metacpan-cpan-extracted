/* This is a comment
NOTE works
*/

//BEGIN INCLUDES
#include "katehighlight.h"
#include "katehighlight.moc"

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
    // Now, the function returns the offset detected, or 0 if no match is found.
    // bool linestart isn't needed, this is equivalent to offset == 0.
    virtual int checkHgl(const QString& text, int offset, int len) = 0;

    virtual bool lineContinue(){return false;}

    virtual QStringList *capturedTexts() {return 0;}

    static void dynamicSubstitute(QString& str, const QStringList *args);

    int attr;
    int ctx;
    signed char region;
    signed char region2;

    bool lookAhead;

    bool dynamic;
    int column;

    // start enable flags, nicer than the virtual methodes
    // saves function calls
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
  else if (name=="dsError") return KateHlItemData::dsError;

  return KateHlItemData::dsNormal;
}
//END

//BEGIN KateHlItem
KateHlItem::KateHlItem(int attribute, int context,signed char regionId,signed char regionId2)
  : attr(attribute),
    ctx(context),
    region(regionId),
    alwaysStartEnable (true),
    customStartEnable (false)
{
}

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


//BEGIN KateHlStringDetect
KateHlStringDetect::KateHlStringDetect(int attribute, int context, signed char regionId,signed char regionId2,const QString &s, bool inSensitive)
  : KateHlItem(attribute, context,regionId,regionId2)
  , str(inSensitive ? s.upper() : s)
  , strLen (str.length())
  , _inSensitive(inSensitive)
{
}

//BEGIN KateHlCFloat
KateHlCFloat::KateHlCFloat(int attribute, int context, signed char regionId,signed char regionId2)
  : KateHlFloat(attribute,context,regionId,regionId2)
{
  alwaysStartEnable = false;
}

//END


/**
 * Creates a new dynamic context or reuse an old one if it has already been created.
 */
int KateHighlighting::makeDynamicContext(KateHlContext *model, const QStringList *args)
{
  QPair<KateHlContext *, QString> key(model, args->front());
  short value;

  if (dynamicCtxs.contains(key))
    value = dynamicCtxs[key];
  else
  {
    kdDebug(13010) << "new stuff: " << startctx << endl;

    KateHlContext *newctx = model->clone(args);

    m_contexts.push_back (newctx);

    value = startctx++;
    dynamicCtxs[key] = value;
    KateHlManager::self()->incDynamicCtxs();
  }

  // kdDebug(13010) << "Dynamic context: using context #" << value << " (for model " << model << " with args " << *args << ")" << endl;

  return value;
}

/**
 * Drop all dynamic contexts. Shall be called with extreme care, and shall be immediatly
 * followed by a full HL invalidation.
 */
void KateHighlighting::dropDynamicContexts()
{
  for (uint i=base_startctx; i < m_contexts.size(); ++i)
    delete m_contexts[i];

  m_contexts.resize (base_startctx);

  dynamicCtxs.clear();
  startctx = base_startctx;
}

/**
 * Parse the text and fill in the context array and folding list array
 *
 * @param prevLine The previous line, the context array is picked up from that if present.
 * @param textLine The text line to parse
 * @param foldinglist will be filled
 * @param ctxChanged will be set to reflect if the context changed
 */
void KateHighlighting::doHighlight ( KateTextLine *prevLine,
                                     KateTextLine *textLine,
                                     QMemArray<uint>* foldingList,
                                     bool *ctxChanged )

void KateHighlighting::loadWildcards()
{
  KConfig *config = KateHlManager::self()->getKConfig();
  config->setGroup("Highlighting " + iName);

  QString extensionString = config->readEntry("Wildcards", iWildcards);

  if (extensionSource != extensionString) {
    regexpExtensions.clear();
    plainExtensions.clear();

    extensionSource = extensionString;

    static QRegExp sep("\\s*;\\s*");

    QStringList l = QStringList::split( sep, extensionSource );

    static QRegExp boringExpression("\\*\\.[\\d\\w]+");

    for( QStringList::Iterator it = l.begin(); it != l.end(); ++it )
      if (boringExpression.exactMatch(*it))
        plainExtensions.append((*it).mid(1));
      else
        regexpExtensions.append(QRegExp((*it), true, true));
  }
}

QValueList<QRegExp>& KateHighlighting::getRegexpExtensions()
{
  return regexpExtensions;
}


//END KateViewHighlightAction

// kate: space-indent on; indent-width 2; replace-tabs on;
