/**********************************************************************
** Copyright (C) 2000 Trolltech AS.  All rights reserved.
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

#include "uic.h"
#include "parser.h"
#include "widgetinterface.h"
#include "widgetdatabase.h"
#include "domtool.h"
#include <qregexp.h>
#include <qsizepolicy.h>
#include <qstringlist.h>
#define NO_STATIC_COLORS
#include <globaldefs.h>

/*!
  Creates a declaration for the object given in \a e.

  Children are not traversed recursively.

  \sa createObjectImpl()
 */
void Uic::createObjectDecl( const QDomElement& e )
{
    if ( e.tagName() == "vbox" || e.tagName() == "hbox" || e.tagName() == "grid" ) {
	out << indent << registerObject(getLayoutName(e) ) << endl;
    } else {
	QString objClass = getClassName( e );
	if ( objClass.isEmpty() )
	    return;
	QString objName = getObjectName( e );
	if ( objName.isEmpty() )
	    return;
	// ignore QLayoutWidgets
	if ( objClass == "Qt::LayoutWidget" )
	    return;

        // register the object and unify its name
	objName = registerObject( objName );
	out << indent << objName << endl;
    }
}

/*!
  Creates a PerlQt attribute declaration for the object given in \a e.

  Children are not traversed recursively.

 */
void Uic::createAttrDecl( const QDomElement& e )
{
    if ( e.tagName() == "vbox" || e.tagName() == "hbox" || e.tagName() == "grid" ) {
	out << indent << registerObject(getLayoutName(e) ) << endl;
    } else {
	QString objClass = getClassName( e );
	if ( objClass.isEmpty() )
	    return;
	QString objName = getObjectName( e );
	if ( objName.isEmpty() )
	    return;
	// ignore QLayoutWidgets
	if ( objClass == "Qt::LayoutWidget" )
	    return;
        // register the object and unify its name
	objName = registerObject( objName );
	out << indent << objName << endl;
        QDomElement n = getObjectProperty( e, "font");
	if ( !n.isNull() )
            out << indent << objName + "_font" << endl;
    }
}


/*!
  Creates an implementation for the object given in \a e.

  Traverses recursively over all children.

  Returns the name of the generated child object.

  \sa createObjectDecl()
 */

static bool createdCentralWidget = FALSE;

