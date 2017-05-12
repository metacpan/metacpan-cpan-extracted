use Plack::Builder;

my $app = builder {
  enable "Plack::Middleware::GNUTerryPratchett";
  sub {[ '200', ['Content-Type' => 'text/html'], ['hello world']] }
};
