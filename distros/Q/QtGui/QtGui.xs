#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <QtCore/qglobal.h>


struct QtGui {
    QtGui(){};
    ~QtGui(){};

    static int ver(){ return QT_VERSION; };
};


MODULE = QtGui		PACKAGE = QtGui


PROTOTYPES: ENABLE

=rem
QtGui *
QtCore::new()
=cut


int
ver()
    CODE:
	RETVAL = QtGui::ver();
    OUTPUT:
	RETVAL


=rem
void
QtGui::DESTROY()
=cut

