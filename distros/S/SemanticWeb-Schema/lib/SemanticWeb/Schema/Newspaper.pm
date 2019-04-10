use utf8;

package SemanticWeb::Schema::Newspaper;

# ABSTRACT: A publication containing information about varied topics that are pertinent to general information

use Moo;

extends qw/ SemanticWeb::Schema::Periodical /;


use MooX::JSON_LD 'Newspaper';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Newspaper - A publication containing information about varied topics that are pertinent to general information

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A publication containing information about varied topics that are pertinent
to general information, a geographic area, or a specific subject matter
(i.e. business, culture, education). Often published daily.

=head1 SEE ALSO

L<SemanticWeb::Schema::Periodical>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
