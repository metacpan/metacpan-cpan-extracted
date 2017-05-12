package Module::Build::Service::gearmand;
{
  $Module::Build::Service::gearmand::VERSION = '0.91';
}
# ABSTRACT: Service implementation for gearmand

use Log::Any qw{$log};
use Moo;
extends 'Module::Build::Service::Base';
with 'Module::Build::Service::Fork';


sub _build_command {
    my ($self) = @_;
    [$self->bin, "-L", $self->listen, "-p", $self->port, "--verbose", "DEBUG"]
}


has 'listen' => (is => 'lazy');
sub _build_listen {'127.0.0.1'}


has 'port' => (is => 'lazy',
               isa => sub {$_[0] =~ m/^\d+$/});

sub _build_port {'4730'}


1;

__END__
=pod

=head1 NAME

Module::Build::Service::gearmand - Service implementation for gearmand

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  $self->services ([[gearmand => 1]]);

=head1 DESCRIPTION

This is a service definition for gearman.  By default we start the
service listening to on localhost:4730 with no config.  You can use
the following arguments to the service definition to customize this.

=head1 ATTRIBUTES

=head2 command

The command line to use when invoking gearmand.  Defaults to:

  <bin> -L <listen> -p <port> --verbose DEBUG

=head2 listen

If you just want gearmand to listen on a different address, specify
the address here.

=head2 port

If you just want gearmand to listen on a different port, specify the
port here.

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

