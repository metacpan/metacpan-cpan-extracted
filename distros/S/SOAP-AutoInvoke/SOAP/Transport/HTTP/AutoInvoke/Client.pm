package SOAP::Transport::HTTP::AutoInvoke::Client;


BEGIN
{

	use strict;
	use vars qw ( $VERSION $AUTOLOAD $DEFAULT_HOST $DEFAULT_PORT $DEFAULT_ENDPOINT $DEFAULT_METHOD_URI  );

	$VERSION = '0.25';

	require 5.000;

	use SOAP::EnvelopeMaker;
	use SOAP::Struct;
	use SOAP::Transport::HTTP::Client;
	use SOAP::Parser;
	use Data::Dumper;

	$DEFAULT_HOST       = "localhost";
	$DEFAULT_PORT       = 80;
	$DEFAULT_ENDPOINT   = "/soap?class=";
	$DEFAULT_METHOD_URI = "urn:com-name-your";

}



sub new
{
my $class = shift;
my $self  = {};

	my $blessing = bless ( $self, $class );

	$self->{_soap_host}       = $DEFAULT_HOST;
	$self->{_soap_port}       = $DEFAULT_PORT;
	$self->{_soap_endpoint}   = $DEFAULT_ENDPOINT.$class;
	$self->{_soap_method_uri} = $DEFAULT_METHOD_URI;
	$self->{_soap_new_method} = "new";
	$self->{_soap_new_args}   = ();

	#
	# override defaults if arguments passed.
	#
	if (@_) {
		while ( my $arg = shift ) {
			if ( $arg eq "_soap_host"
				 || $arg eq "_soap_port"
				 || $arg eq "_soap_endpoint"
				 || $arg eq "_soap_method_uri"
				 || $arg eq "_soap_new_method" )
			{
				$self->{$arg} = shift;
			}
			else {
				push ( @{$self->{_soap_new_args}}, $arg );
			}
		}
	}

	$blessing;
}



sub _soap_get_set_args
{
my ($self, $method) = (shift,shift);


	$method =~ s/_([gs]et)//;
	my $get_set = $1;

	if ( $method =~ /_soap_host$/
		 || $method =~ /_soap_port$/
		 || $method =~ /_soap_endpoint$/
		 || $method =~ /_soap_method_uri$/
		 || $method =~ /_soap_new_method$/ )
	{
		print "GETSET = $get_set\n";
		return ( $self->{$method} ) if ( $get_set eq "get" );

		$self->{$method} = shift;
	}
	else {
		warn ( "Skipping get/set of unknown parameter: $method" );
	}

}



sub _soap_set_new_args
{
	$self->{_soap_new_args} = ();

	if (@_) {
		while ( my $arg = shift ) {
				push ( @{$self->{_soap_new_args}}, $arg );
		}
	}
}



sub _soap_get_new_args
{
	(wantarray)
	  ?  @{$self->{_soap_new_args}}
      :  $self->{_soap_new_args}
	;
}



sub _soap_deliver_request
{
my ($self, $method_name) = (shift, shift);

	#
	# Convert any arguments into a hash for send SOAP::Struct.
	#
	my %ARGV;
	my $arg = 0;

	foreach (@_) {
		if ( ref ($_) eq "ARRAY" ) {
			$_ = Dumper ( $_ );
			s/^\$VAR1 = /_soap_array::/g;
		}
		$ARGV{"ARG$arg"} = $_;
		$arg++;	
	}
	$arg = 0;
	if ( $self->{_soap_new_args} ) {
		foreach (@{$self->{_soap_new_args}}) {
			if ( ref ($_) eq "ARRAY" ) {
				$_ = Dumper ( $_ );
				s/^\$VAR1 = /_soap_array::/g;
			}
			$ARGV{"NewARG$arg"} = $_;
			$arg++;	
		}
	}

	#
	# For some reason I feel compelled to do this..
	#
	$ARGV{ARGC}              = scalar @_;

	$ARGV{_is_soap_autoload} = 1;
	$ARGV{_soap_new_method}  = ( $self->{_soap_new_method} )
	                         ?   $self->{_soap_new_method}
	                         :  ''
	                         ;


	#
	# Now set and send our request to the server.
	#
	my $soap_request = '';
	my $output_fcn = sub { $soap_request .= shift; };
	my $em = SOAP::EnvelopeMaker->new ( $output_fcn );

	my $body = SOAP::Struct->new (
	           %ARGV
	);

	$em->set_body( $self->{method_uri}, $method_name, 0, $body );


	my $soap_on_http = SOAP::Transport::HTTP::Client->new();

	my $soap_response = $soap_on_http->send_receive (
                        $self->{_soap_host},
                        $self->{_soap_port},
                        $self->{_soap_endpoint},
                        $self->{_soap_method_uri},
                        $method_name,
                        $soap_request
	);

	my $soap_parser = SOAP::Parser->new();

	$soap_parser->parsestring($soap_response);

	$body = $soap_parser->get_body;

	#
	# Convert any return arguments into a return list. 
	#
	$arg = 0;
	@_ = ();
	while ( $_ = $body->{"ARG$arg"} ) {
		if ( /^_soap_array::/ ) {
			s/^_soap_array:://;
			$_ = eval ( $_ );
		}
		push ( @_, $_ );
		$arg++;
	}

	@_;
}



