use utf8;

package SemanticWeb::Schema::RadioSeason;

# ABSTRACT: Season dedicated to radio broadcast and associated online delivery.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWorkSeason /;


use MooX::JSON_LD 'RadioSeason';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RadioSeason - Season dedicated to radio broadcast and associated online delivery.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

Season dedicated to radio broadcast and associated online delivery.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWorkSeason>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
