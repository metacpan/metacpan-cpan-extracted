package RTFM::Extension::ArticleTemplates;

our $VERSION = '0.05';

use 5.8.3;
use strict;
use warnings;


=head1 NAME

RTFM::Extension::ArticleTemplates - turns articles into dynamic templates.

=head1 DESCRIPTION

This extension works with RT 3.8 and RTFM. If you are using RT 4.0
please see L<RT::Extension::ArticleTemplates>.

When this extension is installed RTFM parses content of articles as
a template using L<Text::Template> module. Using this extension you can
make your articles dynamic. L<Text::Template> module is used to parse
RT's Templates as well and its syntax is pretty simple - you can consult
RT docs/wiki or module's documentation.

=head1 VERY IMPORTANT

It's a B<SECURITY RISK> to install this extension on systems where
articles can be changed by not trusted users. You're warned!

Your articles may contain some text that looks like a template and
will be parsed after installation when it's actually is not valid
template.

=head1 INSTALLATION

This extension requires RTFM 2.2.2.

=over

=item perl Makefile.PL

=item make

=item make install

May need root permissions

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RTFM::Extension::ArticleTemplates));

or add C<RTFM::Extension::ArticleTemplates> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Kevin Falcone E<lt>falcone@bestpractical.comE<gt>
Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008,2012 Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of version 2 of the GNU General Public License.

=cut

1;
