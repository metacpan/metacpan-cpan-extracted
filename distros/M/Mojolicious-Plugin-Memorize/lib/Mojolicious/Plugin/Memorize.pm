package Mojolicious::Plugin::Memorize;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';
$VERSION = eval $VERSION;

use Mojo::Util;

has cache => sub { +{} };

sub register {
  my ($plugin, $app) = @_;

  $app->helper(
    memorize => sub {
      shift;
      return $plugin unless @_;
      unshift @_, $plugin;
      goto $plugin->can('memorize'); # for the sake of the auto-naming
    }
  );

}

sub expire {
  my ($self, $name) = @_;
  delete $self->cache->{$name};
}

sub memorize {
  my $self = shift;

  my $mem = $self->cache;

  return '' unless ref(my $cb = pop) eq 'CODE';
  my ($name, $args)
    = ref $_[0] eq 'HASH' ? (undef, shift) : (shift, shift || {});

  # Default name
  $name ||= join '', map { $_ || '' } (caller(1))[0 .. 3];

  # Return memorized result or invalidate cached
  return $mem->{$name}{content} if $self->_check_cached($name);

  # Determine new expiration time
  my $expires = 0;
  if ( my $delta = $args->{duration} ) {
    $expires = $delta + Mojo::Util::steady_time;
  } elsif ( my $time = $args->{expires} ) {
    my $delta = $time - time;
    $expires = $delta + Mojo::Util::steady_time;
  }

  # Memorize new result
  $mem->{$name}{expires} = $expires;
  return $mem->{$name}{content} = $cb->();
}

sub _check_cached {
  my ($self, $name) = @_;
  my $mem = $self->cache;

  return unless exists $mem->{$name}; # avoid autoviv

  return 1 unless my $expires = $mem->{$name}{expires};

  return 1 unless Mojo::Util::steady_time >= $expires;

  delete $mem->{$name};

  return 0;
}

1;

=head1 NAME

Mojolicious::Plugin::Memorize - Memorize part of your Mojolicious template

=head1 SYNOPSIS

 use Mojolicious::Lite;
 plugin 'Memorize';

 any '/' => 'index';

 any '/reset' => sub {
   my $self = shift;
   $self->memorize->expire('access');
   $self->redirect_to('/');
 };

 app->start;

 __DATA__

 @@ index.html.ep

 %= memorize access => { expires => 0 } => begin
   This page was memorized on 
   %= scalar localtime
 % end

=head1 DESCRIPTION

This plugin provides the functionality to easily memorize a portion of a
template, to prevent re-evaluation. This may be useful when a portion of your
response is expensive to generate but changes rarely (a menu for example).

The C<memorize> helper derives from the helper that was removed from
C<Mojolicious> at version 4.0, with two major changes. The underlying plugin
object is returned when no arguments are passed and the system is resiliant
against time jumps.

=head1 HELPERS

=over

=item C<memorize( [$name,] [$args,] [$template_block] )>

When called with arguments, this helper wraps the functionality of the
C<memorize> method below. See its documentation for usage.

When called without arguments, the plugin object is returned, allowing the use
of other plugin methods or access to the plugin's cache.

=back

=head1 ATTRIBUTES

=over

=item C<cache>

A hash reference containing the memorized template content and other data. 

=back

=head1 METHODS

=over

=item C<expire( $name )>

This method allows for manually expiring a memorized template block. This may
useful if the template is set to never expire or when the underlying content is
known to have changed.

This is an example of the utility of having access to the underlying hash. In
the original implementation of the core helper, this access was not available.

=item C<memorize( [$name,] [$args,] $template_block )>

This method behaves as the old helper did. It takes as many as three arguments,
the final of which must be a template block (see L<Mojolicious::Lite/Blocks>) to
be memorized. The first argument may be a string which is the name (key) of the
memorized template (used for later access); if this is not provided one will be
generated. A hashref may also be passed in which is used for additional
arguments.

As of this writing, the only available argument are C<duration> and C<expires>. 
The C<duration> key specifies the number of seconds that the template should be
memorized, while the C<expires> key specifies a time (epoch seconds) after which
the template should be re-evaluated. C<duration> is the recommened usage,
C<expires> is provided for historical reasons, and is implemented using
C<duration>. If both are provided, C<duration> is used.

Note that either key may be set to zero to prevent timed expiration.

=item C<register>

This method is called upon loading the plugin and probably is not useful for
other purposes.

=back

=head1 SEE ALSO

=over

=item *

L<Mojolicious>

=item *

L<Mojolicious::Plugin>

=item *

L<Mojolicious::Guides::Rendering>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-Memorize> 


=head1 AUTHORS

=over

=item Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=item Sebastian Riedel 

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Joel Berger and Sebastian Riedel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

