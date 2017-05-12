package Parallol;

use Mojo::Base -base;

our $VERSION = '0.3';

has on_done => sub { sub { } };

sub do {
  my ($self, $callback) = @_;

  $self->{paralloling}++;

  sub {
    $callback->(@_);
    $self->on_done->($self) if --$self->{paralloling} == 0;
  }
}

"Parallolololololololololol";

=head1 NAME

Parallol - Because parallel requests should be as fun as parallololololol!

=head1 SYNOPSIS

  my $p = Parallol->new;
  my $ua = Mojo::UserAgent->new;

  my $titles = {};

  $p->on_done(sub {
    say $titles;
  });

  $ua->get('http://bbc.co.uk/', $p->do(sub {
    $titles->{bbc} = pop->res->dom->at('title')->text;
  }));

  $ua->get('http://mojolicio.us/', $p->do(sub {
    $titles->{mojo} = pop->res->dom->at('title')->text;
  }));

=head1 DESCRIPTION

Basic action for tracking parallel requests and running callbacks after
the last request completes. See L<Mojolicious::Plugin::Parallel> for a
more concrete implementation of this technique.

=head1 METHODS

=head2 do

Wrap a request in a callback, and track parallel count.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin::Parallol>

=head2 AUTHOR

Magnus Holm L<mailto:magnus@nordaaker.com>

=head2 LICENSE

This software is licensed under the same terms as Perl itself.

=cut
