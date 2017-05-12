package Net::Kubernetes::Role::APIAccess;
# ABSTRACT: Role allowing direct access to the REST api
$Net::Kubernetes::Role::APIAccess::VERSION = '1.03';
use Moose::Role;
require LWP::UserAgent;
require HTTP::Request;
use JSON::MaybeXS;
require Cpanel::JSON::XS;
require URI;
use MIME::Base64;


has url => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => 'http://localhost:8080',
);

has api_version => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has base_path => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	lazy     => 1,
	builder  => '_create_default_base_path'
);

has password => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);

has username => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);

has ua => (
	is       => 'ro',
	isa      => 'LWP::UserAgent',
	required => 1,
	builder  => '_build_lwp_agent',
    lazy     => 1,
);

has token => (
	is       => 'ro',
	isa      => 'Str',
	required => 0
);

has 'json' => (
    is       => 'ro',
    isa      => JSON::MaybeXS::JSON,
    required => 1,
    lazy     => 1,
    builder  => '_build_json',
);

has 'ssl_cert_file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'ssl_key_file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'ssl_ca_file' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'ssl_verify' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my(%input) = @_;
	if(ref($input{token})){
		if($input{token}->can('getlines')){
			$input{token} = join('', $input{token}->getlines);
		}
		elsif (ref($input{token}) eq 'GLOB') {
			my $fh = $input{token};
			$input{token} = do{ local $/; <$fh>};
		}
	}elsif (exists $input{token} && -f $input{token}) {
		open(my $fh, '<', $input{token});
		$input{token} = do{ local $/; <$fh>};
		close($fh);
	}
	if(! exists $input{api_version}){
		if(exists $input{base_path}){
			if($input{base_path} =~ m{/api/(v[^/]+)}){
				$input{api_version} = $1;
			}
		}
		else {
			$input{api_version}='v1';
		}
	}
	return $class->$orig(%input);
};

sub _create_default_base_path {
	my($self) = @_;
	return '/api/'.$self->api_version;
}

sub path {
	my($self) = @_;
	return $self->url.$self->base_path;
}

sub _build_lwp_agent {
	my $self = shift;
	my $ua = LWP::UserAgent->new(agent=>'net-kubernetes-perl/0.20');
    if($self->ssl_cert_file){
        $ua = LWP::UserAgent->new(ssl_opts => {
            verify_hostname => $self->ssl_verify,
            SSL_cert_file => $self->ssl_cert_file,
            SSL_key_file  => $self->ssl_key_file,
            SSL_ca_file   => $self->ssl_ca_file,
        });
    }
	return $ua;
}

sub _build_json {
    return JSON::MaybeXS->new->allow_blessed(1)->convert_blessed(1);
}

sub create_request {
	my($self, @options) = @_;
	my $req = HTTP::Request->new(@options);
	if ($self->username && $self->password) {
		$req->header(Authorization=>"Basic ".encode_base64($self->username.':'.$self->password));
	}
	elsif($self->token){
		$req->header(Authorization=>"Bearer ".$self->token);
	}
	return $req;
}


return 42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Kubernetes::Role::APIAccess - Role allowing direct access to the REST api

=head1 VERSION

version 1.03

=head1 AUTHOR

Dave Mueller <dave@perljedi.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Mueller.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::Kubernetes|Net::Kubernetes>

=back

=cut
