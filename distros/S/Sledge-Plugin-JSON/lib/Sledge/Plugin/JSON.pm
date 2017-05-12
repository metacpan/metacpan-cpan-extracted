package Sledge::Plugin::JSON;
use warnings;
use strict;

use JSON::Syck;

our $VERSION = '0.01';
our $ConformToRFC4627 = 0;

sub import {
    my $self = shift;
    my $pkg  = caller;

    no strict 'refs';
    *{"$pkg\::output_json"} = \&_output_json;
}

sub _output_json {
    my ($self, $args) = @_;

    my $encoding = $args->{encoding} ? $args->{encoding} : 'utf-8';

    my $content_type =
        ( $self->debug_level && $self->r->param('debug') )
        ? "text/plain; charset=$encoding"
        : _content_type($self, $encoding );

    my $json = JSON::Syck::Dump($args->{data});
    my $output = _add_callback($self, _validate_callback_param($self, $self->r->param('callback')), $json );

    $self->r->content_type($content_type);
    $self->set_content_length(length $output);
    $self->send_http_header;
    $self->r->print($output);
    $self->invoke_hook('AFTER_OUTPUT');
    $self->finished(1);
}

# copy from Catalyst::View::JSON
sub _content_type {
    my ($self, $encoding) = @_;

    my $user_agent = $self->can('mobile') ? $self->mobile->agent->user_agent
                                          : $self->r->header_in('User-Agent');

    if ( $ConformToRFC4627 ) {
        return "application/json; charset=$encoding";
    } elsif (($user_agent || '') =~ /Opera/) {
        return "application/x-javascript; charset=$encoding";
    } else {
        return "application/javascript; charset=$encoding";
    }
}

sub _add_callback {
    my ($self, $cb, $json) = @_;

    my $output;
    $output .= "$cb(" if $cb;
    $output .= $json;
    $output .= ");"   if $cb;

    return $output;
}

sub _validate_callback_param {
   my ($self, $param) = @_;
   return ( $param =~ /^[a-zA-Z0-9\.\_\[\]]+$/ ) ? $param : undef;
}

=head1 NAME

Sledge::Plugin::JSON - JSON plugin for Sledge

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::JSON;

    $self->output_json(
        {
            data     => \@data,
            encoding => 'euc-jp',
        }
    );

=head1 DESCRIPTION

Sledge::Plugin::JSON is easy to implement JSON plugin for Sledge.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sledge-plugin-json at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sledge-Plugin-JSON>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHORS

Atsushi Kobayashi  C<< <atsushi __at__ mobilefactory.jp> >>
hi-rocks

=head1 THANKS TO

tokurirom
Kensuke Kaneko

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sledge::Plugin::JSON

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sledge-Plugin-JSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sledge-Plugin-JSON>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Plugin-JSON>

=item * Search CPAN

L<http://search.cpan.org/dist/Sledge-Plugin-JSON>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Atsushi Kobayashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sledge::Plugin::JSON
