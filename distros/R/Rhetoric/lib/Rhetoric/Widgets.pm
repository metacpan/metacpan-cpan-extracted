package Rhetoric::Widgets;
use common::sense;
use aliased 'Squatting::H';
use Method::Signatures::Simple;
use File::Basename;
use Ouch;
use IO::All;

our $widgets = H->new({

  # path in filesystem for blog metadata
  base => '',

  # initialize the $widget object
  init => method($config) {
    $self->base($config->{base});
  },

  # return a list of all positions defined by blog metadata
  positions => method {
    my $base = $self->base;
    my @positions = map { basename($_) } grep { -d } <$base/widgets/*>;
  },

  # return widget closures for a given position
  widgets_for => method($position) {
    my $base = $self->base;
    my $path = "$base/widgets/$position";
    ouch('DirectoryNotFound', $path) unless -d $path;
    my @widgets = map { do $_ } <$path/[0-9][0-9]_*.pl>;
  },

  # return content for widgets as a list of strings
  content_for => method($position, $c, @args) {
    my @content =
      grep { defined }
      map  { $_->($c, @args) } $self->widgets_for($position);
  }

});

1;

__END__

=head1 NAME

Rhetoric::Widgets - a widget management object

=head1 SYNOPSIS

  use aliased 'Squatting::H';
  use Rhetoric::Widgets;
  my $blog = H->new;
  $blog->extend($Rhetoric::Storage::File::storage);
  $blog->extend($Rhetoric::Widgets::widget);

=head1 DESCRIPTION

This package contains a C<$widgets> package variable that contains
an object for widget management.  It's intended to be merged in with
one of the storage objects in order to create a blog object.

=head1 
