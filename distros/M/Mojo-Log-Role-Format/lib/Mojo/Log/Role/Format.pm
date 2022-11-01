package Mojo::Log::Role::Format;
use Mojo::Base -role;

use overload ();

our $VERSION = '0.02';

has logf_serialize => sub { \&_serialize };

sub logf {
  my ($self, $level, $format, @args) = @_;
  $self->$level(@args ? sprintf $format, $self->logf_serialize->(@args) : $format)
    if $self->is_level($level);
  return $self;
}

sub _serialize {
  my @args = map { ref $_ eq 'CODE' ? $_->() : $_ } @_;

  local $Data::Dumper::Indent    = 0;
  local $Data::Dumper::Maxdepth  = $Data::Dumper::Maxdepth || 2;
  local $Data::Dumper::Pair      = ':';
  local $Data::Dumper::Quotekeys = 1;
  local $Data::Dumper::Sortkeys  = 1;
  local $Data::Dumper::Terse     = 1;
  local $Data::Dumper::Useqq     = 1;

  return map {
        !defined($_)                ? 'undef'
      : overload::Method($_, q("")) ? "$_"
      : ref($_)                     ? Data::Dumper::Dumper($_)
      :                               $_;
  } @args;
}

1;

=encoding utf8

=head1 NAME

Mojo::Log::Role::Format - Add sprintf logging to Mojo::Log

=head1 SYNOPSIS

  use Mojo::Log;
  my $log = Mojo::Log->new->with_roles('+Format')->level('debug');

  # [info] cool beans
  $log->logf(info => 'cool %s', 'beans');

  # [warn] serializing {"data":"structures"}
  $log->logf(warn => 'serializing %s', {data => 'structures'});

=head1 DESCRIPTION

L<Mojo::Log::Role::Format> is a L<Mojo::Log> role which allow you to log with
a format like C<sprintf()>, avoid "Use of uninitialized" warnings and will
also serialize data-structures and objects.

=head1 ATTRIBUTES

=head2 logf_serialize

  $cb = $log->logf_serialize;
  $log = $log->logf_serialize(sub (@args) { ... });

This attribute must hold a callback that will be used to serialize the arguments
passed to L</logf>.

The default callback uses L<Data::Dumper> with some modifications, but these
settings are currently EXPERIMENTAL and subject to change:

  $Data::Dumper::Indent    = 0;
  $Data::Dumper::Maxdepth  = $Data::Dumper::Maxdepth || 2;
  $Data::Dumper::Pair      = ':';
  $Data::Dumper::Quotekeys = 1;
  $Data::Dumper::Sortkeys  = 1;
  $Data::Dumper::Terse     = 1;
  $Data::Dumper::Useqq     = 1;

=head1 METHODS

=head2 logf

  $log = $log->logf($level => $format, @args);
  $log = $log->logf($level => $message);

See L</SYNOPSIS>.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Mojo::Log>

=cut
