package SNS::Notification;
  use Moose;

  our $VERSION = '0.02';

  has Timestamp => (is => 'ro', isa => 'Str', required => 1);
  has TopicArn => (is => 'ro', isa => 'Str', required => 1);
  has Type => (is => 'ro', isa => 'Str', required => 1);
  has MessageId => (is => 'ro', isa => 'Str', required => 1);
  has Message => (is => 'ro', isa => 'Str', required => 1);
  has UnsubscribeURL => (is => 'ro', isa => 'Str', required => 1);
  has Signature => (is => 'ro', isa => 'Str', required => 1);
  has SignatureVersion => (is => 'ro', isa => 'Str', required => 1);
  has Subject => (is => 'ro', isa => 'Str');
  has SigningCertURL => (is => 'ro', isa => 'Str', required => 1);


  __PACKAGE__->meta->make_immutable;

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

SNS::Notification - An object for representing SNS Notifications

=head1 SYNOPSIS

  use SNS::Notification;
  my $not = SNS::Notification->new(
    Timestamp => ...
    ... required attributes ...
  );
  #do something with $obj

  my $body = decode_json($sns_message);
  my $sns = eval { SNS::Notification->new($body) };
  if ($@) {
    die "Doesn't look like an SNS::Message to me";
  }
  print $sns->Message;

=head1 DESCRIPTION

This module holds an object for representing an SNS messsage. It tries
to validate that all appropiate fields are present.

This is really just a module for other modules that work with SNS to
depend on (and not reimplement it constantly).

=head1 SEE ALSO

L<http://docs.aws.amazon.com/sns/latest/dg/json-formats.html>

L<http://docs.aws.amazon.com/sns/latest/dg/SendMessageToHttp.html>

L<http://docs.aws.amazon.com/sns/latest/dg/SendMessageToSQS.html>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2016 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
