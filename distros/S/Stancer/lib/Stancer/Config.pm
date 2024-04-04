package Stancer::Config;

use 5.020;
use strict;
use warnings;

# ABSTRACT: API configuration
our $VERSION = '1.0.3'; # VERSION

use Stancer::Core::Types qw(:api ArrayRef Bool Enum InstanceOf Int Port Str);

use Config qw(%Config);
use DateTime::TimeZone;
use English qw(-no_match_vars);
use Stancer::Exceptions::MissingApiKey;
use LWP::UserAgent;
use Scalar::Util qw(blessed);

use Moo;
use namespace::clean;

use constant {
    LIVE => 'live',
    TEST => 'test',
};


around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $params = $class->$orig(@args);

    if (exists $params->{keychain}) {
        my @keys = $params->{keychain};

        @keys = @{$params->{keychain}} if ref $params->{keychain} eq 'ARRAY';

        foreach my $key (@keys) {
            my $prefix = substr $key, 0, 5;

            $params->{pprod} = $key if $prefix eq 'pprod';
            $params->{ptest} = $key if $prefix eq 'ptest';
            $params->{sprod} = $key if $prefix eq 'sprod';
            $params->{stest} = $key if $prefix eq 'stest';
        }
    }

    return $params;
};


has calls => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['Stancer::Core::Request::Call']],
    default => sub { [] },
);


has debug => (
    is => 'rw',
    isa => Bool,
    default => sub { not(defined $_[0]->mode) or $_[0]->mode ne Stancer::Config::LIVE },
    lazy => 1,
);


has default_timezone => (
    is => 'rw',
    isa => InstanceOf['DateTime::TimeZone'],
    coerce => sub {
        return $_[0] if not defined $_[0];
        return $_[0] if blessed($_[0]) and $_[0]->isa('DateTime::TimeZone');
        return DateTime::TimeZone->new(name => $_[0]);
    },
);


has host => (
    is => 'rw',
    isa => Str,
    default => 'api.stancer.com',
    predicate => 1,
);


sub keychain {
    my ($this, @args) = @_;
    my @data = @args;
    my @keychain = ();

    if (scalar @args == 1) {
        if (ref $args[0] eq 'ARRAY') {
            @data = @{$args[0]};
        } else {
            @data = ($args[0]);
        }
    }

    if (@data) {
        foreach my $key (@data) {
            ApiKey->($key); # Automaticaly throw an error if $key has a bad format

            my $prefix = substr $key, 0, 5;

            $this->pprod($key) if $prefix eq 'pprod';
            $this->ptest($key) if $prefix eq 'ptest';
            $this->sprod($key) if $prefix eq 'sprod';
            $this->stest($key) if $prefix eq 'stest';
        }
    }

    push @keychain, $this->pprod if defined $this->pprod;
    push @keychain, $this->ptest if defined $this->ptest;
    push @keychain, $this->sprod if defined $this->sprod;
    push @keychain, $this->stest if defined $this->stest;

    return \@keychain;
}


has lwp => (
    is => 'rw',
    isa => sub { ref $_[0] eq 'LWP::UserAgent' },
    default => sub { LWP::UserAgent->new() },
    lazy => 1,
    predicate => 1,
);


has mode => (
    is => 'rw',
    isa => Enum[TEST, LIVE],
    default => TEST,
    predicate => 1,
);


has port => (
    is => 'rw',
    isa => Port,
    predicate => 1,
);


has pprod => (
    is => 'rw',
    isa => PublicLiveApiKey,
);


sub public_key {
    my $this = shift;
    my $key = $this->ptest;
    my $message = 'You did not provide valid public API key for %s.';
    my $environment = 'development';

    if ($this->is_live_mode) {
        $key = $this->pprod;
        $environment = 'production';
    }

    Stancer::Exceptions::MissingApiKey->throw(message => sprintf $message, $environment) unless defined $key;

    return $key;
}


has ptest => (
    is => 'rw',
    isa => PublicTestApiKey,
);


sub secret_key {
    my $this = shift;
    my $key = $this->stest;
    my $message = 'You did not provide valid secret API key for %s.';
    my $environment = 'development';

    if ($this->is_live_mode) {
        $key = $this->sprod;
        $environment = 'production';
    }

    Stancer::Exceptions::MissingApiKey->throw(message => sprintf $message, $environment) unless defined $key;

    return $key;
}


has sprod => (
    is => 'rw',
    isa => SecretLiveApiKey,
);


has stest => (
    is => 'rw',
    isa => SecretTestApiKey,
);


has timeout => (
    is => 'rw',
    isa => Int,
    predicate => 1,
);


sub uri {
    my $this = shift;
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    my $pattern = 'https://%1$s/v%3$s';

    if ($this->port) {
        $pattern = 'https://%1$s:%2$d/v%3$s';
    }
    ## use critic

    return sprintf $pattern, $this->host, $this->port, $this->version;
}


sub user_agent {
    return sprintf 'libwww-perl/%s libstancer-perl/%s (%s %s; perl %vd)', (
        $LWP::VERSION,
        $Stancer::Config::VERSION,
        $Config{osname},
        $Config{archname},
        $PERL_VERSION,
    );
}


