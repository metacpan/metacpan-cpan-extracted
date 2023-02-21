package Terse::Controller;
use strict;
use warnings;
no warnings 'reserved';
use attributes ();
use base 'Terse';
use B 'svref_2object';

our %HTTP;
BEGIN { %HTTP = map { $_ => 1 } qw/get post put delete connect head options trace patch/; }

sub new {
	my ($pkg, @args) = @_;
	my $self = $pkg->SUPER::new(
		app => 0,
		restrict_path => '/',
		@args
	);
	(my $namespace = $pkg) =~ s/^.*Controller:://;
	$namespace =~ s/\:\:/\//g;
	$self->namespace = lc( $namespace );
	$self->default_req = [split "/", $self->namespace]->[-1];
	$self->build_controller() if ($self->can('build_controller'));
	return $self;
}

sub preprocess_req {
	my ($self, $req, $t) = @_;
	if (!$req) {
		my $alias = $Terse::Controller::dispatcher{ref $self}{_alias};
		my $path = $t->request->uri->path;
		for my $candidate (keys %{$alias}) {
			my @captured = $path =~ m/$candidate/;
			if (scalar @captured) {
				$t->captured = \@captured;
				$req = $alias->{$candidate}->{req};
			}
		}
	}
	return $req;
}

sub build_terse {
	my ($self, $t) = @_;
	if ($self->models) {
		$t->models ||= {};
		$t->{model} = sub {
			my ($t, $model) = @_;
			$t->raiseError("invalid model: ${model}", 400) unless $self->models->{$model};
			return $t->models->{$model} ||= $self->models->{$model}->connect($t);
		};
	}
	if ($self->controllers) {
		$t->{controller} = sub {
			my ($t, $controller) = @_;
			return $self->controllers->{$controller} if $self->controllers->{$controller};
			return $self->controllers->{$self->controllers->{_alias}->{$controller}->{namespace}}
				if $self->controllers->{_alias}->{$controller};
			for my $key (keys %{$self->controllers->{_alias}}) {
				my @captured = $controller =~ m/$key/;
				if (scalar @captured) {
					$controller = $self->controllers->{$self->controllers->{_alias}->{$key}->{namespace}};
					$t->captured = \@captured;
					return $controller;
				}
			}
			return;
		};
	}
	if ($self->views) {
		$t->{view} = sub {
			my ($t, $view) = @_;
			$t->raiseError("invalid view: ${view}", 400) unless $self->views->{$view};
			return $self->views->{$view};
		};
	}
	if ($self->plugins) {
		$t->plugins ||= {};
		$t->{plugin} = sub {
			my ($t, $plugin) = @_;
			$t->raiseError("invalid plugin: ${plugin}", 400) unless $self->plugins->{$plugin};
			return $t->plugins->{$plugin} ||= ($self->plugins->{$plugin}->can('connect')
				? $self->plugins->{$plugin}->connect($t) 
				: $self->plugins->{$plugin});
		};
	}
	return $t;
}

sub MODIFY_CODE_ATTRIBUTES {
	my ($package, $coderef, @attributes, @disallowed) = @_;
	no warnings qw(reserved);
	my $name = svref_2object($coderef)->GV->NAME;
	my %attr = PARSE_ATTRIBUTES($name, @attributes);
	push @{ $Terse::Controller::dispatcher{$package}{$attr{req}} }, \%attr;
	if ($attr{path}) {
		(my $namespace = $package) =~ s/^.*Controller:://;
		$namespace =~ s/\:\:/\//g;
		$Terse::Controller::dispatcher{$package}{_alias}{$attr{path}} = {
			namespace => lc( $namespace ),
			req => $attr{req}
		};
	}
	return ();
}

sub FETCH_CODE_ATTRIBUTES {
	my ($class, $coderef) = @_;
	my $cv = svref_2object($coderef);
	return @{$Terse::Controller::dispatcher{$class}{ $cv->GV->NAME }};
}

