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

/* a true global in non-threaded servers */
#ifndef ZTS
static sandwich_per_interp *one_true_interp = NULL;
#endif

struct interp_list {
  void *interp;
  struct interp_list *next;
};

static struct interp_list *free_interps = NULL;

static pthread_key_t sandwich_per_thread_info_key;

/* {{{ sandwich SAPI Details */

static int sandwich_sapi_ub_write(const char *str, uint str_length TSRMLS_DC)
{
  // FIXME - call out to Perl's selected fh
  SV *oh;
  sandwich_per_interp *interp = SG(server_context);
  if(!interp || !interp->output_handler || interp->output_handler == &PL_sv_undef) {
    fwrite(str, 1, str_length, stdout);
    return str_length;
  }
  oh = interp->output_handler;
  if (SvROK(oh) && (SvTYPE(SvRV(oh)) == SVt_PVCV)) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvn(str, str_length)));
    PUTBACK;
    call_sv(oh, G_VOID | G_EVAL);
    FREETMPS;
    LEAVE;
  } else {
    if(SvROK(oh) && !SvPOK(SvRV(oh))) {
      sv_setpvn_mg(SvRV(oh), str, str_length);
    } else {
      sv_catpvn_mg(SvROK(oh)?SvRV(oh):oh, str, str_length);
    }
  }
  return str_length;
}

static void sandwich_sapi_reg_server_vars(zval *track_vars_array TSRMLS_DC)
{
  // FIXME - register $php here?
}

static char *sandwich_sapi_read_cookies(TSRMLS_D)
{
  return NULL;
}

static int sandwich_sapi_header_handler(sapi_header_struct *sapi_header,
  sapi_headers_struct *sapi_headers TSRMLS_DC)
{
  // FIXME - call out to perl
  return SAPI_HEADER_ADD;
}

static int sandwich_sapi_send_headers(sapi_headers_struct *sapi_headers TSRMLS_DC)
{
  // FIXME set headers back through perl
  return SAPI_HEADER_SENT_SUCCESSFULLY;
}

static void sandwich_sapi_log_message(char *message)
{
  // allow this to be overridden nicely?
  croak("%s\n", message);
}



static sapi_module_struct sandwich_sapi = {
  "sandwich",
  "Ham and Cheese",
  NULL, /* startup */
  zend_shutdown, /* shutdown */
  NULL, /* activate */
  NULL, /* deactivate */
  sandwich_sapi_ub_write,
  NULL, /* flush */
  NULL, /* get uid */
  NULL, /* getenv */
  zend_error,
  sandwich_sapi_header_handler,
  sandwich_sapi_send_headers,
  NULL, /* send header */
  NULL, /* read POST */
  sandwich_sapi_read_cookies,
  sandwich_sapi_reg_server_vars,
  sandwich_sapi_log_message,
  STANDARD_SAPI_MODULE_PROPERTIES
};

extern zend_module_entry sandwich_module_entry;

static int ze_started = 0;

int sandwich_php_interpreter_create()
{
  zend_compiler_globals *compiler_globals;
  zend_executor_globals *executor_globals;
  php_core_globals *core_globals;
  sapi_globals_struct *sapi_globals;
  void ***tsrm_ls;

  if(ze_started) {
    return 0;
  }
#ifdef ZTS
  pthread_key_create(&sandwich_per_thread_info_key, NULL);

  if (!tsrm_startup(128, 32, TSRM_ERROR_LEVEL_CORE, "/tmp/TSRM.log")) {
    croak("Failed to init PHP TSRM!\n");
    return -1;
  }
  
  compiler_globals = ts_resource(compiler_globals_id);
  executor_globals = ts_resource(executor_globals_id);
  core_globals = ts_resource(core_globals_id);
  sapi_globals = ts_resource(sapi_globals_id);
  tsrm_ls = ts_resource(0);
#endif

  sapi_startup(&sandwich_sapi);
  ze_started = 1;
  if (FAILURE == php_module_startup(&sandwich_sapi, &sandwich_module_entry, 1)) {
    fprintf(stderr, "Failed to initialize PHP\n");
    return -1;
  }
  
  return 0;
}

sandwich_per_interp *sandwich_per_interp_setup() 
{
  sandwich_per_interp *info;
#ifdef ZTS
  if(free_interps) {
    struct interp_list *tofree = free_interps;
    info = free_interps->interp;
    free_interps = free_interps->next;
    free(tofree);
    /* return interpreter to working state */
    INTERP_CTX_ENTER(info->ctx);
    {
      TSRMLS_FETCH();
      php_request_startup(TSRMLS_C);
      info->ref = 1;
      PG(during_request_startup) = 0;
      SandwichG(php) = info;
      INTERP_CTX_LEAVE();
    }
    return info;
  }
#else
  if(one_true_interp) return one_true_interp;
#endif

  info = calloc(sizeof(*info), 1);
  info->ref = 1;

#ifdef ZTS
  info->ctx = tsrm_new_interpreter_context();
#else
  one_true_interp = info;
#endif

  info->ref = 1;
  INTERP_CTX_ENTER(info->ctx);
  {
    TSRMLS_FETCH();
    
    zend_alter_ini_entry("register_argc_argv", 19, "0", 1, PHP_INI_SYSTEM, PHP_INI_STAGE_ACTIVATE);
    zend_alter_ini_entry("html_errors", 12, "0", 1, PHP_INI_SYSTEM, PHP_INI_STAGE_ACTIVATE);
    zend_alter_ini_entry("implicit_flush", 15, "1", 1, PHP_INI_SYSTEM, PHP_INI_STAGE_ACTIVATE);
    zend_alter_ini_entry("max_execution_time", 19, "0", 1, PHP_INI_SYSTEM, PHP_INI_STAGE_ACTIVATE);

    SG(headers_sent) = 1;
    SG(request_info).no_headers = 1;
    SG(server_context) = info;
    SG(options) = SAPI_OPTION_NO_CHDIR;
    php_request_startup(TSRMLS_C);
    PG(during_request_startup) = 0;
    SandwichG(php) = info;
    INTERP_CTX_LEAVE();
  }

  return info;
}


