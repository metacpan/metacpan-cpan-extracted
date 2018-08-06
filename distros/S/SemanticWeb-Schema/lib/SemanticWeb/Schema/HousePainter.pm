package SemanticWeb::Schema::HousePainter;

# ABSTRACT: A house painting service.

use Moo;

extends qw/ SemanticWeb::Schema::HomeAndConstructionBusiness /;


use MooX::JSON_LD 'HousePainter';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HousePainter - A house painting service.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A house painting service.

=head1 SEE ALSO

L<SemanticWeb::Schema::HomeAndConstructionBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
