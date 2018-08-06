package SemanticWeb::Schema::AppendAction;

# ABSTRACT: The act of inserting at the end if an ordered collection.

use Moo;

extends qw/ SemanticWeb::Schema::InsertAction /;


use MooX::JSON_LD 'AppendAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AppendAction - The act of inserting at the end if an ordered collection.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

The act of inserting at the end if an ordered collection.

=head1 SEE ALSO

L<SemanticWeb::Schema::InsertAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
