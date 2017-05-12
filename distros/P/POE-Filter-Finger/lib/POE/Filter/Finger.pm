package POE::Filter::Finger;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(POE::Filter);

$VERSION = '0.08';

#  {Q1}    ::= [{W}|{W}{S}{U}]{C}
#  {Q2}    ::= [{W}{S}][{U}]{H}{C}
#  {U}     ::= username
#  {H}     ::= @hostname | @hostname{H}
#  {W}     ::= /W
#  {S}     ::= <SP> | <SP>{S}
#  {C}     ::= <CRLF>

my $u_regex = qr{[a-z0-9.]+}i;
my $h_regex = qr{[-_a-z0-9.]+}i;

sub new {
  my $class = shift;
  my $self = {@_};
  $self->{BUFFER} = [];
  bless $self, $class;
}

sub get_one_start {
  my ($self, $raw) = @_;
  push @{ $self->{BUFFER} }, $_ for @$raw;
}

sub get_one {
  my $self = shift;
  my $events = [];

  my $query = shift @{ $self->{BUFFER} };

  return $events unless defined $query;

  my $original = $query;
  my $verbose = $query =~ s{\A/W\s*}{};
  my $user_regex = $self->{username_regex} || $u_regex;
  my $host_regex = $self->{hostname_regex} || $h_regex;

  SWITCH: {
    if ($query eq '') {
      push @$events, { listing => { verbose => $verbose } };
      last SWITCH;
    } 
    if ($query =~ /\A$user_regex\z/) {
      push @$events, { user => { username => $query, verbose => $verbose } };
      last SWITCH;
    } 
    if ($query =~ /\A($user_regex)?((?:\@$host_regex)+)\z/) {
      my ($username, $host_string) = ($1, $2);
      my @hosts = split /@/, $host_string;
      shift @hosts;

      push @$events, { forward => 
      	{  username => $username,
           hosts    => \@hosts,
           verbose  => $verbose, } 
      };
      last SWITCH;
    }
    push @$events, { unknown => $original };
  }
  
  return $events;
}

sub get_pending {
  my $self = shift;
  return $self->{BUFFER};
}

sub put {
  my ($self, $chunks) = @_;
  [ @$chunks ];
}

sub clone {
  my $self = shift;
  my $nself = { };
  $nself->{$_} = $self->{$_} for keys %{ $self };
  $nself->{BUFFER} = [ ];
  return bless $nself, ref $self;
}

'Finger meh!';
__END__

=head1 NAME

POE::Filter::Finger - A POE Filter for creating FINGER servers.

=head1 SYNOPSIS

   # A simple Fingerd using Test::POE::Server::TCP

   use strict;
   use warnings;
   use POE;
   use POE qw(Filter::Stackable Filter::Line Filter::Finger);
   use Test::POE::Server::TCP;

   POE::Session->create(
     package_states => [
        'main' => [qw(
                        _start
                        testd_client_input
        )],
     ],
   );
   
   $poe_kernel->run();
   exit 0;
   
   sub _start {
     my $heap = $_[HEAP];
     # Spawn the Test::POE::Server::TCP server.
     $heap->{testd} = Test::POE::Server::TCP->spawn(
        address => '127.0.0.1',
        port => 0,
	filter => POE::Filter::Stackable->new(
		Filters => [
			POE::Filter::Line->new(),
			POE::Filter::Finger->new(),
		],
	),
     );
     warn "Listening on port: ", $heap->{testd}->port(), "\n";
     return;
   }
   
   sub testd_client_input {
     my ($kernel,$heap,$sender,$id,$input) = @_[KERNEL,HEAP,SENDER,ARG0,ARG1];

     my $output;

     SWITCH: {
	if ( $input->{listing} ) {
	    $output = 'listing of users rejected';
	    last SWITCH;
	}
	if ( $input->{user} ) {
	    my $username = $input->{user}->{username};
	    $output = "query for information on alleged user <$username> rejected";
	    last SWITCH;
	}
	if ( $input->{forward} ) {
	    $output = 'finger forwarding service denied';
	    last SWITCH;
	}
	$output = 'could not understand query';
     }

     $kernel->post( $sender, 'send_to_client', $id, $output );

     return;
   }

=head1 DESCRIPTION

POE::Filter::Finger is a L<POE::Filter> for the FINGER protocol, RFC 1288.

It is for use on the server side and parses incoming finger requests from clients
and produces hashrefs of information relating to those requests.

The C<put> method works in much the same way as L<POE::Filter::Stream> and does
not alter any data passed back to the client.

The filter does not deal with chunking data received into lines. 
It is intended to be used in a stackable filter, L<POE::Filter::Stackable>, with L<POE::Filter::Line>.

It is based on code borrowed from L<Net::Finger::Server>.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::Finger object.

Takes two optional parameters:

  'username_regex', override the regex used to match usernames in query string;
  'hostname_regex', override the regex used to match hostnames in query string;

=back

=head1 METHODS

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

Takes an arrayref which contains lines of Finger protocol data, returns an arrayref of hashref records
dependent on what was requested:

   listing request:

   {
	'listing' => { verbose => '' }, # verbose boolean; did client request a verbose reply?
   }

   user request:

   {
        'user' => {
                        'verbose' => '', # verbose boolean; did client request a verbose reply?
                        'username' => 'bingos' # the username requested.
                  }
   }

   forward request:

   {
        'forward' => {
                        'verbose' => '', # verbose boolean; did client request a verbose reply?
                         'hosts' => [	 # an arrayref of the hosts in the query, left to right
                                        'example.org',
                                        'example.com'
                                    ],
                         'username' => 'bingos' # the user named in the query (if any)
                     }
    }

    unknown request:

    {
            'unknown' => 'this is garbage' # passed the query string
    }


=item C<get_pending>

Returns the filter's partial input buffer.

=item C<put>

Passes any given data through without altering it.

=item C<clone>

Makes a copy of the filter, and clears the copy's buffer.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

Ricardo SIGNES <rjbs@cpan.org>

=head1 LICENSE

Copyright E<copy> Chris Williams and Ricardo SIGNES

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<POE::Filter>

L<Net::Finger::Server>

