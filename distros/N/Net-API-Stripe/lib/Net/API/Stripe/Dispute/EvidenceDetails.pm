##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Dispute/EvidenceDetails.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
package Net::API::Stripe::Dispute::EvidenceDetails;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub due_by { return( shift->_set_get_datetime( 'due_by', @_ ) ); }

sub has_evidence { return( shift->_set_get_boolean( 'has_evidence', @_ ) ); }

sub past_due { return( shift->_set_get_boolean( 'past_due', @_ ) ); }

sub submission_count { return( shift->_set_get_scalar( 'submission_count', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Dispute::EvidenceDetails - Dispute Evidence Details Object

=head1 SYNOPSIS

    my $detail = $dispute->evidence_details({
        due_by => '2020-04-12',
        has_evidence => $stripe->true,
        past_due => '2020-05-01',
        submission_count => 2,
    });

=head1 VERSION

    v0.100.0

=head1 DESCRIPTION

This is instantiated by method B<evidence_details> from module L<Net::API::Stripe::Dispute>

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Dispute::EvidenceDetails> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 due_by timestamp

Date by which evidence must be submitted in order to successfully challenge dispute. Will be null if the customer’s bank or credit card company doesn’t allow a response for this particular dispute.

=head2 has_evidence boolean

Whether evidence has been staged for this dispute.

=head2 past_due boolean

Whether the last evidence submission was submitted past the due date. Defaults to false if no evidence submissions have occurred. If true, then delivery of the latest evidence is not guaranteed.

=head2 submission_count integer

The number of times evidence has been submitted. Typically, you may only submit evidence once.

=head1 API SAMPLE

    {
      "object": "balance",
      "available": [
        {
          "amount": 0,
          "currency": "jpy",
          "source_types": {
            "card": 0
          }
        }
      ],
      "connect_reserved": [
        {
          "amount": 0,
          "currency": "jpy"
        }
      ],
      "livemode": false,
      "pending": [
        {
          "amount": 7712,
          "currency": "jpy",
          "source_types": {
            "card": 7712
          }
        }
      ]
    }

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/disputes/object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

