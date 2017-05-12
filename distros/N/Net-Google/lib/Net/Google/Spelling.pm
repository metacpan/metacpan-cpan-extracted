{

=head1 NAME

Net::Google::Spelling - simple OOP-ish interface to the Google SOAP API for spelling suggestions

=head1 SYNOPSIS

 use Net::Google::Spelling;
 my $spelling = Net::Google::Spelling(\%args);

 $spelling->phrase("muntreal qweebec");
 print $spelling->suggest()."\n";

=head1 DESCRIPTION

Provides a simple OOP-ish interface to the Google SOAP API for
spelling suggestions.

This package is used by I<Net::Google>.

=cut

use strict;

package Net::Google::Spelling;
use base qw (Net::Google::tool);

use Carp;

$Net::Google::Spelling::VERSION   = '1.0';

=head1 PACKAGE METHODS

=cut

=head2 $pkg = __PACKAGE__->new(\%args)

Valid arguments are :

=over 4

=item *

B<key>

I<string>.A Google API key.

If none is provided then the key passed to the parent I<Net::Google>
object will be used.

=item *

B<phrase>

I<string> or I<array reference>.

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
  my $self    = shift;

  my $args = $self->SUPER::init("spelling",@_)
    || return 0;

  #

  if ($args->{'phrase'}) {
    defined($self->phrase( (ref($args->{'phrase'}) eq "ARRAY") ? @{$args->{'phrase'}} : $args->{'phrase'} )) || return 0;
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

=head2 $obj->phrase(@words)

Add one or more words to the phrase you want to spell-check.

If the first item in I<@words> is empty, then any existing I<phrase> 
data will be removed before the new data is added.

Returns a string. Returns undef if there was an error.

=cut

sub phrase {
  my $self  = shift;
  my @words = @_;

  if ((scalar(@words) > 1) && ($words[0] == "")) {
    $self->{'_phrase'} = [];
  }

  if (@words) {
    push @{$self->{'_phrase'}} , @words;
  }

  return join("",@{$self->{'_phrase'}});
}

=head2 $obj->suggest()

Fetch the spelling suggestion from the Google servers.

Returns a string. Returns undef if there was an error.

=cut

sub suggest {
  my $self = shift;

  $self->_queries(1);

  return $self->{'_service'}->doSpellingSuggestion(
						   $self->key(),
						   $self->phrase(),
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

=head1 SEE ALSO

L<Net::Google>

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same 
terms as Perl itself.

=cut

return 1;

}
