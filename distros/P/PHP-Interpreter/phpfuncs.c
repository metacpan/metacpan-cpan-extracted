#include <EXTERN.h>
#include <perl.h>
#include <perlapi.h>

#include "phpinterp.h"
#include "phpfuncs.h"
#include "zend_interfaces.h"


ZEND_DECLARE_MODULE_GLOBALS(sandwich);
zend_class_entry *pl_ce;
zend_class_entry *plobj_ce;
zend_class_entry *plsv_ce;

static zend_object_handlers plobj_handlers;
static zend_object_handlers plsv_handlers;

static zend_object_value plobj_create_object(zend_class_entry *ce TSRMLS_DC);
static zend_object_value plsv_create_object(zend_class_entry *ce TSRMLS_DC);


PHP_MINFO_FUNCTION(sandwich)
{
  php_info_print_table_start();
  php_info_print_table_row(2, "Loaded Modules", "Perl Sandwich");
  php_info_print_table_end();
}

static void
sw_initglobals(zend_sandwich_globals *swg)
{
  memset(&swg->ps_stats, 0, sizeof(swg->ps_stats));
}

static zval *
sandwich_dim_read(zval *obj, zval *offset, int type TSRMLS_DC)
{
  SV           *value;
  zval         *return_value;
  struct plobj *pl;
  char         *name;

  pTHX;

  pl = zend_object_store_get_object(obj TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  value = NULL;
  
  if (Z_TYPE_P(offset) != IS_STRING) {
    goto err_out;
  }

  name = Z_STRVAL_P(offset);
  if (Z_STRLEN_P(offset) < 2) {
    goto err_out;
  }

  switch (name[0]) {
    case '$':
      value = get_sv(name + 1, FALSE);
      break;
    case '@':
      value = (SV *) get_av(name + 1, FALSE);
      break;
    case '%':
      value = (SV *) get_hv(name + 1, FALSE);
      break;
  }

  if (!value) {
    goto err_out;
  }

  return_value = SvZval(value TSRMLS_CC);
  return return_value;
  
err_out:
  MAKE_STD_ZVAL(return_value);
  ZVAL_NULL(return_value);
  return return_value;
}

static void
sandwich_dim_write(zval *obj, zval *offset, zval *value TSRMLS_DC)
{
  return;
}

PHP_METHOD(perl, getvariable)
{
  struct plobj *pl;
  SV           *var;
  zval         *retval;
  char         *name;
  int           namelen;
  pTHX;

  if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &name, &namelen) == FAILURE) {
    return;
  }

  if (namelen < 1) {
    RETURN_NULL();
  }
  
  pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  dSP;
  var = NULL;
  if(strchr(name, '[') || strchr(name, '{')) {
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUTBACK;
    var = eval_pv(name, G_VOID);
    SvREFCNT_inc(var);
    FREETMPS; LEAVE;
  } else {
    switch (name[0]) {
      case '$':
        var =  get_sv(name + 1, FALSE);
        break;
      case '@':
        var = (SV *) get_av(name + 1, FALSE);
        break;
      case '%':
        var = (SV *) get_hv(name + 1, FALSE);
        break;
      default:
        RETURN_NULL();
    }
  }
  if (var != NULL) {
    retval = SvZval(var TSRMLS_CC);
    RETURN_ZVAL(retval, 1, 0);
  } else {
    RETURN_NULL();
  }
}

PHP_METHOD(perl, setvariable)
{
  struct plobj *pl;
  SV           *var;
  zval         *retval;
  char         *name;
  int           namelen;
  zval         *param;
  SV           *sparam;
  pTHX;

  if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "sz", &name, &namelen, &param) == FAILURE) {
    return;
  }

  if (namelen < 1) {
    RETURN_NULL();
  }
  
  pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  var = NULL;
  
  switch (name[0]) {
    case '$':
      var =  get_sv(name + 1, FALSE);
      sparam = newSVzval(param, SandwichG(php));
      sv_setsv(var, sparam);
      break;
    case '@':
      /* check type require param IS_ARRAY, maybe IS_OBJECT */
      var = (SV *) get_av(name + 1, FALSE);
      RETURN_NULL();
      break;
    case '%':
      /* check type require param IS_ARRAY, maybe IS_OBJECT */
      var = (SV *) get_hv(name + 1, FALSE);
      RETURN_NULL();
      break;
    default:
      RETURN_NULL();
  }
  RETURN_TRUE;
}

