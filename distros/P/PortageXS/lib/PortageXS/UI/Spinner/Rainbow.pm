use strict;
use warnings;

package PortageXS::UI::Spinner::Rainbow;
BEGIN {
  $PortageXS::UI::Spinner::Rainbow::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::UI::Spinner::Rainbow::VERSION = '0.3.1';
}

# ABSTRACT: Console progress spinner bling.
# -----------------------------------------------------------------------------
#
# PortageXS::UI::Spinner
#
# author      : Christian Hartmann <ian@gentoo.org>
# license     : GPL-2
# header      : $Header: /srv/cvsroot/portagexs/trunk/lib/PortageXS/UI/Spinner.pm,v 1.1.1.1 2006/11/13 00:28:34 ian Exp $
#
# -----------------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# -----------------------------------------------------------------------------

use Moo;
extends 'PortageXS::UI::Spinner';

use IO::Handle;




has colorstate => ( is => rwp =>, default => sub { 0 } );


has colorstates => (
    is      => ro =>,
    default => sub {
        require Term::ANSIColor;
        my @c;
        push @c, map { Term::ANSIColor::color( 'bold ansi' . $_ ) } 1 .. 15;
        push @c, map { Term::ANSIColor::color( 'ansi' . $_ ) } 1 .. 15;
        \@c;
    }
);


sub _last_colorstate { return $#{ $_[0]->colorstates } }


sub _increment_colorstate {
    my $self      = shift;
    my $rval      = $self->colorstate;
    my $nextstate = $rval + 0.3;
    if ( $nextstate > $self->_last_colorstate ) {
        $nextstate = 0;
    }
    $self->_set_colorstate($nextstate);
    return $rval;
}


sub _get_next_colorstate {
    my (@states) = @{ $_[0]->colorstates };
    return $states[ $_[0]->_increment_colorstate ];
}


sub _print_to_output {
    my $self = shift;
    $self->output_handle->print(@_);
}


sub spin {
    my $self = shift;
    require Term::ANSIColor;
    $self->_print_to_output( "\b"
          . $self->_get_next_colorstate
          . $self->_get_next_spinstate
          . Term::ANSIColor::color('reset') );
}


sub reset {
    $_[0]->_print_to_output("\b \b");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::UI::Spinner::Rainbow - Console progress spinner bling.

=head1 VERSION

version 0.3.1

=head1 SYNOPSIS

    use PortageXS::UI::Spinner::Rainbow;

    my $spinner = PortageXS::UI::Spinner->new(%attributes);

    for ( 0..1000 ){
        sleep 0.1;
        $spinner->spin;
    }
    $spinner->reset;

=head1 METHODS

=head2 C<spin>

Emits a backspace and the next spin character to L<< C<output_handle>|/output_handle >>

=head2 C<reset>

Emits a spin-character clearing sequence to L<< C<output_handle>|/output_handle >>

This is just

    \b : backspace over last character
    \s : print a space to erase past characters
    \b : backspace again to prepare for more output

=head1 ATTRIBUTES

=head2 C<colorstate>

The index of the I<next> color state to dispatch.

=head2 C<colorstates>

A list of colors to dispatch.

=head1 PRIVATE METHODS

=head2 C<_last_colorstate>

The number of L<< C<colorstates>|/colorstates >> this C<::Spinner::Rainbow> object has.

=head2 C<_increment_colorstate>

Increment the position within the L<< C<colorstates>|/colorstates >> array by one, updating L<< C<colorstate>|/colorstate >>

=head2 C<_get_next_colorstate>

Returns the next character from the L<< C<colorstates>|/colorstates >> array

=head2 C<_print_to_output>

Internal wrapper to proxy C<print> to L<< C<output_handle>|/output_handle >>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::UI::Spinner::Rainbow",
    "inherits":["PortageXS::UI::Spinner"],
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHORS

=over 4

=item *

Christian Hartmann <ian@gentoo.org>

=item *

Torsten Veller <tove@gentoo.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Christian Hartmann.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
