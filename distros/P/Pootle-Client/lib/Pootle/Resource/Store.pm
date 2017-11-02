# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Resource::Store;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Resource::Store

Pootle object

=cut

use base('Pootle::Resource');

use Params::Validate qw(:all);

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

sub new($class, @params) {
  $l->debug("Initializing ".__PACKAGE__." with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    file                => 1, #eg. "/media/Firefox/fr/chrome/global/languageNames.properties.po"
    name                => 1, #eg. "languageNames.properties.po"
    pending             => 0, #eg. null
    pootle_path         => 1, #eg. "fr/firefox/chrome/global/languageNames.properties.po"
    resource_uri        => 1, #eg. "/api/v1/stores/76/"
    state               => 1, #eg. 2
    sync_time           => 1, #eg. "2013-03-15T20:10:35.070238"
    tm                  => 0, #eg. null
    translation_project => 1, #eg. "/api/v1/translation-projects/65/"
    units               => 1, #eg. [ '/api/v1/units/70316/', ... ]
  });
  my $s = bless(\%self, $class);

  return $s;
}

sub file($s)                { return $s->{file} }
sub name($s)                { return $s->{name} }
sub pending($s)             { return $s->{pending} }
sub pootle_path($s)         { return $s->{pootle_path} }
sub resource_uri($s)        { return $s->{resource_uri} }
sub state($s)               { return $s->{state} }
sub sync_time($s)           { return $s->{sync_time} }
sub tm($s)                  { return $s->{tm} }
sub translation_project($s) { return $s->{translation_project} }
sub units($s)               { return $s->{units} }

=head2 Accessors

=over 4

=item B<file>

=item B<name>

=item B<pending>

=item B<pootle_path>

=item B<resource_uri>

=item B<state>

=item B<sync_time>

=item B<tm>

=item B<translation_project>

=item B<units>

=cut

1;
