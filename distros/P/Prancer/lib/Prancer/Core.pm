package Prancer::Core;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use Try::Tiny;
use Carp;

use Prancer::Config;

use parent qw(Exporter);
our @EXPORT_OK = qw(config);

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub new {
    my ($class, $configuration_file) = @_;

    # already got an object
    return $class if ref($class);

    # this is a singleton
    my $instance = undef;
    {
        no strict 'refs';
        $instance = \${"${class}::_instance"};
        return $$instance if defined($$instance);
    }

    # ok so the singleton doesn't exist so create an instance
    my $self = bless({}, $class);

    # load configuration options if we were given a config file
    if (defined($configuration_file)) {
        $self->{'_config'} = Prancer::Config->load($configuration_file);
    }

    $$instance = $self;
    return $self;
}

sub initialized {
    my $class = shift;
    no strict 'refs';
    return (${"${class}::_instance"} ? 1 : 0);
}

sub config {
    die "core has not been initialized\n" unless Prancer::Core->initialized();

    # because this method takes no arguments we don't spend any effort trying
    # to figure out if the first argument is an instance of the package or the
    # name of the package or anything like that. and because the previous
    # statement guarantees that we've already been initialized then we'll just
    # get an instance of ourselves and use that. no muss, no fuss.
    my $self = Prancer::Core->new();

    return $self->{'_config'};
}

1;

=head1 NAME

Prancer::Core

=head1 SYNOPSIS

    use Prancer::Core qw(config);

    my $core = Prancer::Core->new('/path/to/config.yml');
    my $foo = $core->config->get('foo');
    my $bar = Prancer::Core->new->config->get('bar');
    my $baz = config->get('baz');

=head1 DESCRIPTION

This class is a singleton that contains some core methods for L<Prancer> to
more easily function. This package can be initialized and used on its own if
you want to use L<Prancer> outside of a PSGI application.

=head1 METHODS

=over

=item initialized

Since this package is a singleton, it might happen that you have a place in
your code where you try to use a method from this package before you are able
to initialize it with the necessary arguments to C<new>. This will tell you if
this package has been initialized.

    die "core has not been initialized" unless Prancer::Core->initialized();
    print Prancer::Core->new->config->get('foo');

=item config

Returns the configuration options parsed when this package was initialized. See
L<Prancer::Config> for more details on how to load and use the configuration
data.

=back

=cut
