package RT::Extension::GroupBroadcast;

use 5.006;
use strict;
use warnings;

=head1 NAME

RT::Extension::GroupBroadcast - send email to groups

=cut

our $VERSION = '0.1.4';

=head1 SYNOPSIS

Broadcast Messages via Email to existing RT groups.
This RT extension enables the sending of bulk email to a predefined RT group.

    https://rt.example.com/Admin/GroupBroadcast.html


=head1 INSTALL

    perl Makefile.PL
    make
    make install

    # Enable this plugin in your RT_SiteConfig.pm:
    Set(@Plugins, (qw/RT::Extension::GroupBroadcast/) );


=head1 SUPPORT

Please report any bugs at either:
L<http://search.cpan.org/dist/RT-Extension-GroupBroadcast/>
L<https://github.com/coffeemonster/rt-extension-groupbroadcast>
    

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alister West, C<< <alister at alisterwest.com> >>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 CHANGES

0.1.4   2013-10-29
    - js.validate 'From' as email type
    - Bugfix: Cc/Bcc address should be ',' seperated (not ';')
    - test-send-email.pl, test-send-group.pl added to scripts
    - added to Menu under Admin/Tools

0.1.3   2012-10-10
    - Fixed typo in install instructions

0.1.2   2012-08-24
    - Moved repo to github.
    - Updated docs.
    - Enable PodToReadme

0.1.1   2012-08-23
    - Mason template to send email to groups (alister).

=cut


1;
__END__
