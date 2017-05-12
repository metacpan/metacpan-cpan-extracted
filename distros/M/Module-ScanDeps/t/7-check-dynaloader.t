#!perl

use strict;
use Test::More;
use Config ();

use Module::ScanDeps;
use DynaLoader;
use File::Temp;

plan skip_all => "No dynamic loading available in your version of perl"
    unless $Config::Config{usedl};

my @try_mods = qw( Cwd File::Glob Data::Dumper List::Util Time::HiRes Compress::Raw::Zlib );
my @dyna_mods = grep { my $mod = $_; 
                       eval("require $mod; 1") 
                       && grep { $_ eq $mod } @DynaLoader::dl_modules
                     } @try_mods;
plan skip_all => "No dynamic module found (tried @try_mods)"
    unless @dyna_mods;
diag "dynamic modules used for test: @dyna_mods";

plan tests => 4 * 2 * @dyna_mods;

foreach my $module (@dyna_mods)
{
    # cf. DynaLoader.pm
    my @modparts = split(/::/,$module);
    my $modfname = defined &DynaLoader::mod2fname ? DynaLoader::mod2fname(\@modparts) : $modparts[-1];
    my $auto_path = join('/', 'auto', @modparts, "$modfname.$Config::Config{dlext}");

    check_bundle_path($module, $auto_path, ".pl", <<"...",
use $module;
1;
...
        sub { scan_deps(
                files   => [ $_[0] ],
                recurse => 0);
        }
    );
    check_bundle_path($module, $auto_path, ".pm", <<"...",
package Bar;
use $module;
1;
...
        sub { scan_deps_runtime(
                files   => [ $_[0] ],
                recurse => 0,
                compile => 1);
        }
    );
    check_bundle_path($module, $auto_path, ".pl", <<"...",
# no way in hell can this detected by static analysis :)
my \$req = join("", qw( r e q u i r e ));
eval "\$req $module";
exit(0);
...
        sub { scan_deps_runtime(
                files   => [ $_[0] ],
                recurse => 0,
                execute => 1);
        }
    );
    check_bundle_path($module, $auto_path, ".pl", <<"...",
# no way in hell can this detected by static analysis :)
my \$req = join("", qw( r e q u i r e ));
eval "\$req \$_" foreach \@ARGV;
exit(0);
...
        sub { scan_deps_runtime(
                files   => [ $_[0] ],
                recurse => 0,
                execute => [ $module ]);
        }
    );
}

exit(0);

# NOTE: check_bundle_path runs 2 tests
sub check_bundle_path {
    my ($module, $auto_path, $suffix, $code, $scan) = @_;

    my ($fh, $filename) = File::Temp::tempfile( UNLINK => 1, SUFFIX => $suffix );
    print $fh $code, "\n" or die $!;
    close $fh;

    my $rv = $scan->($filename);
    my ( $entry ) =  grep { /^\Q$auto_path\E$/ } keys %$rv;
    ok( $entry, "$module: found some key that looks like it pulled in its shared lib (auto_path=$auto_path)" );

    # Actually we accept anything that ends with $auto_path.
    ok($rv->{$entry}->{file} =~ m{/\Q$auto_path\E$}, 
       "$module: the full bundle path we got ($rv->{$entry}->{file}) looks legit" );
}


