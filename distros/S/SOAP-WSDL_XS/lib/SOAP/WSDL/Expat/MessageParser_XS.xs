/*
* set values via global variable acces, not via method calls in objects
* derived from anySimpleType
*/
#define GLOBAL_SIMPLE

/*
* use Class::Std::Fast's object caching facility
*/

#ifndef CACHING
#undef CACHING
#endif

#ifdef DEBUG
#define TRACE printf
#endif
#ifndef DEBUG
#define TRACE
#endif

#include "EXTERN.h"
#include "perl.h"
#include "ctype.h"
#include "XSUB.h"
#include "expat.h"
#include "string.h"

#ifndef XMLCALL
#if defined(_MSC_EXTENSIONS) && !defined(__BEOS__) && !defined(__CYGWIN__)
#define XMLCALL __cdecl
#elif defined(__GNUC__)
#define XMLCALL __attribute__((cdecl))
#else
#define XMLCALL
#endif
#endif

#define NSDELIM '|'

static void* mymalloc(size_t size) {
#ifndef LEAKTEST
  return safemalloc(size);
#else
  return safexmalloc(328,size);
#endif
}

static void* myrealloc(void *p, size_t s) {
#ifndef LEAKTEST
  return saferealloc(p, s);
#else
  return safexrealloc(p, s);
#endif
}

static void myfree(void *p) {
  Safefree(p);
}

static XML_Memory_Handling_Suite ms = {mymalloc, myrealloc, myfree};
static XML_Char nsdelim[] = {NSDELIM, '\0'};
static char * enc = "UTF-8";

/*
 * CallbackVector - Structure for holding data passed to expat callbacks
 *
 *
 */

typedef struct {
    HV* typemap;          // must be assigned...
    AV* list;
    SV * root;
    bool leaf;
    int bufsize;
    int buflen;
    char * buffer;
    int pathsize;
    int pathlen;
    char * path;
} CallbackVector;

SV* obj_id_ref;

#ifdef CACHING
HV* object_cache;
#endif

HV* global_attr;
HV* global_xml_attr;

#ifdef GLOBAL_SIMPLE
HV* global_simple_value;
#endif

void init (SV* object_id, SV* object_cache_ref) {
#ifdef GLOBAL_SIMPLE
    SV* value_ref;
#endif

    SV* global_attr_ref;
    SV* global_xml_attr_ref;

    if ((! SvROK(object_id))) {
        croak("Argument 1 to init (obj id counter) must be scalar ref");
    }
    obj_id_ref = newSVsv(object_id);

#ifdef CACHING
    if (object_cache_ref == &PL_sv_undef) {
        croak("Object cache not set");
    }
    object_cache = (HV*)SvRV(object_cache_ref);
    if ((SV*)object_cache == &PL_sv_undef) {
        croak("Could not get object cache - not a hash reference");
    }
#endif

    // get child alements and attributes ref global variable
    global_attr_ref = get_sv("SOAP::WSDL::XSD::Typelib::ComplexType::___attributes_of_ref", 0);
    global_xml_attr_ref = get_sv("SOAP::WSDL::XSD::Typelib::ComplexType::___xml_attribute_of_ref", 0);

    // sanity checks
    if (global_attr_ref == NULL || global_attr_ref == &PL_sv_undef) {
        croak("Can't find $SOAP::WSDL::XSD::Typelib::ComplexType::___attributes_of_ref. Do you have SOAP::WSDL >= 2.00_25 installed?");
    }
    if (SvTYPE(SvRV(global_attr_ref)) != SVt_PVHV) {
        croak("Can't deref %%{ $SOAP::WSDL::XSD::Typelib::ComplexType::___attributes_of_ref }");
    }

    if (global_xml_attr_ref == NULL || global_xml_attr_ref == &PL_sv_undef) {
        croak("Can't find $SOAP::WSDL::XSD::Typelib::ComplexType::___xml_attribute_of_ref. Do you have SOAP::WSDL >= 2.00_33 installed?");
    }
    if (SvTYPE(SvRV(global_xml_attr_ref)) != SVt_PVHV) {
        croak("Can't deref %%{ $SOAP::WSDL::XSD::Typelib::ComplexType::___xml_attribute_of_ref }");
    }

    global_attr = (HV*)SvRV(global_attr_ref);
    global_xml_attr = (HV*)SvRV(global_xml_attr_ref);

#ifdef GLOBAL_SIMPLE
    // SimpleType values with "GLOBAL_SIMPLE" optimization
    value_ref =  get_sv("SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType::___value", 0);

    // sanity checks
    if (value_ref == NULL || value_ref == &PL_sv_undef) {
        croak("Can't find $SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType::___value. Do you have SOAP::WSDL >= 2.00_25 installed?");
    }
    global_simple_value = (HV*)SvRV(value_ref);
    if ((SV*)global_simple_value == &PL_sv_undef) {
        croak("Can't find $SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType::___value");
    }
#endif
}

