# NAME

Plack::App::GraphQL - Serve GraphQL from Plack / PSGI

https://travis-ci.org/jjn1056/Plack-App-GraphQL

# PROJECT STATUS
| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/jjn1056/Plack-App-GraphQL.svg?branch=master)](https://travis-ci.org/jjn1056/Plack-App-GraphQL) |
[![CPAN version](https://badge.fury.io/pl/Plack-App-GraphQL.svg)](https://metacpan.org/pod/Plack-App-GraphQL) 

# SYNOPSIS

    use Plack::App::GraphQL;

    my $schema = q|
      type Query {
        hello: String
      }
    |;

    my %root_value = (
      hello => 'Hello World!',
    );

    my $app = Plack::App::GraphQL
      ->new(schema => $schema, root_value => \%root_value)
      ->to_app;

Or mount under a given URL:

    use Plack::Builder;
    use Plack::App::GraphQL;

    # $schema and %root_value as above

    my $app = Plack::App::GraphQL
      ->new(schema => $schema, root_value => \%root_value)
      ->to_app;

    builder {
      mount "/graphql" => $app;
    };

You can also use the 'endpoint' configuration option to set a root path to match.
This is the most simple option if you application is not serving other endpoints
or applications (See documentation below).

# DESCRIPTION

Serve [GraphQL](https://metacpan.org/pod/GraphQL) with [Plack](https://metacpan.org/pod/Plack).

Please note this is an early access / minimal documentation release.  You should already
be familiar with [GraphQL](https://metacpan.org/pod/GraphQL).  There's some examples in `/examples` but few real test
cases.  If you are not comfortable using this based on reading the source code and
can't accept the possibility that the underlying code might change (although I expect
the configuration options are pretty set now) then you shouldn't use this. I recommend
looking at official plugins for Dancer and Mojolicious: [Dancer2::Plugin::GraphQL](https://metacpan.org/pod/Dancer2::Plugin::GraphQL),
[Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious::Plugin::GraphQL) instead (or you can send me patches :) ).

This currently doesn't support an asychronous responses until updates are made in 
core [GraphQL](https://metacpan.org/pod/GraphQL).

# CONFIGURATION

This [Plack](https://metacpan.org/pod/Plack) applications supports the following configuration arguments:

## schema

The [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema).  Canonically this should be an instance of [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema)
but if you pass a string or a filehandle, we will assume that it is a parse-able 
graphql SDL document that we can build a schema object from.  Makes for easy demos.

## root\_value

An object, hashref or coderef that field resolvers can use to look up requests.  Generally
the method or hash keys will match the query or mutation keys.  See the examples for
more.

## resolver

Used to change how field resolvers work.  See [GraphQL](https://metacpan.org/pod/GraphQL) (or ignore this since its likely
something you really don't need for normal work.

## convert

This takes a sub class of [GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert), such as [GraphQL::Plugin::Convert::DBIC](https://metacpan.org/pod/GraphQL::Plugin::Convert::DBIC).
Providing this will automatically provide ["schema"](#schema), ["root\_value"](#root_value) and ["resolver"](#resolver).

You can shortcut the value of this with a '+' and we will assume the default namespace.  For
example '+DBIC' is the same as 'GraphQL::Plugin::Convert::DBIC'.

## endpoint

The URI path part that is associated with the graphql API endpoint.  Often this is set to
'graphql'.  The default is '/'.  You might prefer to use a custom or alternative router
(for example [Plack::Builder](https://metacpan.org/pod/Plack::Builder)).

## context\_class

Default is [Plack::App::GraphQL::Context](https://metacpan.org/pod/Plack::App::GraphQL::Context).  This is an object that is passed as the 'context'
argument to your field resolvers.  You might wish to subclass this to add additional useful
methods such as simple access to a user object (if you you authentication for example).

## graphiql

Boolean that defaults to FALSE.  Turn this on to enable the HTML Interactive GraphQL query
screen.  Useful for leaning and debugging but you probably want it off in production.

**NOTE** If you want to use this you should also install [Template::Tiny](https://metacpan.org/pod/Template::Tiny) which is needed.  We
don't make [Template::Tiny](https://metacpan.org/pod/Template::Tiny) a dependency here so that you are not forced to install it where
you don't want the interactive screens (such as production).

## json\_encoder

Lets you specify the instance of the class used for JSON encoding / decoding.  The default is an
instance of [JSON::MaybeXS](https://metacpan.org/pod/JSON::MaybeXS) so you will want to be sure install a fast JSON de/encoder in production,
such as [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel::JSON::XS) (it will default to a pure Perl one which might not need your speed 
requirements).

## exceptions\_class

Class that provides the exception responses.  Override the default ([Plack::App::GraphQL::Exceptions](https://metacpan.org/pod/Plack::App::GraphQL::Exceptions))
if you want complete control over how your errors look.

# METHODS

       TBD
    

# AUTHOR

John Napiorkowski <jnapiork@cpan.org>

# SEE ALSO

[GraphQL](https://metacpan.org/pod/GraphQL), [Plack](https://metacpan.org/pod/Plack)

# COPYRIGHT

Copyright (c) 2019 by "AUTHOR" as listed above.

# LICENSE

This library is free software and may be distributed under the same terms as perl itself.
