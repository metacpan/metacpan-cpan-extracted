#line 1

package HTTP::Server::Simple::CGI;

use base qw(HTTP::Server::Simple HTTP::Server::Simple::CGI::Environment);
use strict;
use warnings;

use vars qw($default_doc $DEFAULT_CGI_INIT $DEFAULT_CGI_CLASS);

$DEFAULT_CGI_CLASS = "CGI";
$DEFAULT_CGI_INIT = sub { require CGI; CGI::initialize_globals()};


#line 30

sub accept_hook {
    my $self = shift;
    $self->setup_environment(@_);
}

#line 42

sub post_setup_hook {
    my $self = shift;
    $self->setup_server_url;
    if ( my $init = $self->cgi_init ) {
        $init->();
    }
}

#line 79

sub cgi_class {
    my $self = shift;
    if (@_) {
        $self->{cgi_class} = shift;
    }
    return $self->{cgi_class} || $DEFAULT_CGI_CLASS;
}

#line 96

sub cgi_init {
    my $self = shift;
    if (@_) {
        $self->{cgi_init} = shift;
    }
    return $self->{cgi_init} || $DEFAULT_CGI_INIT;
    
}


#line 115

sub setup {
    my $self = shift;
    $self->setup_environment_from_metadata(@_);
}

#line 131

$default_doc = ( join "", <DATA> );

sub handle_request {
    my ( $self, $cgi ) = @_;

    print "HTTP/1.0 200 OK\r\n";    # probably OK by now
    print "Content-Type: text/html\r\nContent-Length: ", length($default_doc),
        "\r\n\r\n", $default_doc;
}

#line 147

sub handler {
    my $self = shift;
    my $cgi;
    $cgi = $self->cgi_class->new;
    eval { $self->handle_request($cgi) };
    if ($@) {
        my $error = $@;
        warn $error;
    }
}

1;

__DATA__
<html>
  <head>
    <title>Hello!</title>
  </head>
  <body>
    <h1>Congratulations!</h1>

    <p>You now have a functional HTTP::Server::Simple::CGI running.
      </p>

    <p><i>(If you're seeing this page, it means you haven't subclassed
      HTTP::Server::Simple::CGI, which you'll need to do to make it
      useful.)</i>
      </p>
  </body>
</html>
