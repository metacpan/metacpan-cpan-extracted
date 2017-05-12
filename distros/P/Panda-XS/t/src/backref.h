#pragma once

class BRUnit : virtual public RefCounted {
public:
    int id;

    BRUnit (int id) : id(id) {}

    virtual BRUnit* clone () {
        return new BRUnit(id);
    }

    virtual ~BRUnit () {
        //printf("~BRUnit\n");
        dcnt++;
    }
};

class BRUnitEnabled : public XSBackref, public BRUnit {
public:
    BRUnitEnabled (int id) : BRUnit(id) {}

    virtual BRUnit* clone () {
        //printf("BRUnitEnabled::clone()\n");
        return new BRUnitEnabled(id);
    }
};

class BRStorage {
public:
    BRStorage () : unit(NULL) {}

    BRUnit* get_unit () const {
        return unit;
    }

    void set_unit (BRUnit* val) {
        if (unit) unit->release();
        unit = val;
        if (unit) unit->retain();
    }

    void set_unit_with_id (int id) {
        if (unit) unit->release();
        unit = new BRUnit(id);
        unit->retain();
    }

    void set_unit_with_id2 (int id) {
        if (unit) unit->release();
        unit = new BRUnitEnabled(id);
        unit->retain();
    }

    virtual ~BRStorage () {
        //printf("~BRStorage\n");
        if (unit) unit->release();
        dcnt++;
    }

    virtual BRStorage* clone () {
        //printf("BRStorage::clone()\n");
        BRStorage* ret = new BRStorage();
        ret->set_unit(unit->clone());
        return ret;
    }
private:
    BRUnit* unit;
};

typedef BRUnit    PTRBRUnit;
typedef BRStorage PTRBRStorage;

typedef panda::shared_ptr<BRUnit> BRUnitSP;

class BRSPStorage {
public:
    BRSPStorage () {}
    const BRUnitSP& get_unit () const {
        return unit;
    }
    void set_unit (const BRUnitSP& val) {
        unit = val;
    }
    virtual BRSPStorage* clone () {
        //printf("BRSPStorage::clone()\n");
        BRSPStorage* ret = new BRSPStorage();
        ret->set_unit(BRUnitSP(unit->clone()));
        return ret;
    }
    virtual ~BRSPStorage () {
        //printf("~BRSPStorage\n");
        dcnt++;
    }
private:
    BRUnitSP unit;
};

class BRUnitSPWrapper {
public:
    int xval;
    BRUnitSPWrapper (BRUnitSP& u) : xval(0), _unit(u) {}
    BRUnitSPWrapper* clone () const {
        //printf("BRUnitSPWrapper::clone()\n");
        BRUnitSP uret = _unit->clone();
        BRUnitSPWrapper* ret = new BRUnitSPWrapper(uret);
        ret->xval = xval;
        return ret;
    }
    const BRUnitSP& unit () const {
        return _unit;
    }
    ~BRUnitSPWrapper () {
        //printf("~BRUnitSPWrapper\n");
        dcnt++;
    }
private:
    BRUnitSP _unit;
};