static int _sandwich_call_method(char *method, INTERNAL_FUNCTION_PARAMETERS, int offset)
{
  struct plobj *pl;
  SV           *var;
  zval         *retval;
  char         *name;
  int           namelen;
  zval         *param;
  zval         ***args;
  SV           *sparam;
  int          argc, i;
  SV           *prv;
  pTHX;

  pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  {
    int cnt;
    STRLEN n_a;
    dSP;
  
    argc = ZEND_NUM_ARGS();
    args = (zval ***) safe_emalloc(sizeof(zval **), argc, 0);
    if(zend_get_parameters_array_ex(argc, args) == FAILURE) {
      efree(args);
      WRONG_PARAM_COUNT;
    }
    
    pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
    aTHX = pl->perl;
#endif  
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    if(offset < argc) EXTEND(SP, argc - offset);
    for(i = offset; i < argc; i++) {
      var = newSVzval(*args[i], SandwichG(php));
      var = sv_2mortal(var);
      XPUSHs(var);
    }
    PUTBACK;
    cnt = call_pv(method, G_SCALAR | G_EVAL | G_KEEPERR);
    SPAGAIN;
    if(cnt == 1) {
      prv = POPs;
      SvREFCNT_inc(prv);
      retval = SvZval(prv TSRMLS_CC);
      RETVAL_ZVAL(retval, 1, 0);
    } else {
      RETVAL_NULL();
    }
    if(SvTRUE(ERRSV)) {
    //  croak(SvPVx(ERRSV, n_a));
    }
    PUTBACK;
    FREETMPS; LEAVE;
    efree(args);
  }
}

static int sandwich_call_method(char *method, INTERNAL_FUNCTION_PARAMETERS)
{
  return _sandwich_call_method(method, INTERNAL_FUNCTION_PARAM_PASSTHRU, 0);
}

PHP_METHOD(perl, call)
{
  zval **name[1];
  if(ZEND_NUM_ARGS() < 1) {
    WRONG_PARAM_COUNT;
  }
  if(zend_get_parameters_array_ex(1, name) == FAILURE) {
      WRONG_PARAM_COUNT;
  } else if(Z_TYPE_PP(name[0]) != IS_STRING) {
      WRONG_PARAM_COUNT;
  }
  _sandwich_call_method(Z_STRVAL_PP(name[0]), INTERNAL_FUNCTION_PARAM_PASSTHRU, 1);
}

static PHP_FUNCTION(sandwich_method_handler)
{
  _sandwich_call_method(
    ((zend_internal_function*)EG(function_state_ptr)->function)->function_name,
    INTERNAL_FUNCTION_PARAM_PASSTHRU, 0);
}

static union _zend_function *sandwich_get_method(zval **object_ptr, char *name, int len TSRMLS_DC)
{
  zval *object = *object_ptr;
  zend_internal_function f, *fptr = NULL;
  union _zend_function *func;
  struct plobj *pl;
  char *lc_method_name;

  lc_method_name = emalloc(len + 1);
  zend_str_tolower_copy(lc_method_name, name, len);
  if (zend_hash_find(&plobj_ce->function_table, lc_method_name, len+1, (void**)&func) == SUCCESS) {
    efree(lc_method_name);
    return func;
  }
  efree(lc_method_name);
  
  f.type = ZEND_OVERLOADED_FUNCTION;
  f.num_args = 0;
  f.arg_info = NULL;
  f.scope = plobj_ce;
  f.fn_flags=0;
  f.function_name= estrndup(name, len);
  f.handler= PHP_FN(sandwich_method_handler);

  func = emalloc(sizeof(*func));
  memcpy(func, &f,sizeof(f));
  return func;
}

PHP_METHOD(perl, getinstance)
{
  struct plobj *pl;

  if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "") == FAILURE) {
    return;
  }


  return_value->type = IS_OBJECT;
  return_value->value.obj = plobj_create_object(plobj_ce TSRMLS_CC);
}

SV *my_eval_sv(pTHX_ SV *sv, I32 coe) {
  SV *retval = &PL_sv_undef;
  STRLEN n_a;
  int cnt;
  dSP;
  dMARK;

  ENTER; SAVETMPS;
  eval_sv(sv, G_SCALAR|G_EVAL);
 
  SPAGAIN;
  retval = POPs;
  SvREFCNT_inc(retval);
  PUTBACK;
  FREETMPS; LEAVE;

  if(SvTRUE(ERRSV)) {
    croak(SvPVx(ERRSV, n_a));
  }
  return retval;
}