/*
 * SV * _create_object(char * class_c)
 *
 * Parameters:
 *  class_c : class name
 * Returns:
 *  object of the class given (with ID from Class::Std::Fast set)
*/
SV * _create_object(char * class_c) {
    SV * obj;
    // create SV
    obj = newSV(0);
    // make it a object of class_c and set it to obj_id_ref
    sv_setref_iv(obj, class_c, SvIV(SvRV(obj_id_ref)));
    // Post-Increment obj counter from Class::Std::Fast
    sv_inc( SvRV(obj_id_ref) );
    return obj;
}

/*
 * SV * create_object(char * class_c)
 *
 * Returns a cached or new object
 *
 * Parameters:
 *  class_c : class name
 * Returns:
 *  object of the class given (with ID from Class::Std::Fast set)
*/

SV* create_object (char* class_c, int class_len) {
    SV * obj;
#ifdef CACHING
    AV * pool;
    SV ** pool_ref;
    // try to retrieve cached object instead of creating a new one
    pool_ref = hv_fetch(object_cache, class_c, class_len, 0);
    // we have a pool - try to fetch from it
    if (pool_ref != NULL) {
        pool = (AV*) SvRV(*pool_ref);
        obj = av_pop(pool);

        if (! SvOK(obj)) {  // create object if we had no success
            obj = _create_object(class_c);
        }
        else {
             // TRACE("    Found object with ID %d\n", SvIV(SvRV(obj)));
        }
    }
    // we don't have a pool
    else {
        TRACE("    No pool for <%s> - not creating it\n", class_c);
        // After getting the class name, create a SV assign it a IV value (the
        // Class::Std::Fast counter), and bless it into the class...
        obj = _create_object(class_c);
    }
#endif
#ifndef CACHING
    // Duplicate code from above due to #ifdefine statements
    // After getting the class name, create a SV assign it a IV value (the
    // Class::Std::Fast counter), and bless it into the class...
    obj = _create_object(class_c);
#endif
    return obj;
}


/*
 * set_simple_value
 *
 * Sets a simpleType's value
 *
 * Parameters:
 *  SV* obj:        object to operate on
 *  SV* value_sv:   value to set
 *
 * Returns:
 *  void
 */

void set_simple_value(SV* obj, SV * value_sv) {
    // set object value via global variable access
    // set value
    SV * obj_id = SvRV(obj);
    char * ident = SvPV_nolen(obj_id);
    hv_store(global_simple_value, ident, SvCUR(obj_id), value_sv, 0);
}


/*
 * set_simple_value_from_cbv
 *
 * Sets the value of a simpleType from cbv buffers
 *
 * Parameters:
 *  CallbackVector * cbv:   CallbackVector
 *  SV* obj:                Object to operate on
 *
 * Returns:
 *  void
 */
void set_simple_value_from_cbv(CallbackVector * cbv, SV* obj) {
    SV * value_sv;
    value_sv = newSVpv(cbv->buffer, cbv->buflen);
    set_simple_value(obj, value_sv);
}

char * get_object_class(SV* obj) {
    char * class_name;
    HV * class_stash = SvSTASH(SvRV(obj));
    if ((class_stash == NULL) || ((SV*)class_stash == &PL_sv_undef)) {
        croak("No stash found");
    }
    class_name = HvNAME(class_stash);
    if (class_name == NULL) {
        croak("Ooops: Lost object class name in XS XML parser");
    }
    return class_name;
}

