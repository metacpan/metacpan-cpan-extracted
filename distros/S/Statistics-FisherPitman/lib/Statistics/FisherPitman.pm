package Statistics::FisherPitman;

use 5.008008;
use strict;
use warnings;
use Carp qw(croak);
use List::Util qw(sum);
use Statistics::Descriptive;
use vars qw($VERSION);
$VERSION = 0.034;

=pod

=head1 NAME

Statistics::FisherPitman - Randomization-based alternative to one-way independent groups ANOVA; unequal variances okay

=head1 SYNOPSIS

 use Statistics::FisherPitman 0.034;

 my @dat1 = (qw/12 12 14 15 12 11 15/);
 my @dat2 = (qw/13 14 18 19 22 21 26/);

 my $fishpit = Statistics::FisherPitman->new();
 $fishpit->load({d1 => \@dat1, d2 => \@dat2});

 # Oh, more data just came in:
 my @dat3 = (qw/11 7 7 2 19 19/);
 $fishpit->add({d3 => \@dat3});

 my $T = $fishpit->t_value();
 # now go to monte carlo to get a p for your T

 # or get a t_value and p_value in one by randomization test:
 $fishpit->p_value(resamplings => 1000)->dump(title => "A test");

=head1 DESCRIPTION

Tests for a difference between independent samples. It is commonly recommended as an alternative to the oneway independent groups ANOVA when variances are unequal, as its test-statistic, I<T>, is not dependent on an estimate of variance. As a randomization test, it is "distribution-free", with the probability of obtaining the observed value of I<T> being derived from the data themselves.

=head1 METHODS

=head2 new

 $fishpit = Statistics::FisherPitman->new()

Class constructor; expects nothing.

=cut

#-----------------------------------------------------------------------
sub new {
#-----------------------------------------------------------------------
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self= {};
    ##$self->{$_} = '' foreach qw/df_t df_e f_value chi_value p_value ss_t ss_e title/;
    bless($self, $class);
    return $self;
}

=head2 load

 $fishpit->load('aname', @data1)
 $fishpit->load('aname', \@data1)
 $fishpit->load({'aname' => \@data1, 'another_name' => \@data2})

I<Alias>: C<load_data>

Accepts either (1) a single C<name =E<gt> value> pair of a sample name, and a list (referenced or not) of data; or (2) a hash reference of named array references of data. The data are loaded into the class object by name, within a hash named C<data>, as L<Statistics::Descriptive::Full|Statistics::Descriptive> objects. So you can easily get at any descriptives for the groups you've loaded - e.g., $fishpit->{'data'}->{'aname'}->mean() - or you could get at the data again by going $fishpit->{'data'}->{'aname'}->get_data(); and so on. The names of the data are up to you.

Each call L<unload|unload>s any previous loads.

Returns the Statistics::FisherPitman object.

=cut

#-----------------------------------------------------------------------
sub load {
#-----------------------------------------------------------------------        
    my $self = shift;
    $self->unload();
    $self->add(@_);
}
*load_data = \&load; # Alias


=head2 add

 $fishpit->add('another_name', @data2)
 $fishpit->add('another_name', \@data2)
 $fishpit->add({'another_name' => \@data2})

I<Alias>: C<add_data>

Same as L<load|load> except that any previous loads are not L<unload|unload>ed.

=cut

#-----------------------------------------------------------------------
sub add {
#-----------------------------------------------------------------------        
    my $self = shift;
    
    if (ref $_[0] eq 'HASH') {
      while (my ($sample_name, $sample_data) = each %{$_[0]}) {
         if (ref $sample_data) {
              $self->{'data'}->{$sample_name} = Statistics::Descriptive::Full->new();
              $self->{'data'}->{$sample_name}->add_data(@{$sample_data});
         } 
      }
    }
    else {
       my $sample_name = shift;
       my $sample_data = ref $_[0] eq 'ARRAY' ? $_[0] : scalar (@_) ? \@_ : croak 'No list of data';
       $self->{'data'}->{$sample_name} = Statistics::Descriptive::Full->new();
       $self->{'data'}->{$sample_name}->add_data(@{$sample_data});
    }
}
*add_data = \&add; # Alias

