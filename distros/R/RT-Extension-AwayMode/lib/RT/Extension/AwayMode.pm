use v5.36;

package RT::Extension::AwayMode;

our $VERSION = '0.04';

# Transaction types that hand a ticket off when its owner is away. Must stay a
# subset of the ApplicableTransTypes the scrip condition is registered with in
# etc/initialdata, since RT filters on that before the condition ever runs.
our @DEFAULT_TRANSACTION_TYPES = ( 'Correspond', 'Comment' );

=head1 NAME

RT::Extension::AwayMode - Automatically hand off tickets while an owner is away

=head1 DESCRIPTION

This extension lets any user flag themselves as "away" (on holiday, out of
office, ...) on their own Preferences page, optionally scoped to a start
and/or end date. While a user's away flag is active, any new reply
(C<Correspond> transaction) or comment (C<Comment> transaction) from someone
else on a ticket they own causes the ticket to be reassigned to Nobody, with
an internal comment explaining why. Because unowned tickets are visible to
the whole queue/team, this ensures tickets aren't silently stuck waiting on
someone who is on holiday.

Comments count because F<rt-mailgate> can be run with C<--action comment>,
in which case incoming mail is recorded as a comment rather than as
correspondence. Which transaction types trigger a handoff, and whether
comments written by privileged users are exempt, is configurable; see
L</CONFIGURATION>.

Replies written by the away owner themselves don't trigger the handoff: if
they are answering the ticket, they are clearly still working on it, so it
stays assigned to them.

While their away flag is active, the user also sees a prominent warning
banner on every page of RT, reminding them (and anyone looking over their
shoulder) that Away Mode is on.

Users who left on holiday without setting the flag themselves aren't stuck:
an administrator can set (or clear) away mode on anyone's behalf from that
user's admin page.

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

=head1 UPGRADING

Upgrading from a version before 0.03 needs one manual database change: the
scrip condition installed by C<make initdb> was registered for C<Correspond>
transactions only, and RT filters on that column before the condition code
ever runs, so a code-only upgrade would never see comments. Re-running
C<make initdb> is B<not> the way to fix this: it would install a second copy
of the scrip. Instead, widen the existing condition once (and bring its
description in line with what it now does):

    perl -I /opt/rt6/local/lib -I /opt/rt6/lib -e '
        use RT; RT::LoadConfig(); RT::Init();
        my $cond = RT::ScripCondition->new( RT->SystemUser );
        $cond->Load("Owner Away");
        die "no such scrip condition\n" unless $cond->Id;
        my ($ok, $msg) = $cond->SetApplicableTransTypes("Correspond,Comment");
        die "$msg\n" unless $ok;
        ($ok, $msg) = $cond->SetDescription(
            "Whenever a reply or comment arrives on a ticket whose owner has Away Mode active");
        die "$msg\n" unless $ok;
    '

The description is cosmetic -- it is what the admin UI shows for the
condition -- so only the C<SetApplicableTransTypes> call actually changes
behaviour.

Fresh installs need nothing extra; C<make initdb> already registers both
transaction types.

=head1 CONFIGURATION

Users manage their own away status from Settings -> Away Mode
(F</Prefs/AwayMode.html>): a checkbox to enable away mode, and optional
start/end dates. With no dates set, away mode applies for as long as the
checkbox stays on. With dates set, away mode is only active while today
falls within the (inclusive) start/end range.

Administrators can do the same for any other user from Admin -> Users ->
(select a user) -> Settings -> Away Mode (F</Admin/Users/AwayMode.html>),
which is useful when somebody leaves without setting the flag themselves.
That page requires the C<AdminUsers> right (on top of the C<ShowConfigTab>
right RT already requires for the whole F</Admin/> area) and writes exactly
the same preference the self-service page does, so the two stay
interchangeable.

Two site options control which transactions hand a ticket off. Their
defaults live in F<etc/AwayMode_Config.pm>; to change one, copy it into your
F<RT_SiteConfig.pm> and edit it there.

=over

=item C<$AwayModeTransactionTypes>

    Set( $AwayModeTransactionTypes, ['Correspond'] );

Arrayref of transaction types that trigger the handoff. Defaults to
C<['Correspond', 'Comment']>. Set it to C<['Correspond']> to get the
pre-0.03 behaviour of ignoring comments entirely.

This can only B<narrow> the C<Correspond,Comment> set the scrip condition is
registered for in F<etc/initialdata>; naming any other transaction type here
has no effect, because RT filters on the registered types before the
condition runs.

=item C<$AwayModeIgnorePrivilegedComments>

    Set( $AwayModeIgnorePrivilegedComments, 1 );

Off by default. When on, C<Comment> transactions created by a privileged
user (i.e. a colleague leaving an internal note, rather than a requestor
whose mail arrived through an F<rt-mailgate> running C<--action comment>)
never hand the ticket off. C<Correspond> transactions are unaffected.

Turn this on if your F<rt-mailgate> records incoming mail as correspondence
and you only want comment handling for the rare unprivileged commenter.
Leave it off if F<rt-mailgate> runs with C<--action comment> and your
requestors may themselves be privileged users, since then their incoming
mail would be exempted too.

=back

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

=head2 IsHandledTransactionType

Pure logic, independent of RT, so it can be unit tested without an RT
installation. Takes a transaction type (C<Correspond>, C<Comment>, ...) and
optionally the configured list of handled types, either as an arrayref or as
a single string; when omitted, C<@DEFAULT_TRANSACTION_TYPES> is used.
Returns true if that type should hand an away owner's ticket off. Type
comparison is case insensitive.

=cut

sub IsHandledTransactionType ( $class, $type, $types = undef ) {
    return 0 unless defined $type && length $type;

    $types = [@DEFAULT_TRANSACTION_TYPES] unless defined $types;
    $types = [$types]                     unless ref $types eq 'ARRAY';

    return ( grep { defined $_ && lc($_) eq lc($type) } @$types ) ? 1 : 0;
}

=head2 IsHandledTransaction

Takes an C<RT::Transaction> object and returns whether it should hand an away
owner's ticket off, honouring the C<$AwayModeTransactionTypes> and
C<$AwayModeIgnorePrivilegedComments> config options (see L</CONFIGURATION>).
Thin wrapper around L</IsHandledTransactionType>.

=cut

sub IsHandledTransaction ( $class, $TxnObj ) {
    return 0 unless $TxnObj;

    my $type  = $TxnObj->Type;
    my $types = scalar RT->Config->Get('AwayModeTransactionTypes');
    return 0 unless $class->IsHandledTransactionType( $type, $types );

    return 1 unless lc $type eq 'comment';
    return 1 unless RT->Config->Get('AwayModeIgnorePrivilegedComments');

    my $creator = $TxnObj->CreatorObj;
    return 0 if $creator && $creator->Id && $creator->Privileged;

    return 1;
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
