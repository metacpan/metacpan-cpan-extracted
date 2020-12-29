use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Hook::Output::Tiny;
use STEVEB::Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $d = 't/data/work';
my $f = 't/data/orig/No.pm';

my @valid = ("$d/One.pm", "$d/Two.pm", "$d/Three.pm");

my $h = Hook::Output::Tiny->new;

copy_module_files();

# bad params
{
    # no version
    is eval {
        bump_version();
        1
    }, undef, "no supplied version croaks ok";
    like $@, qr/version parameter/, "...and error is sane";

    # invalid version
    is eval {
        bump_version('aaa');
        1
    }, undef, "invalid version croaks ok";
    like $@, qr/The version number/, "...and error is sane";

    # invalid fs entry
    is eval {
        bump_version('1.00', 'asdf');
        1
    }, undef, "invalid file system entry croaks ok";
    like $@, qr/File system.*invalid/, "...and error is sane";
}

# dry run
{
    $h->flush;

    $h->hook;
    my $data = bump_version('-3.77', $d);
    $h->unhook;

    my @out = $h->stdout;
    my @err = $h->stderr;

    is scalar @out, 2, "proper stdout count ok";
    is scalar @err, 2, "proper warning count ok";

    like $out[1], qr/Dry run/, "dry run output ok";

    is grep(/No.pm.*\$VERSION definition/, @err), 1, "No.pm croaks about no ver def ok";
    is grep(/Bad\.pm.*valid version/, @err), 1, "Bad.pm croaks about no valid ver ok";

    is $data->{"$d/One.pm"}{from}, '0.01', "One has proper from ver";
    is $data->{"$d/One.pm"}{to},   '3.77', "One has proper to ver";
    is $data->{"$d/One.pm"}{dry_run}, 1, "One has dry_run set ok";

    is $data->{"$d/Two.pm"}{from}, '2.00', "Two has proper from ver";
    is $data->{"$d/Two.pm"}{to},   '3.77', "Two has proper to ver";
    is $data->{"$d/Two.pm"}{dry_run}, 1, "Two has dry_run set ok";

    is $data->{"$d/Three.pm"}{from}, '3.00', "Three has proper from ver";
    is $data->{"$d/Three.pm"}{to},   '3.77', "Three has proper to ver";
    is $data->{"$d/Three.pm"}{dry_run}, 1, "Three has dry_run set ok";

    for (keys %$data) {
        is keys %{ $data->{$_} }, 4, "Proper key count for $_";
    }
}

# Bad/No warnings check
{
    $h->flush;

    $h->hook('stderr');
    my $data = bump_version('-3.77', $d);
    $h->unhook('stderr');

    my @err = $h->stderr;

    is scalar @err, 2, "proper warning count ok";

    is grep(/No.pm.*\$VERSION definition/, @err), 1, "No.pm croaks about no ver def ok";
    is grep(/Bad\.pm.*valid version/, @err), 1, "Bad.pm croaks about no valid ver ok";

    is $data->{"$d/One.pm"}{from}, '0.01', "One has proper from ver";
    is $data->{"$d/One.pm"}{to},   '3.77', "One has proper to ver";

    is $data->{"$d/Two.pm"}{from}, '2.00', "Two has proper from ver";
    is $data->{"$d/Two.pm"}{to},   '3.77', "Two has proper to ver";

    is $data->{"$d/Three.pm"}{from}, '3.00', "Three has proper from ver";
    is $data->{"$d/Three.pm"}{to},   '3.77', "Three has proper to ver";
}

# files (dry run)
{

    for my $file (@valid) {
        my $data = bump_version('-9.11', $file);

        is keys %$data, 1, "returned href has proper number of keys ok";
        is exists $data->{$file}, 1, "$file is a key of the returned href ok";
        is keys %{ $data->{$file} }, 4, "href $file entry has proper key count ok";
        is exists $data->{$file}{content}, 1, "$file entry has a 'content' key ok";
    }
}

# files & content (live run)
{

    my $data = bump_version(9.12, $d);

    for my $file (@valid) {
        is keys %$data, 3, "returned href has proper number of keys ok";
        is exists $data->{$file}, 1, "$file is a key of the returned href ok";
        is keys %{$data->{$file}}, 4, "href $file entry has proper key count ok";
        is exists $data->{$file}{content}, 1, "$file entry has a 'content' key ok";
        is $data->{$file}{dry_run}, 0, "$file has dry_run disabled ok";
        is $data->{$file}{to}, '9.12', "$file has proper ver set ok";

        my $c = file_scalar($file);
        is $data->{$file}{content}, $c, "$file content matches updated file ok";
    }

    is $data->{'t/data/work/One.pm'}{from}, '0.01', "One.pm from ver ok";
    is $data->{'t/data/work/Two.pm'}{from}, '2.00', "Two.pm from ver ok";
    is $data->{'t/data/work/Three.pm'}{from}, '3.00', "Three.pm from ver ok";
}

unlink_module_files();
verify_clean();

done_testing();

