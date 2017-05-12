package Silki::Action::REST;
{
  $Silki::Action::REST::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose;

extends 'Catalyst::Action::REST';

override dispatch => sub {
    my $self = shift;
    my $c    = shift;

    if ( $c->request()->looks_like_browser()
        && uc $c->request()->method() eq 'GET' ) {
        my $controller = $self->class();
        my $method     = $self->name() . '_GET_html';

        if ( $controller->can($method) ) {
            $c->execute( $self->class, $self, @{ $c->req->args } );

            return $controller->$method( $c, @{ $c->request()->args() } );
        }
    }

    return super();
};

# Intentionally not immutable. Catalyst should take care of this for us, I
# think.

1;

# ABSTRACT: Extends dispatch to add get_FOO_html

__END__
=pod

=head1 NAME

Silki::Action::REST - Extends dispatch to add get_FOO_html

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

