package Plasp::Server;

use HTML::Entities;
use Path::Tiny;
use URI;
use URI::Escape;

use Moo;
use Types::Standard qw(InstanceOf Str);
use namespace::clean;

has 'asp' => (
    is       => 'ro',
    isa      => InstanceOf ['Plasp'],
    required => 1,
    weak_ref => 1,
);

=head1 NAME

Plasp::Server - $Server Object

=head1 SYNOPSIS

  use Plasp::Server;

  my $svr = Plasp::Server->new(asp => $asp);
  my $html = $svr->HTMLEncode('my $has_timeout = $Server->{ScriptTimeout} && 1');

=head1 DESCRIPTION

The C<$Server> object is that object that handles everything the other objects
do not. The best part of the server object for Win32 users is the
C<CreateObject> method which allows developers to create instances of ActiveX
components, like the ADO component.

=head1 ATTRIBUTES

=over

=item $Server->{ScriptTimeout} = $seconds

Not implemented.

=cut

has 'ScriptTimeout' => (
    is      => 'ro',
    isa     => Str,
    default => 0,
);

=back

=head1 METHODS

=over

=item $Server->Config($setting)

API extension. Allows a developer to read the CONFIG settings, like C<Global>,
C<GlobalPackage>, C<StateDir>, etc. Currently implemented as a wrapper around

  $self->asp->$setting

May also be invoked as C<< $Server->Config() >>, which will return a hash ref of
all the ASP configuration settings.

=cut

sub Config {
    my ( $self, $setting ) = @_;

    return $self->asp->$setting
        if $self->asp->can( $setting );

    return;
}

=item $Server->CreateObject($program_id)

Not implemented.

=cut

# TODO: will not implement
sub CreateObject {
    my ( $self, $program_id ) = @_;
    $self->asp->log->warn( "\$Server->CreateObject has not been implemented!" );
    return;
}

=item $Server->Execute($file, @args)

New method from ASP 3.0, this does the same thing as

  $Response->Include($file, @args)

and internally is just a wrapper for such. Seems like we had this important
functionality before the IIS/ASP camp!

=cut

sub Execute { my $self = shift; $self->asp->Response->Include( @_ ) }

=item $Server->File()

Returns the absolute file path to current executing script. Same as
$ENV{SCRIPT_NAME} when running under mod_perl.

ASP API extension.

=cut

sub File {
    my ( $self ) = @_;
    return path(
        $self->asp->DocumentRoot, $self->asp->req->path_info
    )->absolute->stringify;
}

=item $Server->GetLastError()

Not implemented.

=cut

# TODO: will not implement
sub GetLastError {
    my ( $self ) = @_;
    $self->asp->log->warn( "\$Server->GetLastError has not been implemented!" );
    return;
}

=item $Server->HTMLEncode( $string || \$string )

Returns an HTML escapes version of C<$string>. &, ", >, <, are each escapes with
their HTML equivalents. Strings encoded in this nature should be raw text
displayed to an end user, as HTML tags become escaped with this method.

As of version C<2.23>, C<< $Server->HTMLEncode() >>may take a string reference
for an optmization when encoding a large buffer as an API extension. Here is how
 one might use one over the other:

  my $buffer = '&' x 100000;
  $buffer = $Server->HTMLEncode($buffer);
  print $buffer;

or

  my $buffer = '&' x 100000;
  $Server->HTMLEncode(\$buffer);
  print $buffer;

Using the reference passing method in benchmarks on 100K of data was 5% more
efficient, but maybe useful for some. It saves on copying the 100K buffer twice.

=cut

sub HTMLEncode {
    my ( $self, $string ) = @_;
    for ( ref $string ) {
        if    ( /SCALAR/ ) { return encode_entities( $$string ) }
        elsif ( /ARRAY/ )  { return \map { encode_entities( $_ ) } @$string }
        else               { return encode_entities( $string ) }
    }
}

=item $Server->MapInclude($include)

API extension. Given the include C<$include>, as an absolute or relative file
name to the current executing script, this method returns the file path that
the include would be found from the include search path. The include search path
is the current script directory, C<Global>, and C<IncludesDir> directories.

If the include is not found in the includes search path, then C<undef>, or bool
false, is returned. So one may do something like this:

  if ($Server->MapInclude('include.inc')) {
    $Response->Include('include.inc');
  }

This code demonstrates how one might only try to execute an include if it
exists, which is useful since a script will error if it tries to execute an
include that does not exist.

=cut

sub MapInclude {
    my ( $self, $include ) = @_;
    $self->asp->search_includes_dir( $include );
}

=item $Server->MapPath($url);

Given the url C<$url>, absolute, or relative to the current executing script,
this method returns the equivalent filename that the server would translate the
request to, regardless or whether the request would be valid.

Only a C<$url> that is relative to the host is valid.  Urls like C<"."> and
C<"/"> are fine arguments to C<MapPath>, but C<http://localhost> would not be.

=cut

sub MapPath {
    my ( $self, $url ) = @_;
    return path( $self->asp->DocumentRoot, URI->new( $url )->path )->stringify;
}

=item $Server->Mail(\%mail, %smtp_args);

With the L<Net::SMTP> and L<Net::Config> modules installed, which are part of
the perl L<libnet> package, you may use this API extension to send email. The
C<\%mail> hash reference that you pass in must have values for at least
the C<To>, C<From>, and C<Subject> headers, and the C<Body> of the mail message.

The return value of this routine is C<1> for success, C<0> for failure. If the
C<MailHost> SMTP server is not available, this will have a return value of C<0>.

