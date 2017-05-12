package Net::OBEX::FTP;

use strict;
use warnings;

our $VERSION = '1.001001'; # VERSION

use Carp;
use Net::OBEX;
use XML::OBEXFTP::FolderListing;
use base qw(Class::Data::Accessor);

__PACKAGE__->mk_classaccessors( qw(
        obex
        response
        error
        pwd
        xml
        folders
        files
    )
);

sub new {
    my $class = shift;

    my $self =  bless {}, $class;
    $self->obex( Net::OBEX->new );
    $self->xml( XML::OBEXFTP::FolderListing->new );
    return $self;
}

sub connect {
    my $self = shift;
    croak "Must have even number of arguments to connect()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    croak "Missing `address` argument to connect()"
        unless exists $args{address};

    croak "Missing `port` argument to connect()"
        unless exists $args{port};

    %args = (
        mtu     => 4096,
        version => "\x10",

        %args,
    );

    $self->error(undef);

    my %response;

    my $obex = $self->obex;
    $response{connect} = $obex->connect(
        mtu     => $args{mtu},
        version => $args{version},
        address => $args{address},
        port    => $args{port},
        target  => 'F9EC7BC4953C11D2984E525400DC9E09', # OBEX FTP UUID
    ) or return $self->_set_error('Failed to connect: ' . $obex->error);

    $self->_is_success( \%response, 'connect' )
        or return;

    $response{set_path} = $obex->set_path
        or return $self->_set_error('Failed to set path: ' . $obex->error);

    $self->_is_success( \%response, 'set_path' )
        or return;

    $self->pwd([]);

    $response{get} = $obex->get( type => 'x-obex/folder-listing' )
        or return $self->_set_error(
            'Failed to get folder listing: ' . $obex->error
        );

    my $xml = $self->xml;
    $xml->parse($response{get}{body});
    $self->folders( $xml->folders );
    $self->files( $xml->files );
    return $self->response( \%response );
}

sub cwd {
    my $self = shift;

    my %args;
    if ( @_ & 1 ) {
        $args{path} = shift;
    }
    else {
        %args = @_;
        $args{ +lc } = delete $args{ $_ } for keys %args;
    }

    $self->error(undef);

    my $obex = $self->obex;

    my %response;

    $response{set_path} = $obex->set_path( %args )
        or return $self->_set_error('Failed to set path: ' . $obex->error );

     $self->_is_success( \%response, 'set_path' )
         or return;

    my $pwd_ref = $self->pwd;
    if ( defined $args{path} and length $args{path} ) {
         push @$pwd_ref, $args{path};
    }
    elsif ( defined $args{do_up} ) {
         pop @$pwd_ref;
    }
    else {
        $pwd_ref = [];
    }
    $self->pwd( $pwd_ref );

    $response{get} = $obex->get( type => 'x-obex/folder-listing' )
        or return $self->_set_error(
            'Failed to get folder listing: ' . $obex->error
        );

    my $xml = $self->xml;

    $xml->parse( $response{get}{body} );
    $self->files( $xml->files );
    $self->folders( $xml->folders );

    return $self->response( \%response );
}

sub get {
    my ( $self, $what, $fh ) = @_;

    $self->error(undef);

    my $obex = $self->obex;
    my $response_ref = $obex->get(
        name => $what,
        defined $fh ? ( file => $fh ) : (),
    ) or return $self->_set_error( 'Failed to get: ' . $obex->error );

    return $self->response( $response_ref );
}

