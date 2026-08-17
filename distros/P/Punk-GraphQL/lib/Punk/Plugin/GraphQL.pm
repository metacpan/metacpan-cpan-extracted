package Punk::Plugin::GraphQL;

use 5.024;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();
use File::Basename ();
use File::Spec ();
use File::Raw::JSON ();
use GraphQL::Houtou ();

our $VERSION = '0.02';

my %STATE;

sub _state {
	my ($pkg) = @_;
	return $STATE{$pkg} //= {
		endpoints => [], registered => 0, keywords_used => 0,
	};
}

sub state_for { $STATE{ $_[1] // $_[0] } }   

sub import {
	my ($class) = @_;
	my $caller = caller;
	return if $caller->can('graphql');
	_install_keywords($caller);
	return;
}

sub _install_keywords {
	my ($pkg, $app) = @_;
	my $st = _state($pkg);
	$app ||= $pkg->can('punk_app') ? $pkg->punk_app
		: Carp::croak("Punk::Plugin::GraphQL: $pkg is not a Punk application "
			. "- `use Punk` before `use Punk::Plugin::GraphQL`");
	if (!$st->{tripwire}) {
		$st->{tripwire} = 1;
		$app->middleware(sub {
			my ($inner) = @_;
			if ($st->{keywords_used} && !$st->{registered}) {
				Carp::croak("graphql used but plugin 'GraphQL' was never "
					. "registered (add plugin 'GraphQL')");
			}
			if ($st->{registered} && !@{ $st->{endpoints} }) {
				Carp::croak("plugin 'GraphQL' registered but no graphql "
					  . "endpoints were declared (use the graphql "
					  . "keyword, or pass schema => ... to the plugin)");
			}
			return $inner;
		});
	}
	return if $st->{keywords_installed};
	$st->{keywords_installed} = 1;
	$app->install_kw(graphql => sub {
		my ($path, $schema, $opts) = @_;
		if (ref $schema eq 'HASH' && !defined $opts) {
			$opts   = $schema;
			$schema = delete $opts->{schema};
		}
		Carp::croak("graphql: a path is required") unless defined $path;
		Carp::croak("graphql '$path': a schema is required")
			unless defined $schema;
		$st->{keywords_used}++;
		push @{ $st->{endpoints} },
			{ path => $path, schema => $schema, %{ $opts // {} } };
		_mount_pending($st) if $st->{registered};
		return;
	}, __PACKAGE__);
	return;
}

sub new { bless {}, $_[0] }

sub register {
	my ($self, $app, $opts) = @_;
	$opts //= {};
	my $pkg = $app->caller_class
		or Carp::croak('Punk::Plugin::GraphQL: the app has no caller class');
	my $st = _state($pkg);
	_install_keywords($pkg, $app);
	$st->{app} = $app;
	if (defined $opts->{schema}) {
		my %ep = %$opts;
		$ep{path} //= '/graphql';
		push @{ $st->{endpoints} }, \%ep;
	}
	$st->{registered} = 1;
	_mount_pending($st);
	return;
}

sub _mount_pending {
	my ($st) = @_;
	my $app  = $st->{app};
	my $seen = $st->{mounted_paths} //= {};
	for my $ep (@{ $st->{endpoints} }) {
		next if $ep->{mounted};
		my $path = $ep->{path};
		$path = "/$path" unless $path =~ m{^/};
		$path =~ s{/\z}{} unless $path eq '/';
		Carp::croak("Punk::Plugin::GraphQL: duplicate endpoint '$path'")
			if $seen->{$path}++;
		$ep->{path} = $path;
		_mount($st, $app, $ep);
		$ep->{mounted} = 1;
	}
	return;
}

sub _build_schema {
	my ($app, $ep) = @_;
	my $schema = $ep->{schema};
	if (Scalar::Util::blessed($schema)) {
		Carp::croak("graphql '$ep->{path}': schema object must be a GraphQL::Houtou::Schema, not " . ref $schema)
			unless $schema->isa('GraphQL::Houtou::Schema');
		Carp::croak("graphql '$ep->{path}': resolvers belong in the schema object; they cannot be attached afterwards")
			if $ep->{resolvers};
		return $schema;
	}
	my $sdl = $schema;
	if ($sdl !~ /[{\n]/) {
		open my $fh, '<', $sdl
			or Carp::croak("graphql '$ep->{path}': cannot read schema file '$sdl': $!");
		local $/;
		$sdl = <$fh>;
	}
	my $resolvers = _resolve_resolvers($app, $ep, $sdl);
	return GraphQL::Houtou::build_schema($sdl,
		($resolvers ? (resolvers => $resolvers) : ()));
}

sub _resolve_resolvers {
	my ($app, $ep, $sdl) = @_;
	my $r = $ep->{resolvers} or return undef;
	my %out;
	for my $type (sort keys %$r) {
		my $spec = $r->{$type};
		if (ref $spec eq 'HASH') {
			my %map;
			for my $slot (sort keys %$spec) {
				my $v = $spec->{$slot};
				$map{$slot} = (defined $v && !ref $v)
					? $app->_resolve_target($v,
						"graphql '$ep->{path}' resolver $type.$slot")
					: $v;
			}
			$out{$type} = \%map;
		}
		elsif (defined $spec && !ref $spec) {
			$out{$type} = _controller_type($app, $ep, $type, $spec, $sdl);
		}
		else {
			Carp::croak("graphql '$ep->{path}': resolvers for '$type' must be a hashref or a controller class name");
		}
	}
	return \%out;
}

sub _controller_type {
	my ($app, $ep, $type, $class, $sdl) = @_;
	my $ns   = $app->caller_class . '::Controller::';
	my $full = index($class, $ns) == 0 ? $class : $ns . $class;
	unless (eval "require $full; 1") {
		my $err = $@;
		no strict 'refs';
		Carp::croak("graphql '$ep->{path}': resolvers for '$type' name '$class' but $full does not load: $err")
			unless %{"${full}::"};
	}
	my ($def) = grep {
		($_->{kind} // '') =~ /\A(?:type|interface|union)\z/
		&& ($_->{name} // '') eq $type
	} @{ GraphQL::Houtou::parse($sdl) };
	Carp::croak("graphql '$ep->{path}': resolvers name controller '$class' for '$type' but the SDL defines no such type")
		unless $def;
	my %map;
	for my $field (sort keys %{ $def->{fields} // {} }) {
		my $cv = $full->can($field) or next;
		$map{$field} = $cv;
	}
	if ($def->{kind} ne 'type' and my $cv = $full->can('resolve_type')) {
		$map{resolve_type} = $cv;
	}
	Carp::croak("graphql '$ep->{path}': controller $full has no method matching any field of '$type'")
		unless %map;
	return \%map;
}

sub _mount {
	my ($st, $app, $ep) = @_;
	for my $slot (qw(guard context)) {
		$ep->{$slot} = $app->_resolve_target($ep->{$slot}, "graphql '$ep->{path}' $slot")
			if defined $ep->{$slot} && ref $ep->{$slot} ne 'CODE';
	}
	my $schema = _build_schema($app, $ep);
	my %ropts;
	for my $k (qw(max_cost program_cache_max async default_list_size allow_introspection)) {
		$ropts{$k} = $ep->{$k} if defined $ep->{$k};
	}
	my $runtime = GraphQL::Houtou::build_native_runtime($schema, %ropts);
	$ep->{runtime} = $runtime;
	my $exec = _make_exec($st, $ep, $runtime);
	my $guard = $ep->{guard};
	if ($guard) {
		my $s = $app->under($ep->{path} => $guard);
		$s->post('/' => $exec);
		$s->get('/' => _make_graphiql($ep)) if $ep->{graphiql};
	}
	else {
		$app->route('POST', $ep->{path}, $exec);
		$app->route('GET', $ep->{path}, _make_graphiql($ep))
			if $ep->{graphiql};
	}
	return;
}

sub _err {
	my ($status, $message) = @_;
	my $body = File::Raw::JSON::file_json_encode(
		{ errors => [ { message => $message } ] });
	return [
		$status,
		['Content-Type'   => 'application/json; charset=utf-8',
		'Content-Length' => length $body],
		[$body]
	];
}

sub _make_exec {
	my ($st, $ep, $runtime) = @_;
	my $max_body = exists $ep->{max_body} ? $ep->{max_body} : 1024 * 1024;
	my $context  = $ep->{context};   # already resolved to a coderef
	my %xopts;
	for my $k (qw(max_depth max_nodes)) {
		$xopts{$k} = $ep->{$k} if defined $ep->{$k};
	}
	my $root_value = $ep->{root_value};
	return sub {
		my ($c) = @_;
		my $env = $c->req->env;
		my $ct = lc($env->{CONTENT_TYPE} || '');
		$ct =~ s/\s*;.*//s;
		return _err(415, 'Content-Type must be application/json')
			unless $ct eq 'application/json'
				|| $ct eq 'application/graphql-response+json';
		return _err(413, 'Request body is too large')
			if $max_body && ($env->{CONTENT_LENGTH} || 0) > $max_body;
		my $payload = eval { $c->req->json };
		return _err(400, 'Request body must be a JSON object')
			unless ref $payload eq 'HASH';
		my $query = $payload->{query};
		return _err(400, 'The "query" field is required')
			if !defined $query || ref $query || $query !~ /\S/;
		my $variables = $payload->{variables};
		return _err(400, 'The "variables" field must be a JSON object')
			if defined $variables && ref $variables ne 'HASH';
		my $operation = $payload->{operationName};
		return _err(400, 'The "operationName" field must be a non-empty ' . 'string')
		if defined $operation && (ref $operation || $operation !~ /\S/);
		my %opts = %xopts;
		$opts{variables}	  = $variables  if defined $variables;
		$opts{operation_name} = $operation  if defined $operation;
		$opts{root_value}	 = $root_value if defined $root_value;
		if ($context) {
			my ($ctx, $stall) = $context->($c);
			$opts{context}  = $ctx   if defined $ctx;
			$opts{on_stall} = $stall if defined $stall;
		}
		my $bytes = eval { $runtime->execute_document_to_json($query, %opts) };
		if (!defined $bytes) {
			warn "Punk::Plugin::GraphQL: execution failed: " . ($@ || 'no output') . "\n";
			return _err(500, 'Internal server error');
		}
		my $status = index($bytes, '{"errors":') == 0 ? 400 : 200;
		my $accept = $c->req->header('Accept') // '';
		my $rct = index($accept, 'application/graphql-response+json') >= 0
			? 'application/graphql-response+json; charset=utf-8'
			: 'application/json; charset=utf-8';
		return [
			$status,
			['Content-Type' => $rct, 'Content-Length' => length $bytes],
			[$bytes]
		];
	};
}

sub _asset_dir {
	my $pm = $INC{'Punk/Plugin/GraphQL.pm'}
		or Carp::croak('Punk::Plugin::GraphQL: cannot self-locate');
	return File::Spec->catdir(File::Basename::dirname($pm), 'GraphQL', 'assets');
}

sub _slurp {
	my ($path) = @_;
	open my $fh, '<:raw', $path
		or Carp::croak("Punk::Plugin::GraphQL: cannot read $path: $!");
	local $/;
	return scalar <$fh>;
}

sub _make_graphiql {
	my ($ep) = @_;
	eval { require Template::Stencil; 1 }
		or Carp::croak("Punk::Plugin::GraphQL: the console renders through Template::Stencil, which is not installed: $@");
	my $dir  = _asset_dir();
	my $html = Template::Stencil->new(template_dir => $dir, stat_ttl => -1)->render('console', {
		endpoint => $ep->{path},
		version  => $VERSION,
		css	  => _slurp(File::Spec->catfile($dir, 'console.css')),
		js	   => _slurp(File::Spec->catfile($dir, 'console.js')),
	});
	my $etag = '"punk-graphql-' . $VERSION . '-' . length($html) . '"';
	return sub {
		my ($c) = @_;
		my $inm = $c->req->header('If-None-Match') // '';
		return [304, ['ETag' => $etag], []] if $inm eq $etag;
		return [
			200,
			['Content-Type'   => 'text/html; charset=utf-8',
			'Content-Length' => length $html,
			'ETag'		   => $etag],
			[$html]
		];
	};
}

1;

=head1 NAME

Punk::Plugin::GraphQL - mount GraphQL::Houtou endpoints into a Punk app

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

	package MyApp;
	use Punk;
	use Punk::Plugin::GraphQL;

	plugin 'GraphQL';

	# the short form: a path and an SDL file
	graphql '/graphql' => 'schema/app.graphql';

	# an SDL string instead of a file - anything with a brace or a
	# newline is read as SDL, everything else as a filename
	graphql '/hello' => 'type Query { hello: String }', {
		resolvers => { Query => { hello => sub { 'hi' } } },
	};

	# a schema built by hand - resolvers belong to it and cannot be
	# passed here
	my $schema = GraphQL::Houtou::build_schema($sdl, resolvers => \%r);
	graphql '/prebuilt' => $schema;

	# the usual production endpoint: controllers for resolvers, a
	# per-request context, a guard, the console behind it
	graphql '/books' => 'schema/books.graphql', {
		resolvers => {
			Query    => 'Books',   # MyApp::Controller::Books
			Mutation => { rename => 'Books#rename' },
		},
		context  => 'Books#context',
		guard    => 'Auth#require_token',
		graphiql => 1,
	};

	# one hashref, schema and options together - the same endpoint
	# written the other way round
	graphql '/books-again' => {
		schema    => 'schema/books.graphql',
		resolvers => { Query => 'Books' },
		context   => 'Books#context',
	};

	# large or expensive documents: every ceiling raised deliberately
	graphql '/reports' => 'schema/reports.graphql', {
		resolvers           => { Query => 'Reports' },
		max_body            => 8 * 1024 * 1024,  # bytes, default 1 MiB
		max_cost            => 250_000,          # weighted, default 10_000
		default_list_size   => 100,              # unsized list, default 10
		max_depth           => 30,               # per execution
		max_nodes           => 20_000,           # per execution
		program_cache_max   => 2_000,            # compiled queries kept
		allow_introspection => 0,                # shut in production
	};

	package MyApp::Controller::Books;

	sub users {
		my ($root, $args, $ctx) = @_;
		return $ctx->{db}->users($args->{first});
	}

	sub context {
		my ($c) = @_;
		return ({ db => $c->db });
	}

	1;

Or declare the single endpoint at registration and skip the keyword
entirely:

	plugin 'GraphQL' => {
		path      => '/graphql',
		schema    => 'schema/app.graphql',
		resolvers => { Query => 'Books' },
	};

=head1 DESCRIPTION

This plugin serves GraphQL over HTTP from a L<Punk> application, executed
by L<GraphQL::Houtou>. Each declared endpoint compiles its schema and
native runtime once at register time - in the server parent, so the
compiled artifacts are shared copy-on-write across preforked workers -
and mounts a POST route through Punk's ordinary routing.

The request path is deliberately short. Punk's C dispatcher matches the
route; the request envelope is decoded by C<< $c->req->json >> through
the File::Raw::JSON C ABI; GraphQL::Houtou executes the query on its XS
VM and renders the response straight to UTF-8 JSON bytes; and the handler
returns those bytes as a PSGI triplet, which Punk's C finish path passes
through without re-encoding.

=head1 THE graphql KEYWORD

	graphql PATH => SCHEMA, \%options;
	graphql PATH => { schema => SCHEMA, %options };

C<use Punk::Plugin::GraphQL> installs the keyword into the calling Punk
application class. Either ordering works: declared before
C<plugin 'GraphQL'>, endpoints only record and everything expensive -
the SDL read, schema build, runtime compile, mounting - runs at
registration, in declaration order; declared after it, an endpoint
mounts at the declaration itself. A mismatch croaks at C<to_app> time:
endpoints declared but the plugin never registered, or the plugin
registered but no endpoint ever declared.

SCHEMA is one of:

=over 4

=item * a filename - read at register time and compiled as SDL

=item * an SDL string - anything containing a brace or newline

=item * a L<GraphQL::Houtou::Schema> object - used as-is; the
C<resolvers> option is rejected because resolvers cannot be attached to
an already built schema

=back

Multiple C<graphql> declarations mount independent endpoints, each with
its own schema and runtime.

=head1 OPTIONS

=over 4

=item resolvers

Hashref of resolver maps, keyed by type. Resolvers take the same targets
as Punk routes - a coderef, or a C<'Controller#method'> string resolved
against the application's C<::Controller::> namespace through the same
resolver the router uses, so a typo croaks at boot naming the class and
method:

	resolvers => {
		Query	=> 'Books',					# a controller class
		Mutation => { rename => 'Books#rename' },
		Pet	  => { resolve_type => 'Pets#kind' },
	},

A whole type may name a controller class (here
C<MyApp::Controller::Books>): every field the SDL declares on that type
which has a same-named method on the class is wired to it, fields
without one keep the default resolver, and a class matching no fields at
all croaks at boot. On abstract types the class's C<resolve_type>
method, if any, is wired as the type discriminator.

Resolver methods are called with GraphQL::Houtou's resolver signature -
C<($source, $args, $context, $info)> - not a route handler's C<($c)>;
the request context crosses over through the C<context> builder. The
resolved maps are passed to C<build_schema> - see
L<GraphQL::Houtou/"Building a schema from SDL">.

=item context

Coderef or C<'Controller#method'> target called once per request with
the L<Punk::Context>. Its return is
list-assigned as C<(context, on_stall)>: the first value becomes the
GraphQL execution context, the optional second is the batching hook that
flushes L<GraphQL::Houtou::DataLoader> instances. Create loaders inside
this builder - one per request - so their caches are request-scoped.

	context => sub {
		my ($c) = @_;
		my $users = GraphQL::Houtou::DataLoader->new(
			batch => sub { load_users($c->db, @{ $_[0] }) });
		return ({ db => $c->db, users => $users },
			GraphQL::Houtou::DataLoader->on_stall_for($users));
	},

=item guard

Coderef or C<'Controller#method'> target run before the handler, exactly
as Punk's C<under> guards work: a
reference return short-circuits the request with that response. The
GraphiQL page shares the guard.

=item graphiql

Boolean. When true, GET on the endpoint serves a GraphQL console - a
query editor with variables, a headers pane (a JSON object merged into
every request, so a guard's Authorization token or any custom header
reaches the server; the schema-docs introspection sends them too, with
a refresh control for after the token is pasted in), response pane, and
introspection-driven schema docs. The page is entirely self-contained:
its template,
stylesheet, and script ship in this distribution's assets directory,
are rendered once at boot through L<Template::Stencil>, and are served
from memory as one HTML page that loads nothing from anywhere else - no
CDN, no external requests. Leave it off in production, or put it behind
a C<guard>.

=item max_body

Request body size limit in bytes; oversize requests are refused with a
413 before the body is read. Default 1 MiB. C<0> disables the check.

=item max_cost, default_list_size, program_cache_max, async,
allow_introspection

Passed through to C<build_native_runtime> - see
L<GraphQL::Houtou/"Production query cost limits"> and
L<GraphQL::Houtou/"Declaring an async schema (async =E<gt> 1)">.
Resolvers that return L<Promise::XS> promises need C<< async => 1 >>.

=item max_depth, max_nodes

Passed through per execution as additional validation limits.

=item root_value

Passed through per execution as the root source value.

=back

=head1 THE WIRE CONTRACT

POST with a C<Content-Type> of C<application/json> (or
C<application/graphql-response+json>) and the standard envelope:

	{ "query": "...", "variables": {...}, "operationName": "..." }

Responses carry C<application/graphql-response+json> when the request's
C<Accept> asks for it, plain C<application/json> otherwise.

Status mapping, following the GraphQL over HTTP specification and
matching L<GraphQL::Houtou::PSGI>:

=over 4

=item * 200 - execution reached the schema; field errors, if any, ride
inside the response envelope

=item * 400 - request errors: malformed JSON, missing query, non-object
variables, and any errors-only GraphQL envelope (syntax, validation,
cost rejection, unknown operation)

=item * 413 - body larger than C<max_body>, refused before reading

=item * 415 - wrong content type

=item * 405 - wrong method, with an Allow header, from Punk's router

=item * 500 - the runtime died; details go to the log, not the client

=back

Note one engine contract this plugin papers over: GraphQL::Houtou's
runtime takes the operation name as C<operation_name> and silently
ignores the camelCase spelling, so the envelope's C<operationName> is
mapped explicitly.

=head1 METHODS

=head2 new

Plugin constructor, called by Punk's plugin loader.

=head2 register ($app, \%opts)

Builds and mounts every recorded endpoint. Options may also declare one
endpoint inline: C<< plugin 'GraphQL' => { path => '/graphql', schema =>
..., %options } >> is equivalent to a single C<graphql> keyword.

=head2 state_for ($class)

Introspection seam returning the internal per-application state, for
tests.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

