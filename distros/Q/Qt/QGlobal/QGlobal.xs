/*
 * PerlQt interface to the class-less Qt headers
 *
 * Copyright (C) 1997, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README file
 */

#include "pqt.h"
#include "enum.h"
#include "qkeycode.h"

#define CONST_init(const) \
sv_setiv(perl_get_sv(MSTR(QGlobal::const), TRUE | GV_ADDMULTI), const)

#define STORE_key(key) enumIV(hv, MSTR(key), Align ## key)

inline void init_const() {
    HV *hv = perl_get_hv("QGlobal::Align", TRUE | GV_ADDMULTI);
    STORE_key(Left);
    STORE_key(Right);
    STORE_key(HCenter);
    STORE_key(Top);
    STORE_key(Bottom);
    STORE_key(VCenter);
    STORE_key(Center);

    CONST_init(SingleLine);
    CONST_init(DontClip);
    CONST_init(ExpandTabs);
    CONST_init(ShowPrefix);
    CONST_init(WordBreak);
    CONST_init(GrayText);
    CONST_init(DontPrint);

    CONST_init(SHIFT);
    CONST_init(CTRL);
    CONST_init(ALT);
    CONST_init(ASCII_ACCEL);
}

#define STORE_Op(op) enumIV(hv, MSTR(op), op ## ROP)

inline void init_RasterOp() {
    HV *hv = perl_get_hv("QGlobal::RasterOp", TRUE | GV_ADDMULTI);

    STORE_Op(Copy);
    STORE_Op(Or);
    STORE_Op(Xor);
    STORE_Op(Erase);
    STORE_Op(NotCopy);
    STORE_Op(NotOr);
    STORE_Op(NotXor);
    STORE_Op(NotErase);
    STORE_Op(Not);
}

#define STORE_Key(key) enumIV(hv, MSTR(key), Key_ ## key)

