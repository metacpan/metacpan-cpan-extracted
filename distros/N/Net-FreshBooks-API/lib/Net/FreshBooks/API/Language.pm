use strict;
use warnings;

package Net::FreshBooks::API::Language;
$Net::FreshBooks::API::Language::VERSION = '0.24';
use Moose;
extends 'Net::FreshBooks::API::Base';

# language does not provide "get"
with 'Net::FreshBooks::API::Role::Iterator' => { -excludes => 'get' };

has $_ => ( is => _fields()->{$_}->{is} ) for sort keys %{ _fields() };

sub _fields {
    return {
        code => { is => 'ro' },
        name => { is => 'ro' },
    };
}

__PACKAGE__->meta->make_immutable();

1;

# ABSTRACT: List the languages your FreshBooks account supports

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Language - List the languages your FreshBooks account supports

=head1 VERSION

version 0.24

=head1 SYNOPSIS

    my $fb = Net::FreshBooks::API->new(...);
    my $languages = $fb->language->get_all();

=head2 list

Returns an L<Net::FreshBooks::API::Iterator> object. Currently, all list()
functionality defaults to 15 items per page.

On a practical level, you'll never want to use this method.  get_all() will
provide you with what you need.

=head2 get_all

Returns an ARRAYREF of all possible results, handling pagination for you.

    my $languages = $fb->language->get_all;
    foreach my $language( @{ $languages } ) {
        print $language->name, ' ', $language->code, "\n";
    }

=head1 DESCRIPTION

Returns a list of language names and the corresponding codes that you can use
for clients, invoices and estimates. The codes are from IETF RFC 5646, which
is usually the two-letter ISO-639-1 code. See
L<http://developers.freshbooks.com/docs/languages/> for more info.

You should note that there is no "get" method for Language as the API does not
provide it.

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
