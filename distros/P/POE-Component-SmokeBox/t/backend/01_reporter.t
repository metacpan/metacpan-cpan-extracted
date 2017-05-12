use strict;
use warnings;
use Test::More tests => 13;
use_ok('POE::Component::SmokeBox::Backend::CPAN::Reporter');

my %data = (
        check => [ '-MCPAN::Reporter', '-e', 1 ],
        index => [ '-MCPAN', '-MCPAN::HandleConfig', '-e', 'CPAN::HandleConfig->load; CPAN::Shell::setup_output; CPAN::Index->force_reload();' ],
        smoke => [ '-MCPAN', '-e', 'my $module = shift; $CPAN::Config->{test_report} = 1; CPAN::Index->reload; $CPAN::META->reset_tested; test($module);' ],

);

my $backend = POE::Component::SmokeBox::Backend::CPAN::Reporter->new();
isa_ok( $backend, 'POE::Component::SmokeBox::Backend::CPAN::Reporter' );
isa_ok( $backend, 'POE::Component::SmokeBox::Backend::Base' );

my %tests;
$tests{$_} = $backend->$_ for keys %data;

foreach my $cmd ( keys %tests ) {
  my $test = $tests{$cmd};
  my $data = $data{$cmd};
  ok( $test->[$_] eq $data->[$_], "Test: $test->[$_]" ) for 0 .. $#{ $test };
}
