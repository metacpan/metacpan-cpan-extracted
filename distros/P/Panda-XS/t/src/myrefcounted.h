#pragma once

class MyRefCounted : public virtual RefCounted {
    public:
    int val;
    MyRefCounted (int val) : val(val) { }
    virtual ~MyRefCounted () {
        dcnt++;
    }
};

class MyRefCountedChild : public MyRefCounted {
    public:
    int val2;
    MyRefCountedChild (int val, int val2) : MyRefCounted(val), val2(val2) { }
    virtual ~MyRefCountedChild () {
        dcnt++;
    }
};

typedef panda::shared_ptr<MyRefCounted>      MyRefCountedSP;
typedef panda::shared_ptr<MyRefCountedChild> MyRefCountedChildSP;

static MyRefCounted*  st_myrefcounted;
static MyRefCountedSP st_myrefcounted_sp;

typedef MyRefCounted        PTRMyRefCounted;
typedef MyRefCountedChild   PTRMyRefCountedChild;
typedef MyRefCountedSP      PTRMyRefCountedSP;
typedef MyRefCountedChildSP PTRMyRefCountedChildSP;
