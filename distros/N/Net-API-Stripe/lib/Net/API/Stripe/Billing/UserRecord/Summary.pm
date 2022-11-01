##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Billing/UserRecord/Summary.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/29
## Modified 2022/10/29
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Billing::UserRecord::Summary;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = 'v0.1.0';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub invoice { return( shift->_set_get_scalar( 'invoice', @_ ) ); }

sub livemode { return( shift->_set_get_number( 'livemode', @_ ) ); }

sub period { return( shift->_set_get_hash( 'period', @_ ) ); }

sub subscription_item { return( shift->_set_get_scalar( 'subscription_item', @_ ) ); }

sub total_usage { return( shift->_set_get_number( 'total_usage', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Billing::UserRecord::Summary - Usage Record Summary

=head1 SYNOPSIS

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION



=head1 METHODS

=head2 id string



=head2 object string



=head2 invoice string



=head2 livemode integer



=head2 period hash



=head2 subscription_item string



=head2 total_usage integer

=head1 API SAMPLE

[
   {
      "id" : "sis_1DkWqo2eZvKYlo2Cs4NSCMMw",
      "invoice" : "in_1DkWqo2eZvKYlo2Cghtks5xk",
      "livemode" : "0",
      "object" : "usage_record_summary",
      "period" : {
         "end" : null,
         "start" : null
      },
      "subscription_item" : "si_18PMl42eZvKYlo2CGduFchWC",
      "total_usage" : "1"
   }
]

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Stripe API documentation|>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
