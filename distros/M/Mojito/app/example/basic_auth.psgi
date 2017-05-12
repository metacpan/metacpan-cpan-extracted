# app.psgi
my $page = '
<html>
<head>
  <title>PSGI rocks</title>
</head>
<body>
  <h1>PSGI rolls</h1>
</body>
</html>
';

my $app = sub { 
  [ 200, ['Content-type', 'text/html'], [$page]] 
};

use Plack::Builder;
use Digest::MD5;

builder {
  enable 'Debug';
  #enable 'Debug', panels =>['Profiler::NYTProf'];
  enable_if { $_[0]->{PATH_INFO} !~ m/^\/(?:public|favicon.ico)/ } 
  "Auth::Digest", 
  realm => "SecuredRealm", 
  secret => 'open_sesame',
  password_hashed => 1,
  authenticator => sub { 
    my ($username, $env) = @_; 
    # This is a mockup.  You want to do something real here.
    return Digest::MD5::md5_hex("user:SecuredRealm:password");
  };
  $app;
};
