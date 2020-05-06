package Mojo::Promise::Limiter;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::Promise;

our $VERSION = '0.100';

has outstanding => 0;
has concurrency => 0;
has jobs => sub { [] };

sub new {
    my ($class, $concurrency) = @_;
    $class->SUPER::new(concurrency => $concurrency);
}

sub limit {
    my ($self, $sub, $name) = @_;
    $name //= 'anon';
    if ($self->outstanding < $self->concurrency) {
        return $self->_run($sub, $name);
    } else {
        return $self->_queue($sub, $name);
    }
}

sub _run {
    my ($self, $sub, $name) = @_;
    $self->{outstanding}++;
    $self->emit(run => $name);
    $sub->()->then(
        sub { $self->_remove($name); @_ },
        sub { $self->_remove($name); Mojo::Promise->reject(@_) },
    );
}

sub _queue {
    my ($self, $sub, $name) = @_;
    $self->emit(queue => $name);
    Mojo::Promise->new(sub {
        my ($resolve, $reject) = @_;
        push @{$self->jobs}, { sub => $sub, name => $name, resolve => $resolve, reject => $reject };
    });
}

sub _dequeue {
    my $self = shift;
    if (my $job = shift @{$self->jobs}) {
        $self->emit(dequeue => $job->{name});
        $self->_run($job->{sub}, $job->{name})->then($job->{resolve}, $job->{reject});
    }
}

sub _remove {
    my ($self, $name) = @_;
    $self->{outstanding}--;
    $self->emit(remove => $name);
    if ($self->outstanding < $self->concurrency) {
        $self->_dequeue;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Promise::Limiter - limit outstanding calls to Mojo::Promise

=head1 SYNOPSIS

  use Mojo::Promise::Limiter;
  use Mojo::Promise;
  use Mojo::IOLoop;

  my $limiter = Mojo::Promise::Limiter->new(2);

  my @job = 'a' .. 'e';

  Mojo::Promise->all(
    map { my $name = $_; $limiter->limit(sub { job($name) }) } @job,
  )->then(sub {
    my @result = @_;
    warn "\n";
    warn "results: ", (join ", ", map { $_->[0] } @result), "\n";
  })->wait;

  sub job {
    my $name = shift;
    my $text = "job $name";
    warn "started $text\n";
    return Mojo::Promise->new(sub {
      my $resolve = shift;
      Mojo::IOLoop->timer(0.1 => sub {
        warn "        $text finished\n";
        $resolve->($text);
      });
    });
  }

will outputs:

  started job a
  started job b
          job a finished
          job b finished
  started job c
  started job d
          job c finished
          job d finished
  started job e
          job e finished

  results: job a, job b, job c, job d, job e

=head1 DESCRIPTION

Mojo::Promise::Limiter allows you to limit outstanding calls to C<Mojo::Promise>s.
This is a Perl port of L<https://github.com/featurist/promise-limit>.

=head1 MOTIVATION

I sometimes want to limit outstanding calls to reduce load on external services,
or to reduce some resource (cpu, memory, etc) usage.
For example, without some mechanism to limit outstanding calls,
the following code open 5 connections to metacpan.

  my $http = Mojo::UserAgent->new;
  Mojo::Promise->all_settled(
    $http->get_p("https://metacpan.org/release/App-cpm"),
    $http->get_p("https://metacpan.org/release/Minilla"),
    $http->get_p("https://metacpan.org/release/Mouse"),
    $http->get_p("https://metacpan.org/release/Perl6-Build"),
    $http->get_p("https://metacpan.org/release/Test-CI"),
  )->wait;

With Mojo::Promise::Limiter, you can easily limit concurrent connections.
See L<eg/http.pl|https://github.com/skaji/Mojo-Promise-Limiter/tree/master/eg/http.pl>
for real world example.

=head1 EVENTS

Mojo::Promise::Limiter inherits all events from L<Mojo::EventEmitter> and can emit the
following new ones.

=head2 run

  $limiter->on(run => sub {
    my ($limiter, $name) = @_;
    ...;
  });

=head2 remove

  $limiter->on(remove => sub {
    my ($limiter, $name) = @_;
    ...;
  });

=head2 queue

  $limiter->on(queue => sub {
    my ($limiter, $name) = @_;
    ...;
  });

=head2 dequeue

  $limiter->on(dequeue => sub {
    my ($limiter, $name) = @_;
    ...;
  });

=head1 METHODS

Mojo::Promise::Limiter inherits all methods from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 new

  my $limiter = Mojo::Promise::Limiter->new($concurrency);

Constructs Mojo::Promise::Limiter object.

=head2 limit

  my $promise = $limiter->limit($sub);
  my $promise = $limiter->limit($sub, $name);

Limits calls to C<$sub> based on C<concurrency>,
where C<$sub> is a subroutine reference that must return a promise, and
C<$name> is an optional argument which will be used in events.
C<< $limiter->limit($sub) >> returns a promise that resolves or rejects
the same value or error as C<$sub>.
All subroutine references are executed in the same order in which
they were passed to C<< $limiter->limit >> method.

=head1 SEE ALSO

L<https://github.com/featurist/promise-limit>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Shoichi Kaji <skaji@cpan.org>

The ISC License

=cut
