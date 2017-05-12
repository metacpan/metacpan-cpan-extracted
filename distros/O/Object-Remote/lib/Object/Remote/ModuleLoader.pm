package Object::Remote::ModuleLoader;

BEGIN {
  package Object::Remote::ModuleLoader::Hook;
  use Moo;
  use Object::Remote::Logging qw( :log :dlog );
  has sender => (is => 'ro', required => 1);

  # unqualified INC forced into package main
  sub Object::Remote::ModuleLoader::Hook::INC {
    my ($self, $module) = @_;
    log_debug { "Loading $module via " . ref($self) };
    my $ret = eval {
      if (my $code = $self->sender->source_for($module)) {
        open my $fh, '<', \$code;
        Dlog_trace { "Module sender successfully sent code for '$module': $code" } $code;
        return $fh;
      }
      log_trace { "Module sender did not return code for '$module'" };
      return;
    };
    if ($@) {
      log_trace { "Module sender blew up - $@" };
      if ($@ =~ /Can't locate/) {
        # Fudge the error messge to make it work with
        # Module::Runtime use_package_optimistically
        # Module::Runtime wants - /\ACan't locate \Q$fn\E .+ at \Q@{[__FILE__]}\E line/
        # We could probably measure and hard-code this but that could easily
        # be a forwards compatibility disaster, so do a quick search of caller
        # with a reasonable range; we're already into a woefully inefficient
        # situation here so a little defensiveness won't make things much worse
        foreach my $i (4..20) {
          my ($package, $file, $line) = caller($i);
          last unless $package;
          if ($package eq 'Module::Runtime') {
            # we want to fill in the error message with the 
            # module runtime module call info.
            $@ =~ s/(in \@INC.)/$1 at $file line $line/;
            last;
          }
        }
      }
      die $@;
    }
    return $ret;
  }
}

use Moo;

use Object::Remote::Logging qw( :log );

has module_sender => (is => 'ro', required => 1);

has inc_hook => (is => 'lazy');

sub _build_inc_hook {
  my ($self) = @_;
  log_debug { "Constructing module builder hook" };
  my $hook = Object::Remote::ModuleLoader::Hook->new(sender => $self->module_sender);
  log_trace { "Done constructing module builder hook" };
  return $hook;
}

sub BUILD { shift->enable }

sub enable {
  log_debug { "enabling module loader hook" };
  push @INC, shift->inc_hook;
  return;
}

sub disable {
  my ($self) = @_;
  log_debug { "disabling module loader hook" };
  my $hook = $self->inc_hook;
  @INC = grep $_ ne $hook, @INC;
  return;
}

sub DEMOLISH { $_[0]->disable unless $_[1] }

1;
