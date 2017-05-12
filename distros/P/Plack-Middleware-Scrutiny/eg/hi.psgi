#!/usr/bin/env perl

use v5.14;

use Plack::Request;

# my $app = sub {
sub main {
  my $env = shift;
  my $q = Plack::Request->new($env);
  my $name = $q->param('name');
  # use Data::Dumper;
  # print STDERR "app: got " . Dumper($env);
  # print STDERR "hello!\n";
  return [
    200,
    ['Content-type' => 'text/html'],
    [qq|
      <html>
        <body>
          hello @{[ $q->param('name') ]}<br/>
          also, hello $name<br/>
          <form method=POST>
            <input type=text name=name>
            <input type=submit>
          </form>
        </body>
      </html>
    |]
  ];
};

my $app = \&main;

use Plack::Builder;

builder {
  enable 'Scrutiny';
  $app;
};

