package Net::SMTP::Bulk;

use 5.006;
use strict;
use warnings FATAL => 'all';

#use Encode;
#use Coro;
#use Coro::Handle;
#use AnyEvent::Socket;


=head1 NAME

Net::SMTP::Bulk - NonBlocking batch SMTP using Net::SMTP interface

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';



=head1 SYNOPSIS

This is a rewrite of Net::SMTP using AnyEvent and Coro as a backbone. It supports AUTH, SSL and STARTTLS as well. This module can be used as a drop in replacement for Net::SMTP. At this point this module is EXPIREMENTAL, so use at your own risk. Functionality can change at any time.

=head1 IMPORTANT

Before you start using this module, it is important to understand the fundementals behind it. Now I know it is tempting to skip this part but I assure you that reading this is crucial to using this module. I will try to keep it short.

First of all, let me get this out of the way, this module contains 2 methods of implementation. Method 1: Coro+AnyEvent and Method 2: AnyEvent only. These methods somewhat accomplish the same thing but bahave completely different and were created for different purposes.

=head2 METHOD 1: Coro+AnyEvent

This method was created first, it was used on a server with little ram while trying to send millions of emails. How it works is you have a server+thread queue, once the queue fills up or quit command is called, it sends the emails.

The email sending process is in order, which means it will call the MAIL FROM, RCPT TO and etc commands for all emails in the batch at the same time. If 1 email fails in a batch, it is thrown out of the batch and it is up to you to figure out how to handle it through the Callbacks. It is possible for a single command to mess up the entire batch though.

Other differences: SSL/STARTTLS handshake is negotiated by a workaround

    use Net::SMTP::Bulk::Coro;

    my $smtp = Net::SMTP::Bulk::Coro->new($server, %options);

=head2 METHOD 2: AnyEvent only

After I got new servers with far more ram, I wanted to prioritize speed. So I created this module, it works quite different than the Coro one and is faster but is most likely more memory intensive.

How it works is, you send all the emails to the module and once the quit command is called, all emails are processed on a first come first serve basis.

This means if you have a million emails, all those million emails are going into ram.

Other differences: SSL/STARTTLS handshake is negotiated AnyEvent::TLS 

    use Net::SMTP::Bulk::AnyEvent;

    my $smtp = Net::SMTP::Bulk::AnyEvent->new($server, %options);

=head2 Which Method should you use?

The answer 9/10 times, METHOD 2: AnyEvent only. Why? Because I am using it. While I will go back and try to keep Method 1 up to date when I have time, Method 2 will get far more love since I am using it. If you really plan to use Method 1 and you need some function implemented to keep up with Method 2, please file it in the bug reports on CPAN. And I will prioritize it. But again, only when I have the time.

If your worry about using Method 2 comes down to ram, there are workarounds such as having it send in batches of say 1000. And while I can make Method 2 work like Method 1 fully, at this point I have no plan to. So if you are constrained by ram, try dividing up the emails in 1000 at a time for Method 2. If that doesn't work, Method 1 is your way point.

Both Methods should work for the most part. Just again, Method 2 will see more love at this point.


=head1 SYNTEX
    
See Net::SMTP and methods below for syntax.
    
=head1 SUBROUTINES/METHODS

=head2 new($server,%options)

=head2 new(%options)

Options:
Host - Hostname or IP address

Port - The port to which to connect to on the server (default: 25)

Hello - The domain name you wish to connect to (default: [same as server])

Debug - Debug information (0-10 depending on level. Higher level contains all lower levels) (default: 0, 0 - disabled, 5 - summary, 7 - hangs/fails, 8 - passes, 10 - full details) OPTIONAL

DebugPath - Set to default Debug Path. use [HOST] and [THREAD] for deeper control of output. Dates can also be appended via [YYYY] = year, [MM] = month, [DD] = day, [WK] = week, [hh] = hour, [mm] = minute OPTIONAL

Secure - If you wish to use a secure connection. ( default: 0, 0 - None, 1 - SSL [no verify], 2 - SSL [verify], 3 - STARTTLS [no verify], 4 - STARTTLS [verify]) OPTIONAL [Requires Net::SSLeay]

Threads - How many concurrent connections per host (default: 2) OPTIONAL

Encode - Encode socket( 1: utf8 )

Timeout - Amount of seconds until it gives up on the session and attempts to reconnect ( defaukt: 60  ) OPTIONAL

