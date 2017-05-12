/* vim: set sts=2 ts=2 expandtab bs=2 ai : */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_VERSION
#include "patchlevel.h"
#define PERL_REVISION   5
#define PERL_VERSION    PATCHLEVEL
#define PERL_SUBVERSION SUBVERSION
#endif

#include "phpinterp.h"
#include "phpfuncs.h"

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))

#    define PL_sv_undef         sv_undef
#    define PL_na               na
#    define PL_curcop           curcop
#    define PL_compiling        compiling

#endif

typedef struct {
  zval *val;
  sandwich_per_interp *interp;
} *PHP_Interpreter_Class;

typedef struct {
  zval *val;
  sandwich_per_interp *interp;
} *PHP_Interpreter_Resource;

#define PHP_Interpreter sandwich_per_interp *
#define PHP_Interpreter_Var_Scalar zval *

static int get_class_name(zval *z, char **name, zend_uint *namelen);

static int zval_is_assoc(zval *zptr)
{
  zval **entry;
  HashPosition pos;
  char *sk;
  uint skl;
  ulong nk;

  zend_hash_internal_pointer_reset_ex(Z_ARRVAL_P(zptr), &pos);
  while(zend_hash_get_current_data_ex(Z_ARRVAL_P(zptr), (void **)&entry, &pos) == SUCCESS) {
    if(zend_hash_get_current_key_ex(Z_ARRVAL_P(zptr), &sk, &skl, &nk, 1, &pos) == HASH_KEY_IS_STRING) {
      return 1;
    }
    zend_hash_move_forward_ex(Z_ARRVAL_P(zptr), &pos);
  }
  return 0;
}

zval *SvZval(SV *sv TSRMLS_DC)
{
  SV *orig_sv;
  zval *retval = NULL;
  int type;
  MAKE_STD_ZVAL(retval);

  /* derference sv as much as possible */
  orig_sv = sv;
  while(SvROK(sv) && !SvMAGICAL(sv)) {
    sv = SvRV(sv);
  }
  type = SvTYPE(sv);

  /* this is a crazy hack that seems necessary since $obj->{a} = 1 
   * set's A's type to SVt_PVLV.
   */
  if(type == SVt_PVLV) {
    if(SvIOK(sv)) type = SVt_IV;
    if(SvNOK(sv)) type = SVt_NV;
    if(SvPOK(sv)) type = SVt_PV;
  }
  switch(type) {
    case SVt_IV:   /* int */
      ZVAL_LONG(retval, SvIV(sv));
      break;
    case SVt_NV:   /* double */
      ZVAL_DOUBLE(retval, SvNV(sv));
      break;
    case SVt_PV:    /* string */
      {
        STRLEN strlen;
        char *str = SvPV(sv, strlen);
        ZVAL_STRINGL(retval, str, strlen, 1);
      }
      break;
    case SVt_RV:    /* reference */
      /* should never happen, we fully dereferenced before */
      break;
    case SVt_PVAV: /* indexed array */
      if(SvMAGICAL(sv)) {
        if(strncmp(HvNAME(SvSTASH(sv)), "PHP::Interpreter::Class::", sizeof("PHP::Interpreter::Class::") -1 ) == 0) {
          MAGIC *mg;
          PHP_Interpreter_Class pclass;
          mg = mg_find(sv, PERL_MAGIC_ext);
          if(!mg || !mg->mg_obj || !SvROK(mg->mg_obj) || !SvIOK(SvRV(mg->mg_obj))) break;
          pclass = (PHP_Interpreter_Class) SvIV(SvRV(mg->mg_obj));
          retval = pclass->val;
        } else {
          // handle non-PHP classes
          SvREFCNT_inc(orig_sv);
          plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
        }
      }
      else if(sv_isobject(orig_sv)) {
        plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
      } else {
        int i = 0;
        SV **element;
        I32 cnt = av_len((AV *)sv) + 1;
        array_init(retval);
        for(i = 0; i < cnt; i++) {
          element = av_fetch((AV *)sv, i, 0);
          if(element) {
            add_index_zval(retval, i, SvZval(*element TSRMLS_CC));
          }
        }
      }
      break;
    case SVt_PVHV: /* assoc. array */
      if(SvMAGICAL(sv)) {
        if(strncmp(HvNAME(SvSTASH(sv)), "PHP::Interpreter::Class::", sizeof("PHP::Interpreter::Class::") -1 ) == 0) {
          MAGIC *mg;
          PHP_Interpreter_Class pclass;
          mg = mg_find(sv, PERL_MAGIC_ext);
          if(!mg || !mg->mg_obj || !SvROK(mg->mg_obj) || !SvIOK(SvRV(mg->mg_obj))) break;
          pclass = (PHP_Interpreter_Class) SvIV(SvRV(mg->mg_obj));
          retval = pclass->val;
        } else {
          // handle non-PHP classes
          SvREFCNT_inc(orig_sv);
          plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
        }
      }
      else if(sv_isobject(orig_sv)) {
        plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
      }
      else {
        int i = 0;
        SV *element;
        char *key;
        I32 key_len;
        array_init(retval);
        hv_iterinit((HV *)sv);
        while((element = hv_iternextsv((HV *)sv, &key, &key_len)) != NULL) {
          add_assoc_zval_ex(retval, key, key_len + 1, SvZval(element TSRMLS_CC));
        }
      }
      break;
    case SVt_PVCV: /* code */
      plsv_wrap_sv(retval, sv TSRMLS_CC);
      break;
    case SVt_PVGV: /* glob */
      /* use orig_sv here to avoid losing your bless */
      plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
      break;
    case SVt_PVMG: /* magic */
      if(sv_isobject(orig_sv)) {
        if(strcmp(HvNAME(SvSTASH(sv)), "PHP::Interpreter::Resource") == 0) {
          PHP_Interpreter_Resource prsrc = (PHP_Interpreter_Resource) SvIV(sv);
          retval = prsrc->val;
        } else {
          /* should wrap me in a zend object */
          plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
        }
      } else {
        if(SvPOK(sv)) {
            STRLEN strlen;
            char *str = SvPV(sv, strlen);
            ZVAL_STRINGL(retval, str, strlen, 1);
        }
        else if(SvNOK(sv)) {
          ZVAL_DOUBLE(retval, SvNV(sv));
        } else if(SvIOK(sv)) {
          ZVAL_LONG(retval, SvIV(sv));
        } else {
          plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
        }
        /*
        plsv_wrap_sv(retval, orig_sv TSRMLS_CC);
        */
      }
      break;
    case SVt_PVLV: 
      break;
    default:
      ZVAL_NULL(retval);
      break;
  }
  return retval;
}