DESTROY
{
 	$_[0] = undef;
}



sub AUTOLOAD
{
        my($self) = shift;
        my($method) = ($AUTOLOAD =~ /::([^:]+)$/);
        return unless ($method);

		return $self->_soap_get_set_args ( $method, @_ )
			if ( $method =~ "^_soap_" );


        $self->_soap_deliver_request ( $method, @_ );
}



1;

__END__


=head1 NAME

SOAP::AutoInvoke - Automarshall methods for Perl SOAP

=head1 SYNOPSIS

 #!/usr/bin/perl -w

 #
 #  Client example that goes with server example
 #  in SOAP::Transport::HTTP::AutoInvoke
 #
 use strict;

 package Calculator;
 use base qw( SOAP::AutoInvoke );


 package main;

 my $calc = new Calculator;


 print "sum = ", $calc->add ( 1, 2, 3 ), "\n";


=head1 DESCRIPTION

The intention of SOAP::AutoInvoke is to allow a SOAP client to use a remote
class as if it were local.  The remote package is treated as local with
a declaration like:

  package MyClass;
  use base qw( SOAP::AutoInvoke );

The SOAP::AutoInvoke base class will "Autoload" methods called from an
instance of "MyClass", send it to the server side, and return the results
to the caller's space. 

=head2 Provided Methods


=item B<new>:

I< >
The 'new' method may be called with option arguments to reset variables
from the defaults.

  my $class = new MyClass (
                  _soap_host       => 'anywhere.com',
                  _soap_port       => 80,
                  _soap_endpoint   => 'soapx?class=OtherClass',
                  _soap_method_uri => 'urn:com-name-your'
              );

It is advisable to set the package defaults at installation time in the
SOAP/Transport/HTTP/AutoInvoke/Client.pm (this) file.  The variables may also be reset after
instantiation with the 'set' methods.

The '_soap_' variable is relevant only to the local instantiation of "MyClass".
The remote instantiation will call "new" with any arguments you have passed to
the local instantiation that did I<not> begin with '_soap_':

  my $class = new MyClass (
                  _soap_host => 'anywhere.com',
                  arg1,
                  arg2,
                  @arg3,
                  arg4   => $value,
                  :
              );

This works so long as the data types being passed are something the SOAP
package can serialize.  SOAP::AutoInvoke can send and receive simple
arrays.

To reset the name of the "new" to be called remotely:

  my $class = new MyClass (
                  :
                  _soap_new_method => 'create',
                  :
              );

To not call any new method remotely:

  my $class = new MyClass (
                  :
                  _soap_new_method => undef,
                  :
              );

=over 4

=item B<_soap_get_host>:

returns the contents of $class->{_soap_host}.

=item B<_soap_set_host>:

sets the contents of $class->{_soap_host}.

=item B<_soap_get_port>:

returns the contents of $class->{_soap_port}.

=item B<_soap_set_port>:

sets the contents of $class->{_soap_port}.

=item B<_soap_get_endpoint>:

returns the contents of $class->{_soap_endpoint}.

=item B<_soap_set_endpoint>:

sets the contents of $class->{_soap_endpoint}.

=item B<_soap_get_method_uri>:

returns the contents of $class->{_soap_method_uri}.

=item B<_soap_set_method_uri>:

sets the contents of $class->{_soap_method_uri}.

=item B<_soap_get_new_args>:

returns the contents of $class->{_soap_new_args}.

=item B<_soap_set_new_args>:

sets the contents of $class->{_soap_new_args}.

=item B<_soap_get_new_method>:

returns the contents of $class->{_soap_new_method}.

=item B<_soap_set_new_method>:

sets the contents of $class->{_soap_new_method}.  The default is "new".

=back

=head1 DEPENDENCIES

SOAP-0.28
Data::Dumper

=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP(3). SOAP::Transport::HTTP::AutoInvoke(3).>
