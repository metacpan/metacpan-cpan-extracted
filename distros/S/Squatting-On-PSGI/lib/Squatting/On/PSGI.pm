package Squatting::On::PSGI;

use strict;
use 5.008_001;
our $VERSION = '0.06';

use CGI::Cookie;
use Plack::Request;
use Squatting::H;

# p for private
my %p;
$p{init_cc} = sub {
  my ($c, $env)  = @_;
  my $cc       = $c->clone;
  $cc->env     = $env;
  $cc->cookies = $p{c}->($env->{HTTP_COOKIE} || '');
  $cc->input   = $p{i}->($env);
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = { };
  $cc->state   = $env->{'psgix.session'};
  $cc->status  = 200;
  $cc;
};

# \%input = i($env)  # Extract CGI parameters from an env object
$p{i} = sub {
  my $r = Plack::Request->new($_[0]);
  $r->parameters->as_hashref_mixed;
};

# \%cookies = $p{c}->($cookie_header)  # Parse Cookie header(s).
$p{c} = sub {
  +{ map { ref($_) ? $_->value : $_ } CGI::Cookie->parse($_[0]) };
};

sub psgi {
  my ($app, $env) = @_;

  $env->{PATH_INFO} ||= "/";
  $env->{REQUEST_PATH} ||= do {
    my $script_name = $env->{SCRIPT_NAME};
    $script_name =~ s{/$}{};
    $script_name . $env->{PATH_INFO};
  };
  $env->{REQUEST_URI} ||= do {
    ($env->{QUERY_STRING})
      ? "$env->{REQUEST_PATH}?$env->{QUERY_STRING}"
      : $env->{REQUEST_PATH};
  };

  my $res;
  eval {
    no strict 'refs';
    my ($c, $args) = &{ $app . "::D" }($env->{REQUEST_PATH});
    my $cc = $p{init_cc}->($c, $env);
    my $content = $app->service($cc, @$args);

    $res = [ $cc->status, [ %{ $cc->{headers} } ], [$content], ];
  };

  if ($@) {
    $res = [ 500, [ 'Content-Type' => 'text/plain' ], ["<pre>$@</pre>"] ];
  }

  return $res;
}

1;

__END__

=head1 NAME

Squatting::On::PSGI - Run Squatting app on PSGI

=head1 SYNOPSIS

  # app.psgi
  use App 'On::PSGI';
  App->init;

  my $handler = sub {
      my $env = shift;
      App->psgi($env);
  };

=head1 DESCRIPTION

Squatting::On::PSGI is an adapter to run Squatting apps on PSGI implementations.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt> (original author)

John Beppu E<lt>beppu@cpan.orgE<gt> (current maintainer)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Squatting::On::CGI> L<CGI::PSGI>

=cut