static SV *sandwich_perl_eval(pTHX_ char *command_in) {
  SV *retval;
  SV *command;
  command = newSVpv(command_in, 0);
  retval = my_eval_sv(aTHX_ command, FALSE);
  return retval;
}

PHP_METHOD(perl, eval)
{
  struct plobj *pl;
  char *func;
  long funclen;
  SV *rv;
  pTHX;

  if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &func, &funclen) == FAILURE) {
    return;
  }
  pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  if((rv = sandwich_perl_eval(aTHX_ func)) == NULL)  { 
  } else {
    zval *retval = SvZval(rv TSRMLS_CC);
    RETURN_ZVAL(retval, 1, 0);
  }
}

PHP_METHOD(perl, new)
{
  struct plobj *pl;
  SV           *var;
  zval         *retval;
  zval         *param;
  zval         ***args;
  SV           *sparam;
  int          argc, i;
  SV           *prv;
  zval **name[1];

  pTHX;

  if(ZEND_NUM_ARGS() < 1) {
    WRONG_PARAM_COUNT;
  }
  if(zend_get_parameters_array_ex(1, name) == FAILURE) {
      WRONG_PARAM_COUNT;
  } else if(Z_TYPE_PP(name[0]) != IS_STRING) {
      WRONG_PARAM_COUNT;
  }

  pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  {
    int cnt;
    STRLEN n_a;
    dSP;
  
    argc = ZEND_NUM_ARGS();
    args = (zval ***) safe_emalloc(sizeof(zval **), argc, 0);
    if(zend_get_parameters_array_ex(argc, args) == FAILURE) {
      efree(args);
      WRONG_PARAM_COUNT;
    }
    
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc + 1);
    for(i = 0; i < argc; i++) {
      var = newSVzval(*args[i], SandwichG(php));
      var = sv_2mortal(var);
      XPUSHs(var);
    }
    PUTBACK;
    cnt = call_method("new", G_SCALAR | G_EVAL);
    SPAGAIN;
    if(cnt == 1) {
      prv = POPs;
      SvREFCNT_inc(prv);
      retval = SvZval(prv TSRMLS_CC);
      RETVAL_ZVAL(retval, 1, 0);
    } else {
      RETVAL_NULL();
    }
    if(SvTRUE(ERRSV)) {
    //  croak(SvPVx(ERRSV, n_a));
    }
    PUTBACK;
    FREETMPS; LEAVE;
    efree(args);
  }
}

PHP_METHOD(perl, call_method)
{
  struct plobj *pl;
  SV           *var;
  zval         *retval;
  zval         *param;
  zval         ***args;
  SV           *sparam;
  int          argc, i;
  SV           *prv;
  zval **name[2];

  pTHX;

  if(ZEND_NUM_ARGS() < 2) {
    WRONG_PARAM_COUNT;
  }
  if(zend_get_parameters_array_ex(2, name) == FAILURE) {
      WRONG_PARAM_COUNT;
  } else if(Z_TYPE_PP(name[0]) != IS_STRING || Z_TYPE_PP(name[1]) != IS_STRING) {
      WRONG_PARAM_COUNT;
  }

  pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  {
    int cnt;
    STRLEN n_a;
    dSP;
  
    argc = ZEND_NUM_ARGS();
    args = (zval ***) safe_emalloc(sizeof(zval **), argc, 0);
    if(zend_get_parameters_array_ex(argc, args) == FAILURE) {
      efree(args);
      WRONG_PARAM_COUNT;
    }
    
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc + 1);
    for(i = 0; i < argc; i++) {
      /* skip the first arg, we'll pass this to call_method */
      if(i == 1) continue;
      var = newSVzval(*args[i], SandwichG(php));
      var = sv_2mortal(var);
      XPUSHs(var);
    }
    PUTBACK;
    cnt = call_method(Z_STRVAL_PP(name[1]), G_SCALAR | G_EVAL);
    SPAGAIN;
    if(cnt == 1) {
      prv = POPs;
      SvREFCNT_inc(prv);
      retval = SvZval(prv TSRMLS_CC);
      RETVAL_ZVAL(retval, 1, 0);
    } else {
      RETVAL_NULL();
    }
    if(SvTRUE(ERRSV)) {
    //  croak(SvPVx(ERRSV, n_a));
    }
    PUTBACK;
    FREETMPS; LEAVE;
    efree(args);
  }
}

