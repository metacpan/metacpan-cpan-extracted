use utf8;

package SemanticWeb::Schema::CheckOutAction;

# ABSTRACT: The act of an agent communicating (service provider

use Moo;

extends qw/ SemanticWeb::Schema::CommunicateAction /;


use MooX::JSON_LD 'CheckOutAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CheckOutAction - The act of an agent communicating (service provider

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html The act of an agent communicating (service provider, social media, etc)
their departure of a previously reserved service (e.g. flight check in) or
place (e.g. hotel).<br/><br/> Related actions:<br/><br/> <ul> <li><a
class="localLink" href="http://schema.org/CheckInAction">CheckInAction</a>:
The antonym of CheckOutAction.</li> <li><a class="localLink"
href="http://schema.org/DepartAction">DepartAction</a>: Unlike
DepartAction, CheckOutAction implies that the agent is informing/confirming
the end of a previously reserved service.</li> <li><a class="localLink"
href="http://schema.org/CancelAction">CancelAction</a>: Unlike
CancelAction, CheckOutAction implies that the agent is informing/confirming
the end of a previously reserved service.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::CommunicateAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
