/**********************************************************************
** Copyright (C) 2000 Trolltech AS.  All rights reserved.
** Copyright (c) 2001 Phil Thompson <phil@river-bank.demon.co.uk>
** Copyright (c) 2002 Riverbank Computing Limited <info@riverbankcomputing.co.uk>
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
#include <qfile.h>
#include <qimage.h>
#include <qstringlist.h>
#include <qdatetime.h>
#include <qfileinfo.h>
#define NO_STATIC_COLORS
#include <globaldefs.h>
#include <qregexp.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

struct EmbedImage
{
    int width, height, depth;
    int numColors;
    QRgb* colorTable;
    QString name;
    QString cname;
    bool alpha;
};

static QString convertToCIdentifier( const char *s )
{
    QString r = s;
    int len = r.length();
    if ( len > 0 && !isalpha( (char)r[0].latin1() ) )
	r[0] = '_';
    for ( int i=1; i<len; i++ ) {
	if ( !isalnum( (char)r[i].latin1() ) )
	    r[i] = '_';
    }
    return r;
}


static void embedData( QTextStream& out, const uchar* input, int nbytes )
{
    static const char hexdigits[] = "0123456789abcdef";
    QString s;
    for ( int i=0; i<nbytes; i++ )
    {
	if ( (i%14) == 0 )
        {
            s += "\n    ";
	    out << (const char*)s;
	    s.truncate( 0 );
	}
	uint v = input[i];
        	s += "0x";
	s += hexdigits[(v >> 4) & 15];
	s += hexdigits[v & 15];
	if ( i < nbytes-1 )
	    s += ", ";
	else
	    s += "\n";
    }
    if ( s.length() )
	out << (const char*)s;
}

static void embedData( QTextStream& out, const QRgb* input, int n )
{
    out << hex;
    const QRgb *v = input;
    for ( int i=0; i<n; i++ ) {
	if ( (i%6) == 0  )
	    out << endl << "    ";
	out << "0x";
	out << hex << *v++;
	if ( i < n-1 )
	    out << ", ";
	else
	    out << ";" << endl;
    }
    out << dec; // back to decimal mode
}

void Uic::embed( QTextStream& out, const char* project, const QStringList& images )
{

    QString cProject = convertToCIdentifier( project );

    QStringList::ConstIterator it;
    out << "# Image collection for project '" << project << "'." << endl;
    out << "#" << endl;
    out << "# Generated from reading image files: " << endl;
    for ( it = images.begin(); it != images.end(); ++it )
	out << "#      " << *it << endl;
    out << "#" << endl;
    out << "# Created: " << QDateTime::currentDateTime().toString() << endl;
    out << "#      by: The PerlQt User Interface Compiler (puic)" << endl;
    out << "#" << endl;
    out << "# WARNING! All changes made in this file will be lost!" << endl;
    out << endl;
    out << "use strict;" << endl;
    out << "use utf8;"   << endl;
    out << endl;

    out << indent << "package DesignerMimeSourceFactory_" << cProject << ";" << endl;
    out << indent << "use Qt;" << endl;
    out << indent << "use Qt::isa qw(Qt::MimeSourceFactory);" << endl;
    out << endl;

    QPtrList<EmbedImage> list_image;
    int image_count = 0;
    for ( it = images.begin(); it != images.end(); ++it ) {
	QImage img;
	if ( !img.load( *it  ) ) {
	    fprintf( stderr, "puic: cannot load image file %s\n", (*it).latin1() );
	    continue;
	}
	EmbedImage *e = new EmbedImage;
	e->width = img.width();
	e->height = img.height();
	e->depth = img.depth();
	e->numColors = img.numColors();
	e->colorTable = new QRgb[e->numColors];
	e->alpha = img.hasAlphaBuffer();
	memcpy(e->colorTable, img.colorTable(), e->numColors*sizeof(QRgb));
	QFileInfo fi( *it );
	e->name = fi.fileName();
	e->cname = QString("$image_%1").arg( image_count++);
	list_image.append( e );
	out << "# " << *it << endl;
	QString s;
        QString imgname = (const char *)e->cname;


//my $i0 = Qt::Image($image_0_data, 22, 22, 32, undef, &Qt::Image::BigEndian);
//$i0->setAlphaBuffer(1);
//my $image0 = Qt::Pixmap($i0);

	if ( e->depth == 32 ) {
	    out << indent << "my " << imgname << "_data = pack 'L*'," << endl;
	    embedData( out, (QRgb*)img.bits(), e->width*e->height );
	} else {
	    if ( e->depth == 1 )
		img = img.convertBitOrder(QImage::BigEndian);
	    out << indent << "my " << imgname << "_data = pack 'C*'," << endl;
	    embedData( out, img.bits(), img.numBytes() );
	}
        out << endl;
	if ( e->numColors ) {
	    out << indent << "my " << imgname << "_ctable = " << endl;
	    out << indent << "[" << endl;
	    embedData( out, e->colorTable, e->numColors );
            out << endl;
            out << indent << "];" << endl;
	}
    }

    if ( !list_image.isEmpty() ) {
         out << indent << "my %embed_images = (\n";
	++indent;
	EmbedImage *e = list_image.first();
	while ( e )
        {
	    out << indent << "\"" << e->name << "\"" << " => [" << e->cname << "_data, "
                << e->width << ", " << e->height << ", " << e->depth << ", "
                << (e->numColors ? e->cname + "_ctable" : QString::fromLatin1("undef") ) << ", "
                << (e->alpha ? "1" : "0") << "]," << endl;
	    e = list_image.next();
	}
	--indent;
	out << indent << ");" << endl;

	out << endl;
	out << indent << "my %images = ();" << endl;
	out << endl;
	out << endl;
	out << indent << "sub uic_findImage" << endl;
	out << indent << "{" << endl;
	++indent;
        out << indent << "my $name = shift;" << endl;
	out << indent << "return $images{$name} if exists $images{$name};" << endl;
        out << indent << "return Qt::Image() unless exists $embed_images{$name};" << endl;
        out << indent << endl;
	out << indent << "my $img = Qt::Image(@{$embed_images{$name}}[0..4], &Qt::Image::BigEndian);" << endl;
        out << indent << "${$embed_images{$name}}[5] && $img->setAlphaBuffer(1);" << endl;
	out << indent << "$images{$name} = $img;" << endl;
	out << indent << "return $img;" << endl;
	--indent;
	out << indent << "}" << endl;
	out << endl;
	out << indent << "sub data" << endl;
	out << indent << "{" << endl;
	++indent;
        out << indent << "my $abs_name = shift;" << endl;
	out << indent << "my $img = uic_findImage($abs_name);" << endl;
	out << indent << "if($img->isNull())" << endl;
	out << indent << "{" << endl;
	++indent;
	out << indent << "Qt::MimeSourceFactory::removeFactory(this);" << endl;
	out << indent << "my $s = Qt::MimeSourceFactory::defaultFactory()->data($abs_name);" << endl;
	out << indent << "Qt::MimeSourceFactory::addFactory(this);" << endl;
	out << indent << "return $s;" << endl;
	--indent;
	out << indent << "}" << endl;
	out << indent << "Qt::MimeSourceFactory::defaultFactory()->setImage($abs_name, $img);" << endl;
	out << indent << "return Qt::MimeSourceFactory::defaultFactory()->data($abs_name);" << endl;
	--indent;
	out << indent << "}" << endl;

	out << endl;
	out << endl;

	out << indent << "package staticImages;" << endl;
        out << indent << "use Qt;" << endl;
	out << indent << "use DesignerMimeSourceFactory_" << cProject << ";" << endl;
        out << indent << "our %factories;" << endl;
        out << indent << endl;
        out << indent << "my $factory = DesignerMimeSourceFactory_" << cProject << ";" << endl;
        out << indent << "Qt::MimeSourceFactory::defaultFactory()->addFactory($factory);" << endl;
        out << indent << "$factories{'DesignerMimeSourceFactory_" << cProject << "'} = $factory;" << endl;
	out << endl;
	out << indent << "END" << endl;
        out << indent << "{" << endl;
        ++indent;
        out << indent << "for( values %factories )" << endl;
        out << indent << "{" << endl;
        ++indent;
        out << indent << "Qt::MimeSourceFactory::defaultFactory()->removeFactory($_);" << endl;
        --indent;
        out << indent << "}" << endl;
        out << indent << "%factories = ();" << endl;
        --indent;
        out << indent << "}" << endl;
        out << indent << "1;" << endl;;
	out << endl;
    }
}
