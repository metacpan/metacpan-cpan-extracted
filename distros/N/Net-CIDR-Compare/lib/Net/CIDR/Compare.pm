package Net::CIDR::Compare;

use 5.005000;
use strict;
use warnings;
use Carp;
use Net::CIDR;
use Net::Netmask;

$|++;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::CIDR::Compare ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Net::CIDR::Compare::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Net::CIDR::Compare', $VERSION);

# Preloaded methods go here.

use IO::File;
use File::Temp qw(tempfile tempdir);
use IO::Socket;
use Data::Dumper;

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref($invocant) || $invocant;
  my $cidr_ptr = start_new();
  my $self = { cidr_ptr => $cidr_ptr };
  $self->{print_errors} = 1 if $params{print_errors};
  return bless $self, $class;
}

sub new_list {
  my $self = shift;
  my $list_ptr = setup_new_list($self->{cidr_ptr});
  return $list_ptr;
}

sub remove_list {
  my $self = shift;
  my $list_ptr = shift;
  delete_list($self->{cidr_ptr}, $list_ptr);
}

sub add_range {
  my $self = shift;
  my $list = shift;
  my $ip_range = shift;
  my $skip_check = shift;
  my $array_ref = ();
  if ($skip_check) {
    push @$array_ref, $ip_range;
  }
  else {
    $array_ref = $self->process_ip_range($ip_range) || return 0;
  }
  foreach my $cidr_range (@$array_ref) {
    my ($network, $cidr) = split(/\//, $cidr_range);
    if (!defined($cidr)) {
      $self->{error} = "IP range is malformed [$ip_range].";
      print STDERR $self->{error} . "\n" if $self->{print_errors};
      return 0;
    }
    my $network_decimal = unpack 'N', inet_aton($network);
    save_cidr($list, $network_decimal, $cidr); 
  }
  return 1;
}

sub process_intersection {
  my $self = shift;
  while ($self->get_next_intersection_range()) {
    # do nothing.  this frees C pointers.
  }
  delete $self->{leftover_cidr_processed};
  delete $self->{leftover_cidr_unprocessed};
  delete $self->{expand_cidr};
  my %params = @_;
  $self->{expand_cidr} = $params{expand_cidr};
  my $cidr_ptr = $self->{cidr_ptr};
  dump_intersection_output($cidr_ptr);
}

sub get_next_intersection_range {
  my $self = shift;
  my $cidr_ptr = $self->{cidr_ptr};
  if ($self->{leftover_cidr_processed} && @{$self->{leftover_cidr_processed}}) {
    return shift @{$self->{leftover_cidr_processed}};
  }
  if ($self->{leftover_cidr_unprocessed} && @{$self->{leftover_cidr_unprocessed}}) {
    my $range = shift @{$self->{leftover_cidr_unprocessed}};
    my $cidr_aref = expand_cidr($range, $self->{expand_cidr});
    my $first_expand_range = shift @$cidr_aref;
    if (@$cidr_aref) {
      unshift @{$self->{leftover_cidr_processed}}, @$cidr_aref;
    }
    return $first_expand_range;
  }
  my $range = dump_next_intersection_output($cidr_ptr);
  return unless $range;
  if (defined($self->{expand_cidr})) {
    my ($network, $cidr) = split("/", $range);
    if ($cidr >= $self->{expand_cidr}) {
      return $range;
    }
    else {
      if (($self->{expand_cidr} - $cidr) > 16) {
        my $cidr_aref = expand_cidr($range, 16);
        my $first_slash16 = shift @$cidr_aref;
        my $cidr_aref_first_slash16 = expand_cidr($first_slash16, $self->{expand_cidr});
        my $first_expand_range = shift @$cidr_aref_first_slash16;
        push @{$self->{leftover_cidr_processed}}, @$cidr_aref_first_slash16;
        push @{$self->{leftover_cidr_unprocessed}}, @$cidr_aref;
        return $first_expand_range;
      }
      my $cidr_aref = expand_cidr($range, $self->{expand_cidr});
      my $first_expand_range = shift @$cidr_aref;
      push @{$self->{leftover_cidr_processed}}, @$cidr_aref;
      return $first_expand_range;
    }
  }
  return $range;
}

sub process_ip_range {
  my $self = shift;
  my $ip_range = shift;
  my @octets;
  my $cidr;
  $ip_range =~ s/(\s|\n|\r)+//g;
  if ($ip_range =~ /^(\d+\.\d+\.\d+\.\d+)-(\d+\.\d+\.\d+\.\d+)$/) {
    my $ip_start = $1;
    my $ip_end = $2;
    my $ip_start_decimal = unpack 'N', inet_aton($ip_start);
    my $ip_end_decimal   = unpack 'N', inet_aton($ip_end);
    $self->process_ip_range($ip_start) || return 0; # Do this to run further sanity checks
    $self->process_ip_range($ip_end)   || return 0; #
    if ($ip_end_decimal < $ip_start_decimal) {
      $self->{error} = "IP range is malformed [$ip_range]. Range problem.";
      print STDERR $self->{error} . "\n" if $self->{print_errors};
      return 0;
    }
    my @cidr_array = Net::CIDR::range2cidr("$ip_start-$ip_end");
    return \@cidr_array;
  }
  elsif ($ip_range =~ /^(.+)\.(.+)\.(.+)\.([\d\-\[\]\*]+)$/) {
    @octets = ($1, $2, $3, $4);
  }
  elsif ($ip_range =~ /^(.+)\.(.+)\.(.+)\.(.+)\/(\d+)$/) {
    @octets = ($1, $2, $3, $4);
    $cidr = $5 if defined $5;
  }
  else {
    $self->{error} = "IP range is malformed [$ip_range]";
    print STDERR $self->{error} . "\n" if $self->{print_errors};
    return 0;
  }
  my $range_flag = 0;
  for (my $x = 0; $x <= $#octets; $x++) {
    if ($octets[$x] eq "[0-255]") {
      $octets[$x] = "*";
    }
    if ($octets[$x] =~ /^\[(\d+)-(\d+)\]$/ && !defined($cidr)) {
      my $begin_range = $1;
      my $end_range = $2;
      if ($begin_range < 0 || $begin_range > 255 || $end_range < 0 || $end_range > 255 || $begin_range > $end_range) {
        $self->{error} = "IP range is malformed [$ip_range].  Range problem.";
        print STDERR $self->{error} . "\n" if $self->{print_errors};
        return 0;
      }
      if ($range_flag) {
        $self->{error} = "IP range is malformed [$ip_range].  Range values can only be used for one octet.";
        print STDERR $self->{error} . "\n" if $self->{print_errors};
        return 0;
      }
      $range_flag = 1;
    }
    elsif ($octets[$x] =~ /^\d+$/) {
      if ($range_flag) {
        $self->{error} = "IP range is malformed [$ip_range].  Only asterisks can be used after a bracketed range. Example: 10.10.[1-2].*";
        print STDERR $self->{error} . "\n" if $self->{print_errors};
        return 0;
      }
      if ($octets[$x] < 0 || $octets[$x] > 255) {
        $self->{error} = "IP range is malformed [$ip_range].  Range problem.";
        print STDERR $self->{error} . "\n" if $self->{print_errors};
        return 0;
      }
    }
    elsif ($octets[$x] =~ /^\*$/ && !defined($cidr)) {
      # Do nothing
    }
    else {
      $self->{error} = "IP range is malformed [$ip_range]";
      print STDERR $self->{error} . "\n" if $self->{print_errors};
      return 0;
    }
  }
  if (defined($cidr) && ($cidr > 32 || $cidr < 0)) {
    $self->{error} = "IP range is malformed [$ip_range].  Incorrect CIDR notation.";
    print STDERR $self->{error} . "\n" if $self->{print_errors};
    return 0;
  }
  # Passed initial checks

  my %hash;
  if (defined($cidr)) {
    my @range = Net::CIDR::cidr2range($ip_range);
    ($hash{ip_start}, $hash{ip_end}) = split(/-/, $range[0]);
    $hash{ip_start_decimal} = unpack 'N', inet_aton($hash{ip_start});
    $hash{ip_end_decimal}   = unpack 'N', inet_aton($hash{ip_end});
  }
  else {
    for (my $x = 0; $x < 4; $x++) {
      if ($octets[$x] eq '*') {
        $hash{ip_start} .= "0.";
        $hash{ip_end} .= "255.";
      }
      elsif ($octets[$x] =~ /\[(\d+)-(\d+)\]/) {
        $hash{ip_start} .= $1 . ".";
        $hash{ip_end} .= $2 . ".";
      }
      elsif ($octets[$x] =~ /(\d+)/) {
        $hash{ip_start} .= $1 . ".";
        $hash{ip_end} .= $1 . ".";
      }
      else {
        $self->{error} = "Got unexpected IP value [$ip_range]";
        print STDERR $self->{error} . "\n" if $self->{print_errors};
        return 0;
      }
    }
    $hash{ip_start} =~ s/^(.+)\.$/$1/;
    $hash{ip_end}   =~ s/^(.+)\.$/$1/;
  }
  my @cidr_array = range2cidrlist($hash{ip_start}, $hash{ip_end});
  return \@cidr_array;
}

sub expand_cidr {
  my $cidr_range = shift;
  my $level = shift; # Should be 0 thru 32
  die "Invalid CIDR notation [$level]" if ($level < 0 || $level > 32);
 
  my ($network, $cidr) = split("/", $cidr_range);

  my $network_decimal = unpack 'N', inet_aton($network);
  my @result = ();
  if ($cidr >= $level) {
    push @result, $cidr_range;
    return \@result;
  }
  my $num_slices = 2 ** ($level - $cidr);
  for (my $x = 0; $x < $num_slices; $x++) {
    my $add = $x * (2 ** (32 - $level));
    my $smaller_network = inet_ntoa(pack 'N', ($network_decimal + $add));
    push @result, ($smaller_network . "/" . $level);
  }
  return \@result;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::CIDR::Compare - Find intersections across multiple lists of CIDR ranges, fast.

=head1 SYNOPSIS

  use Net::CIDR::Compare;

  my $collection = Net::CIDR::Compare->new(print_errors => 1);

  my $first_list = $collection->new_list();
  $collection->add_range($first_list, "10.10.0.0/16", 1);

  my $second_list = $collection->new_list();
  $collection->add_range($second_list, "10.10.200.0/24", 1);

  $collection->process_intersection(expand_cidr => 8);
  while (my $cidr_range = $collection->get_next_intersection_range()) {
    print "$cidr_range\n"; # prints 10.10.200.0/24
  }

  $collection->remove_list($second_list);

  $collection->process_intersection(expand_cidr => 8);
  while (my $cidr_range = $collection->get_next_intersection_range()) {
    print "$cidr_range\n"; # prints 10.10.0.0/16
  }

=head1 DESCRIPTION

  This module accepts various formats of IPv4 ranges, converts non-CIDR
  ranges to CIDR, and produces the intersection of CIDR ranges across
  all the lists in the collection.

  Net::CIDR::Compare was designed to handle large IPv4 lists and compute
  the intersection of these lists in a memory-efficient and speedy way.
  The intersection code is C code and Perl-wrapped using XS.  You will
  need a C compiler to install this code.

  Although the main driver for this module's creation is to find the
  intersection across several lists, this module can also be used with just
  a single list to convert non-CIDR range formats to CIDR and merge ranges
  quickly.

  Net::CIDR::Compare also requires Net::CIDR and Net::Netmask for some
  of the range format conversions (e.g. converting 10.0.0.* to 10.0.0.0/24).

=head1 CONSTRUCTING

  Net::CIDR::Compare objects are created with one optional parameter,
  print_errors.  Errors are always stored in $collection->{error} (from
  above example).  If print_errors is set (default yes) then errors
  are also printed to STDERR.

  $collection = Net::CIDR::Compare->new(print_errors => 1)

=head1 METHODS/FUNCTIONS

=over 25

=item ->B<new_list>()

  Creates a new list (C binary tree).  Returns a list pointer.

=item ->B<add_range>($list, $iprange, $skip_check)

  Adds an IP range to the list specified. If the $skip_check parameter is
  set (default no), the range is assumed to be CIDR and no validation checks
  are run.  This greatly improves performance, but if an invalid range is
  passed the result is unknown.

  Non-CIDR formats are silently converted to CIDR unless $skip_check is set.
  Accepted IP range formats:
  CIDR: 1.1.1.0/24
  Wildcard: 1.1.1.*
  Start-End Pair: 1.1.1.0-1.1.1.255
  Bracket Octet Range: 1.1.1.[0-255]


=item ->B<process_intersection>(expand_cidr => 8)

  Finds the intersection across all lists in the collection.  Returns nothing.

  An optional parameter, expand_cidr, sets the minimum CIDR value.  For example,
  setting this parameter to 32 would produce single IP results.  The default is
  0, which produces the smallest CIDR value (largest network size) results.

=item ->B<get_next_intersection_range>()

  Returns the next CIDR range in the intersection.

=item ->B<remove_list>($list)

  Removes a list from the collection.

=back

=head1 LICENSE  

  Sections of this code were obtained from a C program called cidr-convert
  which can be found on numerous sites.  The sourcecode claimed to be of 
  "the public domain."  This code is also part of the public domain.

  Please send feedback to grjones@gmail.com.