QString Uic::createObjectImpl( const QDomElement &e, const QString& parentClass, const QString& par, const QString& layout )
{
    QString parent( par );
    if ( parent == "this" && isMainWindow ) {
	if ( !createdCentralWidget )
	    out << indent << "setCentralWidget(Qt::Widget(this, \"qt_central_widget\"));" << endl;
	createdCentralWidget = TRUE;
	parent = "centralWidget()";
    }
    QDomElement n;
    QString objClass, objName;
    int numItems = 0;
    int numColumns = 0;
    int numRows = 0;

    if ( layouts.contains( e.tagName() ) )
	return createLayoutImpl( e, parentClass, parent, layout );

    objClass = getClassName( e );
    if ( objClass.isEmpty() )
	return objName;
    objName = getObjectName( e );

    QString definedName = objName;
    bool isTmpObject = objName.isEmpty() || objClass == "Qt::LayoutWidget";
    if ( isTmpObject ) {
	if ( objClass[0] == 'Q' )
	    objName = "$" + objClass.mid( 4 );
	else
	    objName = "$" + objClass.lower();
    }

    bool isLine = objClass == "Line";
    if ( isLine )
	objClass = "Qt::Frame";

    out << endl;
    if ( objClass == "Qt::LayoutWidget" ) {
	if ( layout.isEmpty() ) {
	    // register the object and unify its name
	    objName = registerObject( objName );
	    out << indent << (isTmpObject ? QString::fromLatin1("my ") : QString::null) << objName << " = Qt::Widget(" << parent << ", '" << objName << "');" << endl;
	} else {
	    // the layout widget is not necessary, hide it by creating its child in the parent
	    QString result;
	    for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
		if (tags.contains( n.tagName() ) )
		    result = createObjectImpl( n, parentClass, parent, layout );
	    }
	    return result;
	}

    } else if ( objClass != "Qt::ToolBar" && objClass != "Qt::MenuBar" ) {
	// register the object and unify its name
	objName = registerObject( objName );

	// Temporary objects don't go into the class instance dictionary.

	out << indent << (isTmpObject ? QString("my ") : QString::null) << objName << " = " << createObjectInstance( objClass, parent, objName ) << ";" << endl;
    }

    if ( objClass == "Qt::AxWidget" ) {
	QString controlId;
	for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
	    if ( n.tagName() == "property" && n.attribute( "name" ) == "control" ) {
		controlId = n.firstChild().toElement().text();
	    }
	}
	out << indent << objName << "->setControl(\"" << controlId << "\");" << endl;
    }

    lastItem = "undef";
    // set the properties and insert items
    bool hadFrameShadow = FALSE;
    for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
	if ( n.tagName() == "property" ) {
	    bool stdset = stdsetdef;
	    if ( n.hasAttribute( "stdset" ) )
		stdset = toBool( n.attribute( "stdset" ) );
	    QString prop = n.attribute( "name" );
            if ( prop == "database" )
                continue;
	    QString value = setObjectProperty( objClass, objName, prop, n.firstChild().toElement(), stdset );
	    if ( value.isEmpty() )
		continue;
	    if ( prop == "name" )
		continue;
	    if ( isLine && prop == "frameShadow" )
		hadFrameShadow = TRUE;
	    if ( prop == "buddy" && value.startsWith("\"") && value.endsWith("\"") ) {
		buddies << Buddy( objName, value.mid(1, value.length() - 2 ) );
		continue;
	    }
	    if ( isLine && prop == "orientation" ) {
		prop = "frameShape";
		if ( value.right(10) == "Horizontal" )
		    value = "&Qt::Frame::HLine";
		else
		    value = "&Qt::Frame::VLine";
		if ( !hadFrameShadow ) {
		    prop = "frameStyle";
		    value += " | &Qt::Frame::Sunken";
		}
	    }
	    if ( prop == "buttonGroupId" ) {
		if ( parentClass == "Qt::ButtonGroup" )
		    out << indent << parent << "->insert( " << objName << "," << value << ");" << endl;
		continue;
	    }
	    if ( prop == "frameworkCode" )
		continue;
	    if ( objClass == "Qt::MultiLineEdit" &&
		 QRegExp("echoMode|hMargin|maxLength|maxLines|undoEnabled").exactMatch(prop) )
		continue;

	    QString call = objName + "->";
	    bool needClose = false;
	    if ( stdset ) {
		call += mkStdSet( prop ) + "( ";
	    } else {
		call += "setProperty( \"" + prop + "\", Qt::Variant(" ;
		needClose = true;
	    }
	    if ( prop == "accel" )
		call += "Qt::KeySequence( " + value + " )"+ (needClose ? " )": "") + " );";
	    else
		call += value + (needClose ? " )": "") + " );";

	    if ( n.firstChild().toElement().tagName() == "string" ||
		 prop == "currentItem" ) {
		trout << indent << call << endl;
	    } else {
		out << indent << call << endl;
	    }
	} else if ( n.tagName() == "item" ) {
	    QString call;
	    QString value;

	    if ( objClass.mid( 4 ) == "ListBox" ) {
		call = createListBoxItemImpl( n, objName );
		if ( !call.isEmpty() ) {
		    if ( numItems == 0 )
			trout << indent << objName << "->clear();" << endl;
		    trout << indent << call << endl;
		}
	    } else if ( objClass.mid( 4 ) == "ComboBox" ) {
		call = createListBoxItemImpl( n, objName, &value );
		if ( !call.isEmpty() ) {
		    if ( numItems == 0 )
			trout << indent << objName << "->clear();" << endl;
		    trout << indent << call << endl;
		}
	    } else if ( objClass.mid( 4 ) == "IconView" ) {
		call = createIconViewItemImpl( n, objName );
		if ( !call.isEmpty() ) {
		    if ( numItems == 0 )
			trout << indent << objName << "->clear();" << endl;
		    trout << indent << call << endl;
		}
	    } else if ( objClass.mid( 4 ) == "ListView" ) {
		call = createListViewItemImpl( n, objName, QString::null );
		if ( !call.isEmpty() ) {
		    if ( numItems == 0 )
			trout << indent << objName << "->clear();" << endl;
		    trout << call << endl;
		}
	    }
	    if ( !call.isEmpty() )
		numItems++;
	} else if ( n.tagName() == "column" || n.tagName() == "row" ) {
	    QString call;
	    QString value;

	    if ( objClass.mid( 4 ) == "ListView" ) {
		call = createListViewColumnImpl( n, objName, &value );
		if ( !call.isEmpty() ) {
		    out << call;
		    trout << indent << objName << "->header()->setLabel( "
			  << numColumns++ << ", " << value << " );\n";
		}
	    } else if ( objClass ==  "Qt::Table" || objClass == "Qt::DataTable" ) {
		bool isCols = ( n.tagName() == "column" );
		call = createTableRowColumnImpl( n, objName, &value );
		if ( !call.isEmpty() ) {
		    out << call;
		    trout << indent << objName << "->"
			  << ( isCols ? "horizontalHeader" : "verticalHeader" )
			  << "()->setLabel( "
			  << ( isCols ? numColumns++ : numRows++ )
			  << ", " << value << " );\n";
		}
	    }
	}
    }

    // create all children, some widgets have special requirements

    if ( objClass == "Qt::TabWidget" ) {
	for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
	    if ( tags.contains( n.tagName()  ) ) {
		QString page = createObjectImpl( n, objClass, objName );
		QString comment;
		QString label = DomTool::readAttribute( n, "title", "", comment ).toString();
		out << indent << objName << "->insertTab( " << page << ", \"\" );" << endl;
		trout << indent << objName << "->changeTab( " << page << ", "
		      << trcall( label, comment ) << " );" << endl;
	    }
	}
    } else if ( objClass == "Qt::WidgetStack" ) {
	for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
	    if ( tags.contains( n.tagName()  ) ) {
		QString page = createObjectImpl( n, objClass, objName );
		int id = DomTool::readAttribute( n, "id", "" ).toInt();
		out << indent << objName << "->addWidget( " << page << ", " << id << " );" << endl;
	    }
	}
    } else if ( objClass == "Qt::ToolBox" ) {
 	for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
	    if ( tags.contains( n.tagName()  ) ) {
		QString page = createObjectImpl( n, objClass, objName );
		QString label = DomTool::readAttribute( n, "label", "" ).toString();
		out << indent << objName << "->addItem( " << page << ", \"" << label << "\" );" << endl;
	    }
 	}
     } else if ( objClass != "Qt::ToolBar" && objClass != "Qt::MenuBar" ) { // standard widgets
	 WidgetInterface *iface = 0;
	 QString QtObjClass = objClass;
	 QtObjClass.replace( QRegExp("^Qt::"), "Q" );
	 QtObjClass.replace( QRegExp("^KDE::"), "K" );
	 widgetManager()->queryInterface( QtObjClass, &iface );
#ifdef QT_CONTAINER_CUSTOM_WIDGETS
	 int id = WidgetDatabase::idFromClassName( QtObjClass );
	 if ( WidgetDatabase::isContainer( id ) && WidgetDatabase::isCustomPluginWidget( id ) && iface ) {
	     QWidgetContainerInterfacePrivate *iface2 = 0;
	     iface->queryInterface( IID_QWidgetContainer, (QUnknownInterface**)&iface2 );
	     if ( iface2 ) {
		 bool supportsPages = iface2->supportsPages( QtObjClass );
		 for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
		     if ( tags.contains( n.tagName()  ) ) {
			 if ( supportsPages ) {
			     QString page = createObjectImpl( n, objClass, objName );
			     QString comment;
			     QString label = DomTool::readAttribute( n, "label", "", comment ).toString();
			     out << indent << iface2->createCode( objClass, objName, page, label ) << endl;
			 } else {
			     createObjectImpl( n, objClass, objName );
			 }
		     }
		 }
		 iface2->release();
	     }
	     iface->release();
	 } else {
#endif
	     for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
		 if ( tags.contains( n.tagName() ) )
		     createObjectImpl( n, objClass, objName );
	     }
