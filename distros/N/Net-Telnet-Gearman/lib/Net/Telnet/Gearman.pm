package Net::Telnet::Gearman;

use strict;
use warnings;
use base qw/Net::Telnet/;
use Net::Telnet::Gearman::Worker;
use Net::Telnet::Gearman::Function;

our $VERSION = '0.05000';

=head1 NAME

Net::Telnet::Gearman - interact with a Gearman server through its telnet interface

=head1 SYNOPSIS

    use Net::Telnet::Gearman;

    my $session = Net::Telnet::Gearman->new(
        Host => '127.0.0.1',
        Port => 4730,
    );

    my @workers   = $session->workers();
    my @functions = $session->status();
    my $version   = $session->version();
    my $result    = $session->maxqueue( reverse => 15 );

    $session->shutdown('graceful');

=head1 DESCRIPTION

This is currently only tested with Gearman v0.10.

=head1 METHODS

=head2 new

This is the same as in L<Net::Telnet> except for that there is
called C<< $self->open() >> for you.

=cut

sub new {
    my $class = shift;

    # There's a new cmd_prompt in town.
    my $self = $class->SUPER::new(@_) or return;

    $self->open();

    return $self;
}

=head2 workers

This sends back a list of all workers, their file descriptors,
their IPs, their IDs, and a list of registered functions they can
perform.

See also: L<Net::Telnet::Gearman::Worker>

This method accepts any parameters the L<Net::Telnet> C<getline>
method does accept.

=cut

sub workers {
    my ($self, @args) = @_;

    $self->print('workers');

    my @workers = ();

    while ( my $line = $self->getline(@args) ) {
        last if $line eq ".\n";

        push @workers, Net::Telnet::Gearman::Worker->parse_line($line);
    }

    return wantarray ? @workers : \@workers;
}

=head2 status

This sends back a list of all registered functions. Next to
each function is the number of jobs in the queue, the number of
running jobs, and the number of capable workers.

See also: L<Net::Telnet::Gearman::Function>

This method accepts any parameters the L<Net::Telnet> C<getline>
method does accept.

=cut

sub status {
    my ($self, @args) = @_;

    $self->print('status');

    my @functions = ();

    while ( my $line = $self->getline(@args) ) {
        last if $line eq ".\n";

        next unless my $row = Net::Telnet::Gearman::Function->parse_line($line);

        push @functions, $row;
    }

    return wantarray ? @functions : \@functions;
}

=head2 maxqueue

This sets the maximum queue size for a function. If no size is
given, the default is used. If the size is negative, then the queue
is set to be unlimited. This sends back a single line with "OK".

Arguments:

=over 4

=item * Function name

=item * Maximum queue size (optional)

=back

=cut

sub maxqueue {
    my ( $self, @args ) = @_;
    unshift @args, 'maxqueue';
    return $self->_print_and_getline(@args);
}

=head2 shutdown

Shutdown the server. If the optional "graceful" argument is used,
close the listening socket and let all existing connections
complete.

Arguments:

=over 4

=item * "graceful" (optional)

=back

=cut

sub shutdown {
    my ( $self, $graceful ) = @_;
    my @args = ('shutdown');
    push @args, 'graceful' if $graceful;
    return $self->_print_and_getline(@args);
}

=head2 version

Send back the version of the server.

=cut

sub version {
    my ($self) = @_;
    return $self->_print_and_getline('version');
}

sub _print_and_getline {
    my ( $self, @args ) = @_;
    $self->print( join ' ', @args );
    my $line = $self->getline();
    chomp $line;
    return $line;
}

=head1 AUTHOR

Johannes Plunien E<lt>plu@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Johannes Plunien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4 

=item * L<Net::Telnet>

=item * L<http://gearman.org/index.php?id=protocol>

=back

=head1 REPOSITORY

L<http://github.com/plu/net-telnet-gearman/>

=cut

1;
