use Perlmazing;
our @ISA = qw(Perlmazing::Listable);

sub main {
    no warnings;
    if (not defined $_[0]) {
        $_[0] = 0;
    } elsif (is_number $_[0]) {
        my $copy = $_[0];
        # Remove possible _ number separations
        $copy =~ s/(\d)_(\d)/$1$2/g;
        # Avoid octal interpretations
        $copy =~ s/^0+//;
        my $result = eval "$copy";
        croak "Unexpected error with to_number(".dumped($copy)."): $@" if $@;
        $result = 0 unless defined $result;
        $_[0] = $result;
    } else {
        $_[0] =~ s/\D+//g;
        $_[0] += 0;
    }
}

1;