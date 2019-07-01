package School::Code::Compare;
# ABSTRACT: 'naive' metrics for code similarity
$School::Code::Compare::VERSION = '0.101';
use strict;
use warnings;

use Text::Levenshtein::XS qw(distance);

sub new {
    my $class = shift;

    my $self = {
                    max_relative_diff     => 2,
                    min_char_total        => 20,
                    max_relative_distance => 0.8,
               };
    bless $self, $class;

    return $self;
}

sub set_max_relative_difference {
    my $self = shift;

    $self->{max_relative_diff} = shift;

    # make this chainable in OO-interface
    return $self;
}

sub set_min_char_total {
    my $self = shift;

    $self->{min_char_total} = shift;

    # make this chainable in OO-interface
    return $self;
}

sub set_max_relative_distance {
    my $self = shift;

    $self->{max_relative_distance} = shift;

    # make this chainable in OO-interface
    return $self;
}

sub measure {
    my $self = shift;

    my $str1 = shift;
    my $str2 = shift;

    my $length_str1 = length($str1);
    my $length_str2 = length($str2);

    my ($short, $long) =  $length_str1 < $length_str2 ?
                         ($length_str1,  $length_str2) :
                         ($length_str2,  $length_str1) ;

    my $diff           = $long - $short;

    if ($self->{min_char_total} > $length_str1
     or $self->{min_char_total} > $length_str2) {
        return {
            distance     => undef,
            ratio        => undef,
            length1      => $length_str1,
            length2      => $length_str2,
            delta_length => $diff,
            comment      => 'skipped: smaller than '
                            . $self->{min_char_total},
        };
    }

    my $longer_percent = $long / $short;

    $self->{max_distance} = $short * $self->{max_relative_distance};

    if ($longer_percent > $self->{max_relative_diff}) {
        return {
            distance     => undef,
            ratio        => undef,
            length1      => $length_str1,
            length2      => $length_str2,
            delta_length => $diff,
            comment      => 'skipped: delta in length bigger than factor '
                            . $self->{max_relative_diff},
        };
    }
    else {
        my $distance = distance($str1, $str2, $self->{max_distance});

        if (defined $distance) {

            my $shorter_strlen = $length_str1 > $length_str2
                                ? $length_str1 : $length_str2;
            # 100 - (different in %) = (equal in %)
            my $chars_equal_percent = 100 - int($distance/$shorter_strlen*100 + 0.5);

            return {
                distance     => $distance,
                ratio        => $chars_equal_percent,
                length1      => $length_str1,
                length2      => $length_str2,
                delta_length => $diff,
                comment      => 'comparison done',
            };
        }
        else {
            return {
                distance     => undef,
                ratio        => undef,
                length1      => $length_str1,
                length2      => $length_str2,
                delta_length => $diff,
                comment      => 'skipped: distance higher than '
                                . $self->{max_distance} . ' (factor '
                                . $self->{max_relative_distance} . ')',
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

version 0.101

=head1 SYNOPSIS

This distribution ships a script.
You migth want to look at the script L<compare-code> in the C<bin> directory.
For documentation of the used libraries, keep on reading.

This calculates the Levenshtein Difference for two files, if they meet certain criterias:

 use School::Code::Compare;

 my $comparer   = School::Code::Compare->new()                                      
                                       ->set_max_relative_difference(2)             
                                       ->set_min_char_total        (20)             
                                       ->set_max_relative_distance(0.8);         
                                                                                    
 my $comparison1 = $comparer->measure('use v5.22; say "Hi"!',               
                                      'use v5.22; say "Hello";'                     
                                   );                                           
 print $comparison1->{distance} if $comparison #

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
     'delta_length' => 3,
     'length1' => 20,
     'ratio' => 79,
     'length2' => 23,
     'comment' => 'comparison done',
     'distance' => 5
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
