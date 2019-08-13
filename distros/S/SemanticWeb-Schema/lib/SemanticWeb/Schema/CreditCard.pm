use utf8;

package SemanticWeb::Schema::CreditCard;

# ABSTRACT: A card payment method of a particular brand or name

use Moo;

extends qw/ SemanticWeb::Schema::LoanOrCredit SemanticWeb::Schema::PaymentCard /;


use MooX::JSON_LD 'CreditCard';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';


has monthly_minimum_repayment_amount => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'monthlyMinimumRepaymentAmount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CreditCard - A card payment method of a particular brand or name

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html A card payment method of a particular brand or name. Used to mark up a
particular payment method and/or the financial product/service that
supplies the card account.<br/><br/> Commonly used values:<br/><br/> <ul>
<li>http://purl.org/goodrelations/v1#AmericanExpress</li>
<li>http://purl.org/goodrelations/v1#DinersClub</li>
<li>http://purl.org/goodrelations/v1#Discover</li>
<li>http://purl.org/goodrelations/v1#JCB</li>
<li>http://purl.org/goodrelations/v1#MasterCard</li>
<li>http://purl.org/goodrelations/v1#VISA</li> </ul> 

=head1 ATTRIBUTES

=head2 C<monthly_minimum_repayment_amount>

C<monthlyMinimumRepaymentAmount>

The minimum payment is the lowest amount of money that one is required to
pay on a credit card statement each month.

A monthly_minimum_repayment_amount should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<Num>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PaymentCard>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
