MODULE = SWISH::3       PACKAGE = SWISH::3::Token

PROTOTYPES: enable

SV*
value (self)
    swish_Token *self;
    
    PREINIT:
        xmlChar *value;
              
    CODE:
        value = self->value;
        if (value == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)value, self->len );
            SvUTF8_on(RETVAL);  // because we stored as UTF-8
        }
        
    OUTPUT:
        RETVAL
        

swish_MetaName*
meta (self)
    swish_Token *self;
    
    PREINIT:
        char* CLASS;
        
    CODE:
        CLASS  = METANAME_CLASS;
        RETVAL = self->meta;
        RETVAL->ref_cnt++;
        
    OUTPUT:
        RETVAL
       
SV*
meta_id (self)
        swish_Token *self;
    CODE:
        RETVAL = newSViv( self->meta->id );
    OUTPUT:
        RETVAL

     
SV*
context (self)
    swish_Token *self;
    CODE:
        RETVAL = newSVpvn( (char*)self->context, strlen((char*)self->context) );
        
    OUTPUT:
        RETVAL
        

SV*
pos (self)
    swish_Token *self;
    CODE:
        RETVAL = newSViv( self->pos );
        
    OUTPUT:
        RETVAL


SV*
offset (self)
    swish_Token *self;
    CODE:
        RETVAL = newSViv( self->offset );
        
    OUTPUT:
        RETVAL


SV*
len(self)
    swish_Token *self;
    CODE:
        RETVAL = newSViv( self->len );
        
    OUTPUT:
        RETVAL


void
DESTROY(self)
    swish_Token* self
    
    CODE:
        self->ref_cnt--;
                        
        if (SWISH_DEBUG) {
            warn("DESTROY %s [0x%lx] [ref_cnt = %d]", 
                SvPV(ST(0), PL_na), (long)self, self->ref_cnt);
            warn("Token has swish_MetaName object ref_cnt = %d", 
                self->meta->ref_cnt);
        }
        
        if (self->ref_cnt > 0 && self->meta->ref_cnt == 0) {
            SWISH_WARN("Token's MetaName ref_cnt should not be less than Token");
        }
        
        if (self->ref_cnt < 1) {
            swish_token_free(self);
        }
        