static zval *
sv_prop_read(zval *obj, zval *member, int type TSRMLS_DC)
{
  SV           *sv, **value;
  HV           *hash;
  zval         *return_value;
  struct plsv  *pl;
  char         *key;
  long         keylen;
  pTHX;

  pl = zend_object_store_get_object(obj TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  value = NULL;
  sv = pl->sv;
  if(!SvROK(sv)) RETURN_FALSE;
  sv = SvRV(sv);
  if(SvTYPE(sv) == SVt_PVHV) {
    hash = (HV *) sv;
  } else if(SvTYPE(sv) == SVt_PVGV) {
    hash =  SvSTASH(sv);
  } else {
    goto err_out;
  }
  key = Z_STRVAL_P(member);
  keylen = Z_STRLEN_P(member);

  value = hv_fetch(hash, key, keylen, 1);
  if (!value) {
    goto err_out;
  }
  if(SvMAGICAL(*value)){
    mg_get(*value);
  }
  return_value = SvZval(*value TSRMLS_CC);
  return return_value;
  
err_out:
  MAKE_STD_ZVAL(return_value);
  ZVAL_NULL(return_value);
  return return_value;
}

static void
sv_prop_write(zval *object, zval *member, zval *value TSRMLS_DC)
{
  SV           *sv, **svpp;
  HV           *hash;
  zval         *return_value;
  struct plsv  *pl;
  char         *key;
  long         keylen;
  pTHX;

  pl = zend_object_store_get_object(object TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  sv = pl->sv;
  if(!SvROK(sv)) RETURN_FALSE;
  sv = SvRV(sv);
  if(SvTYPE(sv) == SVt_PVHV) {
    hash = (HV *) sv;
  } else if(SvTYPE(sv) == SVt_PVGV) {
    hash =  SvSTASH(sv);
  } else {
    return;
  }
  key = Z_STRVAL_P(member);
  keylen = Z_STRLEN_P(member);
  svpp = hv_store(hash, key, keylen, newSVzval(value, SandwichG(php)), 0);
  if(svpp && SvMAGICAL(*svpp)) {
    mg_set(*svpp);
  }
}

static int
sv_prop_exists(zval *object, zval *member, int has_set_exists TSRMLS_DC)
{
  SV           *sv, **value;
  HV           *hash;
  zval         *return_value;
  struct plsv  *pl;
  char         *key;
  long         keylen;
  pTHX;

  pl = zend_object_store_get_object(object TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  value = NULL;
  sv = pl->sv;
  if(!SvROK(sv)) RETURN_FALSE;
  sv = SvRV(sv);
  if(SvTYPE(sv) == SVt_PVHV) {
    hash = (HV *) sv;
  } else {
    return FAILURE;
  }
  key = Z_STRVAL_P(member);
  keylen = Z_STRLEN_P(member);
  return hv_exists(hash, key, keylen);
}

static int _sv_call_method(char *method, INTERNAL_FUNCTION_PARAMETERS, int offset)
{
  struct plsv *pl;
  SV           *var;
  zval         *retval;
  char         *name;
  int           namelen;
  zval         *param;
  zval         ***args;
  SV           *sparam;
  int          argc, i;
  SV           *prv;
  int          cnt;
  pTHX;

  pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  {
    STRLEN n_a;
    dSP;
    I32 oldscope = PL_scopestack_ix;
    argc = ZEND_NUM_ARGS();
    args = (zval ***) safe_emalloc(sizeof(zval **), argc, 0);
    if(zend_get_parameters_array_ex(argc, args) == FAILURE) {
      efree(args);
      WRONG_PARAM_COUNT;
    }
    pl = zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
    aTHX = pl->perl;
#endif  
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc);
    SvREFCNT_inc(pl->sv);
    XPUSHs(pl->sv);
    for(i = offset; i < argc; i++) {
      var = newSVzval(*args[i], SandwichG(php));
      var = sv_2mortal(var);
      XPUSHs(var);
    }
    PUTBACK;
    cnt = call_method(method, G_SCALAR | G_EVAL);
    SvREFCNT_dec(pl->sv);
    SPAGAIN;
    if(cnt == 1) {
        prv = POPs;
      /*
      if(coe && SvTRUE(ERRSV)) {
        croak(SvPVx(ERRSV, n_a));
      }
      */
      SvREFCNT_inc(prv);
      retval = SvZval(prv TSRMLS_CC);
      RETVAL_ZVAL(retval, 1, 0);
    } else {
      RETVAL_NULL();
    }
    PUTBACK;
    FREETMPS; LEAVE;
    if(SvTRUE(ERRSV)) {
    //  croak(SvPVx(ERRSV, n_a));
    }
    efree(args);
  }
}

static PHP_FUNCTION(sv_method_handler)
{
  _sv_call_method(
    ((zend_internal_function*)EG(function_state_ptr)->function)->function_name,
    INTERNAL_FUNCTION_PARAM_PASSTHRU, 0);
}

static int sv_call_method(char *method, INTERNAL_FUNCTION_PARAMETERS)
{
  return _sv_call_method(method, INTERNAL_FUNCTION_PARAM_PASSTHRU, 0);
}

static union _zend_function *sv_get_method(zval **object_ptr, char *name, int len TSRMLS_DC)
{
  zval *object = *object_ptr;
  zend_internal_function f, *fptr = NULL;
  union _zend_function *func;
  struct plobj *pl;
  char *lc_method_name;

  lc_method_name = emalloc(len + 1);
  zend_str_tolower_copy(lc_method_name, name, len);
  if (zend_hash_find(&plsv_ce->function_table, lc_method_name, len+1, (void**)&func) == SUCCESS) {
    efree(lc_method_name);
    return func;
  }
  efree(lc_method_name);
  
  f.type = ZEND_OVERLOADED_FUNCTION;
  f.num_args = 0;
  f.arg_info = NULL;
  f.scope = plobj_ce;
  f.fn_flags=0;
  f.function_name= estrndup(name, len);
  f.handler= PHP_FN(sv_method_handler);

  func = emalloc(sizeof(*func));
  memcpy(func, &f,sizeof(f));
  return func;
}

int sv_get_class_name(zval *obj, char **class_name, zend_uint *class_name_len, int parent TSRMLS_DC) 
{
  if(parent) {
    *class_name_len = strlen("PerlSV") + 1;
    *class_name = estrndup("PerlSV", *class_name_len);
  } else {
    pTHX;
    struct plsv *pl;
    char *tmp;
    pl = (struct plsv *) zend_object_store_get_object(obj TSRMLS_CC);
#ifdef USE_ITHREADS
    aTHX = pl->perl;
#endif
    if(!sv_isobject(pl->sv)) {
      *class_name_len = strlen("PerlSV") + 1;
      *class_name = estrndup("PerlSV", *class_name_len);
    } else {
      tmp = HvNAME((SvSTASH(SvRV(pl->sv))));
      if(!tmp) return FAILURE;
      *class_name_len = strlen(tmp) + sizeof("PerlSV::") - 1;
      *class_name = emalloc(*class_name_len + 1);
      strncpy(*class_name, "PerlSV::", sizeof("PerlSV::"));
      strcat(*class_name, tmp);
    }
  }
  return SUCCESS;
}

static void stderr_dump(char *in, int inlen) {
  fwrite(in, inlen, 1, stderr);
}

PHP_METHOD(perlsv, __tostring)
{
  struct plsv *pl;
  char         *string;
  STRLEN       stringlen;
  pTHX;
  
  if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "") == FAILURE) {
    return;
  }
  pl = (struct plsv *) zend_object_store_get_object(getThis() TSRMLS_CC);
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  string = SvPV(pl->sv, stringlen);
  RETURN_STRINGL(string, stringlen, 1);
}  

