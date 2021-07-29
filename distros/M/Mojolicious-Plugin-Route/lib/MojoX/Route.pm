package MojoX::Route;
use Mojo::Base -base;

use Scalar::Util 'weaken';

has 'app';

sub new {
  my $class = shift;

  if (ref $class && $class->isa(__PACKAGE__)) {
      @_ == 1 ? $_[0]->{app} = $class->{app} : push @_, app => $class->{app};
  }

  my $self = $class->SUPER::new(@_);
  weaken $self->{app};
  return $self;
}

1;

__END__

=encoding utf8

=head1 NAME

MojoX::Route - Route base class

=head1 SYNOPSIS

    # Route
    package App::Route::Foo;
    use Mojo::Base 'MojoX::Route';

    sub route {
        # code
    }

    sub any {
        # code
    }

    sub under {
        # code
    }

    1;

=head1 DESCRIPTION

L<MojoX::Route> is the base class for your Mojolicious routes, this class was created based on the L<MojoX::Model>.

=head1 ATTRIBUTES

L<MojoX::Route> inherits all attributes from L<Mojo::Base> and implements
the following new ones.

=head2 app

    my $app = $route->app;
    $route  = $route->app(Mojolicious->new);

A reference back to the application, usually a L<Mojolicious> object.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Routes::Route>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Lucas Tiago de Moraes, C<lucastiagodemoraes@gmail.com>.

=head1 CONTRIBUTORS

Andrey Khozov, C<avkhozov@googlemail.com>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
