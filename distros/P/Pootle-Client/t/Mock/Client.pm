# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package t::Mock::Client;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 t::Mock::Client

Mock API calls with dummy data

=cut

use Pootle::Client;

use t::Mock::Resource::Languages;
use t::Mock::Resource::TranslationProjects;
use t::Mock::Resource::Stores;
use t::Mock::Resource::Projects;
use t::Mock::Resource::Units;

sub new {
  if (@_ == 2) {
    return new Pootle::Client({baseUrl => $_[0], credentials => $_[1]});
  }
  return new Pootle::Client({baseUrl => 'http://translate.example.com', credentials => 'username:password'});
}

sub languages {
  return t::Mock::Resource::Languages::all(@_);
}
sub language {
  return t::Mock::Resource::Languages::one(@_);
}
sub projects {
  return t::Mock::Resource::Projects::all(@_);
}
sub project {
  return t::Mock::Resource::Projects::one(@_);
}
sub translationProjects {
  return t::Mock::Resource::TranslationProjects::all(@_);
}
sub translationProject {
  return t::Mock::Resource::TranslationProjects::one(@_);
}
sub stores {
  return t::Mock::Resource::Stores::all(@_);
}
sub store {
  return t::Mock::Resource::Stores::one(@_);
}
sub unit {
  return t::Mock::Resource::Units::one(@_);
}





=head2 cleanup

 @PARAM1 Pootle::Client

=cut

sub cleanup($papi) {
  $papi->flushCaches();
}

1;
