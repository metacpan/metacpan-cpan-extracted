# Reporting a Bug

If you found a bug, please create a Github issue with as much
information as possible.

# Requesting a Feature

It is the intention of the author of this module to add helpful
functions that may be used to make creating C functions parallelized
with OpenMP more idiomatic for use in Perl code.

If you have an idea, you may submit a feature request; but be as
descriptive as possible. It is even better if you have an example
implementation in the form of a Perl script. You may create an issue,
then submit a Pull Request or attach the code in the Issue you create.

# Submitting a Pull Request

Please fork the repository. It is easiest to track if you create a
branch named after an Issue you create on your own fork, then once
you have code changes for wish you'd like feedback, submit a PR against
the master branch of the main repository.

If the PR is not "complete" or you're simply seeking feedback, please
mark the PR as a draft.

## Definition of "Complete" PR

A complete PR consists of the changes, assuming the addition of the C
function in the header file, and a test added in the `t/` directory.

If you do not have a test, please provide a Perl script that may be
used to exercise your new function or feature; if it is a change to an
existing function, please update the associated tests - especially if
this is to fix some kind of bug; so that we may be able to test for
regressions.

### `dist.ini` changes 

If there are additional module requirements or changes needed to the
`dist.ini` file (`Dist::Zilla`,) please include those changes and some
information explaining what the changes to this file affects.

### Version and `Changes` changes

Please update the version's minor number and include an entry in
the `Changes` file that describes the changes. Part of the review
process will be to adjust these, but it helps if this informatiomn is
present. 

# Suggested Workflow

It can be someone cumbersome to work with the C file that contains
the macros and functions. Below are some tips to help make this process
easier:

1. Dist::Zilla is your friend; it's fat and bloated as all get-out; but
it makes development much easier. Use it. 

2. Start with a driver script; better yet, start with the test script in
`./t`; new functions and macros should be added under the `Inline::C`
section. It is much easier to do iterative testing and development if the
C code is right there in the script. Once you have verified that the C
function and/or macro works, add it to the header file in share, and test
with `dzil test`.

## Debugging with the `.tar.gz` file from `dzil build`

Do not forget, `cpanm` can install based on a `tar.gz` file, which is what
the `dzil build` command creates. So you can do something like this to test
a local install:

1. `cpanm -U OpenMP::Simple` # removes the module if it's been _installed_
2. `dzil build`
3. `cpanm OpenMP-Simple-VERSION.tar.gz` 

Note: if necessary, you may invoke `cpanm`'s `--notest` and `--force` flags
if this is necessary for your testing or debugging situation.

# Making a Release

You will not have to do this, but note that the `Makefile` is for making
releases. Normal contributors will not need to use the included `Makefile`.

For general information the process is:

1. `make prepare`
2. `git commit -a -m "rolling VERSION"`
3. `git tag VERSION`
4. `git push origin master`
5. `git push origin VERSION`
6. `dzil release`

