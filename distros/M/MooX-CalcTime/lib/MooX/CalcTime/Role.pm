package MooX::CalcTime::Role;
use Modern::Perl;
use Moo::Role;
use DateTime;

our $VERSION = '0.0.8'; # VERSION
# ABSTRACT: calculate total time that a program run


has _time_start => (
  is        => 'ro',
  default   => time,
);


sub get_run_second  {
  time - $_[0]->_time_start;
}


sub get_runtime {
  my $interval      = $_[0]->get_run_second;
  my $second        = $interval % 60;
  my $total_minute  = int ($interval / 60);
  my $minute        = $total_minute % 60;
  my $total_hour    = int ($total_minute / 60);
  my $hour          = $total_hour % 60;
  my $day           = int($total_hour / 24);
  my $start = DateTime->from_epoch(epoch => $_[0]->_time_start);
  my $end   = DateTime->now;
  my $msg   = "Starting time: $start\n";
  $msg .= "Ending time: $end\n";
  $msg .= "Running time: $day days $hour hours $minute minutes $second second\n";
  return $msg;
}


sub print_runtime {
  say $_[0]->get_runtime;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::CalcTime::Role - calculate total time that a program run

=head1 VERSION

version 0.0.8

=head1 SYNOPSIS

  package AA;

  with 'MooX::CalcTime::Role';

  sub run {
    my $self = shift;
    # return second passed, such as 30
    $self->get_run_second;

    # return a string such as 'Running time: 3 days 2 minutes 1 hours 10 minutes 5 second';
    $self->get_runtime; # return a variable: '3 days 2 hours 1 minute'

    # print return value of 'get_runtime_format' function
    $self->print_runtime;
  }

=head1 DESCRIPTION

This Role is used to inject time related method to other class,
So that we can obtain running time more easily.

=head1 METHODS

=head2 get_run_second

get total seconds passed from consumer class initialize to now.

=head2 get_runtime

get total seconds, which passed from consumer class initialize to now, in a format
of 'Running time: 8 days 4 hours 3 minutes 30 seconds'.

=head2 print_runtime

print total seconds, which passed from consumer class initialize to now, in a format
of 'Running time: 8 days 4 hours 3 minutes 30 seconds'.

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
