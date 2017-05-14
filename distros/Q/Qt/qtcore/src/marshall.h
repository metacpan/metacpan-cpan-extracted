#ifndef MARSHALL_H
#define MARSHALL_H
#include "smoke.h"

class SmokeType;

class Marshall {
public:
    /**
     * FromSV is used for virtual function return values and regular
     * method arguments.
     *
     * ToSV is used for method return-values and virtual function
     * arguments.
     */
    typedef void (*HandlerFn)(Marshall *);
    enum Action { FromSV, ToSV };
    virtual SmokeType type() = 0; // curArgType
    virtual Action action() = 0;
    virtual Smoke::StackItem &item() = 0; //smokeStack
    virtual SV* var() = 0; //curArg
    virtual void unsupported() = 0;
    virtual Smoke *smoke() = 0;
    /**
     * For return-values, next() does nothing.
     * For FromSV, next() calls the method and returns.
     * For ToSV, next() calls the virtual function and returns.
     *
     * Required to reset Marshall object to the state it was
     * before being called when it returns.
     */
    virtual void next() = 0;
    /**
     * For FromSV, cleanup() returns false when the handler should free
     * any allocated memory after next().
     *
     * For ToSV, cleanup() returns true when the handler should delete
     * the pointer passed to it.
     */
    virtual bool cleanup() = 0;

    virtual ~Marshall() {}
};    
#endif // MARSHALL_H