PHP_METHOD(perlsv, call)
{
  struct plsv  *pl;
  SV           *var;
  zval         *retval;
  char         *name;
  int           namelen;
  zval         *param;
  zval         ***args;
  SV           *sparam;
  int          argc, i;
  SV           *prv;
  pTHX;

  pl = (struct plsv *) zend_object_store_get_object(getThis() TSRMLS_CC);
  if(!pl->sv || SvTYPE(pl->sv) != SVt_PVCV) {
    /* fixme, be more descriptive */
    WRONG_PARAM_COUNT;
  }
#ifdef USE_ITHREADS
  aTHX = pl->perl;
#endif
  {
    int cnt;
    STRLEN n_a;
    dSP;
  
    argc = ZEND_NUM_ARGS();
    args = (zval ***) safe_emalloc(sizeof(zval **), argc, 0);
    if(zend_get_parameters_array_ex(argc, args) == FAILURE) {
      efree(args);
      WRONG_PARAM_COUNT;
    }
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    if(argc) EXTEND(SP, argc);
    for(i = 0; i < argc; i++) {
      var = newSVzval(*args[i], SandwichG(php));
      var = sv_2mortal(var);
      XPUSHs(var);
    }
    PUTBACK;
    cnt = call_sv(pl->sv, G_SCALAR | G_EVAL | G_KEEPERR);
    SPAGAIN;
    if(cnt == 1) {
      prv = POPs;
      SvREFCNT_inc(prv);
      retval = SvZval(prv TSRMLS_CC);
      RETVAL_ZVAL(retval, 1, 0);
    } else {
      RETVAL_NULL();
    }
    if(SvTRUE(ERRSV)) {
    //  croak(SvPVx(ERRSV, n_a));
    }
    PUTBACK;
    FREETMPS; LEAVE;
    efree(args);
  }
}

