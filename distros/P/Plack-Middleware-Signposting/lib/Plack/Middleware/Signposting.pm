package Plack::Middleware::Signposting;

our $VERSION = '0.05';

use Catmandu::Sane;
use parent 'Plack::Middleware';

sub to_link_format {
    my ($self, @signs) = @_;

    my $body = join(", ", map {
        my ($uri, $relation, $type) = @$_;
        my $link_text = qq|<$uri>; rel="$relation"|;
        $link_text .= qq|; type="$type"| if $type;
        $link_text;
    } @signs);

    $body;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Signposting - a base class for Plack implementations of the L<Signposting|https://signposting.org> protocol

=begin markdown

[![Build Status](https://travis-ci.org/LibreCat/Plack-Middleware-Signposting.svg?branch=master)](https://travis-ci.org/LibreCat/Plack-Middleware-Signposting)
[![Coverage Status](https://coveralls.io/repos/github/LibreCat/Plack-Middleware-Signposting/badge.svg?branch=master)](https://coveralls.io/github/LibreCat/Plack-Middleware-Signposting?branch=master)

=end markdown

=head1 SYNOPSIS

    package Plack::Middleware::Signposting::Foo;

    use Moo;

    extends 'Plack::Middleware::Signposting';

    sub call {
        my ($self, $env) = @_;

        ...
        my @data = ("0001", $relation, $type);
        $self->to_link_format(\@data);
    }

=head1 METHODS

=over

=item * to_link_format(\@ARRAY)

This method produces the format for the link header.

=back

=head1 MODULES

=over

=item * L<Plack::Middleware::Signposting::JSON>

=item * L<Plack::Middleware::Signposting::Catmandu>

=back

=head1 AUTHOR

Vitali Peil, C<< <vitali.peil at uni-bielefeld.de> >>

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<Plack::Middleware>

=cut
