package Myriad::Commands;

use Myriad::Class;

use Unicode::UTF8 qw(decode_utf8);

use Myriad::Util::UUID;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=head1 NAME

Myriad::Commands

=head1 DESCRIPTION

Provides top-level commands, such as loading a service or making an RPC call.

=cut

use Future::Utils qw(fmap0);

use Module::Runtime qw(require_module);

use Myriad::Service::Remote;

has $myriad;
has $cmd;

BUILD (%args) {
    weaken(
        $myriad = $args{myriad} // die 'needs a Myriad parent object'
    );
}

=head2 service

Attempts to load and start one or more services.

=cut

async method service (@args) {
    my @modules;
    while(my $entry = shift @args) {
        if($entry =~ /,/) {
            unshift @args, split /,/, $entry;
        } elsif(my ($base) = $entry =~ m{^([a-z0-9_:]+)::$}i) {
            require Module::Pluggable::Object;
            my $search = Module::Pluggable::Object->new(
                search_path => [ $base ]
            );
            push @modules, $search->plugins;
        } elsif($entry =~ /^[a-z0-9_:]+[a-z0-9_]$/i) {
            push @modules, $entry;
        } else {
            die 'unsupported ' . $entry;
        }
    }

    my $service_custom_name = $myriad->config->service_name->as_string;

    die 'You cannot pass a service name and load multiple modules' if @modules > 1 and length $service_custom_name;

    # Load modules to compile

    for my $module (@modules) {
        $log->debugf('Loading %s', $module);
        try {
            require_module($module);
            die 'loaded ' . $module . ' but it cannot ->new?' unless $module->can('new');
        } catch ($e) {
            Future::Exception->throw(sprintf 'Service module %s not found', $module) if $e =~ /Can't locate/;
            Future::Exception->throw(sprintf 'Failed to load module for service %s - %s', $module, $e);
        }
    }

    # Load services into Myriad but don't start them yet

    await fmap0(async sub {
        my ($module) = @_;
        $log->debugf('Preparing %s', $module);
        try {
            if ($service_custom_name eq '') {
                await $myriad->add_service($module);
            } else {
                await $myriad->add_service($module, name => $service_custom_name);
            }
        } catch ($e) {
            Future::Exception->throw(sprintf 'Failed to add service %s - %s', $module, $e);
        }
    }, foreach => \@modules, concurrent => 4);

    $cmd = {
        code => async sub {
            try {
                await fmap0 {
                    my $service = shift;
                    $log->infof('Starting service [%s]', $service->service_name);
                    $service->start->transform(fail => sub {
                        return $service->service_name . ' : ' . shift;
                    });
                } foreach => [values $myriad->services->%*], concurrent => 4;

            } catch($e) {
                $log->warnf('Failed to start services - %s', $e);
                await $myriad->shutdown;
            }
        },
        params => {},
    };
}

=head2 remote_service

=cut

method remote_service {
    return Myriad::Service::Remote->new(
        myriad       => $myriad,
        service_name => $myriad->registry->make_service_name(
            $myriad->config->service_name->as_string
        ) // die 'no service name found'
    );
}

=head2 rpc

=cut

async method rpc ($rpc, @args) {
    my $remote_service = $self->remote_service;
    die 'RPC args should be passed as (key value) pairs' unless @args % 2 == 0;
    $cmd = {
        code => async sub {
            my $params = shift;
            my ($remote_service, $rpc, $args) = map { $params->{$_} } qw(remote_service rpc args);
            try {
                my $response = await $remote_service->call_rpc($rpc, @$args);
                $log->infof('RPC response is %s', $response);
            } catch ($e) {
                $log->warnf('RPC command failed due: %s', $e);
            }
            await $myriad->shutdown;
        },
        params => { rpc => $rpc, args => \@args, remote_service => $remote_service}
    };
}

=head2 subscription

=cut

async method subscription ($stream, @args) {
    my $remote_service = $self->remote_service;
    my $uuid = Myriad::Util::UUID::uuid();
    my $subscription = await $remote_service->subscribe($stream, "$0/$uuid");
    $log->infof('Subscribing to: %s | %s', $remote_service->service_name, $stream);
    $cmd = {
        code => async sub {
            my $params = shift;
            my ($subscription, $args) = @{$params}{qw(subscription args)};
            $subscription->each(sub {
                my $info = shift;
                $log->infof('Subscription event received: %s', $info->{data});
            })->completed;
        },
        params => { subscription => $subscription, args => \@args}
    };

}

=head2 storage

=cut

async method storage ($action, $key, $extra = undef) {
    my $remote_service = Myriad::Service::Remote->new(myriad => $myriad, service_name => $myriad->registry->make_service_name($myriad->config->service_name->as_string));
    $cmd = {
        code => async sub {
            my $params = shift;
            my ($remote_service, $action, $key, $extra) = map { $params->{$_} } qw(remote_service action key extra);

            try {
                my $response = await $remote_service->storage->$action($key, $extra // () );
                $log->infof('Storage resposne is: %s', $response);
            } catch ($e) {
                $log->warnf('Error: %s', $e);
            }

            await $myriad->shutdown;
        },
        params => { action => $action, key => $key, extra => $extra, remote_service => $remote_service} };
}

=head2 run_cmd

=cut

async method run_cmd () {
    await $cmd->{code}->($cmd->{params}) if exists $cmd->{code};
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.
