#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Pod::Simpler::Aoh' ) || print "Bail out!\n";
}

subtest 'hash options' => sub {
    test_value({
        get => 0,
        identifier => 'head1',
        content => 'perlfaq3 - Programming Tools ($Revision: 1.38 $, $Date: 1999/05/23 16:08:30 $)',
        title => 'NAME',
    });
    test_value({
        get => 9,
        identifier => 'head2',
        title => 'Is there a ctags for Perl?',
        content => "There's a simple one at http://www.perl.com/CPAN/authors/id/TOMC/scripts/ptags.gz which may do the trick. And if not, it's easy to hack into what you want.",
    });
    test_value({
        get => 13,
        identifier => 'head2',
        title => 'How can I use curses with Perl?',
        content => "The Curses module from CPAN provides a dynamically loadable object module interface to a curses library. A small demo can be found at the directory http://www.perl.com/CPAN/authors/Tom_Christiansen/scripts/rep; this program repeats a command and updates the screen as needed, rendering rep ps axu similar to top.",
    });
};

done_testing();

sub test_value {
    my $args = shift;

    my $parser = Pod::Simpler::Aoh->new();
    my $things = $parser->parse_file( 't/data/perlfaq.pod' );
    my $values = $parser->get($args->{get});
    
    my @fields = qw(identifier content title);
    foreach my $field (@fields) {
        is($values->{$field}, $args->{$field}, "correct value for $field - get $args->{get}");
    }
}

1;
