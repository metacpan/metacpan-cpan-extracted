{

=head1 NAME

Net::Google::Cache - simple OOP-ish interface to the Google SOAP API for 
cached documents

=head1 SYNOPSIS

 use Net::Google::Cache;
 my $cache = Net::Google::Cache(\%args);

 $cache->url("http://aaronland.net);
 print $cache->get();

=head1 DESCRIPTION

Provides a simple OOP-ish interface to the Google SOAP API for cached 
documents.

This package is used by I<Net::Google>.

=cut

use strict;
package Net::Google::Cache;
use base qw (Net::Google::tool);

use Carp;

$Net::Google::Cache::VERSION   = '1.0';

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Valid arguments are :

=over 4

=item *

B<key>

I<string>. A Google API key. 

If none is provided then the key passed to the parent I<Net::Google>
object will be used.

=item *

B<url>

I<string>.

=item *

B<http_proxy>

I<url>. 

Get/set the URL for proxy-ing HTTP request.

Returns a string.

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

The object constructor in Net::Google 0.53, and earlier, expected
a I<GoogleSearchService> object as its first argument followed by
 a hash reference of argument. Versions 0.6 and higher are backwards 
compatible.

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

  my $args = $self->SUPER::init("cache",@_)
    || return 0;

  #

  if ($args->{'url'}) {
    $self->url($args->{'url'});
  }

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

# Defined in Net::Google::tool

=head2 $pkg->url($url)

Set the cached URL to fetch from the Google servers. 

Returns a string. Returns an undef if there was an error.

=cut

sub url {
  my $self = shift;
  my $url  = shift;

  if (defined($url)) {
    $self->{'_url'} = $url;
  }

  return $self->{'_url'};
}

=head2 $pkg->get()

Fetch the requested URL from the Google servers.

Returns a string. Returns undef if there was an error.

=cut

sub get {
  my $self = shift;

  $self->_queries(1);

  return $self->{'_service'}->doGetCachedPage(
					      $self->key(),
					      $self->url(),
					     );
}

=head2 $obj->queries_exhausted() 

Returns true or false depending on whether or not the current in-memory
B<session> has exhausted the Google API 1000 query limit.

=cut

# Defined in Net::Google::tool

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 20:49:03 $

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over 4

=item *

Add hooks to I<get> method to strip out Google headers and footers from cached pages.

=back

=head1 SEE ALSO

L<Net::Google>

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
