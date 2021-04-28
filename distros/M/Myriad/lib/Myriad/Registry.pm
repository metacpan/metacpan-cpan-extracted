package Myriad::Registry;

use Myriad::Class extends => 'IO::Async::Notifier';

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Registry - track available methods and subscriptions

=head1 SYNOPSIS

=head1 DESCRIPTION

Used internally within L<Myriad> for keeping track of what services
are available, and what they can do.

=cut

use Myriad::Exception::Builder category => 'registry';

declare_exception ServiceNotFound => (
    message => 'Unable to locate the given service',
);
declare_exception UnknownClass => (
    message => 'Unable to locate the given class for component lookup',
);

use Myriad::API;

has %rpc;
has %service_by_name;
has %batch;
has %emitter;
has %receiver;

=head2 add_service

Instantiates and adds a new service to the L</loop>.

Returns the service instance.

=cut

async method add_service (%args) {
    my $srv = delete $args{service};
    weaken(my $myriad = delete $args{myriad});

    my $pkg = blessed($srv) ? ref $srv : $srv;
    my $service_name = delete $args{name} // $self->make_service_name($pkg);

    $srv = $srv->new(
        %args,
        name => $service_name,
        myriad => $myriad,
    ) unless blessed($srv) and $srv->isa('Myriad::Service');

    # Inject an `$api` instance so that this service can talk
    # to storage and the outside world
    # also make sure that storage is initiated
    $myriad->storage;
    $myriad->on_start(async sub {
        $Myriad::Service::SLOT{$pkg}{api}->value($srv) = Myriad::API->new(
            myriad => $myriad,
            service_name => $service_name,
            config => await $myriad->config->service_config($pkg, $service_name),
        );
    });

    {
        no strict 'refs';
        ${"${pkg}::metrics"}->{name_prefix} = [$service_name];
    }

    $rpc{$pkg} ||= {};
    $batch{$pkg} ||= {};
    $emitter{$pkg} ||= {};
    $receiver{$pkg} ||= {};
    $log->tracef('Going to load service %s', $service_name);
    $self->loop->add(
        $srv
    );
    await $srv->load();
    my $k = refaddr($srv);
    weaken($service_by_name{$service_name} = $srv);
    weaken($myriad->services->{$k} = $srv);

    return;
}

=head2 service_by_name

Looks up the given service, returning the instance if it exists.

Will throw an exception if the service cannot be found.

=cut

method service_by_name ($k) {
    return $service_by_name{$k} // Myriad::Exception::Registry::ServiceNotFound->throw(
        reason => 'service ' . $k . ' not found'
    );
}

=head2 add_rpc

Registers a new RPC method for the given class.

=cut

method add_rpc ($pkg, $method, $code, $args) {
    $rpc{$pkg}{$method} = {
        code => $code,
        args => $args,
    };
}

=head2 rpc_for

Returns a hashref of RPC definitions for the given class.

=cut

method rpc_for ($pkg) {
    # Exception if getting for an empty unadded service or totally unknown.
    return $rpc{$pkg} // Myriad::Exception::Registry::UnknownClass->throw(
        reason => 'unknown package ' . $pkg
    );
}

=head2 add_batch

Registers a new batch method for the given class.

=cut

method add_batch ($pkg, $method, $code, $args) {
    $batch{$pkg}{$method} = {
        code => $code,
        args => $args,
    };
}

=head2 batches_for

Returns a hashref of batch methods for the given class.

=cut

method batches_for ($pkg) {
    # Exception if getting for an empty unadded service or totally unknown.
    return $batch{$pkg} // Myriad::Exception::Registry::UnknownClass->throw(
        reason => 'unknown package ' . $pkg
    );
}

=head2 add_emitter

Registers a new emitter method for the given class.

=cut

method add_emitter ($pkg, $method, $code, $args) {
    $args->{channel} //= $method;
    $emitter{$pkg}{$method} = {
        code => $code,
        args => $args,
    };
}

=head2 emitters_for

Returns a hashref of emitter methods for the given class.

=cut

method emitters_for ($pkg) {
    # Exception if getting for an empty unadded service or totally unknown.
    return $emitter{$pkg} // Myriad::Exception::Registry::UnknownClass->throw(
        reason => 'unknown package ' . $pkg
    );
}

=head2 add_receiver

Registers a new receiver method for the given class.

=cut

method add_receiver ($pkg, $method, $code, $args) {
    $args->{channel} //= $method;
    $args->{service} = $self->make_service_name($args->{service}) if $args->{service};
    $receiver{$pkg}{$method} = {
        code => $code,
        args => $args,
    };
}

=head2 receivers_for

Returns a hashref of receiver methods for the given class.

=cut

method receivers_for ($pkg) {
    # Exception if getting for an empty unadded service or totally unknown.
    return $receiver{$pkg} // Myriad::Exception::Registry::UnknownClass->throw(
        reason => 'unknown package ' . $pkg
    );
}

=head2 make_service_name

Reformat a given string to make it combatible with our services
naming strategy

=cut

method make_service_name ($name) {
    return lc($name) =~ s{::}{.}gr
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

