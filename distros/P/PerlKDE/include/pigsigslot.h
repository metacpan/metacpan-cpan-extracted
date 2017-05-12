#ifndef PIGSIGSLOT_H
#define PIGSIGSLOT_H
#include <qsignalslotimp.h>

/*
#if !defined(Q_MOC_CONNECTIONLIST_DECLARED)
#define Q_MOC_CONNECTIONLIST_DECLARED
#include <qlist.h>
#if defined(Q_DECLARE)
Q_DECLARE(QListM,QConnection);
Q_DECLARE(QListIteratorM,QConnection);
#else
declare(QListM,QConnection);
declare(QListIteratorM,QConnection);
#endif
#endif
*/
#define pig_func (*((PIG)pig_signal_member))

class pig_sigslot_argument_iterator {
    const char *pigargs;
    int pigcnt;
public:
    pig_sigslot_argument_iterator(const char *pig1) {
        pigargs = pig1;
        pigcnt = *pigargs;
        pigargs += pigargs[1] + 2;
    }
    const char *operator ++() {
        const char *pigr = (--pigcnt < 0) ? 0 : pigargs++;
        // Yes, that NULL pointer is intentionally dereferenced here
        if(*pigr == PIG_PROTO_CONST) pigr = pigargs++;
        if(*pigr == PIG_PROTO_OBJECT) pigargs += *pigargs;
        return pigr;
    }
};

struct pig_slot_data {
    SV *pigreceiver;
    const char *pigproto;
    const char *pigcrypt;
    const char *pigmethod;
    QMetaObject *pigmeta;
};

#include "_pigsigslot.h"

#endif  // PIGSIGSLOT_H
