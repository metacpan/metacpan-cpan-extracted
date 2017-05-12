package SMS::Send::Clickatell;

use warnings;
use strict;

=head1 NAME

SMS::Send::Clickatell - SMS::Send Clickatell Driver

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS
    
  # Create a testing sender
  my $send = SMS::Send->new( 'Clickatell' );
  
  # Send a message
  $send->send_sms(
  	text => 'Hi there',
  	to   => '+447700900999',
  	);

=head1 DESCRIPTION

SMS::Send::Clickatel is a very bare-bones driver for L<SMS::Send> for
the SMS gateway at www.clickatell.com. It currently supports only the
most basic of functionality required by the author so he could use
SMS::Send.

If you need more functionality, patches welcome.

=head1 AUTHOR

Brian McCauley, C<< <nobull at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sms-send-clickatell at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-Clickatell>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::Clickatell


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-Clickatell>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-Clickatell>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-Clickatell>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-Clickatell>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Brian McCauley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

use base 'SMS::Send::Driver';
use HTTP::Request::Common qw(POST);
#use Data::Dumper;

require LWP::UserAgent;

our $http_protocol;

#####################################################################
# Constructor

sub new {
    my $class = shift;
    my %args = @_;
    my $ua = LWP::UserAgent->new;

    eval {
	require Crypt::SSLeay;
	$http_protocol = 'https';
    } unless $http_protocol;
    

    # Create the object
    my $self = bless {
	ua => $ua,
	http_protocol => ( $http_protocol ||= 'http'),
	verbose => $args{_verbose},
	messages => [],
	clickatell_account => [
	    api_id => $args{_api_id},
	    user =>  $args{_user},
	    password => $args{_password},
	    ],
    }, $class;

    $self;
}

sub send_sms {
    my $self = shift;
    my $http_protocol = $self->{http_protocol};

    my $ok;

    my %message = @_;
    my $to = $message{to};
    $to =~ s/^(\+|00)// or 
	die "SMS::Send should have ensured we had an international number";
    $to =~ tr/ ()//d;
    my $req = POST "$http_protocol://api.clickatell.com/http/sendmsg",
    [ %{ { 
	@{ $self->{clickatell_account}},
	to => $to,
	# Allow up to 3 SMS message fragments to be used
	concat => 3,
	text => $message{text},
	$message{_from} ? (from => $message{_from}) : (),
	} } ];
    
    for ( 1,2 ) {
	my $res = $self->{ua}->request($req);
	
	if ( $self->{verbose} ) {
	    print "Status: ",$res->status_line,"\n";
	    print $res->headers_as_string,"\n",$res->content,"\n";
	}
	
	$ok = $res->is_success;
	
	# Retry proxy errors since the UHB proxy seems to generate a few
	# isolated errors at random.
	last unless $res->code == 502;
    }
    $ok;
}

1; # End of SMS::Send::Clickatell
