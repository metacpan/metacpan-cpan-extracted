package Sledge::Plugin::RedirectReferer;
use strict;
use warnings;
use URI;

our $VERSION = '0.04';
our $LAST_URL_KEY = '_last_url';

sub import {
    my $self = shift;
    my $pkg  = caller;

    no strict 'refs';
    *{"$pkg\::redirect_referer"} = sub {
        my ($self , $url) = @_;
        my $redirect_url = $self->session->param( $LAST_URL_KEY ) ? $self->session->param( $LAST_URL_KEY )
                                                                  : $self->r->header_in('Referer');
        if ( $redirect_url ) {
            my $uri = URI->new($redirect_url);
            if ( $uri->host eq $self->r->hostname ) {
                return $self->redirect($uri->path_query);
            } else {
                return $self->redirect($uri->as_string);
            }
        } else {
            return $self->redirect($url);
        }
    };

    *{"$pkg\::last_access_url"} = sub {
        shift->session->param( $LAST_URL_KEY );
    };

    $pkg->register_hook(
        AFTER_OUTPUT => \&store_url,
    );
}

sub store_url {
    my $self = shift;
    $self->session->param( $LAST_URL_KEY => $self->current_url );
}

=head1 NAME

Sledge::Plugin::RedirectReferer - referer redirect plugin for Sledge

=head1 VERSION

This documentation refers to Sledge::Plugin::RedirectReferer version 0.04

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::RedirectReferer;

    sub dispatch_index {
        my $self = shift;
        return $self->redirect_referer('/if/non/referer');
    }

=head1 METHODS

=head2 redirect_referer

    This method redirect referer.

=head2 last_access_url

    This method get your last access url.

=head1 AUTHOR

Atsushi Kobayashi, C<< <nekokak at gmail> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sledge-plugin-redirectreferer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sledge-Plugin-RedirectReferer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sledge::Plugin::RedirectReferer

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sledge-Plugin-RedirectReferer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sledge-Plugin-RedirectReferer>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Plugin-RedirectReferer>

=item * Search CPAN

L<http://search.cpan.org/dist/Sledge-Plugin-RedirectReferer>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Atsushi Kobayashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1
# End of Sledge::Plugin::RedirectReferer
