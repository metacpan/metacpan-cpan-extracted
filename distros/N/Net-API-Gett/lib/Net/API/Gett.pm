package Net::API::Gett;

use strict;
use warnings;

use 5.010;

use Moo;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

use Net::API::Gett::User;
use Net::API::Gett::Share;
use Net::API::Gett::File;
use Net::API::Gett::Request;

BEGIN {
    require LWP::Protocol::https or die "This module requires HTTPS, please install LWP::Protocol::https\n";
}

=head1 NAME

Net::API::Gett - Perl bindings for Ge.tt API

=head1 VERSION

Version 1.06

=cut

our $VERSION = '1.06';

=head1 SYNOPSIS

    use 5.010;
    use Net::API::Gett;

    # Get API Key from http://ge.tt/developers

    my $gett = Net::API::Gett->new( 
        api_key      => 'GettAPIKey',
        email        => 'me@example.com',
        password     => 'mysecret',
    );

    my $file_obj = $gett->upload_file( 
        filename => "ossm.txt",
        contents => "/some/path/example.txt",
           title => "My Awesome File", 
        encoding => ":encoding(UTF-8)" 
    );

    say "File has been shared at " . $file_obj->getturl;

    # Download contents
    my $file_contents = $file_obj->contents();

    open my $fh, ">:encoding(UTF-8)", "/some/path/example-copy.txt" 
        or die $!;
    print $fh $file_contents;
    close $fh;

    # clean up share and file(s)
    my $share = $gett->get_share($file->sharename);
    $share->destroy();

=head1 ABOUT

L<Gett|http://ge.tt> is a clutter-free file sharing service that allows its users to 
share up to 2 GB of files for free.  They recently implemented a REST API; this is a 
binding for the API. See L<http://ge.tt/developers> for full details and how to get an
API key.

=head1 CHANGES FROM PREVIOUS VERSION

This library is more encapsulated. Share functions which act on shares are in the L<Net::API::Gett::Share> 
object namespace, and likewise with Ge.tt L<files|Net::API::Gett:File>. Future versions of this library 
will modify the L<Request|Net::API::Gett::Request> and L<User|Net::API::Gett::User> objects to be 
L<roles|Moo::Role> rather than objects.

=cut

sub BUILD {
    my $self = shift;
    my $args = shift;

    unless ( $self->has_user ) {
        if ( $args->{refresh_token} ||
             $args->{access_token}  ||
             ( $args->{api_key} && $args->{email} && $args->{password} ) ) {
                $self->user( Net::API::Gett::User->new(%{$args}) );
        }
    }
}

=head1 ATTRIBUTES

=over

=item user

L<Net::API::Gett::User> object. C<has_user()> predicate.

=back

=cut

has 'user' => (
    is => 'rw',
    lazy => 1,
    predicate => 'has_user',
    isa => sub { die "$_[0] is not Net::API::Gett::User" unless ref($_[0]) =~ /User/ },
);

=over

=item request

L<Net::API::Gett::Request> object.

=back

=cut

has 'request' => (
    is => 'rw',
    isa => sub { die "$_[0] is not Net::API::Gett::Request" unless ref($_[0]) =~ /Request/ },
    default => sub { Net::API::Gett::Request->new() },
    lazy => 1,
);

=head1 METHODS

Unless otherwise noted, these methods die if an error occurs or if they get a response from the API
which is not successful. If you need to handle errors more gracefully, use L<Try::Tiny> to catch fatal 
errors.

=over

=item new()

Constructs a new object.  Optionally accepts:

=over

=item * A Ge.tt API key, email, and password, or,

=item * A Ge.tt refresh token, or,

=item * A Ge.tt access token

=back

If any of these parameters are passed, they will be proxied into the L<Net::API::Gett::User> object which
will then permit you to make authenticated API calls.  Without an access token (or the means to acquire one)
only non-authenticated calls are allowed; they are: C<get_share()>, C<get_file()>, 
C<$file-E<gt>thumbnail()> and C<$file-E<gt>contents()>.

=back

=head2 Share functions

All of these functions cache L<Net::API::Gett::Share> objects. Retrieve objects from the 
cache using the C<shares> method.  Use the C<get_share> method to update a cache entry if it
is stale.

=over

