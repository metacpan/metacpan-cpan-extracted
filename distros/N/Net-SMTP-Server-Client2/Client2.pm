package Net::SMTP::Server::Client2;

use 5.001;
use strict;

use vars qw($VERSION );

use Carp;
use IO::Socket;


$VERSION = '0.2';

my %_cmds = (
	    DATA => \&_data,
	    EXPN => \&_noway,
	    HELO => \&_hello,
	    HELP => \&_help,
	    MAIL => \&_mail,
	    NOOP => \&_noop,
	    QUIT => \&_quit,
	    RCPT => \&_receipt,
	    RSET => \&_reset,
	    VRFY => \&_noway
	    );

# Utility functions.
sub _put {
    print {shift->{SOCK}} @_, "\r\n";

}

sub _reset0 {
    my $self = shift;
    $self->{FROM} = undef;
    $self->{TO} = [];
    $self->{MSG} = undef;
    $self->{faults} = 0;
}

    
sub _reset {
    my $self = shift;
    $self->_reset0;
    $self->_put("250 buffahs ah cleah, suh!");
}

# New instance.
sub new {
    my($this, $sock) = @_;
    
    my $class = ref($this) || $this;
    my $self = {};
    
    bless($self, $class);
    $self->_reset0;
    $self->{SOCK} = $sock;

    croak("No client connection specified.") unless defined($self->{SOCK});
    return $self;
}

sub greet {
    
    $_[0]->_put("220 Debatable SMTP $VERSION Ready.");
}

sub basta{
	my $self = shift;
	$self -> _put("421 closing transmission channel");
        $self->{SOCK}->close;
	1;
}

# sub process {
sub get_message {
    my $self = shift;
    my($cmd, @args);
    
    my $sock = $self->{SOCK};
    $self->_reset0;
    
    while(<$sock>) {
	print "$$ command: $_";
	$$self{faults} > 15 and $self->basta and last;
	# Clean up.
	chomp;
	s/^\s+//;
	s/\s+$//;
	unless(length $_){
		++$$self{faults};
		$self->greet;
		next;
	};
	($cmd, @args) = split(/\s+/);
	
	$cmd =~ tr/a-z/A-Z/;
	
	if(!defined($_cmds{$cmd})) {
	    sleep ++$$self{faults};
	    $self->_put("500 sorry, I don't know how to $cmd");
	   next;
	};
	
	# all commands return TRUE to indicate that
	# we need to keep working to get the message.
	&{$_cmds{$cmd}}($self, \@args) or 
	    return(defined($self->{MSG}));
    }

    return undef;
}

sub find_addresses {
	# find e-mail addresses in the arguments and return them.
	# max one e-mail address per argument.
	# print "looking for addresses in <@_>\n";
	return map { /([^<|;]+\@[^>|;&,\s]+)/ ? $1 : () } @_;
};

sub okay {
	my $self = shift;
	$self -> _put("250 OK @_");
}

sub fail {
	my $self = shift;
	$self -> _put("554 @_");
}

sub too_long {
	$_[0] -> _put("552 Too much mail data");
};

sub _mail {
    my $self = $_[0];
    my @who = find_addresses(@{$_[1]});
    my $who = shift @who;
    if ($who){
	$self->{FROM} = $who;
	return $self->okay("Envelope sender set to <$who> ")
    }else{
	$self->{faults}++;
	return $self-> _put("501 could not find name\@postoffice in <@{$_[1]}>")
    };
}

sub rcpt_syntax{
	$_[0] -> _put("553 no user\@host addresses found in <@{$_[1]}>");
}

sub _receipt {
    my $self = $_[0];
    my @recipients = find_addresses(@{$_[1]});
    @recipients or return $self->rcpt_syntax($_[1]);
    push @{ $self->{TO} }, @recipients;
    $self->okay("sending to @{$self->{TO}}");
}

