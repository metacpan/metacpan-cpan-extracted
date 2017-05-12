package Spellunker::Pod::Parser;
use strict;
use warnings;
use utf8;
use parent qw(Pod::Simple::Methody);

use Carp ();

use constant {
    MODE_STOPWORDS => 1,
    MODE_IGNORE    => 2,
    MODE_NORMAL    => 3,
};

sub _handle_element_start {
    my ($self, $element_name, $attr_hash_r) = @_;
    $element_name =~ tr/-:./__/;

    if (my $start_line = $attr_hash_r->{start_line}) {
        $self->{start_line} = $start_line;
    }

    if ($element_name eq 'encoding') {
        $self->{mode} = MODE_IGNORE;
    } elsif ($element_name eq 'for') {
        if ($attr_hash_r->{target} eq 'stopwords') {
            $self->{mode} = MODE_STOPWORDS;
        }
    } elsif (
        $element_name eq 'code'
        || $element_name eq 'Verbatim'
        || $element_name eq 'C' # C<>
        || $element_name eq 'L' # L<>
    ) {
        $_[0]->{mode} = MODE_IGNORE;
    }
}

sub _handle_element_end {
    my ($self, $element_name, $attr_hash_r) = @_;
    $element_name =~ tr/-:./__/;
    $self->{mode} = MODE_NORMAL;
}

sub new {
    my $self = shift;
    my $new  = $self->SUPER::new(@_);
    $new->{'output_fh'} ||= *STDOUT{IO};
    $new->{mode} = 'normal';
    $new->accept_target_as_text(qw( text plaintext plain stopwords ));

    # whether to ignore X<...> codes
    $new->nix_X_codes(1);

    # Whether to map S<...>'s to \xA0 characters
    $new->nbsp_for_S(1);

    # whether to try to keep whitespace as-is
    $new->preserve_whitespace(1);

    return $new;
}

sub stopwords { $_[0]->{stopwords} || [] }
sub lines { $_[0]->{lines} || [] }
sub start_line { $_[0]->{start_line} || 0 }

sub _handle_text {
    my ($self, $text) = @_;
    if ($self->{mode} eq MODE_IGNORE) {
        # nop.
    } elsif ($self->{mode} eq MODE_STOPWORDS) {
        push @{$self->{stopwords}}, $text;
    } else {
        my $offset = 0;
        for my $line (split /\n/, $text) {
            push @{$self->{lines}}, [
                $self->start_line + $offset, $line
            ];
            $offset++;
        }
    }
}

1;