=item get_shares()

Retrieves B<all> share information for the given user.  Takes optional scalar integers 
C<offset> and C<limit> parameters, respectively. 

Returns an unordered list of L<Net::API::Gett::Share> objects. 

=back

=cut

sub get_shares {
    my $self = shift;
    croak "Can't call get_shares() without Net::API::Gett::User object" unless $self->has_user;

    my $offset = shift;
    my $limit = shift;

    $self->user->login unless $self->user->has_access_token;

    my $endpoint = "/shares?accesstoken=" . $self->user->access_token;

    if ( defined $offset && looks_like_number $offset ) {
        $endpoint .= "&skip=$offset";
    }

    if ( defined $limit && looks_like_number $limit ) {
        $endpoint .= "&limit=$limit";
    }

    my $response = $self->request->get($endpoint);

    if ( $response ) {
        foreach my $share_href ( @{ $response } ) {
            next unless $share_href;
            $self->add_share(
                $self->_build_share($share_href)
            );
        }
        return $self->shares;
    }
    else {
        return undef;
    }
}

=over

=item get_share()

Retrieves (and/or refreshes cached) information about a specific single share. 
Requires a C<sharename> parameter. Does not require an access token to call.

Returns a L<Net::API::Gett::Share> object.

=back

=cut

sub get_share {
    my $self = shift;
    my $sharename = shift;

    return undef unless $sharename =~ /\w+/;

    my $response = $self->request->get("/shares/$sharename");

    if ( $response ) {
        my $share = $self->_build_share($response);
        $self->add_share($share);
        return $share;
    }
    else {
        return undef;
    }
}

=over

=item create_share()

This method creates a new share instance to hold files. Takes an optional string scalar
parameter which sets the share's title attribute.

Returns the new share as a L<Net::API::Gett::Share> object.

=back

=cut

sub create_share {
    my $self = shift;
    croak "Can't call create_share() without Net::API::Gett::User object" unless $self->has_user;

    my $title = shift;

    $self->user->login unless $self->user->has_access_token;

    my @args = ("/shares/create?accesstoken=".$self->user->access_token);
    if ( $title ) {
        push @args, { title => $title };
    }
    my $response = $self->request->post(@args);

    if ( $response ) {
        my $share = $self->_build_share($response);
        $self->add_share($share);
        return $share;
    }
    else {
        return undef;
    }
}

=head2 File functions

=over

=item get_file()

Returns a L<Net::API::Gett::File> object given a C<sharename> and a C<fileid>.
Does not require an access token to call.

=back

=cut

sub get_file {
    my $self = shift;
    my $sharename = shift;
    my $fileid = shift;

    my $response = $self->request->get("/files/$sharename/$fileid");

    if ( $response ) {
        return $self->_build_file($response);
    }
    else {
        return undef;
    }
}

=over

=item upload_file()

This method uploads a file to Gett. The following key/value pairs are valid:

=over

=item * filename (B<required>) 
    
What to call the uploaded file when it's inside of the Gett service.

=item * sharename (optional) 
    
Where to store the uploaded file. If not specified, a new share will be automatically created.

=item * title (optional) 
    
If specified, this value is used when creating a new share to hold the file. It will not change
the title of an existing share. See the C<update()> method on the share object to do that.

=item * content (optional)

A synonym for C<contents>. (Yes, I've typo'd this too many times.) Anything in C<contents> has 
precedent, if they're both specified.

=item * contents (optional) 

A representation of the file's contents.  This can be one of:

=over

=item * A buffer (See note below)

=item * An L<IO::Handle> object

=item * A FILEGLOB

=item * A pathname to a file to be read

=back

If not specified, the C<filename> parameter is treated as a pathname. This attempts to be DWIM, 
in the sense that if C<contents> contains a value which is not a valid filename, it treats 
C<contents> as a buffer and uploads that data.

=item * encoding

An encoding scheme for the file content. By default it uses C<:raw>. See C<perldoc -f binmode> 
for more information about encodings.

=item * chunk_size

The chunk_size in bytes to use when uploading a file.  Defaults to 1 MB.

=back

Returns a L<Net::API::Gett:File> object representing the uploaded file.

=back

=cut

