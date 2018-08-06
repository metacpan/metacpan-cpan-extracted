package SemanticWeb::Schema::UnRegisterAction;

# ABSTRACT: <p>The act of un-registering from a service

use Moo;

extends qw/ SemanticWeb::Schema::InteractAction /;


use MooX::JSON_LD 'UnRegisterAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::UnRegisterAction - <p>The act of un-registering from a service

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of un-registering from a service.</p> <p>Related actions:</p>
<ul> <li><a class="localLink"
href="http://schema.org/RegisterAction">RegisterAction</a>: antonym of
UnRegisterAction.</li> <li><a class="localLink"
href="http://schema.org/Leave">Leave</a>: Unlike LeaveAction,
UnRegisterAction implies that you are unregistering from a service you
werer previously registered, rather than leaving a team/group of
people.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::InteractAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
