#ifndef _SANDWICH_PHPFUNCS_H
#define _SANDWICH_PHPFUNCS_H

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

#include "phpinterp.h"

struct plobj {
    zend_object zo;
    PerlInterpreter *perl;
};

struct plsv {
    zend_object zo;
    SV *sv;
    PerlInterpreter *perl;
};

struct perlistats {
  uint16_t ps_callcnt;
  uint16_t ps_varcnt;
};

extern ZEND_API zend_class_entry *pl_ce;
extern ZEND_API zend_class_entry *plobj_ce;
extern ZEND_API zend_class_entry *plsv_ce;

void plsv_wrap_sv(zval *retval, SV *sv TSRMLS_DC);


ZEND_BEGIN_MODULE_GLOBALS(sandwich)
    struct perlistats ps_stats;
    sandwich_per_interp *php;
ZEND_END_MODULE_GLOBALS(sandwich)

ZEND_EXTERN_MODULE_GLOBALS(sandwich);

#ifdef ZTS
#define SandwichG(v) TSRMG(sandwich_globals_id, zend_sandwich_globals *, v)
#else
#define SandwichG(v) (sandwich_globals.v)
#endif

#endif
