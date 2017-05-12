package Regex::Number::GtLt;
use List::Util qw/max min/;
require Exporter;
our @ISA = qw(Exporter);
@EXPORT_OK = qw(rxgreater rxsmaller rxbetween);
our $VERSION = '0.01';

use strict;

sub rxgreater{
  my ($width, $str) = @_;
  $str = $str + 0;
  $str = sprintf("\%0${width}d", $str);
  my @rv;
    for my $i (1.. length $str){
    my $ri = length($str) - $i;
    my($pre, $num, $after) = (substr($str, 0, $ri), substr($str,$ri,1), substr($str,$ri+1) );
    if($num == 9){
      $pre++;
      push @rv, $pre . '0' . ('\d' x length $after);
    }else{
      $num++;
      push @rv, $pre . "[$num-9]" . ('\d' x length $after);
    }
  }
  my $re = join "|", @rv;
  return qr/$re/;
}

sub rxsmaller{
  my ($width, $str) = @_;
  $str = $str + 0;
  $str = sprintf("\%0${width}d", $str);
  my @rv;
    for my $i (1.. length $str){
    my $ri = length($str) - $i;
    my($pre, $num, $after) = (substr($str, 0, $ri), substr($str,$ri,1), substr($str,$ri+1) );
    last if $num =~ /^0$/ && $pre =~ /^0*$/;
    if($num == 0){
      $pre && $pre-- && ($pre = sprintf('%0' . ($width - length($after)-1). 'd', $pre)) &&
      push @rv, $pre . '\d' . ('\d' x length $after);
    }else{
      $num && $num--  &&
      push @rv, $pre . ($num > 0 ? "[0-$num]" : '0') . ('\d' x length $after);
    }
  }
  @rv = keys %{ { map { $_=>1 } @rv }};
  my $re = join "|", @rv;
  return qr/$re/;

}
sub rxbetween{
  my($w, $a, $b) = @_;
  ($a, $b) = (min($a, $b), max($a, $b));
  my($rea, $reb) = (rxgreater($w, $a), rxsmaller($w, $b));
  return qr/$rea(?<=$reb)/;
}

1;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

C<Regex::Number::GtLt> - generate regex for numbers larger, smaller or between one or two given numbers.

=head1 SYNOPSIS

  use Regex::Number::GtLt qw/rxgreater rxsmaller rxbetween/;
  my $gre = rxgreater(6,5000);
  my $lre = rxsmaller(6,6000);
  my $bwre = rxbetween(6,5000,6000);

=head1 DESCRIPTION

This module exports three function - rxgreater, rxsmaller and rxbetween to 
generate regex to match numbers greater, smaller or between two given number.
First arg for all function is width in decimal positions of expected numbers,
second (and third in case of rxbetween) is numbers itself. Numbers to match
against generated regexes expected to be zerofilled to specified width,
e.g. 100 => 000100 and so on.

=head1 EXAMPLE 

    use strict;
    use lib qw!Regex-Number-GtLt/lib!;
    use Regex::Number::GtLt qw/rxgreater rxsmaller rxbetween/;
    my $lre  = rxsmaller(4,11);
    my $bwre = rxbetween(4, 555,559);
    my $gre  = rxgreater(4,991);
    for (map sprintf('%04d',$_), 1..1000){
     print "rxgreater match: $_\n" if /$gre/;
     print "rxsmaller match: $_\n" if /$lre/;
     print "rxbetween match: $_\n" if /$bwre/;
    }

This produce following output:

    rxsmaller match: 0001
    rxsmaller match: 0002
    rxsmaller match: 0003
    rxsmaller match: 0004
    rxsmaller match: 0005
    rxsmaller match: 0006
    rxsmaller match: 0007
    rxsmaller match: 0008
    rxsmaller match: 0009
    rxsmaller match: 0010
    rxbetween match: 0556
    rxbetween match: 0557
    rxbetween match: 0558
    rxgreater match: 0992
    rxgreater match: 0993
    rxgreater match: 0994
    rxgreater match: 0995
    rxgreater match: 0996
    rxgreater match: 0997
    rxgreater match: 0998
    rxgreater match: 0999
    rxgreater match: 1000

Please note required width of generating regex and using sprintf to format numbers.

=head1 SEE ALSO

Regexp::Common

=head1 AUTHOR

I.Frolkov, E<lt>ifrol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by I.Frolkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