SV *newSVzval(zval *zptr, PHP_Interpreter interp)
{
  SV *retval;
  INTERP_CTX_ENTER(interp->ctx);
  {
    TSRMLS_FETCH();
    switch( zptr->type) {
      case IS_NULL:
        retval = &PL_sv_undef;
        break;
      case IS_LONG:
        retval =  newSViv(Z_LVAL_P(zptr));
        break;
      case IS_DOUBLE:
        retval =  newSVnv(Z_DVAL_P(zptr));
        break;
      case IS_BOOL:
        retval = Z_BVAL_P(zptr) ? &PL_sv_yes : &PL_sv_no;
        break;
      case IS_ARRAY:
        {
          zval **entry;
          HashPosition pos;
          char *sk;
          uint skl;
          ulong nk;
          int is_assoc = 0;
          if(zval_is_assoc(zptr)) {
            retval = (SV *) newHV();
            is_assoc = 1;
          } else {
            retval = (SV *) newAV();
            is_assoc = 0;
          }
          zend_hash_internal_pointer_reset_ex(Z_ARRVAL_P(zptr), &pos);
          while(zend_hash_get_current_data_ex(Z_ARRVAL_P(zptr), (void **)&entry, &pos) == SUCCESS) {
            switch(zend_hash_get_current_key_ex(Z_ARRVAL_P(zptr), &sk, &skl, &nk, 1, &pos)) {
              case HASH_KEY_IS_STRING:
                if(!is_assoc) { 
                  /* something bad has happened here */ 
                }
                else {
                  hv_store((HV *) retval, sk, skl - 1, newSVzval(*entry, interp), 0);
                }
                break;
              case HASH_KEY_IS_LONG:
                if(is_assoc) {
                  char buf[32];
                  snprintf(buf, sizeof(buf), "%d", nk);
                  hv_store((HV *) retval, buf, strlen(buf), newSVzval(*entry, interp), 0);
                } else {
                  av_store((AV *) retval, nk, newSVzval(*entry, interp));
                }
                break;
            }
            zend_hash_move_forward_ex(Z_ARRVAL_P(zptr), &pos);
          }
          retval = newRV_noinc(retval);
        }
        break;
      case IS_OBJECT:
          {
            char *name;
            zend_uint namelen;
            char objectname[MAXPATHLEN];
            HV *h1, *package;
            SV * c1;
            PHP_Interpreter_Class pclass;
  
            /* this is the special case that this is a perl object returning to us */
            if(Z_OBJCE_P(zptr) == plsv_ce) {
              struct plsv *pl;
              pl = (struct plsv *) zend_object_store_get_object(zptr TSRMLS_CC);
              SvREFCNT_inc(pl->sv);
              retval = pl->sv;
            } else {
              c1 = newSV(0);
              pclass = malloc(sizeof(*pclass));
              /* FIXME: don't leak! */
    
              MAKE_STD_ZVAL(pclass->val);
              ZVAL_ZVAL(pclass->val, zptr, 1, 0);
              pclass->interp = interp;
              sandwich_interp_inc_ref(interp);
              if(get_class_name(zptr, &name, &namelen) < 0) {
                name = "UNKNOWN";
              }
              snprintf(objectname, MAXPATHLEN, "PHP::Interpreter::Class::%s", name);
              sv_setref_pv(c1, "PHP::Interpreter::Class", (void *) pclass);
              h1 = (HV *)sv_2mortal((SV *)newHV());
              hv_magic(h1, (GV*)c1, PERL_MAGIC_tied);
              sv_magic((SV *)h1, c1, PERL_MAGIC_ext, NULL, -1);
              retval = newRV((SV *)h1);
              package = gv_stashpv(objectname, TRUE);
              {
                char objectisa[MAXPATHLEN];
                package = gv_stashpv(objectname, 1);
                snprintf(objectisa, MAXPATHLEN, "PHP::Interpreter::Class::%s::ISA", name);
                //if(get_av(objectisa, FALSE)) {
                  av_push(get_av(objectisa, TRUE),
                          newSVpv("PHP::Interpreter::Class", 0));
                //}
              }
              retval = sv_bless(retval, package);
            }
          }
        break;
      case IS_STRING:
        retval = newSVpv(Z_STRVAL_P(zptr), Z_STRLEN_P(zptr));
        break;
      case IS_RESOURCE:
          {
            SV * c1;
            PHP_Interpreter_Resource prsrc;
  
            c1 = newSV(0);
            prsrc = malloc(sizeof(*prsrc));
            /* FIXME: don't leak! */
            MAKE_STD_ZVAL(prsrc->val);
            ZVAL_ZVAL(prsrc->val, zptr, 1, 0);
            sandwich_interp_inc_ref(interp);
            prsrc->interp = interp;
            sv_setref_pv(c1, "PHP::Interpreter::Resource", (void *) prsrc);
            retval = newSV(0);
            sv_magic(retval, c1, PERL_MAGIC_tiedscalar, NULL, 0);
          }
        break;
      case IS_CONSTANT:
        retval = newSVpv(Z_STRVAL_P(zptr), Z_STRLEN_P(zptr));
        break;
      case IS_CONSTANT_ARRAY:
        /* FIXME: return by copy, not by reference */
        retval = &PL_sv_undef;
        break;
      default:
        { char *ptr = NULL; *ptr = 1; }
        retval = &PL_sv_undef;
        break;
    }
  }
  INTERP_CTX_LEAVE();
  return retval;
}

