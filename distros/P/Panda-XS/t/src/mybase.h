#pragma once

class MyBase {
public:
    int val;
    MyBase (int arg) : val(arg) {}
    virtual MyBase* clone () { return new MyBase(val); }
    virtual ~MyBase () { dcnt++; }
};

class MyChild : public MyBase {
public:
    int val2;
    MyChild (int arg1, int arg2) : MyBase(arg1), val2(arg2) {}
    MyBase* clone () { return new MyChild(val, val2); }
    virtual ~MyChild () { dcnt++; }
};

typedef MyBase  PTRMyBase;
typedef MyChild PTRMyChild;

typedef panda::shared_ptr<MyBase>  MyBaseSP;
typedef panda::shared_ptr<MyChild> MyChildSP;
typedef MyBaseSP  PTRMyBaseSP;
typedef MyChildSP PTRMyChildSP;

typedef std::shared_ptr<MyBase>  MyBaseSSP;
typedef std::shared_ptr<MyChild> MyChildSSP;
typedef MyBaseSSP  PTRMyBaseSSP;
typedef MyChildSSP PTRMyChildSSP;

static MyBaseSP st_mybase_sp;

static MyBaseSSP st_mybase_ssp;

typedef MyBase  MyBaseAV;
typedef MyBase  MyBaseHV;
