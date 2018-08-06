package SemanticWeb::Schema::DanceGroup;

# ABSTRACT: A dance group&#x2014;for example

use Moo;

extends qw/ SemanticWeb::Schema::PerformingGroup /;


use MooX::JSON_LD 'DanceGroup';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DanceGroup - A dance group&#x2014;for example

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A dance group&#x2014;for example, the Alvin Ailey Dance Theater or
Riverdance.

=head1 SEE ALSO

L<SemanticWeb::Schema::PerformingGroup>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
