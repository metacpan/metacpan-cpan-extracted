use Perl6::Slurp;

sub squeeze {
    my ($removed) = @_;
    if ($removed =~ tr/\n/\n/ == 1) { return " " }
    else                            { return "\n\n"; }
}

print slurp(\*DATA, {irs=>qr/[ \t]*\n+/, chomp=>\&squeeze}), "\n";

__END__
This is the
first paragraph


This is the
second
paragraph

This, the
third




This one is
the
very
last
