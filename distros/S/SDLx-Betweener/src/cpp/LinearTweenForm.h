
#ifndef LINEARTWEENFORM_H
#define LINEARTWEENFORM_H

#include <stdlib.h>
#include "Vector.h"
#include "IProxy.h"
#include "ITweenForm.h"

template<typename T,int DIM,bool FLOORED>
class LinearTweenForm : public ITweenForm {

    public:

        LinearTweenForm(
            IProxy<T,DIM> *proxy,
            Vector<T,DIM> &from,
            Vector<T,DIM> &to
        ) : proxy(proxy),
            from(from),
            to(to),
            diff(to - from),
            value(),
            last_value() {
        }

        ~LinearTweenForm() {
            delete proxy;
        }

        void start(float t) {
            compute_value(t);
            store_last_value();
            update();
        }

        void tick(float t) {
            compute_value(t);
            if (value != last_value) {
                store_last_value();
                update();
            }
        }

    private:

        void compute_value(float t) {
            value = from + (FLOORED?
                mult_floor(diff ,t):
                (diff * t)
            );
        }

        void store_last_value() { last_value = value; }

        void update() { proxy->update(value); }

        IProxy<T,DIM> *proxy;

        Vector<T,DIM> from, to, diff, value, last_value;
};

#endif