sub _data {
    my $self = shift;
   
    my @msg;
    
    if(!$self->{FROM}) {
	$self-> _put("503 start with 'mail from: ...'");
	$self->{faults}++;
	return 1;
    }
    
    if(!@{$self->{TO}}) {
	$self->_put("503 specify recipients with 'rcpt to: ...'");
	$self->{faults}++;
	return 1;
    }

    $self->_put("354 And what am I to tell them?");

    my $sock = $self->{SOCK};
    
    while(<$sock>) {
	print "$$ data: $_";
	if(/^\.\r*\n*$/) {
	    $self->{MSG} = join ('', @msg);
	    return 0; # please examine MSG
	}
	
	# RFC 821 compliance.
	s/^\.\./\./;
	push @msg, $_;
    }
    
    return 0; # socket died
}

sub _noway {
    shift->_put("252 Nice try.");
}

sub _noop {
    shift->_put("250 Whatever.");
}

sub _help {
    my $self = shift;
    my $i = 0;
    my $str = "214-Commands\r\n";
    my $total = keys(%_cmds);
    
    foreach(sort(keys(%_cmds))) {
	if(!($i++ % 5)) {
	    if(($total - $i) < 5) {
		$str .= "\r\n214 ";
	    } else {
		$str .= "\r\n214-";
	    }
	} else {
	    $str .= ' ';
	}
	
	$str .= $_;
    }
    
    $self->_put($str);
}

sub _quit {
    my $self = shift;
    
    $self->_put("221 Ciao");
    $self->{SOCK}->close;
    return 0;
}

sub _hello {
    shift->okay( "Welcome" );
}

1;
__END__

=head1 NAME

Net::SMTP::Server::Client2 - A better client for Net::SMTP::Server.

=head1 SYNOPSIS

        use Carp;
        use Net::SMTP::Server;
        use Net::SMTP::Server::Client2;

        my $server = new Net::SMTP::Server(localhost => 25) ||
           croak("Unable to open server : $!\n");

        while($conn = $server->accept()) {

	   fork and last;
	   $conn->close;
        };
	  
	my $count = 'aaa';
        my $client = new Net::SMTP::Server::Client2($conn) ||
               croak("Unable to handle client: $!\n");

	$client->greet; # this is new

        while($client->get_message){ # this is different

	if (length($client->{MSG}) > 1400000){
			$client->too_long; # this is new
	}else{

		if( $client->{MSG} =~ /viagra/i ){
			$client->fail(" we need no viagra "); # this is new
			next;
		};

		$count++;
		open MOUT, ">/tmp/tmpMOUT_${$}_$count" or die "open: $!";
		print MOUT  join("\n",
			$client->{FROM},
			@{$client->{TO}},
			'',
			$client-{MSG}) or die "print: $!";
		close MOUT or die "close: $!";
		link 
			"/tmp/tmpMOUT_${$}_$count",
			"/tmp/MOUT_${$}_$count"
 			or die "link: $!";
		unlink 
			"/tmp/tmpMOUT_${$}_$count"
 			or die "unlink: $!";
		$client->okay("message saved for relay"); # this is new
         }}



=head1 DESCRIPTION

The Net::SMTP::Server::Client2 module
is a patched Net::SMTP::Server::Client module.

 $client->get_message returns before delivering a response
code to the client.  $client->okay(...) and $client->too_large()
and $client->fail(...) return the appropriate codes, rather than
assuming that all messages were 250.  "Is that 250 with you?"  
$client->basta() will 421 and close, which is also an option after
receiving a message you don't want to accept.

  $client->{faults} is the number of booboos the client made while
   presenting the message, after 15 of them we 421 and close.

And, Client2 is no longer is an autoloader or an exporter because it
doesn't export anything or autoload.

=head1 AUTHOR AND COPYRIGHT

  Net::SMTP::Server::Client is Copyright(C) 1999, 
  MacGyver (aka Habeeb J. Dihu), who released
  it under the AL and GPL, so it is okay to patch and re-release it,
  even though he said "all reigths reserved."  He reserved all the
  rights, then he released it.  Go figure.

  Client2,  released by me, in 2002,  contains changes that make
  the interface more complex,  and not backwards-compatible.

  You may distribute this package under the terms of either the GNU
  General Public License or the Artistic License, as specified in the
  Perl README file. 

  David Nicol

=head1 SEE ALSO

Net::SMTP::Server, Net::SMTP::Server::Client

=cut
