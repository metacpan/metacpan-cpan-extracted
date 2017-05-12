package SQLite::More;
our $VERSION = '0.10';
use 5.008008;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(nvl decode random min max sum avg geomavg stddev median percentile distance) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(sqlite_more);
use DBD::SQLite 1.27;  #minimum with $dbh->sqlite_create_function
use DBI         1.609; #minimum with $dbh->sqlite_create_function
use Digest::MD5;
use Carp;

sub sqlite_more
{
  my $dbh=shift();
  
  $dbh->sqlite_create_function( 'nvl',       2, sub { nvl(@_) } );
  $dbh->sqlite_create_function( 'decode',   -1, sub { decode(@_) } );
#  $dbh->sqlite_create_function( 'sysdate',   0, sub { sysdate() } ); #hm
  $dbh->sqlite_create_function( 'upper',     1, sub { uc($_[0]) } );
  $dbh->sqlite_create_function( 'lower',     1, sub { lc($_[0]) } );
  $dbh->sqlite_create_function( 'least',    -1, sub { min(@_) } );
  $dbh->sqlite_create_function( 'greatest', -1, sub { max(@_) } );
  $dbh->sqlite_create_function( 'md5',       1, sub { Digest::MD5::md5(@_) } );
  $dbh->sqlite_create_function( 'md5_hex',   1, sub { Digest::MD5::md5_hex(@_) } );
  $dbh->sqlite_create_function( 'random',    2, sub { random(@_) } );
  $dbh->sqlite_create_function( 'sprintf',  -1, sub { sprintf(shift(),@_) } );
  $dbh->sqlite_create_function( 'time',      0, sub { time() } );

  $dbh->sqlite_create_function( 'sqrt',      1, sub { sqrt(shift) } );
  $dbh->sqlite_create_function( 'power',     2, sub { shift() ** shift() } );
  $dbh->sqlite_create_function( 'ln',        1, sub { log(shift) } ); #2.71
  $dbh->sqlite_create_function( 'log',       1, sub { log(shift) } ); #2.71
  $dbh->sqlite_create_function( 'loge',      1, sub { log(shift) } ); #2.71
  $dbh->sqlite_create_function( 'log10',     1, sub { log(shift)/log(10) } );
  $dbh->sqlite_create_function( 'log2',      1, sub { log(shift)/log(2) } );
  $dbh->sqlite_create_function( 'pi',        0, sub { 3.14159265358979323846264338327950288419716939937510 } );
  $dbh->sqlite_create_function( 'sin',       1, sub { sin(shift) } );
  $dbh->sqlite_create_function( 'cos',       1, sub { cos(shift) } );
  $dbh->sqlite_create_function( 'tan',       1, sub { sin($_[0])/cos($_[0]) } );
  $dbh->sqlite_create_function( 'atan2',     2, sub { atan2(shift,shift) } );
  $dbh->sqlite_create_function( 'perlhash', -1, sub { perlhash(@_) } );
  
  $dbh->sqlite_create_function( 'distance',  4, sub { distance(@_) } );

 #$dbh->sqlite_create_function( 'sum',      -1, sub { sum(@_) } );
  $dbh->sqlite_create_aggregate( "variance", 1, 'SQLite::More::variance' );
  $dbh->sqlite_create_aggregate( "stddev",   1, 'SQLite::More::stddev' );
  $dbh->sqlite_create_aggregate( "median",   1, 'SQLite::More::median' );
  $dbh->sqlite_create_aggregate( "percentile", 2, 'SQLite::More::percentile' );

}

