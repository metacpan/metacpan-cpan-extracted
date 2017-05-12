package TestFindUser;
use Moo;

sub user { $< }

sub send_err { print STDERR "Foo\n"; }

1;
