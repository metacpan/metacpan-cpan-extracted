package Mojolicious::Plugin::Notifications::Assets;
use Mojo::Base -strict;

# Don't stringify, in case someone forgot to define an engine
use overload '""' => sub { '' }, fallback => 1;


# Constructor
sub new {
  bless {
    styles => [],
    scripts => []
  }, shift;
};


# Get or add styles
sub styles {
  my $self = shift;
  return sort @{ $self->{styles} } unless @_;
  push(@{$self->{styles}}, @_);
};


# Get or add scripts
sub scripts {
  my $self = shift;
  return sort @{ $self->{scripts} } unless @_;
  push(@{$self->{scripts}}, @_);
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Notifications::Assets - Collect Assets of Notification Engines


=head1 SYNOPSIS

  use Mojolicious::Plugin::Notifications::Assets;

  my $assets = Mojolicious::Plugin::Notifications::Assets->new;
  $assets->scripts('/myscripts.js');
  $assets->styles('/mystyles.css');


=head1 DESCRIPTION

L<Mojolicious::Plugin::Notifications::Assets> establishes a simple
collector object for assets, used by L<Mojolicious::Plugin::Notifications>.


=head1 METHODS

=head2 new

  my $assets = Mojolicious::Plugin::Notifications::Assets->new;

Create a new assets object.


=head2 scripts

  $assets->scripts('/myscripts.js');
  my @scripts = $assets->scripts;

Add scripts to the asset list or return the collected scripts in sorted order.


=head2 styles

  $assets->styles('/mystyles.css');
  my @styles = $assets->styles;

Add styles to the asset list or return the collected styles in sorted order.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Notifications


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
