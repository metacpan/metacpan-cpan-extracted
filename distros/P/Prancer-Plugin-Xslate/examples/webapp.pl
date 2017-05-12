#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use File::Basename ();
use Plack::Runner;

sub main {
    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # this just returns a PSGI application. $psgi can be wrapped with
    # additional middleware before sending it along to Plack::Runner.
    my $psgi = Foo->new("${root}/foobar.yml")->to_psgi_app();

    # run the psgi app through Plack and send it everything from @ARGV. this
    # way Plack::Runner will get options like what listening port to use and
    # application server to use -- Starman, Twiggy, etc.
    my $runner = Plack::Runner->new();
    $runner->parse_options(@_);
    $runner->run($psgi);

    return;
}

main(@ARGV) unless caller;

package Foo;

use strict;
use warnings FATAL => 'all';

use File::Basename ();

use Prancer qw(config);

# load the template plugin
use Prancer::Plugin::Xslate qw(render);

sub initialize {
    my $self = shift;

    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # in here we get to initialize things!
    my $plugin = Prancer::Plugin::Xslate->load();
    $plugin->path($root);

    return;
}

sub handler {
	my ($self, $env, $request, $response, $session) = @_;

    sub (GET + /) {
        $response->header("Content-Type" => "text/html");
        $response->body(render("foobar.tx", {
            "foo" => "bar"
        }, {
            'function' => {
                'baz' => sub { return "barfoo"; },
            },
            'module' => [
                'Digest::SHA1' => ['sha1_hex'],
                'Data::Dumper'
            ]
        }));
        return $response->finalize(200);
    }
}

1;
