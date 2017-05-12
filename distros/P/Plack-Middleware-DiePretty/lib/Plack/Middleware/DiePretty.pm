package Plack::Middleware::DiePretty;
use parent 'Plack::Middleware';
use strict;
use warnings;
use Plack::Util::Accessor qw(template);
use Try::Tiny;
use Template;
use Path::Class;
use FindBin qw($Bin);

our $VERSION = '0.001';
$VERSION = eval $VERSION;

sub call {
  my ($self, $env) = @_;

  local $SIG{__DIE__} = sub { die @_; };

  my $caught;
  my $res = try { $self->app->($env); } catch { $caught = $_; [ 500, [ 'Content-Type' => 'text/plain; charset=utf-8' ], [ $caught ] ]; };

  my $template = file( $self->template || "$Bin/html/error.html" );

  if ($caught || (ref $res eq 'ARRAY' && $res->[0] == 500)) {
    Template->new({ INCLUDE_PATH => $template->dir->absolute })->process($template->basename, { caught => $caught }, \(my $html)) || die $@;
    $res = [ 500, [ 'Content-Type' => 'text/html'], [ $html ] ];
  }
  $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::DiePretty - Show a 500 error page if you die

=head1 SYNOPSIS

  enable 'DiePretty';
  enable 'DiePretty', template => 'my/500.html';

=head1 OPTIONS

The following are options that can be passed to this module.

=over 4

=item I<template>

The location of your template (currently, Template::Toolkit parsed)

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Justin Hunter <justin.d.hunter@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Justin Hunter

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
