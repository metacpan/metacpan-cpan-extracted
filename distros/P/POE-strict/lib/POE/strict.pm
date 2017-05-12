package POE::strict;

use warnings;
use strict;

use vars qw($VERSION);

$VERSION = '3.01';

# Assert when dispatching events to nonexistent sessions
sub POE::Kernel::ASSERT_EVENTS () { 1 }

# Assert if internal parameters are wacky
sub POE::Kernel::ASSERT_USAGE () { 1 }

# Bitch about receiving unknown events
sub POE::Session::ASSERT_STATES () { 1 }


use POE::Kernel;
use POE::Session;
use POE;


sub import {
	my @orig_args = @_;

	my @args;
	foreach my $arg (@orig_args) {
		push @args, $arg unless $arg eq __PACKAGE__;
	}

	my $caller = (caller())[0];
	eval "package $caller; use POE qw(@args);";
}

1;
__END__

=pod

=head1 NAME

POE::strict - strict mode for POE

=head1 DESCRIPTION

L<POE::strict> acts a lot like the L<strict> pragma in perl. It activates
internal constraints that are not normally active. The runtime behavior of
L<POE> will be a lot more strict (duh) and potentially very loud if your code
is in any way questionable as far as the L<POE> core is concerned. 

This module can be used as if it were L<POE> itself. Suggested usage is the 
removal of all instances of C<use POE> and replacing those with 
C<use POE::strict>. 

For example,

  use POE::strict qw(Component::Client::TCP);

behaves exactly like

  use POE qw(Component::Client::TCP);

(Yeah, yeah, the former is not as semantically nice as the latter. Blame
C<#poe>. They thought the functionality was a bonus and I agreed.)

The list of activated asserts is as follows:

=over

=item POE::Kernel::ASSERT_EVENTS

Assert when dispatching events to nonexistent sessions

=item POE::Kernel::ASSERT_USAGE

Assert if internal parameters are wacky

=item POE::Session::ASSERT_STATES

Yell about receiving unknown events

=back

=head1 CAVEATS

The constants defined by this module MUST be loaded before POE is. So if
some other module calls C<use POE> before POE::strict gets compiled, all
is for naught. You'll probably get some nice redefine warnings and no
strictness. At some point, these constants will be turned into something
a little more runtime friendly. Until then, make sure POE::strict is
what loads up POE.

=head1 AUTHOR

Matt Cashner (sungo@pobox.com)

=head1 LICENSE

Copyright (c) 2004, Matt Cashner. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

=over 4

=item * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

=item * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=item * Neither the name of the Matt Cashner nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# sungo // vim: ts=4 sw=4 noet
