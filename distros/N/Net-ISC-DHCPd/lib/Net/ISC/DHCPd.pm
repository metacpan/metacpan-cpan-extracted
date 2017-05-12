package Net::ISC::DHCPd;

=head1 NAME

Net::ISC::DHCPd - Interacts with ISC DHCPd

=head1 VERSION

0.1709

=head1 SYNOPSIS

    my $dhcpd = Net::ISC::DHCPd->new(
                    config => { file => "path/to/config" },
                    leases => { file => "path/to/leases" },
                    omapi => { key => "some key" },
                );

    $dhcpd->config->parse;

See the tests bundled to this distribution for more examples.

=head1 DESCRIPTION

This namespace contains three semi-separate projects, which this module
binds together: L<dhcpd.conf|Net::ISC::DHCPd::Config>,
L<dhcpd.leases|Net::ISC::DHCPd::Leases> and L<omapi|Net::ISC::DHCPd::OMAPI>.
It is written with L<Moose> which provides classes and roles to represents
things like a host, a lease or any other thing.

The distribution as a whole is targeted an audience who configure and/or
analyze the L<Internet Systems Consortium DHCP Server|http://www.isc.org/software/dhcp>.
If you are not familiar with the server, check out
L<the man pages|http://www.google.com/search?q=man+dhcpd>.

=cut

use Class::Load 0.20;
use Moose 0.90;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class 0.05 qw(File);
use Net::ISC::DHCPd::Types ':all';
use File::Temp 0.20;
use v5.10.1;

our $VERSION = eval '0.1709';

=head1 ATTRIBUTES

=head2 config

This attribute holds a read-only L<Net::ISC::DHCPd::Config> object.
It can be set from the constructor, using either an object or a hash-ref.
The hash-ref will then be passed on to the constructor.

=cut

has config => (
    is => 'ro',
    isa => ConfigObject,
    coerce => 1,
    lazy_build => 1,
);

__PACKAGE__->meta->add_method(_build_config => sub { _build_child_obj(Config => @_) });

=head2 leases

This attribute holds a read-only L<Net::ISC::DHCPd::Leases> object.
It can be set from the constructor, using either an object or a hash-ref.
The hash-ref will then be passed on to the constructor.

=cut

has leases => (
    is => 'ro',
    isa => LeasesObject,
    coerce => 1,
    lazy_build => 1,
);

__PACKAGE__->meta->add_method(_build_leases => sub { _build_child_obj(Leases => @_) });

=head2 omapi

This attribute holds a read-only L<Net::ISC::DHCPd::OMAPI> object.
It can be set from the constructor, using either an object or a hash-ref.
The hash-ref will then be passed on to the constructor.

=cut

has omapi => (
    is => 'ro',
    isa => OMAPIObject,
    coerce => 1,
    lazy_build => 1,
);

__PACKAGE__->meta->add_method(_build_omapi => sub { _build_child_obj(OMAPI => @_) });

=head2 binary

This attribute holds a L<Path::Class::File> object to the dhcpd binary.
It is read-only and the default is "dhcpd3".

=cut

has binary => (
    is => 'ro',
    isa => File,
    coerce => 1,
    default => 'dhcpd3',
);

=head2 errstr

Holds the last know error as a plain string.  This only applies to OMAPI.

=cut

has errstr => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

=head1 METHODS

=head2 parse

 $config->parse;

This parses the config file or the leases file.

=cut

=head2 generate

 print $config->generate;

This generates a copy of the config file in plaintext.

=cut


=head2 test

 $bool = $self->test("config");
 $bool = $self->test("leases");

Will test either the config or leases file. It returns a boolean value
which indicates if it is valid or not: True means it is valid, while
false means it is invalid. Check L</errstr> on failure - it will contain
a descriptive string from either this module, C<$!> or the exit value
(integer stored as a string).

=cut

sub test {
    my $self = shift;
    my $what = shift || q();
    my($child_error, $errno, $output);

    if($what eq 'config') {
        my $tmp = File::Temp->new;
        print $tmp $self->config->generate;
        $output = $self->_run('-t', '-cf', $tmp->filename);
        ($child_error, $errno) = ($?, $!);
    }
    elsif($what eq 'leases') {
        $output = $self->_run('-t', '-lf', $self->leases->file);
        ($child_error, $errno) = ($?, $!);
    }
    else {
        $self->errstr('Invalid argument');
        return;
    }

    # let's set this anyway...
    $self->errstr($output);

    if($child_error and $child_error == -1) {
        $self->errstr($errno);
        ($!, $?) = ($errno, $child_error);
        return;
    }
    elsif($child_error) {
        ($!, $?) = ($errno, $child_error);
        return;
    }

    return 1;
}

sub _run {
    my $self = shift;
    my @args = @_;

    pipe my $reader, my $writer or return '';

    if(my $pid = fork) { # parent
        close $writer;
        wait; # for child process...
        local $/;
        return readline $reader;
    }
    elsif(defined $pid) { # child
        close $reader;
        open STDERR, '>&', $writer or confess $!;
        open STDOUT, '>&', $writer or confess $!;
        { exec $self->binary, @args }
        confess "Exec() failed";
    }

    return ''; # fork failed. check $!
}

# used from attributes
sub _build_child_obj {
    my $type = shift;
    my $self = shift;

    Class::Load::load_class("Net::ISC::DHCPd::$type");

    return "Net::ISC::DHCPd::$type"->new(@_);
}

=head1 SEE ALSO

=over 8

=item Net::DHCP::Info

C<Net::DHCP::Info> an older dhcpd.leases and dhcpd.conf parser, also written
by Jan Henning Thorsen.  It has many limitations that these modules address.

=item kea.isc.org

C<kea.isc.org> a replacement DHCP server from ISC that is high-performance and
supports an API and on-line configuration directly.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-isc-dhcpd at rt.cpan.org>, or through the web interface at
L<https://github.com/jhthorsen/net-isc-dhcpd/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen, C<< <jhthorsen at cpan.org> >>

=head1 MAINTAINER

Robert Drake, C<< <rdrake at cpan.org> >>

=head1 CONTRIBUTORS

Nito Martinez

Alexey Illarionov

Patrick

napetrov

zoffixznet

Bossi

=cut
__PACKAGE__->meta->make_immutable;
1;
