package Perl::Metrics::Halstead;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Compute Halstead complexity metrics

our $VERSION = '0.0608';

use PPI::Document;
use PPI::Dumper;

use Moo;
use strictures 2;
use namespace::clean;


has file => (
    is       => 'ro',
    required => 1,
);


has [qw(
    n_operators
    n_operands
    n_distinct_operators
    n_distinct_operands
)] => (
    is       => 'ro',
    init_arg => undef,
);


has [qw(
    prog_vocab
    prog_length
    est_prog_length
    volume
    difficulty
    level
    lang_level
    intel_content
    effort
    time_to_program
    delivered_bugs
)] => (
    is       => 'lazy',
    init_arg => undef,
    builder  => 1,
);

sub _build_prog_vocab {
    my ($self) = @_;
    return $self->n_distinct_operators + $self->n_distinct_operands;
}

sub _build_prog_length {
    my ($self) = @_;
    return $self->n_operators + $self->n_operands;
}

sub _build_est_prog_length {
    my ($self) = @_;
    return $self->n_distinct_operators * _log2($self->n_distinct_operators)
        + $self->n_distinct_operands * _log2($self->n_distinct_operands);
}

sub _build_volume {
    my ($self) = @_;
    return $self->prog_length * _log2($self->prog_vocab);
}

sub _build_difficulty {
    my ($self) = @_;
    return ($self->n_distinct_operators / 2)
        * ($self->n_operands / $self->n_distinct_operands);
}

sub _build_level {
    my ($self) = @_;
    return 1 / $self->difficulty;
}

sub _build_lang_level {
    my ($self) = @_;
    return $self->volume / $self->difficulty / $self->difficulty;
}

sub _build_intel_content {
    my ($self) = @_;
    return $self->volume / $self->difficulty;
}

sub _build_effort {
    my ($self) = @_;
    return $self->difficulty * $self->volume;
}

sub _build_time_to_program {
    my ($self) = @_;
    return $self->effort / 18;
}

sub _build_delivered_bugs {
    my ($self) = @_;
    return ($self->effort ** (2/3)) / 3000;
}


sub BUILD {
    my ( $self, $args ) = @_;

    my $doc = PPI::Document->new( $self->file );

    my $dump = PPI::Dumper->new( $doc, whitespace => 0, comments => 0 );

    die 'No document parsed for ', $self->file, ". Computation can't continue.\n"
        unless $dump;

    my %halstead;

    for my $item ( $dump->list ) {
        $item =~ s/^\s*//;
        $item =~ s/\s*$//;
        my @item = split /\s+/, $item, 2;
        next unless defined $item[1];
        next if $item[0] eq 'PPI::Token::Pod' or $item[0] eq 'PPI::Token::End';
        push @{ $halstead{ $item[0] } }, $item[1];
    }
#use Data::Dumper;warn(__PACKAGE__,' ',__LINE__,' ',Dumper\%halstead);

    $self->{n_operators} = 0;
    $self->{n_operands}  = 0;

    for my $key ( keys %halstead ) {
        if ( _is_operand($key) ) {
            $self->{n_operands} += @{ $halstead{$key} };
        }
        else {
            $self->{n_operators} += @{ $halstead{$key} };
        }
    }

    my %distinct;

    for my $key ( keys %halstead ) {
        for my $item ( @{ $halstead{$key} } ) {
            if ( _is_operand($key) ) {
                $distinct{operands}->{$item} = undef;
            }
            else {
                $distinct{operators}->{$item} = undef;
            }
        }
    }
#use Data::Dumper;warn(__PACKAGE__,' ',__LINE__,' ',Dumper\%distinct);

    $self->{n_distinct_operators} = keys %{ $distinct{operators} };
    $self->{n_distinct_operands}  = keys %{ $distinct{operands} };

    die 'No distinct operands for ', $self->file, ". Computation cannot continue.\n"
        unless $self->{n_distinct_operands};
}


sub report {
    my ( $self, $precision ) = @_;

    $precision ||= 3;

    printf "Total operators: %d + Total operands: %d = Program length: %d\n",
        $self->n_operators, $self->n_operands, $self->prog_length;
    printf "Distinct operators: %d + Distinct operands: %d = Program vocabulary: %d\n",
        $self->n_distinct_operators, $self->n_distinct_operands, $self->prog_vocab;
    printf "Estimated program length: %.*f\n", $precision, $self->est_prog_length;
    printf "Program volume: %.*f\n", $precision, $self->volume;
    printf "Program difficulty: %.*f\n", $precision, $self->difficulty;
    printf "Program level: %.*f\n", $precision, $self->level;
    printf "Program language level: %.*f\n", $precision, $self->lang_level;
    printf "Program intelligence content: %.*f\n", $precision, $self->intel_content;
    printf "Program effort: %.*f\n", $precision, $self->effort;
    printf "Time to program: %.*f\n", $precision, $self->time_to_program;
    printf "Delivered bugs: %.*f\n", $precision, $self->delivered_bugs;
}


