MODULE = SWISH::3       PACKAGE = SWISH::3::Property

PROTOTYPES: enable

SV*
id (self)
	swish_Property *self;
       
    CODE:
        RETVAL = newSViv( self->id );
        
    OUTPUT:
        RETVAL
        

SV*
name (self)
	swish_Property *self;
    
    CODE:
        RETVAL = newSVpvn( (char*)self->name, strlen((char*)self->name) );
        
    OUTPUT:
        RETVAL
        
SV*
ignore_case (self)
	swish_Property *self;
    
    CODE:
        RETVAL = newSViv( self->ignore_case );
        
    OUTPUT:
        RETVAL
        

SV*
type (self)
	swish_Property *self;
    
    CODE:
        RETVAL = newSViv( self->type );
        
    OUTPUT:
        RETVAL

SV*
verbatim (self)
	swish_Property *self;
    
    CODE:
        RETVAL = newSViv( self->verbatim );
        
    OUTPUT:
        RETVAL

SV*
max (self)
	swish_Property *self;
    
    CODE:
        RETVAL = newSViv( self->max );
        
    OUTPUT:
        RETVAL

SV*
sort (self)
    swish_Property *self;
    
    CODE:
        RETVAL = newSViv( self->sort );
        
    OUTPUT:
        RETVAL
       
SV*
presort (self)
    swish_Property *self;

    CODE:
        RETVAL = newSViv( self->presort );

    OUTPUT:
        RETVAL
 
SV*
alias_for (self)
    swish_Property *self;
    
    CODE:
        if (self->alias_for == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)self->alias_for, strlen((char*)self->alias_for) );
        }

    OUTPUT:
        RETVAL
        

void
DESTROY (self)
    swish_Property *self;
    
    CODE:
        self->ref_cnt--;
        
        if (SWISH_DEBUG) {
            warn("DESTROY %s [0x%lx] [ref_cnt = %d]", 
                SvPV(ST(0), PL_na), (long)self, self->ref_cnt);
        }
        
        
        if (self->ref_cnt < 1) {
            swish_property_free(self);
        }
        