sub _is_success {
    my ( $self, $response_ref, $type ) = @_;
    unless( $response_ref->{ $type }{info}{response_code} == 200 ) {
        my ($code, $meaning)
        = @{ $response_ref->{ $type }{info} }{
            qw( response_code  response_code_meaning )
        };

        $self->response( $response_ref );
        $self->error( "Failed to connect: ($code) $meaning" );
        return 0;
    }
    return 1
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub close {
    my $self = shift;
    $self->obex->close( @_ );
}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN KRZR MTU Motorolla RT foos migh mirrorer mtu obex pwd xml

=head1 NAME

Net::OBEX::FTP - implementation of OBEX File Transfer Profile

=head1 SYNOPSIS

This is an OBEX FTP mirrorer, you can also find it in the C<examples/>
directory of this distribution:

    use strict;
    use warnings;

    use Net::OBEX::FTP;
    use File::Spec;

    my $obex = Net::OBEX::FTP->new;

    my $response = $obex->connect( address => '00:17:E3:37:76:BB', port => 9 )
        or die "Error: " . $obex->error;

    print "Mirroring root folder\n";

    mirror_file( $obex, $_ )
        for @{ $obex->files };

    mirror( $obex );

    sub mirror {
        my $obex = shift;

        for my $folder ( @{ $obex->folders } ) {
            print "Mirroring `$folder`\n";

            $response = $obex->cwd( path => $folder )
                or die "Error: " . $obex->error;

            my $local_folder = File::Spec->catdir( @{ $obex->pwd } );
            mkdir $local_folder
                or die "Failed to create directory `$local_folder` ($!)";

            if ( @{ $obex->folders } ) {
                mirror( $obex );
            }

            mirror_file( $obex, $_ )
                for @{ $obex->files };

            $response = $obex->cwd( do_up => 1 )
            or die "Error: " . $obex->error;
        }
    }

    sub mirror_file {
        my ( $obex, $file ) = @_;
        printf "Mirroring %s\n\tsize is: %d bytes\n",
                    $file, $obex->xml->size( $file );

        my $local_file = File::Spec->catfile( @{ $obex->pwd }, $file );
        open my $fh, '>', $local_file
            or die "Failed to open $local_file: $!";
        binmode $fh;

        $obex->get( $file, $fh )
            or die "Failed to get file $file: " . $obex->error;
        close $fh;
    }

=head1 DESCRIPTION

B<WARNING!!! This module is still in early alpha stage. It is recommended
that you use it only for testing.>

The module is an implementation of OBEX File Transfer Profile.

=head1 CONSTRUCTOR

=head2 new
    my $obex = Net::OBEX::FTP->new;

Takes no arguments, returns a freshly baked Net::OBEX::FTP object.

=head1 METHODS

=head2 connect

    my $response_ref = $obex->connect(
        address => '00:17:E3:37:76:BB', # mandatory
        port    => 9,                   # mandatory
        mtu     => 4096,                # optional
        version => "\x10",              # optional
    ) or die "Error: " . $obex->error;

Instructs the object to connect to the device with MAC address C<address>
to port C<port> (OBEX FTP port). The call to this method also retrieves
folder listing of the root folder. Takes several arguments which are as
follows:

=head3 address

    ->connect( address => '00:17:E3:37:76:BB' ...

B<Mandatory>. Takes a scalar as an value which is the address of the
device to connect to.

=head3 port

    ->connect( port => 9 ...

B<Mandatory>. Takes a scalar as an value which is the OBEX FTP port
of the device you are trying to connect to.

=head3 mtu

    ->connect( mtu => 4096 ...

B<Optional>. Takes a scalar as a value which is your MTU (Maximum
Transmission Unit), in other words, the maximum packet size in bytes
you can accept. B<Defaults to:> C<4096>

=head3 version

    ->connect( version => "\x10" ..

B<Optional>. Takes a one byte value which specifies the version of OBEX
protocol to use for conversation. This argument is provided as "just in case"
and you really shouldn't use it. B<Defaults to:> C<0x10> (version 1.0)

=head3 C<connect> RETURN VALUE

    $VAR1 = {
            'connect' => {
                # return of Net::OBEX->get here
            },
            'set_path' => {
                # return of Net::OBEX->set_path here
            },
            'get' => {
                # return of Net::OBEX->get here
            },
    };

The C<connect()> method will return either C<undef> or an empty list
(depending on the context) if an error occurred an the description of
the error will be available via C<error()> method. Upon success, C<connect()>
returns a hashref with three keys.

=head4 connect

The C<connect> key will contain the return value of L<Net::OBEX> C<connect()>
method.

=head4 set_path

The C<get> key will contain the return value of L<Net::OBEX> C<set_path()>
method.

=head4 get

The C<get> key will contain the return value of L<Net::OBEX> C<get()> method.

=head2 cwd

    $obex->cwd
        or die $obex->error;

    $obex->cwd('foos')
        or die $obex->error;

    $obex->cwd( do_up => 1 )
        or die $obex->error;

Instructs the object to change the B<c>urrent B<w>orking B<d>irectory
and fetch the folder listing.
Takes zero, one or a set of key/value arguments. When called without
arguments will set path to the root folder. Calling with only one argument
is equivalent to calling C<( path => 'foos')> with C<'foos'> being your
argument. The key/value form arguments will be passed directly to
L<Net::OBEX> C<set_path()> method. See documentation for L<Net::OBEX> for
details.

If an error occurred, the C<cwd()> method will return either C<undef> or an
empty list depending on the context. Upon success it will return a hashref
with two keys, C<set_path> and C<get>. The C<set_path> key will contain
the return value of L<Net::OBEX> C<set_path()> method and C<get> key will
contain the return value of L<Net::OBEX> C<get()> method. See documentation
for L<Net::OBEX> for more information.

B<Note:> The OBEX spec suggests that it's possible to do C<cd ../foos> in
one call, e.g. C<cwd( path => 'foos', do_up => 1 )>; the OBEX FTP spec
is unclear about this. The only OBEX FTP capable device I have
(Motorolla KRZR phone) gives me 403 when I try to do it this way.
If you have some different device can you please please please confirm
whether it works for you or not. Thank you.

=head2 get

    $obex->get('file.jpg')
        or die $obex->error;

    $obex->get('file.jpg', $file_handle)
        or die $obex->error;

Instructs the object to download a file. Takes one mandatory and one
optional arguments. The first argument (mandatory) is the name of the
file to download, unless you specify the second argument the content
of the file will be returned as a value of C<body> key in the hashref
the C<get()> method returns. The second argument (optional) is an
I<opened for writing> filehandle, if you specify this argument the file
will be written into that filehandle, use this if you are transferring
large files as to not store them in the memory.

If an error occurred will return either C<undef> or an empty list depending
on the context and the reason for the error will be available via
C<error()> method. Upon success will return a hashref which is exactly
the same as the return value of L<Net::OBEX> C<get()> method. See
documentation for L<Net::OBEX> for more information.

=head2 close

    $obex->close;

Takes no arguments and always returns C<1>. Closes the connection.

=head2 pwd

    my $pwd = join '/', @{ $obex->pwd };

Takes no arguments, returns an arrayref, each element of which will be
a directory name representing a level at which we are in. In other words,
doing C<cwd('foos') ... cwd('bars') ... cwd('beers') ... cwd(do_up => 1)>
will make C<pwd()> return C<[ 'foos', 'bars' ]>. When we are in the root
folder, C<pwd()> will return an empty arrayref.

=head2 folders

    my $folders_in_the_current_dir_ref = $obex->folders;

As mentioned before, C<cwd()> and C<connect()> methods fetch folder listings.
The C<folders()> method returns an arrayref, elements of which are the names
of the folders in the current working directory. If no folders are present
C<folders()> method will return an empty arrayref.

=head2 files

    my $files_in_the_current_dir = $obex->files;

Same as C<folders()> methods, except it lists the I<files> in the current
directory.

=head2 xml

    my $xml_object = $obex->xml;

If C<folders()> and C<files()> is not enough for you feel free to use
the L<XML::OBEXFTP::FolderListing> object which
is provided to you via C<xml()> method. Takes no arguments, returns
L<XML::OBEXFTP::FolderListing> object used by the module. See
L<XML::OBEXFTP::FolderListing> for more information.

=head2 obex

    my $net_obex_obj = $obex->obex;

Takes no arguments, returns a L<Net::OBEX> object used by the module.

=head2 response

    my $last_response = $obex->response;

Takes no arguments, returns the return value of the last successful call
to either C<connect()>, C<get()> or C<cwd()> method.

=head2 error

    $obex->cwd
        or die "Error: " . $obex->error;

Takes no arguments, returns a human readable error message explaining why
C<get()>, C<connect()> or C<cwd()> might have failed.

=head1 SEE ALSO

L<Net::OBEX>, L<XML::OBEXFTP::FolderListing>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Net-OBEX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Net-OBEX/issues>

If you can't access GitHub, you can email your request
to C<bug-Net-OBEX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut