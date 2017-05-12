package PGP::FindKey; 

use strict;
use vars qw($VERSION);

$VERSION = '0.02';

use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;

sub new {
	my ($this, @args) = @_;
	my $class = shift; 
	my $self = bless { @_ }, $class;
	return $self->_init(@_);
}


sub _init {
	my($self, %params) = @_;;

	# Caller can set:
	#  \- address:		(mandatory)
	#  \- keyserver: 	(default to 'keyserver.pgp.com')
	#  \- path:		(default to '/pks/lookup')
	#  \- command:		(default to '?op=index&search=')
    
	return undef unless exists($params{address});
	$self->{keyserver} 	||= 'keyserver.pgp.com';
	$self->{path} 		||= '/pks/lookup';
	$self->{command}	||= '?op=index&search=';
	$self->{address}	||= uri_escape($params{address});

	my $query = "http://" . $self->{keyserver} . $self->{path} . $self->{command} . $self->{address};

	my $ua = LWP::UserAgent->new();
	
	# Check for *_proxy env vars.  Use them if they're there.
	$ua->env_proxy();
	
	# Get the page.

	my $req = new HTTP::Request('GET' => $query); 
	my $res = $ua->request($req);
	unless($res->is_success){ 
		warn(__PACKAGE__ . ":" . $res->status_line);
		return undef;
	}
	my $page = $res->content;
	
	# Parse the response page.  $count contains number of re matches. 
	# An example of the html response is:
	#
	# pub  1024/<a href="/pks/lookup?op=get&search=0x7C2F31DF">7C2F31DF\
	# </a> 2001/08/28 Chris J. Ball &lt;<a href="/pks/lookup?op=get&search\
	# =0x7C2F31DF">chris@void.printf.net</a>&gt;

	my $count =()= $page =~ m!pub  \d{4}/<a.*?href.*?>(.{8})</a> \d{4}/\d{2}/\d{2} (.*) &lt!g;

	# We must only have two matches; one for keyid, one for name.  Zero
	# matches signifies a missed search, and more than two would signify
	# multiple matches.  The reason for giving up and returning undef in
	# the latter case is explained POD-wards.
	
	return undef unless $count == 2;
	$self->{_result} = $1;
	$self->{_name} = $2;
	return $self;
}

sub name { return $_[0]->{_name} }
sub result { return $_[0]->{_result} }

1;
__END__

=head1 NAME

PGP::FindKey - Perl interface to finding PGP keyids from e-mail addresses.

=head1 SYNOPSIS

  use PGP::FindKey; 
  $obj = new PGP::FindKey
  	( 'keyserver' 	=> 'keyserver.pgp.com', 
	  'address' 	=> 'remote_user@their.address' );
  die( "The key could not be found, or there was one than one match.\n" ) unless defined($obj);

  print $obj->result;	# the keyid found. 
  print $obj->name;	# the name associated with the key.

  # We could call `gpg --recv-key $obj->result` here.

=head1 DESCRIPTION

Perl interface to finding PGP keyids from e-mail addresses.

=head1 METHOD

B<new> - Creates a new PGP::FindKey object.  Parameters:

  address:   (mandatory) E-mail address to be translated.
  keyserver: Default to 'keyserver.pgp.com'.
  path:	     Default to '/pks/lookup?'.
  command:   Default to '?op=index&search='.

=head1 NOTES

The module will return undef if more than one key is present for an
address.  This is because that we - or indeed, the user - have no way
of knowing which key they're after in this case, and it would be a
bad idea to encourage them to encrypt to a random public key.  This
limitation will be addressed when a $want_array param is implemented,
and the choice can be given to the user if required.

=head1 TODO

Plenty of things:
  \-  More information about the key found.
  \-  More meaningful error reporting.
  \-  Other mechanisms.  $want_array param, more OO.

=head1 AUTHOR

Chris Ball <chris@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