You could send an email like so:

  $Server->Mail({
    To => 'somebody@yourdomain.com.foobar',
    From => 'youremail@yourdomain.com.foobar',
    Subject => 'Subject of Email',
    Body =>
      'Body of message. '.
      'You might have a lot to say here!',
    Organization => 'Your Organization',
    CC => 'youremailcc@yourdomain.com.foobar',
    BCC => 'youremailbcc@yourdomain.com.foobar',
    Debug => 0 || 1,
  });

Any extra fields specified for the email will be interpreted as headers for the
email, so to send an HTML email, you could set
C<< 'Content-Type' => 'text/html' >> in the above example.

If you have C<MailFrom> configured, this will be the default for the C<From>
header in your email. For more configuration options like the C<MailHost>
setting, check out the CONFIG section.

The return value of this method call will be boolean for success of the mail
being sent.

If you would like to specially configure the Net::SMTP object used internally,
you may set C<%smtp_args> and they will be passed on when that object is
initialized. C<perldoc Net::SMTP> for more into on this topic.

If you would like to include the output of an ASP page as the body of the mail
message, you might do something like:

  my $mail_body = $Response->TrapInclude('mail_body.inc');
  $Server->Mail({ %mail, Body => $$mail_body });

=cut

sub Mail {
    my ( $self, $mail, %smtp_args ) = @_;

    require Net::SMTP;
    my $smtp = Net::SMTP->new( $self->asp->MailHost, %smtp_args );

    return 0 unless $smtp;

    my ( $from ) = split( /\s*,\s*/, ( $mail->{From} || '' ) ); # just the first one
    $smtp->mail( $from || $self->asp->MailFrom || return 0 );

    my @to;
    for my $field ( qw(To BCC CC) ) {
        my $receivers = $mail->{$field};
        next unless $receivers;

        # assume ref of $receivers is an ARRAY if it is
        my @receivers = ref $receivers
            ? @$receivers
            : ( split( /\s*,\s*/, $receivers ) );
        push @to, @receivers;
    }
    $smtp->to( @to ) || return;

    my $body = delete $mail->{Body};

    # assumes MIME-Version 1.0 for Content-Type header, according to RFC 1521
    # http://www.ietf.org/rfc/rfc1521.txt
    $mail->{'MIME-Version'} = '1.0'
        if $mail->{'Content-Type'} && !$mail->{'MIME-Version'};

    my ( @data, %visited );

    # Though the list below are actually keys in $mail, this is to get them to
    # appear first, thought I'm not sure why it's needed
    for my $field ( qw(Subject From Reply-To Organization To), keys %$mail ) {
        my $value = $mail->{$field};
        next unless $value;
        next if $visited{ lc( $field ) }++;

        # assume ref of $value is an ARRAY if it is
        $value = join( ",", @$value ) if ref $value;
        $value =~ s/^[\n]*(.*?)[\n]*$/$1/;
        push @data, "$field: $value";
    }

    my $data = join( "\n", @data, '', $body );
    my $result;
    unless ( $result = $smtp->data( $data ) ) {
        $self->asp->log->error( $smtp->message );
    }

    $smtp->quit();
    return $result;
}

=item $Server->RegisterCleanup($sub)

Not implemented.

=cut

# TODO: will not implement
sub RegisterCleanup {
    my ( $self, $sub ) = @_;
    return;
}

=item $Server->Transfer($file, @args)

New method from ASP 3.0. Transfers control to another script. The Response
buffer will not be cleared automatically, so if you want this to serve as a
faster C<< $Response->Redirect() >>, you will need to call
C<< $Response->Clear() >> before calling this method.

This new script will take over current execution and the current script will not
continue to be executed afterwards. It differs from C<Execute()> because the
original script will not pick up where it left off.

As of L<Apache::ASP> 2.31, this method now accepts optional arguments like
C<< $Response->Include >> & C<< $Server->Execute >>. C<< $Server->Transfer >>
is now just a wrapper for:

  $Response->Include($file, @args);
  $Response->End;

=cut

sub Transfer {
    my $self = shift;
    $self->asp->Response->Include( @_ );
    $self->asp->Response->End;
}

=item $Server->URLEncode($string)

Returns the URL-escaped version of the string C<$string>. C<+>'s are substituted
in for spaces and special characters are escaped to the ascii equivalents.
Strings encoded in this manner are safe to put in urls... they are especially
useful for encoding data used in a query string as in:

  $data = $Server->URLEncode("test data");
  $url = "http://localhost?data=$data";

C<$url> evaluates to C<http://localhost?data=test+data>, and is a
valid URL for use in anchor <a> tags and redirects, etc.

=cut

sub URLEncode {
    my ( $self, $string ) = @_;
    uri_escape_utf8( $string );
}

=item $Server->URL($url, \%params)

Will return a URL with C<%params> serialized into a query string like:

  $url = $Server->URL('test.asp', { test => value });

which would give you a URL of C<test.asp?test=value>

Used in conjunction with the C<SessionQuery>* settings, the returned URL will
also have the session id inserted into the query string, making this a critical
part of that method of implementing cookieless sessions. For more information on
that topic please read on the setting in the CONFIG section, and the SESSIONS
section too.

=cut

sub URL {
    my ( $self, $url, $params ) = @_;
    my $uri = URI->new( $url );
    $uri->query_form( $params );
    $uri->as_string;
}

=item $Server->XSLT(\$xsl_data, \$xml_data)

Not implemented.

=cut

# TODO: will not implement
sub XSLT {
    my ( $self, $xsl_dataref, $xml_dataref ) = @_;
    $self->asp->log->warn( "\$Server->XSLT has not been implemented!" );
    return;
}

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp::Session>

=item * L<Plasp::Request>

=item * L<Plasp::Response>

=item * L<Plasp::Application>

=back
