package Statistics::LogRank;

$VERSION = '0.03';

use strict;
use Carp;
use Statistics::Distributions;

##############
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self= {};

    bless($self,$class);
    return $self;
}
##############

##############
sub load_data {
    my $self = shift;
    my $sample_name = shift;

    my (@sample_data)=@_;

    $self->{sample_data}->{$sample_name}=\@sample_data;

    return $self;
} # end sub load_data
##############

##############
sub perform_log_rank_test {
    my $self=shift;

    my ($first_survive_name,$first_fail_name,$second_survive_name,$second_fail_name)=@_;

    my (@e,@d,@v);
    my ($N1,$D,$N2,$N);

    my $count=0;
    while ($count < @{$self->{sample_data}->{$first_survive_name}})
    {
	$N1 = ${$self->{sample_data}->{$first_survive_name}}[$count];

        $D = ${$self->{sample_data}->{$first_fail_name}}[$count] + ${$self->{sample_data}->{$second_fail_name}}[$count];

        $N2 = ${$self->{sample_data}->{$second_survive_name}}[$count];

        $N = $N1 + $N2;

        if ($N1 + $N2 == 0) {$e[$count]=0;}
        else {$e[$count] =  $N1 * $D / ( $N1 + $N2);}
        $d[$count] = ${$self->{sample_data}->{$first_fail_name}}[$count] - $e[$count];
        if (($N**2 * ($N-1))==0) {$v[$count]=0;}
        else {$v[$count] = ($N1 * $N2 * $D *($N - $D)) / ($N**2 * ($N-1));}

	$count++;
    } # end while


my $total_e=0;
my $total_d=0;
my $total_v=0;

    my $count=0;
    while ($count < @{$self->{sample_data}->{$first_survive_name}})
    {
	$total_e += $e[$count];
	$total_d += $d[$count];
	$total_v += $v[$count];
	$count++
    }

if ($total_v ==0) {$total_v = 0.000000000001;}

my $log_rank_statistic = $total_d**2 / $total_v;
my $chi_prob=Statistics::Distributions::chisqrprob (1,$log_rank_statistic);

return ($log_rank_statistic,$chi_prob);
} # end sub perform_log_rank_test
##############
1;

__END__

=head1 NAME

Statistics::LogRank - Perl module to perform the log rank test (also know as the Mantel-Haenszel or Mantel-Cox test) on survival data.

=head1 SYNOPSIS

    use Statistics::LogRank;

    @group_1_survival = (99,98,95,90,90,87);
    @group_1_deaths   = ( 1, 0, 3, 4, 0, 3);

    @group_2_survival = (100,97,93,90,88,82);
    @group_2_deaths   = (  0, 2, 4, 1, 2, 6);

    my $log_rank = new LogRank;
    $log_rank->load_data('group 1 survs',@group_1_survival);
    $log_rank->load_data('group 1 deaths',@group_1_deaths);
    $log_rank->load_data('group 2 survs',@group_2_survival);
    $log_rank->load_data('group 2 deaths',@group_2_deaths);

    my ($log_rank_stat,$p_value) = $log_rank->perform_log_rank_test('group 1 survs','group 1 deaths','group 2 survs','group 2 deaths');

    print "log rank statistic for test is $log_rank_stat\n";
    print "p value for test is $p_value\n";

=head1 DESCRIPTION

This module performs the log rank statistical test on survival data. The log rank test is also known as the Mantel-Cox test and the Mantel-Haenszel test.
It takes 2 groups of survival and death data (we separate the two to cope with censure, subjects that drop out of the study before completion) and compares if the two groups are identical.

=head1 AUTHOR

Martin Lee, Star Technology Group (mlee@startechgroup.co.uk)

=cut
