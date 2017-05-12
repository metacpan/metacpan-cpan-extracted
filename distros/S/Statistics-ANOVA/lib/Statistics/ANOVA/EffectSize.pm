package Statistics::ANOVA::EffectSize;

use 5.006;
use strict;
use warnings;
use base qw(Statistics::Data);
use Carp qw(croak);
use List::AllUtils qw(any);
$Statistics::ANOVA::EffectSize::VERSION = '0.01';

=head1 NAME

Statistics::ANOVA::EffectSize - Calculate effect-sizes from ANOVAs incl. eta-squared and omega-squared

=head1 VERSION

This is documentation for B<Version 0.01> of Statistics::ANOVA::EffectSize.

=head1 SYNOPSIS

 use Statistics::ANOVA::EffectSize;
 my $es = Statistics::ANOVA::EffectSize->new();
 $es->load(HOA); # a hash of arefs, or other, as in Statistics::Data
 my $etasq = $es->eta_squared(independent => BOOL, partial => 1); # or give data => HOA here
 my $omgsq = $es->omega_squared(independent => BOOL);
 # or calculate not from loaded data but directly:

=head2 DESCRIPTION

Calculates effect-sizes from ANOVAs. 

For I<eta>-squared, values range from 0 to 1, 0 indicating no effect, 1 indicating difference between at least two DV means. Generally indicates the proportion of variance in the DV related to an effect.

For I<omega>-squared, size is conventionally described as small where omega_sq = .01, medium if omega_sq = .059, and strong if omega_sq = .138 (Cohen, 1969).

=head1 SUBROUTINES/METHODS

Rather than working from raw data, these methods are given the statistics, like sums-of-squares, needed to calculate the effect-sizes.

=head2 eta_sq_partial_by_ss, r_squared

 $es->eta_sq_partial_by_ss(ss_b => NUM, ss_w => NUM);

Returns partial I<eta>-squared given between- and within-group sums-of-squares (I<SS>):

=for html <p>&nbsp;&nbsp;&eta;<sup>2</sup><sub>P</sub> = <i>SS</i><sub>b</sub> / ( <i>SS</i><sub>b</sub> + <i>SS</i><sub>w</sub> )</p>

This is also what is commonly designated as I<R>-squared (Maxwell & Delaney, 1990, Eq. 90).

=cut

sub eta_sq_partial_by_ss {
    my ($self, %args) = @_;
    croak 'Undefined values needed to calculate partial eta-squared by sums-of-squares' if any { ! defined $args{$_} } (qw/ss_b ss_w/);
    return $args{'ss_b'} / ( $args{'ss_b'} + $args{'ss_w'} );
}
*r_squared = \&eta_sq_partial_by_ss;

=head2 r_squared_adj

    $es->r_squared_adj(ss_b => NUM, ss_w => NUM, df_b => NUM, df_w => NUM);

Returns adjusted I<R>-squared.

=cut

sub r_squared_adj {
    my ($self, %args) = @_;
    my $r_squared = $self->r_squared(%args); # will check for ss_b and ss_w
    croak 'Could not obtain values to calculate adjusted r-squared' if any { ! defined $args{$_} } (qw/df_b df_w/);
    return 1 - ( ($args{'df_b'} + $args{'df_w'}) / $args{'df_w'} ) * ( 1 - $r_squared );
}

=head2 eta_sq_partial_by_f

 $es->eta_sq_partial_by_f(f_value => NUM , df_b => NUM, df_w => NUM);

Returns partial I<eta>-squared given I<F>-value and its between- and within-groups degrees-of-freedom (I<df>):

=for html <p>&nbsp;&nbsp;&eta;<sup>2</sup><sub>P</sub> = ( <i>df</i><sub>b</sub> . <i>F</i> ) / ( <i>df</i><sub>b</sub> . <i>F</i> + <i>df</i><sub>w</sub> )</p>

=cut

sub eta_sq_partial_by_f {
    my ($self, %args) = @_;
    croak 'Could not obtain values to calculate partial eta-squared by F-value' if any { ! defined $args{$_} } (qw/df_b df_w f_value/);
    return ( $args{'df_b'} * $args{'f_value'} ) / ( $args{'df_b'} * $args{'f_value'} + $args{'df_w'} );
}

=head2 omega_sq_partial_by_ss

 $es->omega_sq_partial_by_ss(df_b => NUM, df_w => NUM, ss_b => NUM, ss_w => NUM);

Returns partial I<omega>-squared given the between- and within-groups sums-of-squares and degrees-of-freedom.

Essentially as given by Maxwell & Delaney (1990), Eq. 92:

=for html <p>&nbsp;&nbsp;&omega;<sup>2</sup><sub>P</sub> = ( <i>ss</i><sub>b</sub> &mdash; (<i>df</i><sub>b</sub> . <i>SS</i><sub>w</sub> / <i>df</i><sub>b</sub>) ) / (( <i>SS</i><sub>b</sub> + <i>SS</i><sub>w</sub> ) + <i>SS</i><sub>w</sub> / <i>df</i><sub>w</sub> )

=cut

sub omega_sq_partial_by_ss {
    my ($self, %args) = @_;
    croak 'Undefined values for calculating partial omega-squared by sums-of-squares' if any { ! defined $args{$_} } (qw/ss_b ss_w df_b df_w/);
    return  ( $args{'ss_b'} - ( $args{'df_b'} * $args{'ss_w'} / $args{'df_w'} ) ) / ( ( $args{'ss_b'} + $args{'ss_w'} ) + $args{'ss_w'} / $args{'df_w'} );
}

