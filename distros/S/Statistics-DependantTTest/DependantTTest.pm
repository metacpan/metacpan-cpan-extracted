package Statistics::DependantTTest;
use strict;
use Carp;
use vars qw($VERSION);
use Statistics::PointEstimation;
no strict 'refs';
$VERSION='0.03';

##############
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self= {};

    $self->{sample_data}  = undef;
    $self->{s}            = undef;



    bless($self,$class);
    return $self;
}
##############

##############
sub load_data {
    my $self = shift;
    my $sample_name = shift;

    my (@sample_data)=@_;

    my $s= new Statistics::PointEstimation;

    $s->add_data(\@sample_data);

    $self->{sample_data}->{$sample_name}=\@sample_data;
    $self->{s}->{$sample_name}=$s;

    return $self;
} # end sub load_data
##############

##############
sub perform_t_test {
    my $self=shift;
    my $first_sample_name = shift;
    my $second_sample_name = shift;
    my $s1=$self->{s}->{$first_sample_name};
    my $s2=$self->{s}->{$second_sample_name};


    if(@{$self->{sample_data}->{$first_sample_name}} != @{$self->{sample_data}->{$second_sample_name}})
    {
	croak "The two results sets are of different length.\n For the paired T-test, the two results must be from two identical sets of subjects tested in a reference and test condition.\n";
    }

    my $s = new Statistics::PointEstimation;

    my @sample_difference;

    my $count=0;
    while ($count < @{$self->{sample_data}->{$first_sample_name}})
    {
	$sample_difference[$count] = ${$self->{sample_data}->{$first_sample_name}}[$count] - ${$self->{sample_data}->{$second_sample_name}}[$count];
        $count++;
    } # end while

    $s->add_data(\@sample_difference);

    my $t_value = $s->t_statistic();

    my $deg_freedom = scalar @{$self->{sample_data}->{$first_sample_name}} - 1;

    return ($t_value, $deg_freedom );
} # end sub perform_t_test
##############


1;
__END__

=head1 NAME

 Statistics::DependantTTest - Perl module to perform Student's dependant or paired T-test on 2 paired samples.

=head1 SYNOPSIS

use Statistics::DependantTTest;
use Statistics::Distributions;

my @before_values=('5','5','6','7','7');
my @after_values=('5','6','6.5','6.5','7.5');

my $t_test = new DependantTTest;
$t_test->load_data('before',@before_values);
$t_test->load_data('after',@after_values);
my ($t_value,$deg_freedom) = $t_test->perform_t_test('before','after');
my ($p_value) = Statistics::Distributions::tprob ($deg_freedom,$t_value);

=head1 DESCRIPTION

This is the statistical T-Test module to compare 2 paired data sets. It takes 2 arrays of values and will return the t value and degrees of freedom in order to test the null hypothesis.
The t values and degrees of freedom may be correlated to a p value using the Statistics::Distributions module.

=head1 AUTHOR

Martin Lee, Star Technology Group (mlee@startechgroup.co.uk)

=head1 SEE ALSO 

Statistics::Distributions Statistics::TTest

=cut
