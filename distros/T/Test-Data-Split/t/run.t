#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

package DataObj;

# We cannot load List::MoreUtils here because it compiles prototypes which
# causes tests to erroneously pass.
#
# use List::MoreUtils qw/notall/;

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _hash
{
    my $self = shift;

    if (@_)
    {
        $self->{_hash} = shift;
    }

    return $self->{_hash};
}

sub _init
{
    my ($self, $args) = @_;

    my $hash_ref = $args->{hash};

    foreach my $k (keys (%$hash_ref))
    {
        if ($k !~ /\A[A-Za-z_\-0-9]{1,80}\z/)
        {
            die "Invalid key in hash reference. All keys must be alphanumeric plus underscores and dashes.";
        }
    }

    $self->_hash($hash_ref);

    return;
}

sub list_ids
{
    my ($self) = @_;

    return [ sort { $a cmp $b } keys(%{$self->_hash}) ];
}

sub lookup_data
{
    my ($self, $id) = @_;

    return $self->_hash->{$id};
}

package main;

use Test::More tests => 12;

use Test::Data::Split;

use File::Temp qw/tempdir/;

use IO::All qw/ io /;

use Test::Differences (qw( eq_or_diff ));

{

    my $dir = tempdir( CLEANUP => 1);

    my $tests_dir = "$dir/t";

    my %hash =
    (
        a => { more => "Hello"},
        b => { more => "Jack"},
        c => { more => "Sophie"},
        d => { more => "Danny"},
        'e100_99' => { more => "Zebra"},
    );

    my $data_obj = DataObj->new(
        {
            hash => (\%hash),
        }
    );

    # TEST
    eq_or_diff(
        $data_obj->list_ids(),
        [ qw(a b c d e100_99) ],
        "list_ids",
    );


    my $obj = Test::Data::Split->new(
        {
            target_dir => "$tests_dir",
            filename_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};

                return "valgrind-$id.t";
            },
            contents_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};

                return <<"EOF";
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
@{['use']} MyTest;

@{['# TEST']}
MyTest->run_id(qq#$id#);

EOF
            },
            data_obj => $data_obj,
        }
    );

    # TEST
    ok ($obj, "Object was initted.");

    $obj->run;

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/valgrind-a.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
@{['use']} MyTest;

@{['# TEST']}
MyTest->run_id(qq#a#);

EOF
        'Test for file a',
    );

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/valgrind-e100_99.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
@{['use']} MyTest;

@{['# TEST']}
MyTest->run_id(qq#e100_99#);

EOF
        'Test for file e100_99',
    );
}

{
    use DataSplitHashTest;

    my $dir = tempdir( CLEANUP => 1);

    my $tests_dir = "$dir/t";

    my $data_obj = DataSplitHashTest->new;

    # TEST
    eq_or_diff(
        $data_obj->list_ids(),
        [ qw(a b c d e100_99) ],
        "Test::Data::Split::Backend::Hash list_ids",
    );

    my $obj = Test::Data::Split->new(
        {
            target_dir => "$tests_dir",
            filename_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};

                return "valgrind-$id.t";
            },
            contents_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};

                return <<"EOF";
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use DataSplitHashTest;

@{['# TEST']}
DataSplitHashTest->new->run_id(qq#$id#);

EOF
            },
            data_obj => $data_obj,
        }
    );

    # TEST
    ok ($obj, "Test::Data::Split::Backend::Hash Object was initted.");

    $obj->run;

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/valgrind-a.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use DataSplitHashTest;

@{['# TEST']}
DataSplitHashTest->new->run_id(qq#a#);

EOF
        'Test::Data::Split::Backend::Hash Test for file a',
    );

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/valgrind-e100_99.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use DataSplitHashTest;

@{['# TEST']}
DataSplitHashTest->new->run_id(qq#e100_99#);

EOF
        'Test::Data::Split::Backend::Hash Test for file e100_99',
    );
}

{
    my %hash =
    (
        a => { more => "Hello"},
        b => { more => "Jack"},
        c => { more => "Sophie"},
        d => { more => "Danny"},
        'e100_99' => { more => "Zebra"},
    );

    my $data_obj = DataObj->new(
        {
            hash => (\%hash),
        }
    );

    my $dir = tempdir( CLEANUP => 1);

    my $tests_dir = "$dir/t";

    # TEST
    eq_or_diff(
        $data_obj->list_ids(),
        [ qw(a b c d e100_99) ],
        "Test::Data::Split::Backend::Hash list_ids",
    );

    my $obj = Test::Data::Split->new(
        {
            target_dir => "$tests_dir",
            filename_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};

                return "id_with_data-$id.t";
            },
            contents_cb => sub {
                my ($self, $args) = @_;

                my $id = $args->{id};
                my $data = $args->{data};

                return <<"EOF";
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
@{['use']} My::TestData;

@{['# TEST']}
My::TestData->new->run(qq#$id#, qq#$data->{more}#);

EOF
            },
            data_obj => $data_obj,
        }
    );

    # TEST
    ok ($obj, "Test::Data::Split::Backend::Hash Object was initted.");

    $obj->run;

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/id_with_data-a.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
@{['use']} My::TestData;

@{['# TEST']}
My::TestData->new->run(qq#a#, qq#Hello#);

EOF
        'Test that the data gets passed',
    );

    # TEST
    eq_or_diff(
        [ io->file("$tests_dir/id_with_data-e100_99.t")->all ],
        [ <<"EOF" ],
#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
@{['use']} My::TestData;

@{['# TEST']}
My::TestData->new->run(qq#e100_99#, qq#Zebra#);

EOF
        'Pass the Data Test for file e100_99',
    );
}

