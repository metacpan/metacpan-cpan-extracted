use strict;
use warnings;
use utf8;
use Test::More;
use Test::Module::Build::Pluggable;

use File::Spec;
use lib File::Spec->rel2abs('lib');

my $test = Test::Module::Build::Pluggable->new();
$test->write_file('lib/Eg.pm', <<'...');
package Eg;
__END__

=head1 SYNOPSIS

    This is a document
...
$test->write_file('Build.PL', <<'...');
use strict;
use Module::Build::Pluggable (
    'ReadmeMarkdownFromPod'
);

my $builder = Module::Build::Pluggable->new(
    dist_name => 'Eg',
    dist_version => 0.01,
    dist_abstract => 'test',
    dynamic_config => 0,
    module_name => 'Eg',
    requires => {},
    provides => {},
    author => 1,
    dist_author => 'test',
);
$builder->create_build_script();
...
$test->write_manifest();

note "** run_build_pl\n";
$test->run_build_pl();
$test->run_build_script();
note "** run_build_script disttest\n";
$test->run_build_script('disttest');

ok(-f 'README.mkdn');
like($test->read_file('README.mkdn'), qr/This is a document/);

undef $test;

done_testing;

