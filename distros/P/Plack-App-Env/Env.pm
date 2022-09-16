package Plack::App::Env;

use base qw(Plack::Component);
use strict;
use warnings;

use Data::Printer;

our $VERSION = 0.09;

sub call {
	my ($self, $env) = @_;

	my $env_output;
	p $env, 'output' => \$env_output;

	return [
		200,
		['Content-Type' => 'text/plain'],
		[$env_output],
	];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::App::Env - Plack Env dump application.

=head1 SYNOPSIS

 use Plack::App::Env;

 my $obj = Plack::App::Env->new(%parameters);
 my $psgi_ar = $obj->call($env);
 my $app = $obj->to_app;

=head1 METHODS

=head2 C<new>

 my $obj = Plack::App::Env->new(%parameters);

Constructor.

Returns instance of object.

=head2 C<call>

 my $psgi_ar = $obj->call($env);

Implementation of env dump.

Returns reference to array (PSGI structure).

=head2 C<to_app>

 my $app = $obj->to_app;

Creates Plack application.

Returns Plack::Component object.

=head1 EXAMPLE

=for comment filename=plack_app_env.pl

 use strict;
 use warnings;

 use Plack::App::Env;
 use Plack::Runner;

 # Run application.
 my $app = Plack::App::Env->new->to_app;
 Plack::Runner->new->run($app);

 # Output:
 # HTTP::Server::PSGI: Accepting connections at http://0:5000/

 # > curl http://localhost:5000/
 # \ {
 #     HTTP_ACCEPT            "*/*",
 #     HTTP_HOST              "localhost:5000",
 #     HTTP_USER_AGENT        "curl/7.64.0",
 #     PATH_INFO              "/",
 #     psgi.errors            *main::STDERR  (read/write, layers: unix perlio),
 #     psgi.input             *HTTP::Server::PSGI::$input  (layers: scalar),
 #     psgi.multiprocess      "",
 #     psgi.multithread       "",
 #     psgi.nonblocking       "",
 #     psgi.run_once          "",
 #     psgi.streaming         1,
 #     psgi.url_scheme        "http",
 #     psgi.version           [
 #         [0] 1,
 #         [1] 1
 #     ],
 #     psgix.harakiri         1,
 #     psgix.input.buffered   1,
 #     psgix.io               *Symbol::GEN1  (read/write, layers: unix perlio),
 #     QUERY_STRING           "",
 #     REMOTE_ADDR            "127.0.0.1",
 #     REMOTE_PORT            39562,
 #     REQUEST_METHOD         "GET",
 #     REQUEST_URI            "/",
 #     SCRIPT_NAME            "",
 #     SERVER_NAME            0,
 #     SERVER_PORT            5000,
 #     SERVER_PROTOCOL        "HTTP/1.1"
 # }

=head1 DEPENDENCIES

L<Data::Printer>,
L<Plack::Component>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-App-Env>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.09

=cut
