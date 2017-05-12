MODULE = SWISH::3		PACKAGE = SWISH::3::TokenIterator

PROTOTYPES: enable


swish_Token*
next(self)
    swish_TokenIterator *self;
    
    PREINIT:
        char* CLASS;
        
    CODE:
        CLASS  = TOKEN_CLASS;
        //warn("calling next token");
        RETVAL = swish_token_iterator_next_token( self );
        //warn("got next token %d", RETVAL);
        if (RETVAL)
            RETVAL->ref_cnt++;
        
    OUTPUT:
        RETVAL
        
void
DESTROY(self)
    swish_TokenIterator* self
    
    CODE:
        self->ref_cnt--;
                        
        if (SWISH_DEBUG) {
            warn("DESTROY %s [0x%lx] [ref_cnt = %d]", 
                SvPV(ST(0), PL_na), (long)self, self->ref_cnt);
        }
        
        /* if Analyzer ref_cnt == 1 then must free its members 
           before freeing self
        */
        if (self->a->ref_cnt == 1) {
            sp_Stash_destroy( self->a->stash );
            self->a->stash = NULL;
            //warn("Analyzer regex refcnt = %d", SvREFCNT((SV*)self->a->regex));
            SvREFCNT_dec( (SV*)self->a->regex );
            self->a->regex = NULL;
        }
        
        if (self->ref_cnt < 1) {
            swish_token_iterator_free(self);
        }
        
