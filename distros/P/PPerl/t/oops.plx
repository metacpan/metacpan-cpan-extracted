#!perl -w
# oops - accidental closure exposed by pperl

my $pid = $$;
sub pid { $pid }
print pid(), "\n";
