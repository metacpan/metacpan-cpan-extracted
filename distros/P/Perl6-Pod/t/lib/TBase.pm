#===============================================================================
#  DESCRIPTION:  Base class for tests
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zag@cpan.org>
#===============================================================================
package TBase;
use strict;
use warnings;
use Test::More;
use Test::Class;
use Perl6::Pod::Test;
use base qw( Test::Class Perl6::Pod::Test );

sub testing_class {
    my $test = shift;
    ( my $class = ref $test ) =~ s/^T[^:]*::/Perl6::Pod::/;
    return $class;
}

sub new_args { () }

sub _use : Test(startup=>1) {
    my $test = shift;
    use_ok $test->testing_class;
}


1;

