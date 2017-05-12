package Mojolicious::Plugin::ForkCart;
use Mojo::Base 'Mojolicious::Plugin';

use Time::HiRes qw(usleep);

our $VERSION = '0.03';
our $pkg = __PACKAGE__;

our $caddy_pkg = "${pkg}::Caddy";
our $plugin_pkg = "${pkg}::Plugin";
our $count = 0;

our $app;  # HACK

use constant DEBUG => $ENV{MOJOLICIOUS_PLUGIN_FORKCART_DEBUG} || 0;

sub register {
  my ($cart, $app, $ops) = @_;

  $Mojolicious::Plugin::ForkCart::app = $app;

  my $caddy = $caddy_pkg->new(app => $app);

  if ($caddy->is_alive && $ENV{HYPNOTOAD_STOP}) {
    my $data = $caddy->state->data;
    $data->{shutdown} = 1;
    $caddy->state->data($data);

    return;
  }

  # This could be simpler
  if ($caddy->is_alive && !$ENV{MOJOLICIOUS_PLUGIN_FORKCART_ADD}) {
    $app->log->info("$$: " . ($caddy->state->data->{caddy_pid} // "") . " is alive: shutdown") if DEBUG;

    my $data = $caddy->state->data;
    $data->{shutdown} = 1;
    $caddy->state->data($data);

    while ($caddy->is_alive) {
      $app->log->info("$$: " . ($caddy->state->data->{caddy_pid} // "") . " is alive: waiting") if DEBUG;

      usleep(50000);
    }

    unlink($caddy->state->file);
  } elsif ($caddy->is_alive) {
    $app->log->info("$$: " . ($caddy->state->data->{caddy_pid} // "") . " is alive: $ENV{MOJOLICIOUS_PLUGIN_FORKCART_ADD}") if DEBUG;
      } elsif ($ARGV[0] && $ARGV[0] =~ m/^(daemon|prefork)$/) {
        my $state_file = $caddy->state->file;

        $app->log->info("$$: $ARGV[0]: unlink($state_file)") if DEBUG;

        unlink($state_file);
      } elsif ($ENV{HYPNOTOAD_REV} && 2 <= $ENV{HYPNOTOAD_REV}) {
        my $state_file = $caddy->state->file;

        $app->log->info("$$: hypnotoad: unlink($state_file)") if DEBUG;

        unlink($state_file);
      }

      $app->helper(forked => sub {
        ++$count;

        Mojo::IOLoop->next_tick($caddy->add(pop));
      });

      if ($ops->{process}) {
        $plugin_pkg->$_($caddy) for @{ $ops->{process} };
      }
    }

    package Mojolicious::Plugin::ForkCart::Plugin;
    use Mojo::Base -base;

    use constant DEBUG => Mojolicious::Plugin::ForkCart::DEBUG;

    sub minion {
      my $caddy = pop;

      my $app = $caddy->app;

      $app->plugin(qw(Mojolicious::Plugin::ForkCall)) 
        unless $app->can("fork_call");

      $app->forked(sub {
        my $app = shift;

        $app->log->info("$$: Child forked: " . getppid) if DEBUG;

        $app->fork_call(
          sub {
            $app->log->info("$$: Child fork_call: " . getppid) if DEBUG;

            # I dunno why I have (or if I have) to do this for hypnotoad
            delete($ENV{HYPNOTOAD_APP});
            delete($ENV{HYPNOTOAD_EXE});
            delete($ENV{HYPNOTOAD_FOREGROUND});
            delete($ENV{HYPNOTOAD_REV});
            delete($ENV{HYPNOTOAD_STOP});
            delete($ENV{HYPNOTOAD_TEST});
            delete($ENV{MOJO_APP_LOADER});
            
            my @cmd = (
                $^X,
                $0,
                "minion",
                "worker"
            );
            $0 = join(" ", @cmd);

            $app->log->debug("$$: ForkCart minion worker") if DEBUG;
            system(@cmd) == 0 
                or die("0: $?");

            return 1;
          },
          sub {
            exit;
          }
        );
      });
    }

    package Mojolicious::Plugin::ForkCart::State;
    use Mojo::Base -base;

    use Fcntl qw(LOCK_EX SEEK_SET LOCK_UN :flock);
    use File::Spec::Functions qw(catfile tmpdir);
    use Mojo::Util qw(slurp spurt steady_time);
    use Mojo::JSON qw(encode_json decode_json);

    has initialized => sub { 0 };

    has qw(file);

    use constant DEBUG => Mojolicious::Plugin::ForkCart::DEBUG;

    sub _lock {
        my $fh = pop;
        flock($fh, LOCK_EX) or die "Cannot lock ? - $!\n";

        # and, in case someone appended while we were waiting...
        seek($fh, 0, SEEK_SET) or die "Cannot seek - $!\n";
    }

    sub _unlock {
        my $fh = pop;
        flock($fh, LOCK_UN) or die "Cannot unlock ? - $!\n";
    }

    sub data {
      my $state = shift;
      my $hash = shift;

      if (!$state->initialized) {
          $state->initialized(1);

          $state->file(catfile(tmpdir, sprintf("%s.state_file", $Mojolicious::Plugin::ForkCart::app->moniker)));
      }

      # Should be created by sysopen
      my $fh;
      if (-f $state->file) {
        open($fh, ">>", $state->file)
          or die(sprintf("Can't open %s", $state->file));

        $state->_lock($fh);
      }

      if ($hash) {
        spurt(encode_json($hash), $state->file);

        $state->_unlock($fh);

        return $hash;
      }
      elsif (-f $state->file) {
        my $ret = decode_json(slurp($state->file));

        $state->_unlock($fh);

        return $ret;
      }
    }

    package Mojolicious::Plugin::ForkCart::Caddy;
    use Mojo::Base -base;

    use Mojo::IOLoop;
    use Fcntl qw(O_RDWR O_CREAT O_EXCL);
    use File::Spec::Functions qw(catfile tmpdir);
    use IO::Handle;
    use Mojo::JSON qw(encode_json decode_json);
    use POSIX qw(:sys_wait_h);
    use Time::HiRes qw(usleep);
    use Mojo::Util qw(slurp spurt steady_time);

    our %code = ();
    our $created = 0;

    has qw(app);
    has qw(state) => sub { Mojolicious::Plugin::ForkCart::State->new };

    use constant DEBUG => Mojolicious::Plugin::ForkCart::DEBUG;

    sub watchdog {
      my $caddy = shift;

      return sub {
        my $data = $caddy->state->data;

        # exit unless kill("SIGZERO", $caddy->state->{caddy_manager}) || $caddy->state->{shutdown};
        kill("-KILL", getpgrp) if $data->{shutdown};

        $caddy->app->log->info("$$: Caddy recurring: " . scalar(keys %{$data->{slots}})) if DEBUG;
      };
    };

    sub is_alive {
      my $caddy = shift;

      $caddy->state->data;  # hack

      return 0 if !-f $caddy->state->file && !-s _;

      return $caddy->state->data->{caddy_pid} ? kill("SIGZERO", $caddy->state->data->{caddy_pid}) : 0;
    }

    sub is_me {
        my $state = shift->state;
        return 0 if !defined $state->data->{caddy_pid};
        return $state->data->{caddy_pid} == $$;
    }

    sub add {
      my $caddy = shift;

      my $code_key = steady_time;
      $code{$code_key} = shift;

      return sub {
        my $state_file = $caddy->state->file;
        
        my $app = $caddy->app;
        
        eval {
          $app->log->info("$$: Worker next_tick") if DEBUG;
        
          sysopen(my $fh, $state_file, O_RDWR|O_CREAT|O_EXCL) or die("$state_file: $$: $!\n");
          $caddy->state->data({ shutdown => 0, caddy_pid => $$, caddy_manager => $ARGV[0] && $ARGV[0] =~ m/daemon/ ? $$ : getppid });
          close($fh);
        };
        
        # Outside the caddy
        if ($@ && !$caddy->is_me) {
          chomp(my $err = $@);
        
          $app->log->info("$$: sysopen($state_file): $err") if DEBUG;
        
          return sub { };
        }
        elsif ($@) {
          chomp(my $err = $@);
          $app->log->info("$$: sysopen($state_file): $err") if DEBUG;
        }
        
        return sub { } if !$caddy->is_me;
        
        # Inside the caddy
        $app->log->info("$state_file: sysopen($$) <-- caddy: " . ($ENV{MOJOLICIOUS_PLUGIN_FORKCART_ADD} // 'undef')) if DEBUG;
        
        my $data = $caddy->state->data;
        my $slots = $data->{slots} //= {};
        
        $slots->{$code_key} = {};
        $slots->{$code_key}{created} = $created;
        
        ++$ENV{MOJOLICIOUS_PLUGIN_FORKCART_ADD};
        $caddy->state->data($data);
        
        $app->log->info("$$ -->: $created: $Mojolicious::Plugin::ForkCart::count") if DEBUG;
        
        # Create the slots in the caddy
        Mojo::IOLoop->next_tick($caddy->create) if ++$created == $Mojolicious::Plugin::ForkCart::count;
      };
    }

    sub create {
      my $caddy = shift;

      $caddy->app->log->info("$$: Caddy create") if DEBUG;

      return(sub {
        my $data = $caddy->state->data;
        my $app = $caddy->app;

        # Belt and suspenders error checking, shouldn't be reached (I think)
        if ($data->{caddy_pid} && $$ != $data->{caddy_pid}) {
            my $msg = "We are not the caddy";

            $app->log->error($msg);

            die($msg);
        }

        $app->log->info("$$: caddy->state->data->{caddy_manager}: " . $caddy->state->data->{caddy_manager}) if DEBUG;

        # Watchdog
        Mojo::IOLoop->recurring(1 => $caddy->watchdog);

        foreach my $code_key (keys %{ $caddy->state->data->{slots} }) {
            $app->log->info("$$: $code_key: $code{$code_key}") if DEBUG;

            my $pid = $caddy->fork($code_key);

            my $data = $caddy->state->data;
            $data->{slots}{$code_key}{pid} = $pid;
            $caddy->state->data($data);
        }
      });
    }

sub fork {
  my $caddy = shift;
  my $code_key = shift;

  my $code = $code{$code_key};
  
  my $app = $caddy->app;

  my $pgroup = getpgrp;

  die "Can't fork: $!" unless defined(my $pid = fork);
  if ($pid) { # Parent

    $app->log->info("$$: Parent return") if DEBUG;

    $SIG{CHLD} = sub {
      while ((my $child = waitpid(-1, WNOHANG)) > 0) {
        $app->log->info("$$: Parent waiting: $child") if DEBUG;
      }
    };

    return $pid;
  }

  $app->log->info("$$: Slot running: $$: " . getppid) if DEBUG;

  setpgrp($pid, $pgroup);

  # Caddy's Child
  Mojo::IOLoop->reset;

  Mojo::IOLoop->recurring(1 => sub {
    my $loop = shift;

    my $str = sprintf("%s", join(", ", @{ $caddy->state->data }{'caddy_manager', 'shutdown'}));
    $app->log->info("$$: Caddy slot monitor: $str") if DEBUG;

    # TODO: Do a graceful stop
    kill("-KILL", $pgroup) if $caddy->state->data->{shutdown} || !$caddy->is_alive;
  });

  $code->($app);
}

sub pid_wait {
  my ($pid, $timeout) = @_;

  my $ret;

  my $done = steady_time + $timeout;
  do {
    $ret = kill("SIGZERO", $pid);

    usleep 50000 if $ret;

  } until(!$ret || $done < steady_time);

  return !$ret;
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ForkCart - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $cart->plugin('ForkCart');

  # Mojolicious::Lite
  plugin 'ForkCart';

=head1 DESCRIPTION

L<Mojolicious::Plugin::ForkCart> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::ForkCart> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
