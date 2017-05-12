=head1 NAME

Net::Lookup::DotTel - Look up information related to a .tel domain name (or
possible another domain name having .tel-style TXT and NAPTR records).

=head1 DESCRIPTION

This module offers an easy way to access the contact information that is
stored in DNS through NAPTR and TXT records under the .tel TLD.

=head1 SYNOPSIS

 use Net::Lookup::DotTel;
 my $lookup = Net::Lookup::DotTel->new;

 if ( $lookup->lookup ( 'smallco.tel' )) {

   my $service = $lookup->get_services ( 'email' );

   if ( $service->{uri} =~ /^mailto:(.+)/ ) {
     my $email = $1;
     print "SmallCo's email address is $email\n";
   }

 }

=head1 METHODS

=cut

package Net::Lookup::DotTel;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp;
use Net::DNS;

=head2 new

 $lookup = Net::Lookup::DotTel->new;
 $lookup = Net::Lookup::DotTel->new ( resolver_config => $resolver_settings );

Constructor. The following optional named parameters can be specified:

=over

=item * resolver_config

A reference to an array containing information be passed to
Net::DNS::Resolver->new. E.g., to specify your own resolving nameservers,
you can do:

 $lookup = Net::Lookup::DotTel->new (
   resolver_config => [
     nameservers => [ '192.168.1.1', '192.168.2.1' ]
   ]
 );

=back

=cut

sub new {

  my $class = shift;
  my %param = @_;

  my $self = {};
  $self->{resolver} = Net::DNS::Resolver->new ( @{$param{resolver_config} || []} );

  bless $self, $class;

}

=head2 lookup

 $lookup->lookup ( 'smallco.tel' );

Lookup the specified domain name. Returns 1 if the domain name exists or 0
otherwise. Note that the fact that a domain exists does not mean that it has
any meaningful TXT or NAPTR records associated with it.

If the lookup was succesful, you can use the other methods to extract
information from this domain.

=cut

sub lookup {

  my $self = shift;
  my ( $domain ) = @_;

  croak "No domain specified" unless ( $domain );

  if ( my $response = $self->{resolver}->query ( $domain, 'ANY' )) {
    $self->{current_domain} = ( $response->question )[0]->qname;
    return 1;
  }

  return 0;

}

=head2 get_keywords

 @keywords = $lookup->get_keywords;
 @keywords = $lookup->get_keywords ( 'pa' );

Return the keywords that are associated with the domain. Keywords contain
additional information related to the domain name that cannot be specified
using NAPTR records. Keywords are stored in TXT records using a
.tel-specific format.

Keywords are ordered into groups. The returned list will contain a reference
to a list (which can be interpolated to a hash) containing the keywords of a
single group. If you specify one or more parameters, only keyword groups
containing a value for the specified keywords will be returned.

E.g., to return only keyword groups that specify a Postal Address (pa) that
contains at least a ZIP code (pc) and a city (tc), you specify:

 @keywords = $lookup->get_keywords ( 'pa', 'pc', 'tc' );

If only a single keyword group matches, @keywords would contain a single
array reference looking something like:

 [ 'pa', '', 'a1', 'Somestreet 1', 'pc', '12094', 'tc', 'Some city', 'c', 'US' ]

Which can be interpolated into a hash so you get:

 {
   'pa' => '',
   'a1' => 'Somestreet 1',
   'pc' => '12094',
   'tc' => 'Some city',
   'c' => 'US'
 }

When interpolating, the order of the elements (which was originally
preserved) will be lost. This may be relevant as .tel users can explicitly
specify the order of the fields for presentation purposes.

For a description of available keywords and their shortened forms, please
refer to the Telnic website, specifically Appendix B of the Developer's
Manual.

For retrieving a list of (business) postal addresses associated with a
domain name, you can also use the get_postal_address method. That methods
translates the keywords to nicer ;) names.

=cut

