package Net::STF::Client;
use strict;
use Net::STF::Bucket;
use Net::STF::Object;
use Carp ();
use Furl::HTTP;
use HTTP::Status ();
use MIME::Base64 ();
use Scalar::Util ();
use URI ();
use Class::Accessor::Lite
    rw => [ qw(
        furl
        agent_name
        repl_count
        url
        error
        username
        password
    ) ]
;

our $VERSION = '1.01';

sub new {
    my $class = shift;

    # Grr, allow hashrefs
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        @_ = %{$_[0]};
    }

    # Only exists to provide back compat with non-published version.
    # You shouldn't be using this
    if ( @_ == 2 && ! ref $_[0] && ref $_[1] eq 'HASH' ) {
        # Net::STF style
        @_ = ( url => $_[0], %{$_[1]} );
    }

    my $self = bless { 
        agent_name => join( '/', $class, $VERSION ),
        repl_count => 3,
        @_
    }, $class;

    if (! $self->furl ) {
        $self->furl(Furl::HTTP->new( agent => $self->agent_name ));
    }

    return $self;
}

sub _url_is_object {
    # Make sure the URL contains more than one level in its path.
    # Otherwise, you may end up getting stuff like
    #   DELETE http://stf.example.com/foo/
    # instead of
    #   DELETE http://stf.example.com/foo/bar
    # The former deletes the BUCKET, whereas the latter deletes the object.

    # XXX regex copied from URI.pm

    my (undef, undef, $path) = 
        $_[0] =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
    if ($path =~ m{^/+[^/]+(?:/+[\./]*)?$}) {
        Carp::croak("Invalid object URL given -> $_[0]");
    }
    1;
}

sub _qualify_url {
    my ($self, $url) = @_;

    my $prefix = $self->url;
    if (! $prefix) {
        return $url;
    }

    return URI->new($url)->abs($prefix)->canonical;
}

sub get_object {
    my ($self, $url, $opts) = @_;

    $self->error(undef);

    $url = $self->_qualify_url($url);

    my %furlopts = (
        method => 'GET',
        url => $url,
    );
    my @res = $self->send_request( \%furlopts, $opts );
    if ( ! HTTP::Status::is_success( $res[1] ) ) {
        $self->error( $res[2] );
        return;
    }
    return Net::STF::Object->new(
        url => $url,
        content => $res[4]
    );
}

sub send_request {
    my ($self, $furlopts, $opts) = @_;

    $furlopts->{headers} ||= [];

    my ($username, $password) = ( $self->username, $self->password );
    if (defined $username && defined $password ) {
        push @{ $furlopts->{headers} },
            ( 'Authorization' => "Basic " . MIME::Base64::encode("$username:$password", "") );
    }

    if ( $opts->{headers} ) {
        push @{$furlopts->{headers}}, @{$opts->{headers}};
    }
    foreach my $key ( qw(write_file write_code) ) {
        if (my $value = $opts->{$key}) {
            $furlopts->{$key} = $value;
        }
    }
    return $self->furl->request( %$furlopts );
}

sub put_object {
    my ($self, $url, $content, $opts) = @_;

    $self->error(undef);

    $url = $self->_qualify_url($url);
    _url_is_object($url);

    if (! defined $content ) {
        Carp::croak( "No content provided" );
    }

    if ( ref $content eq 'SCALAR' ) {
        # raw string passed
        $content = $$content;
    } elsif ( Scalar::Util::openhandle( $content ) ) {
        # make sure we're at the beginning of the file
        seek $content, 0, 0;
    } else {
        # assume it's a file. 
        open my $fh, '<', $content
            or die "Failed to open file $content: $!";
        $content = $fh;
        seek $content, 0, 0;
    }

    my @hdrs;
    push @hdrs,
        ("X-STF-Replication-Count", ($opts->{repl_count} || $self->repl_count));
    if (my $consistency = $opts->{consistency}) {
        push @hdrs, "X-STF-Consistency", $consistency;
    }


    my %furlopts = (
        method  => 'PUT',
        url     => $url,
        headers => \@hdrs,
        content => $content,
    );
    my @res = $self->send_request( \%furlopts, $opts );
    if (! HTTP::Status::is_success($res[1])) {
        $self->error( $res[2] );
        return;
    }

    # if you don't want a result, then we don't create an object
    return if !defined wantarray;

    return Net::STF::Object->new(
        url     => $url,
#        content => $res[4]
    );
}

sub delete_object {
    my ($self, $url, $opts) = @_;

    $self->error(undef);

    $url = $self->_qualify_url($url);
    _url_is_object($url);

    my %furlopts = (
        method => 'DELETE',
        url    => $url,
    );
    my @res = $self->send_request( \%furlopts, $opts );
    if ( ! HTTP::Status::is_success( $res[1] ) ) {
        $self->error( $res[2] );
        return;
    }
    return 1;
}

sub create_bucket {
    my ($self, $url, $opts) = @_;

    $self->error(undef);

    $url = $self->_qualify_url($url);

    my %furlopts = (
        method => 'PUT',
        url    => $url,
        headers => [
            'Content-Length' => 0,
        ],
    );
    my @res = $self->send_request( \%furlopts, $opts );
    if (! HTTP::Status::is_success( $res[1] ) ) {
        $self->error( $res[2] );
        return;
    }

    return Net::STF::Bucket->new(
        client => $self,
        name   => ( URI->new($url)->path =~ m{^/([^/]+)} )[0],
    );
}

