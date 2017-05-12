/**********************************************************************
** Copyright (C) 2000 Trolltech AS.  All rights reserved.
** Copyright (c) 2001 Phil Thompson <phil@river-bank.demon.co.uk>
** Copyright (c) 2002 Germain Garand <germain@ebooksfrance.com>
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
/*
** 06/2002 : Initial release of puic, the PerlQt User Interface Compiler,
**           a work derivated from uic (the Qt User Interface Compiler)
**           and pyuic (the PyQt User Interface Compiler).
**
**           G.Garand
**
**********************************************************************/
#include "uic.h"
#include "parser.h"
#include "widgetdatabase.h"
#include "domtool.h"
#include <qapplication.h>
#include <qfile.h>
#include <qstringlist.h>
#include <qdatetime.h>
#define NO_STATIC_COLORS
#include <globaldefs.h>
#include <stdio.h>
#include <stdlib.h>
#define PUIC_VERSION "0.70"

void getDBConnections( Uic& uic, QString& s);

int main( int argc, char * argv[] )
{
    PyIndent indent;
    bool execCode = FALSE;
    bool subcl = FALSE;
    bool imagecollection = FALSE;
    bool imagecollection_tmpfile = FALSE;
    QStringList images;
    const char *error = 0;
    const char* fileName = 0;
    const char* className = 0;
    QCString outputFile;
    QCString image_tmpfile;
    const char* projectName = 0;
    const char* trmacro = 0;
    bool nofwd = FALSE;
    bool fix = FALSE;
    QApplication app(argc, argv, FALSE);
    QString uicClass;


    for ( int n = 1; n < argc && error == 0; n++ ) {
	QCString arg = argv[n];
	if ( arg[0] == '-' ) {			// option
	    QCString opt = &arg[1];
	    if ( opt[0] == 'o' ) {		// output redirection
		if ( opt[1] == '\0' ) {
		    if ( !(n < argc-2) ) {
			error = "Missing output-file name";
			break;
		    }
		    outputFile = argv[++n];
		} else
		    outputFile = &opt[1];
	    } else if ( opt[0] == 'e' || opt == "embed" ) {
		imagecollection = TRUE;
		if ( opt == "embed" || opt[1] == '\0' ) {
		    if ( !(n < argc-2) ) {
			error = "Missing arguments.";
			break;
		    }
		    projectName = argv[++n];
		} else {
		    projectName = &opt[1];
		}
		if ( argc > n+1 && qstrcmp( argv[n+1], "-f" ) == 0 ) {
		    imagecollection_tmpfile = TRUE;
		    image_tmpfile = argv[n+2];
		    n += 2;
		}
	    } else if ( opt == "nofwd" ) {
		nofwd = TRUE;
	    } else if ( opt == "subimpl" ) {
		subcl = TRUE;
		if ( !(n < argc-2) ) {
		    error = "Missing arguments.";
		    break;
		}
		className = argv[++n];
	    } else if ( opt == "tr" ) {
		if ( opt == "tr" || opt[1] == '\0' ) {
		    if ( !(n < argc-1) ) {
			error = "Missing tr function.";
			break;
		    }
		    trmacro = argv[++n];
		} else {
		    trmacro = &opt[1];
		}
	    } else if ( opt == "version" ) {
		fprintf( stderr,
			 "PerlQt User Interface Compiler v%s for Qt version %s\n", PUIC_VERSION,
			 QT_VERSION_STR );
		exit( 1 );
	    } else if ( opt == "help" ) {
		break;
	    } else if ( opt == "fix" ) {
		fix = TRUE;
	    } else if ( opt[0] == 'p' ) {
		uint tabstop;
		bool ok;

		if ( opt[1] == '\0' ) {
		    if ( !(n < argc-1) ) {
			error = "Missing indent";
			break;
		    }
		    tabstop = QCString(argv[++n]).toUInt(&ok);
		} else
		    tabstop = opt.mid(1).toUInt(&ok);

		if (ok)
		    indent.setTabStop(tabstop);
		else
		    error = "Invalid indent";
	    } else if ( opt == "x" ) {
		execCode = TRUE;
	    } else {
		error = QString( "Unrecognized option " + opt ).latin1();
	    }
	} else {
	    if ( imagecollection && !imagecollection_tmpfile )
		images << argv[n];
	    else if ( fileName )		// can handle only one file
		error	 = "Too many input files specified";
	    else
		fileName = argv[n];
	}
    }

    if ( argc < 2 || error || (!fileName && !imagecollection ) ) {
	fprintf( stderr, "PerlQt user interface compiler.\n" );
	if ( error )
	    fprintf( stderr, "puic: %s\n", error );

	fprintf( stderr, "Usage: %s  [options] [mode] <uifile>\n"
		 "\nGenerate implementation:\n"
		 "   %s  [options] <uifile>\n"
		 "Generate image collection:\n"
		 "   %s  [options] -embed <project> <image1> <image2> <image3> ...\n"
		 "\t<project>\tproject name\n"
		 "\t<image[0..n]>\timage files\n"
		 "or\n"
		 "   %s  [options] -embed <project> -f <file>\n"
		 "\t<project>\tproject name\n"
		 "\t<file>\t\ttemporary file containing image names\n"
		 "Generate subclass implementation:\n"
		 "   %s  [options] -subimpl <classname> <uifile>\n"
		 "\t<classname>\tname of the subclass to generate\n"
		 "Options:\n"
		 "\t-o file\t\tWrite output to file rather than stdout\n"
		 "\t-p indent\tSet the indent in spaces (0 to use a tab)\n"
		 "\t-nofwd\t\tOmit imports of custom widgets\n"
		 "\t-tr func\tUse func(...) rather than trUtf8(...) for i18n\n"
		 "\t-x\t\tGenerate extra code to test the class\n"
		 "\t-version\tDisplay version of puic\n"
		 "\t-help\t\tDisplay this information\n"
		 , argv[0], argv[0], argv[0], argv[0], argv[0] );
	return 1;
    }

    if ( imagecollection_tmpfile ) {
	QFile ifile( image_tmpfile );
	if ( ifile.open( IO_ReadOnly ) ) {
	    QTextStream ts( &ifile );
	    QString s = ts.read();
	    s = s.simplifyWhiteSpace();
	    images = QStringList::split( ' ', s );
	    for ( QStringList::Iterator it = images.begin(); it != images.end(); ++it )
		*it = (*it).simplifyWhiteSpace();
	}
    }

    Uic::setIndent(indent);

    QFile fileOut;
    if ( !outputFile.isEmpty() ) {
	fileOut.setName( outputFile );
	if (!fileOut.open( IO_WriteOnly ) ) {
	    qWarning( "puic: Could not open output file '%s'", outputFile.data() );
	    return 1;
	}
    } else {
	fileOut.open( IO_WriteOnly, stdout );
    }
    QTextStream out( &fileOut );

    if ( imagecollection ) {
	out.setEncoding( QTextStream::Latin1 );
	Uic::embed( out, projectName, images );
	return 0;
    }


    out.setEncoding( QTextStream::UnicodeUTF8 );

    QFile file( fileName );
    if ( !file.open( IO_ReadOnly ) ) {
	qWarning( "puic: Could not open file '%s' ", fileName );
	return 1;
    }

    QDomDocument doc;
    QString errMsg;
    int errLine;
    if ( !doc.setContent( &file, &errMsg, &errLine ) ) {
	qWarning( QString("puic: Failed to parse %s: ") + errMsg + QString (" in line %d\n"), fileName, errLine );
	return 1;
    }

    QDomElement e = doc.firstChild().toElement();
    if ( e.hasAttribute("version") && e.attribute("version").toDouble() > 3.2 ) {
	qWarning( QString("puic: File generated with too recent version of Qt Designer (%s). Recent extensions won't be handled."),
		  e.attribute("version").latin1() );
	return 1;
    }

    DomTool::fixDocument( doc );

    if ( fix ) {
	out << doc.toString();
	return 0;
    }

    if ( !subcl ) {
	out << "# Form implementation generated from reading ui file '" << fileName << "'" << endl;
	out << "#" << endl;
	out << "# Created: " << QDateTime::currentDateTime().toString() << endl;
	out << "#      by: The PerlQt User Interface Compiler (puic)" << endl;
	out << "#" << endl;
	out << "# WARNING! All changes made in this file will be lost!" << endl;
	out << endl;
	out << endl;
    }
    out << "use strict;" << endl;
    out << "use utf8;"   << endl;
    out << endl;
    out << endl;

    Uic uic( fileName, outputFile, out, doc, subcl, trmacro ? trmacro : "trUtf8", className, nofwd, uicClass );

    if (execCode) {
	out << endl;
	out << endl;
	out << indent << "package main;" << endl;
        out << endl;
        out << "use Qt;" << endl;
        out << "use " << (subcl ? QString::fromLatin1(className) : uicClass) << ";" << endl;
        out << endl;
	out << indent << "my $a = Qt::Application(\\@ARGV);" << endl;
        QString s;
        getDBConnections( uic, s);
        out << s;
	out << indent << "my $w = " << (subcl? QString::fromLatin1(className) : uicClass) << ";" << endl;
	out << indent << "$a->setMainWidget($w);" << endl;
	out << indent << "$w->show;" << endl;
	out << indent << "exit $a->exec;" << endl;
    }
    if ( fileOut.status() != IO_Ok ) {
	qWarning( "uic: Error writing to file" );
	if ( !outputFile.isEmpty() )
	    remove( outputFile );
    }
    return 0;
}