void add_element(const char* class_name, const char* ident, int identlen, const char* element_name, SV* value) {
    SV** class_attr_hash_ref;
    SV** attr_hash_ref;
    SV** attr_ref;
    AV* new_value;
    SV* last_obj_sv;

    // get class' attribute hash ref
    class_attr_hash_ref = hv_fetch(global_attr, class_name, strlen(class_name), 0);

    if (class_attr_hash_ref == NULL || (SV*)*class_attr_hash_ref == &PL_sv_undef) {
        croak("Cannot access child element hash for class >%s<", class_name);
    }

    attr_hash_ref = hv_fetch((HV*)SvRV(*class_attr_hash_ref), element_name, strlen(element_name), 0);

    if (attr_hash_ref == NULL || (SV*)*attr_hash_ref == &PL_sv_undef) {
        croak("Cannot access >%s< child element hash for class >%s<", element_name, class_name);
    }

    // fetch value from attribute hash
    // check if it's a hash
    if (! SvROK((SV*) *attr_hash_ref) || ! SvTYPE(SvRV((SV*) *attr_hash_ref)) == SVt_PVHV) {
        croak("Ooops - attribute store is no hash ref");
    }
    // fetch
    attr_ref = hv_fetch((HV*)SvRV(*attr_hash_ref), ident, identlen, 0);

    // if it is undef
    if (attr_ref == NULL || (SV*)*attr_ref == &PL_sv_undef) {
        TRACE("        setting previously undefined value\n");
        // store in attribute hash
        hv_store((HV*)SvRV(*attr_hash_ref), ident, strlen(ident), value, 0);
    }
    else {
        // if it's a list ref
        if ( SvTYPE(SvRV(*attr_ref)) == SVt_PVAV ){
            //TRACE("         appending value to list, refcount: %d\n", SvREFCNT(value));
            // append obj
            //
            /* The av_store below does this:
                   av_push((AV*)SvRV(*attr_ref), value);
               maybe calling SvRV twice is less efficient.
               TODO: benchmark
            */
            av_store((AV*)SvRV(*attr_ref),AvFILLp((AV*)SvRV(*attr_ref))+1,value);
        }
        else {
            TRACE("         converting to list and append value\n");

            // convert to list ref containing old value and add new value
            new_value = newAV();

            // copy old value to new SV (old one will be destroyed by
            // hv_store - we overwrite it...)
            last_obj_sv = newSV(0);
            sv_setsv(last_obj_sv,  *attr_ref);
            /*
              The two calls to av_store do what these two lines would do:
                  av_push(new_value, last_obj_sv);
                  av_push(new_value, value);
              av_store should be more efficient here: We know the indices
               to store at, as the AV to store in is new.
            */
            av_store(new_value,0,last_obj_sv);
            av_store(new_value,1,value);

            TRACE("         converted to list\n");

            // TODO maybe we can use the already computed hash value from above?
            hv_store((HV*)SvRV(*attr_hash_ref), ident, strlen(ident), newRV_noinc((SV*)new_value), 0);
        }
    }
    return;
}

/*
 * Start callback handler for libexpat
 */
