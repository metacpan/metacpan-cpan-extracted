use strict;
use warnings;

use Authen::OATH;       # Debian package: libauthen-oath-perl
use Convert::Base32;    # Debian package: libconvert-base32-perl
use Imager::QRCode;     # Debian package: libimager-qrcode-perl
use Crypt::CBC;         # Debian package: libcrypt-cbc-perl
use LWP::UserAgent;

package RT::Extension::TOTPMFA;

our $VERSION = '0.10';

=head1 NAME

RT::Extension::TOTPMFA - Multi-factor authentication with time-based one-time passcodes

=head1 DESCRIPTION

This extension allows users to add multi-factor authentication to their
account.

A secret token is stored for each user, and used for time-based one-time
passcodes (TOTP).

To enable MFA, the "About me" page is extended with a new section alongside
identity and password, for TOTP token management.  In this section, the user
may scan a QR code based on this token into their mobile device's
TOTP-compatible app, such as FreeOTP+ or Google Authenticator.  Or, they can
enrol the key for their Yubikey device on this page instead.

When an account has MFA enabled, the RT login page works as usual, but the
user is then prompted to enter a one-time passcode before they can proceed
any further.

The MFA prompt will be repeated after a configurable duration, or when a new
session begins.

If a user loses their MFA token, an administrator can switch off MFA in
their account settings on their behalf, on the user basics modification
page.

=head1 RT VERSION

Requires at least RT 5.0.1.

=head1 REQUIREMENTS

These Perl modules are required:

=over

=item *

Authen::OATH (Debian package: libauthen-oath-perl)

=item *

Convert::Base32 (Debian package: libconvert-base32-perl)

=item *

Imager::QRCode (Debian package: libimager-qrcode-perl)

=item *

Crypt::CBC (Debian package: libcrypt-cbc-perl)

=item *

LWP::UserAgent (Debian package: libwww-perl)

=back

=head1 INSTALLATION

For installation to work, you will need C<Module::Install::RTx>.

=over

=item C<RTHOME=/usr/share/request-tracker5/lib perl Makefile.PL>

Adjust I<RTHOME> to point to the directory containing B<RT.pm>.

=item C<make>

=item C<make install>

May need root permissions.

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add these lines:

    Set($TOTPMFA_Issuer, 'Request Tracker');
    Set($TOTPMFA_Period, 30);
    Set($TOTPMFA_Digits, 6);
    Plugin('RT::Extension::TOTPMFA');

See below for configuration details.

=item Restart your web server

=back

=head1 CONFIGURATION

=over 20

=item $TOTPMFA_Issuer

The issuer name used in the QR code when a user registers their secret.
This is what is shown next to the username in the user's authenticator app.
The default is "Request Tracker".

=item $TOTPMFA_Period

How many seconds a one-time passcode is valid for.  The default is 30.

=item $TOTPMFA_Digits

How many digits to use in the one-time passcodes.  The default is 6.

=back

=head1 ISSUES AND CONTRIBUTIONS

The project is held on L<Codeberg|https://codeberg.org>; its issue tracker
is at L<https://codeberg.org/ivarch/rt-extension-totpmfa/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Andrew Wood.

Contributors include:

=over

=item *

L<elacour|https://codeberg.org/elacour> - localisation support, French
translation, inline QR code display, bugfix in secret reset, and packaging
improvements.

=back

License GPLv3+: GNU GPL version 3 or later: L<https://gnu.org/licenses/gpl.html>

This is free software: you are free to change and redistribute it.  There is
NO WARRANTY, to the extent permitted by law.

=head1 INTERNAL FUNCTIONS

This section provides details of the internal functions provided by this
extension, for developers.

=cut

=head2 UserSettings $UserObj

Return a hashref containing the TOTP MFA settings for the C<RT::User> object
B<$UserObj>.

=over 10

=item Type

MFA type to use: None, TOTP (default None).

=item Duration

The re-validation interval: the number of seconds that a successful
authentication is valid for (default 1 day - 86400 seconds).

=item Secret

The OATH TOTP secret, base32 encoded (the default is an empty string).

=item Yubikey

If a Yubikey is being used, the Yubikey identifier (default is an empty
string).

=back

Default values will be returned if the user object is not valid.

=cut

sub UserSettings {
    my ($UserObj) = @_;
    my $Settings = {
        'Type'     => 'None',
        'Duration' => 86400,
        'Secret'   => '',
        'Yubikey'  => ''
    };

    return $Settings if (not $UserObj);
    return $Settings if (not $UserObj->id);

    foreach my $Key (keys %$Settings) {
        my $Attribute = $UserObj->FirstAttribute('TOTPMFA' . $Key);
        next if (not defined $Attribute);
        my $Value = $Attribute->Content;
        next if (not defined $Value);
        $Settings->{$Key} = $Value;
    }

    return $Settings;
}

=head2 UpdateUserSetting $UserObj, $Key, $Value

Change the TOTPMFA setting B<$Key> to B<$Value> for the C<RT::User> object
B<$UserObj>, returning an array (B<$OK>, B<$Message>), where B<$Message> is
an error message if B<$OK> is false.

