use utf8;

package SemanticWeb::Schema::TheaterGroup;

# ABSTRACT: A theater group or company

use Moo;

extends qw/ SemanticWeb::Schema::PerformingGroup /;


use MooX::JSON_LD 'TheaterGroup';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TheaterGroup - A theater group or company

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A theater group or company, for example, the Royal Shakespeare Company or
Druid Theatre.

=head1 SEE ALSO

L<SemanticWeb::Schema::PerformingGroup>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
