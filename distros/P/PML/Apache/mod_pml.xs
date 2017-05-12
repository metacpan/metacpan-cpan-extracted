#include "modules/perl/mod_perl.h"

static mod_perl_perl_dir_config *newPerlConfig(pool *p)
{
    mod_perl_perl_dir_config *cld =
	(mod_perl_perl_dir_config *)
	    palloc(p, sizeof (mod_perl_perl_dir_config));
    cld->obj = Nullsv;
    cld->pclass = "Apache::mod_pml";
    register_cleanup(p, cld, perl_perl_cmd_cleanup, null_cleanup);
    return cld;
}

static void *create_dir_config_sv (pool *p, char *dirname)
{
    return newPerlConfig(p);
}

static void *create_srv_config_sv (pool *p, server_rec *s)
{
    return newPerlConfig(p);
}

static void stash_mod_pointer (char *class, void *ptr)
{
    SV *sv = newSV(0);
    sv_setref_pv(sv, NULL, (void*)ptr);
    hv_store(perl_get_hv("Apache::XS_ModuleConfig",TRUE), 
	     class, strlen(class), sv, FALSE);
}

static mod_perl_cmd_info cmd_info_PMLStore = { 
"Apache::mod_pml::apache_config_callback_pmlstore", "", 
};


static command_rec mod_cmds[] = {
    
    { "PMLStore", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_PMLStore,
      OR_OPTIONS, TAKE1, "turn storing on or off" },

    { NULL }
};

module MODULE_VAR_EXPORT XS_Apache__mod_pml = {
    STANDARD_MODULE_STUFF,
    NULL,               /* module initializer */
    create_dir_config_sv,  /* per-directory config creator */
    NULL,   /* dir config merger */
    create_srv_config_sv,       /* server config creator */
    NULL,        /* server config merger */
    mod_cmds,               /* command table */
    NULL,           /* [7] list of handlers */
    NULL,  /* [2] filename-to-URI translation */
    NULL,      /* [5] check/validate user_id */
    NULL,       /* [6] check user_id is valid *here* */
    NULL,     /* [4] check access by host address */
    NULL,       /* [7] MIME type checker/setter */
    NULL,        /* [8] fixups */
    NULL,             /* [10] logger */
    NULL,      /* [3] header parser */
    NULL,         /* process initializer */
    NULL,         /* process exit/cleanup */
    NULL,   /* [1] post read_request handling */
};

MODULE = Apache::mod_pml		PACKAGE = Apache::mod_pml

PROTOTYPES: DISABLE

BOOT:
    XS_Apache__mod_pml.name = "Apache::mod_pml";
    add_module(&XS_Apache__mod_pml);
    stash_mod_pointer("Apache::mod_pml", &XS_Apache__mod_pml);