=head2 unload

 $fishpit->unload();

Empties all cached data and calculations upon them, ensuring these will not be used for testing. This will be automatically called with each new load, but, to take care of any development, it could be good practice to call it yourself whenever switching from one dataset for testing to another.

=cut

#-----------------------------------------------------------------------        
sub unload {
#-----------------------------------------------------------------------        
    my $self = shift;
    $self->{'data'} = {};
    $self->{$_} = undef foreach qw/df_t df_e f_value chi_value p_value ss_t ss_e ms_t ms_e conf_int/;
}

=head2 t_value

 $fishpit->t_value()

Returns a Fisher-Pitman T-value for the loaded data, and lumps the value into the class object for the key I<t_value>.

I<T> is calculated as follows:

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>g</i><br>&nbsp;<i>T</i> = &nbsp;SUM&nbsp;&nbsp;<i>n</i><sub><i>i</i></sub>&nbsp;<i>x<sub><i>i</i></sub>&sup2;</i></sup><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>i</i> = 1</p>

which pertains to the I<n>umber of observations in each I<i> of I<g> samples, and

=for html <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>n</i><sub><i>i</i></sub><br>&nbsp;<i>x</i><sub><i>i</i></sub> = &nbsp;1/<i>n</i><sub><i>i</i></sub>&nbsp;SUM&nbsp;&nbsp;<i>x</i><sub><i>ij</i></sub><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i>j</i> = 1</p>

(for each I<j> observation in the I<i> sample).

=cut

#-----------------------------------------------------------------------        
sub t_value {
#-----------------------------------------------------------------------        
    my ($self, %args) = @_;
    my %data = ref $args{'data'} eq 'HASH' ? %{$args{'data'}} : ref $self->{'data'} eq 'HASH' ? %{$self->{'data'}} : croak 'No reference to a hash of data for performing ANOVA';
    my (%lens, @dat, %orig) = ();

    foreach (keys %data) {
       $lens{$_} = $data{$_}->count or croak 'Empty data sent to Fisher-Pitman test';
       $orig{$_} = [$data{$_}->get_data];
       push @dat, $data{$_}->get_data;
    }

    my $T = _get_T(\%orig);
    $self->{'t_value'} = $T;
    
    return $T;
}

=head2 p_value

 $fishpit->p_value(resamplings => 'non-negative number')

I<Alias>: test

With a positive value for I<resamplings>, the loaded data will be shuffled so many times, and the T-value calculated for each resampling. The proportion of T-values in these resamplings that are greater than I<or equal to> the T-value of the original data, as loaded, is the I<p_value> for basing significance considerations upon.

Randomization test is simply based on pooling all the data and, for each resampling, giving them a Fisher-Yates shuffle, and distributing them to so many groups, of so many sample-sizes, as in the original dataset.

The class object is fed the values for C<t_value> and C<p_value>. Confidence interval (95%) of the true proportion (p-value) is also calculated and stored as a two-element array named C<conf_int>. The method returns only itself. So you can get at these values thus:

 print "T = $fishpit->{'t_value'}, p = $fishpit->{'p_value'}\n";
 print '95% confidence interval for the proportion of Ts greater than or equal to the observed value ranges from ';
 print "$fishpit->{'conf_int'}->[0] to $fishpit->{'conf_int'}->[1].\n";

=cut
  
