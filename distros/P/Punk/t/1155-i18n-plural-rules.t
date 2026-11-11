#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use Punk ();

# The plural rules t/1153 leaves alone: Czech and Slovak (one, few at 2-4,
# other), Lithuanian (one and few by the last digit, except the teens) and
# Romanian (few for zero and for 1-19 past the hundreds). Each number is
# asserted on its own, since a wrong form reads as grammatical.

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub cat {
    my ($tag, $json) = @_;
    open my $fh, '>:raw', File::Spec->catfile($dir, "$tag.json") or die $!;
    print $fh $json;
    close $fh;
}
my $forms = '{ "items": { "one": "one {count}", "few": "few {count}", "many": "many {count}", "other": "other {count}" } }';
cat($_ => $forms) for qw(en cs sk lt ro);

eval qq{
    package PRApp;
    use Punk;
    plugin 'I18n' => { dir => '$dir', default => 'en' };
    get '/n/:count' => sub {
        my \$c = shift;
        \$c->text(\$c->locale('items', count => \$c->param('count')));
    };
    1;
} or die $@;
my $app = PRApp->to_app;
sub say_n {
    my ($lang, $n) = @_;
    my $r = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => "/n/$n",
        QUERY_STRING   => '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
        HTTP_ACCEPT_LANGUAGE => $lang,
    });
    return $r->[2][0];
}
my %table = (
    cs => [ [ 1, 'one' ], [ 2, 'few' ], [ 4, 'few' ], [ 5, 'other' ], [ 0, 'other' ], [ 22, 'other' ] ],
    sk => [ [ 1, 'one' ], [ 3, 'few' ], [ 7, 'other' ] ],
    lt => [ [ 1, 'one' ], [ 21, 'one' ], [ 2, 'few' ], [ 9, 'few' ], [ 22, 'few' ],
            [ 10, 'other' ], [ 11, 'other' ], [ 12, 'other' ], [ 111, 'other' ], [ 0, 'other' ] ],
    ro => [ [ 1, 'one' ], [ 0, 'few' ], [ 2, 'few' ], [ 19, 'few' ], [ 101, 'few' ], [ 119, 'few' ],
            [ 20, 'other' ], [ 100, 'other' ], [ 120, 'other' ] ],
);
for my $lang (sort keys %table) {
    for my $case (@{ $table{$lang} }) {
        my ($n, $cat) = @$case;
        is(say_n($lang => $n), "$cat $n", "$lang $n is `$cat`");
    }
}

done_testing;
