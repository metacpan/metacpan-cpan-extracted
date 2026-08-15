package Punk::GraphQL;

use 5.024;
use strict;
use warnings;

our $VERSION = '0.01';

use Punk::Plugin::GraphQL ();

1;

__END__

=head1 NAME

Punk::GraphQL - GraphQL endpoints for Punk applications

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	package MyApp;
	use Punk;
	use Punk::Plugin::GraphQL;

	plugin 'GraphQL';

	graphql '/graphql' => 'schema/app.graphql', {
		resolvers => {
			Query    => 'Books',              # MyApp::Controller::Books
			Mutation => { rename => 'Books#rename' },
		},
		context  => 'Books#context',
		guard    => 'Auth#user',
		graphiql => 1,
	};

	# resolvers take the same targets as routes - 'Controller#method'
	# strings or coderefs - and a whole type may name a controller
	# class, wiring every field with a same-named method:

	package MyApp::Controller::Books;

	sub user {
		my ($root, $args, $ctx) = @_;
		return $ctx->{db}->user($args->{id});
	}

	sub context {
		my ($c) = @_;
		return ({ db => $c->db });
	}

	1;

	# app.psgi
	MyApp->to_app;

=head1 DESCRIPTION

Punk::GraphQL mounts a GraphQL-over-HTTP endpoint into a L<Punk>
application, executing requests through L<GraphQL::Houtou>, an XS-first
GraphQL parser and native-VM runtime.

=head1 SEE ALSO

L<Punk::Plugin::GraphQL> - the plugin, keyword, and handler reference

L<GraphQL::Houtou> - the execution engine

L<Punk> - the web framework

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
