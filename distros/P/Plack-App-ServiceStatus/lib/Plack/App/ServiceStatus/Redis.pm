package Plack::App::ServiceStatus::Redis;

# ABSTRACT: Check Redis connection

our $VERSION = '0.911'; # VERSION

use 5.018;
use strict;
use warnings;

sub check {
    my ( $class, $redis ) = @_;

    my $rv = $redis->ping;
    return 'ok' if $rv eq 'PONG';
    return 'nok', "got: $rv";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::ServiceStatus::Redis - Check Redis connection

=head1 VERSION

version 0.911

=head1 SYNOPSIS

  my $redis      = Redis->new;
  my $status_app = Plack::App::ServiceStatus->new(
      app   => 'your app',
      Redis => $redis,
  );

=head1 CHECK

Calls C<ping> on the C<$redis> object.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
