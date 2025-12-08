package Schedule::Activity::NodeFilter;

use strict;
use warnings;
use Ref::Util qw/is_plain_hashref/;

our $VERSION='0.2.5';

my %property=map {$_=>undef} qw/f attr op value boolean filters/;
my %matcher=(
	boolean=>\&matchBoolean,
	elapsed=>\&matchElapsed,
	value  =>\&matchValue,
	avg    =>\&matchValue,
);

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=map {$_=>$opt{$_}} grep {exists($opt{$_})} keys(%property);
	if($self{attr})    { $self{f}//='value' }
	if($self{boolean}) { $self{f}='boolean'; $self{boolean}=lc($self{boolean}) }
	if(!defined($matcher{$self{f}})) { die "Invalid filter function $self{f}" }
	return bless(\%self,$class);
}

sub matches {
	my ($self,$tm,%attributes)=@_;
	return &{$matcher{$$self{f}}}($self,$tm,%attributes);
}

sub matchBoolean {
	my ($self,$tm,%attributes)=@_;
	if($$self{boolean} eq 'and') {
		my $res=1;
		foreach my $filter (@{$$self{filters}}) {
			if(is_plain_hashref($filter)) { $res&&=__PACKAGE__->new(%$filter)->matches($tm,%attributes) }
			else                          { $res&&=$filter->matches($tm,%attributes) }
			if(!$res) { return 0 }
		}
		return $res;
	}
	if($$self{boolean} eq 'or') {
		my $res=0;
		foreach my $filter (@{$$self{filters}}) {
			if(is_plain_hashref($filter)) { $res||=__PACKAGE__->new(%$filter)->matches($tm,%attributes) }
			else                          { $res||=$filter->matches($tm,%attributes) }
			if($res) { return 1 }
		}
		return $res;
	}
	if($$self{boolean} eq 'nand') {
		my $res=0;
		foreach my $filter (@{$$self{filters}}) {
			if(is_plain_hashref($filter)) { $res||=!__PACKAGE__->new(%$filter)->matches($tm,%attributes) }
			else                          { $res||=!$filter->matches($tm,%attributes) }
			if($res) { return 1 }
		}
		return $res;
	}
	return 0;
}

sub matchElapsed {
	my ($self,$tm,%attributes)=@_;
	my $v=$attributes{$$self{attr}}//{};
	$v=$$v{tmmax};
	if(defined($v)) {
		$v=$tm-$v;
		return __PACKAGE__
			->new(f=>'value',attr=>'timecheck',op=>$$self{op},value=>$$self{value})
			->matches(undef,timecheck=>{value=>$v});
	}
	return 0;
}

sub matchValue {
	my ($self,$tm,%attributes)=@_;
	my $v=$attributes{$$self{attr}}//{};
	if   ($$self{f} eq 'value') { $v=$$v{value} }
	elsif($$self{f} eq 'avg')   { $v=$$v{avg} }
	else { die "Not yet available $$self{f}" }
	if(defined($$self{value})) {
		if(!defined($v)) { return 0 }
		if($$self{op} eq 'eq') { return $v==$$self{value} }
		if($$self{op} eq 'ne') { return $v!=$$self{value} }
		if($$self{op} eq 'lt') { return $v< $$self{value} }
		if($$self{op} eq 'le') { return $v<=$$self{value} }
		if($$self{op} eq 'gt') { return $v> $$self{value} }
		if($$self{op} eq 'ge') { return $v>=$$self{value} }
	}
	return 0;
}

1;

__END__

=pod

=head1 NAME

Schedule::Activity::NodeFilter - Evaluate if attributes match logical expressions

=head1 SYNOPSIS

  my $filter=Schedule::Activity::NodeFilter->new(
    f    =>'value/avg/elapsed'
    attr =>'attribute name'
    op   =>'lt/gt/le/ge/eq/ne'
    value=>number
    #
    boolean=>'and/or/nand'
    filters=>[...]
  );

  if($filter->matches($tm,%attributes)) { ... }

=head1 DESCRIPTION

TODO.

=head1 VALUE FILTERS

=head2 Attribute values

A filter that directly checks attribute values as C<attribute op value> can be created with

  f    =>'value',
  attr =>'name',
  op   =>'lt/gt/le/ge/eq/ne',
  value=>number,

It is not necessary to pass C<f=value>, which is the default.  If the attribute value is undefined, the match is false.  All other operators are I<numeric> and are self explanatory.  (This might change, but currently there is no proposal/use case to support setting attributes with string values.)

=head2 Attribute averages

A filter that uses the current average value of an attribute as C<average op value> can be created with

  f    =>'avg',
  attr =>'name',
  op   =>'operator',
  value=>number,

When used from L<Schedule::Activity>, the average will be provided by the attribute as if I<no change in value> occurred between the last recorded entry and the current time.  The meaning of the average depends on the type.

=head2 Elapsed time

To control "time between actions", a filter can be used to check the elapsed time since an integer attribute was stored by evaluating C<(now-attribute time) op value> with

  f    =>'elapsed',
  attr =>'name',
  op   =>'operator'
  value=>seconds,

For any attribute, the most recent recorded event is used as the attribute time.  To record a timestamp for an integer attribute without changing its value, use C<incr=0>.

=head1 BOOLEAN EXPRESSIONS

A boolean filter supports AND, OR, and NAND expressions as follows:

  boolean=>'and/or/nand',
  filters=>[...],

The C<filters> are any list of one or more filters of any type.  That is, C<AND> is the conjunction over I<all> filters in the list (all must be true).  The C<OR> is the disjunction over all filters in the list (at least one must be true).

The Boolean NOT may be implemented as C<boolean=nand, filters=[filter]>, because the NAND operator is implemented via DeMorgan's Laws as C<!A || !B || ...>.

All operators support short-circuiting.

=cut
