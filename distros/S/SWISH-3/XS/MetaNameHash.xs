MODULE = SWISH::3       PACKAGE = SWISH::3::MetaNameHash

PROTOTYPES: enable

SV*
get(self, key)
    xmlHashTablePtr self;
    xmlChar* key;
    
    PREINIT:
        swish_MetaName* meta;
        
    CODE:
        meta    = swish_hash_fetch(self, key);
        meta->ref_cnt++;
        RETVAL  = sp_bless_ptr(METANAME_CLASS, meta);
        SvREFCNT_inc(RETVAL);
        
    OUTPUT:
        RETVAL


void
set(self, meta)
    xmlHashTablePtr self;
    swish_MetaName* meta;
    
    CODE:
        swish_hash_replace(self, meta->name, meta);


SV*
keys(self)
    xmlHashTablePtr self;
            
    CODE:
        RETVAL = newRV((SV*)sp_get_xml2_hash_keys(self));    /* no _inc -- this is a copy */
        
    OUTPUT:
        RETVAL
