package Net::Amazon::Signature;

use strict;
use warnings;
use Spiffy -Base;
field 'Service';

use URI::Escape;
use DateTime;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64;

=head1 NAME

Net::Amazon::Signature

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;

=head1 SYNOPSIS

 use Net::Amazon::Signature;
 my $sig_maker = Net::Amazon::Signature->new(Service => AWSServiceName);

 my ($signature, $timestamp) = $sig_maker->create({
  Operation => 'GetInfo', 
  SecretAccessKey => 'Your Secret Key Here',
  uri_escape => 1
 });

 # go ahead and make your SOAP or REST call now...


=head1 DESCRIPTION

This module creates the encrypted signature needed to login to Amazon's Mechanical Turk and Alexa web services and any other web services that Amazon might make in the future that require an encrypted signature, assuming they follow the same convention.

=cut


=head1 METHODS

=head2 new

 creates a new Net::Amazon::Signature object
 Takes in a hashref with key Service
 Example
 my $foo = Net::Amazon::Signature->new({Service => 'AWSMechanicalTurkRequester'});

=cut

=head2 create

 Creates the signature. The method takes in a hashref with two required values:
 * SecretAccessKey - the secret access key that Amazon has assigned to you.
 * Operation - the name of the operation to perform.

 Returns an array with the signature and the timestamp used in creating the authenticated request.

=cut

sub create
{
  my $args = shift;
  die "need SecretAccessKey" if !$args->{SecretAccessKey};
  die "need Operation"       if !$args->{Operation};

  my $timestamp = DateTime->now() . 'Z';
  my $operation = $args->{Operation};
  my $sig = $self->Service().$operation.$timestamp;
  my $digest =$self->_make_signature($sig,$args->{SecretAccessKey});

  if (defined $args->{uri_escape})
  {
    $digest = uri_escape($digest);
    $timestamp = uri_escape($timestamp);
  }
  return ($digest, $timestamp);
}

=head2 _make_signature

makes the encoded signature give an unencoded string and a hashing key (the secret access id).
You do not need to call this function directly. Call create_signature instead.

=cut

sub _make_signature
{
  my ($sig,$key) =  @_;
  my $hmac = hmac_sha1(@_);
  my $digest = encode_base64($hmac);
  chomp $digest;
  return $digest;
}

=head1 AUTHOR

Rachel Richard, C<< <rachel at nmcfarl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-amazon-signature at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Amazon-Signature>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Amazon::Signature

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Amazon-Signature>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Amazon-Signature>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Amazon-Signature>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Amazon-Signature>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rachel Richard, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
