package Net::Radio::oFono::MessageWaiting;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::MessageWaiting - provide MessageWaiting interface for Modem objects

=cut

our $VERSION = '0.001';

use Net::DBus qw(:typing);

use base qw(Net::Radio::oFono::Modem);

=head1 SYNOPSIS

  my $oFono = Net::Location::oFono->new();
  my @modems = Net::Location::oFono->get_modems();
  foreach my $modem_path (@modems) {
    my $msgwait = Net::Location::oFono->get_modem_interface($modem_path, "MessageWaiting");
    say "VoicemailWaiting: ", 0+$msgwait->GetProperty("VoicemailWaiting"), # boolean
        "VoicemailMessageCount: ", 0+$msgwait->GetProperty("VoicemailMessageCount"), # byte
        "VoicemailMailboxNumber: ", $msgwait->GetProperty("VoicemailMailboxNumber"); # string
  }

=head1 INHERITANCE

  Net::Radio::oFono::MessageWaiting
  ISA Net::Radio::oFono::Modem
    ISA Net::Radio::oFono::Helpers::EventMgr
    DOES Net::Radio::oFono::Roles::RemoteObj
    DOES Net::Radio::oFono::Roles::Properties

=head1 METHODS

No new ones.

See C<ofono/doc/message-waiting.txt> for valid properties and detailed
action description and possible errors.

=cut

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-radio-ofono at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radio-oFono>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::oFono

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radio-oFono>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radio-oFono>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radio-oFono>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radio-oFono/>

=back

=head2 Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

=head2 Business support and maintenance

For business support you can contact Jens via his CPAN email
address rehsackATcpan.org. Please keep in mind that business
support is neither available for free nor are you eligible to
receive any support based on the license distributed with this
package.

=head1 ACKNOWLEDGEMENTS

At first the guys from the oFono-Team shall be named: Marcel Holtmann and
Denis Kenzior, the maintainers and all the people named in ofono/AUTHORS.
Without their effort, there would no need for a Net::Radio::oFono module.

Further, Peter "ribasushi" Rabbitson helped a lot by providing hints
and support how to make this API accessor a valuable CPAN module.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