sub delete_bucket {
    my ($self, $url, $opts) = @_;

    $self->error(undef);

    my @hdrs;
    if ( $opts->{recursive} ) {
        push @hdrs, "X-STF-Recursive-Delete" => "true";
    }

    $url = $self->_qualify_url($url);

    my %furlopts = (
        method  => 'DELETE',
        headers => \@hdrs,
        url     => $url,
    );

    my @res = $self->send_request( \%furlopts, $opts );
    if (! HTTP::Status::is_success( $res[1] ) ) {
        $self->error( $res[2] );
        return;
    }

    return 1;
}

1;

__END__

=head1 NAME

Net::STF::Client - STF Client 

=head1 SYNOPSIS

    use Net::STF::Client;

    my $client = Net::STF::Client->new( 
        url => "http://stf.example.com",
        repl_count => 3,
    );

    # If you want to use Basic Auth:
    # my $client = Net::STF::Client->new(
    #     ... other params ...
    #     username => ....,
    #     password => ....,
    # );

    # direct CRUD from the client (fastest if you have the URL)
    $object = $client->put_object( $url, $content, \%opts );
    $object = $client->get_object( $url, \%opts );
    $bool   = $client->delete_object( $url, \%opts );
    $bool   = $client->delete_bucket( $url, \%opts );

    # bucket-oriented interface
    my $bucket = $client->create_bucket( $bucket_name );
    $object = $bucket->put_object( $key, $content, \%opts );
    $object = $bucket->get_object( $key, \%opts );
    $bool   = $bucket->del_object( $key, \%opts );
    $bool   = $bucket->delete( $recursive );

    # object data
    $object->url;
    $object->key;
    $object->content;

=head1 DESCRIPTION

Net::STF::Client implements the STF protocol to talk to STF servers.

=head1 METHODS

=head2 $class-E<gt>new(%args)

=over 4

=item url

The base URL for your STF server. Required if you're going to use the bucket-oriented interface.

=item repl_count

The default number of replicas to request when creating new objects. You may override this setting during a call to put_object(), but if unspecified, this value will be used as default.

If you don't specify this value in the constructor call, default value of 3 will be used.

=item username

Username used for basic authentication. Leave blank if your server does not use basic authentiation.

=item password

Password used for basic authentication. Leave blank if your server does not use basic authentiation.

=item agent_name

The user agent name used when accessing the STF server. If unspecified, "Net::STF::Client/$VERSION" will be used as default.

=item furl

Furl::HTTP object to talk to the STF server. You only need to provide this if you want to customize the behavior of Furl::HTTP object, which is pretty rare.

=back

=head2 $object = $client-E<gt>put_object( $url, $content, \%opts );

=over 4 

=item $content (Any)

The object value to be stored. Can be anything that Furl::HTTP can handle when making a POST request.

=item $url (Str)

The URL to put your object.

If the url parameter was supplied, you may specify a URL fragment containing the"$bucket_name/$object_name"

So these are equivalent:

    my $stf_base    = "http://stf.mycompany.com/";
    my $bucket_name = "mybucket";
    my $object_name = "path/to/object.dat";

    # Complete URL
    {
        my $client = Net::STF::Client->new();
        $client->put_object( "$stf_base/$bucket_name/$object_name", ... );
    }

    # URL fragment
    {
        my $client = Net::STF::Client->new( url => $stf_base );
        $client->put_object( "$bucket_name/$object_name", ... );
    }

=item %opts

=over 4

=item repl_count (Int)

Specify if you want to override the default X-STF-Replication-Count value:

    # Make a lot of replicas for this object!
    $client->put_object( $url, $content, { repl_count => 30 } );

    # Use whatever default in $client
    $client->put_object( $url, $content );

=item consistency (Int)

Specify if you want to set the X-STF-Consistency value.

=item headers 

Appended to headers sent by Furl::HTTP

=item write_file 

Passed to Furl::HTTP

=item write_code

Passed to Furl::HTTP

=back

=back

=head2 $object = $client-E<gt>get_object( $url, \%opts );

=over 4 

=item url (Str)

See docs for put_object() for details

=item %opts

=over 4

=item headers 

Appended to headers sent by Furl::HTTP

=item write_file 

Passed to Furl::HTTP

=item write_code

Passed to Furl::HTTP

=back

=back

=head2 $bool = $client-E<gt>delete_object( $url, \%opts );

=over 4 

=item url (Str)

See docs for put_object() for details

=item %opts

=over 4

=item headers 

Appended to headers sent by Furl::HTTP

=item write_file 

Passed to Furl::HTTP

=item write_code

Passed to Furl::HTTP

=back

=back

=head2 $bool = $client-E<gt>delete_bucket( $url, \%opts );

=over 4 

=item url (Str)

See docs for put_object() for details

=item %opts

=over 4

=item headers 

Appended to headers sent by Furl::HTTP

=item write_file 

Passed to Furl::HTTP

=item write_code

Passed to Furl::HTTP

=back

=back

=head1 SEE ALSO

L<Net::STF::Object>

L<Net::STF::Bucket>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut