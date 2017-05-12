use Test::More tests => 4;
use Term::TtyRec::Plus;

my $t = Term::TtyRec::Plus->new(
    infile => "t/nethack.ttyrec",
);
my $frame_ref;

$frame_ref = $t->grep("finger of death");
is($frame_ref->{frame}, 53, "t->grep(STRING) works");

$frame_ref = $t->grep(qr/Where do you want to jump\?/);
is($frame_ref->{frame}, 77, "t->grep(REGEX) works");

$frame_ref = $t->grep(sub { $_[0]{timestamp} > 1165798100 } );
is($frame_ref->{frame}, 339, "t->grep(SUB) works");

$frame_ref = $t->grep("priestess of Ptah", sub { $_[0]{data} !~ /\bmace\b/ });
is($frame_ref->{frame}, 364, "multiarg t->grep() works");

