package PDL::Tokenizers;

use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use JSON::MaybeXS qw(decode_json);
use PDL::Core ();
use PDL::Lite ();

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    my $vocab  = $args{vocab}  || {};
    my $merges = $args{merges} || [];
    my $unk_id = $args{unk_id} // ($vocab->{'<unk>'} // $vocab->{'[UNK]'} // 0);

    my %id_to_tok = reverse %{$vocab};
    my %merge_rank;
    for my $i (0 .. $#{$merges}) {
        my $m = $merges->[$i];
        my $key = ref($m) eq 'ARRAY' ? join(' ', @{$m}) : $m;
        $merge_rank{$key} = $i;
    }

    return bless {
        vocab      => $vocab,
        id_to_tok  => \%id_to_tok,
        merge_rank => \%merge_rank,
        unk_id     => $unk_id,
    }, $class;
}

sub from_file {
    my ($class, $file) = @_;
    croak 'Filename required' unless defined $file;
    open my $fh, '<:encoding(UTF-8)', $file or croak "Cannot open '$file': $!";
    local $/;
    my $raw = <$fh>;
    close $fh;
    my $data = decode_json($raw);
    my $model = $data->{model} || $data;
    return $class->new(
        vocab  => $model->{vocab}  || {},
        merges => $model->{merges} || [],
    );
}

sub _bpe_word {
    my ($self, $word) = @_;
    my @syms = split //, $word;
    return @syms if @syms <= 1 || !%{ $self->{merge_rank} };

    while (@syms > 1) {
        my ($best_rank, $best_idx);
        for my $i (0 .. $#syms - 1) {
            my $pair = $syms[$i] . ' ' . $syms[$i + 1];
            my $rank = $self->{merge_rank}{$pair};
            if (defined $rank && (!defined $best_rank || $rank < $best_rank)) {
                $best_rank = $rank;
                $best_idx  = $i;
            }
        }
        last unless defined $best_idx;
        splice @syms, $best_idx, 2, $syms[$best_idx] . $syms[$best_idx + 1];
    }
    return @syms;
}

sub encode {
    my ($self, $text) = @_;
    $text = '' unless defined $text;
    my @ids;
    my $vocab = $self->{vocab};
    for my $word (split /\s+/, $text) {
        next unless length $word;
        if (exists $vocab->{$word}) {
            push @ids, $vocab->{$word};
        } else {
            for my $piece ($self->_bpe_word($word)) {
                push @ids, exists($vocab->{$piece}) ? $vocab->{$piece} : $self->{unk_id};
            }
        }
    }
    return PDL::Core::pdl(PDL::long(), \@ids);
}

sub decode {
    my ($self, $ids_pdl) = @_;
    my @ids = ref($ids_pdl) && eval { $ids_pdl->isa('PDL') }
        ? $ids_pdl->list
        : (ref($ids_pdl) eq 'ARRAY' ? @{$ids_pdl} : ());
    my @pieces = map { $self->{id_to_tok}{$_} // '' } @ids;
    return join(' ', grep { length } @pieces);
}

sub vocab_size {
    my ($self) = @_;
    return scalar keys %{ $self->{vocab} };
}

1;

__END__

=head1 NAME

PDL::Tokenizers - Pure-Perl BPE and HuggingFace tokenizer.json support for PDL

=head1 SYNOPSIS

    use PDL::Tokenizers;

    my $tok = PDL::Tokenizers->from_file('tokenizer.json');
    my $ids = $tok->encode('hello world');   # PDL long ndarray
    my $txt = $tok->decode($ids);

=head1 DESCRIPTION

C<PDL::Tokenizers> provides BPE tokenization and HuggingFace C<tokenizer.json>
loading in pure Perl, encoding text directly into L<PDL> C<long> token-ID
ndarrays for downstream inference in L<PDL::Torch>, L<PDL::ONNX>, or L<PDL::GGML>.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
