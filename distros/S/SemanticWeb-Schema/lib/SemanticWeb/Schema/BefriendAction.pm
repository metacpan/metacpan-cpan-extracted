use utf8;

package SemanticWeb::Schema::BefriendAction;

# ABSTRACT: The act of forming a personal connection with someone (object) mutually/bidirectionally/symmetrically

use Moo;

extends qw/ SemanticWeb::Schema::InteractAction /;


use MooX::JSON_LD 'BefriendAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BefriendAction - The act of forming a personal connection with someone (object) mutually/bidirectionally/symmetrically

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html The act of forming a personal connection with someone (object)
mutually/bidirectionally/symmetrically.<br/><br/> Related
actions:<br/><br/> <ul> <li><a class="localLink"
href="http://schema.org/FollowAction">FollowAction</a>: Unlike
FollowAction, BefriendAction implies that the connection is
reciprocal.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::InteractAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
