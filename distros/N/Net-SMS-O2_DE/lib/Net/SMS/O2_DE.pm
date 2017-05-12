package Net::SMS::O2_DE;

use 5.006;
use strict;
use warnings;

use Carp;
use Net::SMS::Web;
use Time::Local;
use Date::Format;
use POSIX qw(ceil);

=head1 NAME

Net::SMS::O2_DE - a module to send SMS messages using the O2 Germany web2sms!
It's working for Internet-Pack users. They have normally 50 free sms each month.
Maybe it is working also for other users. Please tell me if it's working with you
and you aren't a Internet-Pack user.

=head1 VERSION

Version: 0.07
Date:    24.07.2011

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

        use strict;
        use Net::SMS::O2_DE;
        
        my $sms = Net::SMS::O2_DE->new(
            autotruncate => 1,
            username => '01701234567',
            password => 'SECRET',
            sender => 'YourMother',
            recipient => '+4917676543210',
            message => 'a test message',
        );
        
        $sms->verbose( 1 );
        $sms->login();
        print "Quota: " , $sms->quota(). "\n";
        $sms->message( 'a different message' );
        print "sending message to mobile number ", $sms->recipient();
        $sms->send_sms();
        $sms->logout();

=head1 WARNING

If you don't have any free sms left, sending SMS may cost you money!!

So check, if your quota is high enough to send the desired sms.
Use the function C<sms_count> to determine how much sms will be sent
with the current settings.

Keep in mind that if you have sheduled sms, they arent yet included in the C<quota>.
Eg: If you send now, with quota=10 a scheduled sms which will be sent each hour for
the next 3 hours, quota will be decreased to 9 after the first sms is sent.
An hour later to 8, another hour later to 7. So the quota will not be immideately 7.
		
If you have scheduled a sms with C<schedule_start> and C<frequency> but no end date is set
there will be send an infinite amount of sms. This this is in most cases undesired.
So remind to set C<schedule_start> AND C<schedule_end> 

Use C<sms_count> to check, if you send an infinite number of sms.

		
=head1 DESCRIPTION



