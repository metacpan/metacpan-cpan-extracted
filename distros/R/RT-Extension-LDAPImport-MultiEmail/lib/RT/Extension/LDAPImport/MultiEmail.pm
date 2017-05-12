use strict;
use warnings;
package RT::Extension::LDAPImport::MultiEmail;

our $VERSION = '0.04';

{
    no warnings 'redefine';
    require RT::Extension::LDAPImport;
    package RT::Extension::LDAPImport;
    sub new { return bless {}, 'RT::Extension::LDAPImport::MultiEmail'; }
}

use base 'RT::Extension::LDAPImport';

sub _import_user {
    my $self = shift;
    my %args = @_;
    my $user = $self->SUPER::_import_user(@_);
    return unless $user;

    my $secondary_attrs = RT->Config->Get('LDAPMultiEmail');
    return unless $secondary_attrs;
    $secondary_attrs = [ $secondary_attrs ] unless ref $secondary_attrs;

    $self->{seen}{$user->id}++;

    my $ldap = $args{ldap_entry};
    my $uid   = $ldap->get_value('uid');
    my $email = $ldap->get_value('mail');

    my %original_secondary;
    my @secondary;
    for my $attr (@{$secondary_attrs}) {
        $original_secondary{$attr} = [ $ldap->get_value($attr) ];
        push @secondary, map {[$attr, $_]} grep {/\S/ and $_ ne $email} @{$original_secondary{$attr}};
    }
    my(@users, @merge);
    for my $val (@secondary) {
        my ($attrname, $address) = @{$val};
        my ($parsed) = Email::Address->parse($address);
        unless ($parsed) {
            $self->_debug("Skipping alternate address $address in $attrname of $email, as it is invalid");
            next;
        }

        # Disable user merging's overrides whilst we look up/update the
        # secondary users
        no warnings 'redefine';
        local *RT::User::LoadByCols = \&RT::User::LoadOriginal;
        local *RT::User::CanonicalizeEmailAddress = sub { return $_[1] };

        # Check that the alternate address isn't merged into anyone else already
        my $alt = RT::User->new( RT->SystemUser );
        $alt->LoadByEmail( $address );
        if ($alt->id) {
            my ($effective_id) = $alt->Attributes->Named("EffectiveId");
            if ($effective_id and $user->id != $effective_id->Content) {
                my $other = RT::User->new( RT->SystemUser );
                $other->Load( $effective_id->Content );
                $self->_warn($user->EmailAddress." lists $address".
                             " in $attrname as a secondary, which is already merged into ".
                             $other->EmailAddress
                         );
                next;
            }
        }

        # Pretend we found a record with that email as the primary; note
        # this only changes our local values on this object, not the
        # values in the remote LDAP store.
        $ldap->replace( uid  => $address );
        $ldap->replace( mail => $address );
        $ldap->replace( $_ => [] ) for @{$secondary_attrs};

        # Even if we were told to "only update", we should be able to
        # create aliases to merge in.
        local $RT::LDAPUpdateUsers = $RT::LDAPUpdateOnly;
        local $RT::LDAPUpdateOnly  = 0;

        # Build and import the secondary user
        my $data = $self->_build_user_object( ldap_entry => $ldap );
        $alt = $self->_import_user(
            user       => $data,
            ldap_entry => $ldap,
            import     => $args{import},
        );
        next unless $alt;

        # If it's already merged, do nothing
        my ($effective_id) = $alt->Attributes->Named("EffectiveId");
        push @merge, $alt unless $effective_id;
        push @users, $alt;
    }

    # We do this in a separate loop so that the locals (above) are out
    # of scope, and the standard MergeUsers code is in-place, as it
    # expects
    $_->MergeInto($user) for @merge;

    # Unmerge anyone who we didn't see
    my %merged = map {+($_->id => 1)} @users;
    for my $id (grep {not $merged{$_}} @{$user->GetMergedUsers->Content}) {
        my $alt = RT::User->new( RT->SystemUser );
        $alt->LoadOriginal( id => $id );
        my ($effective_id) = $alt->Attributes->Named("EffectiveId");
        next unless $effective_id->Creator == RT->SystemUser->id;
        $alt->UnMerge;
    }

    # Put the old values back, to be safe; we expect $ldap to go out of
    # scope shortly without being used again, but better safe than sorry.
    $ldap->replace( uid  => $uid );
    $ldap->replace( mail => $email );
    $ldap->replace( $_ => $original_secondary{$_} ) for @{$secondary_attrs};

    return $user;
}

=head1 NAME

RT-Extension-LDAPImport-MultiEmail - Import users with multiple email addresses and merge them

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::LDAPImport::MultiEmail');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::LDAPImport::MultiEmail));

or add C<RT::Extension::LDAPImport::MultiEmail> to your existing C<@Plugins> line.

You will also need to specify which attribute contains "alternate" email
addresses, via:

    Set( $LDAPMultiEmail, 'alternateEmail' );

Multiple alternate email address attributes can be specified using an
array reference:

    Set( $LDAPMultiEmail, ['alternateEmail', 'homeEmail'] );

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-LDAPImport-MultiEmail@rt.cpan.org|mailto:bug-RT-Extension-LDAPImport-MultiEmail@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-LDAPImport-MultiEmail>.

=head1 COPYRIGHT

This extension is Copyright (C) 20013-2014 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
