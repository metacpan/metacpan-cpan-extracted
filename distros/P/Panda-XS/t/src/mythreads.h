#pragma once

class MyThreadSafe : public virtual RefCounted {
    public:
    int val;
    MyThreadSafe (int arg) : val(arg) {}
    virtual ~MyThreadSafe () { dcnt++; }
};

inline MyBase* pxs_mybase_dup (pTHX_ MyBase* obj) {
    return obj->clone();
}
