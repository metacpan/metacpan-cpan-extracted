# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Resource::TranslationProject;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Resource::TranslationProject

Pootle object

=cut

use base('Pootle::Resource');

use Params::Validate qw(:all);

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

sub new($class, @params) {
  $l->debug("Initializing ".__PACKAGE__." with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    description  => 1,                     #eg. ""
    language     => 1,                     #eg. "/api/v1/languages/110/"
    pootle_path  => 1,                     #eg. "/fr/Firefox/"
    project      => 1,                     #eg. "/api/v1/projects/3/"
    real_path    => 1,                     #eg. "Firefox/fr"
    resource_uri => 1,                     #eg. "/api/v1/translation-projects/65/"
    stores       => { type => ARRAYREF } , #eg. [ "/api/v1/stores/77/", ... ]
  });
  my $s = bless(\%self, $class);

  return $s;
}

sub description($s)  { return $s->{description} }
sub language($s)     { return $s->{language} }
sub pootle_path($s)  { return $s->{pootle_path} }
sub project($s)      { return $s->{project} }
sub real_path($s)    { return $s->{real_path} }
sub resource_uri($s) { return $s->{resource_uri} }
sub stores($s)       { return $s->{stores} }

=head2 Accessors

=over 4

=item B<description>

=item B<language>

=item B<pootle_path>

=item B<project>

=item B<real_path>

=item B<resource_uri>

=item B<stores>

=cut

1;
