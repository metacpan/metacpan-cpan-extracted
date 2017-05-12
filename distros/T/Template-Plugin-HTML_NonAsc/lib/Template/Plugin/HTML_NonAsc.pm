#! perl

# Author          : Johan Vromans
# Created On      : Fri Aug  5 20:19:18 2010
# Last Modified By: Johan Vromans
# Last Modified On: Mon Aug 16 07:53:45 2010
# Update Count    : 29
# Status          : Unknown, Use with caution!

=head1 NAME

Template::Plugin::HTML_NonAsc - Slightly less picky html filter.

=head1 SYNOPSIS

This filter behaves like the builtin html filter except that it does
B<not> escape ASCII characters, I<including C<< < >>, C<< > >>, C<< & >>,
and C<< " >>>. This makes it possible to write templates in HTML using
non-ASCII characters. Pass the contents through this filter and all
non-ASCII characters will be escaped using HTML entities.

The best place to apply this filter is in your page/wrapper:

    [%
    USE HTML_NonAsc;		# for html_nonasc filter
    SWITCH page.type;
        ...
        CASE "html";
            content | html_nonasc
                WRAPPER page/html
                        + page/layout;
        ...
        CASE;
            THROW page.type "Invalid page type: $page.type";
    END;
    -%]

=cut

use 5.008003;
use strict;
use warnings;

package Template::Plugin::HTML_NonAsc;

our $VERSION = 0.03;

use base qw( Template::Plugin::Filter );

use HTML::Entities;

sub init {
    my $self = shift;
    my $name = $self->{ _CONFIG }->{name} || 'html_nonasc';
    $self->install_filter($name);
    return $self;
}

sub filter {
    my ( $self, $parameter ) = @_;
    encode_entities( $parameter, '^\n\x20-\x7e' );
    $parameter;
}

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-html_nonasc at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-HTML_NonAsc>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
