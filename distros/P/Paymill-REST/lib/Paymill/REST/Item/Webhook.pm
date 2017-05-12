package Paymill::REST::Item::Webhook;

use Moose;
use MooseX::Types::DateTime::ButMaintained qw(DateTime);
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Email qw(EmailAddress);

with 'Paymill::REST::Operations::Delete';

has _factory => (is => 'ro', isa => 'Object');

has id          => (is => 'ro', isa => 'Str');
has url         => (is => 'ro', isa => Uri, coerce => 1);
has email       => (is => 'ro', isa => EmailAddress);
has livemode    => (is => 'ro', isa => 'Bool');
has event_types => (is => 'ro', isa => 'ArrayRef[Str]');
has app_id      => (is => 'ro', isa => 'Undef|Str');

no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Item::Webhook - Item class for a webhook

=head1 SYNOPSIS

  my $webhook_api = Paymill::REST::Webhooks->new;
  $webhook = $webhook_api->find('hook_lk2j34h5lk34h5lkjh2');

  say $webhook->url;  # Prints the URL of the webhook

=head1 DESCRIPTION

Represents a webhook with all attributes.

=head1 ATTRIBUTES

=over 4

=item id

String containing the identifier of the webhook

=item url

L<Uri> object of the webhook's URL

=item email

String containing the webhook's e-mail address

=item livemode

Boolean indicating whether this webhook is for livemode events

=item event_types

Array of event types this webhook is subscribed to

=item app_id

String representing the app id that created this webhook

=back

=head1 AVAILABLE OPERATIONS

=over 4

=item delete

L<Paymill::REST::Operations::Delete>

=back

=head1 SEE ALSO

L<Paymill::REST> for more documentation.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
