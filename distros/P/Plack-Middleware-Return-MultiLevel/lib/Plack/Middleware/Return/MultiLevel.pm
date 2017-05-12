use strict;
use warnings;

package Plack::Middleware::Return::MultiLevel;

our $VERSION = "0.002";
use base 'Plack::Middleware';
use Plack::Util::Accessor 'level_name';
use Return::MultiLevel;

sub PSGI_KEY () { 'Plack.Middleware.Return.MultiLevel.return_to' }

sub DEFAULT_LEVEL_NAME() { 'default' }

sub _return_level {
  my ($env, $level_name, @returning) = @_;
  my $returns_to = $env->{+PSGI_KEY}->{$level_name} ||
    die "'$level_name' not found, cannot return to it!";

  $returns_to->(@returning);
}

sub prepare_app {
  $_[0]->level_name(DEFAULT_LEVEL_NAME)
    unless(defined $_[0]->level_name);
}

sub call {
  my ($self, $env) = @_;
  return Return::MultiLevel::with_return {
    my ($return_to) = @_;
    my $new_env = +{
      %$env,
      +PSGI_KEY, +{ %{$env->{+PSGI_KEY}||{}}, $self->level_name => $return_to },
    }; # make a shallow copy

    $self->app->($new_env);
  };
}

sub return {
  my ($self, $env, @returning) = @_;
  return _return_level($env, $self->level_name, @returning);
}

=head1 TITLE
 
Plack::Middleware::Return::MultiLevel - Escape a PSGI app from anywhere in the stack
 
=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::Return::MultiLevel::Utils
      qw/return_to_level return_to_default_level/;

    my $app = builder {
      enable "Return::MultiLevel";

      mount "/default" => sub {
        my $env = shift;
        return_to_default_level($env, [200, ['Content-Type', 'text/plain'], ['default']]);
      };

      mount '/layers' => builder {
        enable "Return::MultiLevel", level_name=>'one';
        enable "Return::MultiLevel", level_name=>'two';

        mount '/one' => sub {
          my $env = shift;
          return_to_level($env, 'one', [200, ['Content-Type', 'text/plain'], ['one']]);
        };

        mount '/two' => sub {
          my $env = shift;
          return_to_level($env, 'two', [200, ['Content-Type', 'text/plain'], ['two']]);
        };

      };

    };

=head1 DESCRIPTION

Sometimes when in a PSGI application you want an easy way to escape out of the
current callstack.  For example you might wish to immediately end processing and
return a 'NotFound' or 'ServerError' type response.  In those cases you might
use the core middleware L<Plack::Middleware::HTTPExceptions>, which allows you
to throw an exception object that matches a duck type (has methods C<code> and
C<as_string> or C<as_psgi>).  That middleware wraps everything in an eval and
looks for exception objects of that type, and converts them to a response.

L<Plack::Middleware::Return::MultiLevel> is an alternative approach to solving
this problem.  Instead of throwing an exception, it uses L<Return::MultiLevel>
to set a 'callback' point that you can jump to at any time.  If you don't like
using exceptions for control flow, or you have code that does a lot of exception
catching, you might prefer this approach.

Unlike L<Plack::Middleware::HTTPExceptions> you don't need to return an object
matching a ducktype, you can just return any standard, acceptable PSGI response.

=head1 CONSTANTS

This class defines the following constants

=head2 PSGI_KEY

PSGI environment key under which your return callback are stored.

=head2 DEFAULT_LEVEL_NAME

The default level name used if you choose not to explicitly name your return
level target.
 
=head1 METHODS
 
This class defines the following methods.

=head2 prepare_app

Sets instance defaults
 
=head2 call
 
Used by plack to call the middleware

=head2 return

    my $mw = Plack::Middleware::Return::MultiLevel->new;

    #...

    $mw->return([200, ['Content-Type', 'text/plain'], ['returned']]);

Returns to the callpoint set by L<Return::MultiLevel>.  You should pass this
args suitable for a PSGI response.

Since the return callback is also stored in the C<$psgi_env>, you are more
likely to use methods from L<Plack::Middleware::Return::MultiLevel::Utils>
rather than storing the middleware object.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
 
=head1 SEE ALSO

L<Return::MultiLevel>, L<Plack>, L<Plack::Middleware>, 
L<Plack::Middleware::Return::MultiLevel::Utils>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2014, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
