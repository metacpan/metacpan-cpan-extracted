use utf8;

package SemanticWeb::Schema::HomeAndConstructionBusiness;

# ABSTRACT: A construction business

use Moo;

extends qw/ SemanticWeb::Schema::LocalBusiness /;


use MooX::JSON_LD 'HomeAndConstructionBusiness';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HomeAndConstructionBusiness - A construction business

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html A construction business.<br/><br/> A HomeAndConstructionBusiness is a <a
class="localLink" href="http://schema.org/LocalBusiness">LocalBusiness</a>
that provides services around homes and buildings.<br/><br/> As a <a
class="localLink" href="http://schema.org/LocalBusiness">LocalBusiness</a>
it can be described as a <a class="localLink"
href="http://schema.org/provider">provider</a> of one or more <a
class="localLink" href="http://schema.org/Service">Service</a>(s).

=head1 SEE ALSO

L<SemanticWeb::Schema::LocalBusiness>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
