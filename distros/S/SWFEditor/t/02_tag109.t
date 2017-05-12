use t::Utils;
use Test::More;
use SWFEditor;

note('print_tag_data(): test');

my $expect = <<"EXPECT";
tag=SetBackgroundColor(9)  length=3
EXPECT

SKIP: {
    eval { require Capture::Tiny };
    skip 'Capture::Tiny not installed', 1 if ($@);
    tests {
        my $d1    = get_file_contents('/tag/textvar.tag.0');
        my $swfed = SWFEditor->new();
        my $got   = Capture::Tiny::capture(sub{
            $swfed->print_tag_data(\$d1);
        });
        is($got, $expect, '');
    };
}

SKIP: {
    eval { require Capture::Tiny };
    skip 'Capture::Tiny not installed', 1 if ($@);
    tests {
        my $d1    = get_file_path('/tag/textvar.tag.0');
        my $swfed = SWFEditor->new();
        my $got   = Capture::Tiny::capture(sub{
            $swfed->print_tag_data($d1);
        });
        is($got, $expect, '');
    };
}

done_testing();
