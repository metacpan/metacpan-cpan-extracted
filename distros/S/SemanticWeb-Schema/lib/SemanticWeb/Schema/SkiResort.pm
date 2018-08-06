package SemanticWeb::Schema::SkiResort;

# ABSTRACT: A ski resort.

use Moo;

extends qw/ SemanticWeb::Schema::SportsActivityLocation /;


use MooX::JSON_LD 'SkiResort';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SkiResort - A ski resort.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A ski resort.

=head1 SEE ALSO

L<SemanticWeb::Schema::SportsActivityLocation>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
