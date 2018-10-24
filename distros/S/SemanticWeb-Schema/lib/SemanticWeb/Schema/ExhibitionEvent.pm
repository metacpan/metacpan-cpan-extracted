use utf8;

package SemanticWeb::Schema::ExhibitionEvent;

# ABSTRACT: Event type: Exhibition event, e

use Moo;

extends qw/ SemanticWeb::Schema::Event /;


use MooX::JSON_LD 'ExhibitionEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ExhibitionEvent - Event type: Exhibition event, e

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

Event type: Exhibition event, e.g. at a museum, library, archive,
tradeshow, ...

=head1 SEE ALSO

L<SemanticWeb::Schema::Event>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