inline void init_Key() {
    HV *hv = perl_get_hv("QGlobal::Key", TRUE | GV_ADDMULTI);

    STORE_Key(Escape);
    STORE_Key(Tab);
    STORE_Key(Backtab);
    STORE_Key(Backspace);
    STORE_Key(Return);
    STORE_Key(Enter);
    STORE_Key(Insert);
    STORE_Key(Delete);
    STORE_Key(Pause);
    STORE_Key(Print);
    STORE_Key(SysReq);
    STORE_Key(Home);
    STORE_Key(End);
    STORE_Key(Left);
    STORE_Key(Up);
    STORE_Key(Right);
    STORE_Key(Down);
    STORE_Key(Prior);
    STORE_Key(Next);
    STORE_Key(Shift);
    STORE_Key(Control);
    STORE_Key(Meta);
    STORE_Key(Alt);
    STORE_Key(CapsLock);
    STORE_Key(NumLock);
    STORE_Key(ScrollLock);
    STORE_Key(F1);
    STORE_Key(F2);
    STORE_Key(F3);
    STORE_Key(F4);
    STORE_Key(F5);
    STORE_Key(F6);
    STORE_Key(F7);
    STORE_Key(F8);
    STORE_Key(F9);
    STORE_Key(F10);
    STORE_Key(F11);
    STORE_Key(F12);
    STORE_Key(F13);
    STORE_Key(F14);
    STORE_Key(F15);
    STORE_Key(F16);
    STORE_Key(F17);
    STORE_Key(F18);
    STORE_Key(F19);
    STORE_Key(F20);
    STORE_Key(F21);
    STORE_Key(F22);
    STORE_Key(F23);
    STORE_Key(F24);
    STORE_Key(Space);
    STORE_Key(Exclam);
    STORE_Key(QuoteDbl);
    STORE_Key(NumberSign);
    STORE_Key(Dollar);
    STORE_Key(Percent);
    STORE_Key(Ampersand);
    STORE_Key(Apostrophe);
    STORE_Key(ParenLeft);
    STORE_Key(ParenRight);
    STORE_Key(Asterisk);
    STORE_Key(Plus);
    STORE_Key(Comma);
    STORE_Key(Minus);
    STORE_Key(Period);
    STORE_Key(Slash);
    STORE_Key(0);
    STORE_Key(1);
    STORE_Key(2);
    STORE_Key(3);
    STORE_Key(4);
    STORE_Key(5);
    STORE_Key(6);
    STORE_Key(7);
    STORE_Key(8);
    STORE_Key(9);
    STORE_Key(Colon);
    STORE_Key(Semicolon);
    STORE_Key(Less);
    STORE_Key(Equal);
    STORE_Key(Greater);
    STORE_Key(Question);
    STORE_Key(At);
    STORE_Key(A);
    STORE_Key(B);
    STORE_Key(C);
    STORE_Key(D);
    STORE_Key(E);
    STORE_Key(F);
    STORE_Key(G);
    STORE_Key(H);
    STORE_Key(I);
    STORE_Key(J);
    STORE_Key(K);
    STORE_Key(L);
    STORE_Key(M);
    STORE_Key(N);
    STORE_Key(O);
    STORE_Key(P);
    STORE_Key(Q);
    STORE_Key(R);
    STORE_Key(S);
    STORE_Key(T);
    STORE_Key(U);
    STORE_Key(V);
    STORE_Key(W);
    STORE_Key(X);
    STORE_Key(Y);
    STORE_Key(Z);
    STORE_Key(BracketLeft);
    STORE_Key(Backslash);
    STORE_Key(BracketRight);
    STORE_Key(AsciiCircum);
    STORE_Key(Underscore);
    STORE_Key(QuoteLeft);
    STORE_Key(BraceLeft);
    STORE_Key(Bar);
    STORE_Key(BraceRight);
    STORE_Key(AsciiTilde);
    STORE_Key(nobreakspace);
    STORE_Key(exclamdown);
    STORE_Key(cent);
    STORE_Key(sterling);
    STORE_Key(currency);
    STORE_Key(yen);
    STORE_Key(brokenbar);
    STORE_Key(section);
    STORE_Key(diaeresis);
    STORE_Key(copyright);
    STORE_Key(ordfeminine);
    STORE_Key(guillemotleft);
    STORE_Key(notsign);
    STORE_Key(hyphen);
    STORE_Key(registered);
    STORE_Key(macron);
    STORE_Key(degree);
    STORE_Key(plusminus);
    STORE_Key(twosuperior);
    STORE_Key(threesuperior);
    STORE_Key(acute);
    STORE_Key(mu);
    STORE_Key(paragraph);
    STORE_Key(periodcentered);
    STORE_Key(cedilla);
    STORE_Key(onesuperior);
    STORE_Key(masculine);
    STORE_Key(guillemotright);
    STORE_Key(onequarter);
    STORE_Key(onehalf);
    STORE_Key(threequarters);
    STORE_Key(questiondown);
    STORE_Key(Agrave);
    STORE_Key(Aacute);
    STORE_Key(Acircumflex);
    STORE_Key(Atilde);
    STORE_Key(Adiaeresis);
    STORE_Key(Aring);
    STORE_Key(AE);
    STORE_Key(Ccedilla);
    STORE_Key(Egrave);
    STORE_Key(Eacute);
    STORE_Key(Ecircumflex);
    STORE_Key(Ediaeresis);
    STORE_Key(Igrave);
    STORE_Key(Iacute);
    STORE_Key(Icircumflex);
    STORE_Key(Idiaeresis);
    STORE_Key(ETH);
    STORE_Key(Ntilde);
    STORE_Key(Ograve);
    STORE_Key(Oacute);
    STORE_Key(Ocircumflex);
    STORE_Key(Otilde);
    STORE_Key(Odiaeresis);
    STORE_Key(multiply);
    STORE_Key(Ooblique);
    STORE_Key(Ugrave);
    STORE_Key(Uacute);
    STORE_Key(Ucircumflex);
    STORE_Key(Udiaeresis);
    STORE_Key(Yacute);
    STORE_Key(THORN);
    STORE_Key(ssharp);
    STORE_Key(agrave);
    STORE_Key(aacute);
    STORE_Key(acircumflex);
    STORE_Key(atilde);
    STORE_Key(adiaeresis);
    STORE_Key(aring);
    STORE_Key(ae);
    STORE_Key(ccedilla);
    STORE_Key(egrave);
    STORE_Key(eacute);
    STORE_Key(ecircumflex);
    STORE_Key(ediaeresis);
    STORE_Key(igrave);
    STORE_Key(iacute);
    STORE_Key(icircumflex);
    STORE_Key(idiaeresis);
    STORE_Key(eth);
    STORE_Key(ntilde);
    STORE_Key(ograve);
    STORE_Key(oacute);
    STORE_Key(ocircumflex);
    STORE_Key(otilde);
    STORE_Key(odiaeresis);
    STORE_Key(division);
    STORE_Key(oslash);
    STORE_Key(ugrave);
    STORE_Key(uacute);
    STORE_Key(ucircumflex);
    STORE_Key(udiaeresis);
    STORE_Key(yacute);
    STORE_Key(thorn);
    STORE_Key(ydiaeresis);
}

MODULE = QGlobal		PACKAGE = QGlobal

PROTOTYPES: ENABLE

BOOT:
    init_const();
    init_Key();
    init_RasterOp();

int
qRound(d)
    double d

MODULE = QGlobal		PACKAGE = Qt::Hash

void
DESTROY(rv)
    SV *rv
    CODE:
    HV *obj = (HV *)obj_check(rv);

    if(hv_exists(obj, "DELETE", 6)) {
	SV *THIS =
	    safe_hv_fetch(obj, "THIS", "Could not access \"THIS\" element");
	delete (void *)SvIV(THIS);
    }
