package Plack::Middleware::Session::SerializedCookie;
use strict;
use warnings;

use 5.008;

use parent 'Plack::Middleware';
use Plack::Request;
use Plack::Response;
use Carp;

our $VERSION = 1.03;

sub prepare_app {
    my $self = shift;

    $self->{session_key} = 'plack_session' if ! defined $self->{session_key};

    for my $fname ( qw( serialize deserialize ) ) {
	$self->{$fname} ||= $self->{serializer} && $self->{serializer}->can($fname) && sub { $self->{serializer}->$fname(@_) } || croak __PACKAGE__.": No '$fname' installed!!"
    }

    $self->{cookie_options} = +{ map { $_ => delete $self->{$_} } grep { exists $self->{$_} } qw(path domain secure) };
}

sub call {
    my($self, $env) = @_;

    my $cookie = Plack::Request->new($env)->cookies->{$self->{session_key}}; 
    $env->{'psgix.session'} = eval { $self->{deserialize}->( defined($cookie) ? $cookie : undef ) };
    $self->{deserialize_exception}->($@) if $@ && $self->{deserialize_exception};

    my $res = $self->app->($env);

    $self->response_cb( $res, sub {
	my $res = shift;
	my $response = Plack::Response->new(@$res);
	$self->{cookie_options}->{expires} = time + $self->{expires} if exists $self->{expires};
	$response->cookies->{$self->{session_key}} = $self->{cookie_options};
	if( !defined($env->{'psgix.session'}) || $env->{'psgix.session.option'} && $env->{'psgix.session.option'}{expire} ) {
	    local $self->{cookie_options}{expires} = 1;
	    $res->[1] = $response->finalize->[1];
	}
	else {
	    eval {
		local $self->{cookie_options}{value} =  $self->{serialize}->($env->{'psgix.session'});
		$res->[1] = $response->finalize->[1];
	    };
	    $self->{serialize_exception}->($@) if $@ && $self->{serialize_exception};
	}
    } );
}

1;

=head1 NAME

Plack::Middleware::Session::SerializedCookie -
Session middleware that saves session data in
the customizable serialized cookie

=head1 SYNOPSIS

  # With serialize/deserialize subs

  enable "Session::SerializedCookie",
    serialize => sub {
	my $session = shift;
	...
	return $serialized_session
    },
    deserialize => sub {
	my $serialized_session = shift;
	...
    return $session };


  # With Serializer (object that
  #   implements 'serialize' and 'deserialize')

  enable "Session::SerializedCookie",
    serializer => Data::Serializer->new(...);


  # Mixed case

  my $serializer = Data::Serializer->new(...);
  enable "Session::SerializedCookie",
    serializer => $serializer,
    deserialize => sub {
	my $session = eval { $serializer->deserialize(@_) };
	$session = { ... (initial session) ... } if $@;
	return $session;
    };
  # The missing sub 'serialize' will fall back
  #   to use the serializer's one.


  # Additional exception handler

  enable "Session::SerializedCookie",
    serializer => Data::Serializer->new(...),
    serialize_exception => sub { my $error_msg = shift; ... },
    deserialize_exception => sub { my $error_msg = shift; ... };


  # In the app

  sub {
    my $env = shift;

    # Retrieve the session by $env->{'psgix.session'}
    # If the session is not presented, or something goes wrong when retrieving,
    # it'll be set to {}, an empty hash reference.
    my $session = $env->{'psgix.session'};
    ...

    $session->{blah} = 'blah blah';

    # At the end of the app, $env->{'psgix.session'} will be stored
    # to the cookie automatically.
    # To expire the session, undef the $env->{'psgix.session'} or
    # set $env->{'psgix.session.option'}{expire} = 1
  };


  # For full and more examples, take a look on eg/ directory.

=head1 DESCRIPTION

This middleware component works like L<Plack::Middleware::Session>,
that it provide a simple way to retrieve and store session data
via $env->{'psgix.session'}. It store the session data in the cookie
like what L<Plack::Middleware::Session::Cookie> do, that doesn't
need to store any data in the server side.

In addition, this module provide a convenient way to customize
the way to serialize / deserialize the session data.

