package Proc::ForkSafe v1.0.0;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

our $TRIAL = 0;


sub wrap ($class, $new, $destroy = undef) {
    my $obj = $new->();
    bless { pid => $$, obj => $obj, new => $new, destroy => $destroy }, $class;
}

sub call ($self, $method, @argv) {
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

  my $client = Proc::ForkSafe->wrap(sub (@) { MyPersistentTCPClient->new });
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

=head1 ARTIFACT ATTESTATIONS

GitHub Artifact Attestations are generated for release tarballs uploaded to
CPAN. If you care about provenance for the uploaded tarballs, see:

L<https://github.com/skaji/perl-Proc-ForkSafe/attestations>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
