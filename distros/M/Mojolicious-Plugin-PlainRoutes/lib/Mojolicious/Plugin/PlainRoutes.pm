use 5.014;
package Mojolicious::Plugin::PlainRoutes;
# ABSTRACT: Plaintext route definitions for Mojolicious
$Mojolicious::Plugin::PlainRoutes::VERSION = '0.06';
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/decamelize/;

has autoname => 0;

sub register {
	my ($self, $app, $conf) = @_;

	$self->autoname($conf->{autoname});

	$conf->{file} //= $app->home->rel_file("lib/".$app->moniker.".routes");

	open my $fh, '<:encoding(UTF-8)', $conf->{file};
	my $tree = $self->tokenise($fh);
	close $fh;

	$self->process($app->routes, $tree);
}

sub tokenise {
	my ($self, $input) = @_;

	if (ref $input eq 'GLOB') {
		$input = do { local $/; <$input> };
	} elsif (ref $input) {
		Carp::carp "Non-filehandle reference passed to tokenise";
		return [];
	}

	return $self->_tokenise($input);
}

sub _tokenise {
	my ($self, $input) = @_;

	$input =~ s/\r\n/\n/g;
	$input =~ s/\n\r/\n/g;
	$input =~ s/\r/\n/g;

	my %grammar = (
		comment    => qr{ \# [^\n]* }x,
		verb       => qr{ ANY | DELETE | GET | PATCH | POST | PUT }x,
		path       => qr{ / [^#\s]* }x,
		arrow      => qr{ -> }x,
		scope      => qr( { | } )x,
		action     => qr{ [\w\-:]* \. \w* }x,
		name       => qr{ \( [^)]+ \) }x,
		eol        => qr{ \n }x,
		space      => qr{ [^\S\n]+ }x,
	);

	my @words = grep { defined && length }
	              split m{( $grammar{comment}
	                      | $grammar{verb}
	                      | $grammar{path}
	                      | $grammar{arrow}
	                      | $grammar{scope}
	                      | $grammar{action}
	                      | $grammar{name}
	                      | $grammar{eol}
	                      | $grammar{space}
	                      )}x, $input;

	# Include the lexical category with the word, e.g., map:
	#   "/foo" -> { text => "/foo", category => "path" }
	my @annotated_words;
	for my $word (@words) {
		my @cats = grep { $word =~ /^$grammar{$_}$/ } keys %grammar;

		if (@cats > 1) {
			warn "$word has multiple lexical categories: @cats";
		}

		push @annotated_words, { text => $word, category => $cats[0] // '' };
	}

	# Add special EOF word to act as a clause terminator if necessary
	push @annotated_words, { text => '', category => 'eof' };

	# Initialise
	my $root    = [];
	my @nodes   = ($root);
	my %clause  = ();
	my $context = 'default';

	# Track for helpful error messages
	my $col = 1;
	my $line = 1;
	my $error = 0;

	# Define outside the loop scope so that the closure can access it
	my %word;

	# Called whenever a syntax error is encountered.
	my $syntax_error = sub {
		$error = 1;
		my $_col = $col - length $word{text};
		print STDERR qq{Syntax error in routes on line $line, col $_col: }
		          .  qq{"$word{text}" (expected a @_)\n};
	};

	for (@annotated_words) {
		%word = %$_;
		$col += length $word{text};
		if ($word{category} eq 'eol') {
			$line += 1;
			$col = 1;
		}

		# While in comment context, the parser checks for newlines and
		# otherwise does nothing.
		if ($context eq 'comment') {
			if ($word{category} eq 'eol') {
				$context = 'default';
			}
		}

		# The comment indicator puts the parser into comment context and
		# otherwise does nothing.
		elsif ($word{category} eq 'comment') {
			$context = 'comment';
		}

		# Whitespace is ignored
		elsif ($word{category} eq 'space' || $word{category} eq 'eol') {}

		# First word in clause must be a HTTP verb
		elsif (!exists $clause{verb}) {
			if ($word{category} eq 'verb') {
				$clause{verb} = $word{text};
			}

			# The end of scope may be encountered here if there were two ends
			# of scope in a row.
			elsif ($word{category} eq 'scope' && $word{text} eq '}') {
				if (@nodes == 1) {
					'verb'->$syntax_error;
				} else {
					pop @nodes;
				}
			}

			# It's possible we encounter the EOF word here if we just
			# encountered the end of a scope (or if the input is empty).
			# Anything else is still a syntax error.
			elsif ($word{category} ne 'eof') {
				'verb'->$syntax_error;
			}
		}

		# Second word must be a path part
		elsif (!exists $clause{path}) {
			if ($word{category} eq 'path') {
				$clause{path} = $word{text};
			} else {
				'path'->$syntax_error;
			}
		}

		# Third word must be an action, optionally preceded by an arrow (->)
		elsif (!exists $clause{action}) {
			if (!exists $clause{arrow} && $word{category} eq 'arrow') {
				$clause{arrow} = 1;
			} elsif ($word{category} eq 'action') {
				my ($action, $controller) = split /\./, $word{text};
				$clause{action} = decamelize($action) . "#$controller";

				# The clause needn't carry this useless information after this
				# point.
				delete $clause{arrow};
			} else {
				'action'->$syntax_error;
			}
		}

		# The final word should be some kind of terminator: scope indicators,
		# the beginning of a new clause (i.e., a verb), or the end of input.
		else {
			# An optional name for the clause can be appended before the
			# terminator.
			if (!exists $clause{name} && $word{category} eq 'name') {
				$clause{name} = $word{text} =~ s/ ^\( | \)$ //xgr;
			}

			# The clause is terminated by a new scope.
			elsif ($word{category} eq 'scope') {
				# A new scope means that the preceding clause is a bridge, and
				# therefore the head of a new branch in the tree.
				if ($word{text} eq '{') {
					my $newNode = [ { %clause } ];
					push @{ $nodes[-1] }, $newNode;
					push @nodes, $newNode;

					%clause = ();
				}

				# The end of a scope means that the preceding clause is the
				# last clause in a bridge.
				elsif ($word{text} eq '}') {
					push @{ $nodes[-1] }, { %clause };
					%clause = ();

					# Can't exit a scope if we haven't entered one
					if (@nodes == 1) {
						'verb'->$syntax_error;
					} else {
						pop @nodes;
					}
				}
			}

			# The clause is terminated by the start of a new one
			elsif ($word{category} eq 'verb') {
				push @{ $nodes[-1] }, { %clause };
				%clause = ( verb => $word{text} );
			}

			# Last chance, the clause is terminated by eof
			elsif ($word{category} eq 'eof') {
				push @{ $nodes[-1] }, { %clause };
				%clause = ();
			}

			else {
				'terminator'->$syntax_error;
			}
		}
	}

	if (@nodes != 1) {
		'verb or end of scope'->$syntax_error;
	}

	if ($error) {
		Carp::croak "Parsing routes failed due to syntax errors";
	}

	$root;
}

sub process {
	my ($self, $bridge, $tree) = @_;

	for my $node (@$tree) {
		my $token = ref $node eq 'ARRAY' ? shift @$node : $node;

		my $route = $bridge->route($token->{path})
		                   ->to($token->{action});
		if ($token->{verb} ne 'ANY') {
			$route->via($token->{verb});
		}

		my $p = $route->pattern;
		if (exists $token->{name}) {
			$route->name($token->{name});
		}
		elsif (ref $self->autoname eq 'CODE') {
			my $name = $self->autoname->($route->via->[0], $p->unparsed,
				@{$p->defaults}{qw/controller action/});

			if (ref $name) {
				Carp::croak "Autoname callback did not return a string";
			}

			$route->name($name);
		}
		elsif ($self->autoname) {
			$route->name(join '-', @{$p->defaults}{qw/controller action/});
		}

		if (ref $node eq 'ARRAY') {
			$route->inline(1);
			$self->process($route, $node);
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::PlainRoutes - Plaintext route definitions for Mojolicious

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In lib/MyApp.pm:

    sub startup {
        ...
        $self->plugin('PlainRoutes');
        ...
    }

In lib/myapp.routes:

    # Routes file for MyApp.pm
    ANY / -> Foo.do {
        GET /bar -> Foo.bar
        ANY /baz -> Foo.baz {
            GET /quux -> Foo.quux
        }
    }

    GET /foo/bar/baz/quux -> Foo::Bar::Baz.quux (fbb-quux)

=head1 DESCRIPTION

Routes are defined as an HTTP verb, followed by a path, followed by a
controller/action pair. (The arrow is optional.) An optional name for the
route can be appended with parentheses.

If a route is followed by braces, then it will act as a bridge for the
contained routes.

Anything following a "#" is a comment until the end of the line, as in Perl.

=head1 CONFIGURATION

    $self->plugin('PlainRoutes', {
        # Specify the path of the routes file
        file => $self->home->rel_file('path/to/myapp.routes'),

        # Get automatic names for routes of the form "controller-action"
        autoname => 1,

        # or do it with a callback
        autoname => sub {
            my ($verb, $path, $controller, $action) = @_;
            return "$controller-$action";
        },
    });

=head1 SUPPORT

Use the issue tracker on the Github repository for bugs/feature requests:

    https://github.com/RogerDodger/Mojolicious-Plugin-PlainRoutes/issues

=head1 AUTHOR

Cameron Thornton <cthor@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cameron Thornton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