A perl module to send SMS messages, using the O2 web2sms gateway. This
module will only work with mobile phone numbers that have been registered with
O2 (L<http://www.o2.de/>) and uses form submission to a URL that may be
subject to change. The O2 service is currently only available to german
phone users with internet pack.

There is a maximum length for SMS message (1800 for O2). If the sum
of message length exceed this, the behaviour of the
Net::SMS::O2_DE objects depends on the value of the 'autotruncate' argument to
the constructor. If this is a true value, then the subject / message will be
truncated to 1800 characters. If false, the object will throw an exception
(die). If you set notruncate to 1, then the module won't check the message
length, and you are on your own!

This implementation is based on the module L<Net::SMS::O2>.

The HTTP requests are sent using L<Net::SMS::WEB> which uses L<LWP::UserAgent> module. If you are using a
proxy, you may need to set the HTTP_PROXY environment variable for this to
work (see L<LWP::UserAgent>).

=head1 TODO

There is no check if you entered a valid tel number or frequency or other fields.

=cut	

#------------------------------------------------------------------------------
#
# Package globals
#
#------------------------------------------------------------------------------

use vars qw(
    @ISA
    $URL_PRELOGIN
    $URL_LOGIN
    $URL_SMSCENTER
    $URL_PRESEND
    $URL_SEND
    $URL_SCHEDULE
    $URL_LOGOUT
    %REQUIRED_KEYS 
    %LEGAL_KEYS 
    $MAX_CHARS
    $SINGLE_CHARS
);

@ISA = qw( Net::SMS::Web );

$URL_PRELOGIN = 'https://login.o2online.de/loginRegistration/loginAction.do?_flowId=login&o2_type=asp&o2_label=login/comcenter-login&scheme=http&port=80&server=email.o2online.de&url=%2Fssomanager.osp%3FAPIID%3DAUTH-WEBSSO%26TargetApp%3D%2Fsmscenter_new.osp%253f%26o2_type%3Durl%26o2_label%3Dweb2sms-o2online';
$URL_LOGIN = 'https://login.o2online.de/loginRegistration/loginAction.do';
$URL_SMSCENTER = 'http://email.o2online.de:80/ssomanager.osp?APIID=AUTH-WEBSSO&TargetApp=/smscenter_new.osp?&o2_type=url&o2_label=web2sms-o2online';
$URL_PRESEND = 'https://email.o2online.de/smscenter_new.osp?Autocompletion=1&MsgContentID=-1';
$URL_SEND = 'https://email.o2online.de/smscenter_send.osp';
$URL_SCHEDULE = 'https://email.o2online.de/smscenter_schedule.osp';
$URL_LOGOUT = 'https://login.o2online.de/loginRegistration/loginAction.do?_flowId=logout';


%REQUIRED_KEYS = (
    username => 1,
    password => 1,
);

%LEGAL_KEYS = (
    username => 1,
    password => 1,
	sender => 1,
	anonymous => 1,
    recipient => 1,
    message => 1,
    verbose => 1,
    audit_trail => 1,
	flash_sms => 1,
	frequency => 1,
	schedule_start => 1,
	schedule_end => 1,
);

$MAX_CHARS = 1800;
$SINGLE_CHARS = 160;




=head1 SUBROUTINES/METHODS

=cut

=head2 CONSTRUCTOR Parameters

The constructor for Net::SMS::O2_DE takes the following arguments as hash
values (see L<SYNOPSIS|"SYNOPSIS">):

=head3 autotruncate (OPTIONAL)

O2 has a upper limit on the length of the message (1800). If
autotruncate is true, message is truncated to 1800 if the sum of
the length exceeds 1800. The default for this is false.

=head3 notruncate (OPTIONAL)

Of course, if you don't believe the O2 web interface about maximum character
length, then you can set this option.

=head3 username (REQUIRED)

The O2 username for the user (assuming that the user is already registered
at L<http://www.o2.de/>. Normally your phone number (eg. 017801234567)

=head3 password (REQUIRED)

The O2 password for the user (assuming that the user is already registered
at L<http://www.o2.de/>.

=head3 sender (OPTIONAL)

The sender of the sms. You can set a string value which the recipient sees as sender.
Defaults to undefined which means your number is set as sender or if anonymous is set
the message is sent by anonymous.

=head3 anonymous (OPTIONAL)

If anonymous is set and sender is undef the sms will be sent as anonymous

=head3 recipient (REQUIRED)

Mobile number for the intended SMS recipient. Format must be international (eg. +4917801234567)

=head3 message (REQUIRED)

SMS message body.

=head3 verbose (OPTIONAL)

If true, various soothing messages are sent to STDERR. Defaults to false.

=head3 flash_sms (OPTIONAL)

If true uses FlashSMS. Defaults to undef which means FlashSMS is off.

=head3 schedule_start (OPTIONAL)

If you want to schedule the sms set the parameter C<frequency> to desired value.
This is the start time using epoch time of the scheduling. The value is given
in seconds from epoch (eg. use time function).
ATTENTION: Must be multiple of 900 sekonds (=15 minutes). if not the value will
be round up internally to the next quarter of the hour.

Example:
If C<schedule_start> is set to the time value which represents in localtime:

20.07.2011 20:05:12 it will be round up to 20.07.2011 20:15:00

So the first sms is sent at 20:15:00

=head3 schedule_end (OPTIONAL)

If you want to schedule the sms set the parameter C<frequency> to desired value.
This is the end time using epoch time of the scheduling. The value is given
in seconds from epoch (eg. use time function).
ATTENTION: Must be multiple of 900 sekonds (=15 minutes). if not the value will
be round up internally to the next quarter of the hour.

Example:
If C<schedule_end> is set to the time value which represents in localtime:

20.07.2011 21:05:12 it will be round up to 20.07.2011 21:15:00

So the last sms is sent at exactly 21:15:00

=head3 frequency (OPTIONAL)

Frequency for scheduled sms. Use one of the following values (default is 5):

        5 : only once
        6 : hourly
        1 : dayly
        2 : weekly
        3 : monthly
        4 : each year

Don't forget to set schedule_end otherwise there you may not be able to stop the
sms sending.


=cut

=head2 new
The constructor. For parameter explanation see CONSTRUCTOR parameters
=cut

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->_init( @_ );
    return $self;
}


#------------------------------------------------------------------------------
#
# AUTOLOAD - to set / get object attributes
#
#------------------------------------------------------------------------------

=head2 AUTOLOAD

All of the constructor arguments can be got / set using accessor methods. E.g.:

        $old_message = $self->message;
        $self->message( $new_message );

=cut

sub AUTOLOAD
{
    my $self = shift;
    my $value = shift;

    use vars qw( $AUTOLOAD );
    my $key = $AUTOLOAD;
    $key =~ s/.*:://;
    return if $key eq 'DESTROY';
    croak ref($self), ": unknown method $AUTOLOAD\n" 
        unless $LEGAL_KEYS{ $key }
    ;
    if ( defined( $value ) )
    {
        $self->{$key} = $value;
    }
    return $self->{$key};
}

=head2 get_flow_execution_key

Calls the page to get the FlowExecutionKey for handling login and sending sms.
Called by login.

=cut

sub get_flow_execution_key
{
    my($self) = @_;

    $self->action( Net::SMS::Web::Action->new(
        url     => $URL_PRELOGIN, 
        method  => 'POST',
        params  => {
            username => $self->{username},
            password => $self->{password},
        }
    ) );
	
    if ( $self->response() =~ m{<input type="hidden" name="_flowExecutionKey" value="(_[-\w]+)" />} )
    {
        return $1;
    }
    croak "Can't load FlowExecutionKey";
}

=head2 login

Logs in with specified username and password. Calls get_flow_execution_key
which is required for the whole communication.
After login changes from the login page to the SMS-Center page to set cookies properly.

If already login was already called and not yet logout, this function returns
immediatly because assumes that you are already logged in.
If you want to force a new login, call logout first.

=cut

sub login
{
    my($self) = @_;

    return if $self->{is_logged_in};
	
    $self->action( Net::SMS::Web::Action->new(
        url     => $URL_LOGIN, 
        method  => 'POST',
        params  => {
            '_flowExecutionKey' => $self->get_flow_execution_key(),
            'loginName' => $self->{username},
            'password' => $self->{password},
			'_eventId' => 'login'
        }
    ) );

	if ($self->response() =~ m{<td class="errTxt" colspan="3"><ul><li>(.*)</li></ul></td>})
	{
		croak "Login ERROR: " .$1;
	}
	
	#Change to sms center to initialize server communication
	
    $self->action( Net::SMS::Web::Action->new(
        url     => $URL_SMSCENTER, 
        method  => 'POST'
    ) );

    $self->{is_logged_in} = 1;
}



=head2 logout

Logs you out from the current session. Use login to relogon.
There can be a parameter with '1' to force logging out

=cut
sub logout
{
    my($self) = shift;
	my $force = shift;

	unless ($force)
	{
		return if (!$self->{is_logged_in});
	}
	
    $self->action( Net::SMS::Web::Action->new(
        url     => $URL_LOGOUT, 
        method  => 'POST'
    ) );

	$self->{is_logged_in} = 0;
	
	#if ($self->response =~ m/Logout erfolgreich!/)
	#{
	#    $self->{is_logged_in} = 0;
	#	return 1;
	#}
	#croak "Logout wasn't successful. Maybe the HTML-Code has changed. Please report a bug.";
	
}

=head2 sms_count

Returns the number of needed SMS to send with current settings.
Eg: If your message contains 200 characters, it will you cost
2 sms because 1 sms can hold only 160 chars. So this function will return 2.

If you scheduled the sms for eg. each hour in the next three hours,
this function will return 3.

Combining of long messages and scheduling will also be calculated correctly.

If you have scheduled a sms but no end date there will be send an infinite mount
of sms so this function returns -1 for infinite

=cut

sub sms_count
{
    my($self) = @_;
	my $count_by_text = ceil(length($self->{message})/$SINGLE_CHARS);
	if ($count_by_text <=0)
	{
		$count_by_text = 1;
	}
	
	my $count_by_schedule = 1;
	if ($self->{schedule_start} || $self->{frequency} || $self->{schedule_end})
	{
		#if one of these is set, all must be set, otherwise ther is an infinite number of sms
		unless ($self->{schedule_start} && $self->{frequency} && $self->{schedule_end})
		{
			return -1; #infinite
		}
		if ($self->{frequency} != 5) #more than once
		{
			
			my $sched_start = $self->{schedule_start};
			my $sched_end = $self->{schedule_end};
			#round up to next full quarter hour
			$sched_start += (15*60)-($sched_start%(15*60));
			$sched_end += (15*60)-($sched_end%(15*60));
			my $schedule_duration = $sched_end - $sched_start; #in seconds
			if ($self->{frequency} == 6)
			{ #hourly
					$count_by_schedule = int($schedule_duration  / (60*60))+1;
			}
			elsif ($self->{frequency} ==  1)
			{ #dayly
					$count_by_schedule = int($schedule_duration / (24*60*60))+1;
			}
			elsif ($self->{frequency} ==  2)
			{ #weekly
					$count_by_schedule = int($schedule_duration / (7*24*60*60))+1;
			}
			elsif ($self->{frequency} ==  3)
			{ #monthly
					$count_by_schedule = int($schedule_duration / (31*24*60*60))+1;
			}
			elsif ($self->{frequency} ==  4)
			{ #each year
					$count_by_schedule = int($schedule_duration / (365*24*60*60))+1;
			}
			if ($count_by_schedule < 1) #if division floor to null
			{
				$count_by_schedule = 1;
			}
		}
	}
	
	return $count_by_text*$count_by_schedule;
}

=head2 quota

Returns the current available free sms.

=cut

sub quota
{
    my($self) = @_;
    $self->login( );
    $self->action( Net::SMS::Web::Action->new(
        url     => $URL_PRESEND,
        method  => 'POST',
    ) );

	#Get all hidden form fields needed to send them back to the server
	if ($self->response() =~ m{"frmSMS"(.*?)tr>}ms)
	{
		my @hiddenFieldsArea = $1;
		
		my %hash = ($hiddenFieldsArea[0] =~ m{<input type="hidden" name="([^"]*)" value="([^"]*)">}ig);
		if (%hash)
		{
			$self->{hiddenFields} = \%hash;
		}
		else
		{
			croak "Can't parse hidden fields. Maybe the HTML-Code has changed. Please report a bug.";
		}
	} else {
		croak "Can't parse hidden fields area. Maybe the HTML-Code has changed. Please report a bug.";
	}
	
    if ( $self->response() =~ m{<strong>Frei-SMS: ([\d]+) Web2SMS noch in diesem Monat mit Ihrem Internet-Pack inklusive!</strong>} )
    {
        return $1;
    }
    croak "Can't determine quota. Maybe the HTML-Code has changed. Please report a bug.";
}



=head2 send_sms

This method is invoked to actually send the SMS message that corresponds to the
constructor arguments an set member variables.
Returns 1 on success. Otherwise croak will be called with the error message.
Login will be automatically performed if not yet called.
You have to call logout manually if you want to close the current session.

=cut

sub send_sms
{
    my $self = shift;

    $self->login( );
	
	#Needed to load hidden form fields
    $self->quota( );
	
	
	 #TODO: Add check for valid SMSto, smsfrom, frequency, end date if frequency set
	
	my $params = {
            'SMSTo' => $self->{recipient},
			'SMSText' => $self->{message},
        };
		
	#Add hidden fields to params
	my %hidden = %{$self->{hiddenFields}};
	while ( my ($key, $value) = each(%hidden) ) {
		$params->{$key} = $value;
	}	
		
	if ($self->{sender})
	{
		$params->{'SMSFrom'} = $self->{sender};
		$params->{'FlagAnonymous'} = '0';
		$params->{'FlagDefSender'} = '1';
	} else {
		if ($self->{anonymous})
		{
			print "\n --anon-- \n";
			#Anonymous sender
			$params->{'FlagAnonymous'} = '1';
		} else {
			print "\n --NUMBER-- \n";
			#Use login number as sender (default)
			$params->{'SMSFrom'} = '';
			$params->{'FlagAnonymous'} = '0';
			$params->{'FlagDefSender'} = '1';
		}
	}
	
	if ($self->{flash_sms})
	{
		$params->{'FlagFlash'} = '1';
	} else {
		$params->{'FlagFlash'} = '0';
	}
	
	if ($self->{frequency})
	{
		$params->{'Frequency'} = $self->{frequency};
	} else {
		$params->{'Frequency'} = '5';
	}
	
	my $url = $URL_SEND;
	
	#If no schedule time set, set it to now because it is needed
	my $sched_start = $self->{schedule_start};
	my $sched_end = $self->{schedule_end};
	
	if ($sched_start)
	{
		$sched_start += (15*60)-($sched_start%(15*60));
		#sched end should be set
		unless ($sched_end)
		{
			$sched_end = $sched_start;
		}
		$url = $URL_SCHEDULE;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($sched_start);
		$params->{'StartDateDay'} = $mday;
		$params->{'StartDateMonth'} = $mon+1;
		$params->{'StartDateYear'} = $year+1900;
		$params->{'StartDateHour'} = $hour;
		$params->{'StartDateMin'} = $min;
		$params->{'RepeatStartDate'} = time2str("%Y,%m,%d,%H,%M,00",$sched_start);
		if ($sched_end)
		{
			$sched_end += (15*60)-($sched_end%(15*60));
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($sched_end);
			$params->{'EndDateDay'} = $mday;
			$params->{'EndDateMonth'} = $mon+1;
			$params->{'EndDateYear'} = $year+1900;
			$params->{'EndDateHour'} = $hour;
			$params->{'EndDateMin'} = $min;
			$params->{'RepeatEndDate'} = time2str("%Y,%m,%d,%H,%M,00",$sched_end);
			$params->{'RepeatEndType'} = '1';
		} else {
			$params->{'RepeatEndType'} = '0';
		}
		$params->{'RepeatType'} = $params->{'Frequency'};
	}
	
    $self->action( 
		Net::SMS::Web::Action->new(
			url => $url,
			method  => 'POST',
			params  => $params
		)
	);
	
    if ( $self->response =~ m/Ihre SMS wurde erfolgreich versendet./ or $self->response =~ m/Ihre Web2SMS ist geplant/)
    {
        return 1;
    }
	
    croak "Coudln't send sms.";
}

sub _check_length
{
    my $self = shift;
    $self->{message_length} = 0;
    if ( $self->{autotruncate} )
    {
        # Chop the message down the the correct length.
        $self->{message} = substr $self->{message}, 0, $MAX_CHARS;
        $self->{message_length} += length $self->{$_} for qw/message/;
    }
    elsif ( ! $self->{notruncate} )
    {
        $self->{message_length} = length( $self->{message} );
        if ( $self->{message_length} > $MAX_CHARS )
        {
            croak ref($self), 
                ": total message length is too long ",
                "(> $MAX_CHARS)\n"
            ;
        }
    }
}

sub _init
{
    my $self = shift;
    my %keys = @_;

    for ( keys %REQUIRED_KEYS )
    {
        croak ref($self), ": $_ field is required\n" unless $keys{$_};
    }
    for ( keys %keys )
    {
        $self->{$_} = $keys{$_};
    }
    $self->_check_length();
}

=head1 SEE ALSO

L<Net::SMS::Web>.
L<Net::SMS::O2>.

=head1 AUTHOR

Stefan Profanter, C<< <profanter@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sms-o2_de at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-O2_DE>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::O2_DE


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-O2_DE>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMS-O2_DE>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMS-O2_DE>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMS-O2_DE/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Profanter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::SMS::O2_DE