=cut

sub UpdateUserSetting {
    my ($UserObj, $Key, $Value) = @_;
    my ($Settings, $OK, $Message);

    return (0, 'No user object provided') if (not $UserObj);
    return (0, 'No user object loaded')   if (not $UserObj->id);

    $Settings = RT::Extension::TOTPMFA::UserSettings($UserObj);

    return (0, $UserObj->loc('No TOTPMFA settings key provided'))
      if (not defined $Key);
    return (0, $UserObj->loc('Unknown TOTPMFA settings key: [_1]', $Key))
      if (not exists $Settings->{$Key});
    return (0,
        $UserObj->loc('No TOTPMFA settings value provided for key [_1]', $Key))
      if (not defined $Value);

    return (1, '') if ($Settings->{$Key} eq $Value);

    ($OK, $Message) = $UserObj->SetAttribute(
        'Name'        => 'TOTPMFA' . $Key,
        'Description' => '',
        'Content'     => $Value
    );
    return ($OK, $Message) if (not $OK);

    if ($Key eq 'Secret') {
        $UserObj->_NewTransaction(
            Type     => 'Set',
            Field    => 'TOTPMFA:' . $Key,
            OldValue => '(old secret)',
            NewValue => '(new secret)'
        );
    } else {
        $UserObj->_NewTransaction(
            Type     => 'Set',
            Field    => 'TOTPMFA:' . $Key,
            OldValue => $Settings->{$Key},
            NewValue => $Value
        );
    }

    return (1, $UserObj->loc('Updated TOTPMFA "[_1]" value.', $Key));
}

=head2 IsEnabledForUser $UserObj

Return true if MFA is enabled at all for the C<RT::User> object B<$UserObj>,
meaning that their TOTPMFA I<Type> is set to anything other than "None".

=cut

sub IsEnabledForUser {
    my ($UserObj) = @_;

    return 0 if (not defined $UserObj);
    return 0 if (not $UserObj->id);
    return 0
      if (RT::Extension::TOTPMFA::UserSettings($UserObj)->{'Type'} eq 'None');

    return 1;
}

=head2 NewSecret $UserObj

Generate and store a new TOTP MFA I<Secret> value for the C<RT::User> object
B<$UserObj>, returning (B<$OK>, B<$Message>).

=cut

sub NewSecret {
    my ($UserObj) = @_;
    my ($Settings, $NewSecret, $OK, $Message);

    return (0, 'No user object provided') if (not $UserObj);
    return (0, 'No user object loaded')   if (not $UserObj->id);

    $Settings = RT::Extension::TOTPMFA::UserSettings($UserObj);

    $NewSecret = Convert::Base32::encode_base32(Crypt::CBC->random_bytes(16));

    return RT::Extension::TOTPMFA::UpdateUserSetting($UserObj, 'Secret',
        $NewSecret);
}

=head2 SessionIsAuthenticated $Session

Return true if the session hashref B<$Session> was authenticated by MFA
within the expiry duration.

=cut

sub SessionIsAuthenticated {
    my ($Session) = @_;

    return 0 if (not defined $Session);
    return 0 if (not $Session->{'TOTPMFAValidUntil'});
    return 0 if ($Session->{'TOTPMFAValidUntil'} !~ /^[0-9]+$/);
    return 0 if ($Session->{'TOTPMFAValidUntil'} < time);

    return 1;
}

=head2 QRCode $UserObj

Return the binary data for a QR code in PNG format, suitable for scanning
into an OATH TOTP authenticator application for the C<RT::User> object
B<$UserObj>.

=cut

sub QRCode {
    my ($UserObj) = @_;
    my ($Settings);
    my ($Label, $Secret, $Issuer, $Period, $Algorithm, $Digits);
    my ($URL, $QRCode, $Image, $PNG);

    $Settings = RT::Extension::TOTPMFA::UserSettings($UserObj);

    if (length $Settings->{'Secret'} < 1) {
        RT::Extension::TOTPMFA::NewSecret($UserObj);
        $Settings = RT::Extension::TOTPMFA::UserSettings($UserObj);
    }

    $Label     = $UserObj->Name;
    $Secret    = $Settings->{'Secret'};
    $Issuer    = RT->Config->Get('TOTPMFA_Issuer')    || 'Request Tracker';
    $Period    = RT->Config->Get('TOTPMFA_Period')    || 30;
    $Algorithm = 'SHA1';	# This is the defined standard
    $Digits    = RT->Config->Get('TOTPMFA_Digits')    || 6;

    $URL =
        'otpauth://totp/'
      . $HTML::Mason::Commands::m->interp->apply_escapes($Label, 'u')
      . '?secret='
      . $HTML::Mason::Commands::m->interp->apply_escapes($Secret, 'u')
      . '&issuer='
      . $HTML::Mason::Commands::m->interp->apply_escapes($Issuer, 'u')
      . '&period='
      . $HTML::Mason::Commands::m->interp->apply_escapes($Period, 'u')
      . '&algorithm='
      . $HTML::Mason::Commands::m->interp->apply_escapes($Algorithm, 'u')
      . '&digits='
      . $HTML::Mason::Commands::m->interp->apply_escapes($Digits, 'u');

    $QRCode = Imager::QRCode->new(
        'size'          => 6,
        'margin'        => 3,
        'level'         => 'L',
        'version'       => 0,
        'mode'          => '8-bit',
        'casesensitive' => 1
    );
    $Image = $QRCode->plot($URL);

    $PNG = '';
    $Image->write('data' => \$PNG, 'type' => 'png');

    return $PNG;
}

