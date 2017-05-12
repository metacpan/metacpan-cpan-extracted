package Spellunker::Perl;
use strict;
use warnings;
use utf8;
use 5.010_001;

use version; our $VERSION = version->declare("v0.3.2");

use Spellunker;
use PPI;

use Mouse;

has spellunker => (
    is => 'ro',
    default => sub { Spellunker->new() },
    handles => [qw(add_stopwords load_dictionary)],
);

has ppi => (
    is => 'ro',
    isa => 'PPI::Document',
    required => 1,
);

no Mouse;

sub new_from_file {
    my ($class, $filename) = @_;

    my $ppi = PPI::Document->new($filename);
    return $class->new(ppi => $ppi);
}

sub new_from_string {
    my ($class, $string) = @_;
    my $ppi = PPI::Document->new(\$string);
    return $class->new(ppi => $ppi);
}

# TEST:
# the real defaults are dfined in the parser

# tokens: [$line_number, $content]
sub _check_parser {
    my ($self, $token, $method) = @_;

    my @err = $self->{spellunker}->check_line($token->$method);
    if (@err) {
        return ([$token->line_number, $token->$method, \@err]);
    }
    return ();
}

sub check_comment {
    my ($self) = @_;

    my $comments = $self->ppi->find( sub { $_[1]->isa('PPI::Token::Comment') } );
    return map { $self->_check_parser($_, 'content') } @$comments;
}

sub check_sub_name {
    my ($self) = @_;

    my $comments = $self->ppi->find( sub { $_[1]->isa('PPI::Statement::Sub') } );
    return map { $self->_check_parser($_, 'name') } @$comments;
}

# TEST:
sub agument { }

# TEST:
# template agument

1;
__END__

=encoding utf-8

=head1 NAME

Spellunker::Perl - Spelling checker for Perl script

=head1 SYNOPSIS

    use Spellunker::Perl;

    my $spellunker = Spellunker::Perl->new_from_file('path/to/MyModule.pm');
    my @err = $spellunker->check_comment();
    use Data::Dumper; warn Dumper(@err);

=head1 DESCRIPTION

Spellunker::Perl is Spelling checker for Perl script.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

