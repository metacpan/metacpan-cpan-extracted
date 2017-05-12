use strict;
use warnings;
use Test::More;
use Path::Class;
use List::MoreUtils qw(any);
use IPC::Cmd qw(run);
use Config;

BEGIN {

    sub skip_if_no_fortran_compiler {
        eval "use ExtUtils::F77";
        if ($@) {
            plan( skip_all => 'Tests require ExtUtils::F77 be installed.' );
            exit;
        }
        unless ( ExtUtils::F77->runtimeok ) {
            plan( skip_all => 'Tests require fortran runtime work.' );
            exit;
        }
        unless ( ExtUtils::F77->testcompiler ) {
            plan( skip_all => 'Tests require fortran compiler work.' );
            exit;
        }
    }

    ## Create an empty t/var dir
    my $var = dir('t/var');
    $var->rmtree;
    $var->mkpath;

    ## Cd into it
    chdir $var or die "Unable to cd into $var: $!";

    ## Create a MANIFEST file and test .f file in src/
    file('MANIFEST')->spew('');
    dir('src')->mkpath;
    file('src/test.f')->spew(<<'F_FILE');
	print *, 'Hello World'
	end
F_FILE

    skip_if_no_fortran_compiler();
}

use Module::Build::Pluggable ('Fortran');
my $builder = Module::Build::Pluggable->new(
    dist_name      => 'Eg',
    dist_version   => 0.01,
    dist_abstract  => 'test',
    dynamic_config => 0,
    module_name    => 'Eg',
    requires       => {},
    provides       => {},
    author         => 1,
    dist_author    => 'test',
    f_source       => ['src'],
);
$builder->create_build_script();
is( @{ $builder->f_source },     1,     "added fortran source dir" );
is( pop @{ $builder->f_source }, 'src', "... which is src" );
ok( -f 'Build', 'Build file created' );

run_ok( 'Build', 'Ran Build' );
ok( -f 'src/test.o', '.. fortran file compiled' );

run_ok( 'Build clean', 'Ran Build clean' );
ok( !-f 'src/test.o', '.. object file cleaned up' );

done_testing;

sub run_ok {
    my ( $cmd, $desc ) = @_;

    # Execute with the current perl, this avoids having to deal with relative
    # path issues on a different OS
    $cmd = sprintf "%s %s", $Config{perlpath}, $cmd;

    my $buffer;
    my $ok =
      ok( run( command => $cmd, verbose => 0, buffer => \$buffer ), $desc );
    diag $buffer unless $ok;
    return $ok;
}
