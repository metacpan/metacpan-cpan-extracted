MODULE = SWISH::3       PACKAGE = SWISH::3::xml2Hash

PROTOTYPES: enable

SV*
get(self, key)
    xmlHashTablePtr self;
    xmlChar* key;
    
    PREINIT:
        xmlChar* value;
        
    CODE:
        value  = swish_hash_fetch(self, key);
        RETVAL = newSVpvn((char*)value, xmlStrlen(value));
        SvUTF8_on(RETVAL);  // because we stored as UTF-8
        SvREFCNT_inc(RETVAL);
        
    OUTPUT:
        RETVAL


int
set(self,key,value)
    xmlHashTablePtr self;
    xmlChar *key;
    xmlChar *value;
            
    CODE:
        // swap ret value since C function == 0 == success
        // must dupe value since it will be freed when hash is freed.
        RETVAL = swish_hash_replace(self, key, swish_xstrdup(value)) ? 0 : 1;
        
    OUTPUT:
        RETVAL


AV*
keys(self)
    xmlHashTablePtr self;
            
    CODE:
        RETVAL = sp_get_xml2_hash_keys(self);
        
    OUTPUT:
        RETVAL