static int get_class_name(zval *z, char **name, zend_uint *namelen)
{
  TSRMLS_FETCH();
  if(Z_OBJ_HT_P(z)->get_class_name == NULL || Z_OBJ_HT_P(z)->get_class_name(z, name, namelen, 0 TSRMLS_CC) != SUCCESS)
  {
    zend_class_entry *ce;
    ce = zend_get_class_entry(z TSRMLS_CC);
    if(!ce) return -1;
    *name = ce->name;
    *namelen = ce->name_length;
  }
  return 0;
}

static void my_autoglobal_merge(HashTable *dest, HashTable *src TSRMLS_DC)
{
  zval **src_entry, **dest_entry;
  char *string_key;
  uint string_key_len;
  ulong num_key;
  HashPosition pos;
  int key_type;
  int globals_check = (PG(register_globals) && (dest == (&EG(symbol_table))));

  zend_hash_internal_pointer_reset_ex(src, &pos);
  while (zend_hash_get_current_data_ex(src, (void **)&src_entry, &pos) == SUCCESS) {
    key_type = zend_hash_get_current_key_ex(src, &string_key, &string_key_len, &num_key,
 0, &pos);
    if (Z_TYPE_PP(src_entry) != IS_ARRAY
      || (key_type == HASH_KEY_IS_STRING && zend_hash_find(dest, string_key, string_key_len, (void **) &dest_entry) != SUCCESS)
      || (key_type == HASH_KEY_IS_LONG && zend_hash_index_find(dest, num_key, (void **)&dest_entry) != SUCCESS)
      || Z_TYPE_PP(dest_entry) != IS_ARRAY
    ) {
      (*src_entry)->refcount++;
      if (key_type == HASH_KEY_IS_STRING) {
        /* if register_globals is on and working with main symbol table, prevent overwriting of GLOBALS */
        if (!globals_check || string_key_len != sizeof("GLOBALS") || memcmp(string_key, "GLOBALS", sizeof("GLOBALS") - 1)) {
          zend_hash_update(dest, string_key, string_key_len, src_entry, sizeof(zval *), NULL);
        } else {
          (*src_entry)->refcount--;
        }
      } else {
        zend_hash_index_update(dest, num_key, src_entry, sizeof(zval *), NULL);
      }
    } else {
      SEPARATE_ZVAL(dest_entry);
      my_autoglobal_merge(Z_ARRVAL_PP(dest_entry), Z_ARRVAL_PP(src_entry) TSRMLS_CC);
    }
    zend_hash_move_forward_ex(src, &pos);
  }
}

