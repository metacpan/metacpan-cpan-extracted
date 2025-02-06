use Perlmazing qw(isa_array isa_hash sort_by_key);

sub main {
  map { isa_array $_ ? main(@$_) : isa_hash $_ ? main(sort_by_key %$_) : $_ } @_;
}

1;