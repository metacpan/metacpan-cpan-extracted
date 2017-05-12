package Pistachio::Tokenizer;
# ABSTRACT: provides iterator(), which turns source code text into a Pistachio::Token iterator

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION

use Module::Load;
use Carp 'croak';

use constant {
    LNG => 0,
    IDX => 1, 
    GOT => 2, 
    MAX => 3, 
    TOK => 4
};

# @param string $type Object type.
# @param Pistachio::Language $lang Language object. 
# @return Pistachio::Tokenizer
sub new {
    my $type = shift;
    my $lang = ref $_[0] eq 'Pistachio::Language' && $_[0]
               or croak 'A Pistachio::Language is required';
    bless [$lang], $type;
}

# @param Pistachio::Tokenizer $this
# @param scalarref $text    reference to text
# @return coderef    Pistachio::Token iterator
sub iterator {
    my ($this, $text) = @_;

    # initialize iterator data
    $this->[TOK] = $this->[LNG]->tokens($text);
    $this->[MAX] = scalar @{$this->[TOK]};
    $this->[IDX] = 0;
    $this->[GOT] = 0;

    # iterator closure
    sub {
        return undef if $this->_finished;
        my $token = $this->_transform($this->_curr);
        $this->[GOT]++;
        $this->_next;
        $token;
    };
}

# @param Pistachio::Tokenizer $this
# @return int    1 if we're finished iterating, or 0
sub _finished { 
    my $this = shift;
    $this->[MAX] - $this->[GOT] < 1 ? 1 : 0;
}

# @param Pistachio::Tokenizer $this
# @return Pistachio::Token
sub _curr { 
    my $this = shift;
    $this->[TOK]->[$this->[IDX]];
}

# @param Pistachio::Tokenizer
# @return int    1 if there is a previous element, or 0
sub _has_prev { shift->[IDX] > 0 ? 1 : 0 }
 
# @param Pistachio::Tokenizer $this
# @return int    1 if there is a next element, or 0
sub _has_next {
    my $this = shift;
    $this->[MAX] - $this->[IDX] > 0 ? 1 : 0;
}

# @param Pistachio::Tokenizer $this
# @return Pistachio::Token, or undef
sub _prev {
    my $this = shift;
    return undef unless $this->_has_prev;
    $this->[IDX]--;
    $this->_curr;
}

# @param Pistachio::Tokenizer $this
# @return Pistachio::Token, or undef
sub _next {
    my $this = shift;
    return undef unless $this->_has_next;
    $this->[IDX]++;
    $this->_curr;
}

# @param Pistachio::Tokenizer $this
# @param string $meth    '_prev' or '_next'
# @return Pistachio::Token, or undef
sub _skip_whitespace {
    my ($this, $meth) = @_;
    while ($_ = $this->$meth) { return $_ if !$_->whitespace }
    undef;
}

# @param Pistachio::Tokenizer $this
# @param Pistachio::Token $token
# @return Pistachio::Token
sub _transform {
    my ($this, $token) = @_;

    # Some token types will get transformed into 
    # more specific types by transformation rules.

    my $into;
    for my $rule (@{$this->[LNG]->transform_rules}) {
        $token->match($rule->type, $rule->value) or next;

        $rule->prec and do {
           $this->_has_prev or next;
           $this->_juxtaposed($rule->prec, '_prev') or next;
        };

        $rule->succ and do {
           $this->_has_next or next;
           $this->_juxtaposed($rule->succ, '_next') or next;
        };

        $into = $rule->into;
    }
    $token->type($into) if $into;

    $token;
}

# @param Pistachio::Tokenizer $this
# @param arrayref $neighbors    (type, val) pairs that might either
#                               precede or succeed the current
#                               Pistachio::Token, depending on $meth
# @param string $meth    '_prev' or '_next'
# @return int    1 if the current pair is juxtaposed
#                with the pairs from $neighbors, or 0
sub _juxtaposed {
    my ($this, $neighbors, $meth) = @_;

    my ($match, $idx) = (1, $this->[IDX]);

    for my $n (@$neighbors) {
        my $token = $this->_skip_whitespace($meth);
        my ($type, $val) = ($n->[0], sub {shift eq $n->[1]});
        $match = $token && $token->match($type, $val);
        $this->[IDX] = $idx;
    }

    $match;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Tokenizer - provides iterator(), which turns source code text into a Pistachio::Token iterator

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 use Pistachio::Tokenizer;
 my $tokenizer = Pistachio::Tokenizer->new('Perl5');

 my $scalar_ref = \"use strict; ...;";
 my $it = $tokenizer->iterator($scalar_ref);
 
 while (my $token = $it->()) {
     print $token->type, ': ', $token->value, "\n";
 }

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
