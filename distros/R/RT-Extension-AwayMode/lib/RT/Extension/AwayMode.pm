use v5.36;

package RT::Extension::AwayMode;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::AwayMode - Automatically hand off tickets while an owner is away

=head1 DESCRIPTION

This extension lets any user flag themselves as "away" (on holiday, out of
office, ...) on their own Preferences page, optionally scoped to a start
and/or end date. While a user's away flag is active, any new reply
(Correspond transaction) on a ticket they own causes the ticket to be
reassigned to Nobody, with an internal comment explaining why. Because
unowned tickets are visible to the whole queue/team, this ensures tickets
aren't silently stuck waiting on someone who is on holiday.

While their away flag is active, the user also sees a prominent warning
banner on every page of RT, reminding them (and anyone looking over their
shoulder) that Away Mode is on.

=head1 RT VERSION

Works with RT 6.0.3.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate scrips.

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::AwayMode');

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Users manage their own away status from Settings -> Away Mode
(F</Prefs/AwayMode.html>): a checkbox to enable away mode, and optional
start/end dates. With no dates set, away mode applies for as long as the
checkbox stays on. With dates set, away mode is only active while today
falls within the (inclusive) start/end range.

=head1 METHODS

=head2 IsAwayForPrefs

Pure logic, independent of RT, so it can be unit tested without an RT
installation. Takes the stored AwayMode preference hashref (as produced by
the F</Prefs/AwayMode.html> page: C<< { Enabled => 0|1, StartDate =>
'YYYY-MM-DD'|'', EndDate => 'YYYY-MM-DD'|'' } >>) and an optional "today" in
C<YYYY-MM-DD> form (defaults to the current local date). Returns true if
away mode is currently active for those preferences.

Both C<StartDate> and C<EndDate> are optional and, when present, are
inclusive bounds.

=cut

sub IsAwayForPrefs ( $class, $prefs, $today = undef ) {
    return 0 unless $prefs && $prefs->{'Enabled'};

    $today //= _today_iso();

    return 0 if $prefs->{'StartDate'} && $today lt $prefs->{'StartDate'};
    return 0 if $prefs->{'EndDate'}   && $today gt $prefs->{'EndDate'};

    return 1;
}

=head2 IsUserAway

Takes an C<RT::User> object, loads its C<AwayMode> preference, and returns
whether away mode is currently active for that user. Thin wrapper around
L</IsAwayForPrefs>.

=cut

sub IsUserAway ( $class, $UserObj ) {
    return 0 unless $UserObj;

    my $prefs = $UserObj->Preferences( 'AwayMode', {} );
    return $class->IsAwayForPrefs($prefs);
}

sub _today_iso () {
    my ( $mday, $mon, $year ) = ( localtime(time) )[ 3, 4, 5 ];
    return sprintf( '%04d-%02d-%02d', $year + 1900, $mon + 1, $mday );
}

=head1 AUTHOR

Christian Mehlmauer

=head1 LICENSE AND COPYRIGHT

This is free software, licensed under version 3 of the GNU General Public
License.

=cut

1;
