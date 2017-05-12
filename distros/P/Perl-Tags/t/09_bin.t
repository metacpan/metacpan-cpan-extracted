use strict; use warnings;
use Test::More;

use File::Spec::Functions qw(catfile);
use File::Temp;
use FindBin;

use Capture::Tiny 'capture';

subtest 'Command line ok' => sub {
    my ($stdout, $stderr, $exit) = capture {
        system $^X, "$FindBin::Bin/../bin/perl-tags";
    };
    ok ! $exit, 'command successful';
    like $stdout, qr/Usage: perl-tags <options>/, 'Usage displayed as expected';
    is $stderr, '', 'No stderr';

    ($stdout, $stderr, $exit) = capture {
        system $^X, "$FindBin::Bin/../bin/perl-tags", '-v';
    };
    ok ! $exit, 'command successful';
    is $stderr, '', 'No stderr';
    like $stdout, qr/perl-tags v. [0-9.]+ \(Perl Tags v. [0-9.]+\)/, 'Version command as expected';
};

subtest 'check get_files method' => sub {
    use lib "$FindBin::Bin/../lib";
    require App::Perl::Tags;

    my $app = App::Perl::Tags->new( paths => [ $FindBin::Bin ] );
    my @files = $app->get_files;
    is_deeply $app->{prune}, ['.git', '.svn'], 'Expected value for --prune';
    ok @files > 10, 'Sufficient number of files returned';
    ok ((scalar grep /Moosy/, @files), 'Contains expected files');
    ok ((scalar grep /\.t$/, @files), 'Contains expected files');

    $app = App::Perl::Tags->new( paths => [ $FindBin::Bin ], prune => [ 'Moosy' ] );
    my @pruned_files = $app->get_files;
    ok @pruned_files > 10, 'Sufficient number of files returned';
    ok ((! scalar grep /Moosy/, @pruned_files), 'Pruned Moosy files');

    is_deeply
        [ grep ! /Moosy/, sort @files ],
        [ sort @pruned_files ],
        'Expected files after pruning';
};

for my $no_vars (qw(-no-vars --no-vars -no-variables --no-variables)) {
    subtest "check $no_vars options" => sub {
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        diag "working in $tmpdir" if 0;
        my $tags_file = catfile($tmpdir, 'perltags');
        my $input_file = catfile($tmpdir, "My.pm");
        IO::File->new($input_file, "w")->print(<<'MY_PM');
            package My;
            our $xyzzy;
MY_PM
        my ($stdout, $stderr, $exit) = capture {
            system $^X, "$FindBin::Bin/../bin/perl-tags", 
                '-o', $tags_file, $no_vars, $input_file;
        };
        ok ! $exit, 'command successful';
        is $stderr, '', 'No stdout';
        is $stderr, '', 'No stderr';
        ok grep_file($tags_file, qr/package/), "$tags_file contains package";
        ok !grep_file($tags_file, qr/xyzzy/),
            "$tags_file does not contain variable name";
    };
}

for my $files_opt (qw(-L -files)) {
    subtest "check $files_opt option: file" => sub {
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        diag "working in $tmpdir" if 0;
        my $tags_file = catfile($tmpdir, 'perltags');
        my $pm_file = catfile($tmpdir, "My.pm");
        IO::File->new($pm_file, "w")->print(<<'MY_PM');
            package My;
            our $xyzzy;
MY_PM
        my $input_file = catfile($tmpdir, "list");
        IO::File->new($input_file, "w")->print($pm_file);
        my ($stdout, $stderr, $exit) = capture {
            system $^X, "$FindBin::Bin/../bin/perl-tags",
                '-o', $tags_file, $files_opt, $input_file;
        };
        ok ! $exit, 'command successful';
        is $stderr, '', 'No stdout';
        is $stderr, '', 'No stderr';
        ok grep_file($tags_file, qr/package/), "$tags_file contains package";
    };
}

for my $files_opt (qw(-L -files)) {
    subtest "check $files_opt option: stdin" => sub {
        my $tmpdir = File::Temp->newdir(CLEANUP => 1);
        diag "working in $tmpdir" if 0;
        my $tags_file = catfile($tmpdir, 'perltags');
        my $pm_file = catfile($tmpdir, "My.pm");
        IO::File->new($pm_file, "w")->print(<<'MY_PM');
            package My;
            our $xyzzy;
MY_PM
        my ($stdout, $stderr, $exit) = capture {
            system "echo $pm_file | $^X $FindBin::Bin/../bin/perl-tags ".
                   "-o $tags_file $files_opt -";
        };
        ok ! $exit, 'command successful';
        is $stderr, '', 'No stdout';
        is $stderr, '', 'No stderr';
        ok grep_file($tags_file, qr/package/), "$tags_file contains package";
    };
}

done_testing;

sub grep_file {
    my ($filename, $re) = @_;
    grep /$re/, IO::File->new($filename)->getlines;
}