struct plsv_iterator {
  zend_object_iterator iter;
  SV *sv;
  HV *hv;
  char *key;
  uint keylen;
  zval *fetch_ahead;
};

static void plsv_iter_dtor(zend_object_iterator *iter TSRMLS_DC)
{
  dTHX;
  struct plsv_iterator *I = (struct plsv_iterator*)iter->data;
  if (I->fetch_ahead) {
    ZVAL_DELREF(I->fetch_ahead);
    I->fetch_ahead = NULL;
  }
  if (I->key) {
    efree(I->key);
  }
  if(I->sv) {
    SvREFCNT_dec(I->sv);
  }
  efree(I);
}

static int plsv_iter_valid(zend_object_iterator *iter TSRMLS_DC)
{
  struct plsv_iterator *I = (struct plsv_iterator*)iter->data;
  if(!I->hv) return FAILURE;
  return I->fetch_ahead ? SUCCESS : FAILURE;
}

static void plsv_iter_get_data(zend_object_iterator *iter, zval ***data TSRMLS_DC)
{
  struct plsv_iterator *I = (struct plsv_iterator*)iter->data;
  zval **ptr_ptr;

  /* sanity */
  if (!I->fetch_ahead) {
      *data = NULL;
      return;
  }

  ptr_ptr = emalloc(sizeof(*ptr_ptr)); /* leaks somewhere */
  *ptr_ptr = I->fetch_ahead;
  ZVAL_ADDREF(I->fetch_ahead);
  *data = ptr_ptr;
}

static int plsv_iter_get_key(zend_object_iterator *iter, char **str_key, uint *str_key_len,
    ulong *int_key TSRMLS_DC)
{
  struct plsv_iterator *I = (struct plsv_iterator*)iter->data;

  if (!I->key) {
      return HASH_KEY_NON_EXISTANT;
  }
  *str_key_len = I->keylen;
  *str_key = estrndup(I->key, I->keylen);
  return HASH_KEY_IS_STRING;
}

static void plsv_iter_move_forwards(zend_object_iterator *iter TSRMLS_DC)
{
  struct plsv_iterator *I = (struct plsv_iterator*)iter->data;
  SV *value;
  char *key;
  long keylen;
  pTHX;
  if(!I->hv) return;
  if (I->fetch_ahead) {
      ZVAL_DELREF(I->fetch_ahead);
      I->fetch_ahead = NULL;
  }
  if(I->key) {
    efree(I->key);
    I->key = NULL;
    I->keylen = 0;
  }
  if((value = hv_iternextsv(I->hv, &key, &keylen)) != NULL) {
      I->key = estrndup(key, keylen);
      I->keylen = keylen + 1;
      I->fetch_ahead = SvZval(value TSRMLS_CC);
  }
}

static void plsv_iter_rewind(zend_object_iterator *iter TSRMLS_DC)
{
  pTHX;
  struct plsv_iterator *I = (struct plsv_iterator*)iter->data;
  if(!I->hv) return;
  hv_iterinit(I->hv);
  plsv_iter_move_forwards(iter TSRMLS_CC);
}

static zend_object_iterator_funcs plsv_iter_funcs = {
    plsv_iter_dtor,
    plsv_iter_valid,
    plsv_iter_get_data,
    plsv_iter_get_key,
    plsv_iter_move_forwards,
    plsv_iter_rewind,
    NULL
};

