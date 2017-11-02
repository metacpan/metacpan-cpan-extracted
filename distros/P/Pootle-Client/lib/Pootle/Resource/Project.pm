# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Resource::Project;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Resource::Project

Pootle object

=cut

use base('Pootle::Resource');

use Params::Validate qw(:all);

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

sub new($class, @params) {
  $l->debug("Initializing ".__PACKAGE__." with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    checkstyle           => 1,                    #eg. "standard",
    code                 => 1,                    #eg. "firefox",
    description          => 1,                    #eg. "",
    fullname             => 1,                    #eg. "Firefox 22 (Aurora)",
    ignoredfiles         => 1,                    #eg. "",
    localfiletype        => 1,                    #eg. "po",
    resource_uri         => 1,                    #eg. "/api/v1/projects/4/",
    source_language      => 1,                    #eg. "/api/v1/languages/2/",
    translation_projects => { type => ARRAYREF }, #eg. [ "/api/v1/translation-projects/71/", ... ],
    treestyle            => 1,                    #eg. "nongnu",
  });
  my $s = bless(\%self, $class);

  return $s;
}

sub checkstyle($s)            { return $s->{checkstyle} }
sub code($s)                  { return $s->{code} }
sub description($s)           { return $s->{description} }
sub fullname($s)              { return $s->{fullname} }
sub ignoredfiles($s)          { return $s->{ignoredfiles} }
sub localfiletype($s)         { return $s->{localfiletype} }
sub resource_uri($s)          { return $s->{resource_uri} }
sub source_language($s)       { return $s->{source_language} }
sub translation_projects($s)  { return $s->{translation_projects} }
sub treestyle($s)             { return $s->{treestyle} }

=head2 Accessors

=over 4

=item B<checkstyle>

=item B<code>

=item B<description>

=item B<fullname>

=item B<ignoredfiles>

=item B<localfiletype>

=item B<resource_uri>

=item B<source_language>

=item B<translation_projects>

=item B<treestyle>

=cut

1;
