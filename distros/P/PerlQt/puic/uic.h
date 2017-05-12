/**********************************************************************
** Copyright (C) 2000 Trolltech AS.  All rights reserved.
** Copyright (c) 2001 Phil Thompson <phil@river-bank.demon.co.uk>
**
** This file is part of Qt Designer.
**
** This file may be distributed and/or modified under the terms of the
** GNU General Public License version 2 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://www.trolltech.com/gpl/ for GPL licensing information.
**
** Contact info@trolltech.com if any conditions of this licensing are
** not clear to you.
**
**********************************************************************/

#ifndef UIC_H
#define UIC_H
#include <qdom.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qmap.h>
#include <qtextstream.h>
#include <qpalette.h>
#include <qvariant.h>

#ifndef Q_DUMMY_COMPARISON_OPERATOR
# warning "Defining Q_DUMMY_COMPARISON_OPERATOR"
# ifdef Q_FULL_TEMPLATE_INSTANTIATION
#  define Q_DUMMY_COMPARISON_OPERATOR(C) \
    bool operator==( const C& ) const { \
        qWarning( #C"::operator==( const "#C"& ) got called." ); \
        return FALSE; \
    }
# else
#  define Q_DUMMY_COMPARISON_OPERATOR(C)
# endif
#endif

class PyIndent
{
public:
	PyIndent() : tabStop(4), current(0) {calc();}

	void setTabStop(uint n) {tabStop = n; calc();}
	void operator++() {++current; calc();}
	void operator--() {--current; calc();}
	operator QString() {return indstr;}

private:
	uint tabStop;
	uint current;
	QString indstr;

	void calc();
};


class Uic : public Qt
{
public:
    Uic( const QString &fn, const char *outputFn, QTextStream& outStream,
	QDomDocument doc, bool subcl, const QString &trm,
	const QString& subClass, bool omitForwardDecls, QString &uicClass );

    static void setIndent(const PyIndent &pyind) {indent = pyind;}

    void createFormImpl( const QDomElement &e );

    void createSubImpl( const QDomElement &e, const QString& subclname );

    void createObjectDecl( const QDomElement& e );
    void createAttrDecl( const QDomElement& e );
    void createActionDecl( const QDomElement& e );
    void createActionImpl( const QDomElement& e, const QString &parent );
    void createToolbarImpl( const QDomElement &e, const QString &parentClass, const QString &parent );
    void createMenuBarImpl( const QDomElement &e, const QString &parentClass, const QString &parent );
    void createPopupMenuImpl( const QDomElement &e, const QString &parentClass, const QString &parent );
    QString createObjectImpl( const QDomElement &e, const QString& parentClass, const QString& parent, const QString& layout = QString::null );
    QString createLayoutImpl( const QDomElement &e, const QString& parentClass, const QString& parent, const QString& layout = QString::null );
    QString createObjectInstance( const QString& objClass, const QString& parent, const QString& objName );
    QString createSpacerImpl( const QDomElement &e, const QString& parentClass, const QString& parent, const QString& layout = QString::null );
    void createExclusiveProperty( const QDomElement & e, const QString& exclusiveProp );
    QString createListBoxItemImpl( const QDomElement &e, const QString &parent, QString *value = 0 );
    QString createIconViewItemImpl( const QDomElement &e, const QString &parent );
    QString createListViewColumnImpl( const QDomElement &e, const QString &parent, QString *value = 0 );
    QString createTableRowColumnImpl( const QDomElement &e, const QString &parent, QString *value = 0 );
    QString createListViewItemImpl( const QDomElement &e, const QString &parent,
				    const QString &parentItem );
    void createColorGroupImpl( const QString& cg, const QDomElement& e );
    QColorGroup loadColorGroup( const QDomElement &e );

    QDomElement getObjectProperty( const QDomElement& e, const QString& name );
    QString getPixmapLoaderFunction( const QDomElement& e );
    QString getFormClassName( const QDomElement& e );
    QString getClassName( const QDomElement& e );
    QString getObjectName( const QDomElement& e );
    QString getLayoutName( const QDomElement& e );
    QString getInclude( const QString& className );

    QString setObjectProperty( const QString& objClass, const QString& obj, const QString &prop, const QDomElement &e, bool stdset );

    QString registerObject( const QString& name );
    QString registeredName( const QString& name );
    bool isObjectRegistered( const QString& name );
    QStringList unique( const QStringList& );

    QString trcall( const QString& sourceText, const QString& comment = "" );

    static void embed( QTextStream& out, const char* project, const QStringList& images );

    friend void getDBConnections(Uic& uic, QString& s);

private:
    void registerLayouts ( const QDomElement& e );

    QTextStream& out;
    QTextOStream trout;
    QString languageChangeBody;
    QCString outputFileName;
    QStringList objectNames;
    QMap<QString,QString> objectMapper;
    QStringList tags;
    QStringList layouts;
    QString formName;
    QString lastItem;
    QString trmacro;

    bool nofwd;
    static PyIndent indent;

    struct Buddy
    {
	Buddy( const QString& k, const QString& b )
	    : key( k ), buddy( b ) {}
	Buddy(){} // for valuelist
	QString key;
	QString buddy;
	bool operator==( const Buddy& other ) const
	    { return (key == other.key); }
    };
    struct CustomInclude
    {
	QString header;
	QString location;
	Q_DUMMY_COMPARISON_OPERATOR(CustomInclude)
    };
    QValueList<Buddy> buddies;

    QStringList layoutObjects;
    bool isLayout( const QString& name ) const;

    uint item_used : 1;
    uint cg_used : 1;
    uint pal_used : 1;
    uint stdsetdef : 1;
    uint externPixmaps : 1;

    QString nameOfClass;
    QStringList namespaces;
    QString bareNameOfClass;
    QString pixmapLoaderFunction;

    void registerDatabases( const QDomElement& e );
    bool isWidgetInTable( const QDomElement& e, const QString& connection, const QString& table );
    bool isFrameworkCodeGenerated( const QDomElement& e );
    QString getDatabaseInfo( const QDomElement& e, const QString& tag );
    void createFormImpl( const QDomElement& e, const QString& form, const QString& connection, const QString& table );
    void writeFunctionsSubImpl( const QStringList &fuLst, const QStringList &typLst, const QStringList &specLst,
                                const QString &subClass, const QString &descr );
    QStringList dbConnections;
    QMap< QString, QStringList > dbCursors;
    QMap< QString, QStringList > dbForms;

    static bool isMainWindow;
    static QString mkBool( bool b );
    static QString mkBool( const QString& s );
    bool toBool( const QString& s );
    static QString fixString( const QString &str, bool encode = FALSE );
    static bool onlyAscii;
    static QString mkStdSet( const QString& prop );
    static QString getComment( const QDomNode& n );
    QVariant defSpacing, defMargin;
    QString fileName;
    bool writeFunctImpl;

    void perlSlot(QStringList::Iterator &it);
};

#endif
