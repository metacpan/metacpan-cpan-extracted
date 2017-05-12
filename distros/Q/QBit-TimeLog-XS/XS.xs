#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ppport.h"

#include <time.h>
#include <list>

typedef AV* myav_ref;

inline double tv_diff(timespec & t1, timespec & t2) {
    return (double)(t2.tv_sec - t1.tv_sec) + (double)(t2.tv_nsec - t1.tv_nsec) / 1000000000;
}

inline SV * UNKNOWN_ACTION_SV() {
    SV * res = newSVpv("Working", 0);
    sv_utf8_decode(res);
    return res;
}

class TimeLog {
public:
    TimeLog() : _parent(NULL), _cur(NULL), _description(NULL) {}
    TimeLog(TimeLog * parent) : _parent(parent), _cur(NULL), _description(NULL) {}
    ~TimeLog() {
        for (std::list<TimeLog *>::const_iterator it = _cps.begin(); it != _cps.end(); ++it)
            delete *it;
        if (_description)
            free(_description);
    }

    void start(char * text) {
        if (_cur) {
            TimeLog * tmp = new TimeLog(_cur);
            tmp->start(text);
            _cur->_cps.push_back(tmp);
            _cur = tmp;
        } else {
            clock_gettime(CLOCK_MONOTONIC, &_start);
            _description = strdup(text);
            _cur = this;
        }
    }

    void finish() {
        clock_gettime(CLOCK_MONOTONIC, &_cur->_finish);
        _cur = _cur->_parent;
    }

    AV * analyze() {
        return __analyze(false, false, NULL);
    }


private:
    AV * __analyze(bool first, bool last, timespec * prev_time) {
        AV * res = newAV();

        if (first && _parent) {
            AV * av = newAV();
            av_extend(av, 2);
            av_store(av, 0, UNKNOWN_ACTION_SV());
            av_store(av, 1, newSVnv(tv_diff(_parent->_start, _start)));
            av_push(res, newRV_noinc((SV*)av));
        }

        if (!first && prev_time) {
            AV * av = newAV();
            av_extend(av, 2);
            av_store(av, 0, UNKNOWN_ACTION_SV());
            av_store(av, 1, newSVnv(tv_diff(*prev_time, _start)));
            av_push(res, newRV_noinc((SV*)av));
        }

        AV * av = newAV();
        av_extend(av, 3);
        SV * desc = newSVpv(_description, 0);
        sv_utf8_decode(desc);
        av_store(av, 0, desc);
        av_store(av, 1, newSVnv(tv_diff(_start, _finish)));

        if (_cps.size()) {
            size_t cnt = 0;
            timespec prev_finish;
            AV * cav = newAV();

            for (std::list<TimeLog *>::const_iterator it = _cps.begin(); it != _cps.end(); ++it) {
                AV * tav = (*it)->__analyze(cnt == 0, cnt == _cps.size() - 1, &prev_finish);
                do {
                    av_push(cav, av_shift(tav));
                } while (av_len(tav) >= 0);
                sv_2mortal((SV*)tav);
                prev_finish = (*it)->_finish;
                ++cnt;
            }
            av_store(av, 2, newRV_noinc((SV*)cav));
        }

        av_push(res, newRV_noinc((SV*)av));

        if (last && _parent) {
            AV * av = newAV();
            av_extend(av, 2);
            av_store(av, 0, UNKNOWN_ACTION_SV());
            av_store(av, 1, newSVnv(tv_diff(_finish, _parent->_finish)));
            av_push(res, newRV_noinc((SV*)av));
        }

        return res;
    }

    TimeLog * _parent;
    TimeLog * _cur;
    std::list<TimeLog *> _cps;
    char * _description;
    timespec _start, _finish;
};

MODULE = QBit::TimeLog::XS          PACKAGE = QBit::TimeLog::XS

TimeLog *
TimeLog::new()

void
TimeLog::start(char * text)

void
TimeLog::finish()

myav_ref
TimeLog::analyze()

void
TimeLog::DESTROY()

