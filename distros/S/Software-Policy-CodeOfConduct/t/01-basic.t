
use v5.20;
use warnings;

use Test2::V0;
use Path::Tiny 0.119 qw( path tempdir );

use Test::File::ShareDir -share => {
    -dist => {
        "Software-Policy-CodeOfConduct" => "share"
    }
};

use Software::Policy::CodeOfConduct;

for my $file (qw( Contributor_Covenant_1.4 Contributor_Covenant_2.0 Contributor_Covenant_2.1 )) {

    subtest $file => sub {

        ok my $policy =
          Software::Policy::CodeOfConduct->new( contact => 'bogon@example.com', name => "Bogomip", policy => $file, text_columns => 0 ),
        'constructor';

        ok $policy->template_path, "template_path";

        ok my $text = $policy->fulltext, "fulltext";

        my $re = quotemeta( $policy->name );
        like $text, qr/\b${re}\b/, "text has the name";

        is $policy->text, $text, "text is alias";

        note $text;

        is $policy->filename, "CODE_OF_CONDUCT.md", "filename";

        my $dir = tempdir();
        ok my $path = $policy->save($dir), "save";

        ok -e $path, "file ${path} exists";

        is $path, path( $dir, $policy->filename ), "expected path";

        is $path->slurp_raw, $policy->text, "expected content";

    };

}

done_testing;
