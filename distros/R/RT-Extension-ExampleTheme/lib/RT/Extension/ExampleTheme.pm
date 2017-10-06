use strict;
use warnings;
package RT::Extension::ExampleTheme;

our $VERSION = '0.01';

# Add css files to the @CSSFiles config
RT->AddStyleSheets('example-theme.css');
RT->AddJavaScript('example-theme.js');

=head1 NAME

RT-Extension-ExampleTheme - Example Theme Extension

=head1 DESCRIPTION

RT::Extension::ExampleTheme is a small example of the customizations users can make
to change the look and feel of RT. These changes are saved as a theme for others to use.

=head1 RT VERSION

Works with RT 4.2, 4.4

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>
Add this line:

    Plugin('RT::Extension::ExampleTheme');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

To set this theme as the default RT theme (optional), add the following line to your
RT_SiteConfig.pm

    Set( $WebDefaultStylesheet, ('example-theme'));

Individual users can also select the theme they want on their preferences page.

=head1 EXAMPLE CONTENT

This extension provides some examples of ways to customize the style of RT. You can find
more information in the L<RT Style Documentation|https://docs.bestpractical.com/rt/latest/customizing/styling_rt.html>.

=head2 CSS

To change the appearance of RT, you can modify any CSS files you copy from one of RT's base
themes. In addition to copying and modifying the CSS set by RT, you can add your own and
even do things like hide parts of the RT UI. See F<static/css/example-theme.css> for an
example of hiding the "Priority" field.

=head2 Javascript

RT uses jQuery, which provides many tools to modify the RT UI via javascript. To see an example
of changing a label with jQuery, see F<static/js/example-theme.js>, which changes "The Basics" on
the ticket display page to "Ticket State". The trickiest part is often getting the selector right.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ExampleTheme@rt.cpan.org|mailto:bug-RT-Extension-ExampleTheme@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ExampleTheme>.

=head1 LICENSE AND COPYRIGHT

This extension is Copyright (c) 2017 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
