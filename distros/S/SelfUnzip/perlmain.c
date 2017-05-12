/*
 * "The Road goes ever on and on, down from the door where it began."
 */

#ifdef OEMVS
#pragma runopts(HEAP(1M,32K,ANYWHERE,KEEP,8K,4K))
#endif

/* Suppose that foo.zip contains the needed modules.  Do
      cat perl foo.zip > ! perlx
      chmod a+x perlx
      zip -A perlx
   Then if unzip is present, perlx may be used like this:
      perlx -e 'require Foo'
   but
      perlx -MFoo -e0
   does not work yet.
 */

const char module_text[] =
 "sub ___::extract_file {\n"
 "  (undef, my $file) = (shift, shift);\n"
 "  warn \"extracting '$file'...\\n\";\n"
 "  open my $file, \"-|\", \"unzip -p $^X $file\";\n"
 "  $file;\n"
 "}\n"
 "push @INC, \\&___::extract_file;\n";


#include "EXTERN.h"
#define PERL_IN_MINIPERLMAIN_C
#include "perl.h"

static void xs_init (pTHX);
static PerlInterpreter *my_perl;

#if defined (__MINT__) || defined (atarist)
/* The Atari operating system doesn't have a dynamic stack.  The
   stack size is determined from this value.  */
long _stksize = 64 * 1024;
#endif

int
main(int argc, char **argv, char **env)
{
    int exitstatus;

#ifdef PERL_GLOBAL_STRUCT
#define PERLVAR(var,type) /**/
#define PERLVARA(var,type) /**/
#define PERLVARI(var,type,init) PL_Vars.var = init;
#define PERLVARIC(var,type,init) PL_Vars.var = init;
#include "perlvars.h"
#undef PERLVAR
#undef PERLVARA
#undef PERLVARI
#undef PERLVARIC
#endif

    PERL_SYS_INIT3(&argc,&argv,&env);

    if (!PL_do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    exit(1);
	perl_construct(my_perl);
	PL_perl_destruct_level = 0;
    }

    exitstatus = perl_parse(my_perl, xs_init, argc, argv, (char **)NULL);
    if (!exitstatus) {
	perl_eval_pv(module_text, TRUE);
	exitstatus = perl_run(my_perl);
    }

    perl_destruct(my_perl);
    perl_free(my_perl);

    PERL_SYS_TERM();

    exit(exitstatus);
    return exitstatus;
}

/* Register any extra external extensions */

EXTERN_C void boot_SelfUnzip (CV* cv);
EXTERN_C void boot_DynaLoader (CV* cv);

static void
xs_init(pTHX)
{
	char *file = __FILE__;
	dXSUB_SYS;
	{
	newXS("SelfUnzip::bootstrap", boot_SelfUnzip, file);
	}
	{
	/* DynaLoader is a special case */

	newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
	}
}
