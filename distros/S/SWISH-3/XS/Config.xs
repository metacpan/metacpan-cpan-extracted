MODULE = SWISH::3		PACKAGE = SWISH::3::Config	

PROTOTYPES: enable

swish_Config *
new(CLASS)
    char* CLASS;
    
    CODE:
        RETVAL = swish_config_init();
        RETVAL->ref_cnt++;
        RETVAL->stash = sp_Stash_new();
        
    OUTPUT:
        RETVAL


        
void
set_default(self)
    swish_Config *self
    
    CODE:
        swish_config_set_default(self);
        

# accessors/mutators
void
_set_or_get(self, ...)
    swish_Config *self;
ALIAS:
    set_properties          = 1
    get_properties          = 2
    set_metanames           = 3
    get_metanames           = 4
    set_mimes               = 5
    get_mimes               = 6
    set_parsers             = 7
    get_parsers             = 8
    set_aliases             = 9
    get_aliases             = 10
    set_index               = 11
    get_index               = 12
    set_misc                = 13
    get_misc                = 14
PREINIT:
    SV* RETVAL;
PPCODE:
{
    
    //warn("number of items %d for ix %d", items, ix);
    
    START_SET_OR_GET_SWITCH

    // set properties
    case 1:  croak("TODO");
             break;
             
    // get properties
    case 2:  RETVAL = sp_bless_ptr( PROPERTY_HASH_CLASS, self->properties );
             break;
             
    // set metanames
    case 3:  croak("TODO");
             break;
             
    // get metanames
    case 4:  RETVAL = sp_bless_ptr( METANAME_HASH_CLASS, self->metanames );
             break;
           
    // set mimes  
    case 5:  croak("TODO");
             break;
    
    // get mimes
    case 6:  RETVAL = sp_bless_ptr( XML2_HASH_CLASS, self->mimes );
             break;
             
    // set parsers
    case 7:  croak("TODO");
             break;
           
    // get parsers  
    case 8:  RETVAL = sp_bless_ptr( XML2_HASH_CLASS, self->parsers );
             break;
    
    // set aliases
    case 9:  croak("TODO");
             break;
             
    // get aliases
    case 10: RETVAL = sp_bless_ptr( XML2_HASH_CLASS, self->tag_aliases );
             break;
    
    // set index
    case 11: croak("TODO");
             break;
             
    // get index
    case 12: RETVAL = sp_bless_ptr( XML2_HASH_CLASS, self->index );
             break;
    
    // set misc
    case 13: croak("TODO");
             break;
             
    // get misc
    case 14: RETVAL = sp_bless_ptr( XML2_HASH_CLASS, self->misc );
             break;
        
    END_SET_OR_GET_SWITCH
}
 
void
debug(self)
    swish_Config* self
    
    CODE:
        swish_config_debug(self);
        



boolean
add(self, conf_file)
    swish_Config* self
    char* conf_file
    
    CODE:
        if (swish_config_add(self, (xmlChar*)conf_file)) {
            RETVAL = SWISH_TRUE;
        }
        else {
            RETVAL = SWISH_FALSE;
        }
    
    OUTPUT:
        RETVAL
 
      
void
delete(self, key)
    swish_Config* self
    char* key
    
    CODE:
        croak("delete() not yet implemented\n");
        

swish_Config *
read(CLASS, filename)
    char* CLASS
    char* filename
    
    CODE:
        RETVAL = swish_header_read(filename);
        RETVAL->ref_cnt++;
        RETVAL->stash = sp_Stash_new();
        
    OUTPUT:
        RETVAL


SV*
write(self, filename)
    swish_Config* self;
    char* filename;
    
    CODE:
        swish_header_write(filename, self);
        
    OUTPUT:
        filename

void
DESTROY(self)
    swish_Config* self;
    
    CODE:
        self->ref_cnt--;
               
        if (SWISH_DEBUG) {
            warn("DESTROY %s [0x%lx] [ref_cnt = %d]", 
                SvPV(ST(0), PL_na), (long)self, self->ref_cnt);
        }

        if (self->ref_cnt < 1) {
            
          sp_Stash_destroy( self->stash );
          //SWISH_WARN("set config stash to NULL");
          self->stash = NULL;
          swish_config_free( self );
          
        }
        

        
