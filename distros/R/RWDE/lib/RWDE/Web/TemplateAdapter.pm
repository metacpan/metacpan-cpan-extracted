package RWDE::Web::TemplateAdapter;

use strict;
use warnings;

use Error qw(:try);
use Template;

use RWDE::Configuration;
use RWDE::RObject;

use base qw(RWDE::Singleton);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 509 $ =~ /(\d+)/;

my $unique_instance;

sub get_instance {
  my ($self, $params) = @_;

  if (ref $unique_instance ne $self) {
    $unique_instance = $self->new;
  }

  return $unique_instance;
}

sub initialize {
  my ($self, $params) = @_;

  my @types = ('rwp', 'ttml', 'bin', 'rss');

  foreach my $type (@types) {

    $self->{$type} = Template->new(
      {
        TAG_STYLE    => 'asp',
        PROCESS      => 'types/' . $type . '.tt',
        POST_CHOMP   => 1,
        PRE_CHOMP    => 1,
        INCLUDE_PATH => RWDE::Configuration->get_root() . '/templates/components:' . RWDE::Configuration->get_root() . '/templates',
        PLUGIN_BASE  => 'Plugins',
        VARIABLES    => { commify => \&RWDE::Utility::commify, },
        COMPILE_DIR  => '/tmp/templates',
        COMPILE_EXT  => '.tc',
      }
    ) or die "Template::new failure";
  }

  return ();
}

sub render {
  my ($self, $params) = @_;

  my @required = qw( helper );
  RWDE::RObject->check_params({ required => \@required, supplied => $params });

  my $template_adapter = $self->get_instance();

  my $type = $$params{helper}->get_pagetype();

  unless (defined $type and defined $template_adapter->{$type}) {
    throw RWDE::DevelException({ info => "There is an error with requested type: $type (possibly badly separated, or not defined for uri: " . $$params{helper}->get_uri() });
  }

  my $t = $template_adapter->{$type};

  my $template_name = $$params{helper}->get_uri();
  my $vars_ref      = $$params{helper}->get_stash();

  unless ($t->process($template_name, $vars_ref)) {
    throw RWDE::DevelException({ info => 'There is an error: ' . $t->error() . "in template: $template_name" });
  }

  return ();
}

1;
