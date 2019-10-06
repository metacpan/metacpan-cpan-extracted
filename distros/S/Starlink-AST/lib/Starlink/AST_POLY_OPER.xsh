MODULE = Starlink::AST  PACKAGE = Starlink::AST::Polygon

int
AST__LT()
 CODE:
#ifdef AST__LT
    RETVAL = AST__LT;
#else
    Perl_croak(aTHX_ "Constant AST__LT not defined\n");
#endif
 OUTPUT:
  RETVAL

int
AST__LE()
 CODE:
#ifdef AST__LE
    RETVAL = AST__LE;
#else
    Perl_croak(aTHX_ "Constant AST__LE not defined\n");
#endif
 OUTPUT:
  RETVAL

int
AST__EQ()
 CODE:
#ifdef AST__EQ
    RETVAL = AST__EQ;
#else
    Perl_croak(aTHX_ "Constant AST__EQ not defined\n");
#endif
 OUTPUT:
  RETVAL

int
AST__GE()
 CODE:
#ifdef AST__GE
    RETVAL = AST__GE;
#else
    Perl_croak(aTHX_ "Constant AST__GE not defined\n");
#endif
 OUTPUT:
  RETVAL

int
AST__GT()
 CODE:
#ifdef AST__GT
    RETVAL = AST__GT;
#else
    Perl_croak(aTHX_ "Constant AST__GT not defined\n");
#endif
 OUTPUT:
  RETVAL

int
AST__NE()
 CODE:
#ifdef AST__NE
    RETVAL = AST__NE;
#else
    Perl_croak(aTHX_ "Constant AST__NE not defined\n");
#endif
 OUTPUT:
  RETVAL
