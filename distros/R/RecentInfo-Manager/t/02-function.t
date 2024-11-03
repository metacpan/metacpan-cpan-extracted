#!perl
use 5.020;
use Test2::V0 -no_srand;
use Time::HiRes 'sleep';
use RecentInfo::Manager 'add_recent_file', 'remove_recent_file', 'recent_files';
use experimental 'try', 'signatures';
use stable 'postderef';

use File::Temp 'tempfile';
use Data::Dumper;

my $name;
#my ($fh, $recent_tempname) = tempfile;
my $recent_tempname = $0;
my $os;
{
    if( $^O =~ /MSWin32|cygwin/ ) {
        # On Windows, we only have the special folder
        require Win32;
        $name = Win32::GetFolderPath(Win32::CSIDL_RECENT());
        $os = 'Windows';
    } else {
        # Elsewhere we can use a tempfile
        $os = 'Unix';
        (my( $fh ), $name ) = tempfile;
        close $fh;
        END {
            unlink $name if defined $name;
        };
    };
};
note "Recent entries live under '$name'";
# Do some roundtrip tests
my @initial = recent_files(undef, { recent_path => $name });
if( $os eq 'Unix' ) {
    # Hrr, not on Windows ...
    is \@initial, [], "We start out with an empty recently used list";
} else {
    isnt \@initial, [], "We have some previous recent files";
}

sub contains_file( $fn, $list ) {
    return [grep { $_ =~ /\Q$fn\E/ } $list->@* ]
}

note "Adding $recent_tempname to recent files";
add_recent_file($recent_tempname, undef, { recent_path => $name });
sleep 0.1;

my @new = recent_files(undef, { recent_path => $name });
my $fullpath = File::Spec->rel2abs($recent_tempname);
is contains_file($fullpath, \@new), [$fullpath], "We added one file"
    or diag Dumper \@new;

if( $os eq 'Unix' ) {

    my @other = recent_files(undef, { app => 'foo', recent_path => $name });
    is \@other, [], "Recent files for another program are empty with appname initialized";
    sleep 0.1;
    
    @other = recent_files({ app => 'bar' }, { recent_path => $name });
    is \@other, [], "Recent files for another program are empty with appname as parameter";
    sleep 0.1;
} else {
    SKIP: {
        skip "App name is ignored on Windows", 2;
    }
}

add_recent_file([$recent_tempname,$recent_tempname], undef, { recent_path => $name });
@new = recent_files(undef, { recent_path => $name });
is contains_file($fullpath, \@new), [$fullpath], "Adding the same file multiple times keeps the number the same";
sleep 0.1;

remove_recent_file([$recent_tempname,$recent_tempname], { recent_path => $name });
@new = recent_files(undef, { recent_path => $name });
is contains_file($fullpath, \@new), [], "We removed the file";
sleep 0.1;

done_testing;
