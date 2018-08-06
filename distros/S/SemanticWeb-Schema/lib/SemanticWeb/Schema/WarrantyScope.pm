package SemanticWeb::Schema::WarrantyScope;

# ABSTRACT: <p>A range of of services that will be provided to a customer free of charge in case of a defect or malfunction of a product

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'WarrantyScope';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WarrantyScope - <p>A range of of services that will be provided to a customer free of charge in case of a defect or malfunction of a product

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>A range of of services that will be provided to a customer free of
charge in case of a defect or malfunction of a product.</p> <p>Commonly
used values:</p> <ul>
<li>http://purl.org/goodrelations/v1#Labor-BringIn</li>
<li>http://purl.org/goodrelations/v1#PartsAndLabor-BringIn</li>
<li>http://purl.org/goodrelations/v1#PartsAndLabor-PickUp</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
