# ABSTRACT: ponapi CLI server runner
package PONAPI::CLI::RunServer;

use strict;
use warnings;

use Plack::Runner;
use Plack::Middleware::MethodOverride;
use PONAPI::Server;

use File::Temp  qw( tempdir );
use Path::Class qw( file );

use POSIX ();

$SIG{INT} = sub {
    print "demo server shutting down...\n";
    $SIG{INT} = sub { POSIX::_exit(0) };
    exit 0;
};

sub run {
    my $port = shift;

    my $dir = _create_dir();

    my $app = Plack::Middleware::MethodOverride->wrap(
        PONAPI::Server->new(
            'repository.class' => 'Test::PONAPI::Repository::MockDB',
            'ponapi.config_dir' => $dir
        )->to_app()
    );

    my $runner = Plack::Runner->new;
    $runner->parse_options( '-port', $port || 5000 );
    $runner->run($app);
}

sub _create_dir {
    my $dir  = tempdir( CLEANUP => 1 );

    my $conf = file( $dir . '/server.yml' );
    $conf->spew(<<"DEFAULT_CONF");
server:
  spec_version: "1.0"
  sort_allowed: "true"
  send_version_header: "true"
  send_document_self_link: "true"
  links_type: "relative"
  respond_to_updates_with_200: "false"

repository:
  class:  "Test::PONAPI::Repository::MockDB"
  args:   []
DEFAULT_CONF

    return $dir;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::CLI::RunServer - ponapi CLI server runner

=head1 VERSION

version 0.003001

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
