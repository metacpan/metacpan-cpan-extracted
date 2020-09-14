package Regru::API::Hosting;

# ABSTRACT: REG.API v2 hosting management functions

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.051'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'hosting' },
);

sub available_methods {[qw(
    nop
    get_jelastic_refill_url
    set_jelastic_refill_url
    get_parallelswpb_constructor_url
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::Hosting

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Hosting - REG.API v2 hosting management functions

=head1 VERSION

version 0.051

=head1 DESCRIPTION

REG.API hosting management functions. Most of their available only for C<partners>.

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<hosting>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes. Scope: B<everyone>. Typical usage:

    $resp = $client->hosting->nop;

Returns success response.

More info at L<Hosting management: nop|https://www.reg.com/support/help/api2#hosting_nop>.

=head2 set_jelastic_refill_url

Update Jelastic refill URL for current reseller. That url is used when client hits "Refill" button at his Jelastic account page. Keywords C<< <service_id> >> and C<< <email> >> in url will be replaced
with service identifier and user email, which was used for Jelastic account registration.
Scope B<partners>.

Typical usage:

    $resp = $client->hosting->set_jelastic_refill_url(
        url => 'http://mysite.com?service_id=<service_id>&email=<email>'
    );

Returns success response if URL was set.
More info at L<Hosting management: set_jelastic_refill_url|https://www.reg.com/support/help/api2#hosting_set_jelastic_refill_url>.

=head2 get_jelastic_refill_url

Fetch Jelastic refill URL for current reseller. Scope: B<partners>. Typical usage:

    $resp = $client->hosting->get_jelastic_refill_url;

Answer will contain the C<url> field, with reseller refill url.

More info at L<Hosting management: get_jelastic_refill_url|https://www.reg.com/support/help/api2#hosting_get_jelastic_refill_url>.

=head2 get_parallelswpb_constructor_url

Retrieves an URL for ParallelsWPB constructor. Scope: B<clients>. Typical usage:

    $resp = $client->hosting->get_parallelswpb_constructor_url(
        service_id => 2312677,
    );

Answer will contain the C<url> field, with URL for ParallelsWPB constructor.

More info at L<Hosting management: get_parallelswpb_constructor_url|https://www.reg.com/support/help/api2#hosting_get_parallelswpb_constructor_url>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<REG.API Hosting management|https://www.reg.com/support/help/api2#hosting_functions>

L<REG.API Common error codes|https://www.reg.com/support/help/api2#common_errors>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/regru/regru-api-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
