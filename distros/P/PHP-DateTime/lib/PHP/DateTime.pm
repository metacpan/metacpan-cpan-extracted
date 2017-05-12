package PHP::DateTime;

=head1 NAME

PHP::DateTime - Clone of PHP's date and time functions.

=head1 SYNOPSIS

  use PHP::DateTime;
  
  if( checkdate($month,$day,$year) ){ print 'The date is good.'; }
  
  print date( $format, $time );
  print date( $format ); # Defaults to the current time.
  
  @d = getdate(); # A list at the current time.
  @d = getdate($time); # A list at the specified time.
  $d = getdate($time); # An array ref at the specified time.
  
  my @g = gettimeofday(); # A list.
  my $g = gettimeofday(); # An array ref.
  
  my $then = mktime( $hour, $min, $sec, $month, $day, $year );

=head1 DESCRIPTION

Duplicates some of PHP's date and time functions.  Why?  I can't remember. 
It should be useful if you are trying to integrate your perl app with a php app. 
Much like PHP this module gratuitously exports all its functions upon a use(). 
Neat, eh?

=cut

use strict;
use warnings;

use Time::DaysInMonth qw();
use Time::Timezone qw();
use Time::HiRes qw();
use Time::Local qw();

our $VERSION = '0.05';

my $days_short   = [qw( Sun Mon Tue Wed Thr Fri Sat )];
my $days_long    = [qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday )];
my $months_short = [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )];
my $months_long  = [qw( January February March April May June July August September October November December )];

use Exporter qw( import );
our @EXPORT = qw(
    checkdate date getdate gettimeofday mktime
);

=head1 METHODS

All of these methods should match PHP's methods exactly.

  - Months are 1-12.
  - Days are 1-31.
  - Years are in four digit format (1997, not 97).

=head2 checkdate

  if( checkdate($month,$day,$year) ){ print 'The date is good.'; }

L<http://php.net/manual/en/function.checkdate.php>

=cut

sub checkdate {
    my($month,$day,$year) = @_;
    return (
        $year>=1 and $year<=32767 and 
        $month>=1 and $month<=12 and 
        $day>=1 and $day <= Time::DaysInMonth::days_in($year,$month)
    );
}

=head2 date

  print date( $format, $time );
  print date( $format ); # Defaults to the current time.

L<http://php.net/manual/en/function.date.php>

=cut

sub date {
    my $format = shift;
    my $esecs = (@_?shift():time());
    my $tzoffset;
    if(@_){
        $tzoffset = shift;
        if($tzoffset=~/^-?[0-9]+\.[0-9]+$/s){ $tzoffset=$tzoffset*60*60; }
        elsif($tzoffset=~/^(-?)([0-9]+):([0-9]+)$/s){ $tzoffset=(($1*$2*60)+($1*$3))*60; }
        else{ $tzoffset+=0; }
    }else{
        $tzoffset = Time::Timezone::tz_local_offset();
    }
    $esecs += $tzoffset;
    my @times = gmtime($esecs);

    my $str;
    my @chars = split(//,$format);
    foreach (@chars){
        if($_ eq 'D'){ $str.=$days_short->[$times[6]]; }
        elsif($_ eq 'M'){ $str.=$months_short->[$times[4]]; }
        elsif($_ eq 'd'){ $str.=($times[3]<10?'0':'').$times[3]; }
        elsif($_ eq 'Y'){ $str.=$times[5]+1900; }
        elsif($_ eq 'g'){ $str.=($times[2]==0?12:$times[2]-($times[2]>12?12:0)); }
        elsif($_ eq 'i'){ $str.=($times[1]<10?'0':'').$times[1]; }
        elsif($_ eq 'a'){ $str.=($times[2]>=12?'pm':'am'); }
        else{ $str.=$_; }
    }

    return $str;
}

=head2 getdate

  @d = getdate(); # A list at the current time.
  @d = getdate($time); # A list at the specified time.
  $d = getdate($time); # An array ref at the specified time.

L<http://php.net/manual/en/function.getdate.php>

=cut

sub getdate {
    my($esecs) = (@_?shift():time);
    my @times = localtime($esecs);
    @times = (
        $times[0],$times[1],$times[2],
        $times[3],$times[6],$times[4]+1,$times[5]+1900,$times[6],
        $days_long->[$times[6]],$months_long->[$times[4]],
        $esecs
    );
    if(wantarray){ return @times; }
    else{ return [@times]; }
}

=head2 gettimeofday

  my %g = gettimeofday(); # A hash.
  my $g = gettimeofday(); # An hash ref.

L<http://php.net/manual/en/function.gettimeofday.php>

=cut

sub gettimeofday {
    my($sec,$usec) = Time::HiRes::gettimeofday();
    my $minuteswest = int((-1 * Time::Timezone::tz_local_offset())/60);
    my $dsttime = ((localtime(time))[8]?1:0);
    my %times = ( sec=>$sec,usec=>$usec,minuteswest=>$minuteswest,dsttime=>$dsttime );
    if(wantarray){ return %times; }
    else{ return {%times}; }
}

=head2 mktime

  my $then = mktime( $hour, $min, $sec, $month, $day, $year );

L<http://php.net/manual/en/function.mktime.php>

=cut

sub mktime {
    # hour, minute, second, month, day, year, is_dst
    my $times = [ ( localtime(time) )[2,1,0,4,3,5] ];
    $times->[3]++;
    $times->[5]+=1900;

    for( my $i=0; $i<@$times; $i++ ){
        last if(!@_);
        $times->[$i] = shift;
    }

    $times->[3]--;
    $times->[5]-=1900;
    my $esecs = Time::Local::timelocal( (@$times)[2,1,0,4,3,5] );

    return $esecs;
}

1;
__END__

=head1 SEE ALSO

L<http://php.net/manual/en/ref.datetime.php>

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

