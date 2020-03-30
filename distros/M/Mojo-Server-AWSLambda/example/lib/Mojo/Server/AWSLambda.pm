package Mojo::Server::AWSLambda;

use Mojo::Base 'Mojo::Server';

use Mojo::Server::AWSLambda::Request;
use Mojo::Server::AWSLambda::Response;

use Mojo::Util qw<monkey_patch md5_sum>;
use Scalar::Util 'blessed';

our $VERSION = "0.01";


sub load_app {
  my ($self, $path) = @_;

  {
    require FindBin;
    FindBin->again;
    local $ENV{MOJO_APP_LOADER} = 1;
    local $ENV{MOJO_EXE};

    delete $INC{$path};
    my $app = eval
      "package Mojo::Server::Sandbox::@{[md5_sum $path]}; require \$path";
    die qq{Can't load application from file "$path": $@} if $@;
    die qq{File "$path" did not return an application object.\n}
      unless blessed $app && $app->can('handler');
    $self->app($app);
  };
  FindBin->again;

  return $self->app;
};


sub run {
   my $self = shift;
   return sub { $self->call(shift) };
}

sub call {
    my ($self, $env) = @_;

    my $tx = $self->build_tx;

    my $req = Mojo::Server::AWSLambda::Request->new;
    $req->parse($env);
    $tx->req($req);

    $self->emit(request => $tx);

    my $res = bless $tx->res, 'Mojo::Server::AWSLambda::Response';
    $res->output;
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Server::AWSLambda - Mojolicious server for AWS Lambda

=head1 SYNOPSIS

    use Mojo::Server::AWSLambda;
    my $server = Mojo::Server::AWSLambda->new(app => $mojo_app)->run;
    $server->($payload);

=head1 DESCRIPTION

Mojolicious server for AWS Lambda

** THIS MODULE IS EXPERIMENTAL. **

=head1 SEE ALSO

=over 4

=item L<AWS::Lambda> L<https://github.com/ytnobody/p5-Mojo-Server-AzureFunctions>

=back

=head1 LICENSE

Copyright (C) Prajith P.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Prajith P<lt>me@prajith.in<gt>

=cut


