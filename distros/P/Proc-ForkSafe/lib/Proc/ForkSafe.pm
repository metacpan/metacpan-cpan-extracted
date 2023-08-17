package Proc::ForkSafe;
use strict;
use warnings;

our $VERSION = '0.001';

sub wrap {
    my ($class, $new, $destroy) = @_;
    my $obj = $new->();
    bless { pid => $$, obj => $obj, new => $new, destroy => $destroy }, $class;
}

sub call {
    my ($self, $method, @argv) = @_;
    if ($self->{pid} != $$) {
        $self->{destroy}->($self->{obj}) if $self->{destroy};
        undef $self->{obj};
        $self->{obj} = $self->{new}->();
        $self->{pid} = $$;
    }
    $self->{obj}->$method(@argv);
}

1;
__END__

=encoding utf-8

=head1 NAME

Proc::ForkSafe - help make objects fork safe

=head1 SYNOPSIS

  use Proc::ForkSafe;

  package MyPersistentTCPClient {
    sub new {
      ...
    }
    sub request {
      ...
    }
  }

  my $client = Proc::ForkSafe->wrap(sub { MyPersistentTCPClient->new });
  my $res = $client->call(request => @some_argv);

  my $pid = fork // die;
  if ($pid == 0) {
    # in child process, $client will be reinitialized
    my $res2 = $client->call(request => @some_argv);
    ...
    exit;
  }
  waitpid $pid, 0;

=head1 DESCRIPTION

Proc::ForkSafe helps make objects fork safe.

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
