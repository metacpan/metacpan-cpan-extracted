#pragma once

class MyOther {
    public:
    int val;
    MyOther (int arg) : val(arg) {}
    virtual ~MyOther () { dcnt++; }
};
