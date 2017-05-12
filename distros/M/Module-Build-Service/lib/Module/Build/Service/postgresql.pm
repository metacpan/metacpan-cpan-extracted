package Module::Build::Service::postgresql;
{
  $Module::Build::Service::postgresql::VERSION = '0.91';
}
# ABSTRACT: Service implementation for postgresql

use File::Path qw{make_path remove_tree};
use File::Slurp;
use File::Spec;
use Log::Any qw{$log};
use Moo;
extends 'Module::Build::Service::Base';


has 'bindir' => (is => 'lazy');
sub _build_bindir {
    my ($self) = @_;
    for my $prefix ("/usr/lib/postgresql", "/usr/local/lib/postgresql") {
        my $dir = File::Spec->catdir ($prefix, $self->version, "bin");
        $log->tracef ("Checking %s for binaries", $dir);
        if (-e File::Spec->catfile ($dir, "pg_ctl") and -e File::Spec->catfile ($dir, "createdb") and -e File::Spec->catfile ($dir, "pg_dumpall")) {
            $log->tracef ("Returning %s as binary directory", $dir);
            return $dir;
        }
    }
    die "Couldn't find postgresql binaries";
}


has 'data' => (is => 'lazy');
sub _build_data {
    my ($self) = @_;
    my $dir = File::Spec->catdir ($self->_builder->mbs_data_dir, 'postgresql');
    -d $dir or make_path ($dir) or die "Couldn't create data directory " . $dir;
    $dir;
}


has 'dump' => (is => 'lazy');
sub _build_dump {
    my ($self) = @_;
    File::Spec->catfile ($self->_builder->mbs_log_dir, 'postgresql.sql');
}


has 'service' => (is => 'ro',
                  isa => sub {!defined $_[0] or ref $_[0] eq "ARRAY"},
                  predicate => 'has_service');


has 'version' => (is => 'lazy');

sub _build_version {
    local $SIG{__WARN__} = sub {};
    (my $version = qx/psql -V/) =~ s/^psql \(PostgreSQL\) (\d+\.\d+)(?:\.|beta|rc)\d+.+/$1/s;
    die "Couldn't not figure out postgresql version" unless $version;
    $version;
}


sub _bin {
    my ($self, $bin) = @_;
    File::Spec->catfile ($self->bindir, $bin);
}


sub start_service {
    my ($self) = @_;
    $log->debug ("postgresql service initializing");
    $self->run_process ($self->_bin ("pg_ctl"), "init", "-s", "-D", $self->data, "-o", "-A trust");
    $log->debug ("postgresql service starting");
    my $logfile = $self->log =~ m,^/, ? $self->log : File::Spec->catfile ($self->_builder->mbs_log_dir, $self->log);
    $self->run_process ($self->_bin ("pg_ctl"), "start", "-s", "-w", "-D", $self->data, "-l", $logfile, "-o", "-h '' -F -k " . $self->data);
    if ($self->has_service) {
        $log->debug ("Writing service file");
        $ENV{PGSYSCONFDIR} = $self->data;
        write_file "$ENV{PGSYSCONFDIR}/pg_service.conf", map {
            my ($service, $database) = ref $_ ? @{$_} : ($_, $_);
            $self->run_process ($self->_bin ("createdb"), "-h", $self->data, $database);
            sprintf "[%s]\ndbname=%s\nhost=%s\n", $service, $database, $self->data;
        } @{$self->service};
    }
    warn "Postgresql instance available using '-h " . $self->data . "'\n";
}


sub stop_service {
    my ($self) = @_;
    if ($self->dump) {
        $log->trace ("Dumping sql data");
        $self->run_process ($self->_bin ("pg_dumpall"), "-h", $self->data, "-f", $self->dump);
    }
    $log->debug ("postgresql service stopping");
    $self->run_process ($self->_bin ("pg_ctl"), "stop", "-m", "immediate", "-s", "-D", $self->data);
    $log->debug ("Cleaning up");
    remove_tree ($self->data);
}

1;


__END__
=pod

=head1 NAME

Module::Build::Service::postgresql - Service implementation for postgresql

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  $self->services ([[slapd => 1]]);

=head1 DESCRIPTION

This is a service definition for postgresql.  By default we start the
service listening on a local unix socket, with a fairly default
configuration and a database named test.  You can use the following
arguments to the service definition to customize this.

=head1 ATTRIBUTES

=head2 bindir

Attempts to figure out the location of the postgresql binaries, and
make sure that the necessary binaries are available.  If it fails to
find everything we need, since this leaves us dead in the water, we
abort.

=head2 data

Figures out a directory to store the postgresql data files in.  If you
override this, you must make sure the directory exists.

=head2 dump

The name of the file to dump the final database to in LDIF format.
Defaults to C<postgresql.sql> in the C<Module::Build::Service> log
directory.

=head2 service

Define a list of service name to database mappings that will be placed
in C<pg_service.conf> that can be used for connecting to the test
database.

Each item may either be a string, in which case a 1:1 correspondence
is assumed, or it can be an arrayref, where the first item is the
service name and the second is the database name.  Each database named
will be created.  Alternatively, you can manage it all yourself.

=head2 version

Tries to figure out the version of postgresql installed on the system.
Since this is lazily built, it will only get called if we really need
it...in which case, if we're not able to figure it out, we should just
abort.

=head2 OTHER

See L<Module::Build::Service::Base> for more configurable attributes.

=head1 METHODS

=head2 start_service

Tries to initialize and start the postgresql database.

=head2 stop_service

Stops the postgresql database.  Totally overrides default
implementation (since we want to use pg_ctl, not kill the process
directly).

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ironic Design, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

