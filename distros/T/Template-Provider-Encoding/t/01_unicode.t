use strict;
use Test::More 'no_plan';

use Encode;
use Template::Provider::Encoding;
use Template::Stash::ForceUTF8;
use Template;

my @files = qw( euc-jp.tt utf-8.tt utf-8-wo-encoding.tt utf-8-bom.tt );

my $author = "\x{5bae}\x{5ddd}"; # miyagawa
my $place  = "\x{6771}\x{4eac}"; # Tokyo
my $author_utf8 = encode("utf-8", $author);
my $place_utf8  = encode("utf-8", $place);

for my $file (@files) {
    my $tt = Template->new(
        LOAD_TEMPLATES => [ Template::Provider::Encoding->new ],
    );
    my $vars;
    $vars->{author} = $author;             # Unicode string
    $vars->{my}     = { place => $place }; # Unicode string
    $tt->process("t/$file", $vars, \my $out) or die $tt->error;

    ok Encode::is_utf8($out), "$file output is utf-8 flagged";
    like $out, qr/$author/, "$file includes author name correctly";
    like $out, qr/$place/, "$file includes place correctly";
    unless ($file =~ /(-wo-|-bom)/) {
        my $encoding = ($file =~ /(.*)\.tt/)[0];
        like $out, qr/encoding=$encoding/, "$file has encoding $encoding";
    }
}

# test mixing Unicode flagged and UTF-8 bytes in the stash (Unicode flagged)
for my $file (@files) {
    my $tt = Template->new(
        LOAD_TEMPLATES => [ Template::Provider::Encoding->new ],
        STASH => Template::Stash::ForceUTF8->new,
    );
    my $vars;
    $vars->{author} = $author;                  # unicode string
    $vars->{my}     = { place => $place_utf8 }; # utf-8
    $tt->process("t/$file", $vars, \my $out) or die $tt->error;

    ok Encode::is_utf8($out), "$file output is utf-8 flagged";
    like $out, qr/$author/, "$file includes author name correctly";
    like $out, qr/$place/, "$file includes place correctly";
    unless ($file =~ /(-wo-|-bom)/) {
        my $encoding = ($file =~ /(.*)\.tt/)[0];
        like $out, qr/encoding=$encoding/, "$file has encoding $encoding";
    }
}
