use strict;
use warnings;
use Test::More;
use Path::Class;
use List::MoreUtils qw(any);
use IPC::Cmd qw(run);
use Config;

BEGIN {
    my $var = dir('t/var');
    $var->rmtree;
    $var->mkpath;
    chdir $var or die "Unable to chdir into $var: $!";
    file('MANIFEST')->spew('');
    dir('lib/PDL/Test')->mkpath;
    file('lib/PDL/Test/PD.pd')->spew(<<'PDFILE');
pp_setversion($VERSION);
pp_addpm({At=>'Top'},<<'EOD');
use strict;
use warnings;

=head1 NAME

PDL::Test::PD - Test PD File
# ABSTRACT: Test PD File

=head1 SYNOPSIS

 use PDL::Test::PD;
 ...

=head1 DESCRIPTION

...

=cut

EOD
pp_done();  # you will need this to finish pp processing
PDFILE
}

use Module::Build::Pluggable ('PDL');

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
);
$builder->create_build_script();
is( @{ $builder->include_dirs }, 1, "added include dirs" );
ok( -f 'Build', 'Build file created' );

my $buffer;
run_ok( 'Build', 'Ran Build' );
ok( -f 'lib/PDL/Test/PD.pm', '... Build created .pm file' );
ok( -f 'lib/PDL/Test/PD.xs', '... and .xs file' );

run_ok( 'Build distmeta', "Ran Build distmeta" );
ok( -f 'META.json', '... created META.json file' );

run_ok( 'Build distdir', "Ran Build distdir" );
ok( -f 'lib/PDL/Test/PD.pod', '... and .pod file' );

run_ok( 'Build clean', "Ran Build clean" );
ok( !-f 'lib/PDL/Test/PD.pm',  '... removed .pm file' );
ok( !-f 'lib/PDL/Test/PD.xs',  '... and .xs file' );
ok( !-f 'lib/PDL/Test/PD.pod', '... and .pod file' );

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
