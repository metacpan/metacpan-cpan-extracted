use utf8;

package SemanticWeb::Schema::DisagreeAction;

# ABSTRACT: The act of expressing a difference of opinion with the object

use Moo;

extends qw/ SemanticWeb::Schema::ReactAction /;


use MooX::JSON_LD 'DisagreeAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DisagreeAction - The act of expressing a difference of opinion with the object

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of expressing a difference of opinion with the object. An agent
disagrees to/about an object (a proposition, topic or theme) with
participants.

=head1 SEE ALSO

L<SemanticWeb::Schema::ReactAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
