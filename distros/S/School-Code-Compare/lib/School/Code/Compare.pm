package School::Code::Compare;
# ABSTRACT: 'naive' metrics for code similarity
$School::Code::Compare::VERSION = '0.007';
use strict;
use warnings;

use Text::Levenshtein::XS qw(distance);

sub new {
    my $class = shift;

    my $self = {
                    max_char_diff  => 70,
                    min_char_total => 20,
                    max_distance   => 300,
               };
    bless $self, $class;

    return $self;
}

sub set_max_char_difference {
    my $self = shift;

    $self->{max_char_diff} = shift;

    # make this chainable in OO-interface
    return $self;
}

sub set_min_char_total {
    my $self = shift;

    $self->{min_char_total} = shift;

    # make this chainable in OO-interface
    return $self;
}

sub set_max_distance {
    my $self = shift;

    $self->{max_distance} = shift;

    # make this chainable in OO-interface
    return $self;
}

sub measure {
    my $self = shift;

    my $str1 = shift;
    my $str2 = shift;

    my $length_str1 = length($str1);
    my $length_str2 = length($str2);


    if ($self->{min_char_total} > $length_str1
     or $self->{min_char_total} > $length_str2) {
        return {
            distance     => undef,
            ratio        => undef,
            delta_length => undef,
            comment      => 'skipped: smaller than '
                            . $self->{min_char_total},
        };
    }

    my $diff = $length_str1 - $length_str2;

    $diff = $diff * -1 if ($diff < 0);

    if ($diff > $self->{max_char_diff}) {
        return {
            distance     => undef,
            ratio        => undef,
            delta_length => $diff,
            comment      => 'skipped: delta in length bigger than '
                            . $self->{max_char_diff},
        };
    }
    else {
        my $distance = distance($str1, $str2, $self->{max_distance});

        if (defined $distance) {

            my $total_chars = $length_str1 + $length_str2;
            my $proportion_chars_changes =
                                    int(($distance / ($total_chars / 2))*100);

            return {
                distance     => $distance,
                ratio        => $proportion_chars_changes,
                delta_length => $diff,
                comment      => 'comparison done',
            };
        }
        else {
            return {
                distance     => undef,
                ratio        => undef,
                delta_length => $diff,
                comment      => 'skipped: distance higher than '
                                . $self->{max_distance},
            };
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare - 'naive' metrics for code similarity

=head1 VERSION

version 0.007

=head1 SYNOPSIS

This distribution ships a script.
You migth want to look at the script L<compare-code> in the C<bin> directory.
For documentation of the used libraries, keep on reading.

This calculates the Levenshtein Difference for two files, if they meet certain criterias:

 use School::Code::Compare;

 my $comparer   = School::Code::Compare->new()                                    
                                       ->set_max_char_difference(400)             
                                       ->set_min_char_total     ( 20)             
                                       ->set_max_distance       (400);
 
 my $comparison = $comparer->measure( 'use strict; print "Hello\n";',
                                      'use v5.22; say "Hello";'
                                    ); 

 print $comparison->{distance} if $comparison   # 13

=head1 FUNCTIONS

=head2 set_max_char_difference

Don't even start comparison, if the difference in char count is higher than set.

=head2 set_min_char_total

Don't even start comparison if a file is below this char count.

=head2 set_max_distance

Abort comparison (in the midst of comparison), if distance is becoming higher then set value.

=head2 measure

Do a comparison for two strings.
Gives back a hash reference with different information:

 # (example output from synopsis)
 {
   'distance'     => 13,
   'ratio'        => 50,
   'comment'      => 'comparison done',
   'delta_length' => 5
 };

=over 4

=item distance

The Levenshtein Distance.
See L<Text::Levenshtein::XS> for more information.

=item ratio

The ratio of the distance in chars to the average length of the compared strings.
A ratio of zero means, the strings are similar.
A ratio of 50 means, that 50% of a string is different.

My experience is, that if you get a ratio below 30% you have to start looking if the code was copied and altered (if your concern is to find 'cheaters' in educational/school environments).
This method of measurement is by no means well established.
It may be even 'naive', but it just seems to work out quite well.
See L<School::Code::Compare::Judge> to see, how the results are currently interpreted.

=item comment

A comment on how the comparison went.

=item delta_length

Difference in length (chars) of the two compared strings.

=back

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
