use strict;
use warnings;
use types;
our $VERSION = 0.004_000;

use Test2::V0;
use File::Find ();                    # for recursively searching directories
use IPC::Run3 qw(run3);               # for running external commands with captured I/O

# directories we do not want to descend into; by entry name, not full path
my arrayref::string $directories_exclude = [qw(
    .git
    .github
    .gitlab
    node_modules
    blib
    local
    tmp
    vendor
    .build
    _build-dir
    _Inline
)];

# build a hash for O(1) computational complexity exclusion checks during File::Find traversal
my hashref::integer $directories_exclude_hash = { map { $ARG => 1 } @{$directories_exclude} };

# this is an authors-only test, skip if not explicitly enabled by AUTHOR_TESTING or RELEASE_TESTING
if (not ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING})) {
    plan skip_all => 'author test; `export AUTHOR_TESTING=1` to run';  # skip all tests if env vars are not set
}

# allow overriding the CLI path via env var, default to `markdownlint-cli2`
my string $markdownlint_path = $ENV{MARKDOWNLINT_CLI2} || 'markdownlint-cli2';

# verify the linter is available; skip all tests if not installed or not runnable
{
    # buffers for capturing stdout and stderr
    my string $child_stdout = '';
    my string $child_stderr = '';

    # wrap call to run3() in eval{} block to contain OS errors if `markdownlint-cli2` executable is missing
    my boolean $ok = eval {
        # run linter with --help as a quick smoke test
        run3([$markdownlint_path, '--help'], \undef, \$child_stdout, \$child_stderr);
        1;  # return true if "run3()" succeeded
    };
    if (not $ok) {
        plan skip_all => 'markdownlint-cli2 executable not found; install it or `export MARKDOWNLINT_CLI2=/path/to/markdownlint-cli2`';
    }
}

# array to collect Markdown files found in the repository
my arrayref::string $markdown_filenames = [];

# DEV NOTE: explanation about our use of "File::Find::find()" below...
# 
# why "no_chdir => 1"?
# File::Find’s default is to chdir() into each directory before calling wanted(),
# which makes relative file tests depend on a moving cwd and complicates logs;
# with "no_chdir => 1", the process cwd never changes and $ARG in wanted()
# is the full path (same as $File::Find::name), so tests like "-f $ARG" are stable
# 
# what preprocess() sees and returns:
# @ARG contains basenames (entry names) of the current directory;
# we explicitly skip dot entries '.' and '..' for clarity, and prune by basename
# using $directories_exclude_hash, so names like '_build-dir' are excluded at
# any depth, either root or nested;
# we return both the files and directories we keep; returning files is not a problem,
# File::Find still passes them to wanted(), where we apply the '.md'/'.markdown' filter
# 
# what wanted() does:
# because "no_chdir => 1" is set, the value of $ARG is a full path;
# thus, we can test "-f $ARG" and the "/\.(?:md|markdown)\z/i" regex directly on $ARG;
# if it matches, we push $File::Find::name (equivalent path) onto $markdown_filenames

