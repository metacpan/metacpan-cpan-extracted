package Rose::URI;

use strict;

use Carp();
use URI::Escape();

use Rose::Object;
our @ISA = qw(Rose::Object);

use overload
(
  '""'   => sub { shift->as_string },
  'bool' => sub { length shift->as_string },
   fallback => 1,
);

our $Make_URI;

our $SCHEME_RE = '[a-zA-Z][a-zA-Z0-9.+\-]*';

our $VERSION = '1.00';

# Class data
use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar => 
  [
    'default_query_param_separator',
    'default_omit_empty_query_params',
  ],
);

# Object data
use Rose::Object::MakeMethods::Generic
(
  scalar =>
  [
    'username',
    'password',
    'scheme',
    'host',
    'port',
    'path',
    'fragment',
    'query_param_separator' => { interface => 'get_set_init' },
  ],
);

__PACKAGE__->default_query_param_separator('&');
__PACKAGE__->default_omit_empty_query_params(0);

sub init_query_param_separator { ref(shift)->default_query_param_separator }

sub new
{
  my($class) = shift;

  my $self =
  {
    username => '',
    password => '',
    scheme   => '',
    host     => '',
    port     => '',
    path     => '',
    query    => {},
    fragment => '',
  };

  bless $self, $class;

  $self->init(@_);

  return $self;
}

sub init
{
  my($self) = shift;

  if(@_ == 1)
  {
    $self->init_with_uri(@_);
  }
  else
  {
    $self->SUPER::init(@_);
  }
}

sub init_with_uri
{
  my($self) = shift;

  $self->$Make_URI($_[0]);
}

sub clone
{
  my($self) = shift;
  return bless _deep_copy($self), ref($self);
}

sub parse_query
{
  my($self, $query) = @_;

  $self->{'query_string'} = undef;

  unless(defined $query && $query =~ /\S/)
  {
    $self->{'query'} = { };
    return 1;
  }

  my @params;

  if(index($query, '&') >= 0)
  {
    @params = split(/&/, $query);
  }
  elsif(index($query, ';') >= 0)
  {
    @params = split(/;/, $query);
  }
  elsif(index($query, '=') < 0)
  {
    $self->{'query_string'} = __unescape_uri($query);
    $self->{'query'} = { $self->{'query_string'} => undef };
    return 1;
  }

  @params = ($query)  unless(@params);

  my %query;

  foreach my $item (@params)
  {
    my($param, $value) = map { __unescape_uri($_) } split(/=/, $item);

    $param = __unescape_uri($item)  unless(defined($param));

    if(exists $query{$param})
    {
      if(ref $query{$param})
      {
        push(@{$query{$param}}, $value);
      }
      else
      {
        $query{$param} = [ $query{$param}, $value ];
      }
    }
    else
    {
      $query{$param} = $value;
    }
  }

  $self->{'query'} = \%query;

  return 1;
}

sub query_hash
{
  my($self) = shift;

  return (wantarray) ? %{$self->{'query'}} : { %{$self->{'query'}} };
}

sub omit_empty_query_params
{
  my($self) = shift;

  if(@_)
  {
    return $self->{'omit_empty_query_params'} = $_[0] ? 1 : 0;
  }

  return defined $self->{'omit_empty_query_params'} ?
    $self->{'omit_empty_query_params'} : ref($self)->default_omit_empty_query_params;
}

sub query_param
{
  my($self) = shift;

  if(@_ == 1)
  {
    return $self->{'query'}{$_[0]}  if(exists $self->{'query'}{$_[0]});
    return;
  }
  elsif(@_ == 2)
  {
    $self->{'query_string'} = undef;

    if(ref $_[1])
    {
      return $self->{'query'}{$_[0]} = [ @{$_[1]} ];
    }

    return $self->{'query'}{$_[0]} = $_[1];
  }

  Carp::croak "query_param() takes either one or two arguments";
}

sub query_params
{
  my($self) = shift;

  return sort keys %{$self->{'query'}}  unless(@_);

  my $params = $self->query_param(@_);

  $params = (ref $params) ? [ @$params ] : 
            (defined $params) ? [ $params ] : [];

  return (wantarray) ? @$params : $params;
}