void sandwich_per_interp_shutdown(sandwich_per_interp *interp)
{
#ifndef ZTS
  if(one_true_interp == NULL) return;
  else one_true_interp = NULL;
#endif

  INTERP_CTX_ENTER(interp->ctx);
  {
    struct interp_list *node;
    TSRMLS_FETCH();
    php_request_shutdown(NULL);
#ifdef ZTS
    tsrm_set_interpreter_context(NULL);
    node = malloc(sizeof(*node));
    node->interp = interp;
    node->next = free_interps;
    free_interps = node;
#endif
  }
  INTERP_CTX_LEAVE();
}

int my_eval_string(char *str, zval *retval_ptr, char *string_name TSRMLS_DC)
{
  zval pv;
  zend_op_array *new_op_array;
  zend_op_array *original_active_op_array = EG(active_op_array);
  zend_function_state *original_function_state_ptr = EG(function_state_ptr);
  zend_uchar original_handle_op_arrays;
  int retval;

  if (retval_ptr) {
    pv.value.str.len = strlen(str) + sizeof(" return true;") -1;
    pv.value.str.val = emalloc(pv.value.str.len + 1);
    strcpy(pv.value.str.val, str);
    strcat(pv.value.str.val, " return true;");
  }
  pv.type = IS_STRING;

  original_handle_op_arrays = CG(handle_op_arrays);
  CG(handle_op_arrays) = 0;
  new_op_array = compile_string(&pv, string_name TSRMLS_CC);
  CG(handle_op_arrays) = original_handle_op_arrays;

  if (new_op_array) {
    zval *local_retval_ptr=NULL;
    zval **original_return_value_ptr_ptr = EG(return_value_ptr_ptr);
    zend_op **original_opline_ptr = EG(opline_ptr);

    EG(return_value_ptr_ptr) = &local_retval_ptr;
    EG(active_op_array) = new_op_array;
    EG(no_extensions)=1;
    zend_execute(new_op_array TSRMLS_CC);

    if (local_retval_ptr) {
      if (retval_ptr) {
        COPY_PZVAL_TO_ZVAL(*retval_ptr, local_retval_ptr);
      } else {
        zval_ptr_dtor(&local_retval_ptr);
      }
    } else {
      if (retval_ptr) {
        INIT_ZVAL(*retval_ptr);
      }
    }

    EG(no_extensions)=0;
    EG(opline_ptr) = original_opline_ptr;
    EG(active_op_array) = original_active_op_array;
    EG(function_state_ptr) = original_function_state_ptr;
    destroy_op_array(new_op_array TSRMLS_CC);
    efree(new_op_array);
    EG(return_value_ptr_ptr) = original_return_value_ptr_ptr;
         retval = SUCCESS;
  } else {
    retval = FAILURE;
  }
  zval_dtor(&pv);
  return retval;
}

SV *sandwich_eval(sandwich_per_interp *interp, char *code)
{
  int rv = 0;
  zval retval;
  INTERP_CTX_ENTER(interp->ctx);
  {
    TSRMLS_FETCH();
    zend_try {
      if (FAILURE == my_eval_string(code, &retval, "PHP::Interpreter::eval" TSRMLS_CC)) {
        rv = -1;
        goto cleanup;
      }
    } zend_catch {
      rv = -1;
      goto cleanup;
    } zend_end_try() {
    }
  }
cleanup:
  INTERP_CTX_LEAVE();
  if(rv == -1) {
    croak("PHP Error in eval");
  } else {
    SV *rv;
    /* FIXME, do i need to copy retval? */
    rv = newSVzval(&retval, interp);
    return rv;
  }
}

int sandwich_include(sandwich_per_interp *interp, char *file, int once)
{
  int rv = 0;
  INTERP_CTX_ENTER(interp->ctx);
  {
    zend_file_handle file_handle;
    TSRMLS_FETCH();
    zend_try {
        int dummy = 1;
        SG(request_info).path_translated = file;
        file_handle.type = ZEND_HANDLE_FILENAME;
        file_handle.handle.fd = 0;
        file_handle.filename = SG(request_info).path_translated;
        file_handle.opened_path = NULL;
        file_handle.free_filename = 0;
        if(zend_hash_add(&EG(included_files), file, strlen(file)+1, (void *)&dummy, sizeof(int), NULL) != SUCCESS&& once) {
          /* implicit success! */
          rv = 0;
          goto cleanup;
        }
        rv = (php_execute_script(&file_handle TSRMLS_CC) == 1)?0:-1;
    } zend_catch {
      rv = -1;
      goto cleanup;
    } zend_end_try() {
    }
  }
cleanup:
  INTERP_CTX_LEAVE();
  return rv;
}

zval *sandwich_call_function(sandwich_per_interp *interp, zval *method, zval **params, zend_uint param_count)
{
  TSRMLS_FETCH();
  zend_try {
    zval *retval;
    MAKE_STD_ZVAL(retval);
    if(call_user_function(EG(function_table), NULL, method, retval, param_count, params TSRMLS_CC) == FAILURE) {
      return NULL;
    }
    return retval;
  } zend_catch {
    return NULL;
  } zend_end_try() {
    return NULL;
  }
}

/* vim: set ts=2 sts=2 ai bs=2 expandtab : */
