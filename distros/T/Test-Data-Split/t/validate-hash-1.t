#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 4;

use Test::Data::Split;

use File::Temp qw/tempdir/;

use IO::All qw/ io /;

use Test::Differences (qw( eq_or_diff ));

{
    use DataSplitValidateHashTest1;

    my $dir = tempdir( CLEANUP => 1 );

    my $tests_dir = "$dir/t";

    my $data_obj = DataSplitValidateHashTest1->new;

    # TEST
    eq_or_diff( $data_obj->list_ids(), [qw(test_abc test_foo)],
        "Test...ValidateHash list_ids",
    );

    my $obj = Test::Data::Split->new(
        {
            target_dir  => "$tests_dir",
            filename_cb => sub {
                my ( $self, $args ) = @_;

                my $id = $args->{id};

                return "valgrind-$id.t";
            },
            contents_cb => sub {
                my ( $self, $args ) = @_;

                my $id   = $args->{id};
                my $data = $args->{data};

                return <<"EOF";
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use DataSplitHashTest;

@{['# TEST']}
DataSplitValidateHashTest1->new->run_id(qq#$id#, qq#$data#);

EOF
            },
            data_obj => $data_obj,
        }
    );

    # TEST
    ok( $obj, "Test...ValidateHash Object was initted." );

    $obj->run;

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/valgrind-test_abc.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use DataSplitHashTest;

@{['# TEST']}
DataSplitValidateHashTest1->new->run_id(qq#test_abc#, qq#prefix_FooBar#);

EOF
        'Test...ValidateHash Test for file test_abc',
    );

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/valgrind-test_foo.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use DataSplitHashTest;

@{['# TEST']}
DataSplitValidateHashTest1->new->run_id(qq#test_foo#, qq#prefix_JustAValue#);

EOF
        'Test...ValidateHash Test for file test_foo',
    );
}
