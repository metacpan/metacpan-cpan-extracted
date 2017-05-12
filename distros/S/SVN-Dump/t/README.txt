The test suite is written so as to make it easy to tests various
dump formats.

The t/dump directory contains various bits and pieces of both valid and
broken dumps. It contains several subdirectories:

    t/dump/full
        contains full dumps (such as those produced by svnadmin dump)
        the tests read the dump with SVN::Dump, and compare the dump
        produced by SVN::Dump to the original. Any difference is a bug
        in SVN::Dump.

    t/dump/records
        contains individual records (uuid, format, headers, revision,
        node, dir, etc)

    t/dump/property
        contains only property blocks

    t/dump/headers
        contains only header blocks

    t/dump/fail
        contains broken elements (record, headers, property or text blocks).
        The first line is actually a regular expression that should match
        the error message produced by SVN::Dump.


To add new dump excerpts to be tested, simply copy them in the relevant
directory.

