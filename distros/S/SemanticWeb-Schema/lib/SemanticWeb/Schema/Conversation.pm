use utf8;

package SemanticWeb::Schema::Conversation;

# ABSTRACT: One or more messages between organizations or people on a particular topic

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Conversation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Conversation - One or more messages between organizations or people on a particular topic

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

One or more messages between organizations or people on a particular topic.
Individual messages can be linked to the conversation with isPartOf or
hasPart properties.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