#-----------------------------------------------------------------------        
sub p_value {
#-----------------------------------------------------------------------        
    my ($self, %args) = @_;
    my %data = ref $args{'data'} eq 'HASH' ? %{$args{'data'}} : ref $self->{'data'} eq 'HASH' ? %{$self->{'data'}} : croak 'No reference to a hash of data for performing ANOVA';
    
    my (%lens, @dat, %orig) = ();
    foreach (keys %data) {
       $orig{$_} = [$data{$_}->get_data];
       push @dat, $data{$_}->get_data;
       $lens{$_} = $data{$_}->count or croak 'Empty data sent to Fisher-Pitman test';
    }

    my $T = _get_T(\%orig);
    $self->{'t_value'} = $T;

    my $resamplings = $args{'resamplings'} || return $self; 

    my ($n_gteq, $name, @ari, @perm, %rands) = (0);
    
    foreach (1 .. $resamplings) {
        _fy_shuffle(\@dat);
        @perm = @dat;
        foreach $name(keys %data) {
            @ari = ();
            for (1 .. $lens{$name}) {
                push @ari, shift @perm;
            }
            $rands{$name} = [@ari];
        }
        $n_gteq++ if _get_T(\%rands) >= $T;
        %rands = ();
    }
    my $p = $n_gteq / $resamplings;
    $self->{'p_value'} = $p;
    $self->{'conf_int'} = _conf_int($n_gteq, $resamplings);
    return $self;
}
*test = \&p_value; # Alias

=head2 dump

 $fishpit->dump(title => 'A test of something', conf_int => 1|0, precision_p => integer)

Prints a line to STDOUT of the form I<T = t_value, p = p_value>. Above this string, a title can also be printed, by giving a value to the optional I<title> argument. The 95% confidence interval, and the precision of the p-value(s), can also be optionally dumped, as above. Ends with a line-break, i.e., "\n".

=cut

#-----------------------------------------------------------------------        
sub dump {
#-----------------------------------------------------------------------        
    my ($self, %args) = @_;
    print "$args{'title'}\n" if $args{'title'};
    print $self->string(%args);
    print "\n";
}

=head2 string

 $fishpit->string(conf_int => 1|0, precision_p => integer)

Returns a line of the form I<T = t_value, p = p_value>, to the precision specified (if any), and, optionally, with the confidence-interval for the p-value appended.

=cut

#-----------------------------------------------------------------------        
sub string {
#-----------------------------------------------------------------------        
    my ($self, %args) = @_;
    my $str = '';
    $str .= "T = $self->{'t_value'}";
    if (defined $self->{'p_value'}) {
        $str .= ', p = ';
        $str .= $args{'precision_p'} ? sprintf('%.' . $args{'precision_p'} . 'f', $self->{'p_value'}) : $self->{'p_value'};
        if ($args{'conf_int'}) {
            $str .= " (95% CI: ";
            if ($args{'precision_p'}) {
                $str .= sprintf('%.' . $args{'precision_p'} . 'f', $self->{'conf_int'}->[0]);
                $str .= ', ';
                $str .= sprintf('%.' . $args{'precision_p'} . 'f', $self->{'conf_int'}->[1]);
            }
            else {
                $str .= join(', ', @{$self->{'conf_int'}});
            }
            $str .= ')';
        }
    }
    return $str;
}

sub _get_T {
    my ($data) = @_;
    my ($T, $xij, $count) = (0, 0);
    foreach (keys %{$data}) {
        $count = scalar(@{$data->{$_}});
        $xij = 1 / $count * sum(@{$data->{$_}});
        $T += $count * $xij**2
    }
    return $T;
}

sub _conf_int {
    my ($ng, $ns) = @_;
    my $p = $ng / $ns;
    my $i = 1.96 * sqrt($p * (1 - $p) / $ns);
    my $lo = $p - $i;
    my $hi = $p + $i;
    return [$lo, $hi];
}

sub _fy_shuffle { # fisher-yates shuffle, via Perl FAQ 4
	my ($list) = @_;
	my $i;
	for ($i = @$list; --$i; ) {
		my $j = int rand ($i+1);
		next if $i == $j;
		@$list[ $i, $j ] = @$list[ $j, $i ];
	}
}

