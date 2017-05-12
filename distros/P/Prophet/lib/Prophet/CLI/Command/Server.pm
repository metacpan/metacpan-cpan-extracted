package Prophet::CLI::Command::Server;
{
  $Prophet::CLI::Command::Server::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::CLI::Command';

has server => (
    is      => 'rw',
    isa     => 'Maybe[Prophet::Server]',
    default => sub {
        my $self = shift;
        return $self->setup_server();
    },
    lazy => 1,
);

sub ARG_TRANSLATIONS {
    shift->SUPER::ARG_TRANSLATIONS(), p => 'port', w => 'writable';
}

use Prophet::Server;

sub usage_msg {
    my $self = shift;
    my ( $cmd, $subcmd ) = $self->get_cmd_and_subcmd_names( no_type => 1 );

    return <<"END_USAGE";
usage: ${cmd}${subcmd} [--port <number>]
END_USAGE
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    Prophet::CLI->end_pager();
    $self->server->run;
}

sub setup_server {
    my $self = shift;

    my $server_class = ref( $self->app_handle ) . "::Server";
    if ( !$self->app_handle->try_to_require($server_class) ) {
        $server_class = "Prophet::Server";
    }
    my $server;
    if ( $self->has_arg('port') ) {
        $server = $server_class->new(
            app_handle => $self->app_handle,
            port       => $self->arg('port')
        );
    } else {
        $server = $server_class->new( app_handle => $self->app_handle );
    }
    return $server;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Server

=head1 VERSION

version 0.751

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