void start(void * data, const XML_Char *el, const XML_Char **attr) {
    CallbackVector* cbv = data;
    SV * obj;                           // element object
    SV * attribute_set;                 // attribute set object
    SV ** class_name;                   // class name as SV**
    char * class_c;                     // class name as char *

    char * attr_var_name;               // name for attribute global in perl
    SV * xml_attr_class;                // attribute class as SV*

    XML_Char * pos = strchr(el, NSDELIM);       // set pointer on delimiter

    int element_name_len;

    // handle non-namespace qualified elements
    if (pos == NULL) {
        pos = (XML_Char*)el;
    }
    else {
        pos++;
    }
    element_name_len = strlen(pos);

    TRACE("Start: %s\n    Name: %s\n", el, pos);

    // we think we're a leaf node until we see an end...
    cbv->leaf = 1;

    // reset character buffer
    cbv->buffer[0] = cbv->buflen = 0;

    // TODO maybe use int len to store strlen? might be more efficient...
    // extend path if neccessary
    if (cbv->pathlen + element_name_len >= cbv->pathsize - 1) {
        cbv->pathsize = cbv->pathsize + element_name_len + 128;
        cbv->path = myrealloc(cbv->path, cbv->pathsize);
    }
    // $path = $path/$local_name
    if (cbv->pathlen) {
        // we can use strcat here - pos is always null-terminated
        strcat(cbv->path,"/");
        strcat(cbv->path,pos);
        cbv->pathlen = cbv->pathlen + element_name_len + 1;
    }
    else {  //$path=$localname
        // we can use strcat here - pos is always null-terminated
        strcat(cbv->path,pos);
        cbv->pathlen = cbv->pathlen + element_name_len;
    }

    // look for Envelope/Body/ in path, and set pos as pointer to the last
    // slash
    // TODO rename pos from here on - it's a bit confusing...
    pos = strstr(cbv->path, "Envelope/Body/");
    if (pos) {
        TRACE("    Path: %s\n", &pos[14]);

        // get class_name from typemap
        class_name =  hv_fetch(cbv->typemap, &pos[14], cbv->pathlen - 14,  0);
        if (class_name == NULL || (SV*)*class_name == &PL_sv_undef) {
            croak("Path %s not found in typemap\n", &pos[14]);
        }

        class_c = SvPV_nolen(*class_name);
        TRACE("    Class Name: %s\n", class_c);

        // create a object of class_c - way faster than new()
        obj = create_object(class_c, SvCUR(*class_name));
        //TRACE("    Created object wit ID %s", SvPV_nolen(obj));

        TRACE("    Checking attributes: ");
        // check whether there are attributes.
        if (*attr == NULL) {
            TRACE("no attributes\n");
        }
        else {
            char * xml_attr_class_var = mymalloc(strlen(class_c) + 22);
            sprintf(xml_attr_class_var, "%s::XML_ATTRIBUTE_CLASS", class_c);
            SV * xml_attr_class = get_sv(xml_attr_class_var, FALSE);
            if (xml_attr_class==NULL) {
                TRACE("no attribute class - ignoring attributes\n");
            }
            else {
                char * attr_class_c = SvPV_nolen(xml_attr_class);
                TRACE("attribute class %s\n", attr_class_c);
                // create AttributeSet object and set it in parent
                attribute_set = create_object(attr_class_c, SvCUR(xml_attr_class));
                // set attributes in AttributeSet object, just like setting

                // child elements
                int i;
                for (i=0;;i=i+2) {
                    if (attr[i] == NULL) {
                        break;
                    }
                    TRACE("        found attribute >%s< = >%s<\n", attr[i], attr[i+1]);
                    // lookup attribute class
                    // for now we just use "xsd:string" for all attributes
                    char * attribute_class = "SOAP::WSDL::XSD::Typelib::Builtin::string";

                    // create attribute object
                    SV* attr_obj = create_object(attribute_class, strlen(attribute_class));

                    // set value
                    SV* attr_value = newSVpv(attr[i+1], strlen(attr[i+1]));
                    set_simple_value(attr_obj, attr_value);

                    SV* ident_sv = SvRV(attribute_set);
                    // set object in attributeSet object
                    add_element(attr_class_c, SvPV_nolen(ident_sv), SvCUR(ident_sv), attr[i], attr_obj);
                }
                // we only need to put the attr_obj into the slot with
                // the current object's ID in global_xml_attr_ref
                SV * obj_id = SvRV(obj);
                char * key = SvPV_nolen(obj_id);
                hv_store(global_xml_attr, key, strlen(key), attribute_set, 0);
            }
            myfree(xml_attr_class_var);
        }
#ifdef DEBUG
        // #ifdef because SvIV(SvRV(obj))) is expensive...
        TRACE("    pushing new obj %d on stack\n", SvIV(SvRV(obj)));
#endif
        // remember object - we set it's value later, and if it's the root
        // object, we'll set root to it in end()

        // av_push(cbv->list, obj);
        // this is what av_push does - we're in for speed, remember ;-)
        av_store(cbv->list,AvFILLp(cbv->list)+1,obj);

    }

    // cleanup
    cbv->buflen = 0;
    cbv->buffer[0]=0;
}  /* End of start handler */


