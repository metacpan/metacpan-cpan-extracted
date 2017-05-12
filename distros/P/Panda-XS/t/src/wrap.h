#pragma once

typedef MyBase  WBase;
typedef MyChild WChild;
typedef WBase   PTRWBase;
typedef WChild  PTRWChild;

class Wrapper {
public:
    WBase* obj;
    int xval;

    Wrapper (WBase* arg) : obj(arg), xval(0) {}

    virtual Wrapper* clone () {
        Wrapper* cloned = new Wrapper(obj->clone());
        cloned->xval = xval;
        return cloned;
    }

    virtual ~Wrapper () {
        dcnt++;
        delete obj;
    }
};

class WrapperChild : public Wrapper {
public:
    int xval2;

    WrapperChild (WChild* arg) : Wrapper(arg), xval2(0) {}

    virtual Wrapper* clone () {
        WrapperChild* cloned = new WrapperChild(static_cast<WChild*>(obj->clone()));
        cloned->xval = xval;
        cloned->xval2 = xval2;
        return cloned;
    }
};