sub get_keywords {

  my $self = shift;
  my @must_contain = @_;

  unless ( $self->{current_domain} ) {
    carp "Called get_text without succesful lookup";
    return ();
  }

  my @results = ();

  if ( my $response = $self->{resolver}->query ( $self->{current_domain}, 'TXT' )) {

    RECORD: foreach my $t ( $response->answer ) {

      if ( $t->type eq 'TXT' ) {

        my @parts = $t->char_str_list;
        if ( $parts[0] eq '.tkw' ) {

          # Find out whether we have all the required keywords in this
          # group.

          KEYWORD: foreach my $kw ( @must_contain ) {
            for ( my $i = 2; $i <= $#parts; $i+= 2 ) {
              next KEYWORD if ( $parts[$i] eq $kw );
            }
            next RECORD;
          }

          push @results, [ @parts[2..$#parts] ];

        }
      }
    }
  }

  return @results;

}

=head2 get_postal_address

 @postal_addresses = $lookup->get_postal_address;

Return all postal addresses which are associated with the current domain. A
postal address is a keyword group containing at least one of the following
groups of keywords:

=over

=item * pa, a1, tc

=item * bpa, a1, tc

=back

The returned list contains all addresses that could be found, ordered in the
following way:

=over

=item * addresses with more keyword (more complete addresses) before addresses with less keywords,

=item * postal addresses (pa) before business postal addresses (bpa),

=item * ordered by label alphabetically, listing addresses without a label before any other addresses,

=item * ordered by keyword contents alphabetically.

=back

Note that the last of this order sequence does not make any particular
sense; it is used only to guarantee that the order in which the addresses
are returned stays the same if the data does not change.

Every address in the list consists of a reference to a hash with the following keys:

=over

=item * order

A reference to a list containing the field names in the order in which they
appeared in the original keyword group. The field names we use here are the
longer field names present in the rest of the hash.

=item * label

The label associated with this address.

=item * type

The type of address, either 'pa' or 'bpa'.

=item * address1

=item * address2

=item * address3

The street address, consisting of a maximum of three lines.

=item * postcode

=item * city

=item * state

=item * country

These should speak for itself. Note that neither of these fields are in any
particular order; specifically, do not expect the country field to contain
an ISO country code.

=back

E.g., when a single address is returned with the current domain, the list
may contain the following result for a Dutch address:

 {
   order => ['address1', 'postcode', 'city', 'country'],
   address1 => 'Some street 1',
   postcode => '1234 AB',
   city => 'Amsterdam',
   country => 'NL'
 }

In scalar context, returns only the first address (this is what you want to
do for a 'quick and dirty' .tel based address lookup).

=cut

sub get_postal_address {

  my $self = shift;

  my @keywords = $self->get_keywords ( 'pa', 'a1', 'tc' );
  push @keywords, $self->get_keywords ( 'bpa', 'a1', 'tc' );

  # Sort the keywords
  @keywords = sort {
    ( @{$b} <=> @{$a} ) || 	# More descriptive before less descriptive.
    (( $a->[2] eq 'pa' ) && ( $b->[2] eq 'bpa' ) && -1 ) ||	# PA before BPA
    (( $b->[2] eq 'pa' ) && ( $a->[2] eq 'bpa' ) && 1 ) ||	# BPA after PA
    ( $a->[3] cmp $b->[3] ) ||					# Alphabetically by label
    ( join ( ' ', @{$a} ) cmp join ( ' ', @{$b} ))		# Alphabetically by keywords.
  } @keywords;

  my @results;
  foreach my $kw ( @keywords ) {

    my %address;
    my @order;

    while ( my $n = shift @{$kw} ) {

      my $v = shift @{$kw};

      foreach (
        { name => 'a1', nice => 'address1' },
        { name => 'a2', nice => 'address2' },
        { name => 'a3', nice => 'address3' },
        { name => 'pc', nice => 'postcode' },
        { name => 'tc', nice => 'city' },
        { name => 'sp', nice => 'state' },
        { name => 'c', nice => 'country' }
      ) {

        if ( $n eq $_->{name} ) {
          $address{$_->{nice}} = $v;
          push @order, $_->{nice};
        }
      }

      unless ( $address{type} ) {
        if ( $n eq 'pa' ) {
          $address{type} = 'pa';
          $address{label} = $v;
        } elsif ( $n eq 'bpa' ) {
          $address{type} = 'bpa';
          $address{label} = $v;
        }
      }
    }

    $address{order} = \@order;

    push @results, \%address;

  }

  if ( wantarray ) {
    return @results;
  }

  return $results[0];

}

=head2 get_services

 @services = $lookup->get_services;
 @services = $lookup->get_services ( 'email' );

Return the services that are associated with the current domain. If an ENUM
service is specified, returns only services that match this service type.
The services are taken from the NAPTR records associated with the domain and
are ordered by the preference and order fields. The service can be specified
as specific as you want:

=over

=item * 'email' will return all email services,

=item * 'email:mailto' will return only email services of subtype 'mailto',

=item * 'x-lbl:Label' will return only services with label 'Label' (case insensitive).

=back

Every service in the list consists of a hash reference with the following keys:

=over

=item * services

A reference to a list containing the ENUM services of this record.

=item * uri

The translated URI for the service, e.g. the email address as
'mailto:somebody@domain.invalid' or a phone number as 'tel:+12356890'.

=item * label

Contains the .tel label as specified by the non-standard ENUM service
'x-lbl'. This is a .tel-specific extension. If the x-lbl service is not
present then neither is this key.

=item * order

=item * preference

=item * regexp

=item * flags

=item * replacement

These keys contain the original values of the NAPTR record.

=back

For most uses, only 'label' and 'uri' will actually be interesting.

If the method is called in a scalar context, only the first service found is
returned. For this service to always be the same we order the NAPTR records
not just on preference and order, but also alphabetically by services,
regexp, flags and replacement fields.

The .tel registry supports a number of non-standard ENUM services, which are
described in the whitepaper 'NAPTR Records in .tel'.

=cut

sub get_services {

  my $self = shift;
  my ( $service ) = @_;

  unless ( $self->{current_domain} ) {
    carp "Called get_text without succesful lookup";
    return ();
  }

  my @results;

  if ( my $response = $self->{resolver}->query ( $self->{current_domain}, 'NAPTR' )) {

    foreach my $n ( $response->answer ) {

      if ( $n->type eq 'NAPTR' ) {

        my @services;
        my $value = '';

        if ( $n->flags eq 'u' ) {

          # Terminal NAPTR

          @services = split ( /\+/, $n->service );
          if ( (!$service) || (grep m/^$service(:.+)?$/, @services )) {

            # Service matches query. Determine the service URI.

            $value = $n->name;
            my $regexp = $n->regexp;

            # Note that the following is not entirely correct; it does not
            # allow for escaping the delim-char that is used.

            my ( $match, $replacement, $flags ) = split ( substr ( $regexp, 0, 1), substr ( $regexp, 1 ));
            $value =~ s/$match/$replacement/e;
            $value ||= $regexp;	# For 'fixing' thoroughly broken regexps
          }

        } # end Terminal NAPTR

        push @results, {
          services => \@services,
          uri => $value || '',
          label => ( grep m/^x-lbl:(.+)$/, @services )[0] || '',
          order => $n->order || 0,
          preference => $n->preference || 0,
          flags => $n->flags || '',
          regexp => $n->regexp || '',
          replacement => $n->replacement || ''
        };
      }
    }
  }

  @results = sort {
    ( $a->{preference} <=> $b->{preference} ) ||	# By preference
    ( $a->{order} <=> $b->{order} ) ||			# By order
    ( join ( '+', @{$a->{services}} ) cmp join ( '+', @{$b->{services}} )) ||	# By service field
    ( $a->{regexp} cmp $b->{regexp} ) ||		# By regexp
    ( $a->{flags} cmp $b->{flags} ) ||			# By flags
    ( $a->{replacement} cmp $b->{replacement} )		# By replacement
  } @results;

  if ( wantarray ) { 
    return @results;
  }

  return $results[0];

}

=head2 get_text

 @text = $lookup->get_text;

Return the TXT records that are associated with the current domain that are
not .tel keywords or system messages. This will retrieve any TXT record
associated with the domain which does not start with ".tkw" or ".tsm". Note
that the records are not returned in any particular order.

If the query was not succesful, an empty list is returned.

Note that all texts in a single TXT field are simply concatenated; this is
due to the fact that plain .tel TXT fields usually contain a descriptive
text only.

=cut

sub get_text {

  my $self = shift;

  unless ( $self->{current_domain} ) {
    carp "Called get_text without succesful lookup";
    return ();
  }

  my @results;

  if ( my $response = $self->{resolver}->query ( $self->{current_domain}, 'TXT' )) {

    foreach my $t ( $response->answer ) {

      if ( $t->type eq 'TXT' ) {

        my @parts = $t->char_str_list;
        unless (( $parts[0] eq '.tkw' ) || ( $parts[0] eq '.tsm' )) {

          push @results, join ( ' ', @parts );

        }
      }
    }
  }

  return @results;

}

=head1 AUTHOR

Sebastiaan Hoogeveen, <pause-zebaz@nederhost.nl>

=head1 SEE ALSO

http://dev.telnic.org/pages/howtos.html for a link to the Developer's Manual
which, among others, contains a description of the .tel keywords.

http://dev.telnic.org/pages/record_types.html for a link to the whitepaper
'NAPTR Records in .tel'.

http://dev.telnic.org/pages/howtos.html for a description of keywords.

If you are looking for a way to manipulate the DNS records in the Telnic
system take a look at WebService::Telnic.

=head1 BUGS

Since this is a very early release of what could become a pretty complex
module, there are probably several bugs in this code. Use at your own risk.
Bugs can be reported by email to the author.

=head1 COPYRIGHT

Copyright 2009 Sebastiaan Hoogeveen. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

1;
