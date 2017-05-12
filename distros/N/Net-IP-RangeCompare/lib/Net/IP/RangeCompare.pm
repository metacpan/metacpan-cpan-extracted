
package Net::IP::RangeCompare;
use strict;
use Data::Dumper;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number blessed);
use vars qw($error $VERSION @ISA @EXPORT_OK %EXPORT_TAGS %HELPER);
use Data::Range::Compare qw(HELPER_CB 
         key_helper
         key_start
         key_end
         key_generated
         key_missing
         key_data
         add_one
         sub_one
         cmp_values
         sort_largest_range_end_first
         sort_largest_range_start_first
         sort_smallest_range_start_first
         sort_smallest_range_end_first
         sort_in_consolidate_order
         sort_in_presentation_order
);
use Data::IPV4::Range::Parse qw(

        ALL_BITS
        MAX_CIDR
        MIN_CIDR
        int_to_ip
        ip_to_int
        sort_quad
        sort_notations
        broadcast_int
        base_int
        size_from_mask
        hostmask
        cidr_to_int
        parse_ipv4_cidr
        parse_ipv4_range
        parse_ipv4_ip
        auto_parse_ipv4_range

);

use constant key_start_ip =>key_start;
use constant key_end_ip =>key_end;

%HELPER=HELPER_CB;

$VERSION=4.025;
use overload
  '""' => \&notation
  ,'fallback' => 1;


require Exporter;
@ISA=qw(Exporter Data::Range::Compare );

@EXPORT_OK=qw(
  hostmask
  cidr_to_int
  ip_to_int
  int_to_ip
  size_from_mask
  base_int
  broadcast_int
  cmp_int
  sort_quad
  sort_notations
  add_one
  sub_one

  sort_ranges 
  sort_largest_first_int_first
  sort_smallest_last_int_first
  sort_largest_last_int_first 
  sort_smallest_first_int_first

  get_overlapping_range
  get_common_range
  grep_overlap
  grep_non_overlap

  consolidate_ranges
  range_start_end_fill
  fill_missing_ranges
  range_compare
  compare_row
  range_compare_force_cidr
  );

%EXPORT_TAGS = (
  ALL=>\@EXPORT_OK
  ,HELPER=>[qw(
    hostmask
    cidr_to_int
    ip_to_int
    int_to_ip
    sort_quad
  size_from_mask
  base_int
  broadcast_int
  cmp_int
  sort_notations
  add_one
  sub_one
  )]
  ,SORT=>[qw(
    sort_ranges 
    sort_largest_first_int_first
    sort_smallest_last_int_first
    sort_largest_last_int_first 
    sort_smallest_first_int_first
  )]
  ,OVERLAP=>[qw(
    get_overlapping_range
    get_common_range
    grep_overlap
    grep_non_overlap
  )]
  ,PROCESS=>[qw(
    consolidate_ranges
    range_start_end_fill
    fill_missing_ranges
    range_compare
    compare_row
    range_compare_force_cidr
  )]
);

## compatibilty stuffs
*sort_ranges=\&sort_in_consolidate_order;
*sort_largest_first_int_first=\&sort_largest_range_start_first;
*sort_smallest_last_int_first=\&sort_smallest_range_end_first;
*sort_largest_last_int_first =\&sort_largest_range_end_first;
*sort_smallest_first_int_first=\&sort_smallest_range_start_first;

sub new {
  my ($s,$start,$end,@args)=@_;
  return undef unless looks_like_number $start;
  return undef unless looks_like_number $end;
  return undef if $start>$end;
  $s->SUPER::new(\%HELPER,$start,$end,@args);
}

sub parse_new_range {
  my ($s,@args)=@_;
  my $string;
  if($#args >0) { 
    $string=join ' - ',@args;
  } else {
    return undef unless defined($args[0]);
    $string=$args[0];
    my $class=blessed($string);
    if(ref($string)) {
      return $string if $class and $class eq 'Net::IP::RangeCompare';
      if($class) {
        $string .='';
        return undef unless $string=~ m/
          ^
          \d(\.\d{1,3}){0,3}
	    \s*[\/-]\s*
          \d(\.\d{1,3}){0,3}
   	  $
        /x;
      } else {
        return undef;
      }
    }
  }
  my ($start,$end)=auto_parse_ipv4_range($string);
  return undef unless looks_like_number($end);
  $s->new($start,$end);
}
*new_from_ip=\&parse_new_range;
*new_from_range=\&parse_new_range;
*new_from_cidr=\&parse_new_range;

##########################################################
#
# OO Stubs

