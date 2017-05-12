# $Id: DCCIf.pm,v 1.4 2004/02/11 14:36:48 matt Exp $

package Net::DCCIf;
use strict;

use IO::Socket;
use Socket qw(:crlf inet_ntoa);
use Fatal qw(open close);
use Symbol qw(gensym);

use vars qw($VERSION);

$VERSION = '0.02';

my %result_map = (
    A => 'Accept',
    R => 'Reject',
    S => 'Accept Some',
    T => 'Temporary Failure',
    );

sub new {
    my $class = shift;
    
    return bless {}, $class;
}

sub connect {
    my $self = shift;
    my %opts = @_;
    
    %$self = (); # clear out self in case its being re-used.
    
    $opts{homedir} ||= $self->{homedir} || '/var/dcc';
    
    # this slightly odd logic copied from the original dccif.pl
    if ($opts{clnt_addr}) {
        inet_aton($opts{clnt_addr}) || die "Client address lookup failed: $!";
    }
    elsif ($opts{clnt_name}) {
        $opts{clnt_addr} = inet_ntoa(scalar(gethostbyname($opts{clnt_name})))
            || die "Cannot resolve domain name $opts{clnt_name}: $!";
    }
    else {
        $opts{clnt_name} = '';
    }
    
    my $server = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => "$opts{homedir}/dccifd",
        ) || die "Socket connect failed ($opts{homedir}/dccifd): $!";
    
    $self->{server} = $server;
    $self->{homedir} = $opts{homedir};
    
    my @options;
    if ($opts{known_spam}) {
        push @options, "spam";
    }
    if ($opts{output_body}) {
        push @options, "body";
    }
    if ($opts{output_header}) {
        push @options, "header";
    }
    if ($opts{query_only}) {
        push @options, "query";
    }
    
    $self->send("opts", join(" ", @options), LF);
    
    $self->send("clnt helo env_from",
                $opts{clnt_addr}, CR, $opts{clnt_name}, LF, 
                $opts{helo}, LF,
                $opts{env_from}, LF,
                );
    
    if (!ref($opts{env_to})) {
        $opts{env_to} = $opts{env_to} ? [$opts{env_to}] : [];
    }
    
    $self->{env_to} = $opts{env_to};
    
    foreach my $env_to (@{$opts{env_to}}) {
        $self->send("env_to", $env_to, LF);
    }
    
    $self->send("end of env_tos", LF);
    
    return $self;
}

sub dcc_file {
    my ($self, $file) = @_;
    
    my $fh = gensym();
    open($fh, $file);
    
    return $self->dcc_fh($fh);
}

sub dcc_fh {
    my ($self, $fh) = @_;
    
    my $buf;
    while (1) {
        my $i = sysread($fh, $buf, 8192);
        die "sysread file handle failed: $!" unless defined($i);
        last unless $i;
        $self->send("body", $buf);
    }
    
    return $self->get_results();
}

sub send {
    my ($self, $type, @data) = @_;
    # warn("send $type:", join('', @data)) if $type ne 'body';
    $self->{server}->syswrite(join('', @data)) || die "socket write failed at $type: $!";
}

sub get_results {
    my ($self) = @_;
    
    if ($self->{results}) {
        return @{$self->{results}};
    }
    
    $self->{server}->shutdown(1) || die "socket shutdown failed: $!";
    my $result = $self->{server}->getline || die "socket read failed: $!";
    my $oks = $self->{server}->getline || die "socket read failed: $!";
    chomp($result); chomp($oks);
    
    $result = $result_map{$result};
    my @ok_map;
    foreach my $env_to (@{$self->{env_to}}) {
        my $val = substr($oks, 0, 1, '');
        push @ok_map, $env_to, $result_map{$val};
    }
    
    $self->{results} = [ $result, @ok_map ];
    return( $result, @ok_map );
}

sub get_output {
    my ($self, %opts) = @_;
    
    my $output_fh = $opts{output_fh};
    if (!$output_fh) {
        if ($opts{output_file}) {
            $output_fh = gensym();
            open($output_fh, ">" . $self->{output_file});
        }
    }
    
    my $ret = '';
    my $buf;
    while (1) {
        my $i = $self->{server}->read($buf, 8192);
        die "read socket failed: $!" unless defined($i);
        last unless $i;
        if ($output_fh) {
            print $output_fh ($buf) or die "write output filehandle failed: $!";
        }
        else {
            $ret .= $buf;
        }
    }
    
    return $ret;
}

sub disconnect {
    my $self = shift;
    delete $self->{server};
}

1;

=head1 NAME

Net::DCCIf - Interface to the DCC daemon

=head1 SYNOPSIS

  my $dcc = Net::DCCIf->new();
  $dcc->connect();
  my ($results, $oks) = $dcc->dcc_file("test.eml");
  $dcc->disconnect();

=head1 DESCRIPTION

This module is a simple interface to the Distributed Checksum Clearinghouse
daemon (dccifd). It is a simpler replacement for the F<dccif.pl> script that 
dcc ships with, making usage more perlish (though probably at the expense of
a slight performance drop).

=head1 API

The API is intentionally simple. Hopefully it allows enough flexibility to
support everything needed, however if not there may be some advantages to
sticking with F<dccif.pl> from the DCC distribution.

