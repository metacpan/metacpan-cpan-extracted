# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer/Call.pm 43085 2008-03-01T12:28:42.888222Z daisuke  $
#
# Copyright (c) 2008 Daisuke Maki <daisuke@endeworks.jp>
# all rights reserved.

package R::Writer::Call;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(call args delimiter end_of_call_chain);

sub new
{
    my $class = shift;
    my %args  = @_;
    $class->SUPER::new({ @_ });
}

sub as_string
{
    my $self = shift;
    my $c    = shift;

    my $f = $self->call;
    my $args = $self->args;
    return ($self->{object} ?  "$self->{object}." : "" ) .
        "$f(" .
            join(",",
                 map {
                     $c->__obj_as_string( $_ );
                 } @$args
             ) . ")"
    ;
}

1;

__END__

=head1 NAME

R::Writer::Call - Function Calls

=head1 SYNOPSIS

  use R::Writer::Call;
  # Internal use only

=head1 METHODS

=head2 new

=head2 as_string

=cut
