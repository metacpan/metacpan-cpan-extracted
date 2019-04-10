use utf8;

package SemanticWeb::Schema::WorkersUnion;

# ABSTRACT: A Workers Union (also known as a Labor Union

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'WorkersUnion';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WorkersUnion - A Workers Union (also known as a Labor Union

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A Workers Union (also known as a Labor Union, Labour Union, or Trade Union)
is an organization that promotes the interests of its worker members by
collectively bargaining with management, organizing, and political
lobbying.

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
