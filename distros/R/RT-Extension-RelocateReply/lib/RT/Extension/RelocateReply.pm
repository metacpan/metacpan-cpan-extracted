use strict;
use warnings;
use Data::Dumper;
package RT::Extension::RelocateReply;

our $VERSION = '1.00';


'RT::Queue'->AddRight( Admin => RelocateReply => "Relocate comments or correspondances of a ticket");

=head1 NAME

RT::Extension::RelocateReply - relocate missplaced messages to the right ticket

=head1 DESCRIPTION

This extension for RT gives the ability to those who have the 
C<RelocateReply> right to relocate / move messages (comments or 
	correspondences) from one ticket to another. The relocation action
appears in both ticket's history width the current date. There will be
message at the original place stating the transaction transition.

=head1 RT VERSION

Works with RT 4.4.

=head1 INSTALLATION


	sudo perl Makefile.PL

	make

	make install	

    Add this line:

        Plugin('RT::Extension::RelocateReply');

    enable Read/Write rights for the rt user in the destination directory /usr/local/share/request-tracker4/plugins/RT-Extension-RelocateReply

    = Clear your mason cache

        rm -rf /opt/rt4/var/mason_data/obj

    = Restart your webserver


=back
=head1 AUTHOR

	Fazekas Bálint, Mithrandir kft. fazekas.balint@mithrandir.hu

	Attila Kadar, Mithrandir Ltd. E<lt>attila.kadar@mithrandir.huE<gt>
=head1 BUGS
All bugs should be reported to the above address.
=head1 LICENSE
This is free software, licensed under:
  The GNU General Public License, Version 2, June 1991
=cut

1;

