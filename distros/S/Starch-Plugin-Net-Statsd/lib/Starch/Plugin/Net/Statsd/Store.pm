package # hide from PAUSE
    Starch::Plugin::Net::Statsd::Store;

use Net::Statsd;
use Types::Common::String -types;
use Time::HiRes qw( gettimeofday tv_interval );
use Try::Tiny;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForStore
);

has statsd_path => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_statsd_path {
    my ($self) = @_;
    my $path = $self->short_store_class_name();

    # Path sanitization stolen, and slightly modified, from the statsd source.
    $path =~ s{\s+}{_}g;
    $path =~ s{/}{-}g;
    $path =~ s{::}{-}g;
    $path =~ s{[^a-zA-Z_\-0-9\.]}{}g;

    return $path;
}

has statsd_full_path => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_statsd_full_path {
    my ($self) = @_;
    return $self->manager->statsd_root_path() . '.' . $self->statsd_path();
}

foreach my $method (qw( set get remove )) {
    around $method => sub{
        my ($orig, $self, @args) = @_;

        return $self->$orig( @args ) if $self->isa('Starch::Store::Layered');

        my $path = $self->statsd_full_path() . '.' . $method;

        my $start = [gettimeofday];

        my ($errored, $error);
        my $data = try { $self->$orig( @args ) }
        catch { ($errored, $error) = (1, $_) };

        my $end = [gettimeofday];

        if ($errored) {
            $path .= '-error';
        }
        elsif ($method eq 'get') {
            $path .= '-' . ($data ? 'hit' : 'miss');
        }

        my $host = $self->manager->statsd_host();
        local $Net::Statsd::HOST = $host if defined $host;

        my $port = $self->manager->statsd_port();
        local $Net::Statsd::PORT = $port if defined $port;

        Net::Statsd::timing(
            $path,
            tv_interval($start, $end) * 1000,
            $self->manager->statsd_sample_rate(),
        );

        die $error if $errored;

        return if $method ne 'get';
        return $data;
    };
}

1;
