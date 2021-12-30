# --
# Kernel/System/Email.pm - the global email send module
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package
    Kernel::System::Email;

use strict;
use warnings;

use Kernel::System::Crypt;
use Kernel::System::HTMLUtils;

our $VERSION = 0.01;

=head1 NAME

Kernel::System::Email - to send email

=head1 SYNOPSIS

Global module to send email via sendmail or SMTP.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

=item Send()

To send an email without already created header:

    my $Sent = $SendObject->Send();

    if ($Sent) {
        print "Email sent!\n";
    }
    else {
        print "Email not sent!\n";
    }

=cut

sub Send {
    my ( $Self, %Param ) = @_;

# ---
# TestSMTP
# ---
    my $RealRecipients = $Self->{ConfigObject}->Get( 'TestSMTP::RealRecipients' ) || [];
    my $FakeRecipients = $Self->{ConfigObject}->Get( 'TestSMTP::SendTo' ) || [];

    for my $Type ( qw(To Cc) ) {
        next if !$Param{$Type};
        my @Addresses = split /;/, $Param{$Type};
        my %Recipients;

        for my $Address ( @Addresses ) {
            if( !grep{ $Address =~ /\Q$_\E/ }@{$RealRecipients} ) {
                for my $Fake ( @{$FakeRecipients} ) {
                    $Recipients{$Fake} = 1;
                }
            }
            else {
                $Recipients{$Address} = 1;
            }
        }

        $Param{$Type} = join '; ', keys %Recipients;
    }
# ---

    return 1
}

=item Check()

Check mail configuration

    my %Check = $SendObject->Check();

=cut

sub Check {
    my ( $Self, %Param ) = @_;

    return ( Successful => 0, Message => $Check{Message} );
}

=item Bounce()

Bounce an email

    $SendObject->Bounce();

=cut

sub Bounce {
    my ( $Self, %Param ) = @_;

    return 1
}

1;

=back

