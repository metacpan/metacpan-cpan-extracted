package Net::SSH::Mechanize::ConnectParams;
use Moose;

our $VERSION = '0.1.3'; # VERSION

has 'host' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

has 'user' => (
    isa => 'Str',
    is => 'rw',
);

has 'password' => (
    isa => 'Str',
    is => 'rw',
    predicate => 'has_password',
);

has 'port' => (
    isa => 'Int',
    is => 'rw',
    default => 22,
);

sub ssh_cmd {
    my $self = shift;

    my @cmd = ('-t', $self->host, 'sh');

    unshift @cmd, defined $self->user? ('-l', $self->user) : ();
    unshift @cmd, defined $self->port? ('-p', $self->port) : ();
    unshift @cmd, '/usr/bin/ssh';
    return @cmd;
}



__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Net::SSH::Mechanize::ConnectParams - encapsulates information about an ssh connection

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

This class is just a container for log-in details with a method which
constructs an approprate C<ssh> command invocation.

This equates to C</usr/bin/ssh -t somewhere.com sh>:

    my $minimal_params = Net::SSH::Mechanize::ConnectParams->new(
        host => 'somewhere.com',
    );

This equates to C</usr/bin/ssh -l someone -p 999 -t somewhere.com sh>:

    my $all_params = Net::SSH::Mechanize::ConnectParams->new(
        host => 'somewhere.com',
        user => 'someone',
        port => 999,
        password => 'secret',
    );

=head1 CLASS METHODS

=head2 C<< $obj = $class->new(%parameters) >>

Creates a new instance.  Parameters is a hash or a list of key-value
parameters.  Valid parameter keys are:

=over 4

=item C<host>

The hostname to connect to (a scalar string).  Either this or C<connection_params> must
be supplied.

=item C<user>

The name of the user account to log into (a scalar string).  If not
given, no user will be supplied to C<ssh> (this typically means it
will use the current user as default).

=item C<port>

The port to connect to (a positive scalar integer; C<ssh> will default
to 22 if this is not specificed).

=item C<password>

The password to connect with (a scalar string).  This is only required
if authentication will be performed, either on log-in or when sudoing.

=back

=head1 INSTANCE ATTRIBUTES

=head2 C<< $obj->host >>
=head2 C<< $obj->user >>
=head2 C<< $obj->password >>
=head2 C<< $obj->port >>

These are all read-write accessors for the attribute parameters
accepted by the constructor.

=head1 INSTANCE METHODS

=head2 C<< $cmd = $obj->ssh_cmd >>

This constructs the C<ssh> command to invoke.  If you need something
different, you can create a subclass which overrides this method, and
pass that via the C<connection_params> parameter to
C<< Net::SSH::Mechanize->new() >>.


=head1 AUTHOR

Nick Stokoe  C<< <wulee@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Nick Stokoe C<< <wulee@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