Hosts - An ARRAY containing a list of HASH reference of Hosts OPTIONAL

GlobalTimeout - (Method 2 only) Amount of seconds for no activity on any thread. If no activity is seen on any thread, it will reconnect on all threads. Keep in mind the delays you plan to use for Sleep and Retry. ( default: 120 ) OPTIONAL

Sleep - (Method 2 only) A HASH that sets a sleep timer in seconds for reconnect attempts. ( Default: Hang=>0, Fail => 0 ) CAVEAT: Since a timer is used the last second is not reliable, so if you set a timer of 30 seconds, it can be anywhere between 29-30 seconds. OPTIONAL

Retry - (Method 2 only) Amount of retries until it gives up. ( default: Hang=>1, GlobalHang => 1, Fail => 5 ) Put 0 for unlimited. OPTIONAL

Auth - (Method 2 only) An ARRAY containing AUTH details. ( eg. ['AUTO','user','pass'] or to force a mechanism such as LOGIN ['LOGIN','user','pass'] ) OPTIONAL

Callbacks - You can supply callback functions on certain conditions, these conditions include: OPTIONAL

Pipeline - (Method 2 only) Use pipelining for even quicker sending, makse sure server accepts pipelining. Pipelining should offer a good speed boost but may lead to more complex debugging, especially in mode 2 ( default: 0, 0 - Disabled with 4 round trips [normal], 1 - Pipelining with 2 roundtrips [faster], 2 - Pipelining with 1 roundtrip [fastest] ) OPTIONAL

Method1:
connect_pass,connect_fail,auth_pass,auth_fail,reconnect_pass,reconnect_fail,pass,fail,hang

The callback must return 1 it to follow proper proceedures. You can overwrite the defaults by supplying a different return.

1 - Default

101 - Remove Thread permanently

102 - Remove thread temporarily and reconnect at end of batch

103 - Remove thread temporarily and restart at end of batch (If your using an SMTP server with short timeout, it is suggested to use this over reconnect)

104 - Remove Thread temporarily

202 - Reconnect now

203 - Restart now

Method2:
connect_pass - connected to server

pass - Email was accepted by server

fail - This triggers if some sort of error happens, be it server did not recognize command or failed to connect. (I will most likely move fail to connect later on to connect_fail)

hang - timeout has been reached for sending to email to user, email not sent

global_hang - timeout has been reached for entire email sening operation

read - callback on every line read

The callback must return 1 it to follow proper proceedures. Other callback responses will be implemented later.

1 - Default

=head2 new(%options, Hosts=>[\%options2,\%options3])

You can supply multiple hosts in an array.


=head2 auth( [ MECHANISM,] USERNAME, PASSWORD  )

*Requires Authen::SASL

=head2 mail( ADDRESS )

=head2 to( ADDRESS )

=head2 data()

=head2 datasend( DATA )

=head2 dataend( DATA )

=head2 reconnect(  )

=head2 quit( [ID] )

*ID is Method2 only and is an optional field. It helps you track the ID through debugging. It defaults to epoch time if not passed.

=head1 CAVEATS

Other then the Caveats described above, it should he noted that there are missing functions for full SMTP compatibility.

Missing fuctions include: HELO(EHLO is used), TURN, ATURN, SIZE, ETRN, CHUNKING/BDAT, DSN, RSET, VRFY, HELP

These functions will be added as time goes on. If you need a certain function to have priority, request it .
=cut

sub new {
    my $class=shift;
    my %new=@_;
    my $self={};

    if (($new{Mode}||'') eq 'AnyEvent') {
        require Net::SMTP::Bulk::AnyEvent;    
        $self=Net::SMTP::Bulk::AnyEvent->new(@_);    
    } else {
        if (eval { require Net::SMTP::Bulk::Coro; 1 }) {
            $self=Net::SMTP::Bulk::Coro->new(@_);
        } else {
            require Net::SMTP::Bulk::AnyEvent; 
            $self=Net::SMTP::Bulk::AnyEvent->new(@_);
        }
    
        
    }
    
    

    return $self;
}


#########################################################################


=head1 AUTHOR

KnowZero

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-smtp-bulk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMTP-Bulk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMTP::Bulk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMTP-Bulk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMTP-Bulk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMTP-Bulk>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMTP-Bulk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 KnowZero.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Net::SMTP::Bulk
