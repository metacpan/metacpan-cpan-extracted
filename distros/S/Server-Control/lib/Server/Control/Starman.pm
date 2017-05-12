package Server::Control::Starman;
BEGIN {
  $Server::Control::Starman::VERSION = '0.20';
}
use File::Slurp qw(read_file);
use File::Which qw(which);
use Log::Any qw($log);
use Moose;
use strict;
use warnings;

extends 'Server::Control';

has '+binary_name'   => ( is => 'ro', isa => 'Str', default => 'starman' );
has 'app_psgi'       => ( is => 'ro', required => 1 );
has 'options'        => ( is => 'ro', required => 1, isa => 'HashRef' );
has 'options_string' => ( is => 'ro', init_arg => undef, lazy_build => 1 );

sub BUILD {
    my ( $self, $params ) = @_;

    $self->{params} = $params;
}

sub _build_options_string {
    my $self    = shift;
    my %options = %{ $self->{options} };
    return join(
        ' ',
        (
            map { sprintf( "--%s %s", _underscore_to_dash($_), $options{$_} ) }
              keys(%options)
        ),
        "--daemonize",
        "--preload-app"
    );
}

sub _underscore_to_dash {
    my ($str) = @_;
    $str =~ s/_/-/g;
    return $str;
}

override _build_error_log => sub {
    my $self = shift;
    return $self->options->{error_log} || super();
};

override _build_pid_file => sub {
    my $self = shift;
    return $self->options->{pid} || super();
};

override _build_port => sub {
    my $self = shift;
    return $self->options->{port} || super();
};

sub do_start {
    my $self = shift;

    $self->run_system_command(
        sprintf( '%s %s %s',
            $self->binary_path, $self->options_string, $self->app_psgi )
    );
}

# HACK - starman does not show up in Proc::ProcessTable on Linux for some reason!
# Fall back to using /proc directly.
#
sub _find_process {
    my ( $self, $pid ) = @_;

    if ( $^O eq 'linux' ) {
        my $procdir = "/proc/$pid";
        if ( -d $procdir ) {
            my $proc = bless( { pid => $pid, uid => ( stat($procdir) )[4] },
                'Proc::ProcessTable::Process' );
            return $proc;
        }
        return undef;
    }
    else {
        return $self->SUPER::_find_process($pid);
    }
}

__PACKAGE__->meta->make_immutable();

1;




=pod

=head1 NAME

Server::Control::Starman -- Control Starman

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use Server::Control::Starman;

    my $starman = Server::Control::Starman->new(
        binary_path => '/usr/local/bin/starman'
        options => {
            port      => 123,
            error_log => '/path/to/error.log',
            pid       => '/path/to/starman.pid'
        },
    );
    if ( !$starman->is_running() ) {
        $starman->start();
    }

=head1 DESCRIPTION

Server::Control::Starman is a subclass of L<Server::Control|Server::Control>
for L<Starman|Starman> processes.

=head1 CONSTRUCTOR

In addition to the constructor options described in
L<Server::Control|Server::Control>:

=over

=item app_psgi

Path to app.psgi; required.

=item options

Options to pass to the starman binary; required. Possible keys include:
C<listen>, C<host>, C<port>, C<workers>, C<backlog>, C<max_requests>, C<user>,
C<group>, C<pid>, and C<error_log>. Underscores are converted to dashes before
passing to starman.

C<--daemonize> and C<--preload-app> are automatically passed to starman; the
only current way to change this is by subclassing and overriding
C<_build_options_string>.

In addition, the C<error_log>, C<pid>, and C<port> options, if given, will be
used to populate the corresponding Server::Control parameters
(L<error_log|Server::Control/error_log>, L<pid_file|Server::Control/pid_file>,
and L<port|Server::Control/port>).

e.g. this

    options => {
        port      => 123,
        error_log => '/path/to/error.log',
        max_requests => 100,
        pid       => '/path/to/starman.pid'
    }

will result in command line options

    --port 123 --error-log /path/to/error.log --max-requests 100
    --pid /path/to/starman.pid --daemonize --preload-app

=back

=head1 SEE ALSO

L<Server::Control|Server::Control>, L<Starman|Starman>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

