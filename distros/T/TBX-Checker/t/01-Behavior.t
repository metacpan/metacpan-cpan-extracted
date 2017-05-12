#basic test file

use strict;
use warnings;
use Test::More 0.88;
plan tests => 6;
use TBX::Checker qw(check);
use FindBin qw($Bin);
use Path::Tiny;
use URI::file;

my $corpus_dir = path($Bin, 'corpus');
my $good_tbx = path($corpus_dir, 'good.tbx');
my $bad_tbx = path($corpus_dir, 'bad.tbx');

# testing with files is simple
test_all($good_tbx, $bad_tbx);

# testing with text requires replacing relative paths with
# absolute ones
my $good_text = $good_tbx->slurp;
my $bad_text = $bad_tbx->slurp;

my $core_dtd = 'TBXcoreStructV02.dtd';
my $xcs = 'small.xcs';
for($good_text, $bad_text){
    $_ =~ s/$core_dtd/URI::file->new_abs(path($corpus_dir, $core_dtd))/e;
    $_ =~ s/$xcs/URI::file->new_abs(path($corpus_dir, $xcs))/e;
}

test_all(\$good_text, \$bad_text);

sub test_all {
    my ($good_tbx, $bad_tbx) = @_;
    my ($passed, $messages) = check($good_tbx);
    ok($passed, 'good.tbx should check')
    	or note explain $messages;

    ($passed, $messages) = check($bad_tbx);
    ok(!$passed, q{bad.tbx shouldn't check});

    ($passed, $messages) = check($good_tbx, loglevel => 'FINE');
    ok($#$messages != 0, 'arguments passed on to jar');
}

#TODO: test failure for non-existent file and missing data arg
