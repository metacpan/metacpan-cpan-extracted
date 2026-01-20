package Schedule::Activity::Attribute::Report;

use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;
use Ref::Util qw/is_ref/;

our $VERSION='0.3.0';

sub new {
	my ($ref,%schedule)=@_;
	my $class=is_ref($ref)||$ref;
	my %self=%schedule; # shallow
	return bless(\%self,$class);
}

sub gridreport {
	my ($self,%opt)=@_;
	$opt{steps}//=10;
	my $yidx=1; if($opt{values} eq 'avg') { $yidx=2 };
	my $tmmin=(        sort {$a<=>$b} map {$$_{xy}[0][0]} values %{$$self{attributes}})[0];
	my $tmmax=(reverse sort {$a<=>$b} map {$$_{xy}[-1][0]} values %{$$self{attributes}})[0];
	my $tmstep=($tmmax-$tmmin)/$opt{steps};
	my @times=map {$tmmin+$tmstep*$_} (0..$opt{steps});
	my @res;
	if($opt{header}) { push @res,[map {sprintf($opt{fmt},$_)} @times]; if($opt{names}) { push @{$res[-1]},'Attribute' } }
	foreach my $name (sort keys %{$$self{attributes}}) {
		my @row;
		my $attr=$$self{attributes}{$name}{xy};
		my ($i,$y)=(-1);
		foreach my $tm (@times) {
			while(($i<$#$attr)&&($tm>=$$attr[$i+1][0])) { $i++ }
			if($i<0)           { $y=0 }
			elsif($i>=$#$attr) { $y=$$attr[$i][$yidx] }
			elsif($i==0)       { $y=$$attr[0][$yidx] }
			else {
				my $p=($tm-$$attr[$i][0])/($$attr[$i+1][0]-$$attr[$i][0]);
				$y=(1-$p)*$$attr[$i][$yidx]+$p*$$attr[$i+1][$yidx];
			}
			push @row,sprintf($opt{fmt},$y);
		}
		if($opt{names}) { push @row,$name }
		push @res,\@row;
	}
	return @res;
}

sub summaryreport {
	my ($self,%opt)=@_;
	my $yidx=1; if($opt{values} eq 'avg') { $yidx=2 };
	my @res;
	if($opt{header}) { push @res,[$opt{values} eq 'avg'?'Average':'Value']; if($opt{names}) { push @{$res[-1]},'Attribute' } }
	foreach my $name (sort keys %{$$self{attributes}}) {
		push @res,[sprintf($opt{fmt},$$self{attributes}{$name}{xy}[-1][$yidx])];
		if($opt{names}) { push @{$res[-1]},$name }
	}
	return @res;
}

sub rawhash {
	my ($value,@rows)=@_;
	my %res;
	my @times=@{shift @rows}; pop(@times);
	foreach my $row (@rows) {
		my $name=pop(@$row);
		foreach my $i (0..$#times) {
			my $tm=$times[$i];
			my $v=$$row[$i];
			$res{$name}{$value}{$tm}=$v;
		}
	}
	return %res;
}

sub rawplot {
	my ($sep,@rows)=@_;
	my @times=@{shift @rows}; pop(@times);
	my $res=join($sep,'Time',map {$$_[1+$#times]//''} @rows)."\n";
	foreach my $i (0..$#times) { $res.=join($sep,$times[$i],map {$$_[$i]//''} @rows)."\n" }
	return $res;
}

sub report {
	my ($self,%opt)=@_;
	%opt=(
		type  =>'',
		values=>'avg',
		header=>1,
		names =>1,
		fmt   =>'%0.4g',
		sep   =>"\t",
		format=>'text',
		%opt
	);
	if($opt{format}=~/^hash/) { $opt{header}=$opt{names}=1 }
	#
	my @rows; # will use dispatch later
	if   ($opt{type} eq 'grid')    { @rows=$self->gridreport(%opt) }
	elsif($opt{type} eq 'summary') { @rows=$self->summaryreport(%opt) }
	#
	if   ($opt{format} eq 'hash')  { return +{rawhash($opt{values},@rows)} }
	elsif($opt{format} eq 'table') { return \@rows }
	elsif($opt{format} eq 'plot')  { return rawplot($opt{sep},@rows) }
	else                           { return join("\n",map {join($opt{sep},@$_)} @rows) }
}

1;

__END__

=pod

=head1 NAME

Schedule::Activity::Attribute::Report - Helpers to construct attribute reports

=head1 SYNOPSIS

  my $reporter=Schedule::Activity::Attribute::Report->new(%schedule);
  print $reporter->report(type=>'grid',values=>'avg',steps=>10,header=>1,names=>1,fmt=>'%0.4g',sep=>"\t");

=head1 DESCRIPTION

A collection of functions to convert attribute reporting history into useful output.  Reports may include overall values, time-based grids, activity-based grids, and support different output formats.

Note:  Not every option is currently supported.

=head1 GENERAL OPTIONS

Values are output with the numeric format specified in C<fmt>, default C<%0.4g>.  Columns are separated by C<sep>, default tab.

Pass C<names=1> to include a column for the attribute names.  This option permits concatenating columns from multiple grids when set to zero.  This is on by default.

Pass C<header=1> to include a header row.  This option permits concatenating rows from multiple grids when set to zero.  This is on by default.

=head1 GRIDS

Report grids can be generated with C<type=grid>.  The C<values> are either 'avg' for averages, or 'y' for the raw attribute values; each is determined via linear interpolation between attribute history points.

=head2 Columns

Pass C<steps=10> or any number to specify the number of columns for a time-based grid between the start and maximum time values in the schedule.

=head1 SUMMARY VALUES

Specifying C<type=summary> gives only two-column output of the final 'avg' or 'y' value for the attribute at the end of the schedule.

=head1 FORMATS

Passing C<format=text> will produce newline-separated rows as a string.  This is the default.

Passing C<format=table> will return an array reference containing the formatted table entries.

Passing C<format=hash> will return a hash reference with entries C<attribute{values}{time}=value>.  The C<attribute> is the name of the attribute.  The nested key will be either "avg" or "y" as selected by the C<values> parameter.  The time/value key-value will be equivalent to the table values from the report, not the full attribute history.

Passing C<format=plot> will return multi-column time series data with the labels in the first row (if enabled), using C<sep> as the column separator, suitable for use with plotting tools.  For example, with gnuplot:

  plot for [n=2:3] 'attributes.dat' using 1:n with linespoints title columnheader(n)

=cut