sub dump {
    my ($self) = @_;
    return {
        n_operators => $self->n_operators,
        n_operands => $self->n_operands,
        n_distinct_operators => $self->n_distinct_operators,
        n_distinct_operands => $self->n_distinct_operands,
        prog_vocab => $self->prog_vocab,
        prog_length => $self->prog_length,
        est_prog_length => $self->est_prog_length,
        volume => $self->volume,
        difficulty => $self->difficulty,
        level => $self->level,
        lang_level => $self->lang_level,
        intel_content => $self->intel_content,
        effort => $self->effort,
        time_to_program => $self->time_to_program,
        delivered_bugs => $self->delivered_bugs,
    };
}

sub _is_operand {
    my $key = shift;
    return $key =~ /Number/
        || $key eq 'PPI::Token::Symbol'
        || $key eq 'PPI::Token::HereDoc'
        || $key eq 'PPI::Token::Data'
        || $key =~ /Quote/;
}

sub _log2 {
    my $n = shift;
    return log($n) / log(2);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Metrics::Halstead - Compute Halstead complexity metrics

=head1 VERSION

version 0.0608

=head1 SYNOPSIS

  use Perl::Metrics::Halstead;

  my $halstead = Perl::Metrics::Halstead->new(file => '/some/perl/code.pl');

  my $metrics = $halstead->dump;

  $halstead->report;

=head1 DESCRIPTION

C<Perl::Metrics::Halstead> computes software Halstead complexity metrics.

Please see the explanatory links in the L</"SEE ALSO"> section for descriptions
of what these attributes mean and how they are computed.

My write-up about this technique is at
L<http://techn.ology.net/halstead-software-complexity-of-perl-code/>

The installed program for computing this is called L<halstead>.

=head1 ATTRIBUTES

B<All> attributes are calculated except for B<file>, which is required to be
given in the constructor.

=head2 file

  $file = $halstead->file;

The file to analyze.

=head2 n_operators

  $n = $halstead->n_operators;

The total number of operators.

=head2 n_operands

  $n = $halstead->n_operands;

The total number of operands.

=head2 n_distinct_operators

  $n = $halstead->n_distinct_operators;

The number of distinct operators.

=head2 n_distinct_operands

  $n = $halstead->n_distinct_operands;

The number of distinct operands.

=head2 prog_vocab

  $x = $halstead->prog_vocab;

The program vocabulary.

=head2 prog_length

  $x = $halstead->prog_length;

The program length.

=head2 est_prog_length

  $x = $halstead->est_prog_length;

The estimated program length.

=head2 volume

  $x = $halstead->volume;

The program volume.

=head2 difficulty

  $x = $halstead->difficulty;

The program difficulty.

=head2 level

  $x = $halstead->level;

The program level.

=head2 lang_level

  $x = $halstead->lang_level;

The programming language level.

=head2 intel_content

  $x = $halstead->intel_content;

Measure of the information content of a program.

=head2 effort

  $x = $halstead->effort;

The program effort.

=head2 time_to_program

  $x = $halstead->time_to_program;

The time to program (in seconds).

=head2 delivered_bugs

  $x = $halstead->delivered_bugs;

Delivered bugs.

=head1 METHODS

=head2 new

  $halstead = Perl::Metrics::Halstead->new(file => $file);

Create a new C<Perl::Metrics::Halstead> object given the B<file> argument.

=head2 BUILD

Process the given B<file> into the computed metrics.

=head2 report

  $halstead->report;
  $halstead->report($precision);

Print the computed metrics to C<STDOUT>.  Optionally provide a number for the
decimal precision.  Default: 3 digits

=head2 dump

  $metrics = $halstead->dump;

Return a hashref of the metrics and their computed values.

=head1 SEE ALSO

The F<bin/halstead> and F<t/01-methods.t> files in this distribution.

L<Moo>

L<PPI::Document>

L<PPI::Dumper>

L<https://en.wikipedia.org/wiki/Halstead_complexity_measures>

L<http://techn.ology.net/halstead-software-complexity-of-perl-code/>

L<https://www.verifysoft.com/en_halstead_metrics.html>

L<https://www.geeksforgeeks.org/software-engineering-halsteads-software-metrics/>

L<https://www.compuware.com/hard-can-find-halstead-maintenance-effort-metric/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
