package NetDNA;
use strict;
use warnings;
use JSON;
use Net::OAuth;
use LWP::UserAgent;
use URI;
use Data::Dumper;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
my $base_url = "https://rws.netdna.com/";
my $debug;
my $VERSION = '0.1';

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


#################### subroutine header begin ####################

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   : 

=cut

#################### subroutine header end ####################

# Constructor
sub new {
        my $class = shift;
        my $self = {
                _myalias                => shift,
                _consumer_key           => shift,
                _consumer_secret        => shift,
        };
        # Print all the values just for clarification.
        #print "My Alias is $self->{_myalias}\n";
        #print "My Consumer Key is $self->{_consumer_key}\n";
        #print "My Consumer Secret is $self->{_consumer_secret}\n";
        bless $self, $class;
        return $self;
}

# Set the Alias
sub setAlias {
        my ( $self, $alias ) = @_;
        $self->{_myalias} = $alias if defined($alias);
        return $self->{_myalias};
}

# Set the Consumer Key
sub setKey {
        my ( $self, $alias ) = @_;
        $self->{_myalias} = $alias if defined($alias);
        return $self->{_consumer_key};
}

# Set the Consumer Secret
sub setSecret {
        my ( $self, $secret ) = @_;
        $self->{_myalias} = $secret if defined($secret);
        return $self->{_consumer_secret};
}

# Get the Alias
sub getAlias {
        my( $self ) = @_;
        return $self->{_myalias};
}

# Get the Consumer Key
sub getKey {
        my( $self ) = @_;
        return $self->{_consumer_key};
}

# Get the Consumer Secret
sub getSecret {
        my( $self ) = @_;
        return $self->{_consumer_secret};
}

# Override helper function
sub get {
        my( $self, $address, $debug ) = @_;
        $address = $base_url . $self->{_myalias} . $address;

        if($debug){
                print "Making GET request to " . $address . "\n";
        }

        my $url = shift;
        my $ua = LWP::UserAgent->new;
        
        # Create request
        my $request = Net::OAuth->request("request token")->new(
                consumer_key => $self->{_consumer_key},  
                consumer_secret => $self->{_consumer_secret}, 
                request_url => $address, 
                request_method => 'GET', 
                signature_method => 'HMAC-SHA1',
                timestamp => time,
	        nonce => '', 
                callback => '',
        );

        # Sign request        
        $request->sign;

        # Get message to the Service Provider
        my $res = $ua->get($request->to_url); 
        
        # Decode JSON
        my $decoded_json = decode_json($res->content);
        if($decoded_json->{code} == 200) {
		if($debug){
                        print Dumper $decoded_json->{data};
		}
		return $decoded_json->{data};
	} else {
	        if($debug){
		        print Dumper $decoded_json->{error};
		}
		return $decoded_json->{error};
	}
        
        
        
}

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

NetDNA - Login and access information on NetDNA's Rest Interface

=head1 SYNOPSIS

  use NetDNA;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Michael Bastos
    CPAN ID: MBASTOS
    NetDNA
    bastosmichael@gmail.com
    https://github.com/netdna/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

