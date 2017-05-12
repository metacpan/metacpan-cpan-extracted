MODULE = SWISH::3       PACKAGE = SWISH::3::Analyzer

PROTOTYPES: enable


swish_Analyzer *
new(CLASS, config)
    char*           CLASS;
    swish_Config*   config;
    
    CODE:
        RETVAL = swish_analyzer_init(config);
        RETVAL->ref_cnt++;
        RETVAL->stash = sp_Stash_new();
        
    OUTPUT:
        RETVAL


# accessors/mutators
void
_set_or_get(self, ...)
    swish_Analyzer* self;
ALIAS:
    set_regex           = 1
    get_regex           = 2
PREINIT:
    SV*             stash;
    SV*             RETVAL;
PPCODE:
{
    
    //warn("number of items %d for ix %d", items, ix);
    
    START_SET_OR_GET_SWITCH

    // set_regex
    case 1:  sp_SV_is_qr(ST(1));
             self->regex = ST(1);
             break;
             
    // get_regex
    case 2:  RETVAL  = self->regex; //SvREFCNT_inc( self->regex );
             break;
                
    END_SET_OR_GET_SWITCH
}

boolean
get_tokenize(self)
    swish_Analyzer* self;
    
    CODE:
        RETVAL = self->tokenize;
    
    OUTPUT:
        RETVAL

    
void
set_tokenize(self, arg)
    swish_Analyzer* self;
    SV* arg;

    CODE:    
        if (SvIOK(arg)) {
            self->tokenize = SvIV(arg);
        }
        else {
            croak("argument to set_tokenize() should be an integer");
        }



void
DESTROY(self)
    swish_Analyzer* self
    
    CODE:
        self->ref_cnt--;
                        
        if (SWISH_DEBUG) {
            warn("DESTROY %s [0x%lx] [ref_cnt = %d]", 
                SvPV(ST(0), PL_na), (long)self, self->ref_cnt);
        }
        
        if (self->ref_cnt < 1) {
            sp_Stash_destroy( self->stash );
            self->stash = NULL;
            //warn("Analyzer regex refcnt = %d", SvREFCNT((SV*)self->regex));
            SvREFCNT_dec( (SV*)self->regex );
            self->regex = NULL;
            swish_analyzer_free(self);
        }
        