static my_auto_globals_create_request(void *dummy TSRMLS_DC)
{
  zval *form_variables;
  unsigned char _gpc_flags[3] = {0, 0, 0};
  char *p;

  ALLOC_ZVAL(form_variables);
  array_init(form_variables);
  INIT_PZVAL(form_variables);

  for (p = PG(variables_order); p && *p; p++) {
    switch (*p) {
      case 'g':
      case 'G':
        if (!_gpc_flags[0]) {
          my_autoglobal_merge(Z_ARRVAL_P(form_variables), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_GET]) TSRMLS_CC);
          _gpc_flags[0] = 1;
        }
        break;
      case 'p':
      case 'P':
        if (!_gpc_flags[1]) {
          my_autoglobal_merge(Z_ARRVAL_P(form_variables), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_POST]) TSRMLS_CC);
          _gpc_flags[1] = 1;
        }
        break;
      case 'c':
      case 'C':
        if (!_gpc_flags[2]) {
          my_autoglobal_merge(Z_ARRVAL_P(form_variables), Z_ARRVAL_P(PG(http_globals)[TRACK_VARS_COOKIE]) TSRMLS_CC);
          _gpc_flags[2] = 1;
        }
        break;
    }
  }

  zend_hash_update(&EG(symbol_table), "_REQUEST", sizeof("_REQUEST"), &form_variables, sizeof(zval *), NULL);
  return 0;
}


MODULE = PHP::Interpreter PACKAGE = PHP::Interpreter PREFIX=SAND_

REQUIRE:        1.9505
PROTOTYPES:     DISABLE

SV* SAND_new(classname, ...)
  char *classname;
  CODE:
    {
      PHP_Interpreter interp;
      if(sandwich_php_interpreter_create() == -1) {
        croak("Error creating Zend Runtime\n");
        RETVAL = &PL_sv_undef;
        return;
      }
      interp = sandwich_per_interp_setup();
      if(items > 1 && SvROK(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVHV)) {
        HV *args = (HV *) SvRV(ST(1));
        SV *trackvars;
        char *trackvars_key;
        I32 trackvars_keylen;
        INTERP_CTX_ENTER(interp->ctx);
        TSRMLS_FETCH();
        hv_iterinit(args);
        while((trackvars = hv_iternextsv(args, &trackvars_key, &trackvars_keylen)) != NULL) {
          HV *hv;
          SV *autoglobal;
          char *key;
          I32 keylen;
          zval *track_vars_array = NULL;

          if(!strcmp(trackvars_key, "GET")) {
            track_vars_array = PG(http_globals)[TRACK_VARS_GET];
          }
          else if(!strcmp(trackvars_key, "POST")) {
            track_vars_array = PG(http_globals)[TRACK_VARS_POST];
          }
          else if(!strcmp(trackvars_key, "COOKIE")) {
            track_vars_array = PG(http_globals)[TRACK_VARS_COOKIE];
          }
          else if(!strcmp(trackvars_key, "SERVER")) {
            track_vars_array = PG(http_globals)[TRACK_VARS_SERVER];
          }
          else if(!strcmp(trackvars_key, "ENV")) {
            track_vars_array = PG(http_globals)[TRACK_VARS_ENV];
          }
          else if(!strcmp(trackvars_key, "FILES")) {
            track_vars_array = PG(http_globals)[TRACK_VARS_FILES];
          }
/*
          else if(!strcmp(trackvars_key, "BRIC")) {
            zval *bric = SvZval(trackvars TSRMLS_CC);
            zend_register_auto_global("BRIC", sizeof("BRIC")-1, NULL TSRMLS_CC);
            zend_hash_update(&EG(symbol_table), "BRIC", sizeof("BRIC"), &bric, sizeof(zval *), NULL);
          }
*/
          else if(!strcmp(trackvars_key, "OUTPUT")) {
            sandwich_per_interp *interp = (sandwich_per_interp *)SG(server_context);
            if(interp) {
              SvREFCNT_inc(trackvars);
              interp->output_handler = trackvars;
            }
          } else if(!strcmp(trackvars_key, "INCLUDE_PATH")) {
            STRLEN strlen;
            char *str = SvPV(trackvars, strlen);
            zend_alter_ini_entry("include_path", sizeof("include_path"), str, strlen, PHP_INI_USER, PHP_INI_STAGE_RUNTIME);
          }
          else {
            /* special case - this isn't an autoglobal - register it and continue */
            int old_register_globals = PG(register_globals);
            PG(register_globals) = 1;
            php_register_variable_ex(trackvars_key, SvZval(trackvars TSRMLS_CC), NULL TSRMLS_CC);
            PG(register_globals) = old_register_globals;
            continue;
          }
          if(!SvROK(trackvars) || !(SvTYPE(SvRV(trackvars)) == SVt_PVHV)) continue;
          hv = (HV *) SvRV(trackvars);
          hv_iterinit(hv);
          while((autoglobal = hv_iternextsv(hv, &key, &keylen)) != NULL) {
            zval *zag = SvZval(autoglobal TSRMLS_CC);
            php_register_variable_ex(key, zag, track_vars_array TSRMLS_CC);
          }
        }
        my_auto_globals_create_request(NULL TSRMLS_CC);
        INTERP_CTX_LEAVE();
      }
      RETVAL = newSV(0);
      sv_setref_pv(RETVAL, classname, (void *)interp);
    }
  OUTPUT:
    RETVAL

