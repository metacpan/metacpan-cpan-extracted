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


struct QtCore {
    QtCore(){};
    ~QtCore(){};

    static int ver(){ return QT_VERSION; };
};


MODULE = QtCore		PACKAGE = QtCore


PROTOTYPES: ENABLE

=rem
QtCore *
QtCore::new()
=cut


int
ver()
    CODE:
	RETVAL = QtCore::ver();
    OUTPUT:
	RETVAL


=rem
void
QtCore::DESTROY()
=cut

