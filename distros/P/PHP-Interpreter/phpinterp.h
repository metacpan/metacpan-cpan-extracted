#ifndef _SANDWICH_PHPINTERP_H
#define _SANDWICH_PHPINTERP_H

#include <EXTERN.h>
#include <perl.h>
#include <perlapi.h>

#undef module_name
#undef API_EXPORT
#include <main/php_config.h>
#include <main/php.h>
#include <main/php_ini.h>
#include <main/php_main.h>
#include <zend.h>
#include <zend_API.h>
#include <zend_compile.h>
#include <zend_ini.h>
#include <SAPI.h>
#include <TSRM.h>

typedef struct {
  void *ctx;
  int ref;
  SV *output_handler;
} sandwich_per_interp;

int sandwich_php_interpreter_create();

sandwich_per_interp *sandwich_per_interp_setup();

void sandwhich_per_interp_shutdown(sandwich_per_interp *interp);

SV *sandwich_eval(sandwich_per_interp *interp, char *code);
int sandwich_include(sandwich_per_interp *interp, char *file, int once);

/* NOTE: caller must tsrm_set_interpreter_context and reset the old one */
zval *sandwich_call_function(sandwich_per_interp *interp, zval *method, zval **params, zend_uint param_count);

#define sandwich_interp_inc_ref(interp) interp->ref++
#define sandwich_interp_dec_ref(interp) if(--interp->ref == 0) sandwich_per_interp_shutdown(interp)

zval *SvZval(SV *sv TSRMLS_DC);
SV *newSVzval(zval *param, sandwich_per_interp *interp);

#ifdef ZTS
#define INTERP_CTX_ENTER(ctx) void *old_ctx = tsrm_set_interpreter_context(ctx)
#define INTERP_CTX_LEAVE()   tsrm_set_interpreter_context(old_ctx)
#else
#define INTERP_CTX_ENTER(ctx)
#define INTERP_CTX_LEAVE()
#endif

#endif
