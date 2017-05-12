#include <QHostAddress>
#include <QUdpSocket>
#include <QPalette>
#include <QMetaObject>
#include <QMetaMethod>
#include <QLinkedList>
#include <QProcess>

// Perl headers
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include "util.h"
#include "marshall_basetypes.h"

//qint64 QUdpSocket::readDatagram(char*, qint64, QHostAddress*=0, quint16*=0)
XS(XS_qudpsocket_readdatagram) {
    dXSARGS;
    if (items < 3 || items > 5) {
        croak( "%s", "Invalid argument list to Qt::UdpSocket::readDatagram()" );
    }

    smokeperl_object *o = sv_obj_info(ST(0));

    if (!o) {
        croak( "Qt::UdpSocket::read() called on a non-Qt object" );
    }
    if(isDerivedFrom(o, "QUdpSocket") == -1) {
        croak( "%s", "Qt::UdpSocket::readDatagram() called on a"
            " non-UdpSocket object");
    }
    if(!SvROK(ST(1))) {
        croak( "%s", "First argument to Qt::UdpSocket::readDatagram() should"
            " be a scalar reference." );
    }

    QUdpSocket * socket = (QUdpSocket *) o->smoke->cast(
        o->ptr,
        o->classId,
        o->smoke->idClass("QUdpSocket").index
    );

    STRLEN maxSize = SvIV( ST(2) );
    char* buf = new char[maxSize];
    strncpy(buf, SvPV_nolen(SvRV(ST(1))), maxSize);

    QHostAddress * address = 0;
    quint16 * port = 0;

    if (items >= 4) {
        smokeperl_object* o = sv_obj_info( ST(3) );
        if ( o ) {
            address = (QHostAddress*)o->ptr;
        }
    }
    if (items == 5) {
        if(!SvROK(ST(4))) {
            croak( "%s", "Fourth argument to Qt::UdpSocket::readDatagram() should"
                " be a scalar reference." );
        }
        if ( SvOK(SvRV(ST(4))) ) {
            fprintf( stderr, "OK!\n" );
            port = new quint16( SvIV( SvRV( ST(4) ) ) );
        }
        else 
            port = new quint16( 0 );
    }

    STRLEN readSize = socket->readDatagram( buf, maxSize, address, port );

    if ( !SvREADONLY(SvRV(ST(1))) )
        sv_setpvn( SvRV(ST(1)), buf, readSize );
    if ( items == 5 ) {
        if ( !SvREADONLY(SvRV(ST(4))) )
            sv_setiv( SvRV(ST(4)), *port );
        delete port;
    }

    ST(0) = sv_2mortal( newSViv( (IV)readSize ) );
    XSRETURN(1);
}

