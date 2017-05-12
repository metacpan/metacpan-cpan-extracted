package Paymill::REST;

use strict;
use 5.008_005;
our $VERSION = '0.02';

my $PRIVATE_KEY = '';

use Module::Find;

BEGIN {
    useall Paymill::REST;
}

1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST - A wrapper around PAYMILL's payment API

=head1 SYNOPSIS

  use Paymill::REST;
  my $trx_api             = Paymill::REST::Transactions->new;
  my $created_transaction = $trx_api->create(
      {
          amount      => 4200,
          token       => '098f6bcd4621d373cade4e832627b4f6',
          currency    => 'USD',
          description => "Hitchhiker's Guide to the Galaxy",
      }
  );

=head1 DESCRIPTION

Paymill::REST is a wrapper around PAYMILL's payment API.

=head1 GENERAL ARCHITECTURE

It is intended that things such creating and retrieving items is done through
operations called on the respective C<Paymill::REST::*> modules (a so called B<item factory>), so
everything related to transactions is achieved
through L<Paymill::REST::Transactions>.

Each operation of those factories is returning one or a list of the
appropriate item modules, so operations called on L<Paymill::REST::Transactions>
are returning one or a list of L<Paymill::REST::Item::Transaction>.

=head2 AVAILABLE OPERATIONS

Not all operations are available to every item factory (currently only
C<delete> is not available to L<Paymill::REST::Item::Refund>).

=over 4

=item Creating new items

L<Paymill::REST::Operations::Create>

=item Delete existing items

L<Paymill::REST::Operations::Delete>

=item Find a single item

L<Paymill::REST::Operations::Find>

=item List all or a subset of items

L<Paymill::REST::Operations::List>

=back

=head1 CONFIGURATION

Each item factory inherits from L<Paymill::REST::Base>, which is
holding all the configuration.  The following options are available:

=over 4

=item api_key

Defines your private API key which you get from PAYMILL.

=item proxy

An L<URI> or URI string which is passed to L<LWP::UserAgent>'s C<proxy>
method for connecting to the PAYMILL API.

=back

B<Note:> every other option you'll find in the code is only meant for
development of this module and shouldn't be changed!

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item PAYMILL:

L<http://www.paymill.com>

=item Item factories:

L<Paymill::REST::Clients>, L<Paymill::REST::Offers>, L<Paymill::REST::Payments>,
L<Paymill::REST::Preauthorizations>, L<Paymill::REST::Refunds>,
L<Paymill::REST::Subscriptions>, L<Paymill::REST::Transactions>,
L<Paymill::REST::Webhooks>

=item Item modules:

L<Paymill::REST::Item::Client>, L<Paymill::REST::Item::Offer>, L<Paymill::REST::Item::Payment>,
L<Paymill::REST::Item::Preauthorization>, L<Paymill::REST::Item::Refund>,
L<Paymill::REST::Item::Subscription>, L<Paymill::REST::Item::Transaction>,
L<Paymill::REST::Item::Webhook>

=back

=head1 TODO

=over 4

=item Add ability to save changes to item objects

=item Add convenience operations (eg. C<refund> for transactions) where possible

=back

=cut