SV *SAND_eval(interp, code)
  PHP_Interpreter interp;
  char *code;
  CODE:
    {
      RETVAL = sandwich_eval(interp, code);
    }
  OUTPUT:
    RETVAL

SV *SAND_include(interp, file)
  PHP_Interpreter interp;
  char *file;
  CODE:
    {
      if(sandwich_include(interp, file, 0) == 0) {
        RETVAL = newSVsv(ST(0));
      }
      else {
        croak("Error including %s\n", file);
        RETVAL = &PL_sv_no;
      }
    }
  OUTPUT:
    RETVAL

SV *SAND_include_once(interp, file)
  PHP_Interpreter interp;
  char *file;
  CODE:
    {
      if(sandwich_include(interp, file, 1) == 0) {
        RETVAL = newSVsv(ST(0));
      }
      else {
        croak("Error including %s\n", file);
        RETVAL = &PL_sv_no;
      }
    }
  OUTPUT:
    RETVAL

SV *SAND_call(interp, method_name, ...)
  PHP_Interpreter interp;
  char *method_name;
  CODE:
    {
      zval method;
      zval **params = NULL;
      int i;
      int param_count = 0;
      zval *retval;
      char *croakstr = NULL;
      INTERP_CTX_ENTER(interp->ctx);
      {
        TSRMLS_FETCH();
        INIT_ZVAL(method);
        ZVAL_STRING(&method, method_name, 1);
        if(items > 2) {
          params = emalloc(sizeof(zval *) * (items - 2));
          for(i = 2; i< items; i++) {
            params[i - 2] = SvZval(ST(i) TSRMLS_CC);
          }
          param_count = items - 2;
        }
        retval = sandwich_call_function(interp, &method, params, param_count);
        zval_dtor(&method);
        if(retval == NULL) {
          INTERP_CTX_LEAVE();
          croakstr = "A PHP error occurred\n";
        } else {
          RETVAL = newSVzval(retval, interp);
        }
      }
      INTERP_CTX_LEAVE();
      if(croakstr) croak(croakstr);
    }
  OUTPUT:
    RETVAL

SV *SAND_is_multithreaded(interp)
  PHP_Interpreter interp;
  CODE:
    {
#ifdef ZTS
      RETVAL = &PL_sv_yes;
#else 
      RETVAL = &PL_sv_no;
#endif
    }
  OUTPUT:
    RETVAL

SV *SAND_set_output_handler(interp, sv)
  PHP_Interpreter interp;
  SV *sv;
  CODE:
    {
      if(interp->output_handler) {
        RETVAL = interp->output_handler;
      }
      SvREFCNT_inc(sv);
      interp->output_handler = sv;
    }
  OUTPUT:
    RETVAL

void SAND_DESTROY(interp)
  PHP_Interpreter interp;
  CODE:
    {
      sandwich_interp_dec_ref(interp);
    }

SV* SAND_get_output(interp)
  PHP_Interpreter interp;
  CODE:
    {
      SV* oh = interp->output_handler;
      if(SvROK(oh) && SvPOK(SvRV(oh))) {
        RETVAL = newSVsv(SvRV(oh));
      }
      else {
        RETVAL = &PL_sv_undef;
      }
    }
  OUTPUT:
    RETVAL

void SAND_clear_output(interp)
  PHP_Interpreter interp;
  CODE:
    {
      SV* oh = interp->output_handler;
      if(SvROK(oh) && SvPOK(SvRV(oh))) {
        sv_setpvn_mg(SvRV(oh), "", 0);
      }
    }
  
