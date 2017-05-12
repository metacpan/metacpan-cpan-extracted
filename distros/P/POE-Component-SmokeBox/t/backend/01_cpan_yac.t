use strict;
use warnings;
use Test::More tests => 12;
use_ok('POE::Component::SmokeBox::Backend::CPAN::YACSmoke');

my %data = (
        check => [ '-MCPAN::YACSmoke', '-e', 1 ],
        index => [ '-MCPANPLUS::Backend', '-e', 'CPANPLUS::Backend->new()->reload_indices( update_source => 1 );' ],
        smoke => [ '-MCPAN::YACSmoke', '-e', 'my $module = shift; my $smoke = CPAN::YACSmoke->new(); $smoke->test($module);' ],
);

my $backend = POE::Component::SmokeBox::Backend::CPAN::YACSmoke->new();
isa_ok( $backend, 'POE::Component::SmokeBox::Backend::CPAN::YACSmoke' );
isa_ok( $backend, 'POE::Component::SmokeBox::Backend::Base' );

my %tests;
$tests{$_} = $backend->$_ for keys %data;

foreach my $cmd ( keys %tests ) {
  my $test = $tests{$cmd};
  my $data = $data{$cmd};
  ok( $test->[$_] eq $data->[$_], "Test: $test->[$_]" ) for 0 .. $#{ $test };
}
