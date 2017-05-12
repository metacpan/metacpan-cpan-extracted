use strict;
use warnings;
use CGI::Simple;
use POE qw(Component::FastCGI Component::Captcha::reCAPTCHA);

# Your reCAPTCHA keys from
#   https://admin.recaptcha.net/recaptcha/createsite/
use constant PUBLIC_KEY       => '<public key here>';
use constant PRIVATE_KEY      => '<private key here>';
use constant FASTCGI_PORT     => 1027;

my $captcha = POE::Component::Captcha::reCAPTCHA->spawn( alias => 'recaptcha' );

POE::Session->create(
   package_states => [
      'main' => [qw(_start _request _captcha)],
   ],
);

exit 0;

sub _start {
  my ($kernel,$session) = @_[KERNEL,SESSION];

  POE::Component::FastCGI->new(
    Port => FASTCGI_PORT,
    Handlers => [
        [ '.*' => $session->postback( '_request' ) ],
    ]
  );

  return;
}

sub _request {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $request = $_[ARG1]->[0];

  if ( $request->method eq 'POST' ) {
     my $q = CGI::Simple->new( $request->content );
     warn $_, "\n" for $q->param;
     my %opts = (
        event      => '_captcha',
        privatekey => PRIVATE_KEY,
        remoteip   => $request->env('REMOTE_ADDR'),
        challenge  => $q->param( 'recaptcha_challenge_field' ),
        response   => $q->param( 'recaptcha_response_field' ),
        _request   => $request,
     );
     $kernel->post( 'recaptcha', 'check_answer', \%opts );
     return;
  }

  my $error = undef;

  my $response = $request->make_response;
  $response->header("Content-type" => "text/html");
  my $content = <<EOT;
<html>
  <body>
    <form action="" method="post">
EOT

  $content .= $captcha->get_html( PUBLIC_KEY, $error );
  $content .= <<EOT;
    <br/>
    <input type="submit" value="submit" />
    </form>
  </body>
</html>
EOT

  $response->content($content);
  $response->send;
  return;
}

sub _captcha {
  my ($kernel,$reply) = @_[KERNEL,ARG0];
  my $request = delete $reply->{_request};

  my $response = $request->make_response;
  $response->header("Content-type" => "text/html");
  my $content = <<EOT;
<html>
  <body><pre>
EOT
  if ( $reply->{is_valid} ) {
     $content .= "<p>That was a valid response</p>\n";
  }
  else {
     $content .= "<p>Got $reply->{error}</p>\n";
  }
  $content .= <<EOT;
  </pre></body>
</html>
EOT
  $response->content($content);
  $response->send;
  return;
}
