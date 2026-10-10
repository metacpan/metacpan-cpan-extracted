# Peta::NN::Codec

characters to token indices, string pairs to edit labels

## Synopsis

```perl
use Peta::NN::Codec qw(build_vocab window edit_label apply_edit);

my $vocab  = build_vocab(\@words);
my @chars  = split //, 'Irena';
my $tokens = window(\@chars, @chars - 4, 4, $vocab);    # the last four

my $label = edit_label('Irena', 'Ireno');               # "1:o"
print apply_edit('Helena', $label);                     # Heleno
```

## Functions

All are exported on request.

### build_vocab

`build_vocab(\@strings)`: `{ character => index }` over every character
of the strings. Indices 0 and 1 are reserved for padding and for unknown
characters.

### window

`window(\@chars, $from, $count, $vocab)`: the token indices of `$count`
consecutive positions starting at `$from`, which may lie before the start or
run past the end.

### edit_label

`edit_label($in, $out)`: how to turn `$in` into `$out` by rewriting its
end, as `"cut:add"`. Jelínek to Jelínku is `"2:ku"`.

### apply_edit

`apply_edit($in, $label)`: the string with the edit carried out, or undef
when the label asks to cut more than the string has.

### edit2_label

`edit2_label($in, $out)`: the same for both ends around what the two strings
share, as `"cut:add|cut:add"`, first for the front.

### apply_edit2

`apply_edit2($in, $label)`: the string with a two-ended edit carried out, or
undef.

---

From the POD of `lib/Peta/NN/Codec.pm`; change it there.
