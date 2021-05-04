package Plasp::Request;

use List::Util qw(all);

use Moo;
use Sub::HandlesVia;
use Types::Standard qw(InstanceOf Str Int HashRef);
use namespace::clean;

has 'asp' => (
    is       => 'ro',
    isa      => InstanceOf ['Plasp'],
    required => 1,
    weak_ref => 1,
);

=head1 NAME

Plasp::Request - $Request Object

=head1 SYNOPSIS

  use Plasp::Request;

  my $req = Plasp::Request->new(asp => $asp);
  my $session_cookie = $req->Cookies('session');
  my $host = $req->ServerVariables('HTTP_HOST');

=head1 DESCRIPTION

The request object manages the input from the client browser, like posts, query
strings, cookies, etc. Normal return results are values if an index is
specified, or a collection / perl hash ref if no index is specified. WARNING:
the latter property is not supported in ActiveState PerlScript, so if you use
the hashes returned by such a technique, it will not be portable.

A normal use of this feature would be to iterate through the form variables in
the form hash...

  $form = $Request->Form();
  for(keys %{$form}) {
    $Response->Write("$_: $form->{$_}<br>\n");
  }

Note that if a form POST or query string contains duplicate values for a key,
those values will be returned through normal use of the C<$Request> object:

  @values = $Request->Form('key');

but you can also access the internal storage, which is an array reference like
so:

  $array_ref = $Request->{Form}{'key'};
  @values = @{$array_ref};

Please read the PERLSCRIPT section for more information on how things like
C<< $Request->QueryString() >> & C<< $Request->Form() >> behave as collections.

=head1 ATTRIBUTES

=over

=item $Request->{Method}

API extension. Returns the client HTTP request method, as in GET or POST. Added
in version C<2.31>.

=cut

has 'Method' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { shift->asp->req->method },
);

=item $Request->{TotalBytes}

The amount of data sent by the client in the body of the request, usually the
length of the form data. This is the same value as
C<< $Request->ServerVariables('CONTENT_LENGTH') >>

=cut

has 'TotalBytes' => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub { shift->asp->req->content_length || 0 },
);

sub BUILD {
    my ( $self ) = @_;

    # Due to problem mentioned above in the builder methods, we are calling
    # these attributes to populate the values for the hash key to be available
    $self->Cookies;
    $self->FileUpload;
    $self->Form;
    $self->Method;
    $self->Params;
    $self->QueryString;
    $self->ServerVariables;
    $self->TotalBytes;
}

=back

=head1 METHODS

=over

=item $Request->BinaryRead([$length])

Returns a string whose contents are the first C<$length> bytes of the form data,
or body, sent by the client request. If C<$length> is not given, will return all
of the form data. This data is the raw data sent by the client, without any
parsing done on it by Plasp.

Note that C<BinaryRead> will not return any data for file uploads. Please see
the C<< $Request->FileUpload() >> interface for access to this data.
C<< $Request->Form() >> data will also be available as normal.

=cut

sub BinaryRead {
    my ( $self, $length ) = @_;
    my $req = $self->asp->req;
    return if $req->content_type =~ /multipart/;
    my $body   = $req->body;
    my $buffer = '';
    $length ||= $req->content_length;
    $body->read( $buffer, $length );
    return $buffer;
}

=item $Request->ClientCertificate()

Not implemented.

=cut

# TODO: will not implement
sub ClientCertificate {
    my ( $self ) = @_;
    $self->asp->log->warn( "\$Request->ClientCertificate has not been implemented!" );
    return;
}

=item $Request->Cookies($name [,$key])

Returns the value of the Cookie with name C<$name>. If a C<$key> is specified,
then a lookup will be done on the cookie as if it were a query string. So, a
cookie set by:

  Set-Cookie: test=data1=1&data2=2

would have a value of C<2> returned by C<< $Request->Cookies('test','data2') >>.

If no name is specified, a hash will be returned of cookie names as keys and
cookie values as values. If the cookie value is a query string, it will
automatically be parsed, and the value will be a hash reference to these values.

