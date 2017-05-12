#include "modules/perl/mod_perl.h"

static mod_perl_perl_dir_config *newPerlConfig(pool *p)
{
    mod_perl_perl_dir_config *cld =
	(mod_perl_perl_dir_config *)
	    palloc(p, sizeof (mod_perl_perl_dir_config));
    cld->obj = Nullsv;
    cld->pclass = "Apache::OpenIndex";
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

static mod_perl_cmd_info cmd_info_IndexIgnore = { 
"Apache::OpenIndex::push_config", "ignore", 
};
static mod_perl_cmd_info cmd_info_DirectoryIndex = { 
"Apache::OpenIndex::DirectoryIndex", "", 
};
static mod_perl_cmd_info cmd_info_HeaderName = { 
"Apache::OpenIndex::push_config", "header", 
};
static mod_perl_cmd_info cmd_info_ReadmeName = { 
"Apache::OpenIndex::push_config", "readme", 
};
static mod_perl_cmd_info cmd_info_FancyIndexing = { 
"Apache::OpenIndex::FancyIndexing", "", 
};
static mod_perl_cmd_info cmd_info_IndexOrderDefault = { 
"Apache::OpenIndex::IndexOrderDefault", "", 
};
static mod_perl_cmd_info cmd_info_AddDescription = { 
"Apache::OpenIndex::AddDescription", "", 
};
static mod_perl_cmd_info cmd_info_IndexOptions = { 
"Apache::OpenIndex::IndexOptions", "", 
};
static mod_perl_cmd_info cmd_info_OpenIndexOptions = { 
"Apache::OpenIndex::OpenIndexOptions", "", 
};


static command_rec mod_cmds[] = {
    
    { "IndexIgnore", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_IndexIgnore,
      OR_INDEXES, ITERATE, "a list of file names" },

    { "DirectoryIndex", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_DirectoryIndex,
      OR_INDEXES, ITERATE, "one or more file extensions" },

    { "HeaderName", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_HeaderName,
      OR_INDEXES, ITERATE, "a list of file names" },

    { "ReadmeName", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_ReadmeName,
      OR_INDEXES, ITERATE, "a list of file names" },

    { "FancyIndexing", perl_cmd_perl_FLAG,
      (void*)&cmd_info_FancyIndexing,
      OR_INDEXES, FLAG, "Limited to on or off (superseded by IndexOptions FancyIndexing)" },

    { "IndexOrderDefault", perl_cmd_perl_TAKE2,
      (void*)&cmd_info_IndexOrderDefault,
      OR_INDEXES, TAKE2, "{Ascending,Descending} {Name,Size,Description,Date}" },

    { "AddDescription", perl_cmd_perl_RAW_ARGS,
      (void*)&cmd_info_AddDescription,
      OR_INDEXES, RAW_ARGS, "Descriptive text followed by one or more filenames" },

    { "IndexOptions", perl_cmd_perl_RAW_ARGS,
      (void*)&cmd_info_IndexOptions,
      OR_INDEXES, RAW_ARGS, "one or more index options" },

    { "OpenIndexOptions", perl_cmd_perl_RAW_ARGS,
      (void*)&cmd_info_OpenIndexOptions,
      OR_INDEXES, RAW_ARGS, "one or more OpenIndex options" },

    { NULL }
};

module MODULE_VAR_EXPORT XS_Apache__OpenIndex = {
    STANDARD_MODULE_STUFF,
    NULL,               /* module initializer */
    create_dir_config_sv,  /* per-directory config creator */
    perl_perl_merge_dir_config,   /* dir config merger */
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

#define this_module "Apache/OpenIndex.pm"

static void remove_module_cleanup(void *data)
{
    if (find_linked_module("Apache::OpenIndex")) {
        /* need to remove the module so module index is reset */
        remove_module(&XS_Apache__OpenIndex);
    }
    if (data) {
        /* make sure BOOT section is re-run on restarts */
        (void)hv_delete(GvHV(incgv), this_module,
                        strlen(this_module), G_DISCARD);
         if (dowarn) {
             /* avoid subroutine redefined warnings */
             perl_clear_symtab(gv_stashpv("Apache::OpenIndex", FALSE));
         }
    }
}

MODULE = Apache::OpenIndex		PACKAGE = Apache::OpenIndex

PROTOTYPES: DISABLE

BOOT:
    XS_Apache__OpenIndex.name = "Apache::OpenIndex";
    add_module(&XS_Apache__OpenIndex);
    stash_mod_pointer("Apache::OpenIndex", &XS_Apache__OpenIndex);
    register_cleanup(perl_get_startup_pool(), (void *)1,
                     remove_module_cleanup, null_cleanup);

void
END()

    CODE:
    remove_module_cleanup(NULL);
