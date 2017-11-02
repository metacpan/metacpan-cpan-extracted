# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Resource::Unit;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Resource::Unit

Pootle object

=cut

use base('Pootle::Resource');

use Params::Validate qw(:all);

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

sub new($class, @params) {
  $l->debug("Initializing ".__PACKAGE__." with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    commented_by          => 0, #eg. null
    commented_on          => 1, #eg. "2013-03-15T20:10:35.017844",
    context               => 1, #eg. "This is a phrase, not a verb.",
    developer_comment     => 1, #eg. "Translators: name of the option in the menu.",
    locations             => 1, #eg. "fr/firefox/chrome/global/languageNames.properties.po:62",
    mtime                 => 1, #eg. 2013-05-12T17:51:49.786611",
    resource_uri          => 1, #eg. "/api/v1/units/70316/",
    source_f              => 1, #eg. "New Tab",
    source_length         => 1, #eg. 29,
    source_wordcount      => 1, #eg. 3,
    state                 => 1, #eg. 0,
    store                 => 1, #eg. "/api/v1/stores/76/",
    submitted_by          => 0, #eg. "/api/v1/users/3/",
    submitted_on          => 1, #eg. "2013-05-21T17:51:16.155000",
    suggestions           => { type => ARRAYREF }, #eg. ["/api/v1/suggestions/1/", ...]
    target_f              => 1, #eg. "",
    target_length         => 1, #eg. 0,
    target_wordcount      => 1, #eg. 0,
    translator_comment    => 1, #eg. ""
  });
  my $s = bless(\%self, $class);

  return $s;
}

sub commented_by($s)       { return $s->{commented_by} }
sub commented_on($s)       { return $s->{commented_on} }
sub context($s)            { return $s->{context} }
sub developer_comment($s)  { return $s->{developer_comment} }
sub locations($s)          { return $s->{locations} }
sub mtime($s)              { return $s->{mtime} }
sub resource_uri($s)       { return $s->{resource_uri} }
sub source_f($s)           { return $s->{source_f} }
sub source_length($s)      { return $s->{source_length} }
sub source_wordcount($s)   { return $s->{source_wordcount} }
sub state($s)              { return $s->{state} }
sub store($s)              { return $s->{store} }
sub submitted_by($s)       { return $s->{submitted_by} }
sub submitted_on($s)       { return $s->{submitted_on} }
sub suggestions($s)        { return $s->{suggestions} }
sub target_f($s)           { return $s->{target_f} }
sub target_length($s)      { return $s->{target_length} }
sub target_wordcount($s)   { return $s->{target_wordcount} }
sub translator_comment($s) { return $s->{translator_comment} }

=head2 Accessors

=over 4

=item B<commented_by>

=item B<commented_on>

=item B<context>

=item B<developer_comment>

=item B<locations>

=item B<mtime>

=item B<resource_uri>

=item B<source_f>

=item B<source_length>

=item B<source_wordcount>

=item B<state>

=item B<store>

=item B<submitted_by>

=item B<submitted_on>

=item B<suggestions>

=item B<target_f>

=item B<target_length>

=item B<target_wordcount>

=item B<translator_comment>

=cut

1;
