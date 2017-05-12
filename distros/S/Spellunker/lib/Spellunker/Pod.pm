package Spellunker::Pod;
use strict;
use warnings;
use utf8;
use Spellunker;
use Spellunker::Pod::Parser;

sub new {
    my $class = shift;
    bless {spellunker => Spellunker->new()}, $class;
}

sub add_stopwords {
    my $self = shift;
    $self->{spellunker}->add_stopwords(@_);
}

sub load_dictionary {
    my $self = shift;
    $self->{spellunker}->load_dictionary(@_);
}

sub _check_parser {
    my ($self, $parser) = @_;

    # '=for stopwords'
    for my $stopwords (@{$parser->stopwords}) {
        $self->add_stopwords(split /\s+/, $stopwords);
    }

    my $lines = $parser->lines;
    my $line = 0;
    my @rv;
    for my $line ( @$lines ) {
        my $text = $line->[1];
        my @err = $self->{spellunker}->check_line($text);
        if (@err) {
            push @rv, [$line->[0], $line->[1], \@err];
        }
    }
    return @rv;
}

sub check_file {
    my ($self, $filename) = @_;

    my $parser = Spellunker::Pod::Parser->new();
    $parser->parse_file($filename);
    $self->_check_parser($parser);
}

sub check_text {
    my ($self, $text) = @_;

    my $parser = Spellunker::Pod::Parser->new();
    $parser->parse_string_document($text);
    $self->_check_parser($parser);
}

1;

