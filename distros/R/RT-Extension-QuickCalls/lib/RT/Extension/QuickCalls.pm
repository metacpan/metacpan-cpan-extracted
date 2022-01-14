package RT::Extension::QuickCalls;
use warnings;
use strict;

our $VERSION = '1.03';

=head1 NAME

RT::Extension::QuickCalls - Quickly create tickets in specific queues with default values

=head1 RT VERSION

Works with RT 4.4, 5.0

=head1 SYNOPSIS

You will need to enable the new QuickCalls portlet with a line
like this in your F<RT_SiteConfig.pm> file:

    Set($HomepageComponents, [qw(QuickCreate Quicksearch MyAdminQueues MySupportQueues MyReminders
                                 RefreshHomepage QuickCalls)]);

This is the default portlet list with QuickCalls added to the end
People can then choose to add the portlet to their homepage
in Preferences -> RT at a glance

To set up your Quick Calls, you will want to specify a C<Name> and a
C<Queue> in the config file.  The C<Name> will become the C<Subject> of
the task unless you specify a C<Subject> option.  You can add other
Ticket options as needed, such as C<Status>.  Additionally, if the
C<SetOwnerToCurrentUser> option is set, the ticket will be owned by the
current user.

    Set($QuickCalls,[{Name => "Foo", Queue => 'General', Status => 'resolved'},
                     {Name => "Bar", Queue => 'Queue2',  Status => 'resolved'}]);

If a value is an anonymous subref, it will be called when the QuickCall
is selected, and its return value filled in for the appropriate key:

    Set($QuickCalls,[ {
       Queue   => 'General',
       Name    => 'This will have the current time on the server in its content',
       Content => sub {
          my $date = localtime;
          return "When: $date\n\n";
       },
    }]);

After you have added QuickCalls to your home page, you will be able to select
one, click Create and be brought to the ticket creation page with multiple
fields pre-filled.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::QuickCalls');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::QuickCalls));

or add C<RT::Extension::QuickCalls> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-QuickCalls@rt.cpan.org|mailto:bug-RT-Extension-QuickCalls@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-QuickCalls>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