1;
__END__

=head1 EXAMPLE

This example is taken from Berry & Mielke (2002); see C<ex/fishpit.pl> in the installation dist for implementation. The following (real) data are lead (Pb) values (in mg/kg) of soil samples from two districts in New Orleans, one from school grounds, another from surrounding streets. Was there a significant difference in lead levels between the samples? The variances were determined to be unequal, and the Fisher-Pitman test put to the question. As there were over 100 billion possible permutations of the data, a large number of resamplings was used: 10 million. 

The following shows how the test would be performed with the present module; using a smaller number of resamplings produces much the same result. A test of equality of variances is also shown.

 my $data = {
    dist1 => [qw/16.0 34.3 34.6 57.6 63.1 88.2 94.2 111.8 112.1 139.0 165.6 176.7 216.2 221.1 276.7 362.8 373.4 387.1 442.2 706.0/],
    dist2 => [qw/4.7 10.8 35.7 53.1 75.6 105.5 200.4 212.8 212.9 215.2 257.6 347.4 461.9 566.0 984.0 1040.0 1306.0 1908.0 3559.0 21679.0/],
 };

 # First test equality of variances:
 require Statistics::ANOVA;
 my $anova = Statistics::ANOVA->new();
 $anova->load_data($data);
 $anova->levene_test()->dump();
 # This prints: F(1, 38) = 4.87100593921132, p = 0.0344251996755789
 # As this suggests significantly different variances ...

 require Statistics::FisherPitman;
 my $fishpit = Statistics::FisherPitman->new();
 $fishpit->load_data($data);
 $fishpit->test(resamplings => 10000)->dump(conf_int => 1, precision_p => 3);
 # This prints, e.g.: T = 56062045.0525, p = 0.014 (95% CI: 0.011, 0.016)

Hence a difference is indicated, which can be identified from the means. The data being cached as L<Statistics::Descriptive|Statistics::Descriptive> objects (see L<load|load>), the means can be got at thus:

 print "District 1 mean = ", $fishpit->{'data'}->{'dist1'}->mean(), "\n"; # 203.935
 print "District 2 mean = ", $fishpit->{'data'}->{'dist2'}->mean(), "\n"; # 1661.78

So beware District 2, it seems. The module naturally produces the same I<T>-value as reported by Berry and Mielke, and they obtained I<p> = .0148 from their 10 million resamplings. 

Pointing to the value of the test, Berry and Mielke also showed that common alternatives for the unequal variances situation - such as the pooled variance I<t>-test for independent samples, and oneway ANOVA with logarithmic transformation of the data - failed to detect a significant difference between the samples; not a negligible failure given the social health implications.

=head1 REFERENCES

Berry, K. J., & Mielke, P. W., Jr., (2002). The Fisher-Pitman permutation test: An attractive alternative to the F test. I<Psychological Reports>, I<90>, 495-502.

=head1 SEE ALSO

L<Statistics::ANOVA|lib::Statistics::ANOVA> Firstly test your independent groups data with the Levene's or O'Brien's equality of variances test in this package to see if they satisfy assumptions of the ANOVA; if not, happily use Fisher-Pitman instead.

=head1 LIMITATIONS/TO DO

Optimisation welcomed.

Do auto number of resamplings based on N possible permutations.

Randomization procedure can always be improved.

=head1 REVISION HISTORY

See CHANGES in installation distribution.

=head1 AUTHOR/LICENSE

=over 4

=item Copyright (c) 2006-2009 Roderick Garton

rgarton AT cpan DOT org

This program is free software. It may be used, redistributed and/or modified under the same terms as Perl-5.6.1 (or later) (see L<http://www.perl.com/perl/misc/Artistic.html>).

=item Disclaimer

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=back

=head1

This ends documentation for a Perl implementation of the Fisher-Pitman permutation test alternative to one-way ANOVA.

=cut
