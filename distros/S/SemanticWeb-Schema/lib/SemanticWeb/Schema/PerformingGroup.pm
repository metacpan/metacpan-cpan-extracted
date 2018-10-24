use utf8;

package SemanticWeb::Schema::PerformingGroup;

# ABSTRACT: A performance group

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'PerformingGroup';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PerformingGroup - A performance group

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A performance group, such as a band, an orchestra, or a circus.

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
