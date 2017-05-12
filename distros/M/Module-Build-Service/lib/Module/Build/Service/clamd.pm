package Module::Build::Service::clamd;
{
  $Module::Build::Service::clamd::VERSION = '0.91';
}
# ABSTRACT: Service implementation for clamd

use Log::Any qw{$log};
use Moo;
extends 'Module::Build::Service::Base';
with 'Module::Build::Service::Fork';


sub _build_command {
    my ($self) = @_;
    [$self->bin, "-c", $self->config];
}


has 'config' => (is => 'lazy',
                 isa => sub {-f $_[0]});
sub _build_config {
    my ($self) = @_;
    $self->config_default->filename;
}

has 'config_default' => (init_arg => undef,
                         is => 'lazy',
                         isa => sub {ref $_[0] eq 'File::Temp'});
sub _build_config_default {
    my ($self) = @_;
    require File::Temp;
    my $tempfile = File::Temp->new();
    $tempfile->printf (<<CLAMD, $self->socket);
  Debug true
  FixStaleSocket true
  Foreground true
  LocalSocket %s
CLAMD
    $tempfile;
}


has 'socket' => (is => 'lazy');
sub _build_socket {
    my ($self) = @_;
    File::Spec->catfile ($self->_builder->mbs_socket_dir, 'clamd');
}


1;

__END__
=pod

=head1 NAME

Module::Build::Service::clamd - Service implementation for clamd

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  $self->services ([[clamd => 1]]);

=head1 DESCRIPTION

This is a service definition for clamd.  By default we start the
service listening to on localhost:50097 with a minimal config.  You
can use the following arguments to the service definition to customize
this.

=head1 ATTRIBUTES

=head2 command

The command line to use when invoking clamd.  Defaults to:

  <bin> -c <config>

=head2 config

A config file to use for setting up clamd.

We will generate a minimalist config file by default but if you have
something more elaborate in mind, you can point to a static config
file here.

If you do so, please be warned that the config I<MUST> include the

  Foreground true

directive, or we will not be able to terminate it properly.  The
default config is equivalent to

  Debug true
  FixStaleSocket true
  Foreground true
  LocalSocket _build/mbs/socket/clamd

=head2 socket

If you just want clamd to listen on a different socket, specify the
full path here and it will be substituted into the default config.

=head2 OTHER

See L<Module::Build::Service::Base> and
L<Module::Build::Service::Fork> for more configurable attributes.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ironic Design, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

