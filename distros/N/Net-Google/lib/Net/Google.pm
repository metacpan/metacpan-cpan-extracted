{

=head1 NAME

Net::Google - simple OOP-ish interface to the Google SOAP API

=head1 SYNOPSIS

 use Net::Google;
 use constant LOCAL_GOOGLE_KEY => "********************************";

 my $google = Net::Google->new(key=>LOCAL_GOOGLE_KEY);
 my $search = $google->search();

 # Search interface

 $search->query(qw(aaron straup cope));
 $search->lr(qw(en fr));
 $search->starts_at(5);
 $search->max_results(15);

 map { print $_->title()."\n"; } @{$search->results()};

 # or...

 foreach my $r (@{$search->response()}) {
   print "Search time :".$r->searchTime()."\n";

   # returns an array ref of Result objects
   # the same as the $search->results() method
   map { print $_->URL()."\n"; } @{$r->resultElements()};
 }

 # Spelling interface

 print $google->spelling(phrase=>"muntreal qwebec")->suggest(),"\n";

 # Cache interface

 my $cache = $google->cache(url=>"http://search.cpan.org/recent");
 print $cache->get();

=head1 DESCRIPTION

Provides a simple OOP-ish interface to the Google SOAP API

=head1 ENCODING

According to the Google API docs :

 "In order to support searching documents in multiple languages 
 and character encodings the Google Web APIs perform all requests 
 and responses in the UTF-8 encoding. The parameters <ie> and 
 <oe> are required in client requests but their values are ignored.
 Clients should encode all request data in UTF-8 and should expect
 results to be in UTF-8."

(This package takes care of setting both parameters in requests.)

=cut

use strict;

package Net::Google;
use base qw (Net::Google::tool);

use Carp;

$Net::Google::VERSION     = '1.0';

$Net::Google::QUERY_LIMIT = 1000;
$Net::Google::KEY_QUERIES = {};

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Valid arguments are :

=over 4

=item *

B<key>

I<string>. A Google API key.

=item *

B<http_proxy>

I<url>. A URL for proxy-ing HTTP requests.

=item *

B<debug>

Valid options are:

=over 4

=item *

I<boolean>

If true prints debugging information returned by SOAP::Lite
to STDERR

=item *

I<coderef>.

Your own subroutine for munging the debugging information
returned by SOAP::Lite.

=back

=back

Note that prior to version 0.60, arguments were not passed
by reference. Versions >= 0.60 are backwards compatible.

Returns an object. Woot!

=cut

sub new {
  my $pkg = shift;

  my $self = {};
  bless $self,$pkg;

  if (! $self->init(@_)) {
    return undef;
  }

  return $self;
}

sub init {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  $self->{'_debug'}      = $args->{'debug'};
  $self->{'_key'}        = $args->{'key'};
  $self->{'_http_proxy'} = $args->{'http_proxy'};

  # Do *not* call parent
  # class' init() method.

  return 1;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->key($string)

Get/set the Google API key for this object.

=cut

# Defined in Net::Google::tool

=head2 $obj->http_proxy($url)

Get/set the HTTP proxy for this object.

Returns a string.

=cut

# Note we subclass the method normally inherited
# from ::tool.pm. Since this is just a wrapper
# module, we don't have a SOAP thingy to actually
# set the proxy for so we'll just cache it for
# later.

sub http_proxy {
  my $self = shift;
  my $uri  = shift;

  if ($uri) {
    $self->{'_http_proxy'} = $uri;
  }

  return $self->{'_http_proxy'};
}

=head2 $obj->search(\%args)

Valid arguments are :

=over 4

=item *

B<key>

I<string>. A Google API key. 

If none is provided then the key passed to the parent 
I<Net::Google> object will be used.

=item *

B<starts_at>

I<int>. First result number to display. 

Default is 0.

=item *

B<max_results>

I<int>. Number of results to return. 

Default is 10.

=item *

B<lr>

I<string> or I<array reference>. Language restrictions.

=item *

B<safe>

I<boolean>.

=item *

B<filter>

I<boolean>.

=item *

B<http_proxy>

I<url>. A URL for proxy-ing HTTP requests.


=item *

B<debug>

Valid options are:

=over 4

=item *

I<boolean>

If true prints debugging information returned by SOAP::Lite
to STDERR

=item *

I<coderef>

Your own subroutine for munging the debugging information
returned by SOAP::Lite.

=back

=back

Note that prior to version 0.60, arguments were not passed
by reference. Versions >= 0.60 are backwards compatible.

Returns a I<Net::Google::Search> object. Woot!

Returns undef if there was an error.

=cut

sub search {
  my $self = shift;
  require Net::Google::Search;
  return Net::Google::Search->new($self->_parse_args(@_));
}

=head2 $obj->spelling(\%args)

Valid arguments are:

=over 4

=item *

B<key>

I<string>. A Google API key. 

If none is provided then the key passed to the parent 
I<Net::Google> object will be used.

=item *

B<phrase>

I<string> or I<array reference>.

=item *

B<http_proxy>

I<url>. A URL for proxy-ing HTTP requests.

=item *

B<debug>

=over 4

=item *

B<boolean>

Prints debugging information returned by SOAP::Lite to STDERR

=item *

B<coderef>

Your own subroutine for munging the debugging information
returned by SOAP::Lite.

=back

If no option is defined then the debug argument passed to the parent
I<Net::Google> object will be used.

=back

Note that prior to version 0.60, arguments were not passed
by reference. Versions >= 0.60 are backwards compatible.

Returns a I<Net::Google::Spelling> object. Woot!

Returns undef if there was an error.

=cut

sub spelling {
  my $self = shift;
  require Net::Google::Spelling;
  return Net::Google::Spelling->new($self->_parse_args(@_));
}

# Small things are good because you can
# fit them in your hand *and* your mouth.

sub speling { return shift->spelling(@_); }

=head2 $obj->cache(\%args)

Valid arguments are :

=over 4

=item *

B<key>

String. Google API key. 

If none is provided then the key passed to the parent I<Net::Google> 
object will be used.

=item *

B<url>

I<string>

=item *

B<http_proxy>

I<url>. A URL for proxy-ing HTTP requests.

=item *

B<debug>

Valid options are:

=over 4

=item *

I<boolean>

If true, prints debugging information returned by SOAP::Lite
to STDERR

=item *

I<coderef>

Your own subroutine for munging the debugging information
returned by SOAP::Lite.

=back

If no option is defined then the debug argument passed to the parent
I<Net::Google> object will be used.

=back

Note that prior to version 0.60, arguments were not passed
by reference. Versions >= 0.60 are backwards compatible.

Returns a I<Net::Google::Cache> object. Woot!

Returns undef if there was an error.

=cut

sub cache {
  my $self = shift;
  require Net::Google::Cache;
  return Net::Google::Cache->new($self->_parse_args(@_));
}

=head2 $obj->queries_exhausted() 

Returns true or false depending on whether or not the current in-memory
B<session> has exhausted the Google API 1000 query limit.

=cut

# Defined in Net::Google::tool

#

sub _parse_args {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  foreach my $el ("key","debug","http_proxy") {
    next if (defined($args->{$el}));
    $args->{$el} = $self->{"_$el"};
  }

  return $args;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 20:49:03 $

=head1 AUTHOR

Aaron Straup Cope

=head1 CONTRIBUTORS

Marc Hedlund <marc@precipice.org>

=head1 SEE ALSO

http://www.google.com/apis

L<Net::Google::Search>

L<Net::Google::Spelling>

L<Net::Google::Cache>

L<Net::Google::Response>

L<Net::Google::Service>

http://aaronland.info/weblog/archive/4231

=head1 TO DO

=over 4

=item *

Tickle the tests so that they will pass on systems without
Test::More.

=item *

Add tests for filters.

=item *

Add some sort of functionality for managing multiple keys. 
Sort of like what is describe here :

http://aaronland.net/weblog/archive/4204

This will probably happen around the time Hell freezes over
so if you think you can do it faster, go nuts.

=back

=head1 BUGS

Please report all bugs via http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;

}
