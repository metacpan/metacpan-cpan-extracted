#pragma once

class MixBase {
    public:
    int val;
    MixBase (int arg) : val(arg) {}
    virtual ~MixBase () { dcnt++; }
};

class MixPluginA {
    public:
    int val;
    MixPluginA () : val(0) {}
    virtual ~MixPluginA () { dcnt++; }
};

class MixPluginB {
    public:
    int val;
    MixPluginB () : val(0) {}
    virtual ~MixPluginB () { dcnt++; }
};
