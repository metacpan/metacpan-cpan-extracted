MODULE = SWISH::3		PACKAGE = SWISH::3::Doc

PROTOTYPES: enable

SV*
mtime(self)
    swish_DocInfo* self;
    
    CODE:
        RETVAL = newSViv( self->mtime );
        
    OUTPUT:
        RETVAL
        
SV*
size(self)
    swish_DocInfo* self;
    
    CODE:
        RETVAL = newSViv( self->size );
        
    OUTPUT:
        RETVAL
        
SV*
nwords(self)
    swish_DocInfo* self;
    
    CODE:
        RETVAL = newSViv( self->nwords );
        
    OUTPUT:
        RETVAL


SV*
encoding(self)
    swish_DocInfo *self;

    PREINIT:
        xmlChar *encoding;

    CODE:
        encoding = self->encoding;
        if (encoding == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)encoding, strlen((char*)encoding) );
        }
        
    OUTPUT:
        RETVAL

SV*
uri(self)
    swish_DocInfo *self;

    PREINIT:
        xmlChar *uri;

    CODE:
        uri = self->uri;
        if (uri == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)uri, strlen((char*)uri) );
        }
        
    OUTPUT:
        RETVAL

SV*
ext(self)
    swish_DocInfo *self;

    PREINIT:
        xmlChar *ext;

    CODE:
        ext = self->ext;
        if (ext == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)ext, strlen((char*)ext) );
        }
        
    OUTPUT:
        RETVAL
        
SV*
mime(self)
    swish_DocInfo *self;

    PREINIT:
        xmlChar *mime;

    CODE:
        mime = self->mime;
        if (mime == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)mime, strlen((char*)mime) );
        }

    OUTPUT:
        RETVAL
        

SV*
parser(self)
    swish_DocInfo *self;

    PREINIT:
        xmlChar *parser;

    CODE:
        parser = self->parser;
        if (parser == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)parser, strlen((char*)parser) );
        }

    OUTPUT:
        RETVAL

   
SV*
action(self)
    swish_DocInfo *self;

    PREINIT:
        xmlChar *action;

    CODE:
        action = self->action;
        if (action == NULL) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSVpvn( (char*)action, strlen((char*)action) );
        }

    OUTPUT:
        RETVAL


void
DESTROY (self)
    swish_DocInfo * self;

    CODE:
        self->ref_cnt--;

        if (SWISH_DEBUG) {
            warn("DESTROY %s [%ld] [ref_cnt = %d]",
                SvPV(ST(0), PL_na), (long)self, self->ref_cnt);
        }

        // freed by parser_data


