package Plack::Middleware::MemoryUsage;

use strict;
use warnings;

use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw( callback packages);

our $VERSION = '0.03';

use B::Size2::Terse;
use Devel::Symdump;

sub call {
    my($self, $env) = @_;

    my $before = $self->memory_usage();
    my $res    = $self->app->($env);
    my $after  = $self->memory_usage();
    my $diff   = {};

    for my $pkg (keys %$after) {
        $diff->{$pkg} = $after->{$pkg} - ($before->{$pkg} || 0);
    }

    $self->response_cb($res, sub {
                           my $res = shift;
                           $self->callback->( $env, $res, $before, $after, $diff )
                               if $self->callback;
                       });
}

sub memory_usage {
    my $self = shift;
    my @packages = $self->packages ? @{$self->packages} : Devel::Symdump->rnew("main")->packages;
    my $size;

    for my $package ("main", @packages) {
        my($subs, $opcount, $opsize) = B::Size2::Terse::package_size($package);
        $size->{$package} = $opsize;
    }
    return $size;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::MemoryUsage - for measuring process memory

=head1 SYNOPSIS

  use Plack::Builder;
  builder {
      enable "MemoryUsage",
          callback => sub {
              my ($env, $res, $before, $after, $diff) = @_;
              my $worst_count = 5;
              for my $pkg (sort { $diff->{$b} <=> $diff->{$a} } keys %$diff) {
                  warn sprintf("%-32s %8d = %8d - %8d [KB]\n",
                               $pkg,
                               $diff->{$pkg}/1024,
                               $after->{$pkg}/1024,
                               $before->{$pkg}/1024,
                              );
                  last if --$worst_count <= 0;
              }
          };
        $app;
  };
  
  # 1st                                diff      after     before
  MemoryEater                         36864 =    36873 -        9 [KB]
  B::Size2::Terse                       191 =      645 -      453 [KB]
  B::AV                                  21 =       37 -       16 [KB]
  B::HV                                   4 =       18 -       14 [KB]
  B::NV                                   0 =        8 -        8 [KB]
  
  # 2nd (grow up 18432 KB)
  MemoryEater                         18432 =    55305 -    36873 [KB]
  Plack::Middleware::MemoryUsage          0 =       13 -       13 [KB]
  IO::Socket::INET                        0 =      270 -      270 [KB]
  Apache2::Status                         0 =       26 -       26 [KB]
  Symbol                                  0 =       40 -       40 [KB]

=head1 DESCRIPTION

Plack::Middleware::MemoryUsage is middleware for measuring process memory.

Enabling Plack::Middleware::MemoryUsage causes huge performance penalty.
So I HIGHLY RECOMMEND to enable this middleware only on development env or not processing every request on production using Plack::Middleware::Conditional.

  builder {
      ## with 1/3 probability
      enable_if { int(rand(3)) == 0 } "MemoryUsage",
      ## only exists X-Memory-Usage request header
      # enable_if { exists $_[0]->{HTTP_X_MEMORY_USAGE} } "MemoryUsage",
          callback => sub {
          ...
          };
        $app;
  };

=head1 CONFIGURATION

=over 4

=item callback

callback subref will be called after process app.

  callback => sub {
      my ($env, $res, $before, $after, $diff) = @_;
      ...
  };

First argument is Plack env.

Second argument is Plack response.

Third argument is a hash ref of memory usage by package at before process app.

Fourth argument is a hash ref of memory usage by package at after process app.

Fifth argument is a hash ref of difference memory usage by package between before and after.

=item packages

packages arrayref will limit modules to measure.

  packages => [ 'Plack::Middleware', 'B::Size2::Terse', ...];

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 REPOSITORY

L<https://github.com/hirose31/plack-middleware-memoryusage>

  git clone git://github.com/hirose31/plack-middleware-memoryusage.git

patches and collaborators are welcome.

=head1 SEE ALSO

L<Plack::Middleware>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

