package School::Code::Compare;
# ABSTRACT: Calculate the difference between two strings
$School::Code::Compare::VERSION = '0.002';
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

School::Code::Compare - Calculate the difference between two strings

=head1 VERSION

version 0.002

=head1 SYNOPSIS

This distribution ships a script.
You migth want to look at the script L<compare-code> in the bin directory.

For documentation of the used libraries, keep on reading.

 my $comparer   = School::Code::Compare->new()                                    
                                       ->set_max_char_difference(400)             
                                       ->set_min_char_total     ( 20)             
                                       ->set_max_distance       (400);
 
 my $comparison = $comparer->measure( $files[$i]->{"code_$algo"},
                                      $files[$j]->{"code_$algo"}      
                                    ); 

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