#ifdef QT_CONTAINER_CUSTOM_WIDGETS
	 }
#endif
    }

    return objName;
}



/*!
  Creates a set-call for property \a exclusiveProp of the object
  given in \a e.

  If the object does not have this property, the function does nothing.

  Exclusive properties are used to generate the implementation of
  application font or palette change handlers in createFormImpl().

 */
void Uic::createExclusiveProperty( const QDomElement & e, const QString& exclusiveProp )
{
    QDomElement n;
    QString objClass = getClassName( e );
    if ( objClass.isEmpty() )
	return;
    QString objName = getObjectName( e );
#if 0 // it's not clear whether this check should be here or not
    if ( objName.isEmpty() )
 	return;
#endif
    for ( n = e.firstChild().toElement(); !n.isNull(); n = n.nextSibling().toElement() ) {
	if ( n.tagName() == "property" ) {
	    bool stdset = stdsetdef;
	    if ( n.hasAttribute( "stdset" ) )
		stdset = toBool( n.attribute( "stdset" ) );
	    QString prop = n.attribute( "name" );
	    if ( prop != exclusiveProp )
		continue;
	    QString value = setObjectProperty( objClass, objName, prop, n.firstChild().toElement(), stdset );
	    if ( value.isEmpty() )
		continue;
	    // we assume the property isn't of type 'string'
	    ++indent;
	    out << indent << objName << "->setProperty(\"" << prop << "\", Qt::Variant(" << value << "));" << endl;
	    --indent;
	}
    }
}


