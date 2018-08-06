package SemanticWeb::Schema::BookmarkAction;

# ABSTRACT: An agent bookmarks/flags/labels/tags/marks an object.

use Moo;

extends qw/ SemanticWeb::Schema::OrganizeAction /;


use MooX::JSON_LD 'BookmarkAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BookmarkAction - An agent bookmarks/flags/labels/tags/marks an object.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

An agent bookmarks/flags/labels/tags/marks an object.

=head1 SEE ALSO

L<SemanticWeb::Schema::OrganizeAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
