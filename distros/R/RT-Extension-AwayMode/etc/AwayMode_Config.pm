package RT;

=head1 NAME

AwayMode_Config - default configuration for RT::Extension::AwayMode

=head1 DESCRIPTION

Never edit this file: it ships with the extension and is overwritten on
upgrade. To change an option, copy the corresponding C<Set> line into your
F<RT_SiteConfig.pm> and edit it there. Both options are documented in
L<RT::Extension::AwayMode/CONFIGURATION>.

=over 4

=item C<$AwayModeTransactionTypes>

Arrayref of transaction types that hand a ticket off while its owner is
away. Can only narrow the C<Correspond,Comment> set the scrip condition is
registered for in F<etc/initialdata>.

=item C<$AwayModeIgnorePrivilegedComments>

When true, C<Comment> transactions created by a privileged user (a colleague
leaving an internal note, rather than a requestor whose mail arrived through
an F<rt-mailgate> running C<--action comment>) never hand the ticket off.
C<Correspond> transactions are unaffected.

=back

=cut

Set( $AwayModeTransactionTypes, [ 'Correspond', 'Comment' ] )
    unless defined $AwayModeTransactionTypes;

Set( $AwayModeIgnorePrivilegedComments, 0 )
    unless defined $AwayModeIgnorePrivilegedComments;

1;
