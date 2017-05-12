package Plack::App::Prack;

use warnings;
use strict;

use Plack::Util::Accessor qw/config/;
use Plack::App::Prack::Worker;

our $VERSION = '0.02';

use parent 'Plack::Component';

sub prepare_app {
  my $self = shift;

  die "configuration \"".$self->config."\" doesn't exist" unless -e $self->config;

  $self->{worker} = Plack::App::Prack::Worker->new(config => $self->config);
}

sub call {
  my ($self, $env) = @_;
  return $self->{worker}->proxy($env);
}

1;

__END__

=head1 NAME

Plack::App::Prack - Proxy plack requests to a rack application

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::App::Prack;

    builder {
      mount "/rack" => Plack::App::Prack->new(config => "config.ru");
    }

=head1 DESCRIPTION

This app will fork a ruby process that can handle rack requests.
Requests are converted to JSON and sent over a unix socket as a
netstring, a response is then read and used as the psgi response.

=head1 AUTHOR

Lee Aylward, C<< <leedo at cpan.org> >>

=head1 SEE ALSO

Nack L<http://josh.github.com/nack/>

L<Plack::Builder>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
