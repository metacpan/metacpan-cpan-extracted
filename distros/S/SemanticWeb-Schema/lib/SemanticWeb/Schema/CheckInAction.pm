use utf8;

package SemanticWeb::Schema::CheckInAction;

# ABSTRACT: The act of an agent communicating (service provider

use Moo;

extends qw/ SemanticWeb::Schema::CommunicateAction /;


use MooX::JSON_LD 'CheckInAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CheckInAction - The act of an agent communicating (service provider

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html The act of an agent communicating (service provider, social media, etc)
their arrival by registering/confirming for a previously reserved service
(e.g. flight check in) or at a place (e.g. hotel), possibly resulting in a
result (boarding pass, etc).<br/><br/> Related actions:<br/><br/> <ul>
<li><a class="localLink"
href="http://schema.org/CheckOutAction">CheckOutAction</a>: The antonym of
CheckInAction.</li> <li><a class="localLink"
href="http://schema.org/ArriveAction">ArriveAction</a>: Unlike
ArriveAction, CheckInAction implies that the agent is informing/confirming
the start of a previously reserved service.</li> <li><a class="localLink"
href="http://schema.org/ConfirmAction">ConfirmAction</a>: Unlike
ConfirmAction, CheckInAction implies that the agent is informing/confirming
the <em>start</em> of a previously reserved service rather than its
validity/existence.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::CommunicateAction>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