sub upload_file {
    my $self = shift;
    my $opts = { @_ };

    return undef unless ref($opts) eq "HASH";

    my $sharename = $opts->{'sharename'};

    if ( not $sharename ) {
        my $share = $self->create_share($opts->{'title'});
        $sharename = $share->sharename;
    }

    $self->user->login unless $self->user->has_access_token;

    my $endpoint = "/files/$sharename/create?accesstoken=".$self->user->access_token;
    
    my $filename = $opts->{'filename'};

    my $response = $self->request->post($endpoint, { filename => $filename });

    # typo proof this - yeah I've been bitten by this!
    unless ( exists $opts->{'contents'} ) {
            if ( exists $opts->{'content'} ) {
            $opts->{'contents'} = delete $opts->{'content'};
        }
        else {
            $opts->{'contents'} = $filename 
        }
    }

    if ( $response ) {
        my $file = $self->_build_file($response);
        if ( $file->readystate eq "remote" ) {
            my $put_upload_url = $file->put_upload_url;
            croak "Didn't get put upload URL from $endpoint" unless $put_upload_url;
            if ( $file->send_file($put_upload_url, $opts->{'contents'}, 
                        $opts->{'encoding'}, $opts->{'chunk_size'}) ) {
                return $file;
            }
            else {
                croak "There was an error reading data from " . $opts->{'contents'};
            }
        }
        else {
            croak "$endpoint doesn't have right readystate";
        }
    }
    else {
        return undef;
    }
}

sub _build_share {
    my $self = shift;
    my $share_href = shift;

    my $share = Net::API::Gett::Share->new(
        sharename => $share_href->{'sharename'},
        created => $share_href->{'created'},
        title => $share_href->{'title'},
        getturl => $share_href->{'getturl'},
    );
    foreach my $file_href ( @{ $share_href->{'files'} } ) {
        next unless $file_href;
        my $file = $self->_build_file($file_href);
        $share->add_file($file);
    }
    $share->user($self->user) if $self->has_user;

    return $share;
}

sub _build_file {
    my $self = shift;
    my $file_href = shift;

    # filter out undefined attributes
    my @attrs = grep { defined $file_href->{$_} } 
        qw(filename size created fileid downloads readystate getturl download sharename);
    my @params = map { $_ => $file_href->{$_} } @attrs;

    if ( exists $file_href->{'upload'} ) {
        push @params, 'put_upload_url' => $file_href->{'upload'}->{'puturl'};
        push @params, 'post_upload_url' => $file_href->{'upload'}->{'posturl'};
    }

    my $file = Net::API::Gett::File->new( @params );
    $file->user($self->user) if $self->has_user;
    
    return $file;
}

=over

=item add_share()

This method populates/updates the L<Net::API::Gett:Share> object local cache.

It returns undef if the passed value isn't a L<Net::API::Gett::Share> object.

=back

=cut

sub add_share {
    my $self = shift;
    my $share = shift;

    return undef unless ref($share) =~ /Share/;

    my $sharename = $share->sharename();

    $self->{'shares'}->{$sharename} = $share;
}

=over

=item shares()

This method retrieves one or more cached L<Net::API::Gett::Share> objects. Objects are
requested by sharename.  If no parameter list is specified, B<all> cached objects are 
returned in an unordered list. (The list will B<not> be in the order shares were added
to the cache.)

If no objects are cached, this method returns an empty list.

=back

=cut

sub shares {
    my $self = shift;

    if ( @_ ) {
        return map { $self->{'shares'}->{$_} } @_;
    }

    return () unless exists $self->{'shares'};

    return values %{ $self->{'shares'} };
}

=head1 AUTHOR

Mark Allen, C<< <mrallen1 at yahoo dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-api-gett at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-API-Gett>.  I will 
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::API::Gett

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-API-Gett>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-API-Gett>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-API-Gett>

=item * MetaCPAN

L<https://metacpan.org/module/Net::API::Gett/>

=item * GitHub

L<https://github.com/mrallen1/Net-API-Gett>

=back

=head1 SEE ALSO

L<Gett API documentation|http://ge.tt/developers>

=head1 CONTRIBUTORS

Thanks to the following for patches: 

=over

=item

Keedi Kim (L<https://github.com/keedi>)

=item

Alexander Ost

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mark Allen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Net::API::Gett