SV* SAND_instantiate(interp, class, ...)
  PHP_Interpreter interp;
  char *class;
  CODE:
    {
      char *croakstr = NULL;
      zval *obj = NULL;
      INTERP_CTX_ENTER(interp->ctx);
      {
        zend_fcall_info fci;
        zval method;
        zval *retval = NULL;
        zend_class_entry *ce;
        int param_count = 0;
        zval ***params = NULL;
        zend_function *constructor;
        int i;
        TSRMLS_FETCH();
        MAKE_STD_ZVAL(obj);
        ce = zend_fetch_class(class, strlen(class), ZEND_FETCH_CLASS_DEFAULT TSRMLS_CC);
        object_init_ex(obj, ce);
        fci.size = sizeof(fci);
        fci.function_table = EG(function_table);
        fci.no_separation = 0;
        fci.object_pp = &obj;
        fci.retval_ptr_ptr = &retval;
        fci.symbol_table = NULL;
        if(items > 2) {
          params = emalloc(sizeof(zval **) * (items - 2));
          for(i = 2; i< items; i++) {
            zval *arg = SvZval(ST(i) TSRMLS_CC);
            params[i - 2] = &arg;
          }
          param_count = items - 2;
        }
        fci.param_count = param_count;
        fci.params = params;

        if(Z_OBJ_HT_P(obj)->get_constructor && (constructor = Z_OBJ_HT_P(obj)->get_constructor(obj TSRMLS_CC))) {
          INIT_ZVAL(method);
          ZVAL_STRING(&method, constructor->common.function_name, 1);
          fci.function_name = &method;
          if(zend_call_function(&fci, NULL TSRMLS_CC) == FAILURE) {
            croakstr = "an error occurred in object constructor";
          }
          zval_dtor(&method);
        }
        if(retval) zval_ptr_dtor(&retval);
        if(fci.param_count > 0) {
          int i;
          for (i=0; i < fci.param_count; i++) {
              zval_ptr_dtor(fci.params[i]);
          }
          efree(fci.params);
        }
      }
      if(obj) RETVAL = newSVzval(obj, interp);
      INTERP_CTX_LEAVE();
      if(croakstr) croak(croakstr);
    }
  OUTPUT:
    RETVAL

MODULE = PHP::Interpreter PACKAGE = PHP::Interpreter::Class PREFIX=PHP_V_C_

REQUIRE:        1.9505
PROTOTYPES:     DISABLE

SV* PHP_V_C_FETCH(pclass, key)
  PHP_Interpreter_Class pclass;
  char *key;
  CODE:
    {
      zend_class_entry *ce;
      zval *retval;
      INTERP_CTX_ENTER(pclass->interp->ctx);
      {
        TSRMLS_FETCH();

        ce = zend_get_class_entry(pclass->val TSRMLS_CC);
        retval = zend_read_property(ce, pclass->val, key, strlen(key), 0 TSRMLS_CC);
        RETVAL = newSVzval(retval, pclass->interp);
      }
      INTERP_CTX_LEAVE();
    }
  OUTPUT:
    RETVAL

SV* PHP_V_C_STORE(pclass, key, value)
  PHP_Interpreter_Class pclass;
  char *key;
  SV *value;
  CODE:
    {
      zend_class_entry *ce;
      zval *retval;

      INTERP_CTX_ENTER(pclass->interp->ctx);
      {
        zval *tostore;
        TSRMLS_FETCH();

        ce = zend_get_class_entry(pclass->val TSRMLS_CC);
        tostore =  SvZval(value TSRMLS_CC);
        if(tostore) zend_update_property(ce, pclass->val, key, strlen(key), tostore TSRMLS_CC);
        else croak("problem converting perl type to SV");
        RETVAL = newSVsv(value);
      }
      INTERP_CTX_LEAVE();
    }
  OUTPUT:
    RETVAL

SV* PHP_V_C_FIRSTKEY(pclass)
  PHP_Interpreter_Class pclass;
  CODE:
    {
      char *key;
      ulong index;
      char buf[32];
      HashTable *properties;

      INTERP_CTX_ENTER(pclass->interp->ctx);
      {
        TSRMLS_FETCH();
        properties = Z_OBJPROP_P(pclass->val);
        zend_hash_internal_pointer_reset(properties);
        switch(zend_hash_get_current_key(properties, &key, &index, 0))
        {
          case HASH_KEY_IS_STRING:
            RETVAL = newSVpv(key, 0);
            break;
          case HASH_KEY_IS_LONG:
            RETVAL = newSViv(index);
            break;
          case HASH_KEY_NON_EXISTANT:
          default:
            RETVAL = &PL_sv_undef;
            break;
        }
      }
      INTERP_CTX_LEAVE();
    }
  OUTPUT:
    RETVAL
   
SV* PHP_V_C_NEXTKEY(pclass, lastkey)
  PHP_Interpreter_Class pclass;
  char *lastkey;
  CODE:
    {
      char *key;
      ulong index;
      char buf[32];
      HashTable *properties;

      INTERP_CTX_ENTER(pclass->interp->ctx);
      {
        TSRMLS_FETCH();
        properties = Z_OBJPROP_P(pclass->val);
        zend_hash_move_forward(properties);
        switch(zend_hash_get_current_key(properties, &key, &index, 0))
        {
          case HASH_KEY_IS_STRING:
            RETVAL = newSVpv(key, 0);
            break;
          case HASH_KEY_IS_LONG:
            RETVAL = newSViv(index);
            break;
          case HASH_KEY_NON_EXISTANT:
          default:
            RETVAL = &PL_sv_undef;
            break;
        }
      }
      INTERP_CTX_LEAVE();
    }
  OUTPUT:
    RETVAL