=head2 omega_sq_partial_by_ms

 $es->omega_sq_partial_by_ms(df_b => NUM, ms_b => NUM, ms_w => NUM, count => NUM);

Returns partial I<omega>-squared given between- and within-group mean sums-of-squares (I<MS>). Also needs between-groups degrees-of-freedom and sample-size (here labelled "count") I<N>:

=for html <p>&nbsp;&nbsp;&omega;<sup>2</sup><sub>P</sub> = <i>df</i><sub>b</sub>  ( <i>MS</i><sub>b</sub> &ndash; <i>MS</i><sub>w</sub> ) / ( <i>df</i><sub>b</sub> . <i>MS</i><sub>b</sub> + ( <i>N</i> &ndash; <i>df</i><sub>b</sub> ) <i>MS</i><sub>w</sub> ) </p>

=cut

sub omega_sq_partial_by_ms {
    my ($self, %args) = @_;
    croak 'Could not obtain values to calculate partial omega-squared by mean sums-of-squares' if any { ! defined $_ } values %args;
    return  $args{'df_b'} * ( $args{'ms_b'} - $args{'ms_w'} )  / ( $args{'df_b'} * $args{'ms_b'} + ( $args{'count'} - $args{'df_b'} ) * $args{'ms_w'} );
}

=head2 omega_sq_partial_by_f

 $es->omega_sq_partial_by_ms(f_value => NUM, df_b => NUM, df_w => NUM);

Returns partial I<omega>-squared given I<F>-value and its between- and within-group degrees-of-freedom (I<df>):

=for html <p>&nbsp;&nbsp;&omega;<sup>2</sup><sub>P</sub>(est.) = ( <i>F</i> - 1 ) / ( <i>F</i> + ( df</i><sub>w</sub> + 1 ) / <i>df</i><sub>b</sub> )</p>

This is an estimate formulated by L<D. Lakens|http://daniellakens.blogspot.com.au/2015/06/why-you-should-use-omega-squared.html> that will not ordinarily agree with the method by (mean) sum-of-squares.

=cut

sub omega_sq_partial_by_f {
    my ($self, %args) = @_;
    croak 'Could not obtain values to calculate partial omega-squared by mean sums-of-squares' if any { ! defined $_ } values %args;
    return ( $args{'f_value'} - 1 ) / ( $args{'f_value'} + ( $args{'df_w'} + 1)/$args{'df_b'} ); 
}

=head2 eta_to_omega

 $es->eta_to_omega(df_b => NUM, df_w => NUM, eta_sq => NUM);

Returns I<omega>-squared based on I<eta>-squared and the between- and within-groups degrees-of-freedom.

=for html <p>&nbsp;&nbsp;&omega;<sup>2</sup><sub>P</sub> = ( &eta;<sup>2</sup><sub>P</sub>(<i>df</i><sub>b</sub> + <i>df</i><sub>w</sub>) &ndash; <i>df</i><sub>b</sub> ) /  ( &eta;<sup>2</sup><sub>P</sub>(<i>df</i><sub>b</sub> + <i>df</i><sub>w</sub>) &ndash; <i>df</i><sub>b</sub> ) + ( (<i>df</i><sub>w</sub> + 1)(1 &ndash; &eta;<sup>2</sup><sub>P</sub>) ) ) </p>

=cut

sub eta_to_omega {
    my ($self, %args) = @_;
    croak 'Could not obtain values to calculate partial omega-squared by mean sums-of-squares' if any { ! defined $_ } values %args;
    my $num = $args{'eta_sq'} * ( $args{'df_b'} + $args{'df_w'} ) - $args{'df_b'};
    return $num / ( $num + ( ( $args{'df_w'} + 1) * ( 1 - $args{'eta_sq'} ) ) );
}

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> : C<any> method

L<Statistics::Data|Statistics::Data> : used as base.

=head1 DIAGNOSTICS

=over 4

=item Could not obtain values to calculate ...

C<croak>ed if the sufficient statistics have not been provided.

=back

=head1 REFERENCES

Cohen, J. (1969). I<Statistical power analysis for the behavioral sciences>. New York, US: Academic.

Lakens, D. (2015). Why you should use omega-squared instead of eta-squared, I<The 20% statistician> [L<Weblog|http://daniellakens.blogspot.com.au/2015/06/why-you-should-use-omega-squared.html>].

Maxwell, S. E., & Delaney, H. D. (1990). I<Designing experiments and analyzing data: A model comparison perspective>. Belmont, CA, US: Wadsworth.

Olejnik, S., & Algina, J. (2003). Generalized eta and omega squared statistics: Measures of effect size for some common research designs. I<Psychological Methods>, I<8>, 434-447. doi: L<10.1037/1082-989X.8.4.434|http://dx.doi.org/10.1037/1082-989X.8.4.434>.

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-anova-effectsize-0.01 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-ANOVA-EffectSize-0.01>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 NOTES


For independent variables only, omega-square (raw):

w2 = (SSeffect - (dfeffect)(MSerror)) / MSerror + SStotal

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::ANOVA::EffectSize


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-ANOVA-EffectSize-0.01>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-ANOVA-EffectSize-0.01>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-ANOVA-EffectSize-0.01>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-ANOVA-EffectSize-0.01/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Statistics::ANOVA::EffectSize
