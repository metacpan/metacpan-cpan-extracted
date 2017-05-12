package Mojolicious::Plugin::Logf;
use Mojo::Base 'Mojolicious::Plugin';
use Data::Dumper ();
use overload     ();
use constant UNDEF => $ENV{MOJO_LOGF_UNDEF} || '__UNDEF__';

our $VERSION = '0.10';

sub logf {
  my ($self, $c, $level, $format, @args) = @_;
  my $log = $c->app->log;
  $log->$level(@args ? sprintf $format, $self->flatten(@args) : $format)
    if $log->is_level($level);
  $c;
}

sub flatten {
  my $self = shift;
  my @args = map { ref $_ eq 'CODE' ? $_->() : $_ } @_;

  local $Data::Dumper::Indent   = 0;
  local $Data::Dumper::Maxdepth = $Data::Dumper::Maxdepth || 2;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Terse    = 1;

  for (@args) {
    $_
      = !defined($_) ? UNDEF
      : overload::Method($_, q("")) ? "$_"
      : ref($_) ? Data::Dumper::Dumper($_)
      :           $_;
  }

  return @args;
}

sub register {
  my ($self, $app, $config) = @_;

  $app->helper(logf => sub { @_ == 1 ? $self : logf($self, @_) });
  $app->log->format(\&_rfc3339) if $config->{rfc3339};
}

sub _rfc3339 {
  my ($s, $m, $h, $day, $month, $year) = gmtime(shift);
  sprintf '[%04d-%02d-%02dT%02d:%02d:%02dZ] [%s] %s', $year + 1900, $month + 1, $day, $h,
    $m, $s, shift(@_), join "\n", @_, '';
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Logf - Plugin for logging datastructures using sprintf

=head1 VERSION

0.10

=head1 DESCRIPTION

L<Mojolicious::Plugin::Logf> is a plugin which will log complex datastructures
and avoid "unitialized" warnings. This plugin use L<Mojo::Log> or whatever
L<Mojo/log> is set to, to do the actual logging.

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin logf => {rfc3339 => 1};

  get "/" => sub {
    my $c = shift;
    $c->logf(info => 'request: %s', $self->req->params->to_hash);
    $c->render(text => "cool!");
  };

Setting C<rfc3339> to "1" will make the log look like this:

  [2016-02-19T13:05:37Z] [info] Some log message

=head1 COPY/PASTE CODE

If you think it's a waste to depend on this module, you can copy paste the
code below to get the same functionality as the L</logf> helper:

  helper logf => sub {
    my ($c, $level, $format) = (shift, shift, shift);
    my $log = $c->app->log;
    return $c unless $log->is_level($level);
    my @args = map { ref $_ eq 'CODE' ? $_->() : $_ } @_;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Maxdepth = $Data::Dumper::Maxdepth || 2;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    for (@args) {
      $_
        = !defined($_) ?  "__UNDEF__" 
        : overload::Method($_, q("")) ? "$_"
        : ref($_) ? Data::Dumper::Dumper($_)
        :           $_;
    }
    $log->$level(sprintf $format, @args);
    return $c;
  };

Note: The code above is generated and tested from the original source code,
but it will more difficult to get updates and bug fixes.

=head1 HELPERS

=head2 logf

  $self = $c->logf;
  $c = $c->logf($level => $format, @args);

Logs a string formatted by the usual C<printf> conventions of the C library
function C<sprintf>. C<$level> need to be a valid L<Mojo::Log> level.
C<@args> will be converted using L</flatten>.

Calling this method without any arguments will return C<$self>
(an instance of this plugin), allowing you to call L</flatten>:

  @args_as_strings = $c->logf->flatten(@args);

=head1 METHODS

=head2 flatten

  @args_as_strings = $self->flatten(@args);

Used to convert input C<@args> using these rules:

=over 4

=item * Scalar

No rule applied.

=item * Code ref

A code ref will be called, and the list of return values will be flattened.
The code below will not calculate the request params, unless the log level
is "debug":

  $c->logf(debug => 'request: %s', sub {$c->req->params->to_hash});

=item * Object with string overloading

Will be coverted to a string using the string overloading function.

=item * Data structure or object

Will be serialized using L<Data::Dumper> with these settings:

  $Data::Dumper::Indent = 0;
  $Data::Dumper::Maxdepth = $Data::Dumper::Maxdepth || 2;
  $Data::Dumper::Sortkeys = 1;
  $Data::Dumper::Terse = 1;

NOTE! These settings might change, but will always do its best to
serialize the object into one line. C<$Data::Dumper::Maxdepth> is
used to avoid dumping large nested objects. Set this variable
if you need deeper logging. Example:

  local $Data::Dumper::Maxdepth = 1000;
  $c->logf(info => 'Deep structure: %s', $some_object);

=item * Undefined value

Will be logged as "__UNDEF__". This value can be changed by setting
the global environment variable C<MOJO_LOGF_UNDEF> before loading this
plugin.

=back

=head2 register

Will register the L</logf> helper in the application

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
