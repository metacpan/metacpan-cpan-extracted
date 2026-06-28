MODULE = PDF::Make  PACKAGE = PDF::Make::Action
PROTOTYPES: ENABLE

# Action type constants
int
GOTO()
    CODE:
        RETVAL = PDFMAKE_ACTION_GOTO;
    OUTPUT:
        RETVAL

int
GOTOR()
    CODE:
        RETVAL = PDFMAKE_ACTION_GOTOR;
    OUTPUT:
        RETVAL

int
URI()
    CODE:
        RETVAL = PDFMAKE_ACTION_URI;
    OUTPUT:
        RETVAL

int
NAMED()
    CODE:
        RETVAL = PDFMAKE_ACTION_NAMED;
    OUTPUT:
        RETVAL

int
JAVASCRIPT()
    CODE:
        RETVAL = PDFMAKE_ACTION_JAVASCRIPT;
    OUTPUT:
        RETVAL

int
HIDE()
    CODE:
        RETVAL = PDFMAKE_ACTION_HIDE;
    OUTPUT:
        RETVAL

int
LAUNCH()
    CODE:
        RETVAL = PDFMAKE_ACTION_LAUNCH;
    OUTPUT:
        RETVAL

# Named action constants
int
NEXTPAGE()
    CODE:
        RETVAL = PDFMAKE_NAMED_NEXTPAGE;
    OUTPUT:
        RETVAL

int
PREVPAGE()
    CODE:
        RETVAL = PDFMAKE_NAMED_PREVPAGE;
    OUTPUT:
        RETVAL

int
FIRSTPAGE()
    CODE:
        RETVAL = PDFMAKE_NAMED_FIRSTPAGE;
    OUTPUT:
        RETVAL

int
LASTPAGE()
    CODE:
        RETVAL = PDFMAKE_NAMED_LASTPAGE;
    OUTPUT:
        RETVAL

int
PRINT()
    CODE:
        RETVAL = PDFMAKE_NAMED_PRINT;
    OUTPUT:
        RETVAL

# Highlight mode constants
int
HIGHLIGHT_NONE()
    CODE:
        RETVAL = PDFMAKE_HIGHLIGHT_NONE;
    OUTPUT:
        RETVAL

int
HIGHLIGHT_INVERT()
    CODE:
        RETVAL = PDFMAKE_HIGHLIGHT_INVERT;
    OUTPUT:
        RETVAL

int
HIGHLIGHT_OUTLINE()
    CODE:
        RETVAL = PDFMAKE_HIGHLIGHT_OUTLINE;
    OUTPUT:
        RETVAL

int
HIGHLIGHT_PUSH()
    CODE:
        RETVAL = PDFMAKE_HIGHLIGHT_PUSH;
    OUTPUT:
        RETVAL

# Action accessors
int
type(self)
    pdfmake_action_t *self
    CODE:
        RETVAL = self->type;
    OUTPUT:
        RETVAL

UV
obj_num(self)
    pdfmake_action_t *self
    CODE:
        RETVAL = (UV)self->obj_num;
    OUTPUT:
        RETVAL

# Action builders - these are called via Document methods, exposed here for completeness

UV
write(self)
    pdfmake_action_t *self
    CODE:
        RETVAL = pdfmake_action_write(self);
        if (RETVAL == 0)
            croak("PDF::Make::Action::write: failed to write action");
    OUTPUT:
        RETVAL

pdfmake_action_t *
chain(self, next)
    pdfmake_action_t *self
    pdfmake_action_t *next
    CODE:
        pdfmake_err_t err = pdfmake_action_chain(self, next);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Action::chain: failed to chain action");
        RETVAL = self;
    OUTPUT:
        RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Action", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "type", pdfmake_action_t, type, PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_CONST(stash, "GOTO",              PDFMAKE_ACTION_GOTO);
    PDFMAKE_REGISTER_CONST(stash, "GOTOR",             PDFMAKE_ACTION_GOTOR);
    PDFMAKE_REGISTER_CONST(stash, "URI",               PDFMAKE_ACTION_URI);
    PDFMAKE_REGISTER_CONST(stash, "NAMED",             PDFMAKE_ACTION_NAMED);
    PDFMAKE_REGISTER_CONST(stash, "JAVASCRIPT",        PDFMAKE_ACTION_JAVASCRIPT);
    PDFMAKE_REGISTER_CONST(stash, "HIDE",              PDFMAKE_ACTION_HIDE);
    PDFMAKE_REGISTER_CONST(stash, "LAUNCH",            PDFMAKE_ACTION_LAUNCH);
    PDFMAKE_REGISTER_CONST(stash, "NEXTPAGE",          PDFMAKE_NAMED_NEXTPAGE);
    PDFMAKE_REGISTER_CONST(stash, "PREVPAGE",          PDFMAKE_NAMED_PREVPAGE);
    PDFMAKE_REGISTER_CONST(stash, "FIRSTPAGE",         PDFMAKE_NAMED_FIRSTPAGE);
    PDFMAKE_REGISTER_CONST(stash, "LASTPAGE",          PDFMAKE_NAMED_LASTPAGE);
    PDFMAKE_REGISTER_CONST(stash, "PRINT",             PDFMAKE_NAMED_PRINT);
    PDFMAKE_REGISTER_CONST(stash, "HIGHLIGHT_NONE",    PDFMAKE_HIGHLIGHT_NONE);
    PDFMAKE_REGISTER_CONST(stash, "HIGHLIGHT_INVERT",  PDFMAKE_HIGHLIGHT_INVERT);
    PDFMAKE_REGISTER_CONST(stash, "HIGHLIGHT_OUTLINE", PDFMAKE_HIGHLIGHT_OUTLINE);
    PDFMAKE_REGISTER_CONST(stash, "HIGHLIGHT_PUSH",    PDFMAKE_HIGHLIGHT_PUSH);
}
