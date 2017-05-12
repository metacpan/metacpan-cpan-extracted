=head1 NAME

RT-OnlineDocs - Provides developer documentation in RT itself

=head1 DESCRIPTION

This extension adds a "Developer Documentation" menu to the RT user
interface.  This tool provides a browsable user interface to the RT API
documentation for the running RT instance.

=head1 INSTALLATION

This extension is works with RT 4.0.  You can also find the
documentation for your version at L<https://bestpractical.com/docs/rt/>

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RT::OnlineDocs));

or add C<RT::OnlineDocs> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

Original code by Audrey Tang.

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-OnlineDocs@rt.cpan.org|mailto:bug-RT-OnlineDocs@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-OnlineDocs>.

=head1 COPYRIGHT

This software is copyright (c) 1996-2015 by Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

use strict;
use warnings;

package RT::OnlineDocs;

require File::Basename;
require File::Find;
require File::Temp;
require File::Spec;
require Pod::Simple::HTML;

our $VERSION = "1.1";

sub lib_paths {
    my $dirname   = "$RT::BasePath/lib";
    my $localdir  =  $RT::LocalLibPath;
    my $plugindir =  $RT::LocalPluginPath;

    # We intentionally don't use the plugins API, as this also gets us
    # plugins that are not currently enabled
    my @plugins = ();
    if(opendir(PLUGINS, $plugindir)) {
        while(defined(my $plugin = readdir(PLUGINS))) {
            next if($plugin =~ /^\./);
            push(@plugins, "$plugindir/$plugin/lib");
        }
        closedir(PLUGINS);
    }

    return ($dirname, $localdir, @plugins);
}

1;
