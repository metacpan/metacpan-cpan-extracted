##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Terminal/Configuration.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Terminal::Configuration;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub bbpos_wisepos_e { return( shift->_set_get_class( 'bbpos_wisepos_e',
{
  splashscreen => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
}, @_ ) ); }

sub is_account_default { return( shift->_set_get_boolean( 'is_account_default', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub tipping { return( shift->_set_get_class( 'tipping',
{
  aud => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  cad => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  chf => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  czk => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  dkk => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  eur => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  gbp => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  hkd => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  myr => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  nok => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  nzd => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  sek => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  sgd => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
  usd => {
           definition => {
             fixed_amounts       => { type => "array" },
             percentages         => { type => "array" },
             smart_tip_threshold => { type => "number" },
           },
           type => "class",
         },
}, @_ ) ); }

sub verifone_p400 { return( shift->_set_get_class( 'verifone_p400',
{
  splashscreen => { package => "Net::API::Stripe::File", type => "scalar_or_object" },
}, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Terminal::Configuration - The Configuration object

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

A Configurations object represents how features should be configured for terminal readers.


=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 bbpos_wisepos_e hash

An object containing device type specific settings for BBPOS WisePOS E

It has the following properties:

=over 4

=item C<splashscreen> string expandable

A File ID representing an image you would like displayed on the reader.

When expanded this is an L<Net::API::Stripe::File> object.

=back

=head2 is_account_default boolean

Whether this Configuration is the default for your account

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 tipping hash

On-reader tipping settings

It has the following properties:

=over 4

=item C<aud> hash

Tipping configuration for AUD

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<cad> hash

Tipping configuration for CAD

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<chf> hash

Tipping configuration for CHF

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<czk> hash

Tipping configuration for CZK

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<dkk> hash

Tipping configuration for DKK

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<eur> hash

Tipping configuration for EUR

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<gbp> hash

Tipping configuration for GBP

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<hkd> hash

Tipping configuration for HKD

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<myr> hash

Tipping configuration for MYR

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<nok> hash

Tipping configuration for NOK

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<nzd> hash

Tipping configuration for NZD

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<sek> hash

Tipping configuration for SEK

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<sgd> hash

Tipping configuration for SGD

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=item C<usd> hash

Tipping configuration for USD

=over 8

=item C<fixed_amounts> array

Fixed amounts displayed when collecting a tip

=item C<percentages> array

Percentages displayed when collecting a tip

=item C<smart_tip_threshold> integer

Below this amount, fixed amounts will be displayed; above it, percentages will be displayed


=back

=back

=head2 verifone_p400 hash

An object containing device type specific settings for Verifone P400

It has the following properties:

=over 4

=item C<splashscreen> string expandable

A File ID representing an image you would like displayed on the reader.

When expanded this is an L<Net::API::Stripe::File> object.

=back

=head1 API SAMPLE

[
   {
      "bbpos_wisepos_e" : {
         "splashscreen" : "file_1Le9F32eZvKYlo2CHWjaVfbW"
      },
      "id" : "tmc_ElVUAjF8xXG3hj",
      "is_account_default" : 0,
      "livemode" : 0,
      "object" : "terminal.configuration"
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|https://stripe.com/docs/api/terminal/configuration>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
