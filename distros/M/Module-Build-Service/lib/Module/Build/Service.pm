package Module::Build::Service;
{
  $Module::Build::Service::VERSION = '0.91';
}
# ABSTRACT: Manage services necessary for automated or interactive testing

use strict;
use warnings;
use Class::Load qw{load_class};
use File::Path qw{make_path remove_tree};
use File::Spec qw{};
use Log::Any qw{$log};
use Try::Tiny;
use base qw{Module::Build};

sub check_dir () {
    $log->tracef ("Creating directory %s", $_);
    -d $_ or make_path ($_) or die "Couldn't create directory $_\n";
}

__PACKAGE__->add_property (services => default => []);
__PACKAGE__->add_property (mbs_data_dir =>
                           check => \&check_dir,
                           default => sub {
                               $log->tracef ("Defaulting data directory");
                               local $_ = File::Spec->rel2abs(File::Spec->catdir ("_build", "mbs", "data"));
                               check_dir;
                               $_;
                           });
__PACKAGE__->add_property (mbs_log_dir =>
                           check => \&check_dir,
                           default => sub {
                               $log->tracef ("Defaulting log directory");
                               local $_ = File::Spec->rel2abs(File::Spec->catdir ("_build", "mbs", "log"));
                               check_dir;
                               $_;
                           });
__PACKAGE__->add_property (mbs_socket_dir =>
                           check => \&check_dir,
                           default => sub {
                               $log->tracef ("Defaulting socket directory");
                               local $_ = File::Spec->rel2abs(File::Spec->catdir ("_build", "mbs", "socket"));
                               check_dir;
                               $_;
                           });


sub ACTION_test {
    my ($self, @args) = @_;
    $self->__wrapper ("SUPER::ACTION_test", @args);
}


sub ACTION_interact {
    my ($self, @args) = @_;
    $self->__wrapper ("interact", @args);
}

sub interact {
    print STDERR "Press enter to continue";
    my $junk = <STDIN>;
}

# __wrapper is the heart of the routines we expose.  It will start
# required and/or recommended services before executing the named method
# that is handed to it as its sole argument.  When that method returns,
# __wrapper shuts down all the running services and leaves.

sub __wrapper {
    my ($self, $method, @args) = @_;

    $log->tracef ("Wrapping %s", $method);

    my ($failure, @running);

    $log->trace ("Starting up services");
    try {
        @running = map {
            my ($name, $required, %args) = @{$_};
            try {
                my $class = "Module::Build::Service::$name";
                $log->tracef ("Attempting to load %s", $name);
                load_class $class;
                $log->tracef ("Attempting to instantiate %s", $name);
                $class->new (_builder => $self, %args);
            } catch {
                $log->errorf ("Failed to start %s: %s", $name, $_);
                $required and die "Don't know how to handle required service $name: $_";
            }
        } @{$self->services};
        $log->tracef ("Running %s", $method);
        $self->$method (@args);
        $log->tracef ("Done with %s", $method);
    } catch {
        $log->errorf ("Failure starting services: %s", $_);
        $failure = $_;
    } finally {
        $log->trace ("Shutting down services");
        pop @running while @running;
    };

    die $failure if ($failure);
}

1;

__END__
=pod

=head1 NAME

Module::Build::Service - Manage services necessary for automated or interactive testing

=head1 VERSION

version 0.91

=head1 SYNOPSIS

You can either invoke C<Module::Build::Services> in your C<Build.PL>:

  use Module::Build::Services;
  Module::Build::Services->new (...,
                                services => [[postgresql => 1],
                                             [memcached => 0]])->create_build_script;

Or use it as a base class, adding hooks and such:

  package Foo::Build;
  use base qw{Module::Build::Service};

  sub SERVICE_pre_start_postgresql {
      warn "You're not gonna like this!";
  }

Then invoking that subclass in C<Build.PL>:

  use Foo::Build;
  Foo::Build->new (...,
                   services => [[postgresql => 1],
                                [memcached => 0]])->create_build_script;

Then on the command line:

  ./Build test

or

  ./Build interact

=head1 DESCRIPTION

This subclass of L<Module::Build> attempts to make it easy to start
various support services that the testing environment may need to have
access to.  Browse the C<Module::Build::Service::*> namespace for
supported services, or use one of the existing definitions as a
template to create your own.

=head2 Simplest usage

You have two options on how to use C<Module::Build::Service>.  If you
can make do with a fairly vanilla configuration, you can simply use
C<Module::Build::Services> as you would C<Module::Build>, and specify
the services when you call C<new>:

  use Module::Build::Services;
  Module::Build::Services->new (...,
                                services => [[postgresql => 1],
                                             [memcached => 0]])->create_build_script;

=head2 As a subclass

If you have more sophisticated needs---you need to use the hooks in
the service modules to manipulate the process or something of that
nature---you can use C<Module::Build::Service> as a base class to
define your hooks or otherwise add or change behavior:

  package Foo::Build;
  use base qw{Module::Build::Service};

  sub SERVICE_pre_start_postgresql {
      warn "You're not gonna like this!";
  }

Then use that subclass in Build.PL:

  use Foo::Build;
  Foo::Build->new (...,
                   services => [[postgresql => 1],
                                [memcached => 0]])->create_build_script;

=head2 As a subclass with C<Dist::Zilla>

Since C<Dist::Zilla>'s support for Module::Build doesn't (or didn't
when I first started using it a couple of years ago) make it easy to
add parameters to the invocation, you need to override C<new> to set
up your services.

So you could override the base class in your C<dist.ini>:

  [ModuleBuild]
  mb_class = Foo::Build

And then in your C<inc/Foo/Build.pm>:

  use base qw{Module::Build::Service};
  sub new {
    my ($invokee, @args) = @_;
    my $self = $invokee->SUPER::new (@args);
    $self->services ([[postgresql => 1, service => 'llama'],
                      [memcached => 0]]);
    $self
  }

=head1 METHODS

=head2 test

In the altered build process, the C<test> action iterates over the
services that have been specified, and starts each in turn before
running the tests.  When the tests finish, we shut the services down
in reverse order.

Called transparently when you do C<./Build test>.

=head2 interact

A new action, C<interact> iterates over the services that have been
specified, and starts each in turn before calling the C<interact>
method.  When the method returns, we shut the services down in reverse
order.

Called when you do C<./Build interact>.

=for Pod::Coverage check_dir
ACTION_test
ACTION_interact

=head1 CONFIGURATION

To configure the services to be started, you need to fill in the new
services property on the Module::Build object.

The property is an arrayref, where each item is, in turn, an arrayref
specifying:

=over

=item the name of the service

This is the the name of a class in the C<Module::Build::Service>
namespace.

=item whether the service is required

A boolean flag indicating whether the failure of the service to
initialize represents an error, or the build should continue.

=item any additional arguments

These are going to be specific to the service definition

=back

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ironic Design, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

