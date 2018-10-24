use utf8;

package SemanticWeb::Schema::BusinessFunction;

# ABSTRACT: The business function specifies the type of activity or access (i

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'BusinessFunction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BusinessFunction - The business function specifies the type of activity or access (i

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html The business function specifies the type of activity or access (i.e., the
bundle of rights) offered by the organization or business person through
the offer. Typical are sell, rental or lease, maintenance or repair,
manufacture / produce, recycle / dispose, engineering / construction, or
installation. Proprietary specifications of access rights are also
instances of this class.<br/><br/> Commonly used values:<br/><br/> <ul>
<li>http://purl.org/goodrelations/v1#ConstructionInstallation</li>
<li>http://purl.org/goodrelations/v1#Dispose</li>
<li>http://purl.org/goodrelations/v1#LeaseOut</li>
<li>http://purl.org/goodrelations/v1#Maintain</li>
<li>http://purl.org/goodrelations/v1#ProvideService</li>
<li>http://purl.org/goodrelations/v1#Repair</li>
<li>http://purl.org/goodrelations/v1#Sell</li>
<li>http://purl.org/goodrelations/v1#Buy</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