static zend_object_iterator *plsv_iter_get(zend_class_entry *ce, zval *object TSRMLS_DC)
{
  struct plsv *pl;
  struct plsv_iterator *I;
  SV *sv;
  pTHX;

  pl = (struct plsv *) zend_object_store_get_object(object TSRMLS_CC);

  I = ecalloc(1, sizeof(*I));
  I->iter.funcs = &plsv_iter_funcs;
  I->iter.data = I;
  SvREFCNT_inc(pl->sv);
  sv = pl->sv;
  I->sv = pl->sv;
  if(SvROK(sv)) { sv = SvRV(sv); }
  if(SvTYPE(sv) == SVt_PVHV) {
    I->hv = (HV *) sv;
  } else {
    I->hv = NULL;
    I->fetch_ahead = NULL;
    I->key = NULL;
    SvREFCNT_dec(pl->sv);
    return &I->iter;
  }
  return &I->iter;
}

static function_entry pl_functions[] = {
  PHP_ME(perl, getinstance, NULL, ZEND_ACC_PUBLIC | ZEND_ACC_STATIC)
  {NULL, NULL, NULL}
};

static function_entry plobj_functions[] = {
  PHP_ME(perl, eval, NULL, ZEND_ACC_PUBLIC)
  PHP_ME(perl, getvariable, NULL, ZEND_ACC_PUBLIC) 
  PHP_ME(perl, setvariable, NULL, ZEND_ACC_PUBLIC) 
  PHP_ME(perl, call, NULL, ZEND_ACC_PUBLIC) 
  PHP_ME(perl, new, NULL, ZEND_ACC_PUBLIC) 
  PHP_ME(perl, call_method, NULL, ZEND_ACC_PUBLIC) 
  {NULL, NULL, NULL}
};

static function_entry plsv_functions[] = {
  PHP_ME(perlsv, __tostring, NULL, ZEND_ACC_PUBLIC)
  PHP_ME(perlsv, call, NULL, ZEND_ACC_PUBLIC) 
  {NULL, NULL, NULL}
};

static void 
plobj_free(void *obj TSRMLS_DC)
{
  struct plobj *pl;

  pl = (struct plobj *) obj;
  zend_hash_destroy(pl->zo.properties);
  FREE_HASHTABLE(pl->zo.properties);

  efree(obj);
}

static void
plobj_dtor(void *obj, zend_object_handle handle TSRMLS_DC)
{
}

static struct plobj *
plobj_new(zend_class_entry *ce TSRMLS_DC)
{
  struct plobj      *pl;
  zend_object_value  obj;
  dTHX;
  
  pl = ecalloc(1, sizeof(*pl));
  pl->zo.ce = ce;
  
  ALLOC_HASHTABLE(pl->zo.properties);
  zend_hash_init(pl->zo.properties, 0, NULL, ZVAL_PTR_DTOR, 0);

#ifdef USE_ITHREADS
  pl->perl = aTHX;
#endif

  return pl;
}

static void
plobj_clone(void *obj, void **cp TSRMLS_DC)
{
  struct plobj *pl;
  struct plobj *clone;

  pl = (struct plobj *) obj;
  
  clone = plobj_new(pl->zo.ce TSRMLS_CC);
  if (!clone) {
    *cp = NULL;
    return;
  }

  *cp = (void *) clone;
}

static zend_object_value 
plobj_create_object(zend_class_entry *ce TSRMLS_DC)
{
  struct plobj      *pl;
  zend_object_value  obj;
  
  pl = plobj_new(ce TSRMLS_CC);
  
  obj.handle = zend_objects_store_put(pl, plobj_dtor,
      (zend_objects_free_object_storage_t) plobj_free, plobj_clone TSRMLS_CC);
  obj.handlers = (zend_object_handlers *) &plobj_handlers;

  return obj;
}


static void 
plsv_free(void *obj TSRMLS_DC)
{
  struct plsv *pl;

  pl = (struct plsv *) obj;
  zend_hash_destroy(pl->zo.properties);
  FREE_HASHTABLE(pl->zo.properties);

  efree(obj);
}

static void
plsv_dtor(void *obj, zend_object_handle handle TSRMLS_DC)
{
  struct plsv *pl;
  dTHX;

  pl = (struct plsv *) obj;
  SvREFCNT_dec(pl->sv);
}

