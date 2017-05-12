package Module::Build::Service::slapd;
{
  $Module::Build::Service::slapd::VERSION = '0.91';
}
# ABSTRACT: Service implementation for slapd

use File::Path qw{make_path remove_tree};
use File::Temp;
use Log::Any qw{$log};
use Moo;
extends 'Module::Build::Service::Base';
with 'Module::Build::Service::Fork';


sub _build_command {
    my ($self) = @_;
    [$self->bin, "-f", $self->config, "-h", $self->listen, "-dfilter,stats"];
}


has 'config' => (is => 'lazy');
sub _build_config {
    my ($self) = @_;
    File::Spec->catfile ($self->_builder->base_dir, "t", "etc", "slapd.conf");
}


has 'data' => (is => 'lazy');
sub _build_data {
    my ($self) = @_;
    my $dir = File::Spec->catdir ($self->_builder->mbs_data_dir, "slapd");
    $log->tracef ("%s creating data directory %s", $self->service_name, $dir);
    -d $dir or make_path ($dir) or die "Couldn't create data directory " . $dir;
    $dir
}


has 'dump' => (is => 'lazy');
sub _build_dump {
    my ($self) = @_;
    File::Spec->catfile ($self->_builder->mbs_log_dir, "slapd.ldif");
}


has 'listen' => (is => 'lazy');
sub _build_listen { 'ldapi://slapd' }


before 'stop_service' => sub {
    my ($self) = @_;
    $self->run_process ("/usr/sbin/slapcat", "-f", $self->config, "-l", $self->dump);
};

1;

__END__
=pod

=head1 NAME

Module::Build::Service::slapd - Service implementation for slapd

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  $self->services ([[slapd => 1]]);

=head1 DESCRIPTION

This is a service definition for slapd.  By default we start the
service listening on a local unix socket, with a configuration located
in t/etc/slapd.conf.  You can use the following arguments to the
service definition to customize this.

=head1 ATTRIBUTES

=head2 command

The command line to use when invoking memcached.  Defaults to:

  <bin> -f <config> -h <listen> -dfilter,stats

=head2 config

The path to the configuration file for slapd.  Defaults to C<t/etc/slapd.conf>

=head2 data

The directory in which the ldap data will be stored.  Defaults to
C<_build/mbs/data/slapd>.

If you set this to something else, you are responsible for making sure
the directory exists.

=head2 dump

The name of the file to dump the final database to in LDIF format.  Defaults to C<,,slapd.ldif>

=head2 listen

If you just want memcached to listen on a different address, specify
the address here, using slapd's URL-style specifier.

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

