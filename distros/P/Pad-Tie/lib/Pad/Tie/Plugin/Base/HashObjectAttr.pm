use strict;
use warnings;

package Pad::Tie::Plugin::Base::HashObjectAttr;

use base 'Pad::Tie::Plugin';
use Carp ();
use Devel::LexAlias ();

sub provides { 
  $_[0]->attr_type . '_attr'
}

sub sigil {
  Carp::confess "subclass $_[0] did not override virtual method 'sigil'"
}
  
sub build_attrs {
  my ($plugin, $ctx, $self, $args) = @_;

  $args = $plugin->canon_args($args);

  my $rv = { pre_call => [] };

  my $sigil = $plugin->sigil;
  # XXX something isn't quite right here in the relationship between provides
  # and the name of 'build_attrs' and ...
  my ($attr_type) = $plugin->provides;
  for my $method (keys %$args) {
    my $name = $args->{$method};
    my $var_name = "$sigil$name";
    if (exists $ctx->{$var_name}) {
      Carp::carp "removing existing context entry for $var_name; " .
        "adding entry for $attr_type => $method";
      delete $ctx->{$var_name};
    }
    $plugin->build_one_attr(
      $ctx, $self, {
        method => $method,
        name   => $name,
      },
      $rv,
    );
  }

  return $rv;
}
    
sub build_one_attr {
  my ($plugin, $ctx, $self, $arg, $rv) = @_;
  my $sigil = $plugin->sigil;
  push @{ $rv->{pre_call} }, sub {
    my ($self, $code, $args) = @_;
    Devel::LexAlias::lexalias(
      $code,
      "$sigil$arg->{name}",
      $plugin->ref_for_attr(
        $ctx,
        $self,
        $arg,
      ),
    );
  };
}

1;

__END__

=head1 NAME

Pad::Tie::Plugin::Base::HashObjectAttr

=head1 DESCRIPTION

This plugin is a base class for method personalities that provide direct access
to contents of hash-based objects.

You should not use this plugin directly; use one of its subclasses.

=cut
