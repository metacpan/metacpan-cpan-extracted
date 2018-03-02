package Pg::ServiceFile;

use Moo;
use Config::Pg::ServiceFile;
use Types::Standard qw/ArrayRef HashRef Str/;
use Types::Path::Tiny 'Path';

# ABSTRACT: Basic PostgreSQL connection service file interface

our $VERSION = '0.03';

has data => (
    is  => 'lazy',
    isa => Str,
);

has file => (
    is     => 'lazy',
    isa    => Path,
    coerce => 1,
);

has name => (
    is  => 'lazy',
    isa => Str,
);

has names => (
    is  => 'lazy',
    isa => ArrayRef,
);

has service => (
    is  => 'lazy',
    isa => HashRef,
);

has services => (
    is  => 'lazy',
    isa => HashRef,
);

sub _build_data { shift->file->slurp_utf8 }

sub _build_file { $ENV{PGSERVICEFILE} || '~/.pg_service.conf'}

sub _build_name { $ENV{PGSERVICE} || '' }

sub _build_names { [sort keys %{shift->services}] }

sub _build_service {
    my $self = shift;
    return $self->services->{$self->name};
}

sub _build_services { Config::Pg::ServiceFile->read_string(shift->data) }

1;

__END__

=encoding utf-8

=head1 NAME

Pg::ServiceFile - Basic PostgreSQL connection service file interface

=head1 SYNOPSIS

    use Pg::ServiceFile;

    # Uses $ENV{PGSERVICEFILE} or user's `~/.pg_service.conf` file
    my $pgservice = Pg::ServiceFile->new();

    # Use a specific service file - `pg_config --sysconfdir`/pg_service.conf
    my $pgservice = Pg::ServiceFile->new(file => '/etc/postgresql-common/pg_service.conf');

    # Print all the service names
    say $_ for @{$pgservice->names};

    # Get the username for a specific service name
    say $pgservice->services->{foo}->{user};

=head1 DESCRIPTION

L<Pg::ServiceFile> is a partially complete interface to the PostgreSQL
connection service file. It's complete in the fact that it reads the C<<
$ENV{PGSERVICEFILE} >> or the user service file C<< ~/.pg_service.conf >> as
standard, but will not automatically retrieve and merge the system-wide service
file or check C<PGSYSCONFDIR>.

If you know the connection service file you want to use, and just want the data
as a C<HASH> reference, you can use the simpler module
L<Config::Pg::ServiceFile> which has less dependencies and features.

=head1 ATTRIBUTES

L<Pg::ServiceFile> implements the following attributes.

=head2 data

    my $pgservice = Pg::ServiceFile->new(data => <<~'PGSERVICEFILE');
        [foo]
        host=localhost
        port=5432
        user=foo
        dbname=db_foo
        password=password
    PGSERVICEFILE

    my $pgservice = Pg::ServiceFile->new(file => '~/.pg_service.conf');
    say $pgservice->data;

The connection service file data. This is the contents of L</"file">, or the
data that has been passed in directly during instantiation.

=head2 file

    my $pgservice = Pg::ServiceFile->new();
    say $pgservice->file; # ~/.pg_service.conf (if it exists)

    my $pgservice = Pg::ServiceFile->new(file => '~/myservice.conf');
    say $pgservice->file; # ~/myservice.conf

Defaults to C<< $ENV{PGSERVICEFILE} >> or C<< ~/.pg_service.conf >>, but can be
any valid connection service file.

=head2 name

    local $ENV{PGSERVICE} = 'foo';

    my $pgservice = Pg::ServiceFile->new();
    say $pgservice->name; # foo
    say $pgservice->service->{dbname}; # db_foo

The value of C<< $ENV{PGSERVICE} >> if it exists, or whatever is set during
instantiation. It does not check to see if a corresponding service entry exists
in the service L</"file">, but L</"service"> will return the relevant data if
it does.

=head2 names

    my $pgservice = Pg::ServiceFile->new();
    say $_ for @{$pgservice->names};

Returns the names of all the connection services from the service L</"file">.

=head2 service

    my $pgservice = Pg::ServiceFile->new(name => 'foo');
    say $pgservice->service->{dbname}; # db_foo

If L</"name"> has been set via C<< $ENV{PGSERVICE} >> or on instantiation, returns
the corresponding connection service. See L</"name">.

=head2 services

    my $pgservice = Pg::ServiceFile->new();
    while (my ($name, $service) = each %{$pgservice->services}) {
        say "[$name] $service->{dbname} at $service->{host}";
    }

Returns a C<HASH> of all of the connection services from L</"file">.

=head1 CREDITS

=over 2

Erik Rijkers

=back

=head1 AUTHOR

Paul Williams E<lt>kwakwa@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Paul Williams

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Config::Pg::ServiceFile>,
L<https://www.postgresql.org/docs/current/static/libpq-pgservice.html>.

=cut
