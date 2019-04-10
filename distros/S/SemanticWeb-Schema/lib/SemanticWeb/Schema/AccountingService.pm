use utf8;

package SemanticWeb::Schema::AccountingService;

# ABSTRACT: Accountancy business

use Moo;

extends qw/ SemanticWeb::Schema::FinancialService /;


use MooX::JSON_LD 'AccountingService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AccountingService - Accountancy business

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html Accountancy business.<br/><br/> As a <a class="localLink"
href="http://schema.org/LocalBusiness">LocalBusiness</a> it can be
described as a <a class="localLink"
href="http://schema.org/provider">provider</a> of one or more <a
class="localLink" href="http://schema.org/Service">Service</a>(s).

=head1 SEE ALSO

L<SemanticWeb::Schema::FinancialService>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
