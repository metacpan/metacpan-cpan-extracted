use strict;
use warnings;

package Net::FTP::Mock;
BEGIN {
  $Net::FTP::Mock::VERSION = '0.103300';
}

# ABSTRACT: test code using Net::FTP without having an FTP server


use Moose;

use File::Copy 'copy';

{
    my $servers;
    sub servers {
        return $servers if @_ < 2;
        $servers = $_[1];
    }
}

has host => ( isa => 'Str', is => 'ro', required => 1, initializer => '_check_host' );
has user => ( is => 'rw', isa => 'Str' );
has pass => ( is => 'rw', isa => 'Str' );
has message => ( is => 'rw', isa => 'Str' );
has _account => ( is => 'rw', isa => 'HashRef', lazy => 1, builder => '_get_account' );
has root => ( is => 'rw', isa => 'Str', lazy => 1, default => sub { $_[0]->_account->{root} } );
has code => ( is => 'rw', isa => 'Int' );


sub Net::FTP::new {
    my ( undef, @args ) = @_;

    my $ftp = Net::FTP::Mock->new( host => @args );
    return $ftp if !$ftp->message;

    $@ = $ftp->message;
    return;
}


sub import {
    my ( $self , %args ) = @_;

    $INC{'Net/FTP.pm'} = $INC{'Net/FTP/Mock.pm'};
    $self->servers( \%args );

    return;
}


sub isa {
    return 1 if $_[1] eq 'Net::FTP';
    return $_[0]->UNIVERSAL::isa($_[1]);
}

sub _check_host {
    my ( $self, $host, $set_function ) = @_;

    $self->message( "Net::FTP: Bad hostname '$host'" ) if !$self->servers->{$host};

    return $set_function->( $host );
}

sub _server {
    my ( $self ) = @_;
    return if !$self->servers;
    return $self->servers->{$self->host};
}

sub _get_account {
    my ( $self ) = @_;
    return $self->_bad_host if !$self->_server;
    my $acc = $self->_server->{$self->user}{$self->pass} || $self->_bad_account;
    return $acc;
}

sub _bad_host {
    my ( $self ) = @_;
    $self->message( "Cannot connect to ".$self->host.": Net::FTP: Bad hostname '".$self->host."'" );
    return {};
}

sub _bad_account {
    my ( $self ) = @_;
    $self->message( "Login or password incorrect!\n" );
    return {};
}

sub _file_missing {
    my ( $self, $file, $target ) = @_;
    $self->code( 550 );
    return;
}

sub _full_filename {
    my ( $self, $file ) = @_;

    $file = $self->root.$file;

    return $file;
}



sub login {
    my ( $self, $user, $pass ) = @_;

    $self->user( $user );
    $self->pass( $pass );

    return 1 if $self->_account->{active};
    return;
}

sub binary {}

sub get {
    my ( $self, $file, $target ) = @_;

    $file = $self->_full_filename( $file );
    return $self->_file_missing if !-e $file;

    copy $file, $target or return;

    $self->code( 226 );
    return $file;
}

sub quit {}

sub mdtm {
    my ( $self, $file ) = @_;

    $file = $self->_full_filename( $file );
    return if !-e $file;

    return (stat $file)[9];
}

sub size {
    my ( $self, $file ) = @_;

    $file = $self->_full_filename( $file );
    return if !-e $file;

    return -s $file;
}


1;

__END__
=pod

=head1 NAME

Net::FTP::Mock - test code using Net::FTP without having an FTP server

=head1 VERSION

version 0.103300

=head1 SYNOPSIS

    use Net::FTP::Mock (
        localhost => {
            username => { password => {
                active => 1,
                root => "t/remote_ftp/"
            }},
        },
        ftp.work.com => {
            harry => { god => {
                active => 1,
                root => "t/other_remote_ftp/"
            }},
        },
    );

    use Net::FTP; # will do nothing, since Mock already blocked it

    # $ftp here actually is a Net::FTP::Mock object,
    # but when inspected with isa() it happily claims to be Net::FTP
    my $ftp = Net::FTP->new("ftp.work.com", Debug => 0) or die "Cannot connect to some.host.name: $@";

    # all of these do what you'd think they do, only instead of acting
    # on a real ftp server, they act no the data provided via import
    # and the local harddisk
    $ftp->login( "harry",'god' ) or die "Cannot login ", $ftp->message;
    $ftp->get("that.file") or die "get failed ", $ftp->message;
    $ftp->quit;

=head1 DESCRIPTION

Net::FTP::Mock is designed to make code using Net::FTP testable without having to set up actual FTP servers. When
calling its import(), usually by way of use, you can pass it a hash detailing virtual servers, their accounts, as well
as directories that those accounts map to on the local machine.

You can then interact with the Net::FTP::Mock object exactly as you would with a real one.

NOTE: This is a work in progress and much of Net::FTP's functionality is not yet emulated. If it behaves odd, look at
the code or yell at me. Contributions on github are very welcome.

=head1 NAME

test code using Net::FTP without having an FTP server

=head1 METHODS

=head2 Net::FTP::new

Factory method that is implanted into Net::FTP's namespace and returns a Net::FTP::Mock object. Should behave exactly
like Net::FTP's new() behaves.

=head2 servers

Class attribute that stores the servers hashref passed when the module is used.

=head2 Net::FTP::Mock->import( %server_details );

Blocks Net::FTP's namespace in %INC and prepares the servers to be emulated.

=head2 isa

Overrides isa to ensure that Moose's type checks recognize this as a Net::FTP object.

=head1 SUPPORTED NET::FTP METHODS

=head2 code

=head2 message

=head2 binary

=head2 get

=head2 quit

=head2 mdtm

=head2 size

=head2 login

=head1 ACKNOWLEDGEMENTS

Thanks to L<Tr@ffics|http://traffics.de> and especially Jens Muskewitz for granting permission to release this module.

Many thanks to mst and rjbs who fielded my newbie questions in #moose and helped me figure out how to actually create
the Mock object from Net::FTP's mainspace, as well as how to get the Mock object to masquerade as Net::FTP.

=head1 CONTRIBUTIONS

Since I'm not sure how much time i can devote to this, I'm happy about any help. The code is up on github and i'll
accept any helping pull requests.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

