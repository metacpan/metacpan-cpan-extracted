package Say::Compat;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.01;

sub import {
    my $class = shift;
    my $caller = caller;

    if( $] < 5.010 ) {
        require Perl6::Say;
        Perl6::Say->import;

        no strict 'refs';
        *{$caller . '::say'} = \&Perl6::Say::say;
    }
    else {
        require feature;
        feature->import("say");
    }
}


=head1 NAME

Say::Compat - Backwards compatibility wrapper for say()

=head1 SYNOPSIS

    use Say::Compat;

    say "Hello world!";
    say STDERR "Hello error!";

=head1 DESCRIPTION

This is a compatibility layer to allow Perl code to use C<say()>
without sacrificing backwards compatibility.  Simply use the
module in your code and it will do the right thing.

When used on a Perl before 5.10, it will load L<Perl6::Say>.

When used on 5.10 or later it will load the built in L<say()|feature>.

=head1 CAVEATS

Perl6::Say does not fully emulate all the syntax of the real say.
Therefore, to avoid incompatibilities, you must code to its
limitations.  See the documentation for Perl6::Say for details.

Future versions may use a different module to emulate say, but
they will strive to avoid 

=cut

1;
