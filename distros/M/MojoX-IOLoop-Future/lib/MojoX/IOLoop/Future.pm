package MojoX::IOLoop::Future;
  use strict;
  use warnings;

  use Mojo::IOLoop;
  use Future;

  use base qw( Future );

  sub await {
    my $self = shift;

    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  }

1;

#################### main pod documentation begin ###################

=head1 NAME

MojoX::IOLoop::Future - use L<Future> with L<Mojo::IOLoop>

=head1 SYNOPSIS

  use MojoX::IOLoop::Future;
  my $f = MojoX::IOLoop::Future->new;

=head1 DESCRIPTION

Creates Futures that know how to await with Mojo::IOLoop. This permits these
futures to block until the future is ready

=head1 CONTRIBUTE

The source code and issues are on https://github.com/pplu/mojo-ioloop-future

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

Copyright (c) 2015 by Jose Luis Martinez Torres

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
