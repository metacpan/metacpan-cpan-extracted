use strict;
use warnings;
use Test::More tests => 12;
use_ok('POE::Component::SmokeBox::Backend::CPAN::Reporter::Smoker');

my %data = (
        check => [ '-e', 'use CPAN::Reporter::Smoker 0.17;' ],
        index => [ '-MCPAN', '-MCPAN::HandleConfig', '-e', 'CPAN::HandleConfig->load; CPAN::Shell::setup_output; CPAN::Index->force_reload();' ],
        smoke => [ '-MCPAN::Reporter::Smoker', '-e', 'my $module = shift; start( list => [ $module ] );' ],

);

my $backend = POE::Component::SmokeBox::Backend::CPAN::Reporter::Smoker->new();
isa_ok( $backend, 'POE::Component::SmokeBox::Backend::CPAN::Reporter::Smoker' );
isa_ok( $backend, 'POE::Component::SmokeBox::Backend::Base' );

my %tests;
$tests{$_} = $backend->$_ for keys %data;

foreach my $cmd ( keys %tests ) {
  my $test = $tests{$cmd};
  my $data = $data{$cmd};
  ok( $test->[$_] eq $data->[$_], "Test: $test->[$_]" ) for 0 .. $#{ $test };
}
