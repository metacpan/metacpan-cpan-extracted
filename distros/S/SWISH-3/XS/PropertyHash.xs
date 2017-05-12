MODULE = SWISH::3       PACKAGE = SWISH::3::PropertyHash

PROTOTYPES: enable

SV*
get(self, key)
    xmlHashTablePtr self;
    xmlChar* key;
    
    PREINIT:
        swish_Property* prop;
        
    CODE:
        prop    = swish_hash_fetch(self, key);
        prop->ref_cnt++;
        RETVAL  = sp_bless_ptr(PROPERTY_CLASS, prop);
        SvREFCNT_inc(RETVAL);
        
    OUTPUT:
        RETVAL


void
set(self, prop)
    xmlHashTablePtr self;
    swish_Property* prop;
    
    CODE:
        swish_hash_replace(self, prop->name, prop);
        

SV*
keys(self)
    xmlHashTablePtr self;
            
    CODE:
        RETVAL = newRV((SV*)sp_get_xml2_hash_keys(self));    /* no _inc -- this is a copy */
        
    OUTPUT:
        RETVAL
