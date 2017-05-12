package t::MojoTestServer;
use Mojolicious::Lite;
use Data::Dumper;
use MojoX::Template::PHP;
use PHP;

plugin 'MojoX::Plugin::PHP' => {
    php_var_preprocessor => \&_var_preprocessor,
    php_header_processor => \&_compute_from_header,
    php_output_postprocessor => \&_postprocess_php_output
};

# t::MojoTestServer::_postprocess can be redefined, say, in t/12-postprocess.t

get '/' => sub { $_[0]->render( text => 'This is t::MojoTestServer' ); };
post '/body' => sub {
    my $self = shift;
    my $content_type = 'text/plain';
    if (ref $self->req->body eq 'File::Temp') {
	$self->render( "content-type" => $content_type,
		       text => join q//, readline($self->req->body) );
    } else {
	$self->render( "content-type" => $content_type,
		       text => Data::Dumper::Dumper($self->req->body) );
    }
};

# used in t/11-globals.t
sub _var_preprocessor {
    my $params = shift;
    while (my ($key,$val) = each %TestApp::View::PHPTest::phptest_globals) {
	$params->{$key} = $val;
    }
}

if ($Mojolicious::VERSION < 4.62) {
    *Mojo::JSON::decode_json = sub { Mojo::JSON->new->decode($_[0]) }
}

# used in t/10-compute.t
sub _compute_from_header {
    my ($key, $payload, $c) = @_;
    if ($key eq 'X-compute') {
	$payload = eval { Mojo::JSON::decode_json($payload) };
	if ($@) {
	    PHP::assign_global( 'Perl_compute_result', $@ );
	    return;
	}
	my $expr = $payload->{expr};
	my $output = $payload->{output} // 'Perl_compute_result';
	my $result = eval $expr;
	if ($@) {
	    PHP::assign_global( $output, $@ );
	    return;
	}
	PHP::assign_global( $output, $result );
	return 0;
    } elsif ($key eq 'X-collatz') {
	# see t/collatz2.php, pod for MojoX::Plugin::PHP
	$payload = eval { Mojo::JSON::decode_json($payload) };
	if ($@) {
	    PHP::assign_global( 'Perl_result', $@ );
	    return;
	}
	my $result = 1 + 3 * $payload->{n};
	PHP::assign_global( $payload->{result} || 'Perl_result', $result );
	return 0;
    } 
    return 1;
}

# flexible output postprocessor that can be updated at runtime
# see t/12-postprocess.t
sub _postprocess_php_output {
    our $postprocessor;
    $postprocessor && $postprocessor->(@_);
}

1;
