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
#include "widgetdatabase.h"
#include "domtool.h"
#include <qfile.h>
#include <qstringlist.h>
#include <qdatetime.h>
#define NO_STATIC_COLORS
#include <globaldefs.h>
#include <qregexp.h>
#include <stdio.h>
#include <stdlib.h>


/*!
  Creates an implementation for a subclass \a subClass of the form
  given in \a e

  \sa createSubDecl()
 */
void Uic::createSubImpl( const QDomElement &e, const QString& subClass )
{
    QDomElement n;
    QDomNodeList nl;
    int i;

    QString objClass = getClassName( e );
    if ( objClass.isEmpty() )
	return;
    out << indent << "package " << subClass << ";" << endl;
    out << indent << "use Qt;" << endl;
    out << indent << "use " << nameOfClass << ";" << endl;
    out << indent << "use Qt::isa qw("<< nameOfClass << ");" << endl;

    out << endl;

    // constructor
    out << indent << "sub NEW" << endl;
    out << indent << "{" << endl;
    ++indent;
    if ( objClass == "Qt::Dialog" || objClass == "Qt::Wizard" ) {
	out << indent << "shift->SUPER::NEW(@_[0..3]);" << endl;
    } else if ( objClass == "Qt::Widget")  {
	out << indent << "shift->SUPER::NEW(@_[0..2]);" << endl;
    } else if ( objClass == "Qt::MainWindow" ) {
	out << indent << "shift->SUPER::NEW(@_[0..2]);" << endl;
	out << indent << "statusBar();" << endl;
	isMainWindow = TRUE;
    } else {
	out << indent << "shift->SUPER::NEW(@_[0,1]);" << endl;
    }
    --indent;
    out << indent << "}" << endl;
    out << endl;

    // find additional functions
    QStringList publicSlots, protectedSlots, privateSlots;
    QStringList publicSlotTypes, protectedSlotTypes, privateSlotTypes;
    QStringList publicSlotSpecifier, protectedSlotSpecifier, privateSlotSpecifier;
    QStringList publicFuncts, protectedFuncts, privateFuncts;
    QStringList publicFunctRetTyp, protectedFunctRetTyp, privateFunctRetTyp;
    QStringList publicFunctSpec, protectedFunctSpec, privateFunctSpec;


    nl = e.parentNode().toElement().elementsByTagName( "slot" );
    for ( i = 0; i < (int) nl.length(); i++ ) {
	n = nl.item(i).toElement();
	if ( n.parentNode().toElement().tagName() != "slots"
	     && n.parentNode().toElement().tagName() != "connections" )
	    continue;
        QString l = n.attribute( "language", "C++" );
	if ( l != "C++" && l != "Perl" ) //- mmh
	    continue;
	QString returnType = n.attribute( "returnType", "void" );
	QString functionName = n.firstChild().toText().data().stripWhiteSpace();
	if ( functionName.endsWith( ";" ) )
	    functionName = functionName.left( functionName.length() - 1 );
	QString specifier = n.attribute( "specifier" );
	QString access = n.attribute( "access" );
	if ( access == "protected" ) {
	    protectedSlots += functionName;
	    protectedSlotTypes += returnType;
	    protectedSlotSpecifier += specifier;
	} else if ( access == "private" ) {
	    privateSlots += functionName;
	    privateSlotTypes += returnType;
	    privateSlotSpecifier += specifier;
	} else {
	    publicSlots += functionName;
	    publicSlotTypes += returnType;
	    publicSlotSpecifier += specifier;
	}
    }

    nl = e.parentNode().toElement().elementsByTagName( "function" );
    for ( i = 0; i < (int) nl.length(); i++ ) {
	n = nl.item(i).toElement();
	QString fname = n.attribute( "name" );
	fname = Parser::cleanArgs( fname );
	if ( n.parentNode().toElement().tagName() != "functions" )
	    continue;
        QString l = n.attribute( "language", "C++" );
	if ( l != "C++" && l != "Perl" ) //- mmh
	    continue;
	QString returnType = n.attribute( "returnType", "void" );
	QString functionName = n.firstChild().toText().data().stripWhiteSpace();
	if ( functionName.endsWith( ";" ) )
	    functionName = functionName.left( functionName.length() - 1 );
	QString specifier = n.attribute( "specifier" );
	QString access = n.attribute( "access" );
	if ( access == "protected" ) {
	    protectedFuncts += functionName;
	    protectedFunctRetTyp += returnType;
	    protectedFunctSpec += specifier;
	} else if ( access == "private" ) {
	    privateFuncts += functionName;
	    privateFunctRetTyp += returnType;
	    privateFunctSpec += specifier;
	} else {
	    publicFuncts += functionName;
	    publicFunctRetTyp += returnType;
	    publicFunctSpec += specifier;
	}
    }

    // FIXME PerlQt: distinguishing public/protected/private slots does not make any sense in the forseable future
    //        but nevermind, never forget somewhere far beyond the sky, Ashley Winters is furbishing *Plan 42* ! :)

    if ( !publicFuncts.isEmpty() )
	writeFunctionsSubImpl( publicFuncts, publicFunctRetTyp, publicFunctSpec, subClass, "public function" );

    if ( !publicSlots.isEmpty() )
	writeFunctionsSubImpl( publicSlots, publicSlotTypes, publicSlotSpecifier, subClass, "public slot" );

    if ( !protectedFuncts.isEmpty() )
	writeFunctionsSubImpl( protectedFuncts, protectedFunctRetTyp, protectedFunctSpec, subClass, "protected function" );

    if ( !protectedSlots.isEmpty() )
	writeFunctionsSubImpl( protectedSlots, protectedSlotTypes, protectedSlotSpecifier, subClass, "protected slot" );

    if ( !privateFuncts.isEmpty() )
	writeFunctionsSubImpl( privateFuncts, privateFunctRetTyp, privateFunctSpec, subClass, "private function" );

    if ( !privateSlots.isEmpty() )
	writeFunctionsSubImpl( privateSlots, privateSlotTypes, privateSlotSpecifier, subClass, "private slot" );

    out << "1;" << endl;
}

void Uic::writeFunctionsSubImpl( const QStringList &fuLst, const QStringList &typLst, const QStringList &specLst,
				 const QString &subClass, const QString &descr )
{
    QValueListConstIterator<QString> it, it2, it3;
    for ( it = fuLst.begin(), it2 = typLst.begin(), it3 = specLst.begin();
	  it != fuLst.end(); ++it, ++it2, ++it3 ) {
	QString type = *it2;
	if ( type.isEmpty() )
	    type = "void";
	if ( *it3 == "non virtual" )
	    continue;
        out << endl;
	int astart = (*it).find('(');
	out << indent << "sub " << (*it).left(astart)<< endl;
	out << indent << "{" << endl;
	++indent;
	out << indent << "print \"" << subClass << "->" << (*it) << ": (Private) Not implemented yet.\\n\";" << endl;
	--indent;
        out << indent << "}" << endl;
    }
    out << endl;
}