=head2 MFALogin $Session, $OTP

Return true, and update the session to record that MFA was validated, if a
TOTP MFA form submission was received with a correct value.

=cut

sub MFALogin {
    my ($Session, $OTP) = @_;
    my ($UserObj, $Settings);
    my ($Period,  $Algorithm, $Digits);

    $UserObj  = $Session->{'CurrentUser'}->UserObj;
    $Settings = RT::Extension::TOTPMFA::UserSettings($UserObj);

    $Period    = RT->Config->Get('TOTPMFA_Period')    || 30;
    $Digits    = RT->Config->Get('TOTPMFA_Digits')    || 6;

    # Note that we ignore $Settings->{'Type'} here because we could be
    # called just to test that someone's authenticator is working, before
    # they have enabled MFA.

    if ($OTP =~ /^[0-9]+$/) {

        # Numeric passcode - OATH TOTP.

        # Can't validate if we have no stored secret.
        return (0, $UserObj->loc('No TOTP secret registered'))
          if (not defined $Settings->{'Secret'});

        # Calculate what the OTP should be.
        my $OATH = Authen::OATH->new(
            'digits'   => $Digits,
            'timestep' => $Period
        );
        my $CheckValue =
          $OATH->totp(Convert::Base32::decode_base32($Settings->{'Secret'}));

        my $MatchingOTP = 0;

        $MatchingOTP = 1 if ($CheckValue eq $OTP);

        # If it didn't match, try both an earlier and a later one.
        if (not $MatchingOTP) {
            $CheckValue =
              $OATH->totp(Convert::Base32::decode_base32($Settings->{'Secret'}),
                time - $Period);
            $MatchingOTP = 1 if ($CheckValue eq $OTP);
        }
        if (not $MatchingOTP) {
            $CheckValue =
              $OATH->totp(Convert::Base32::decode_base32($Settings->{'Secret'}),
                time + $Period);
            $MatchingOTP = 1 if ($CheckValue eq $OTP);
        }

        return (0, $UserObj->loc('One-time passcode does not match.'))
          if (not $MatchingOTP);

    } elsif ($OTP =~ /[a-z]{32}/) {

        # 32 letters - Yubikey.

        # We only want the static part of the stored Yubikey ID, so we remove
        # the last 32 alphabetic characters, which should leave us with the
        # initial 12.
        my $Yubikey = $Settings->{'Yubikey'};
        if (defined $Yubikey) {
            $Yubikey =~ s/[a-z]{32}\s*$//s;
            $Yubikey =~ s/^\s*//s;
            $Yubikey = undef if ($Yubikey !~ /[a-z]{12}/);
        }

        # Can't validate if we have no registered device.
        return (0, $UserObj->loc('No Yubikey device registered'))
          if (not defined $Yubikey);

        # The prefix must match the registered device.
        return (
            0,
            $UserObj->loc(
                'One-time passcode is not from the registered Yubikey device.')
        ) if ($OTP !~ /^\Q$Yubikey\E/);

        # Call the Yubico API to validate the passcode.

        my $NumberUsedOnce =
          Convert::Base32::encode_base32(Crypt::CBC->random_bytes(20));

        my $UserAgent = LWP::UserAgent->new;
        $UserAgent->timeout(30);

        # TODO: option to define a proxy
        # $UserAgent->proxy(...);

        my $URL =
            'https://api.yubico.com/wsapi/2.0/verify?id=1&otp='
          . $HTML::Mason::Commands::m->interp->apply_escapes($OTP, 'u')
          . '&nonce='
          . $HTML::Mason::Commands::m->interp->apply_escapes($NumberUsedOnce,
            'u');
        my $Response = $UserAgent->get($URL);

        if (not $Response) {
            return (0,
                $UserObj->loc('One-time passcode validation API call failed'));
        } elsif ($Response->is_error) {
            return (
                0,
                $UserObj->loc(
'One-time passcode validation API call failed with this error: [_1]',
                    $Response->status_line
                )
            );
        }

        my $Content = $Response->content if (defined $Response);
        $Content = '' if (not defined $Content);

        if ($Content =~ s/^.*status=([A-Z_]+).*?/$1/s) {
            return (
                0,
                $UserObj->loc(
'One-time passcode validation failed with this status response: [_1]',
                    $Content
                )
            ) if ($Content ne 'OK');
        } else {
            return (
                0,
                $UserObj->loc(
'One-time passcode validation failed with no valid status response',
                    $Content
                )
            );
        }

    } else {

        return (0,
            $UserObj->loc('One-time passcode does not match a known format.'));

    }

    $Session->{'TOTPMFAValidUntil'} = time + $Settings->{'Duration'};
    return (1, '');
}

1;
