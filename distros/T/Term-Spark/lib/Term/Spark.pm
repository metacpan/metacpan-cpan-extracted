package Term::Spark;

use strict;
use warnings;
use utf8;

use Sub::Exporter -setup => {
    'exports' => [ 'show_bar', 'show_graph' ],
};

our @ISA = qw();

our $VERSION = '0.25'; # VERSION

sub show_bar {
    my $num = shift;
    my $max = shift;

    my @graph  = qw{ ▁ ▂ ▃ ▄ ▅ ▆ ▇ █ };

    my $index = ( $num * ( scalar( @graph ) - 1 )  ) / $max;

    return $graph[ int $index ];
}

sub show_graph {
    my %args = @_;

    my $max    = $args{'max'}    || 0;
    my $values = $args{'values'} || [];
    my $result = q{};

    for my $value ( @{ $values } ) {
        $result .= show_bar( $value, $max );
    }

    return $result;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Term::Spark

=head1 SYNOPSIS

Displays beautiful graphs to use in the terminal

=head1 DESCRIPTION

=head2 METHODS

Returns a string with a single utf8 bar according to the value

    Term::Spark::show_bar($value_for_this_bar, $max_value);

Returns a string with a bunch of utf8 bars according to the values

    Term::Spark::show_graph('max' => $max_value, 'values' => \@values);

Example:

    A script to capture args or STDIN and print a graph:

    use Term::Spark;

    chomp( @ARGV = <STDIN> ) unless @ARGV;

    my @list = sort { $a <=> $b } @ARGV;

    print Term::Spark::show_graph(
        'max'     => $list[-1],
        'values'  => \@ARGV,
    );

=head1 NAME

Term::Spark - Perl extension for dispaying bars in the terminal

=head1 SEE ALSO

Original idea: https://github.com/holman/spark

=head1 AUTHOR

Gil Gonçalves <lurst@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gil Gonçalves.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