sub first_int () { $_[0]->[key_start_ip] }
sub last_int () { $_[0]->[key_end_ip] }
sub first_ip () { int_to_ip($_[0]->[key_start_ip]) }
sub last_ip () { int_to_ip($_[0]->[key_end_ip]) }
sub missing () {$_[0]->[key_missing] }
sub generated () {$_[0]->[key_generated] }
sub error () { $error }
sub size () { 1 + $_[0]->last_int - $_[0]->first_int }

sub data () {
  my ($s)=@_;
  # always return the data ref if it exists
  return $s->[key_data] if ref($s->[key_data]);
  $s->[key_data]={};
  $s->[key_data]
}

sub notation {
  join ' - ' 
    ,int_to_ip($_[0]->first_int) 
    ,int_to_ip($_[0]->last_int)
}

sub get_cidr_notation () {
  my ($s)=@_;
  my $n=$s;
  my $return_ref=[];
  my ($range,$cidr);
  while($n) {
    ($range,$cidr,$n)=$n->get_first_cidr;
    push @$return_ref,$cidr;
  }
  join(', ',@$return_ref);
}

sub overlap ($) {
  my ($range_a,$range_b)=@_;
  my $class=blessed $range_a;
  $range_b=$class->parse_new_range($range_b);

  # return true if range_b's start range is contained by range_a
  return 1 if 
      $range_a->cmp_first_int($range_b)!=1
        &&
      $range_a->cmp_last_int($range_b)!=-1;

  # return true if range_b's end range is contained by range_a
  return 1 if 
      #$range_a->first_int <=$range_b->last_int 
      cmp_int($range_a->first_int,$range_b->last_int )!=1
        &&
      #$range_a->last_int >=$range_b->last_int;
      cmp_int($range_a->last_int,$range_b->last_int)!=-1;

  return 1 if 
      #$range_b->first_int <=$range_a->first_int 
      $range_b->cmp_first_int($range_a)!=1
        &&
      #$range_b->last_int >=$range_a->first_int;
      $range_b->cmp_last_int($range_a)!=-1;

  # return true if range_b's end range is contained by range_a
  return 1 if 
      #$range_b->first_int <=$range_a->last_int 
      cmp_int($range_b->first_int,$range_a->last_int )!=1
        &&
      #$range_b->last_int >=$range_a->last_int;
      cmp_int($range_b->last_int,$range_a->last_int)!=-1;

  # return undef by default
  undef
}

sub next_first_int () { add_one($_[0]->last_int)  }
sub previous_last_int () { sub_one($_[0]->first_int)  }
sub get_first_cidr () {
  my ($s)=@_;
  my $class=blessed $s;
  my $first_cidr;
  my $output_cidr;
  for(my $cidr=MAX_CIDR;$cidr>-1;--$cidr) {
    $output_cidr=MAX_CIDR - $cidr;
    my $mask=cidr_to_int($output_cidr);

    my $hostmask=hostmask($mask);
    my $size=size_from_mask($mask);

    next if $s->mod_first_int($size);


    my $last_int=$s->first_int + $hostmask;
    next if cmp_int($last_int,$s->last_int)==1;

    $first_cidr=$class->new($s->first_int,$last_int);

    last;
  }
  my $cidr_string=join('/',int_to_ip($first_cidr->first_int),$output_cidr);

  if($first_cidr->cmp_last_int($s)==0) {
    return ( $first_cidr ,$cidr_string);
  } else {
    return ( 
      $first_cidr 
      ,$cidr_string
      ,$class->new(
        $first_cidr->next_first_int
        ,$s->last_int
      )
    );
  }

}

sub is_cidr () {
  my ($s)=@_;
  my ($range,$cidr,$next)=$s->get_first_cidr;
  my $is_cidr=defined($next) ? 0 : 1;
  $is_cidr
}

sub is_range () {
  my ($s)=@_;
  my ($range,$cidr,$next)=$s->get_first_cidr;
  my $is_range=defined($next) ? 1 : 0;
  $is_range
}

sub nth ($) {
	my ($s,$offset)=@_;
	my $int=$s->first_int + $offset;
	return undef if cmp_int($int,$s->last_int)==1;
	int_to_ip($int);
}

