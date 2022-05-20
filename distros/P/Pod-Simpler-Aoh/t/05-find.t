#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Pod::Simpler::Aoh' ) || print "Bail out!\n";
}

subtest 'hash options' => sub {
    test_value({
        find => ["title", "NAME"],
        identifier => 'head1',
        content => 'perlfaq3 - Programming Tools ($Revision: 1.38 $, $Date: 1999/05/23 16:08:30 $)',
        title => 'NAME',
    });
};

done_testing();

sub test_value {
    my $args = shift;

    my $parser = Pod::Simpler::Aoh->new();
    my $things = $parser->parse_file( 't/data/perlfaq.pod' );
    my $values = $parser->find(@{$args->{find}});
    my @fields = qw(identifier content title);
    foreach my $field (@fields) {
        is($values->{$field}, $args->{$field}, "correct value for $field - find");
    }
}

1;
