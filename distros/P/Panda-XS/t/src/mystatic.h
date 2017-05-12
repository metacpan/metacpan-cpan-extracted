#pragma once

class MyStatic {
public:
    int val;
    MyStatic (int val) : val(val) { }
    ~MyStatic () {}
};

class MyStaticChild : public MyStatic {
public:
    int val2;
    MyStaticChild (int val, int val2) : MyStatic(val), val2(val2) { }
};

typedef MyStatic      PTRMyStatic;
typedef MyStaticChild PTRMyStaticChild;
