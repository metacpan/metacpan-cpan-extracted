
MODULE = SOOT		PACKAGE = SOOT::API

void
type(sv)
    SV* sv
  INIT:
    SOOT::BasicType type;
  PPCODE:
    dXSTARG;
    type = GuessType(aTHX_ sv);
    const char* type_str = SOOT::gBasicTypeStrings[type];
    XPUSHp(type_str, strlen(type_str));


void
cproto(sv)
    SV* sv
  INIT:
    SOOT::BasicType type;
  PPCODE:
    dXSTARG;
    type = GuessType(aTHX_ sv);
    string cproto = CProtoFromType(aTHX_ sv, type);
    if (cproto.length() == 0)
      XPUSHs(&PL_sv_undef);
    else
      XPUSHp(cproto.c_str(), cproto.length());


void
is_same_object(obj1, obj2)
    SV* obj1
    SV* obj2
  PPCODE:
    if (SOOT::IsSameTObject(aTHX_ obj1, obj2))
      XSRETURN_YES;
    else
      XSRETURN_NO;


void
prevent_destruction(rootObject)
    SV* rootObject
  PPCODE:
    SOOT::PreventDestruction(aTHX_ rootObject);


void
print_ptrtable_state()
  PPCODE:
    gSOOTObjects->PrintStats();

void
is_soot_class(className)
    char* className
  PPCODE:
    string isROOTName = string(className) + string("isROOT");
    SV* isROOT = get_sv(isROOTName.c_str(), 0);
    if (isROOT == NULL)
      XSRETURN_NO;
    else
      XSRETURN_YES;


void
Cleanup()
  PPCODE:
    PtrTable* tmp = SOOT::gSOOTObjects;
    SOOT::gSOOTObjects = NULL;
    tmp->Clear();
    delete tmp;