SV* PHP_V_C_EXISTS(pclass, skey)
  PHP_Interpreter_Class pclass;
  SV *skey;
  CODE:
    {
      char *key;
      uint keylen;
      HashTable *properties;

      INTERP_CTX_ENTER(pclass->interp->ctx);
      {
        TSRMLS_FETCH();
        properties = Z_OBJPROP_P(pclass->val);
        key = SvPV(skey, keylen);
        if(zend_hash_exists(properties, key, keylen + 1)) {
          RETVAL = &PL_sv_yes;
        } else {
          RETVAL = &PL_sv_no;
        }
      }
      INTERP_CTX_LEAVE();
    }
  OUTPUT:
    RETVAL
 
SV *PHP_V_C_DELETE(pclass, skey)
  PHP_Interpreter_Class pclass;
  SV *skey;
  CODE:
    {
      char *key;
      uint keylen;
      HashTable *properties;
      zval zkey;

      INTERP_CTX_ENTER(pclass->interp->ctx);
      {
        TSRMLS_FETCH();
        properties = Z_OBJPROP_P(pclass->val);
        key = SvPV(skey, keylen);
        INIT_ZVAL(zkey);
        ZVAL_STRINGL(&zkey, key, keylen, 1);
        /*
        if(Z_OBJ_HT_P(pclass->val)->unset_property(pclass->val, &zkey TSRMLS_CC)) {
          RETVAL = &PL_sv_yes;
        } else {
          RETVAL = &PL_sv_no;
        }
        */
        Z_OBJ_HT_P(pclass->val)->unset_property(pclass->val, &zkey TSRMLS_CC);
        RETVAL = &PL_sv_yes;
        zval_dtor(&zkey);
      }
      INTERP_CTX_LEAVE();
    }
  OUTPUT:
    RETVAL

SV *PHP_V_C__AUTOLOAD(self, method_name, ...)
  SV *self;
  char *method_name;
  CODE:
    {
      PHP_Interpreter_Class pclass;
      MAGIC *mg;
      zval method;
      zval ***params = NULL;
      zval calling_obj;
      int i;
      int param_count = 0;
      zval *retval;
      PHP_Interpreter interp;
      char *croakstr = NULL;

      mg = mg_find((SvRV(self)), PERL_MAGIC_ext);
      pclass = (PHP_Interpreter_Class) SvIV(SvRV(mg->mg_obj));

      interp = pclass->interp;

      INTERP_CTX_ENTER(interp->ctx);
      {
        zend_fcall_info fci;
        TSRMLS_FETCH();
        //INIT_ZVAL(calling_obj);
        //array_init(&calling_obj);
  
        INIT_ZVAL(method);
        ZVAL_STRING(&method, method_name, 1);
       
        
        //PZVAL_IS_REF(pclass->val) = 1;
        //zval_add_ref(&pclass->val);
        //add_index_zval(&calling_obj, 0, pclass->val);
        //add_index_zval(&calling_obj, 1, &method);
       
        //if(!zend_is_callable(&calling_obj, 0, NULL)) {
        //  croakstr = "Function not callable";
        //  goto cleanup;
        //}
        if(items > 2) {
          params = emalloc(sizeof(zval **) * (items - 2));
          for(i = 2; i< items; i++) {
            zval *arg = SvZval(ST(i) TSRMLS_CC);
            params[i - 2] = &arg;
          }
          param_count = items - 2;
        }
        fci.param_count = param_count;
        fci.params = params;
        fci.size = sizeof(fci);
        fci.function_table = EG(function_table);
        fci.function_name = &method;
        fci.no_separation = 0;
        fci.object_pp = &pclass->val;
        fci.retval_ptr_ptr = &retval;
/* 
        if(call_user_function_ex(EG(function_table), NULL, &calling_obj, &retval, param_count, &params, 0, NULL TSRMLS_CC) != SUCCESS) {
          fprintf(stderr, "an error occurred calling %s\n", method_name);
          RETVAL = &PL_sv_undef;
        } 
*/
        if(zend_call_function(&fci, NULL TSRMLS_CC) == FAILURE) {
          croakstr = "an error occurred while calling your method";
        }
        else {
          switch(retval->type) {
            case IS_NULL:
              RETVAL = &PL_sv_undef;
              break;
            case IS_LONG:
            case IS_BOOL:
            case IS_DOUBLE:
            case IS_STRING:
              RETVAL = newSVzval(retval, pclass->interp);
              /*
  
              SV * c1 = sv_newmortal();
              RETVAL = newSV(0);
              sv_setref_pv(c1, "PHP::Interpreter::Var::Scalar", (void *) retval);
              sv_magic(RETVAL, c1, PERL_MAGIC_tiedscalar, NULL, 0);
  
              */
              break;
            case IS_ARRAY:
              RETVAL = newSVzval(retval, pclass->interp);
              break;
            case IS_OBJECT: 
              {
                char *name;
                zend_uint namelen;
                char objectname[MAXPATHLEN];
                HV *h1, *package;
                SV * c1;
                PHP_Interpreter_Class pclass;
  
                c1 = newSV(0);
                pclass = malloc(sizeof(*pclass));
                /* FIXME: don't leak! */
                pclass->val = retval;
                pclass->interp = interp;
                if(get_class_name(retval, &name, &namelen) < 0) {
                  name = "UNKNOWN";
                } 
                snprintf(objectname, MAXPATHLEN, "PHP::Interpreter::Class::%s", name);
                sv_setref_pv(c1, "PHP::Interpreter::Class", (void *) pclass);
                h1 = (HV *)sv_2mortal((SV *)newHV());
                hv_magic(h1, (GV*)c1, PERL_MAGIC_tied);
                RETVAL = newRV((SV *)h1);
                package = gv_stashpv(objectname, TRUE);
                {
                  char objectisa[MAXPATHLEN];
                  package = gv_stashpv(objectname, 1);
                  snprintf(objectisa, MAXPATHLEN, "PHP::Interpreter::Class::%s::ISA", name);
                  //if(get_av(objectisa, FALSE)) {
                    av_push(get_av(objectisa, TRUE),
                            newSVpv("PHP::Interpreter::Class", 0));
                  //}
                }
                sv_setref_pv(RETVAL, objectname, (void *) pclass);
                //RETVAL = sv_bless(RETVAL, package);
              }
            case IS_RESOURCE:
                {
                  SV * c1;
                  PHP_Interpreter_Resource prsrc;

                  c1 = newSV(0);
                  prsrc = malloc(sizeof(*prsrc));
                  /* FIXME: don't leak! */
                  prsrc->val = retval;
                  prsrc->interp = interp;
                  sandwich_interp_inc_ref(interp);
                  RETVAL = newSV(0);
                  sv_setref_pv(c1, "PHP::Interpreter::Resource", (void *) prsrc);
                  sv_magic(RETVAL, c1, PERL_MAGIC_tiedscalar, NULL, 0);
                }
              break;
              break;
            default:
              fprintf(stderr, "unsupported return type in PHP_Interpreter_call\n");
              RETVAL = &PL_sv_undef;
              break;
          }
        }
  cleanup:
        /* FIXME: this dtor must not destroy pclass->val */
        //zval_dtor(&calling_obj);
        if(fci.param_count > 0) {
          int i;
          for (i=0; i < fci.param_count; i++) {
              zval_ptr_dtor(fci.params[i]);
          }
          efree(fci.params);
        }
        zval_dtor(&method);
        INTERP_CTX_LEAVE();
      }
      if(croakstr) croak(croakstr);
    }
  OUTPUT:
    RETVAL