It is sometimes important to customize the serializer because of
various application. Someone might need to store critical data in
the session. Someone might need to store large data there.
Some one might need just a simplest and fastest one, and
don't care if the user can arbitrarily modify the session data.

=head1 CONFIGURATIONS

=over 4

=item session_key

This is used as the cookie name

=item path, domain, secure

These are used as the cookie params.
See L<Plack::Response> for these options.

=item expires

This one is used as an advance time from the request time.

=item serialize

Set this attribute to a sub reference. It will be called
when serializing. The only argument is the session data,
$env->{'psgix.session'} in fact. And this sub should return
the serialized one.

If this attribute is not presented. This module will try
to use the serializer's member sub 'serialize'.

=item deserialize

Set this attribute to a sub reference. It is the inverse of
serialize. It will get the serialized session as the only
argument, and should return the session data.

Like 'serialize', if this attribute is missed, the module
will try to use serializer's one.

=item serializer

Set this attribute to an object. When 'serialize' or 'deserialize'
is missed, the module will use this object's.

=item serialize_exception, deserialize_exception

If there is anything wrong when serializing or deserializing,
the coresponding sub will be called with the error message ($@)
as the only argument.

Note that exception is expensive. You should avoid exception
when possible, if the efficiency is important at your application.

=back

=head1 CONSIDERATION

When customizing your own serializing method, there are some issues
that you might need to consider.

=over 4

=item serializer

This is the primary part of serialization, to transform a bunch of data
into a string, and to transform a string back to the original data.

There are several well-known serialization method, such as L<Data::Dumper>,
L<JSON>, L<YAML>, L<PHP::Serialization>, L<Data::DumpXML>, etc. Each of them
has different benefits and different limits. You should read their documents
for more information.

My favorite one is L<JSON>. It will try to use L<JSON::XS> when availible.
This one is both efficient and simple. Though you can only store opaque
data structure with array reference, hash reference, string, and number
data types. You can't store other types such as code reference, blessed object,
tied data, nor references that refer to the same variable or cyclic references (L<JSON>
will extract them independently and completely).

=item base64

It's not allowed to use all the octet codes as the cookie value.
It's a safer way to encode your serialized string into base64 form.
You may take a look on L<MIME::Base64>.

Note, you should use this as the final filter, or it will be useless.

=item encryption

Sometimes, you may want to store critical data in the session,
that you don't want the user to know what you have store there.
You may consider to encrypt the session.
My favorite one is AES (L<Crypt::Rijndael>).

Besides, to encrypt session can avoid the user to change the session.
If you just want to prevent the user to change the session, but don't
care if the user could read its content, it's not neccessary to encrypt it.
You can use signature instead. See the section L</signature>.

=item compression

The browser will not allow to store very large cookie data.
You may need to compress it. Though, to think of storing smaller data in session
might be a much better approach.

You may use L<Compress::Zlib> to achieve this.

=item additional data

Besides to filter the whole session, you may want to just put additional data,
that could help you to do some verification.

You can store the additional data
by concating them with the serialized string (if they are string form already),

  $serialized_session = join ',', $serialized_session, $addition1, $addition2

or more generally injecting into the session data structure before serialization.

  $session = [$session, $addition1, $addition2]

=over 4

=item signature

Use a one-way hash function to generate the signature from the serialized session
string and a secret string. The users cannot generate the signatures by themselves
without knowing about the secret string. So they can't generate arbitrary session
data with correct signatures.

There are many one-way hash functions availible, such as SHA1, SHA2, MD5, MD6, etc.

It's no need to use signature, if you've encrypted the session.

=item timestamp

With timestamp, you can expire old session strictly. That is, even the browser
never expires the cookie, you can still expire it by rejecting old timestamp.

=item ip address

This is a more aggresive way to prevent the unwelcome bad guy from
stealing the session.

Use this feature cautiously. It will block users who change their ip address rapidly.
On the other hand, it's useless if the bad guy is using the same ip address as the
user, 'cause they are at the same intranet, or the bad guy is the spyware on the
same computer.

=back

=back

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 SEE ALSO

L<Plack::Middleware::Session>
L<Plack::Middleware::Session::Cookie>

=cut