sub PARSE_ATTRIBUTES {
	my ($sub, @attributes) = @_;
	my %attr = (
		req => $sub,
		callback => $sub
	);
	for my $attribute (@attributes) {
		if ($attribute =~ m/^\s*params\((.*)\)\s*$/) {
			$attr{params} = { eval $1 };
		}
		elsif ($attribute =~ m/^\s*([^\s\(]+)\s*\(([\s\'\"]*?)(.*)([\s\'\"]*?)\)/) {
			my $k = lc($1);
			$attr{$k} = $3;
			if ($HTTP{$k} || $k =~ m/^(any|websocket|deleayed)$/i) {
				$attr{req} = $attr{$k};
			}
		}
		else {
			$attr{lc($attribute)} = 1; 
		}
	}
	$attr{any} = 1 if ($attr{websocket} && scalar keys %attr < 4);
	return %attr;
}

sub delayed_response_handle {
	my ($self, $t,  $response, $sid, $ct, $status) = @_;
	$t->{_delayed_response} = sub {
		my $responder = shift;
		my $view = $t->view($t->response_view || $self->response_view);
		my $res = $t->_build_response($sid, 
			$t->content_type || $view && $view->content_type || $ct,
			$t->response->status_code ||= $status ||= 200
		);
		$res = [splice @{$res->finalize}, 0, 2];
		my $writer = $responder->($res);
		$response = eval { $response->($writer); };
		if ($@ || $t->response->error) {
			$res->[0] = $t->response->status_code || 500;
			$t->raiseError($@) if #@;
			push @{$res}, [$t->response->serialize];
			return $responder->($res);
		}
		elsif ($response) {
			$view = $t->view($t->response_view || $self->response_view);
			if ($view) {
				my (undef, $render) = $view->render($t, $response);
				if ($t->response->error) {
					$res->[0] = $t->response->status_code || 500;
					push @{$res}, [$t->response->no_response ? () : $t->response->serialize];
					return $responder->($res);
				}
				$response = $render;
			} else {
				$response = $response->serialize;
			}
			$writer->write($response);
		}
		$writer->close;
	};
	return $t;
}


sub response_handle {
	my ($self, $t, $response_body, $sid, $ct, $status) = @_;
	$ct ||= 'application/json';
	my $res = $t->{_delayed_response};
	return $res if ($res);
	my ($content_type, $body) = $self->views && $self->views->{$t->response_view || $self->response_view} 
		? $t->view($t->response_view || $self->response_view)->render($t, $response_body) 
		: ($ct, $response_body->serialize());
	$res = $t->_build_response($sid, $content_type, $response_body->status_code ||= $status ||= 200);
	$res->body($body);
	return $res->finalize;
}

sub dispatch {
	my ($self, $req, $t, @params) = @_;
	my $package = ref $self || $self;
	my $dispatch = $Terse::Controller::dispatcher{$package};
	my @dispatcher = @{ $dispatch->{$req} || [] };
	my $in;

	$in = sub {
		my @ISA = eval "\@$_[0]::ISA";
		for (@ISA) {
			$in->($_);
			$dispatch = $Terse::Controller::dispatcher{$_};
			next unless $dispatch && $dispatch->{$req};
			unshift @dispatcher, @{ $dispatch->{$req} };
		}
	};
	$in->($package);
	if (!scalar @dispatcher) {
		$t->logError('Invalid dispatch request', 400);
		return;
	}
	$dispatch = undef;
	my $path = $t->request->uri->path;
	my $caps = scalar @{ $t->captured || [] };

	DISPATCH: for my $candidate (reverse @dispatcher) {
		next DISPATCH unless ($candidate->{lc($t->request->method)} || $candidate->{any});
		next DISPATCH unless (!$candidate->{captured} || $caps == $candidate->{captured});
		if ($candidate->{params}) {
			for my $param (keys %{$candidate->{params}}) {
				next DISPATCH if (!$t->params->{$param});
				next DISPATCH unless $self->_partial_match(
					$t->params->{$param}, 
					$candidate->{params}->{$param}
				);
			}
		}
		$t->request->uri->path =~ m/$candidate->{path}/ or next if $candidate->{path};
		$dispatch = $candidate;
		last;
	}
	$dispatch = $self->dispatch_hook($dispatch) if $self->can('dispatch_hook'); 
	my $callback = $dispatch->{callback};
	if (!$callback) {
		$t->logError('No callback found to dispatch the request', 400);
		return;
	}
	$t->response_view = $dispatch->{view} if $dispatch->{view};
	$t->content_type($dispatch->{content_type}) if $dispatch->{content_type};
	if ($dispatch->{delayed}) {
		return $t->delayed_response(sub { $self->$callback($t, @params); $t->response; });
	} elsif ($dispatch->{websocket}) {
		$self->websockets ||= {};
		$self->websockets->{$t->sid->value} = $t->websocket($self->$callback($t, @params), close_delete => 1);
		return $t;
	}
	return $self->$callback($t, @params);
}

sub _partial_match {
	my ($self, $param, $spec) = @_;
	return 0 if !$param && $spec;
	my ($ref, $match) = (ref $spec, 1);
	if (!$ref) {
		$match = ref $param ? 0 : $param =~ m/^$spec$/;
	} elsif ($ref eq 'ARRAY') {
		for (my $i = 0; $i < scalar @{$spec}; $i++) {
			$match = $self->_partial_match($param->[$i], $spec->[$i]);
			last if (!$match);
		}
	} elsif ($ref eq 'HASH') {
		for my $key ( keys %{$spec} ) {
			$match = $self->_partial_match($param->{$key}, $spec->{$key});
			last if (!$match);
		}
	}
	return $match;
}

1;

__END__;


=head1 NAME

Terse::Controller - controllers made simple.

=head1 VERSION

Version 0.123456789

=cut

=head1 SYNOPSIS

	package Stocks;

	use base 'Terse::Controller';

	sub login :any {
		return 1;
	}

	sub auth_prevent :any(auth) {
		return 0;
	}

	sub auth :get :post {
		return $_[1]->delayed_response(sub { ... });;
	}

	sub purchase :get :delayed { # delayed attribute is the same as the above 
		... #1
	}
	
	sub purchase_virtual :get(purchase) :params(virtual => 1) {
		... #2
	}

	sub purchase_post :post(purchase) {
		... # 3
	}

	sub purchase_virtual_post :post(purchase) :params(virtual => 1) {
		... # 4
	}

	sub other :get :path(foo/(.*)/bar) :captured(1) {
		... # 5
	}

	sub group_chat :websocket {
		my ($self, $context) = @_;
		return (
			connect => sub {
				$_[0]->send('welcome');
			},
			retrieve => sub {
				my ($websocket, $msg) = @_;
				# $msg = '{"confrim_sha":"XXX", "message": "Howdy world."}';
				if ($self->plugin->validate->user_message_sha($context, $websocket->graft('retrieved',$msg))) {
					$websocket->send($websocket->retrieved->confirm_sha);
					for my $open (%{ $self->websockets }) {
						$self->websockets->$open->send($websocket->retrieved->message);
					}
				}
			},
			error => sub {

			},
			disconnect => sub {

			}
		);
	}


	1;

	.... psgi ...

	use Terse;
	use Stocks;
	our $api = Stocks->new();

	sub {
		my ($env) = (shift);
		Terse->run(
			plack_env => $env,
			application => $api,
		);
	};

	....

	plackup Stocks.psgi

	GET http://localhost:5000/?req=purchase  #1
	POST http://localhost:5000/ {"req":"purchase"} #3

	GET http://localhost:5000/?req=purchase&virtual=1 #2
	POST http://localhost:5000/ {"req":"purchase", "virtual":1} #4

	GET http://localhost:5000/foo/555/bar #5

	CONNECT ws://localhost:5000/?req=group_chat;

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

L<Terse>.

=cut