/*!  Attention: this function has to be in sync with
  Resource::saveProperty() and DomTool::elementToVariant. If you
  change one, change all.
 */
QString Uic::setObjectProperty( const QString& objClass, const QString& obj, const QString &prop, const QDomElement &e, bool stdset )
{
    QString v;
    if ( e.tagName() == "rect" ) {
	QDomElement n3 = e.firstChild().toElement();
	int x = 0, y = 0, w = 0, h = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "x" )
		x = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "y" )
		y = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "width" )
		w = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "height" )
		h = n3.firstChild().toText().data().toInt();
	    n3 = n3.nextSibling().toElement();
	}
	v = "Qt::Rect(%1, %2, %3, %4)";
	v = v.arg(x).arg(y).arg(w).arg(h);

    } else if ( e.tagName() == "point" ) {
	QDomElement n3 = e.firstChild().toElement();
	int x = 0, y = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "x" )
		x = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "y" )
		y = n3.firstChild().toText().data().toInt();
	    n3 = n3.nextSibling().toElement();
	}
	v = "Qt::Point(%1, %2)";
	v = v.arg(x).arg(y);
    } else if ( e.tagName() == "size" ) {
	QDomElement n3 = e.firstChild().toElement();
	int w = 0, h = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "width" )
		w = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "height" )
		h = n3.firstChild().toText().data().toInt();
	    n3 = n3.nextSibling().toElement();
	}
	v = "Qt::Size(%1, %2)";
	v = v.arg(w).arg(h);
    } else if ( e.tagName() == "color" ) {
	QDomElement n3 = e.firstChild().toElement();
	int r = 0, g = 0, b = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "red" )
		r = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "green" )
		g = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "blue" )
		b = n3.firstChild().toText().data().toInt();
	    n3 = n3.nextSibling().toElement();
	}
	v = "Qt::Color(%1, %2, %3)";
	v = v.arg(r).arg(g).arg(b);
    } else if ( e.tagName() == "font" ) {
	QDomElement n3 = e.firstChild().toElement();
	QString attrname = e.parentNode().toElement().attribute( "name", "font" );
	QString fontname;
	if ( !obj.isEmpty() ) {
	    fontname = registerObject( "$" + obj + "_" + attrname );
	    out << indent << "my " << fontname << " = Qt::Font(" << obj << "->font);" << endl;
	} else {
	    fontname = "$" + registerObject( "font" );
	    out << indent << "my " << fontname << " = Qt::Font(this->font);" << endl;
	}
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "family" )
		out << indent << fontname << "->setFamily(\"" << n3.firstChild().toText().data() << "\");" << endl;
	    else if ( n3.tagName() == "pointsize" )
		out << indent << fontname << "->setPointSize(" << n3.firstChild().toText().data() << ");" << endl;
	    else if ( n3.tagName() == "bold" )
		out << indent << fontname << "->setBold(" << mkBool( n3.firstChild().toText().data() ) << ");" << endl;
	    else if ( n3.tagName() == "italic" )
		out << indent << fontname << "->setItalic(" << mkBool( n3.firstChild().toText().data() ) << ");" << endl;
	    else if ( n3.tagName() == "underline" )
		out << indent << fontname << "->setUnderline(" << mkBool( n3.firstChild().toText().data() ) << ");" << endl;
	    else if ( n3.tagName() == "strikeout" )
		out << indent << fontname << "->setStrikeOut(" << mkBool( n3.firstChild().toText().data() ) << ");" << endl;
	    n3 = n3.nextSibling().toElement();
	}

	if ( prop == "font" ) {
	    if ( !obj.isEmpty() )
		out << indent << obj << "->setFont(" << fontname << ");" << endl;
	    else
		out << indent << "setFont(" << fontname << ");" << endl;
	} else {
	    v = fontname;
	}
    } else if ( e.tagName() == "string" ) {
	QString txt = e.firstChild().toText().data();
	QString com = getComment( e.parentNode() );

	if ( prop == "toolTip" && objClass != "Qt::Action" && objClass != "Qt::ActionGroup" ) {
	    if ( !obj.isEmpty() )
		trout << indent << "Qt::ToolTip::add(" << obj << ", "
		    << trcall( txt, com ) << ");" << endl;
	    else
		out << indent << "Qt::ToolTip::add( this, "
		    << trcall( txt, com ) << ");" << endl;
	} else if ( prop == "whatsThis" && objClass != "Qt::Action" && objClass != "Qt::ActionGroup" ) {
	    if ( !obj.isEmpty() )
		trout << indent << "Qt::WhatsThis::add(" << obj << ", "
		    << trcall( txt, com ) << ");" << endl;
	    else
		trout << indent << "Qt::WhatsThis::add( this,"
		      << trcall( txt, com ) << ");" << endl;
        } else {
	    v = trcall( txt, com );
	}
    } else if ( e.tagName() == "cstring" ) {
	    v = "\"%1\"";
	    v = v.arg( e.firstChild().toText().data() );
    } else if ( e.tagName() == "number" ) {
	v = "int(%1)";
	v = v.arg( e.firstChild().toText().data() );
    } else if ( e.tagName() == "bool" ) {
	if ( stdset )
	    v = "%1";
	else
	    v = "Qt::Variant(%1, 0)";
	v = v.arg( mkBool( e.firstChild().toText().data() ) );
    } else if ( e.tagName() == "pixmap" ) {
	v = e.firstChild().toText().data();
        if( !externPixmaps )
        	v.prepend( '$' );
	if ( !pixmapLoaderFunction.isEmpty() ) {
	    v.prepend( pixmapLoaderFunction + "(" + QString( externPixmaps ? "\"" : "" ) );
	    v.append( QString( externPixmaps ? "\"" : "" ) + ")" );
	}
    } else if ( e.tagName() == "iconset" ) {
	v = "Qt::IconSet(%1)";
	QString s = e.firstChild().toText().data();
        if( !externPixmaps )
        	s.prepend( '$' );
	if ( !pixmapLoaderFunction.isEmpty() ) {
	    s.prepend( pixmapLoaderFunction + "(" + QString( externPixmaps ? "\"" : "" ) );
	    s.append( QString( externPixmaps ? "\"" : "" ) + ")" );
	}
	v = v.arg( s );
    } else if ( e.tagName() == "image" ) {
	v = e.firstChild().toText().data() + "->convertToImage()";
    } else if ( e.tagName() == "enum" ) {
	if ( stdset )
	    v = "&%1::%2()";
	else
	    v = "\"%1\"";
	QString oc = objClass;
	QString ev = e.firstChild().toText().data();
	if ( oc == "Qt::ListView" && ev == "Manual" ) // #### workaround, rename QListView::Manual in 4.0
	    oc = "Qt::ScrollView";
	if ( stdset )
	    v = v.arg( oc ).arg( ev );
	else
	    v = v.arg( ev );
    } else if ( e.tagName() == "set" ) {
	QString keys( e.firstChild().toText().data() );
	QStringList lst = QStringList::split( '|', keys );
	v = "int(&";
	QStringList::Iterator it = lst.begin();
	while ( it != lst.end() ) {
	    v += objClass + "::" + *it;
	    if ( it != lst.fromLast() )
		v += " | &";
	    ++it;
	}
        v += ")";
    } else if ( e.tagName() == "sizepolicy" ) {
	QDomElement n3 = e.firstChild().toElement();
	QSizePolicy sp;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "hsizetype" )
		sp.setHorData( (QSizePolicy::SizeType)n3.firstChild().toText().data().toInt() );
	    else if ( n3.tagName() == "vsizetype" )
		sp.setVerData( (QSizePolicy::SizeType)n3.firstChild().toText().data().toInt() );
	    else if ( n3.tagName() == "horstretch" )
		sp.setHorStretch( n3.firstChild().toText().data().toInt() );
	    else if ( n3.tagName() == "verstretch" )
		sp.setVerStretch( n3.firstChild().toText().data().toInt() );
	    n3 = n3.nextSibling().toElement();
	}
	QString tmp = (obj.isEmpty() ? QString::fromLatin1("this") : obj) + "->";
	v = "Qt::SizePolicy(%1, %2, %3, %4, " + tmp + "sizePolicy()->hasHeightForWidth())";
	v = v.arg( (int)sp.horData() ).arg( (int)sp.verData() ).arg( sp.horStretch() ).arg( sp.verStretch() );
    } else if ( e.tagName() == "palette" ) {
	QPalette pal;
	bool no_pixmaps = e.elementsByTagName( "pixmap" ).count() == 0;
	QDomElement n;
	if ( no_pixmaps ) {
	    n = e.firstChild().toElement();
	    while ( !n.isNull() ) {
		QColorGroup cg;
		if ( n.tagName() == "active" ) {
		    cg = loadColorGroup( n );
		    pal.setActive( cg );
		} else if ( n.tagName() == "inactive" ) {
		    cg = loadColorGroup( n );
		    pal.setInactive( cg );
		} else if ( n.tagName() == "disabled" ) {
		    cg = loadColorGroup( n );
		    pal.setDisabled( cg );
		}
		n = n.nextSibling().toElement();
	    }
	}
	if ( no_pixmaps && pal == QPalette( pal.active().button(), pal.active().background() ) ) {
	    v = "Qt::Palette(Qt::Color(%1,%2,%3), Qt::Color(%1,%2,%3))";
	    v = v.arg( pal.active().button().red() ).arg( pal.active().button().green() ).arg( pal.active().button().blue() );
	    v = v.arg( pal.active().background().red() ).arg( pal.active().background().green() ).arg( pal.active().background().blue() );
	} else {
	    QString palette = "pal";
	    if ( !pal_used ) {
		out << indent << palette << " = Qt::Palette();" << endl;
		pal_used = TRUE;
	    }
	    QString cg = "cg";
	    if ( !cg_used ) {
		out << indent << cg << " = Qt::ColorGroup();" << endl;
		cg_used = TRUE;
	    }
	    n = e.firstChild().toElement();
	    while ( !n.isNull() && n.tagName() != "active" )
		n = n.nextSibling().toElement();
	    createColorGroupImpl( cg, n );
	    out << indent << palette << "->setActive(" << cg << ");" << endl;

	    n = e.firstChild().toElement();
	    while ( !n.isNull() && n.tagName() != "inactive" )
		n = n.nextSibling().toElement();
	    createColorGroupImpl( cg, n );
	    out << indent << palette << "->setInactive(" << cg << ");" << endl;

	    n = e.firstChild().toElement();
	    while ( !n.isNull() && n.tagName() != "disabled" )
		n = n.nextSibling().toElement();
	    createColorGroupImpl( cg, n );
	    out << indent << palette << "->setDisabled(" << cg << ");" << endl;
	    v = palette;
	}
    } else if ( e.tagName() == "cursor" ) {
	v = "Qt::Cursor(%1)";
	v = v.arg( e.firstChild().toText().data() );
    } else if ( e.tagName() == "date" ) {
	QDomElement n3 = e.firstChild().toElement();
	int y, m, d;
	y = m = d = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "year" )
		y = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "month" )
		m = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "day" )
		d = n3.firstChild().toText().data().toInt();
	    n3 = n3.nextSibling().toElement();
	}
	v = "Qt::Date(%1,%2,%3)";
	v = v.arg(y).arg(m).arg(d);
    } else if ( e.tagName() == "time" ) {
	QDomElement n3 = e.firstChild().toElement();
	int h, m, s;
	h = m = s = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "hour" )
		h = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "minute" )
		m = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "second" )
		s = n3.firstChild().toText().data().toInt();
	    n3 = n3.nextSibling().toElement();
	}
	v = "Qt::Time(%1, %2, %3)";
	v = v.arg(h).arg(m).arg(s);
    } else if ( e.tagName() == "datetime" ) {
	QDomElement n3 = e.firstChild().toElement();
	int h, mi, s, y, mo, d;
	h = mi = s = y = mo = d = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "hour" )
		h = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "minute" )
		mi = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "second" )
		s = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "year" )
		y = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "month" )
		mo = n3.firstChild().toText().data().toInt();
	    else if ( n3.tagName() == "day" )
		d = n3.firstChild().toText().data().toInt();
	    n3 = n3.nextSibling().toElement();
	}
	v = "Qt::DateTime(Qt::Date(%1, %2, %3), Qt::Time(%4, %5, %6))";
	v = v.arg(y).arg(mo).arg(d).arg(h).arg(mi).arg(s);
    } else if ( e.tagName() == "stringlist" ) {
	QStringList l;
	QDomElement n3 = e.firstChild().toElement();
	QString listname;
	if ( !obj.isEmpty() ) {
	    listname = obj + "->{_strlist";
	    listname = registerObject( listname );
            listname += "}";
	    out << indent << listname << " = [";
	} else {
            listname = registerObject( "$" + listname );
	    out << indent << "my " << listname << " = [";
	}
        int i = 0;
	while ( !n3.isNull() ) {
	    if ( n3.tagName() == "string" )
            {
		out << "'" << n3.firstChild().toText().data().simplifyWhiteSpace() << "'";
		n3 = n3.nextSibling().toElement();
		if( n3.isNull() )
		    break;
                i++;
                if( (i%3) == 0 )
                {
                    ++indent;
                    out << "," << endl << indent;
                    --indent;
                }
                else
                    out << ", ";
	    }
	    else
	    	n3 = n3.nextSibling().toElement();
	}
        out << "];" << endl;
	v = listname;
    }
    return v;
}




/*! Extracts a named object property from \a e.
 */
QDomElement Uic::getObjectProperty( const QDomElement& e, const QString& name )
{
    QDomElement n;
    for ( n = e.firstChild().toElement();
	  !n.isNull();
	  n = n.nextSibling().toElement() ) {
	if ( n.tagName() == "property"  && n.toElement().attribute("name") == name )
	    return n;
    }
    return n;
}

