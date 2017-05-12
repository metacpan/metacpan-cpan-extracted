MODULE = SWISH::3       PACKAGE = SWISH::3::Stash

PROTOTYPES: enable

SV*
get(self,key)
    SV* self;
    SV* key;
    
    PREINIT:
        SV* value;
        
    CODE:
        RETVAL = sp_Stash_get( self, SvPV(key, PL_na) );
        SvREFCNT_inc(RETVAL);
        
    OUTPUT:
        RETVAL
        

void
set(self,key,value)
    SV* self;
    SV* key;
    SV* value;
    
    CODE:
        sp_Stash_set(self, SvPV(key, PL_na), value);



AV*
keys(self)
    SV* self;
            
    CODE:
        RETVAL = sp_hv_keys( sp_extract_hash(self) );
    
    OUTPUT:
        RETVAL    


AV*
values(self)
    SV* self;
            
    CODE:
        RETVAL = sp_hv_values( sp_extract_hash(self) );
    
    OUTPUT:
        RETVAL    


void
DESTROY(self)
    SV *self;
    
    CODE:
    
        if (SWISH_DEBUG) {
            warn("DESTROY %s [0x%lx]", 
                SvPV(ST(0), PL_na), (long)self);
            
        }

