use strict;
use warnings;
use Test::More;
use Moose 2.1604;
use Test::Moose 2.1604;

my $class = 'Term::YAP::Process';

BEGIN { use_ok('Term::YAP::Process') }

my @attribs = qw(child_pid usr1 enough);

foreach my $attrib (@attribs) {

    has_attribute_ok( $class, $attrib );

}

can_ok( $class,
    qw(get_child_pid _set_child_pid get_usr1 _set_usr1 is_enough _set_enough) );

plan tests => ( scalar(@attribs) ) + 2;
