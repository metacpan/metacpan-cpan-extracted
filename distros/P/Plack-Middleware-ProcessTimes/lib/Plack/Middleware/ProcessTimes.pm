package Plack::Middleware::ProcessTimes;
$Plack::Middleware::ProcessTimes::VERSION = '1.000000';
use strict;
use warnings;

# ABSTRACT: Include process times of a request in the Plack env

use Time::HiRes qw(time);
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw( measure_children );

sub call {
  my ($self, $env) = @_;

  my @times = (time, times);

  my $res = $self->app->($env);

  return $self->response_cb($res, sub{
    my $inner = shift;

    if ($self->measure_children) {
       1 while waitpid(-1, 1) > 0;
    }

    @times = map { $_ - shift @times } time, times;

    my $CPU = 0;
    $CPU += $times[$_] for 1..4;
    push @times, $CPU;

    @times = map { sprintf "%.3f", $_ } @times;

    $env->{'pt.real'}     = $times[0];
    $env->{'pt.cpu-user'} = $times[1];
    $env->{'pt.cpu-sys'}  = $times[2];

    if ($self->measure_children) {
      $env->{'pt.cpu-cuser'} = $times[3];
      $env->{'pt.cpu-csys'}  = $times[4];
    } else {
      $env->{'pt.cpu-cuser'} = '-';
      $env->{'pt.cpu-csys'}  = '-';
    };

    return;
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::ProcessTimes - Include process times of a request in the Plack env

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

 # in app.psgi
 use Plack::Builder;

 builder {
    enable 'AccessLog::Structured',
       extra_field => {
         'pt.cpu-user' => 'CPU-User-Time',
         'pt.cpu-sys'  => 'CPU-Sys-Time',
       };

    enable 'ProcessTimes';

    $app
 };

=head1 DESCRIPTION

C<Plack::Middleware::ProcessTimes> defines some environment values based on the
L<perlfunc/times> function.  The following values are defined:

=over

=item * C<pt.real> - Actual recorded wallclock time

=item * C<pt.cpu-user>

=item * C<pt.cpu-sys>

=item * C<pt.cpu-cuser>

=item * C<pt.cpu-csys>

=back

Look up C<times(2)> in your system manual for what these all mean.

=head1 CONFIGURATION

=head2 measure_children

Setting C<measure_children> to true will L<perlfunc/waitpid> for children so
that child times can be measured.  If set responses will be somewhat slower; if
not set, the headers will be set to C<->.

=head1 THANKS

This module was originally written for Apache by Randal L. Schwartz
<merlyn@stonehenge.com> for the L<ZipRecruiter|https://www.ziprecruiter.com/>
codebase.  Thanks to both Randal and ZipRecruiter for allowing me to publish
this module!

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