void end(void * data, const char *el) {
    CallbackVector* cbv = data;
    char * pos;
//    char * pathend;
    I32 len;

    SV * obj = av_pop(cbv->list);   // now obj has a refcount of 1
    SV * ident_sv;
    SV ** last_obj;

    char * class_name;
    char * ident;

    pos = strchr(el, NSDELIM);

    // handle non-namespace qualified elements
    if (pos == NULL) {
        pos = (XML_Char*)el;
    }
    else {
        pos++;
    }

    if (cbv->leaf && (cbv->buflen)) {
        set_simple_value_from_cbv(cbv, obj);
    }

    // set object attribute via global variable access
    len = av_len(cbv->list);
    if (len>=0) {
        last_obj = av_fetch(cbv->list, len, 0);


        if ( (last_obj == NULL) || ((SV*)*last_obj == &PL_sv_undef) || (! sv_isobject(*last_obj) ) )  {
            croak("No object found on stack");
        }

        //TRACE("        Found last object ID: %s\n", SvPV_nolen(SvRV(*last_obj)), cbv->path);

        class_name = get_object_class((SV*)*last_obj);
        //TRACE("        Setting child element >%s< in >%s< (%d)\n", pos, class_name, SvIV(SvRV(*last_obj)));

        // get last obj's object ID
        ident_sv = SvRV((SV*)*last_obj);
        // ident = SvPV_nolen(SvRV((SV*)*last_obj));

        add_element(class_name, SvPV_nolen(ident_sv), SvCUR(ident_sv), pos, obj);

    }
    else {
        // destroy root object - we have already saved it away...
        // TODO use this for setting root object - we need to come here anyway.
        // would save us a test in start()
        if (obj != &PL_sv_undef) {
            if (! SvTRUE(cbv->root) ) {
                sv_setsv(cbv->root, obj);
            }
            SvREFCNT_dec(obj);
        }
    }

    // cleanup
    cbv->buflen = 0;
    cbv->buffer[0] = 0;


    // remove last name from path by setting the last / to 0 byte
    // pathend = strrchr(cbv->path, '/');
    // if(pathend) {
    //    pathend[0]=0;
    //    cbv->pathlen = cbv->pathlen - strlen(pos) - 1;
    // }

    // this is faster...
    if (cbv->pathlen) {
        cbv->pathlen = cbv->pathlen - strlen(pos) - 1;
        if (cbv->pathlen > 0 ) {
            cbv->path[cbv->pathlen] = 0;
        }
        else {
            cbv->path[0] = 0;
        }
    }

    // stop thinking we might be a leaf
    cbv->leaf = 0;
}   /* End of end handler */

void chars(void* data, const XML_Char *s, int len) {
    CallbackVector * cbv = data;
    int i;

    // return if we're no leaf
    if (! cbv->leaf) {
            return;
    };

    // check whether our string consists only of whitespaces
    for (i=0;i<len;i++) {
        if (! isspace(s[i]))
            break;
    }
    // return if whitespace count == length
    if (i == len) {
        return;
    }

    // extend buffer if len > buffer size
    if (cbv->buflen + len >= cbv->bufsize) {
        cbv->bufsize = cbv->bufsize + len + 128;
        cbv->buffer = myrealloc((void*)cbv->buffer, cbv->bufsize);
    }

    // add chars to buffer and len to buffer length
    // we need strncat here - s is not null-terminated
    strncat(cbv->buffer,s,len);
    cbv->buflen += len;
    return;
}

SV* _parse_string(SV* xml, SV* typemap_ref){
    AV * list = newAV();
    SV * result = newSV(0);
    XML_Parser p;

    CallbackVector * cbv = mymalloc(sizeof(CallbackVector));
    unsigned int len = SvCUR(xml);

    if (!SvPOKp(xml)) {
        croak("Argument 1 to _parse_string (xml) must be string ref");
    }
    if ((! SvROK(typemap_ref)) || (SvTYPE(SvRV(typemap_ref)) != SVt_PVHV)) {
        croak("Argument 2 to _parse_string (typemap) must be hash ref");
    }

    p = XML_ParserCreate_MM(enc, &ms, nsdelim);
    if (! p) {
        croak( "Couldn't allocate memory for parser\n");
    }
    // initialize callback data store
    cbv->path = (char*) mymalloc(256);
    cbv->pathsize = 256;
    cbv->pathlen = 0;
    cbv->buffer = (char*) mymalloc(64);
    cbv->buffer[0] = 0;
    cbv->bufsize = 64;
    cbv->list =  list;
    cbv->typemap = (HV*)SvRV(typemap_ref);
    cbv->root = newSV(0);
    cbv->path[0] = 0;           // set path to 0-length string

    // tell expat to use cbv as user data in callbacks
    XML_SetUserData(p, cbv);

    // Set expat callback handlers
    XML_SetElementHandler(p, start, end);
    XML_SetCharacterDataHandler(p, chars);

    if (! XML_Parse(p, SvPV_nolen(xml), len, 1)) {
        croak("Parse error");
    }

    sv_setsv(result, cbv->root);

    // trigger freeing temp variables
    SvREFCNT_dec((SV*)list);
    SvREFCNT_dec((SV*)cbv->root);
    myfree((void*)cbv->path);
    myfree((void*)cbv->buffer);
    myfree(cbv);

    XML_ParserFree(p);
    return result;
}

MODULE = SOAP::WSDL::Expat::MessageParser_XS    PACKAGE = SOAP::WSDL::Expat::MessageParser_XS

PROTOTYPES: ENABLE

SV * _parse_string (xml, typemap_ref)
    SV *    xml
    SV *    typemap_ref

void init(object_id, object_cache_ref)
    SV *    object_id
    SV *    object_cache_ref