void getDBConnections( Uic& uic, QString& s)
{
    int num = 0;
    for ( QStringList::Iterator it = uic.dbConnections.begin(); it != uic.dbConnections.end(); ++it ) {
        if ( !(*it).isEmpty()) {
            QString inc = (num ? QString::number(num+1) : QString::null);
            s += "\n# Connection to database " + (*it) + "\n\n";
            s += "my $DRIVER" + inc + " =\t\t'QMYSQL3';" + (inc?"":" # appropriate driver") + "\n";
            s += "my $DATABASE" + inc + " =\t\t'foo';" + (inc?"":" # name of your database") + "\n";
            s += "my $USER" + inc + "=\t\t'john';" + (inc?"":" # username") + "\n";
            s += "my $PASSWORD" + inc + "=\t\t'ZxjGG34s';" + (inc?"":" # password for USER") + "\n";
            s += "my $HOST" + inc + "=\t\t'localhost';" + (inc?"":" # host on which the database is running") + "\n";
            s += "\n";
            s += "my $db" + inc + " = Qt::SqlDatabase::addDatabase( $DRIVER" + inc;
            if (inc)
                s+= ", '" + (*it) + "'";
            s += " );\n";
            s += "   $db" + inc + "->setDatabaseName( $DATABASE" + inc + " );\n";
            s += "   $db" + inc + "->setUserName( $USER" + inc + " );\n";
            s += "   $db" + inc + "->setPassword( $PASSWORD" + inc + " );\n";
            s += "   $db" + inc + "->setHostName( $HOST" + inc + " );\n";
            s += "\n";
            s += "if( !$db" + inc + "->open() )\n";
            s += "{\n";
            s += "        Qt::MessageBox::information( undef, 'Unable to open database',\n";
            s += "                                     $db" + inc + "->lastError()->databaseText() . \"\\n\");\n";
            s += "        exit 1;\n";
            s += "}\n";
            s += "\n";
            num++;
        }
    }
}

