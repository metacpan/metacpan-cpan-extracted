
package Role::Log::Syslog::Fast;

use strict;
use Moose::Role;
use Log::Syslog::Fast 0.55 ':all';
use List::Util qw(first);

# ABSTRACT: A Logging role for Moose on Log::Syslog::Fast
our $VERSION = '0.14'; # VERSION

has '_proto' => (
    is      => 'rw',
    isa     => 'Int',
    default => LOG_UNIX
);

has '_hostname' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $options = [ '/dev/log', '/dev/klog', '/var/run/syslog' ];
        my $found = first {-r} @$options;
        return $found if $found;
    }
);

has '_port' => (
    is      => 'rw',
    isa     => 'Int',
    default => 514
);

has '_facility' => (
    is      => 'rw',
    isa     => 'Int',
    default => LOG_LOCAL0
);

has '_severity' => (
    is      => 'rw',
    isa     => 'Int',
    default => LOG_INFO
);

has '_sender' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'localhost'
);

has '_name' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'MooseX-Log-Syslog-Fast'
);

has '_logger' => (
    is      => 'ro',
    isa     => 'Log::Syslog::Fast',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Log::Syslog::Fast->new(
            $self->_proto,    $self->_hostname, $self->_port, $self->_facility,
            $self->_severity, $self->_sender,   $self->_name
        );
    }
);

sub log {
    my ( $self, $msg, $time ) = @_;
    return $time ? $self->_logger->send( $msg, $time ) : $self->_logger->send($msg);
}

1;



=pod

=head1 NAME

Role::Log::Syslog::Fast - A Logging role for Moose on Log::Syslog::Fast

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    {
        package ExampleLog;

        use Moose;
        with 'Role::Log::Syslog::Fast';

        sub BUILD {
            my $self = shift;
            $self->_hostname('/var/run/syslog');
            $self->_name('Example');
        }

        sub test {
            my $self = shift;
            $self->log('foo');
        }

    }

    my $obj = new ExampleLog;

    $obj->test;

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Syslog::Fast> for use with L<Moose> classes.

=head1 METHOD

=head2 log

(message, [time])

=head1 SEE ALSO

L<Log::Syslog::Fast>, L<Log::Syslog>, L<Moose>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to bug-moosex-log-syslog-fast@rt.cpan.org, or through the web interface at http://rt.cpan.org.

Or come bother us in #moose on irc.perl.org.

=head1 AUTHOR

Thiago Rondon <thiago@aware.com.br>

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Thiago Rondon <thiago@nsms.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Thiago Rondon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__



1;



