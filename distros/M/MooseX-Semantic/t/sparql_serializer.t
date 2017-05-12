use Test::More skip_all => 'This shouldnt be part of MooseX::Semantic';
use MooseX::Semantic::Test::Person;
use Data::Dumper;

my $p = MooseX::Semantic::Test::Person->new(
    name => 'James',
);
# warn Dumper $p->export_to_string( format => 'sparqlu' );
