package Parse::DaemontoolsStatus;
use strict;
use warnings;
our $VERSION = '0.02';

sub parse {
    my $line = shift;

    my ($service, $status, $pid, $seconds, $info);

    # parse up status line
    $line =~ /
        ^
        (\S+):\s         # $1 service
        (\S+)\s          # $2 status
        \(pid\s(\S+)\)\s # $3 pid
        (\S+)\s seconds  # $4 seconds
        (,?\s?.*)        # $5 info
        $
    /x;

    ($service, $status, $pid, $seconds, $info) = ($1,$2,$3,$4,$5);
    $info =~ s/^,\s// if $info;

    return +{
        service => $service,
        status  => $status,
        pid     => $pid,
        seconds => $seconds,
        info    => $info,
    } if $service;

    # parse down status line
    $line =~ /
        ^
        (\S+):\s         # $1 service
        (\S+)\s          # $2 status
        (\S+)\s seconds  # $3 seconds
        (,?\s?.*)        # $4 info
        $
    /x;

    ($service, $status, $pid, $seconds, $info) = ($1,$2,undef,$3,$4);
    $info =~ s/^,\s// if $info;

    return +{
        service => $service,
        status  => $status,
        pid     => $pid,
        seconds => $seconds,
        info    => $info,
    } if $service;

    # parse not running status line
    $line =~ /
        ^
        (\S+):\s                  # $1 service
        (supervise\snot\srunning) # $2 status
        $
    /x;

    ($service, $status, $pid, $seconds, $info) = ($1,$2,undef,0,'');

    return +{
        service => $service,
        status  => $status,
        pid     => $pid,
        seconds => $seconds,
        info    => $info,
    } if $service;

    return;
}

1;
__END__

=head1 NAME

Parse::DaemontoolsStatus - parse daemontools status line

=head1 SYNOPSIS

  use Parse::DaemontoolsStatus;
  my $data = Parse::DaemontoolsStatus->parse($line);
  __END__
  $data = +{
      service => '/service/some_app',
      status  => 'down',
      pid     => undef,
      seconds => 10,
      info    => '',
  };

=head1 DESCRIPTION

Parse::DaemontoolsStatus is parse daemontools status line

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
