package Statistics::KruskalWallis;

$VERSION = '0.01';

use strict;
use Carp;
use Statistics::Distributions;

##############
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self= {};

    $self->{sample_data}        = undef;
    $self->{rank_data}          = undef;
    $self->{no_of_sets}         = 0;
    $self->{no_of_samples}      = 0;


    bless($self,$class);
    return $self;
}
##############

##############
sub load_data {
    my $self = shift;
    my $sample_name = shift;

    my (@sample_data)=@_;

    $self->{no_of_samples}+=@sample_data;;
    $self->{no_of_sets} = $self->{no_of_sets} + 1;
    $self->{sample_data}->{$sample_name}=\@sample_data;
    $self->{rank_data}->{$sample_name}->{sum} = 0;
    $self->{rank_data}->{$sample_name}->{n}=0;

    return 1;
} # end sub load_data
##############

##############
sub perform_kruskal_wallis_test {
    my $self=shift;

    my ($sample_name,$sample_data_element,$sample_data_value);
    my ($grouped_data_ref) = $self->_group_data();
    $self->_rank_data($grouped_data_ref);
    my ($H) = $self->_calculate_H();
    my ($chi_prob)=Statistics::Distributions::chisqrprob (($self->{no_of_sets}-1),$H);

# chi_prob only valid when no_of_sets > 3
    return ($H,$chi_prob);
} # end sub
##############

##############
sub _group_data {

    my $self = shift;
    my (%grouped_data,$sample_name,$sample_data_element);

    foreach $sample_name (keys(%{$self->{sample_data}})) {
	foreach $sample_data_element (@{$self->{sample_data}->{$sample_name}}){
	    if (exists($grouped_data{$sample_data_element})) 
	    {
		push @{$grouped_data{$sample_data_element}}, $sample_name;
	    } # end if
	    else 
	    {
		$grouped_data{$sample_data_element} = [$sample_name];
	    } # end else
	} # end foreach sample_data_element
    } # end foreach sample name

    return (\%grouped_data);
} # end sub _group_data
##############

##############
sub _rank_data {

    my $self = shift;
    my $grouped_data_ref = shift;

    my $rank = 1;
    my ($sample_name,$sample_data_value);

    foreach $sample_name (keys(%{$self->{sample_data}})) {
	    $self->{rank_data}->{$sample_name}->{sum} = 0;
	    $self->{rank_data}->{$sample_name}->{n} = 0;
    } # end foreach


    foreach $sample_data_value (sort { $a <=> $b } (keys(%$grouped_data_ref))) {

	if (@{$$grouped_data_ref{$sample_data_value}} > 1) {$rank+=0.5;}

	foreach $sample_name (@{$$grouped_data_ref{$sample_data_value}}) {
	    $self->{rank_data}->{$sample_name}->{sum}+= $rank;
	    $self->{rank_data}->{$sample_name}->{n}++;
	} # end foreach
    
	$rank=int($rank+1.5);
    } # end foreach
} # end sub
##############

##############
sub _calculate_H {

    my $self = shift;
# calculate mean sum

    my $sample_name;
    my $mean_sq_sum = 0;

    foreach $sample_name (keys(%{$self->{sample_data}})) {
	$mean_sq_sum += ($self->{rank_data}->{$sample_name}->{sum}**2) / $self->{rank_data}->{$sample_name}->{n};
    } # end foreach samplename

# calculate kw statistic

    my $H = 12 / ( $self->{no_of_samples} * ($self->{no_of_samples} + 1) );
    $H = $H * $mean_sq_sum;
    $H = $H - 3 * ($self->{no_of_samples} + 1);

    return ($H);
} # end sub _calculate_H
##############

##############
sub post_hoc {

    my $self = shift;
    my $test_name = shift;
    my ($control_group_name,$test_group_name)=@_;

    my ($p_value,$q);

# one day may add further post-hoc tests
    if ($test_name eq 'Newman-Keuls') {
	my $SE = ( $self->{no_of_samples} * ($self->{no_of_samples} + 1) ) / 12;
	$SE = $SE * ( 1/$self->{rank_data}->{$control_group_name}->{n} + 1/$self->{rank_data}->{$test_group_name}->{n});
	$SE = $SE**0.5;

	my $r1 = $self->{rank_data}->{$control_group_name}->{sum} / $self->{rank_data}->{$control_group_name}->{n};
	my $r2 = $self->{rank_data}->{$test_group_name}->{sum} / $self->{rank_data}->{$test_group_name}->{n};

        $q = ( $r1 - $r2 ) / $SE;

	if ($q>2.576) {$p_value='>0.01';}
	elsif ($q>1.960) {$p_value='>0.05';}
	elsif ($q>1.645) {$p_value='>0.1';}
	else {$p_value='<0.1';}

    } # end test

    return ($q,$p_value);
} # end sub post_hoc
##############
1;

__END__

=head1 NAME

Statistics::KruskalWallis - Perl module to perform the Kruskall-Wallis test,
use to test if differences exist between 3 or more independant groups of 
unequal sizes.

Also includes the post-hoc Newman-Keuls test, to test if the differences 
between pairs of the tested group are significant.

=head1 SYNOPSIS

    use Statistics::KruskalWallis;
    use strict;

    my @group_1 = (6.4,6.8,7.2,8.3,8.4,9.1,9.4,9.7);
    my @group_2 = (2.5,3.7,4.9,5.4,5.9,8.1,8.2);
    my @group_3 = (1.3,4.1,4.9,5.2,5.5,8.2);

    my $kw = new Statistics::KruskalWallis;

    $kw->load_data('group 1',@group_1);
    $kw->load_data('group 2',@group_2);
    $kw->load_data('group 3',@group_3);

    my ($H,$p_value) = $kw->perform_kruskal_wallis_test;

   print "Kruskal Wallis statistic is $H\n";
   print "p value for test is $p_value\n";

#post hoc
   my ($q,$p) = $kw->post_hoc('Newman-Keuls','group 1','group 3');
   print "Newman-Keuls statistic for groups 1,3 is $q, p value $p\n";

   ($q,$p) = $kw->post_hoc('Newman-Keuls','group 1','group 2');
   print "Newman-Keuls statistic for groups 1,2 is $q, p value $p\n";

   ($q,$p) = $kw->post_hoc('Newman-Keuls','group 2','group 3');
   print "Newman-Keuls statistic for groups 2,3 is $q, p value $p\n";

=head1 DESCRIPTION

This module performs the Kruskal Wallis statistical test on data. 
It takes 3 or more groups of independant data of unequal size, and tests the 
null hypothesis, that the mean ranks of the groups do not differ. 

The facility to perform post-hoc tests on the groups to test differences
between pairs of groups is included. So far only the Newman-Keuls test
is included, hopefully further tests will be included.

=head1 AUTHOR

Martin Lee, Star Technology Group (mlee@startechgroup.co.uk)
copyright (c) 2003 Star Technology Group Ltd.

=cut