# walk the repository to collect Markdown files, excluding unwanted dirs
File::Find::find(
    {
        no_chdir => 1,  # always use full pathnames in $File::Find::name

        # preprocess() runs once per directory; @ARG contains entry *names* (basenames)
        preprocess => sub {
#            diag 'in preprocess(), dir = \'' . $File::Find::dir . '\'' . "\n";

            my arrayref::string $entries_keep = [];  # entries we will keep and allow File::Find to process
            my integer $original_count = scalar @ARG;

            foreach my string $entry_name (@ARG) {
#                diag 'in preprocess(), considering entry name = \'' . $entry_name . '\'' . "\n";

                # ignore dot entries explicitly
                if ( ($entry_name eq '.') || ($entry_name eq '..') ) {
#                    diag 'in preprocess(), dot entry, skipping' . "\n";
                    next;
                }

                # exclude by basename anywhere in the tree (e.g., '_build-dir' at any depth)
                if (exists $directories_exclude_hash->{$entry_name}) {
#                    diag 'in preprocess(), entry excluded by name, skipping' . "\n";
                    next;
                }

                # keep everything else (files and directories)
#                diag 'in preprocess(), entry kept for traversal' . "\n";
                push @{$entries_keep}, $entry_name;
            }

#            diag 'in preprocess(), kept ' . scalar(@{$entries_keep}) . ' of ' . $original_count . ' entries' . "\n";

            # return the filtered list of entries for this directory
            return @{$entries_keep};
        },

        wanted => sub {
#            diag 'in wanted(), have $ARG = \'' . $ARG . '\'' . "\n";

            # only consider regular files
            if (not -f $ARG) {
#                diag 'in wanted(), not a regular file, skipping' . "\n";
                return;
            }

            # only consider files with '.md' or '.markdown' extension (case-insensitive)
            if (not ($ARG =~ /\.(?:md|markdown)\z/i)) {
#                diag 'in wanted(), not a \'.md\' or \'.markdown\' file, skipping' . "\n";
                return;
            }

            # save the full path for later linting
#            diag 'in wanted(), yes a \'.md\' or \'.markdown\' file, saving' . "\n";
            push @{$markdown_filenames}, $File::Find::name;
        },
    },
    '.',  # start search from current directory
);

# report which directories are excluded and which files are included; helps debugging in CI logs
diag 'Excluded directories: ' . join(', ', @{$directories_exclude}) if @{$directories_exclude};
if (@{$markdown_filenames}) {
    diag 'Markdown files found for linting:';  # print list of files found
    diag (' - ' . $ARG) for @{$markdown_filenames};
} else {
    # fail fast on misconfiguration
    diag 'No Markdown files found for linting.';
    skip_all 'No Markdown files found for linting; check ignore list or working directory';
}

# sort Markdown files to ensure deterministic order
$markdown_filenames = [sort @{$markdown_filenames}];

# plan the number of tests equal to the number of Markdown files found
plan tests => scalar @{$markdown_filenames};

# run markdownlint-cli2 on each Markdown file individually
for my string $markdown_filename (@{$markdown_filenames}) {
    # buffers for capturing stdout and stderr
    my string $child_stdout = '';
    my string $child_stderr = '';

    # wrap call to "run3()" in "eval" to contain OS errors if `markdownlint-cli2` executable is missing
    my boolean $ok = eval {
        # use "run3()" to actually call external `markdownlint-cli2` command;
        # DEV NOTE: explicitly include the name of the default config file '.markdownlint-cli2.jsonc' because
        # it is necessary (not optional) for tests to pass, thus if it is missing we will get a helpful error message;
        # first argument to run3() must be single concatenated string containing entire command to run,
        # does not work correctly if passing via arrayref of separated command elements
        run3(($markdownlint_path . ' ' . $markdown_filename . ' ' . '--config .markdownlint-cli2.jsonc'), \undef, \$child_stdout, \$child_stderr);
        1;  # return true if "run3()" succeeded
    };

    # compute the child process' 8-bit integer exit status AKA exit value AKA exit code
    my integer $child_exit_status = $CHILD_ERROR >> 8;

    # combine stdout and stderr into one string
    my string $child_stdout_stderr = ($child_stdout // '') . ($child_stderr // '');

    # success if run3 succeeded, exit status 0, and output contains expected summary;
    # DEV NOTE: must use "&&" instead of "and" below, in order to correctly catch test failures
    my boolean $pass =
        $ok &&
        ($child_exit_status == 0) &&
        ($child_stdout_stderr =~ /Linting:\s+1\s+file\(s\)/s) &&
        ($child_stdout_stderr =~ /Summary:\s+0\s+error\(s\)/s);

    # record test result with error output if it failed
    ok($pass, ('markdownlint clean: ' . $markdown_filename)) or
    diag 
        '---- markdownlint-cli2 output for ' . $markdown_filename . '----' . "\n" .
        $child_stdout_stderr . "\n" .
        'exit_status = ' . $child_exit_status . "\n" .
        '--------------------------------------------------' . "\n";
}
