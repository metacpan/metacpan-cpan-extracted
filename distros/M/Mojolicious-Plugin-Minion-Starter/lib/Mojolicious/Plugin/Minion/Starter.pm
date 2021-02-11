package Mojolicious::Plugin::Minion::Starter;

# ABSTRACT: start/stop minion workers with the Mojolicious server

use Mojo::Base 'Mojolicious::Plugin', -signatures;

my $app;

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') };

has config => sub { {} };

has workers => sub { [] };

sub register {
    my $self = shift;
    my $app = shift;
    my $config = shift;

    $self->app($app);
    $self->config($config);

    $app->log->info('Started ' . __PACKAGE__);
    $app->hook(before_server_start => $self->before_server_start_hook($config));
}

sub before_server_start_hook{
    my $self = shift;
    my $spawn = (shift() || {})->{spawn};

    $spawn //= 1; $spawn = $spawn <= 0 ? 1 : $spawn;

    sub {
	my ($server, $app) = @_;

	if ($self->config->{debug}) {
	    $self->app->log->info(sprintf "Server type is %s, process %d", ref $server, $$);
	    $self->app->log->info(sprintf "Pid of parent of server process is %d", getppid());
	}
	# Mojo::Server::PSGI + plackup: parent is shell, server is plackup
	# Mojo::Server::PSGI + starman: parent is starman
	# Mojo::Server::Daemon morbo: parent is not shell

	if (ref $server eq 'Mojo::Server::Prefork') {
	    $server->on(spawn => sub  {
			    my ($server, $pid) = @_;
			    $self->spawn_worker if (scalar @{$self->workers} < $spawn);
			});
	    return;
	}
	if (ref $server eq 'Mojo::Server::Daemon') {
	    $self->spawn_worker for (0..($spawn - 1));
	    return;
	}
	$self->server_ok($server, $self->config->{debug});
    }
}

sub server_ok {
    my $self = shift;
    my $server = ref $_[0] ? ref shift : shift;

    my $verbose = shift;

    if ($server eq 'Mojo::Server::Daemon') {
	$self->app->log->info(sprintf "Ok: %s support server type %s", __PACKAGE__, $server);
	return 1;
    } elsif ($server eq 'Mojo::Server::Prefork') {
	$self->app->log->info(sprintf "Warning: %s does not support server type %s", __PACKAGE__, $server);
	return;
    } else {
	$self->app->log->info(sprintf "%s does not support server type %s", __PACKAGE__, $server);
	return;
    }
}

sub spawn_worker {
    my $self = shift;

    if (my $pid = fork) {
	push @{$self->workers}, $pid;
	# push @workers, $pid;
	return;
    } else {
	if ($self->config->{debug}) {
	    $self->app->log->info(sprintf "Starting minion worker %d with parent %d", $$, getppid());
	} else {
	    $self->app->log->info("Starting minion worker $$");
	}
	$self->app->minion->worker->run;
    }
}

sub DESTROY {
    my $self = shift;

    for (grep { (kill 0 => $_) && ($$ != $_ ) } @{$self->workers}) {
	if (kill HUP => $_) {
	    $self->app->log->info(sprintf 'Stopped minion worker %d', $_);
	} else {
	    $self->app->log->info(sprintf 'Error on stopping minion worker %d: %s', $_, $@) if $self->config->{debug};
	}
    }
}

1;
