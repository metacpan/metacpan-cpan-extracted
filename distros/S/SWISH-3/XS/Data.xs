MODULE = SWISH::3		PACKAGE = SWISH::3::Data

PROTOTYPES: enable


SV*
s3(self)
    swish_ParserData *self;
    
    PREINIT:
        char    *class;
        swish_3 *s3;

    CODE:
        self->s3->ref_cnt++;
        class  = sp_Stash_get_char((SV*)self->s3->stash, SELF_CLASS_KEY);
        //warn("s3 class = %s\n", class);
        RETVAL = sp_bless_ptr( class, self->s3 );
        
    OUTPUT:
        RETVAL
        
    CLEANUP:
        SvREFCNT_inc( RETVAL );


swish_Config*
config(self)
    swish_ParserData* self
    
	PREINIT:
        char* CLASS;

    CODE:
        CLASS  = sp_Stash_get_char(self->s3->stash, CONFIG_CLASS_KEY);
        self->s3->config->ref_cnt++;
        RETVAL = self->s3->config;
        
    OUTPUT:
        RETVAL
        
        
SV*
property(self, p)
    swish_ParserData* self;
    xmlChar* p;
    
	PREINIT:
        xmlBufferPtr buf;
        
    CODE:
        buf = swish_hash_fetch(self->properties->hash, p);
        RETVAL = newSVpvn((char*)xmlBufferContent(buf), xmlBufferLength(buf));
        
    OUTPUT:
        RETVAL
        
SV*
metaname(self, m)
    swish_ParserData* self;
    xmlChar* m;
    
	PREINIT:
        xmlBufferPtr buf;
        
    CODE:
        buf = xmlHashLookup(self->metanames->hash, m);
        RETVAL = newSVpvn((char*)xmlBufferContent(buf), xmlBufferLength(buf));
        
    OUTPUT:
        RETVAL

        
SV*
properties(self)
    swish_ParserData* self
    
    CODE:
        RETVAL = newRV_noinc((SV*)sp_nb_to_hash( self->properties ));
        
    OUTPUT:
        RETVAL
        

SV*
metanames(self)
    swish_ParserData* self
    
    CODE:
        RETVAL = newRV_noinc((SV*)sp_nb_to_hash(self->metanames));
        
    OUTPUT:
        RETVAL
       


swish_DocInfo *
doc(self)
    swish_ParserData* self
    
    PREINIT:
        char* CLASS;
        
    CODE:
        CLASS  = DOC_CLASS;
        self->docinfo->ref_cnt++;
        RETVAL = self->docinfo;
        
    OUTPUT:
        RETVAL


swish_TokenIterator *
tokens(self)
    swish_ParserData* self
    
    PREINIT:
        char* CLASS;
        
    CODE:
        CLASS = TOKENITERATOR_CLASS;
        self->token_iterator->ref_cnt++;    // TODO needed?
        RETVAL = self->token_iterator;
        
    OUTPUT:
        RETVAL
        
