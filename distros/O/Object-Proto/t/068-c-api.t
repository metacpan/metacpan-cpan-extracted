use strict;
use warnings;
use Test::More;
use Config;
use File::Spec;
use File::Temp ();
use File::Path ();
use Object::Proto;

BEGIN {
    eval { require ExtUtils::CBuilder; require ExtUtils::ParseXS; require ExtUtils::Depends; 1 }
        or plan skip_all => 'ExtUtils::CBuilder, ExtUtils::ParseXS and ExtUtils::Depends build the test module';
    ExtUtils::CBuilder->new(quiet => 1)->have_compiler
        or plan skip_all => 'a C compiler builds the test module';
}

my $tmp = File::Temp->newdir;
my $xs  = File::Spec->catfile($tmp, 'CApi.xs');
my $c   = File::Spec->catfile($tmp, 'CApi.c');
open my $fh, '>', $xs or die "$xs: $!";
print $fh <<'XS';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "object_types.h"

static bool even_check(pTHX_ SV *val) { return SvIOK(val) && (SvIV(val) % 2) == 0; }
static SV *twice_coerce(pTHX_ SV *val) { return sv_2mortal(newSViv(SvIV(val) * 2)); }
static bool mod_check(pTHX_ SV *val, void *data) { return SvIOK(val) && (SvIV(val) % PTR2IV(data)) == 0; }
static SV *mod_coerce(pTHX_ SV *val, void *data) { return sv_2mortal(newSViv(SvIV(val) * PTR2IV(data))); }

MODULE = OPT::CApi    PACKAGE = OPT::CApi

BOOT:
    object_register_type_xs(aTHX_ "Even", even_check, NULL);
    object_register_type_xs(aTHX_ "Twice", NULL, twice_coerce);
    object_register_type_xs(aTHX_ "Bare", NULL, NULL);
    object_register_type_xs_ex(aTHX_ "Triples", mod_check, mod_coerce, INT2PTR(void *, 3));
    object_register_type_xs_ex(aTHX_ "Sevens", mod_check, NULL, INT2PTR(void *, 7));

int
registered(name)
    const char *name
  CODE:
    RETVAL = object_get_registered_type(aTHX_ name) != NULL;
  OUTPUT:
    RETVAL

void
register_plain(name)
    const char *name
  CODE:
    object_register_type_xs(aTHX_ name, NULL, NULL);

void
register_ex(name)
    const char *name
  CODE:
    object_register_type_xs_ex(aTHX_ name, NULL, NULL, NULL);
XS
close $fh;

ExtUtils::ParseXS::process_file(filename => $xs, output => $c, prototypes => 0);
my $builder = ExtUtils::CBuilder->new(quiet => 1);
my %vars = ExtUtils::Depends->new('OPT::CApi', 'Object::Proto')->get_makefile_vars;
my @inc = map { /^-I(.+)/ ? $1 : () } split ' ', $vars{INC};
my @link = proto_library();
diag("linking against @link") if @link;
my $obj = $builder->compile(source => $c, include_dirs => [@inc, File::Spec->rel2abs('include'), "$tmp"]);
my $dir = File::Spec->catdir($tmp, 'auto', 'OPT', 'CApi');
File::Path::make_path($dir);
my $lib = $builder->link(objects => [$obj, @link], module_name => 'OPT::CApi', lib_file => File::Spec->catfile($dir, "CApi.$Config{dlext}"));
ok(-f $lib, 'the test module built');

{
    package OPT::CApi;
    our @ISA = ('DynaLoader');
    require DynaLoader;
    unshift @INC, "$tmp";
    DynaLoader::bootstrap('OPT::CApi');
}
ok(OPT::CApi::registered('Even'), 'a type registered from C is found by name');
ok(!OPT::CApi::registered('Odd'), 'and an unknown name is not');
ok(Object::Proto::has_type('Triples'), 'has_type sees a C registered type');
eval { OPT::CApi::register_plain('Even') };
like($@, qr/Type 'Even' is already registered/, 'a name cannot be registered twice from C');
eval { OPT::CApi::register_ex('Triples') };
like($@, qr/Type 'Triples' is already registered/, 'nor with user data');
eval { Object::Proto::register_type('Even', sub { 1 }) };
like($@, qr/Type 'Even' is already registered/, 'nor from Perl');

Object::Proto::define('OPT::User', 'e:Even', 'w:Twice', 'b:Bare', 't:Triples', 's:Sevens', 'ew:Even:writer(set_e)');
my $u = OPT::User->new(e => 2, w => 5, b => 'anything', t => 1, s => 14);
is($u->e, 2, 'a C check function passes a good value');
is($u->w, 10, 'a C coerce function runs at construction');
is($u->b, 'anything', 'a type with neither check nor coerce takes anything');
is($u->t, 3, 'a C coerce function with user data runs at construction');
is($u->s, 14, 'a C check function with user data passes a good value');
eval { OPT::User->new(e => 3) };
like($@, qr/Type constraint failed for 'e' in new\(\): expected Even/, 'a C check function rejects at construction');
eval { OPT::User->new(s => 15) };
like($@, qr/Type constraint failed for 's' in new\(\): expected Sevens/, 'with user data too');
is($u->w(4), 8, 'a C coerce function runs on the setter');
is($u->t(2), 6, 'with user data too');
eval { $u->e(5) };
like($@, qr/Type constraint failed for 'e': expected Even/, 'a C check function rejects on the setter');
eval { $u->set_e(7) };
like($@, qr/Type constraint failed for 'ew': expected Even/, 'and on a writer');
is($u->set_e(8), 8, 'which passes a good value');
my $p = OPT::User->new(2, 5, 'x', 1, 7);
is($p->w, 10, 'positional construction coerces through C');
eval { OPT::User->new(3) };
like($@, qr/Type constraint failed for 'e' in new\(\): expected Even/, 'and checks through C');


sub proto_library {
    my %exts = (MSWin32 => [$Config{_a}, '.lib', ".$Config{dlext}"], cygwin => ['.dll'], android => [".$Config{dlext}"]);
    my $exts = $exts{$^O} or return;
    my @parts = ('auto', 'Object', 'Proto');
    my $stem = defined &DynaLoader::mod2fname ? DynaLoader::mod2fname(\@parts) : 'Proto';
    for my $dir (grep { -d $_ } @INC) {
        for my $ext (@$exts) {
            my $file = File::Spec->catfile($dir, @parts, "$stem$ext");
            return $file if -f $file;
        }
    }
    return;
}

done_testing;
