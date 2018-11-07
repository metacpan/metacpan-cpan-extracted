use utf8;

package SemanticWeb::Schema::OnDemandEvent;

# ABSTRACT: A publication event e

use Moo;

extends qw/ SemanticWeb::Schema::PublicationEvent /;


use MooX::JSON_LD 'OnDemandEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OnDemandEvent - A publication event e

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A publication event e.g. catch-up TV or radio podcast, during which a
program is available on-demand.

=head1 SEE ALSO

L<SemanticWeb::Schema::PublicationEvent>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
