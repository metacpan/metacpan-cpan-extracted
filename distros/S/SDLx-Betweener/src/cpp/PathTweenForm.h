
#ifndef PATHTWEENFORM_H
#define PATHTWEENFORM_H

#include <stdlib.h>
#include "Vector.h"
#include "IProxy.h"
#include "IPath.h"
#include "ITweenForm.h"

class PathTweenForm : public ITweenForm {

    public:

        PathTweenForm(
            IProxy<int,2> *proxy,
            IPath *path
        ) : proxy(proxy),
            path(path),
            value(),
            last_value() {
        }

        ~PathTweenForm() {
            delete proxy;
            delete path;
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

        void compute_value(float t) { value = path->solve(t); }

        void store_last_value() { last_value = value; }

        void update() { proxy->update(value); }

        IProxy<int,2> *proxy;
        IPath         *path;
        Vector<int,2> value, last_value;
};

#endif
