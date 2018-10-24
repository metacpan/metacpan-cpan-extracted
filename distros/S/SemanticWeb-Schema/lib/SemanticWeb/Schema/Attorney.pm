use utf8;

package SemanticWeb::Schema::Attorney;

# ABSTRACT: Professional service: Attorney

use Moo;

extends qw/ SemanticWeb::Schema::LegalService /;


use MooX::JSON_LD 'Attorney';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Attorney - Professional service: Attorney

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html Professional service: Attorney. <br/><br/> This type is deprecated - <a
class="localLink" href="http://schema.org/LegalService">LegalService</a> is
more inclusive and less ambiguous.

=head1 SEE ALSO

L<SemanticWeb::Schema::LegalService>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