static struct plsv *
plsv_new(zend_class_entry *ce TSRMLS_DC)
{
  struct plsv      *pl;
  zend_object_value  obj;
  dTHX;
  
  pl = ecalloc(1, sizeof(*pl));
  pl->zo.ce = ce;
  
  ALLOC_HASHTABLE(pl->zo.properties);
  zend_hash_init(pl->zo.properties, 0, NULL, ZVAL_PTR_DTOR, 0);

#ifdef USE_ITHREADS
  pl->perl = aTHX;
#endif

  return pl;
}

static void
plsv_clone(void *obj, void **cp TSRMLS_DC)
{
  struct plsv *pl;
  struct plsv *clone;

  pl = (struct plsv *) obj;
  
  clone = plsv_new(pl->zo.ce TSRMLS_CC);
  if (!clone) {
    *cp = NULL;
    return;
  }

  *cp = (void *) clone;
}

static zend_object_value 
plsv_create_object(zend_class_entry *ce TSRMLS_DC)
{
  struct plsv      *pl;
  zend_object_value  obj;
  
  pl = plsv_new(ce TSRMLS_CC);
  
  obj.handle = zend_objects_store_put(pl, plsv_dtor,
      (zend_objects_free_object_storage_t) plsv_free, plsv_clone TSRMLS_CC);
  obj.handlers = (zend_object_handlers *) &plsv_handlers;

  return obj;
}

void plsv_wrap_sv(zval *retval, SV *sv TSRMLS_DC)
{
  dTHX;
  struct plsv *pl;

  object_init_ex(retval, plsv_ce);
  retval->refcount = 1;
  retval->is_ref = 1;

  pl = (struct plsv *) zend_object_store_get_object(retval TSRMLS_CC);
  SvREFCNT_inc(sv);
  pl->sv = sv;
}
 

PHP_MINIT_FUNCTION(sandwich)
{
  zend_class_entry pl;
  zend_class_entry plobj;
  zend_class_entry plsv;
  
  ZEND_INIT_MODULE_GLOBALS(sandwich, sw_initglobals, NULL);

  INIT_CLASS_ENTRY(pl, "Perl", pl_functions);
  pl_ce = zend_register_internal_class(&pl TSRMLS_CC);
  if (!pl_ce) {
    return FAILURE;
  }

  INIT_CLASS_ENTRY(plobj, "PerlObject", plobj_functions);
  
  plobj.create_object = plobj_create_object;
  plobj_ce = zend_register_internal_class(&plobj TSRMLS_CC);
  if (!plobj_ce) {
    return FAILURE;
  }

  memcpy(&plobj_handlers, zend_get_std_object_handlers(), 
      sizeof(plobj_handlers));

  plobj_handlers.read_dimension = sandwich_dim_read;
  plobj_handlers.write_dimension = sandwich_dim_write;
  plobj_handlers.get_method = sandwich_get_method;
  plobj_handlers.call_method = sandwich_call_method;

  INIT_CLASS_ENTRY(plsv, "PerlSV", plsv_functions);
  plsv_ce = zend_register_internal_class(&plsv TSRMLS_CC);
  plsv_ce->create_object = plsv_create_object;
  plsv_ce->get_iterator = plsv_iter_get;
  zend_class_implements(plsv_ce TSRMLS_CC, 1, zend_ce_traversable);
  if (!plsv_ce) {
    return FAILURE;
  }
  memcpy(&plsv_handlers, zend_get_std_object_handlers(), 
      sizeof(plsv_handlers));

  plsv_handlers.read_property = sv_prop_read;
  plsv_handlers.write_property = sv_prop_write;
  plsv_handlers.has_property = sv_prop_exists;
  plsv_handlers.get_method = sv_get_method;
  plsv_handlers.call_method = sv_call_method;
  plsv_handlers.get_class_name = sv_get_class_name;
  
  return SUCCESS;
}


PHP_FUNCTION(sandwich_test)
{
    RETURN_STRING("mmmm... peanut butter", 1);
}

static function_entry sandwich_functions[] = {
  PHP_FE(sandwich_test, NULL)
  {NULL, NULL, NULL}
};


zend_module_entry sandwich_module_entry = {
  STANDARD_MODULE_HEADER,
  "sandwich",
  sandwich_functions,
  PHP_MINIT(sandwich),
  NULL,
  NULL,
  NULL,
  PHP_MINFO(sandwich),
  NULL,
  STANDARD_MODULE_PROPERTIES
};

/* vim: set sw=2 ts=2 sts=2 ai bs=2 expandtab : */
