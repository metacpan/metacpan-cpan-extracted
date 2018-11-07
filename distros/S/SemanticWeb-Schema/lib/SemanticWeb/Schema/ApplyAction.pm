use utf8;

package SemanticWeb::Schema::ApplyAction;

# ABSTRACT: The act of registering to an organization/service without the guarantee to receive it

use Moo;

extends qw/ SemanticWeb::Schema::OrganizeAction /;


use MooX::JSON_LD 'ApplyAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ApplyAction - The act of registering to an organization/service without the guarantee to receive it

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html The act of registering to an organization/service without the guarantee to
receive it.<br/><br/> Related actions:<br/><br/> <ul> <li><a
class="localLink"
href="http://schema.org/RegisterAction">RegisterAction</a>: Unlike
RegisterAction, ApplyAction has no guarantees that the application will be
accepted.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::OrganizeAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