When in doubt, try it out. Remember that unless you set the C<Expires> attribute
of a cookie with C<< $Response->Cookies('cookie', 'Expires', $xyz) >>, the
cookies that you set will only last until you close your browser, so you may
find your self opening & closing your browser a lot when debugging cookies.

For more information on cookies in ASP, please read C<< $Response->Cookies() >>

=cut

# For some reason, for attributes that start with a capital letter, Moose seems
# to load the default value before the object is fully initialized. lazy => 1 is
# a workaround to build the defaults later
has 'Cookies' => (
    is      => 'ro',
    isa     => HashRef,
    reader  => '_get_Cookies',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        my %cookies;
        for my $name ( keys %{ $self->asp->req->cookies } ) {
            my $value = $self->asp->req->cookies->{$name}
                ? [ split '&', $self->asp->req->cookies->{$name} ]
                : [];
            if ( all {/.=./} @$value ) {
                for ( @$value ) {
                    my ( $key, $val ) = split '=';
                    $cookies{$name}{$key} = $val;
                }
            } else {
                $cookies{$name} = $value->[0];
            }
        }
        return \%cookies;
    },
    handles_via => 'Hash',
    handles     => {
        _get_Cookie => 'get',
    },
);

sub Cookies {
    my ( $self, $name, $key ) = @_;

    if ( $name ) {
        if ( $key ) {
            my $cookie = $self->_get_Cookie( $name );
            return ref $cookie eq 'HASH' ? $cookie->{$key} : $cookie;
        } else {
            return $self->_get_Cookie( $name );
        }
    } else {
        return $self->_get_Cookies;
    }
}

=item $Request->FileUpload($form_field, $key)

API extension. The C<FileUpload> interface to file upload data is stabilized.
The internal representation of the file uploads is a hash of hashes, one hash
per file upload found in the C<< $Request->Form() >> collection. This collection
of collections may be queried through the normal interface like so:

  $Request->FileUpload('upload_file', 'ContentType');
  $Request->FileUpload('upload_file', 'FileHandle');
  $Request->FileUpload('upload_file', 'BrowserFile');
  $Request->FileUpload('upload_file', 'Mime-Header');
  $Request->FileUpload('upload_file', 'TempFile');

  * note that TempFile must be use with the UploadTempFile configuration setting.

The above represents the old slow collection interface, but like all collections
in Plasp, you can reference the internal hash representation more
easily.

  my $fileup = $Request->{FileUpload}{upload_file};
  $fileup->{ContentType};
  $fileup->{BrowserFile};
  $fileup->{FileHandle};
  $fileup->{Mime-Header};
  $fileup->{TempFile};

=cut

has 'FileUpload' => (
    is      => 'ro',
    isa     => HashRef,
    reader  => '_get_FileUploads',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        my %uploads;

        # $self->asp->req->uploads is a Hash::MultiValue, however, Apache::ASP
        # does not deal with multiple uploads per-field, so we just pick the
        # last one.
        for my $field ( keys %{ $self->asp->req->uploads } ) {
            my $upload = $self->asp->req->uploads->get( $field );
            $uploads{$field} = {
                ContentType => $upload->content_type,
                BrowserFile => $upload->filename,
                TempFile    => $upload->path,
                FileHandle  => IO::File->new( $upload->path, 'r' ),
            };
        }
        return \%uploads;
    },
    handles_via => 'Hash',
    handles     => {
        _get_FileUpload => 'get',
    },
);

sub FileUpload {
    my ( $self, $form_field, $key ) = @_;

    if ( $form_field ) {
        my $upload = $self->_get_FileUpload( $form_field )->{$key};
        return wantarray && ref $upload eq 'ARRAY' ? @$upload : $upload;
    } else {
        return $self->_get_FileUploads;
    }
}

=item $Request->Form($name)

Returns the value of the input of name C<$name> used in a form with POST method.
If C<$name> is not specified, returns a ref to a hash of all the form data. One
can use this hash to create a nice alias to the form data like:

  # in global.asa
  use vars qw( $Form );
  sub Script_OnStart {
    $Form = $Request->Form;
  }
  # then in ASP scripts
  <%= $Form->{var} %>

