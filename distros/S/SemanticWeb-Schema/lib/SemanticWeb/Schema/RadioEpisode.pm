use utf8;

package SemanticWeb::Schema::RadioEpisode;

# ABSTRACT: A radio episode which can be part of a series or season.

use Moo;

extends qw/ SemanticWeb::Schema::Episode /;


use MooX::JSON_LD 'RadioEpisode';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RadioEpisode - A radio episode which can be part of a series or season.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A radio episode which can be part of a series or season.

=head1 SEE ALSO

L<SemanticWeb::Schema::Episode>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
