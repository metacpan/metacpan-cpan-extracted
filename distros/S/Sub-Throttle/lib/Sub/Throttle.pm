package Sub::Throttle;

use strict;
use warnings;

use Carp qw(croak);
use List::Util qw(max);
use Time::HiRes qw(time sleep);

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(throttle);
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);
our @EXPORT = ();
our $VERSION = '0.02';

sub throttle {
    croak "too few arguments to throttle\n"
        if @_ < 2;
    my ($load, $func, @args) = @_;
    my @ret;
    my $start = time;
    if (wantarray) {
        @ret = $func->(@args);
    } else {
        $ret[0] = $func->(@args);
    }
    sleep(_sleep_secs($load, time - $start));
    wantarray ? @ret : $ret[0];
}

sub _sleep_secs {
    my ($load, $elapsed) = @_;
    max($elapsed, 0) * (1 - $load) / $load;
}

1;
=head1 NAME

Sub::Throttle - Throttle load of perl function

=head1 SYNOPSIS

  use Sub::Throttle qw(throttle);
  
  my $load = 0.1;
  
  throttle($load, sub { ... });
  throttle($load, \&subref, @args);

=head1 DESCRIPTION

Throttles the load of perl function by calling L<sleep>.

=head1 METHODS

=head2 throttle($load, $subref [, @subargs])

Calls L<sleep> after executing $subref with given @subargs so that the ratio of execution time becomes equal to $load.

=head1 AUTHOR

Kazuho Oku E<lt>kazuhooku at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Cybozu Labs, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
