package Mojolicious::Plugin::ParamLogger;

use Mojo::Base 'Mojolicious::Plugin';

use Carp;
use Data::Dumper ();

our $VERSION = '0.03';

sub register
{
  my ($self, $app, $options) = @_;
  return unless $app->mode eq 'development' or $options->{$app->mode};

  my $level = $options->{level};
  if(!$level) {
      # By default debug level is suppressed in production
      $level = $app->mode eq 'production' ? 'info' : 'debug';
  }

  croak "unknown log level '$level'" unless $app->log->can($level);

  my $params = $options->{filter} || ['password'];
  $params = [ $params ] if ref $params ne 'ARRAY';

  my %filter;
  @filter{@$params} = (1) x @$params;

  $app->hook(before_dispatch => sub {
      my $c = shift;
      my $params = $c->req->params->to_hash;

      for my $name (keys %$params) {
	  next unless defined $params->{$name};

	  if($filter{$name}) {
	      $params->{$name} = '#' x 8;
	  }
	  elsif(length($params->{$name}) > 75) {
	      substr($params->{$name}, 75) = '...';
	  }
      }

      my $path = $c->req->url->path;
      $path = "/$path" if index($path, '/') != 0; # Mojo doesn't always add the slash

      my $message = sprintf '%s %s%s', $c->req->method, $path, Data::Dumper->new([$params])->Terse(1)->Indent(0)->Useqq(1)->Pad(' ')->Dump;
      eval { $c->app->log->$level($message) };
      if($@) {
	  $c->render_exception($@);
	  return;
      }
  });
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::ParamLogger - Log request parameters

=for html <a href="https://travis-ci.org/sshaw/Mojolicious-Plugin-ParamLogger"><img src="https://travis-ci.org/sshaw/Mojolicious-Plugin-ParamLogger.svg?branch=master"></a>

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('ParamLogger', %options)

  # Mojolicious::Lite
  plugin 'ParamLogger', %options;

=head1 DESCRIPTION

This module automatically logs request parameters while in development mode.
See L</OPTIONS> for details.

C<Mojolicious> doesn't log request parameters. Of course -depending on your setup-
they may be logged elsewhere but, when in development, I use C<morbo> and C<morbo>
doesn't log them (same goes for C<hypnotoad>).

=head1 OPTIONS

=head2 C<filter>

  $self->plugin('ParamLogger', filter => 'authtoken')
  $self->plugin('ParamLogger', filter => [ qw{nome senha} ])

Parmeter values to exclude from the log. Defaults to C<'password'>.

=head2 C<level>

  $self->plugin('ParamLogger', level => 'info')

Log the request parameters at the given log level. Defaults to C<'info'> in production, C<'debug'> everywhere else.
See L<Mojo::Log/level> for a list of log levels.

=head2 C<mode>

  $self->plugin('ParamLogger', production => 1)

Turn on parameter logging for the given mode. By default parameters will only be logged when in development mode.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::Log>

=head1 LICENSE

Copyright (c) 2012 Skye Shaw.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
