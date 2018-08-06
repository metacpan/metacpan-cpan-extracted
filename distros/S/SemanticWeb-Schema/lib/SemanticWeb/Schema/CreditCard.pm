package SemanticWeb::Schema::CreditCard;

# ABSTRACT: <p>A card payment method of a particular brand or name

use Moo;

extends qw/ SemanticWeb::Schema::PaymentCard SemanticWeb::Schema::LoanOrCredit /;


use MooX::JSON_LD 'CreditCard';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CreditCard - <p>A card payment method of a particular brand or name

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>A card payment method of a particular brand or name. Used to mark up a
particular payment method and/or the financial product/service that
supplies the card account.</p> <p>Commonly used values:</p> <ul>
<li>http://purl.org/goodrelations/v1#AmericanExpress</li>
<li>http://purl.org/goodrelations/v1#DinersClub</li>
<li>http://purl.org/goodrelations/v1#Discover</li>
<li>http://purl.org/goodrelations/v1#JCB</li>
<li>http://purl.org/goodrelations/v1#MasterCard</li>
<li>http://purl.org/goodrelations/v1#VISA</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::LoanOrCredit>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