sub _internal_ip_list_func ($) {
  my ($s,$mode)=@_;
  my $next=$s;
  my @list;
  my $ip;
  my $cidr;
  while($next) {
    ($ip,$cidr,$next)=$next->get_first_cidr;
    if($mode eq 'first_int') {
      push @list,$ip->first_int;
    } elsif($mode eq 'first_ip') {
      push @list,$ip->first_ip;
    } elsif($mode eq 'last_ip') {
      push @list,$ip->last_ip;
    } elsif($mode eq 'last_int') {
      push @list,$ip->last_int;
    } elsif($mode eq 'netmask_int') {
      my ($cidr_int)=($cidr=~ /(\d+)$/);
      push @list,cidr_to_int($cidr_int);
    } elsif($mode eq 'netmask') {
      my ($cidr_int)=($cidr=~ /(\d+)$/);
      push @list,int_to_ip(cidr_to_int($cidr_int));
    }
  }
  @list;
}

sub netmask_int_list { $_[0]->_internal_ip_list_func('netmask_int') }
sub netmask_list { $_[0]->_internal_ip_list_func('netmask') }
sub base_list_int () { $_[0]->_internal_ip_list_func('first_int') }
sub base_list_ip () { $_[0]->_internal_ip_list_func('first_ip') }
sub broadcast_list_int () { $_[0]->_internal_ip_list_func('last_int') }
sub broadcast_list_ip () { $_[0]->_internal_ip_list_func('last_ip') }

sub enumerate {
  my ($s,$cidr)=@_;
  $cidr=MAX_CIDR unless $cidr;
  my $mask=cidr_to_int($cidr);
  my $hostmask=hostmask($mask);
  my $n=$s;
  my $class=blessed $s;
  sub {
    return undef unless $n;
    #my $cidr_end=($n->first_int & $mask) + $hostmask;
    my $cidr_end=broadcast_int($n->first_int , $mask);
    my $return_ref;
    if(cmp_int($cidr_end,$n->last_int)!=-1) {
      $return_ref=$n;
      $n=undef;
    } else {
      $return_ref=$class->new(
        $n->first_int
        ,$cidr_end
      );
      $n=$class->new(
        $return_ref->next_first_int
        ,$n->last_int
      );
    }
    $return_ref;
  }
}

sub enumerate_size {
  my ($s,$inc)=@_;
  my $class=blessed $s;
  $inc=1 unless $inc;
  my $done;
  sub {
    return undef if $done;
    my $first=$s->first_int;
    my $next=$first + $inc;
    my $last;
    if(cmp_int($s->last_int,$next)!=-1) {
      $last=$next;
    } else {
      $last=$s->last_int;
    }
    my $new_range=$class->new($first,$last);
    $done=1 if $s->cmp_last_int($new_range)==0;
    $s=$class->new($new_range->next_first_int,$s->last_int);
    $new_range;
  }
}

sub cmp_first_int($) {
  my ($s,$cmp)=@_;
  cmp_int($s->first_int,$cmp->first_int)
}

sub cmp_last_int($) {
  my ($s,$cmp)=@_;
  cmp_int($s->last_int,$cmp->last_int)
}

sub mod_first_int ($) { $_[0]->first_int % $_[1] }

*cmp_int=\&cmp_values;

sub get_common_range {
  shift if $_[0] eq 'Net::IP::RangeCompare';
  shift if $_[0] eq \%HELPER;
  my $ranges=shift;
    croak 'empty range reference' if $#$ranges==-1;
  my $range=Net::IP::RangeCompare->SUPER::get_common_range(\%HELPER,$ranges);
  return undef if cmp_values($range->first_int,$range->last_int)==1;
  $range;
}

sub grep_non_overlap { 
  my ($range,$list)=@_;
  my $result=[];
  my $cmp=Net::IP::RangeCompare->parse_new_range($range);
  return $result unless defined($cmp);
  @$result=(grep { 
     my $range=Net::IP::RangeCompare->parse_new_range($_);
     defined($range) ? !$cmp->overlap($range) : 0
    } @$list);
  $result;
}
sub grep_overlap { 
  my ($range,$list)=@_;
  my $result=[];
  my $cmp=Net::IP::RangeCompare->parse_new_range($range);
  return $result unless defined($cmp);
  @$result=(grep { 
     my $range=Net::IP::RangeCompare->parse_new_range($_);
     defined($range) ? $cmp->overlap($range) : 0
    } @$list);
  $result;
}

sub get_overlapping_range {
  shift if $_[0] eq 'Net::IP::RangeCompare';
  shift if $_[0] eq \%HELPER;
  Net::IP::RangeCompare->SUPER::get_overlapping_range(\%HELPER,@_);
}

sub consolidate_ranges {
  shift if $_[0] eq 'Net::IP::RangeCompare';
  shift if $_[0] eq \%HELPER;
  Net::IP::RangeCompare->SUPER::consolidate_ranges(\%HELPER,@_)
}

