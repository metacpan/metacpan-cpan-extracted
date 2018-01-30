package Squid::Guard::Common;

use 5.008;
use strict;
use warnings;
use Carp;

our @ISA = qw();

our $VERSION = '0.20';


=head1 NAME

Squid::Guard::Common - A set of common utility routines

=head1 SYNOPSYS

    use Squid::Guard::Common;

=head1 DESCRIPTION

Makes the following routines available


=head2 Squid::Guard::Common::argton( $addr )

Takes an address as dotted decimals, bit-count-mask, or hex, and converts it to a 32 bit word.
Taken from ipcalc.pl utility

=cut

# Stuff taken from ipcalc.pl
our $thirtytwobits = 4294967295; # for masking bitwise not on 64 bit arch

sub argton
# expects 1. an address as dotted decimals, bit-count-mask, or hex
#         2. netmask flag. if set -> check netmask and negate wildcard
#            masks
# returns integer or -1 if invalid
{
   my $arg          = shift;
   my $netmask_flag = shift;

   my $i = 24;
   my $n = 0;

   # dotted decimals
   if    ($arg =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
      my @decimals = ($1,$2,$3,$4);
      foreach (@decimals) {
         if ($_ > 255 || $_ < 0) {
            return -1;
         }
         $n += $_ << $i;
         $i -= 8;
      }
      if ($netmask_flag) {
         return validate_netmask($n);
      }
      return $n;
   }

   # bit-count-mask (24 or /24)
   $arg =~ s/^\/(\d+)$/$1/;
   if ($arg =~ /^\d{1,2}$/) {
      if ($arg < 1 || $arg > 32) {
         return -1;
      }
      for ($i=0;$i<$arg;$i++) {
         $n |= 1 << (31-$i);
      }
      return $n;
   }

   # hex
   if ($arg =~   /^[0-9A-Fa-f]{8}$/ ||
       $arg =~ /^0x[0-9A-Fa-f]{8}$/  ) {
      if ($netmask_flag) {
         return validate_netmask(hex($arg));
      }
      return hex($arg);
   }

   # invalid
   return -1;

   sub validate_netmask
   {
      my $mask = shift;
      my $saw_zero = 0;
      # negate wildcard
      if (($mask & (1 << 31)) == 0) {
      #print "WILDCARD\n";
         $mask = ~$mask;
      }
      # find ones following zeros
      for (my $i=0;$i<32;$i++) {
         if (($mask & (1 << (31-$i))) == 0) {
            $saw_zero = 1;
         } else {
            if ($saw_zero) {
      #print "INVALID NETMASK\n";
               return -1;
            }
         }
      }
      return $mask;
   }
}

=head2 Squid::Guard::Common::ntoa( $val )

Takes a 32 bit value and converts it to dotted decimal
Taken from ipcalc.pl utility

=cut

sub ntoa
{
   return join ".",unpack("CCCC",pack("N",shift));
}


=head2 Squid::Guard::Common::network( $addr, $mask )

Takes two arguments as dotted decimals, bit-count-mask, or hex, and calculates the network address in a 32 bit word.

=cut

sub network($$)
{
	my $base = Squid::Guard::Common::argton(shift);
	my $mask = Squid::Guard::Common::argton(shift);
	return $base & $mask;
}


=head2 Squid::Guard::Common::broadcast( $addr, $mask )

Takes two arguments as dotted decimals, bit-count-mask, or hex, and calculates the broadcast address in a 32 bit word.

=cut

sub broadcast($$)
{
	my $base = Squid::Guard::Common::argton(shift);
	my $mask = Squid::Guard::Common::argton(shift);
	my $network = $base & $mask;
	return $network | ((~$mask) & $thirtytwobits);
}


my $cachettl = 0;
my $cachepurgelastrun = 0;
my %cacheh;	# this contains the real cache items
my @cachea;	# this contains the cache keys with the time they where written in the cache.


sub _cachepurge() {
	my $time = time();
	return if $cachepurgelastrun == $time;	# do not purge too often
	$cachepurgelastrun = $time;

        my $t = $time - $cachettl;

	return unless @cachea;			# try to avoid looping through if unnecessary
	return if $cachea[0]->[0] > $t;

	my $ndel = 0;
        LOOP: foreach my $p ( @cachea ) {
                last LOOP if $p->[0] > $t;

                my $k = $p->[1];
                delete( $cacheh{$k} ) if defined( $cacheh{$k} ) && $cacheh{$k}->[0] <= $t;

		$ndel++;
        }
	
	$ndel and splice(@cachea, 0, $ndel);
}


sub _cachewr($$) {
        my ($k, $v) = @_;
	defined($v) or $v = "";	# be sure not to cache undef values since _cacherd returns undef when the value is not in the cache

        my $t = time;

        my @arr = ( $t, $v );
        $cacheh{$k} = \@arr;

        my @arra = ($t, $k);
        push @cachea, \@arra;
}


sub _cacherd($) {
        my ($k) = @_;
	# Purge the cache when reading from it. This also ensures that the remaining cache record are in their ttl. This could be done in other occasions too
	_cachepurge();
        return defined($cacheh{$k}) ? $cacheh{$k}->[1] : undef;
}


# Gets a passwd row, making use of the cache if enabled.

sub _getpwnamcache($) {
	my $nam = shift;
	my $k = "PWNAM: $nam";

	if( $cachettl ) {
		my $v = _cacherd( $k );
		defined($v) and return split( /:/, $v );
	}

	my @a = getpwnam($nam);

	if( $cachettl ) {
		_cachewr( $k, join( ':', @a ) );
	}

	return @a;
}


sub _getgrnamcache($) {
	my $nam = shift;
	my $k = "GRNAM: $nam";

	if( $cachettl ) {
		my $v = _cacherd( $k );
		defined($v) and return split( /:/, $v );
	}

	my @a = getgrnam($nam);

	if( $cachettl ) {
		_cachewr( $k, join( ':', @a ) );
	}

	return @a;
}


# Runs a command, making use of the cache if enabled.

sub _runcache($) {
	my $cmd = shift;
	my $k = "RUN: $cmd";

	my $v;
	if( $cachettl ) {
		$v = _cacherd( $k );
		defined($v) and return $v;
	}

	$v = `$cmd`;

	if( $cachettl ) {
		_cachewr( $k, $v );
	}

	return $v;
}




1;