sub query_param_add
{
  my($self, $name, $value) = @_;

  Carp::croak "query_add_param() takes two arguments"  unless(@_ == 3);

  my $params = $self->query_params($name);

  push(@$params, (ref $value) ? @$value : $value);

  $self->query_param($name => (@$params > 1) ? $params : $params->[0]);

  return (wantarray) ? @$params : $params;
}

sub query_param_exists
{
  my($self, $param) = @_;

  Carp::croak "Missing query param argument"  unless(defined $param);

  return exists $self->{'query'}{$param};
}

sub query_param_delete
{
  my($self) = shift;

  Carp::croak "query_param_delete() takes one or more arguments"  unless(@_);

  foreach my $param (@_)
  {
    if(defined $self->{'query_string'} && $param eq $self->{'query_string'})
    {
      $self->{'query_string'} = undef;
    }

    delete $self->{'query'}{$param};
  }
}

sub as_string
{
  my($self) = shift;

  my $scheme = $self->scheme;
  my $user   = $self->userinfo_escaped;
  my $port   = $self->port;
  my $query  = $self->query;
  my $frag   = __escape_uri($self->fragment);

  return ((length $scheme) ? "$scheme://" : '') .
         ((length $user) ? "$user\@" : '') .
         $self->host .
         ((length $port) ? ":$port" : '') .
         __escape_uri_whole($self->path) . 
         ((length $query) ? "?$query" : '') .
         ((length $frag) ? "#$frag" : '');
}

sub query
{
  my($self) = shift;

  if(@_ == 1)
  {
    if(ref $_[0])
    {
      $self->{'query'} = _deep_copy($_[0])
    }
    else
    {
      $self->parse_query($_[0]);
    }
  }
  elsif(@_)
  {
    $self->{'query'} = _deep_copy({ @_ });
  }

  my $want = wantarray;

  return  unless(defined wantarray);

  if(defined $self->{'query_string'})
  {
    return __escape_uri($self->{'query_string'});
  }

  my(@query, $omit_empty);

  foreach my $param (sort keys %{$self->{'query'}})
  {
    my @values = $self->query_params($param);

    # Contortions to avoid calling this method in the common(?) case where
    # every query parameter has at least one value.
    if(!@values && !(defined $omit_empty ? $omit_empty : ($omit_empty = $self->omit_empty_query_params)))
    {
      @values = ('');
    }

    foreach my $value (@values)
    {
      push(@query, __escape_uri($param) . '=' . __escape_uri($value));
    }
  }

  return join($self->query_param_separator, @query);
}