sub nvl  #copied from Acme::Tools 1.14
{
  return $_[0] if defined $_[0] and length($_[0]) or @_==1;
  return $_[1] if @_==2;
  return nvl(@_[1..$#_]) if @_>2;
  return undef;
}
sub decode  #copied from Acme::Tools 1.14
{
  croak "Must have a mimimum of two arguments" if @_<2;
  my $uttrykk=shift;
  if(defined$uttrykk){ shift eq $uttrykk and return shift or shift for 1..@_/2 }
  else               { not defined shift and return shift or shift for 1..@_/2 }
  return shift;
}
sub random  #copied from Acme::Tools 1.14
{
  my($from,$to)=@_;
  if(ref($from) eq 'ARRAY'){
      return $$from[random($#$from)];
  }
  ($from,$to)=(0,$from) if @_==1;
  ($from,$to)=($to,$from) if $from>$to;
  return int($from+rand(1+$to-$from));
}
sub min  #copied from Acme::Tools 1.14
{
  my $min;
  for(@_){ $min=$_ if defined($_) and !defined($min) || $_<$min }
  $min;
}
sub max  #copied from Acme::Tools 1.14
{
  my $max;
  for(@_){ $max=$_ if defined($_) and !defined($max) || $_>$max }
  $max;
}
sub sum  #copied from Acme::Tools 1.14
{
  my $sum; no warnings;
  $sum+=$_ for @_;
  $sum;
}
sub avg  #copied from Acme::Tools 1.14
{
  my $sum=0;
  no warnings;
  $sum+=$_ for @_;
  return $sum/@_ if @_>0;
  return undef;
}
sub geomavg   #copied from Acme::Tools 1.14
{ exp(avg(map log($_),@_)) }
sub stddev  #copied from Acme::Tools 1.14
{
  my $sumx2; $sumx2+=$_*$_ for @_;
  my $sumx; $sumx+=$_ for @_;
  sqrt( (@_*$sumx2-$sumx*$sumx)/(@_*(@_-1)) );
}
sub median  #copied from Acme::Tools 1.14
{
  no warnings;
  my @list = sort {$a<=>$b} @_;
  my $n=@list;
  $n%2
    ? $list[($n-1)/2]
    : ($list[$n/2-1] + $list[$n/2])/2;
}
sub percentile  #copied from Acme::Tools 1.14
{
  my(@p,@t,@ret);
  if(ref($_[0]) eq 'ARRAY'){ @p=@{shift()} }
  elsif(not ref($_[0]))    { @p=(shift())  }
  else{croak()}
  @t=@_;
  return if not @p;
  croak if not @t;
  @t=sort{$a<=>$b}@t;
  push@t,$t[0] if @t==1;
  for(@p){
    croak if $_<0 or $_>100;
    my $i=(@t+1)*$_/100-1;
    push@ret,
      $i<0       ? $t[0]+($t[1]-$t[0])*$i:
      $i>$#t     ? $t[-1]+($t[-1]-$t[-2])*($i-$#t):
      $i==int($i)? $t[$i]:
                   $t[$i]*(int($i+1)-$i) + $t[$i+1]*($i-int($i));
  }
  return @p==1 ? $ret[0] : @ret;
}
our $Distance_factor=3.141592653589793238462643383279502884197169399375105820974944592307816406286 / 180;
sub distance  #copied from Acme::Tools 1.14
{
  my($lat1,$lon1,$lat2,$lon2)=map $Distance_factor*$_, @_;
  my $a= sin(($lat2-$lat1)/2)**2
       + sin(($lon2-$lon1)/2)**2 * cos($lat1) * cos($lat2);
  my $sqrt_a  =sqrt($a);    $sqrt_a  =1 if $sqrt_a  >1;
  my $sqrt_1ma=sqrt(1-$a);  $sqrt_1ma=1 if $sqrt_1ma>1;
  my $c=2*atan2($sqrt_a,$sqrt_1ma);
  my($Re,$Rp)=( 6378137.0, 6356752.3 ); #earth equatorial and polar radius
  my $R=$Re-($Re-$Rp)*sin(abs($lat1+$lat2)/2); #approx
  return $c*$R;
}
sub perlhash
{
  my($hashname,$key,$val)=@_;
  $hashname=((caller(3))[0]||'main').'::'.$hashname if $hashname!~/::/;
  die if not $hashname=~/^(\w+::)*\w+$/; #noedv?
  no strict 'refs';
  my $r=$$hashname{$key};
  $$hashname{$key}=$val if @_>=3;
  return $r;
}


1;
package SQLite::More::variance;
  sub new {bless [],shift}sub step{push @{$_[0]},$_[1]}
  sub finalize {
      my $self = shift;
      my $n = @$self;
      return undef if not defined $n or $n < 2; #need at least 2
      my $avg = 0;
      $avg += $_ for @$self;
      $avg /= $n;
      my $sigma = 0;
      $sigma += ($_-$avg)**2 for @$self;
      $sigma /= $n - 1;
      return $sigma;
  }
1;

package SQLite::More::stddev;
  sub new {bless {n=>undef,sumx=>undef,sumx2=>undef},shift}
  sub step{
    my($self,$value)=@_;
    $$self{'n'}++;
    $$self{'sumx'}+=$value;
    $$self{'sumx2'}+=$value**2;
  }
  sub finalize {
    my $self=shift;
    my $n=$$self{'n'};
    return undef if not defined $n or $n < 2; #need at least 2
    return sqrt( ($n*$$self{'sumx2'}-$$self{'sumx'}**2)/$n/($n-1) );
  }
1;

package SQLite::More::median;
  sub new {bless [],shift}sub step{push @{$_[0]},$_[1]}
  sub finalize {SQLite::More::median(@{$_[0]})}
1;

package SQLite::More::percentile;
  sub new {bless [],shift}
  sub step{
    my($self,$percentile,$value)=@_;
    push @$self,$percentile if not @$self;
    die if $$self[0] != $percentile;
    push @$self,$value;
  }
  sub finalize {
    #$_[0][0]*=100 if $_[0][0]<2; #hm
    SQLite::More::percentile(@{$_[0]})
  }

package SQLite::More::correlation;
  sub new {bless [],shift}sub step{push @{$_[0]},$_[1]}
  sub finalize {
  }
1;

__END__

=head1 NAME

SQLite::More - Add more SQL functions to SQLite in Perl - some of those found in Oracle and others

=head1 SYNOPSIS

 use DBI 1.609;
 use SQLite::More;
 my $file = '/path/to/some/database_file.sqlite';
 my $dbh  = DBI->connect("dbi:SQLite:$file");
 my $sql  = "select median(salary) from employee";         #  <---- median
 sqlite_more($dbh);                                        #  attach more functions
 print "Median salary: ";
 print "".( ($dbh->selectrow_array($sql))[0] )."\n";

=head1 DESCRIPTION

SQLite do not have all the SQL functions that Oracle and other RDBMSs have.

Using C<SQLite::More> makes more of those functions available to user SQL statements.

SQLite::More uses the class function C<sqlite_create_function()> of
L<DBD::SQLite>, which is available from DBD::SQLite version 1.27
released 23. nov. 2009.

B<Extra functions added my SQLite::More version 0.02:>

Normal row functions:

 nvl(x,y)                              if x is null then y else x
 decode(x, c1,r1, c2,r2, c3,r3, d)     if x=c1 then r1 elsif x=c2 then r2 elsif x=c3 then r3 else d

 upper(string)               returns perls uc() of that string, may not work for chars other than a-z
 lower(string)               returns perls lc() of that string, may not work for chars other than A-Z
 least(n1,n2,n3,...)         returns the minimum number except null values
 greatest(n1,n2,n3,...)      returns the maximum number except null values
 md5(string)                 returns the 128-bit binary MD5-"string", uses Digest::MD5::md5()
 md5_hex(string)             returns the hexadecimal representation of md5 of a string, uses Digest::MD5::md5_hex()
 random(a,b)                 returns a pseudo-random number between a and b inclusive, i.e. random(1,6) "is" a dice
 time()                      returns the number of seconds since 1. jan 1970, uses perls time function
 sprintf(format,x,y,z,...)   returns a string, uses perl sprintf function

 sqrt(x)                     returns the square root of a number
 power(x,p)                  returns x^p or x**p sice either is an operator in SQL
 ln(x)                       returns the natural logarithm of x, based on e = 2.718281828459...
 log(x)                      returns the natural logarithm of x, based on e = 2.718281828459...
 loge(x)                     returns the natural logarithm of x, based on e = 2.718281828459...
 log10(x)                    returns the logarithm of x, based on 10, that is log10(1000) = 3
 log2(x)                     returns the logarithm of x, based on 2, that is log2(1024) = 10
 pi()                        returns the constant 3.14159265358979323846264338327950288419716939937510
 sin(x)                      returns result of x of trigonometric sinus, x in radians, sin(pi/2) = 1
 cos(x)                      returns result of x of trigonometric sinus, x in radians, cos(pi) = -1
 tan(x)                      tan(x) = sin(x) / cos(x)
 atan2(x,y)                  

 distance(lat1,lon1,lat2,lon2)   ca the earth surface distance in meters given two geographical coordinates

 perlhash('hashname',k,v)    returns $package::hashname{k} where package is main or the callers package

Aggregate functions:

 median(value)
 percentile(p,value)         p is a number between 0 and 100
 percentile(50,value)        same as median(value)
 variance(value)             sum(map ($_-avg(@values))**2, @values)
 stddev(value)               standard deviation, sqrt( (n*sum(map$_**2,@values)-sum(@values)**2) / (n*(n-1)) )

=head2 perlhash

The perlhash function takes two or three input arguments.

First argument:

Name of a perl hash. The name can be fully qualified with package name (like C<main::h> or C<MyClass::hash>)
or just the C<hashname> in which case the package name is deducted by SQLite::More using perls I<caller()>.

Remember to declare the hash with C<our> or C<local>, do not use C<my>.

Two arguments:

- the perl hash value is returned

Three arguments:

- the perl hash old value is returned, but sets the value to the third argument.

Example:

 our %hash=(good=>123, bad=>234, ugly=>345);
 $dbh->do("update some_table set score=perlhash('hash',name)       where name in ('good','bad','ugly')");
 $dbh->do("update some_table set score=perlhash('main::hash',name) where name in ('good','bad','ugly')");
 $dbh->do("update some_table set score=perlhash('hash',name,0)     where name in ('good','bad','ugly')");
 print $hash{'good'}; # some_table.score is 123 for 'good', but $hash{'good'} is set to 0 afterwards.

 package notmain;
 our %hash=(good=>111, bad=>222, ugly=>333);
 $dbh->do("update some_table set score=perlhash('hash',name)         "); # this and
 $dbh->do("update some_table set score=perlhash('notmain::hash',name)"); # this is the same


=head2 EXPORT

 sqlite_more($dbh)

=head1 SQL EXAMPLES

 select
   department,                                 -- which department
   sum(1),                                     -- number of employees in each department
   avg(salary),                                -- average salsry in each department
   median(salary),                             -- median salary in each department
   max(salary),                                -- top earners salary in each department
   stddev(salary),                             -- standard deviatino within department
   percentile(90,salary),                      -- minimum salary of the top 10% earners in each department
   sum(decode(least(100000,salary),100000,1)), -- how many six figure earners (and 7 and 8 and ...) in each department
   sum(salary)                                 -- total salaries in each department
 from employees
 group by department;

 update player set dice = random(1,6);


=head1 INSTALLING

 sudo cpan DBI                 # needs >= 1.609 it seems, at least 1.607 isn't ok
 sudo cpan DBD::SQLite         # needs >= 1.27
 sudo cpan SQLite::More

Or:

 sudo /usr/bin/cpan DBI                 # needs >= 1.609 it seems, at least 1.607 isn't ok
 sudo /usr/bin/cpan DBD::SQLite         # needs >= 1.27
 sudo /usr/bin/cpan SQLite::More

Or:

 sudo apt-get install perl-DBI perl-DBD-SQLite    # might be too old
 sudo cpan SQLite::More

Or:

 sudo yum install perl-DBI perl-DBD-SQLite        # might be too old
 sudo cpan SQLite::More

Or even messier:

 sudo bash
 perl -MDBI          -le'print$DBI::VERSION'           # check current version, should be at least 1.609
 perl -MDBD::SQLite  -le'print$DBD::SQLite::VERSION'   # check current version, should be at least 1.27
 perl -MSQLite::More -le'print$SQLite::More::VERSION'  # check current version
 cd /tmp

 VERSION=1.609
 wget http://search.cpan.org/CPAN/authors/id/T/TI/TIMB/DBI-$VERSION.tar.gz
 tar zxf DBI-$VERSION.tar.gz
 cd      DBI-$VERSION
 perl Makefile.PL  # PREFIX=/...   #possibly
 make test && make install
 #make install                     #maybe anyway
 #--Maybe even:
 #cp -p /usr/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi/auto/DBI/DBI.so   \
 #      /usr/lib64/perl5/vendor_perl/5.8.8/x86_64-linux-thread-multi/auto/DBI/DBI.so

 VERSION=1.31
 wget http://search.cpan.org/CPAN/authors/id/A/AD/ADAMK/DBD-SQLite-$VERSION.tar.gz
 tar zxf DBD-SQLite-$VERSION.tar.gz
 cd      DBD-SQLite-$VERSION
 perl Makefile.PL  # PREFIX=/...   #possibly
 make test && make install
 #make install                     #maybe anyway

 VERSION=0.10
 wget http://search.cpan.org/CPAN/authors/id/K/KJ/KJETIL/SQLite-More-$VERSION.tar.gz
 tar zxf SQLite-More-$VERSION.tar.gz
 cd      SQLite-More-$VERSION
 perl Makefile.PL  # PREFIX=/...   #possibly
 make test && make install

=head1 SEE ALSO

L<DBD::SQLite>

L<DBI>

=head1 HISTORY

Release history

 0.10   Nov 2010

=head1 AUTHOR

Kjetil Skotheim, E<lt>kjetilskotheim@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kjetil Skotheim

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