void PHP_V_C_DESTROY(in)
  SV *in;
  CODE:
    {
      PHP_Interpreter_Class pclass;
      MAGIC *mg;
      
      mg = mg_find((SvRV(in)), PERL_MAGIC_ext);
      if(!mg || !mg->mg_obj || !SvROK(mg->mg_obj) || !SvIOK(SvRV(mg->mg_obj))) return;
      pclass = (PHP_Interpreter_Class) SvIV(SvRV(mg->mg_obj));
      if(!pclass) return;
      INTERP_CTX_ENTER(pclass->interp->ctx);
      {
        TSRMLS_FETCH();
        zval_ptr_dtor(&pclass->val);
      }
      INTERP_CTX_LEAVE();
      /* potentially shutdown ZE */
      sandwich_interp_dec_ref(pclass->interp);
      free(pclass);
    }

MODULE = PHP::Interpreter PACKAGE = PHP::Interpreter::Resource PREFIX=PHP_V_R_

REQUIRE:        1.9505
PROTOTYPES:     DISABLE

PHP_Interpreter_Resource PHP_V_R_FETCH(zptr)
  PHP_Interpreter_Resource zptr;
  PHP_Interpreter_Resource rv;
  CODE:
    {
      INTERP_CTX_ENTER(zptr->interp->ctx);
      RETVAL = malloc(sizeof(*RETVAL));
      MAKE_STD_ZVAL(RETVAL->val);
      ZVAL_ZVAL(RETVAL->val, zptr->val, 1, 0);
      RETVAL->interp = zptr->interp;
      sandwich_interp_inc_ref(zptr->interp);
      INTERP_CTX_LEAVE();
    }
  OUTPUT:
    RETVAL

void PHP_V_R_STORE(zptr, new)
  PHP_Interpreter_Resource zptr;
  SV *new;
  CODE:
    {
    }

void PHP_V_R_DESTROY(prsrc)
  PHP_Interpreter_Resource prsrc;
  CODE:
    {
      if(!prsrc || !prsrc->interp) return;
      INTERP_CTX_ENTER(prsrc->interp->ctx);
      {
        TSRMLS_FETCH();
        zval_ptr_dtor(&prsrc->val);
      }
      INTERP_CTX_LEAVE();
      /* potentially shutdown ZE */
      sandwich_interp_dec_ref(prsrc->interp);
      free(prsrc);
    }