File upload data will be loaded into C<< $Request->Form('file_field') >>, where
the value is the actual file name of the file uploaded, and the contents of the
file can be found by reading from the file name as a file handle as in:

  while(read($Request->Form('file_field_name'), $data, 1024)) {};

For more information, please see the CGI / File Upload section, as file uploads
are implemented via the CGI.pm module.

=cut

has 'Form' => (
    is      => 'ro',
    isa     => InstanceOf ['Hash::MultiValue'],
    reader  => '_get_Form',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;

        # ASP includes uploads in its Form()
        return Hash::MultiValue->new(
            $self->asp->req->body_parameters->flatten,
            $self->asp->req->uploads->flatten,
        );
    },
    handles_via => 'Hash',
    handles     => {
        _get_FormField => 'get',
    },
);

sub Form {
    my ( $self, $name ) = @_;

    if ( $name ) {
        my $value = $self->_get_FormField( $name );
        return wantarray && ref $value eq 'ARRAY' ? @$value : $value;
    } else {
        return $self->_get_Form;
    }
}

=item $Request->Params($name)

API extension. If C<RequestParams> CONFIG is set, the C<< $Request->Params >>
object is created with combined contents of C<< $Request->QueryString >> and
C<< $Request->Form >>. This is for developer convenience simlar to CGI.pm's
C<param()> method. Just like for C<< $Response->Form >>, one could create a
nice alias like:

  # in global.asa
  use vars qw( $Params );
  sub Script_OnStart {
    $Params = $Request->Params;
  }

=cut

has 'Params' => (
    is          => 'ro',
    isa         => InstanceOf ['Hash::MultiValue'],
    reader      => '_get_Params',
    lazy        => 1,
    default     => sub { shift->asp->req->parameters },
    handles_via => 'Hash',
    handles     => {
        _get_Param => 'get',
    },
);

sub Params {
    my ( $self, $name ) = @_;

    if ( $name ) {
        my $param = $self->_get_Param( $name );
        return wantarray && ref $param eq 'ARRAY' ? @$param : $param;
    } else {
        return $self->_get_Params;
    }
}

=item $Request->QueryString($name)

Returns the value of the input of name C<$name> used in a form with GET method,
or passed by appending a query string to the end of a url as in
http://localhost/?data=value. If C<$name> is not specified, returns a ref to a
hash of all the query string data.

=cut

has 'QueryString' => (
    is          => 'ro',
    isa         => InstanceOf ['Hash::MultiValue'],
    reader      => '_get_QueryString',
    lazy        => 1,
    default     => sub { shift->asp->req->query_parameters },
    handles_via => 'Hash',
    handles     => {
        _get_Query => 'get',
    },
);

sub QueryString {
    my ( $self, $name ) = @_;

    if ( $name ) {
        my $qparam = $self->_get_Query( $name );
        return wantarray && ref $qparam eq 'ARRAY' ? @$qparam : $qparam;
    } else {
        return $self->_get_QueryString;
    }
}

=item $Request->ServerVariables($name)

Returns the value of the server variable / environment variable with name
C<$name>. If C<$name> is not specified, returns a ref to a hash of all the
server / environment variables data. The following would be a common use of
this method:

  $env = $Request->ServerVariables();
  # %{$env} here would be equivalent to the cgi %ENV in perl.

=cut

has 'ServerVariables' => (
    is          => 'ro',
    isa         => HashRef,
    reader      => '_get_ServerVariables',
    lazy        => 1,
    default     => sub { \%ENV },
    handles_via => 'Hash',
    handles     => {
        _get_ServerVariable => 'get',
    },
);

sub ServerVariables {
    my ( $self, $name ) = @_;

    if ( $name ) {
        my $var = $self->_get_ServerVariable( $name );
        return wantarray && ref $var eq 'ARRAY' ? @$var : $var;
    } else {
        return $self->_get_ServerVariables;
    }
}

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp::Session>

=item * L<Plasp::Response>

=item * L<Plasp::Application>

=item * L<Plasp::Server>

=back