=head2 C<< Net::DCCIf->new() >>

This constructs a new Net::DCCIf object. It takes no options, and will always
return a valid object unless there is an out of memory error.

=head2 C<< $dcc->connect(%options) >>

Attempt to connect to the local unix domain socket. By default this domain
socket is expected to be at F</var/dcc/dccifd>, however you can override
this with the C<homedir> option. If the connection fails for any reason
then an exception will be thrown detailing the error.

Returns the object, to facilitate method chaining.

B<Options>

=over 4

=item C<< env_from => $from >>

The envelope from address (C<MAIL FROM> data).

=item C<< env_to => \@env_tos >>

The envelope to addresses as an array reference (C<RCPT TO> data).

B<< WARNING: >> if you pass an empty list here then DCC will assume
zero recipients and not increment the counter for this email (equivalent
to doing a C<< query_only >> lookup).

=item C<< helo => $helo >>

The HELO line.

=item C<< homedir => $dir >>

Specifies the location of the C<dccifd> unix domain socket.

=item C<< clnt_addr => $addr >>

Specifies the IP address of the connecting server. If this is an invalid
address then an exception will be thrown.

=item C<< clnt_name => $name >>

Specifies the host name of the connecting server. If the C<clnt_name> is
specified, but C<clnt_addr> is not, then a hostname lookup will be
performed to try and determine the IP address. If this lookup fails an
exception will be thrown.

=item C<< known_spam => 1 >>

Specifies that we already know this email is spam (i.e. it came in to
a spamtrap address) and so we let the DCC server know about it.

=item C<< output_body => 1 >>

Makes L<< get_output()|/$dcc->get_output(%options) >> return the full body of the email with
a header added to it.

=item C<< output_header => 1 >>

Makes L<< get_output()|/$dcc->get_output(%options) >> return just a header line.

=item C<< query_only => 1 >>

Issues a query only, rather than first incrementing the database and then
querying.

=back

=head2 C<< $dcc->dcc_file($filename) >>

Opens the file and calls L<< dcc_fh()|/$dcc->dcc_fh($fh) >> on the resulting filehandle.

Returns C<($result, @mappings)>. See L</Results> below.

=head2 C<< $dcc->dcc_fh($fh) >>

Sends the contents of the filehandle to the dcc server.

Returns C<($result, @mappings)>. See L</Results> below.

=head2 C<< $dcc->send($type, @data) >>

Sends raw text data to the dcc server. The type is usually one of C<"header"> or
C<"body">, and is used in error messages if there is a problem sending the
data.

Use this method B<before> any calls to C<dcc_fh> or C<dcc_file>. Using it after
may result in an error or unexpected results.

=head2 C<< $dcc->get_results() >>

Following sending the email via C<send()> you have to manually extract the
results (these are the same results as returned by C<dcc_fh()> and C<dcc_file()>
above).

=head2 C<< $dcc->get_output(%options) >>

This method returns the header or body from the dcc server that resulted from
running dcc on the data. The output depends on the values of the C<output_body>
or C<output_header> options passed in the C<connect()> call.

Returns the data as a string unless the C<output_fh> or C<output_file> options
are set.

B<Options>

=over 4

=item C<< output_fh => $fh >>

A filehandle to send the output to. If you wish the output to go to STDOUT, you can
pass it with C<< $dcc->get_output(output_fh => \*STDOUT) >>.

This option overrides any setting for C<output_file>.

=item C<< output_file => $file >>

A filename to send the output to, as with C<output_fh> above.

=back

=head2 C<< $dcc->disconnect() >>

Disconnect from the dccifd server and cleanup.

=head1 Results

The results returned from C<dcc_file>, C<dcc_fh> and C<get_results> above are a
list of values: C<($action, @mappings)>.

The C<$action> value is one of:

=over 4

=item "Accept"

=item "Reject"

=item "Reject Some"

=item "Temporary Failure"

=back

The C<@mappings> value is a list of envelope to addresses followed by the action
that should be taken for that address. It is often easier to map this to a hash:

  my ($action, %mappings) = $dcc->get_results();
  print "Action: $action\n";
  print "Matt Sergeant action: " . $mappings{'matt@sergeant.org'} . "\n";

This should only have differing values in it should the primary action be
"Reject Some", otherwise the values will all be the same as C<$action>.

Ordering of the mappings will be the same as the order of C<env_to> addresses
passed to C<connect()> above. Note that this ordering will be lost if you
map it to a hash.

=head1 Exceptions

This module throws exceptions for all errors. In order to catch these errors
without having your program exit you can use the C<eval {}> construct:

  my $dcc = Net::DCCIf->new();
  eval {
    $dcc->connect();
    my ($results, %mapping) = $dcc->dcc_file("test.eml");
    print "Results: $results\n";
    print "Recipients: $_ => $mapping{$_}\n" for keys %mapping;
  };
  if ($@) {
    warn("An error occurred in dcc: $@");
  }

=head1 BUGS

No real test suite yet, as its hard to do when testing daemons and so I
got lazy :-(

=head1 AUTHOR

Matt Sergeant <matt@sergeant.org> working for MessageLabs

=head1 LICENSE

This is free software. You may redistribute it under the same terms
as Perl itself.

Copyright 2003. All Rights Reserved.

=cut
