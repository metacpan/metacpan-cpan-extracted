use utf8;

package SemanticWeb::Schema::TakeAction;

# ABSTRACT: The act of gaining ownership of an object from an origin

use Moo;

extends qw/ SemanticWeb::Schema::TransferAction /;


use MooX::JSON_LD 'TakeAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TakeAction - The act of gaining ownership of an object from an origin

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html The act of gaining ownership of an object from an origin. Reciprocal of
GiveAction.<br/><br/> Related actions:<br/><br/> <ul> <li><a
class="localLink" href="http://schema.org/GiveAction">GiveAction</a>: The
reciprocal of TakeAction.</li> <li><a class="localLink"
href="http://schema.org/ReceiveAction">ReceiveAction</a>: Unlike
ReceiveAction, TakeAction implies that ownership has been transfered.</li>
</ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::TransferAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