sub fill_missing_ranges {
  shift if $_[0] eq 'Net::IP::RangeCompare';
  shift if $_[0] eq \%HELPER;
  Net::IP::RangeCompare->SUPER::fill_missing_ranges(\%HELPER,@_);
}

sub range_start_end_fill { 
  shift if $_[0] eq 'Net::IP::RangeCompare';
  shift if $_[0] eq \%HELPER;
  Net::IP::RangeCompare->SUPER::range_start_end_fill(\%HELPER,@_);
}

sub range_compare { 
  shift if $_[0] eq 'Net::IP::RangeCompare';
  shift if $_[0] eq \%HELPER;
  my $sub=Net::IP::RangeCompare->SUPER::range_compare(\%HELPER,@_) ;
  sub {
    my @row=$sub->();
    return () unless @row;
    return (get_common_range(\@row),@row);
  }
}

sub range_compare_force_cidr {
  my $sub=range_compare(@_);

  my ($common,@row)=$sub->();
  my ($cidr,$notation,$next)=$common->get_first_cidr;
  sub {
    return () unless @row;
    my @return_row=($cidr,$notation,@row);
    if($next) {
      ($cidr,$notation,$next)=$next->get_first_cidr;
    } else {
      ($common,@row)=$sub->();
      if(@row) {
        ($cidr,$notation,$next)=$common->get_first_cidr 
      } else {
        $next=undef;
      }
    }
    @return_row
  }
}

sub compare_row  {
  shift if $_[0] eq 'Net::IP::RangeCompare';
  shift if $_[0] eq \%HELPER;
  my ($ref,$row, $cols)=@_;
  return Net::IP::RangeCompare->SUPER::init_compare_row(\%HELPER,$ref) 
    unless defined($cols);
  Net::IP::RangeCompare->SUPER::compare_row(\%HELPER,$ref,$row, $cols);
}

=pod

=back

=cut

############################################
#
# End of the package
1;

############################################
#
# Helper package
package Net::IP::RangeCompare::Simple;

use strict;
use warnings;
use Carp qw(croak);
use constant key_sources=>0;
use constant key_columns=>1;
use constant key_compare=>2;
use constant key_changed=>3;

sub new  {
  my ($class)=@_;
  my $ref=[];
  $ref->[key_sources]={};
  $ref->[key_changed]={};
  $ref->[key_columns]=[];
  $ref->[key_compare]=undef;

  bless $ref,$class;
}


sub add_range ($$) {
  my ($s,$key,$range)=@_;
  croak "Key is not defined" unless defined($key);
  croak "Range is not defined" unless defined($range);

  my $obj=Net::IP::RangeCompare->parse_new_range($range);
  croak "Could not parse: $range" unless $obj;

  my $list;

  if(exists $s->[key_sources]->{$key}) {
    $list=$s->[key_sources]->{$key};
  } else {
    $s->[key_sources]->{$key}=[];
    $list=$s->[key_sources]->{$key};
  }
  push @$list,$obj;
  $s->[key_changed]->{$key}=1;
  $obj
}

sub get_ranges_by_key ($) {
  my ($s,$key)=@_;
  croak "key was not defined" unless defined($key);

  return [@{$s->[key_sources]->{$key}}]
    if exists $s->[key_sources]->{$key};
  
  return undef;
}

sub compare_ranges {
  my ($s,@keys)=@_;
  my %exclude=map { ($_,1) } @keys;
  croak "no ranges defined" unless keys %{$s->[key_sources]};
  
  my $columns=$s->[key_columns];
  @$columns=();
  my $compare_ref=[];
  while(my ($key,$ranges)=each %{$s->[key_sources]}) {
    next if exists $exclude{$key};
    push @$columns,$key;
    $s->[key_sources]->{$key}=Net::IP::RangeCompare::consolidate_ranges($ranges)
     if $s->[key_changed]->{$key};
    $s->[key_changed]->{$key}=0;
    push @$compare_ref,$s->[key_sources]->{$key};

  }
  croak "no ranges defined" if $#$columns==-1;

  $s->[key_compare]=Net::IP::RangeCompare::range_compare(
    $compare_ref
    ,consolidate_ranges=>0
  );

  1
}

sub get_row () {
  my ($s)=@_;

  croak "no ranges defined" unless keys %{$s->[key_sources]};

  #make sure we have something to compare
  $s->compare_ranges
    unless  $s->[key_compare];
  my %row;
  my (@cols)=$s->[key_compare]->();
  return () unless @cols;
  my $common;

  ($common,@row{@{$s->[key_columns]}})=@cols;

  $common,%row

}

sub get_keys () {
  keys %{$_[0]->[key_sources]}
}

############################################
#
# End of the package
1;

__END__