has version => (
    is => 'rw',
    isa => Int,
    default => 1,
    predicate => 1,
);


my $instance;

sub init {
    my ($self, @args) = @_;

    if ($self && $self ne __PACKAGE__) {
        unshift @args, $self;
    }

    my $params = {};

    if (scalar @args == 0) {
        return $instance;
    }

    if (scalar @args == 1) {
        if (ref $args[0] eq 'HASH') {
            $params = $args[0];
        } else {
            $params->{keychain} = $args[0];
        }
    } else {
        $params = {@args};
    }

    $instance = __PACKAGE__->new($params);

    return $instance;
}


sub is_live_mode {
    my $this = shift;

    return 1 if $this->mode eq LIVE;
    return q//;
}

sub is_test_mode {
    my $this = shift;

    return 1 if $this->mode eq TEST;
    return q//;
}

sub is_not_live_mode {
    my $this = shift;

    return not $this->is_live_mode;
}

sub is_not_test_mode {
    my $this = shift;

    return not $this->is_test_mode;
}


sub last_call {
    my $this = shift;

    return ${ $this->calls }[-1];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Config - API configuration

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

Handle configuration, connection and credential to API.

    use Stancer::Config;

    Stancer::Config->init($secret_key);

    my $payment = Stancer::Payment->new();
    $payment->send();

=head1 ATTRIBUTES

=head2 C<calls>

Read-only list of C<Stancer::Core::Request::Call>.

This list is only available in debug mode.

=head2 C<debug>

Read/Write boolean.

Indicate if we are in debug mode.

In debug mode we will register every request made to the API.

Debug mode is enabled by default in test mode and disabled by default in live mode.

=head2 C<default_timezone>

Read/Write instance of C<DateTime::TimeZone>.

Will be used as default time zone for every C<DateTime> object created by the API.

If none provided, we will let
L<DateTime default mechanism|https://metacpan.org/pod/DateTime#Globally-Setting-a-Default-Time-Zone>
do the work.

You may pass a string, it will be used to create a new C<DateTime::TimeZone> instance.

=head2 C<host>

Read/Write string, default to "api.stancer.com".

API host

=head2 C<keychain>

Read/Write array reference of API keys.

API keychain.

=head2 C<lwp>

Read/Write instance of C<LWP::UserAgent>.

If none provided, it will instanciate a new instance.
This allow you to provide your own configured L<LWP::UserAgent>.

=head2 C<mode>

Read/Write, must be 'test' or 'live', default depends on key.

You better use `Stancer::Config::TEST` or `Stancer::Config::LIVE` constants.

API mode

=head2 C<port>

Read/Write integer.

API HTTP port

=head2 C<pprod>

Read/Write 30 characters string.

Public production authentication key.

=head2 C<public_key>

Read-only 30 characters string.

Public authentication key.
Will return C<pprod> or C<ptest> key depending on configured C<mode>.

=head2 C<ptest>

Read/Write 30 characters string.

Public development authentication key.

=head2 C<secret_key>

Read-only 30 characters string.

Secret authentication key.
Will return C<sprod> or C<stest> key depending on configured C<mode>.

=head2 C<sprod>

Read/Write 30 characters string.

Secret production authentication key.

=head2 C<stest>

Read/Write 30 characters string.

Secret development authentication key.

=head2 C<timeout>

Read/Write integer.

Timeout for every API call

=head2 C<uri>

Read-only string.

Complete location for the API.

=head2 C<user_agent>

Read-only default user agent.

=head2 C<version>

Read/Write integer.

API version

=head1 METHODS

=head2 C<< Stancer::Config->new(I<%args>) : I<self> >>

This method create a new configuration object.
C<%args> can have any attribute listed in current documentation.

We may also see L</init> method.

=head2 C<< Config::init(I<$token>) : I<self> >>

=head2 C<< Config::init(I<%args>) : I<self> >>

=head2 C<< Config::init() : I<self> >>

Get an instance with only a token. It may also accept the same hash used in `new` method.

Will act as a singleton if called without argument.

=head2 C<< $config->is_live_mode() : I<bool> >>

=head2 C<< $config->is_test_mode() : I<bool> >>

=head2 C<< $config->is_not_live_mode() : I<bool> >>

=head2 C<< $config->is_not_test_mode() : I<bool> >>

Indicate if we are running or not is live mode or test mode.

=head2 C<< $config->last_call() : I<Stancer::Core::Request::Call> >>

Return the last call to the API.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Config;

You must import C<Log::Any::Adapter> before our libraries, to initialize the logger instance before use.

You can choose your log level on import directly:
    use Log::Any::Adapter (File => '/var/log/payment.log', log_level => 'info');

Read the L<Log::Any> documentation to know what other options you have.

=cut

=head1 SECURITY

=over

=item *

Never, never, NEVER register a card or a bank account number in your database.

=item *

Always uses HTTPS in card/SEPA in communication.

=item *

Our API will never give you a complete card/SEPA number, only the last four digits.
If you need to keep track, use these last four digit.

=back

=cut

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://gitlab.com/wearestancer/library/lib-perl/-/issues> or by email to
L<bug-stancer@rt.cpan.org|mailto:bug-stancer@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Joel Da Silva <jdasilva@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2024 by Stancer / Iliad78.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
