use utf8;

package SemanticWeb::Schema::Embassy;

# ABSTRACT: An embassy.

use Moo;

extends qw/ SemanticWeb::Schema::GovernmentBuilding /;


use MooX::JSON_LD 'Embassy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Embassy - An embassy.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

An embassy.

=head1 SEE ALSO

L<SemanticWeb::Schema::GovernmentBuilding>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