sub query_form
{
  my($self) = shift;

  if(@_)
  {
    $self->{'query_string'} = undef;
    $self->{'query'} = { };

    for(my $i = 0; $i < $#_; $i += 2)
    {
      $self->query_param_add($_[$i] => $_[$i + 1]);
    }
  }

  return  unless(defined(wantarray));

  my @query;

  foreach my $param ($self->query_params)
  {
    foreach my $value ($self->query_params($param))
    {
      push(@query, $param, $value);
    }
  }

  return @query;
}

sub abs
{
  my($self, $base) = @_;

  return $self  unless($base && !length $self->scheme);

  my $new = $self->as_string;

  $new  =~ s{^/}{};
  $base =~ s{/$}{};

  return Rose::URI->new("/$new")  unless($base =~ m{^$SCHEME_RE://}o);
  return Rose::URI->new("$base/$new");
}

sub rel
{
  my($self, $base) = @_;

  return $self  unless($base);

  my $uri = $self->as_string;

  if($uri =~ m{^$base/?})
  {
    $uri =~ s{^$base/?}{};

    return Rose::URI->new($uri);
  }

  return $self;
}

sub userinfo
{
  my($self) = shift;

  my $user = $self->username;
  my $pass = $self->password;

  if(length $user && length $pass)
  {
    return join(':', $user, $pass);
  }

  return $user  if(length $user);
  return '';
}

sub userinfo_escaped
{
  my($self) = shift;

  my $user = __escape_uri($self->username);
  my $pass = __escape_uri($self->password);

  if(length $user && length $pass)
  {
    return join(':', $user, $pass);
  }

  return $user  if(length $user);
  return '';
}

sub __uri_from_apache_uri
{
  my($self) = shift;

  my $uri = Apache::URI->parse(Apache->request, @_);

  $self->{'username'} = $uri->user     || '';
  $self->{'password'} = $uri->password || '';
  $self->{'scheme'}   = $uri->scheme   || '';
  $self->{'host'}     = $uri->hostname || '';
  $self->{'port'}     = $uri->port     || '';
  $self->{'path'}     = $uri->path     || '';
  $self->{'fragment'} = $uri->fragment || '';

  $self->parse_query($uri->query);

  return $uri;
}

sub __uri_from_uri
{
  my($self) = shift;

  my $uri = URI->new(@_);

  if($uri->can('user'))
  {
    $self->{'username'} = $uri->user;
  }
  elsif($uri->can('userinfo'))
  {
    if(my $userinfo = $uri->userinfo)
    {
      if(my($user, $pass) = split(':', $userinfo))
      {
        $self->{'username'} = __unescape_uri($user);
        $self->{'password'} = __unescape_uri($pass);
      }
    }
  }

  $self->{'scheme'}   = __unescape_uri($uri->scheme   || '');
  $self->{'host'}     = __unescape_uri($uri->host     || '')  if($uri->can('host'));
  $self->{'port'}     = __unescape_uri($uri->_port    || '')  if($uri->can('_port'));
  $self->{'path'}     = __unescape_uri($uri->path     || '')  if($uri->can('path'));
  $self->{'fragment'} = __unescape_uri($uri->fragment || '');

  $self->parse_query($uri->query);

  return $uri;
}

if(exists $ENV{'MOD_PERL'} && require mod_perl && $mod_perl::VERSION < 1.99)
{
  require Apache;
  require Apache::URI;
  require Apache::Util;

  *__escape_uri   = \&Apache::Util::escape_uri;
  *__unescape_uri = \&Apache::Util::unescape_uri_info;

  $Make_URI = \&__uri_from_apache_uri;
}
else
{
  *__escape_uri   = \&URI::Escape::uri_escape;
  *__unescape_uri = sub 
  {
    my $e = URI::Escape::uri_unescape(@_);

    $e =~ s/\+/ /g;

    return $e;
  };

  require URI;
  $Make_URI = \&__uri_from_uri;
}

sub __escape_uri_whole
{
  URI::Escape::uri_escape($_[0], 
    (@_ > 1) ? (defined $_[1] ? $_[1] : ()) : q(^A-Za-z0-9\-_.,'!~*#?&()/?@\:\[\]=));
}

# Based on code from Clone::PP
sub _deep_copy
{
  my($data) = shift;

  my $ref_type = ref $data or return $data;

  my $copy;

  if($ref_type eq 'HASH')
  {
    $copy = {};
    %$copy = map { !ref($_) ? $_ : _deep_copy($_) } %$data;
  }
  elsif($ref_type eq 'ARRAY')
  {
    $copy = [];
    @$copy = map { !ref($_) ? $_ : _deep_copy($_) } @$data;
  }
  elsif($ref_type eq 'REF' or $ref_type eq 'SCALAR') 
  {
    $copy = \(my $var = '');
    $$copy = _deep_copy($$data);
  }
  elsif($ref_type->isa(__PACKAGE__)) # cloning
  {
    $copy = _deep_copy({ %{$data} });
  }
  else
  {
    $copy = $data;
  }

  return $copy;
}

1;

__END__

=head1 NAME

Rose::URI - A URI class that allows easy and efficient manipulation of URI components.

=head1 SYNOPSIS

    use Rose::URI;

    $uri = Rose::URI->new('http://un:pw@foo.com/bar/baz?a=1&b=two+3');

    $scheme = $uri->scheme;
    $user   = $uri->username;
    $pass   = $uri->password;
    $host   = $uri->host;
    $path   = $uri->path;
    ...

    $b = $uri->query_param('b');  # $b = "two 3"
    $a = $uri->query_param('a');  # $a = 1

    $uri->query_param_delete('b');
    $uri->query_param('c' => 'blah blah');
    ...

    print $uri;

=head1 DESCRIPTION

L<Rose::URI> is an alternative to L<URI>.  The important differences are as follows.

L<Rose::URI> provides a rich set of query string manipulation methods. Query parameters can be added, removed, and checked for their existence. L<URI> allows the entire query to be set or returned as a whole via the L<query_form|URI/query_form> or L<query|URI/query> methods, and the L<URI::QueryParam> module provides a few more methods for query string manipulation.

L<Rose::URI> supports query parameters with multiple values (e.g. "a=1&a=2"). L<URI> has  limited support for this through L<query_form|URI/query_form>'s list return value.  Better methods are available in L<URI::QueryParam>.

L<Rose::URI> uses Apache's C-based URI parsing and HTML escaping functions when running in a mod_perl 1.x web server environment.

L<Rose::URI> stores each URI "in pieces" (scheme, host, path, etc.) and then assembles those pieces when the entire URI is needed as a string. This technique is based on the assumption that the URI will be manipulated many more times than it is stringified.  If this is not the case in your usage scenario, then L<URI> may be a better alternative.

Now some similarities: both classes use the L<overload> module to allow "magic" stringification.  Both L<URI> and L<Rose::URI> objects can be printed and compared as if they were strings.

L<Rose::URI> actually uses the L<URI> class to do the heavy lifting of parsing URIs when not running in a mod_perl 1.x environment.

Finally, a caveat: L<Rose::URI>  supports only "http"-like URIs.  This includes ftp, http, https, and other similar looking URIs. L<URI> supports many more esoteric URI types (gopher, mailto, etc.) If you need to support these formats, use L<URI> instead.

=head1 CONSTRUCTOR

=over 4

=item B<new [ URI | PARAMS ]>

Constructs a URI object based on URI or PARAMS, where URI is a string and PARAMS are described below. Returns a new L<Rose::URI> object.

The query string portion of the URI argument may use either "&" or ";" as the parameter separator. Examples:

    $uri = Rose::URI->new('/foo?a=1&b=2');
    $uri = Rose::URI->new('/foo?a=1;b=2'); # same thing

The L<query_param_separator|/query_param_separator> parameter determines what is used when the query string (or the whole URI) is output as a string later.

L<Rose::URI> uses L<URI> or L<Apache::URI> (when running under mod_perl 1.x) to do its URI string parsing.

Valid PARAMS are:

    fragment
    host
    password
    path
    port
    query
    scheme
    username

    query_param_separator

Which correspond to the following URI pieces:

    <scheme>://<username:password>@<path>?<query>#<fragment>

All the above parameters accept strings.  See below for more information about the L<query|/query> parameter.  The L<query_param_separator|/query_param_separator> parameter determines the separator used when constructing the query string.  It is "&" by default (e.g. "a=1&b=2")

=back


=head1 CLASS METHODS

=over 4

=item B<default_omit_empty_query_params [BOOL]>

Get or set a boolean value that determines whether or not query parameters with "empty" (that is, undef or zero-length) values will be omitted from the L<query|/query> string by default.  The default value is false.

=item B<default_query_param_separator [CHARACTER]>

Get or set the character used to separate query parameters in the stringified version of L<Rose::URI> objects.  Defaults to "&".

=back

=head1 OBJECT METHODS

=over 4

=item B<abs [BASE]>

This method exists solely for compatibility with L<URI>.

Returns an absolute L<Rose::URI> object.  If the current URI is already absolute, then a reference to it is simply returned.  If the current URI is relative, then a new absolute URI is constructed by combining the URI and the BASE, and returned.

=item B<as_string>

Returns the URI as a string.  The string is "URI escaped" (reserved URI characters are replaced with %xx sequences), but not "HTML escaped" (ampersands are not escaped, for example).

=item B<clone>

Returns a copy of the L<Rose::URI> object.

=item B<fragment [FRAGMENT]>

Get or set the fragment portion of the URI.

=item B<omit_empty_query_params [BOOL]>

Get or set a boolean value that determines whether or not query parameters with "empty" (that is, undef or zero-length) values will be omitted from the L<query|/query> string.  The default value is determined by the L<default_query_param_separator|/default_query_param_separator> class method.

=item B<password [PASSWORD]>

Get or set the password portion of the URI.

=item B<path [PATH]>

Get or set the path portion of the URI.

=item B<port [PORT]>

Get or set the port number portion of the URI.

=item B<query [QUERY]>

Get or sets the URI's query.  QUERY may be an appropriately escaped query string (e.g. "a=1&b=2&c=a+long+string"), a reference to a hash, or a list of name/value pairs.

Query strings may use either "&" or ";" as their query separator. If a "&" character exists anywhere in the query string, it is assumed to be the separator.

If none of the characters "&", ";", or "=" appears in the query string, then the entire query string is taken as a single parameter name with an undefined value.

Hashes and lists should specify multiple parameter values using array references.

Here are some examples representing the query string "a=1&a=2&b=3"

    $uri->query("a=1&a=2&b=3");             # string
    $uri->query("a=1;a=2;b=3");             # same thing
    $uri->query({ a => [ 1, 2 ], b => 3 }); # hash ref
    $uri->query(a => [ 1, 2 ], b => 3);     # list

Returns the current (or new) query as a URI-escaped (but not HTML-escaped) query string.

=item B<query_form QUERY>

Implementation of L<URI>'s method of the same name.  This exists for backwards compatibility purposes only and should not be used (or necessary).  See the L<URI> documentation for more details.

=item B<query_hash>

Returns the current query as a hash (in list context) or reference to a hash (in scalar context), with multiple parameter values represented by array references (see the L<query|/query> method for details).

The return value is a shallow copy of the actual query hash.  It should be treated as read-only unless you really know what you are doing.

Example:

    $uri = Rose::URI->new('/foo?a=1&b=2&a=2');

    $h = $uri->query_hash; # $h = { a => [ 1, 2 ], b => 2 }

=item B<query_param NAME [, VALUE]>

Get or set a query parameter.  If only NAME is passed, it returns the value of the query parameter named NAME.  Parameters with multiple values are returned as array references.  If both NAME and VALUE are passed, it sets the parameter named NAME to VALUE, where VALUE can be a simple scalar value or a reference to an array of simple scalar values.

Examples:

    $uri = Rose::URI->new('/foo?a=1');

    $a = $uri->query_param('a'); # $a = 1

    $uri->query_param('a' => 3); # query string is now "a=3"

    $uri->query_param('b' => [ 4, 5 ]); # now "a=3&b=4&b=5"

    $b = $uri->query_param('b'); # $b = [ 4, 5 ];

=item B<query_params NAME [, VALUE]>

Same as the L<query_param|/query_param> method, except the return value is always either an array (in list context) or reference to an array (in scalar context), even if there is only one value.

Examples:

    $uri = Rose::URI->new('/foo?a=1&b=1&b=2');

    $a = $uri->query_params('a'); # $a = [ 1 ]
    @a = $uri->query_params('a'); # @a = ( 1 )

    $b = $uri->query_params('a'); # $b = [ 1, 2 ]
    @b = $uri->query_params('a'); # @b = ( 1, 2 )

=item B<query_param_add NAME, VALUE>

Adds a new value to a query parameter.   Example:

    $uri = Rose::URI->new('/foo?a=1&b=1');

    $a = $uri->query_param_add('b' => 2); # now "a=2&b=1&b=2"

Returns an array (in list context) or reference to an array (in scalar context) of the new parameter value(s).

=item B<query_param_delete NAME>

Deletes all instances of the parameter named NAME from the query.

=item B<query_param_exists NAME>

Returns a boolean value indicating whether or not a parameter named NAME exists in the query string.

=item B<query_param_separator [CHARACTER]>

Get or set the character used to separate query parameters in the stringified version of the URI.  Defaults to the return value of the L<default_query_param_separator|/default_query_param_separator> class method ("&" by default).

=item B<rel BASE>

This method exists solely for compatibility with L<URI>.

Returns a relative URI reference if it is possible to make one that denotes the same resource relative to BASE.  If not, then the current URI is simply returned.

=item B<scheme [SCHEME]>

Get or set the scheme portion of the URI.

=item B<userinfo>

Returns the L<username|/username> and L<password|/password> attributes joined by a ":" (colon). The username and password are not escaped in any way. If there is no password, only the username is returned (without the colon).  If neither exist, an empty string is returned.

=item B<userinfo_escaped>

Returns the L<username|/username> and L<password|/password> attributes joined by a ":" (colon). The username and password are URI-escaped, but not HTML-escaped. If there is no password, only the username is returned (without the colon).  If neither exist, an empty string is returned.

=item B<username [USERNAME]>

Get or set the username portion of the URI.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
