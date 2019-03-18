package Perl::Metrics::Halstead;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Compute Halstead complexity metrics

our $VERSION = '0.0500';

use Moo;
use strictures 2;
use namespace::clean;

use PPI::Document;
use PPI::Dumper;


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
    return $self->effort / 18; # seconds
}

sub _build_delivered_bugs {
    my ($self) = @_;
    return ($self->effort ** (2/3)) / 3000;
}


sub BUILD {
    my ( $self, $args ) = @_;

    my $doc = PPI::Document->new( $self->file );

    my $dump = PPI::Dumper->new( $doc, whitespace => 0 );

    my %halstead;

    for my $item ( $dump->list ) {
        $item =~ s/^\s*//;
        $item =~ s/\s*$//;
        my @item = split /\s+/, $item, 2;
        next unless defined $item[1];
        next if $item[0] eq 'PPI::Token::Comment'
            or $item[0] eq 'PPI::Token::Pod';
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
}


sub report {
    my ($self) = @_;
    printf "Total operators = %d, Total operands = %d\n", $self->n_operators, $self->n_operands;
    printf "Distinct operators = %d, Distinct operands = %d\n", $self->n_distinct_operators, $self->n_distinct_operands;
    printf "Program vocabulary = %d, Program length = %d\n", $self->prog_vocab, $self->prog_length;
    printf "Estimated program length = %.3f\n", $self->est_prog_length;
    printf "Program volume = %.3f\n", $self->volume;
    printf "Program difficulty = %.3f\n", $self->difficulty;
    printf "Program level = %.3f\n", $self->level;
    printf "Program language level = %.3f\n", $self->lang_level;
    printf "Program intelligence content = %.3f\n", $self->intel_content;
    printf "Program effort = %.3f\n", $self->effort;
    printf "Time to program = %.3f\n", $self->time_to_program;
    printf "Delivered bugs = %.3f\n", $self->delivered_bugs;
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
    return $key eq 'PPI::Token::Number'
        || $key eq 'PPI::Token::Symbol'
        || $key eq 'PPI::Token::Pod'
        || $key eq 'PPI::Token::HereDoc'
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

version 0.0500

=head1 SYNOPSIS

  use Perl::Metrics::Halstead;

  my $pmh = Perl::Metrics::Halstead->new(file => '/some/perl/code.pl');

  my $metrics = $pmh->dump;

  $pmh->report;

=head1 DESCRIPTION

C<Perl::Metrics::Halstead> computes Halstead complexity metrics.

Please see the explanatory links in the L</"SEE ALSO"> section for descriptions
of what these attributes mean and how they are computed.

=head1 ATTRIBUTES

=head2 file

  $file = $pmh->file;

The file to analyze.  This is a required attribute.

=head2 n_operators

  $n_operators = $pmh->n_operators;

The total number of operators.  This is a computed attribute.

=head2 n_operands

  $n_operands = $pmh->n_operands;

The total number of operands.  This is a computed attribute.

=head2 n_distinct_operators

  $n_distinct_operators = $pmh->n_distinct_operators;

The number of distinct operators.  This is a computed attribute.

=head2 n_distinct_operands

  $n_distinct_operands = $pmh->n_distinct_operands;

The number of distinct operands.  This is a computed attribute.

=head2 prog_vocab

  $prog_vocab = $pmh->prog_vocab;

The program vocabulary.  This is a computed attribute.

=head2 prog_length

  $prog_length = $pmh->prog_length;

The program length.  This is a computed attribute.

=head2 est_prog_length

  $est_prog_length = $pmh->est_prog_length;

The estimated program length.  This is a computed attribute.

=head2 volume

  $volume = $pmh->volume;

The program volume.  This is a computed attribute.

=head2 difficulty

  $difficulty = $pmh->difficulty;

The program difficulty.  This is a computed attribute.

=head2 level

  $level = $pmh->level;

The program level.  This is a computed attribute.

=head2 lang_level

  $lang_level = $pmh->lang_level;

The programming language level.  This is a computed attribute.

=head2 intel_content

  $intel_content = $pmh->intel_content;

Amount of intelligence presented in the program.  This is a computed attribute.

=head2 effort

  $effort = $pmh->effort;

The program effort.  This is a computed attribute.

=head2 time_to_program

  $time_to_program = $pmh->time_to_program;

The time to program.  This is a computed attribute.

=head2 delivered_bugs

  $delivered_bugs = $pmh->delivered_bugs;

Delivered bugs.  This is a computed attribute.

=head1 METHODS

=head2 new()

  $pmh = Perl::Metrics::Halstead->new(file => $file);

Create a new C<Perl::Metrics::Halstead> object given the B<file> argument.

=head2 BUILD()

Process the given B<file> into the computed metrics.

=head2 report()

  $pmh->report();

Print the computed metrics to C<STDOUT>.

=head2 dump()

  $metrics = $pmh->dump();

Return a hashref of the metrics and their computed values.

=head1 SEE ALSO

The F<t/01-methods.t> file in this distribution.

L<Moo>

L<PPI::Document>

L<PPI::Dumper>

L<https://en.wikipedia.org/wiki/Halstead_complexity_measures>

L<https://www.verifysoft.com/en_halstead_metrics.html>

L<https://www.geeksforgeeks.org/software-engineering-halsteads-software-metrics/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
