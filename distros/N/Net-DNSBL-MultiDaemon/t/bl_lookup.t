# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

use Net::DNSBL::MultiDaemon qw(
	bl_lookup
);

use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	newhead
	get1char
);
use Net::DNS::ToolKit::Debug qw(
        print_head
        print_buf
);     

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

sub expect {
  my $x = shift;
  my @exp;
  foreach(split(/\n/,$x)) {
    if ($_ =~ /0x\w+\s+(\d+) /) {
      push @exp,$1;
    }
  }  
  return @exp;
}
 
sub chk_exp {
  my($bp,$exp) = @_;
  my $todo = '';
  my @expect = expect($$exp);
  foreach(0..length($$bp) -1) {
    $char = get1char($bp,$_);
    next if $char == $expect[$_];
    print "buffer mismatch $_, got: $char, exp: $expect[$_]\nnot ";
    $todo = 'fix test for marginal dn_comp resolver implementations';
    last;
  }
  &ok($todo);
}

#####
##### testing - bl_lookup($put,$mp,$rtp,$sinaddr,$alarm,$rid,$id,$rip,$type,@blist);
#####

my($get,$put,$parse) = new Net::DNS::ToolKit::RR;
my %threads;
my $buf;
my @bldomains = qw(
	one.com
	two.net
	three.org
);
my $sinaddr = 'known text';
my $zone = 'once.upon.a.time.com';
my $alarm = 55;
my $revIP = '4.3.2.1';
my $rid = 65432;
my $id = 12345;
my $type = T_AXFR;		# just for the heck of it

##	generate initial buffer
my $aval = next_sec() + $alarm;
bl_lookup($put,\$buf,\%threads,$sinaddr,$alarm,$rid,$id,$revIP,$type,$zone,@bldomains);

## test 2	verify threads
print "more than one thread\nnot "
	unless 1 == keys %threads;
&ok;

## test 3	verify threads content key
@_ = %threads;
print "bad key, got: $_, exp: $rid\nnot "
	unless $_[0] == $rid;
&ok;

## test 4	verify thread sinaddr
print "thread sinaddr mismatch, got: $_, exp: $sinaddr\nnot "
	unless ($_ = ${$_[1]->{args}}[0]) eq $sinaddr;
&ok;

## test 5	verify thread revIP
print "thread revIP mismatch, got: $_, exp: $revIP\nnot "
	unless ($_ = ${$_[1]->{args}}[1]) eq $revIP;
&ok;

## test 6	verify thread type
print "thread type mismatch, got: $_, exp: $type\nnot "
	unless ($_ = ${$_[1]->{args}}[3]) == $type;
&ok;

## test 7	verify thread zone
print "thread zone mismatch, got: $_, exp: $zone\nnot "
	unless ($_ = ${$_[1]->{args}}[4]) eq $zone;
&ok;

## test 8	verify thread original id
print "thread oid mismatch, got: $_, exp $id\nnot "
	unless ($_ = ${$_[1]->{args}}[2]) == $id;
&ok;

## test 9-11	verify bl domains
foreach(0..$#bldomains) {
  print "thread bldomain mismatch, got: ". ${$_[1]->{args}}[5+$_] ." exp: $bldomains[$_]\nnot "
	unless ${$_[1]->{args}}[5+$_] eq $bldomains[$_];
  &ok;
}

## test 12	verify alarm value
print "alarm mismatch, got: $_, exp: $aval\nnot "
	unless $_[1]->{expire} == $aval;
&ok;

## test 13	verify question content
my $expected = q|
  0     :  1111_1111  0xFF  255    
  1     :  1001_1000  0x98  152    
  2     :  0000_0001  0x01    1    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0001  0x01    1    
  13    :  0011_0100  0x34   52  4  
  14    :  0000_0001  0x01    1    
  15    :  0011_0011  0x33   51  3  
  16    :  0000_0001  0x01    1    
  17    :  0011_0010  0x32   50  2  
  18    :  0000_0001  0x01    1    
  19    :  0011_0001  0x31   49  1  
  20    :  0000_0011  0x03    3    
  21    :  0110_1111  0x6F  111  o  
  22    :  0110_1110  0x6E  110  n  
  23    :  0110_0101  0x65  101  e  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
|;

#print_head(\$buf);
#print_buf(\$buf);

chk_exp(\$buf,\$expected);
