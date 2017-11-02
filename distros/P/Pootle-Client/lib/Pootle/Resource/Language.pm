# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Resource::Language;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Resource::Language

Pootle Language-object

=cut

use base('Pootle::Resource');

use Params::Validate qw(:all);

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

sub new($class, @params) {
  $l->debug("Initializing ".__PACKAGE__." with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    code                 => 1,
    description          => 1,
    fullname             => 1,
    nplurals             => 1,
    pluralequation       => 1,
    resource_uri         => 1,
    specialchars         => 1,
    translation_projects => { type => ARRAYREF },
  });
  my $s = bless(\%self, $class);

  return $s;
}

sub code($s)                 { return $s->{code} }
sub description($s)          { return $s->{description} }
sub fullname($s)             { return $s->{fullname} }
sub nplurals($s)             { return $s->{nplurals} }
sub pluralequation($s)       { return $s->{pluralequation} }
sub resource_uri($s)         { return $s->{resource_uri} }
sub specialchars($s)         { return $s->{specialchars} }
sub translation_projects($s) { return $s->{translation_projects} }

=head2 Accessors

=over 4

=item B<code>

=item B<description>

=item B<fullname>

=item B<nplurals>

=item B<pluralequation>

=item B<resource_uri>

=item B<specialchars>

=item B<translation_projects>

=cut

1;
