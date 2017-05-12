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
builder {
  enable 'Debug';
  #enable 'Debug', panels =>['Profiler::NYTProf'];
  $app;
};
