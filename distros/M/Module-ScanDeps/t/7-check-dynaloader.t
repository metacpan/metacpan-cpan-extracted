#!perl

use strict;
use Test::More;
use Config ();

use Module::ScanDeps;
use DynaLoader;
use File::Temp;
use Data::Dumper;

plan skip_all => "No dynamic loading available in your version of perl"
    unless $Config::Config{usedl};

my @try_mods = qw( File::Glob Data::Dumper List::Util Time::HiRes Compress::Raw::Zlib );
my @dyna_mods = grep { my $mod = $_; 
                       eval("require $mod; 1") 
                       && grep { $_ eq $mod } @DynaLoader::dl_modules
                     } @try_mods;
plan skip_all => "No dynamic module found (tried @try_mods)"
    unless @dyna_mods;

my $extra_verbose = ($ENV{TEST_VERBOSE}||0) > 1;
diag "dynamic modules used for test: @dyna_mods";
if ($extra_verbose)
{
    diag "\@DynaLoader::dl_modules = @DynaLoader::dl_modules";
    diag "\@DynaLoader::dl_shared_objects = @DynaLoader::dl_shared_objects";
}

plan tests => 4 * 2 * @dyna_mods;

foreach my $module (@dyna_mods)
{
    # cf. DynaLoader.pm
    my @modparts = split(/::/,$module);
    my $modfname = defined &DynaLoader::mod2fname ? DynaLoader::mod2fname(\@modparts) : $modparts[-1];
    my $auto_path = join('/', 'auto', @modparts, "$modfname.$Config::Config{dlext}");

    check_bundle_path(static => $module, $auto_path,
        sub { scan_deps(
                files   => [ $_[0] ],
                recurse => 0);
        },
        ".pl", <<"...",
use $module;
1;
...
    );
    check_bundle_path(compile => $module, $auto_path,
        sub { scan_deps_runtime(
                files   => [ $_[0] ],
                recurse => 0,
                compile => 1);
        },
        ".pm", <<"...",
package Bar;
use $module;
1;
...
    );
    check_bundle_path(execute => $module, $auto_path,
        sub { scan_deps_runtime(
                files   => [ $_[0] ],
                recurse => 0,
                execute => 1);
        },
        ".pl", <<"...",
# no way in hell can this detected by static analysis :)
my \$req = join("", qw( r e q u i r e ));
eval "\$req $module";
exit(0);
...
    );
    check_bundle_path(execute_with_args => $module, $auto_path,
        sub { scan_deps_runtime(
                files   => [ $_[0] ],
                recurse => 0,
                execute => [ $module ]);
        },
        ".pl", <<"...",
# no way in hell can this detected by static analysis :)
my \$req = join("", qw( r e q u i r e ));
eval "\$req \$_" foreach \@ARGV;
exit(0);
...
    );
}

exit(0);

# NOTE: check_bundle_path runs 2 tests
sub check_bundle_path {
    my ($tag, $module, $auto_path, $scan, $suffix, $source) = @_;

    my ($fh, $filename) = File::Temp::tempfile( UNLINK => 1, SUFFIX => $suffix );
    print $fh $source, "\n" or die $!;
    close $fh;

    my $rv = $scan->($filename);
    diag("check_bundle_path:$tag for $module ...");
    diag(Dumper($rv)) if $extra_verbose;

    my ( $entry ) =  grep { /^\Q$auto_path\E$/ } keys %$rv;
    ok($entry,
       "check_bundle_path:$tag for $module: ".
       "found some key that looks like it pulled in its shared lib (auto_path=$auto_path)");

    # Actually we accept anything that ends with $auto_path.
    ok($rv->{$entry}{file} =~ m{/\Q$auto_path\E$}, 
       "check_bundle_path:$tag for $module: ".
       "the full bundle path we got \"$rv->{$entry}{file}\" looks legit");
}


