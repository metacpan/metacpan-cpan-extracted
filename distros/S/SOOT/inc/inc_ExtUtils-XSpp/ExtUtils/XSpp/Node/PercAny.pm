package ExtUtils::XSpp::Node::PercAny;

use strict;
use base 'ExtUtils::XSpp::Node';

=head1 NAME

ExtUtils::XSpp::Node::PercAny - contains information about %Foo tags handled by plugins

=head1 DESCRIPTION

Used internally during parsing.

=cut

sub init {
    my( $this, %args ) = @_;

    $this->{NAME} = $args{any};
    $this->{NAMED_ARGUMENTS} = $args{any_named_arguments};
    $this->{POSITIONAL_ARGUMENTS} = $args{any_positional_arguments};
}

1;
