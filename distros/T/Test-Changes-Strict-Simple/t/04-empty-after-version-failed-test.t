use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::Changes::Strict::Simple -empty_line_after_version => 1;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp qw(tempdir);
use Local::Test::Helper qw(:all);



{
  note("missing Changes file");
  my $non_existing_file = 'this-file-does-not-exist';
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("The '$non_existing_file' file does not exist");
  changes_strict_ok(changes_file => 'this-file-does-not-exist');
  test_test("fail works");
}

{
  note("Changes file is a directory, not a file");
  my $dir = tempdir(CLEANUP => 1);
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("The '$dir' file is not a readable text file");
  changes_strict_ok(changes_file => $dir);
  test_test("fail works");
}

{
  note("Changes file is empty");
  my $fname = write_changes(q{});
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("The '$fname' file empty");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
}

{
  note("No newline at end of file");
  my $fname = write_changes('Revision history for distribution Foo-Bar-Baz');
  test_out("not ok 1 - Changes file passed strict checks");
  test_fail(+2);
  test_diag("'$fname': no newline at end of file");
  changes_strict_ok(changes_file => $fname);
  test_test("fail works");
}

{
  note("Wrong title");
  {
    note("Malformed title 1");
    my $fname = write_changes("Revision history for Foo-Bar-Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Malformed title 2");
    my $fname = write_changes("Revision history for module Foo-Bar-Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Malformed title 3");
    my $fname = write_changes("Revision history for distribution Foo::Bar::Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Malformed title 4");
    my $fname = write_changes("Revision history for distribution Foo-Bar::Baz\n");
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Missing title");
    my $fname = write_changes(<<'EOF');
0.01 2024-02-28

  - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Missing or malformed 'Revision history ...' at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
}


{
  note("Non-space white characters");
  {
    note("1 non-space white character");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 2024-02-28

\t- Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Non-space white character found at line 5");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Multiple non-space white characters");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-15

  -\tAnother release.

0.01 2024-02-28

\t\r- Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Non-space white character found at lines 5, 9");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
}


{
  note("Trailing blanks");
  my @changes = ("Revision history for distribution Foo-Bar-Baz",  # 0 - line  1
                 "",                                               # 1 - line  2
                 "0.02 2024-03-01",                                # 2 - line  3
                 "",                                               # 3 - line  4
                 "  - Bugfix.",                                    # 4 - line  5
                 "",                                               # 5 - line  6
                 "0.01 2024-02-28",                                # 6 - line  7
                 "",                                               # 7 - line  8
                 "  - Initial release.",                           # 8 - line  9
                 ""                                                # 9 - line 10
                );
  {
    note("Trailing blanks in title line");
    my @test_input = @changes;
    $test_input[0] .= "  ";
    my $fname = write_changes(join("\n", @test_input));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Trailing white character at line 1");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Trailing blanks in empty line");
    my @test_input = @changes;
    $test_input[3] .= "  ";
    my $fname = write_changes(join("\n", @test_input));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Trailing white character at line 4");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Trailing blanks in multiple lines");
    my @test_input = @changes;
    $test_input[$_] .= "  " for (1, 2, 4);
    my $fname = write_changes(join("\n", @test_input));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Trailing white character at lines 2, 3, 5");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("Trailing blanks and non-blank white chars in multiple lines");
    my @test_input = @changes;
    $test_input[1] .= "\t ";
    $test_input[2] .= "    ";
    substr($test_input[4], 0, 1) = "\t";
    substr($test_input[8], 0, 1) = "\t";
    $test_input[8] .= " ";
    my $fname = write_changes(join("\n", @test_input));
    my $diag =
      "Non-space white character found at lines 2, 5, 9" .
      ". " .
      "Trailing white character at lines 2, 3, 9";
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag($diag);
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
  {
    note("4 trailing empty lines");
    my $fname = write_changes(join("\n", (@changes, ("") x 4)));
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("more than 3 empty lines at end of file");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
}


{
  note("check changes");
  {
    note("missing dot at end of line");
    my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus
  - Donec quam felis.

0.01 2024-02-28

  - Initial release

EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+3);
    test_diag("Line 8: missing dot at end of line");
    test_diag("Line 13: missing dot at end of line");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("unexpected empty lines");
    {
      note("unexpected empty line after title");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz


0.02 2024-03-01

  - Initial release

EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 3: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
    {
      note("unexpected empty line after version line");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01


  - Initial release

EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 5: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }

    {
      note("unexpected empty line between item lines");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.

  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 6: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }

    {
      note("unexpected empty line between item line and continuation");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.

    Donec sodales sagittis magna.
  - Donec quam felis.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 9: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }

    {
      note("unexpected empty line between item line and version line");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.02 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.



0.01 2024-02-28

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 10: unexpected empty line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
  }

  {
    note("unexpected version line");
    {
      note("unexpected version line immediately after title line");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz
0.02 2024-03-01

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 2: unexpected version line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }

    {
      note("unexpected version line immediately after version line");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-04-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.

0.02 2024-03-10
0.01 2024-02-28

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 12: unexpected version line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }

    {
      note("unexpected version line after empty line after version line");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-04-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.

0.02 2024-03-10

0.01 2024-02-28

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 13: unexpected version line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
  }

  {
    note("Version line check");
    {
      note("Not exactly two values");
      {
        note("Version, but no date");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: not exactly two values");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }
      {
        note("No version, but a date");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

2024-04-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: not exactly two values");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }
    }

    {
      note("invalid version");
      {
        note("too many dots");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03.5.9 2024-04-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: 0.03.5.9: invalid version");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }
      {
        note("heading 'v'");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

v0.03 2024-04-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: v0.03: invalid version");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }
    }
  }

  {
    note("Invalid date");
    {
      note("wrong format");
      {
        note("wrong format: separator");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024/04/01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: 2024/04/01: invalid date: wrong format");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }

      {
        note("wrong format: too many digits");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-004-01

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: 2024-004-01: invalid date: wrong format");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }
    }

    {
      note("Non-existent date");
      {
        note("35 May");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-05-35

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: '2024-05-35': invalid date");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }

      {
        note("29 February, but not a leap year");
        my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2025-02-29

  - Bugfix.
EOF
        test_out("not ok 1 - Changes file passed strict checks");
        test_fail(+2);
        test_diag("Line 3: version check: '2025-02-29': invalid date");
        changes_strict_ok(changes_file => $fname);
        test_test("fail works");
      }
    }
    {
      note("future date");
      my $next_year = (localtime)[5] + 1900 + 1;
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 $next_year-04-03

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 3: version check: $next_year-04-03: date is in the future.");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
    {
      note("before Perl era");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.01 1965-04-03

  - Initial release.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 3: version check: 1965-04-03: before Perl era");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
  }

  {
    note("unexpected item line");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

  - Initial release.

0.03 2025-04-03

  - Bugfix.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 3: unexpected item line");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }

  {
    note("invalid item content");
    {
      note("empty item");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  -
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 6: invalid item content");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
    }

    {
      note("no space after dash");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  -Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 6: invalid item content");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
    }

    {
      note("more than 1 space after dash");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  -   Donec quam felis.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("Line 9: invalid item content");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
    }
  }

  {
    note("item line: no indentation / wrong indentation");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix. Donec sodales sagittis magna.
- Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
    - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.

0.01 2024-02-28

 - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+4);
    test_diag("Line 6: no indentation");
    test_diag("Line 9: wrong indentation");
    test_diag("Line 14: wrong indentation");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
  {
    note("unexpected item continuation");
    {
      note("immediately after title");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz
  Donec sodales sagittis magna.

0.03 2025-04-03

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 2: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
    {
      note("after empty line after title");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

  Donec sodales sagittis magna.

0.03 2025-04-03

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 3: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
    {
      note("immediately after version line");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03
  Donec sodales sagittis magna.

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 4: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
    {
      note("after empty line after version line");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  Donec sodales sagittis magna.

  - Bugfix.
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Line 5: unexpected item continuation");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
  }
  {
    note("item continuation: wrong indentation");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
  ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.
  - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.
      Donec sodales sagittis magna.

0.01 2024-02-28

  - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+3);
    test_diag("Line 7: wrong indentation");
    test_diag("Line 11: wrong indentation");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
  {
    note("Unexpected end of file");
    {
      note("EOF after title line");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Unexpected end of file");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
    {
      note("EOF after version line");
      my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

0.03 2025-04-03

EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+2);
      test_diag("Unexpected end of file");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
  }

  {
    note("combined");
    {
      note("missing dot at end of line / unexpected EOF");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
  ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus
  - Donec quam felis.
  Sed consequat, leo eget bibendum sodales, augue velit cursus nunc

0.02 2024-02-28

  - Some changes

0.01 2024-02-25

 - First release
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+6);
      test_diag("Line 7: wrong indentation");
      test_diag("Line 8: missing dot at end of line");
      test_diag("Line 10: wrong indentation; missing dot at end of line");
      test_diag("Line 14: missing dot at end of line");
      test_diag("Line 18: wrong indentation; missing dot at end of line");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
    {
      note("missing dot at end of line / unexpected EOF");
      my $fname = write_changes(<<'EOF');
Revision history for distribution Foo-Bar-Baz

0.03 2024-03-01

  - Bugfix.
  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus
  - Donec quam felis.

0.02 2024-02-28

     - Some changes

0.02 2024-02-25
EOF
      test_out("not ok 1 - Changes file passed strict checks");
      test_fail(+4);
      test_diag("Line 8: missing dot at end of line");
      test_diag("Line 13: wrong indentation; missing dot at end of line");
      test_diag("Unexpected end of file");
      changes_strict_ok(changes_file => $fname);
      test_test("fail works");
    }
  }
}                              # /check changes

{
  note("check version monotonic");
  {
    note("duplicate version");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

1.00 2025-01-21

  - Bugfix.

0.02 2024-10-12

  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.

0.02 2024-04-03

  - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.
    Donec sodales sagittis magna.

0.01 2024-02-28

  - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("0.02: duplicate version");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
  {
    note("wrong order of versions");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

1.00 2025-01-21

  - Bugfix.

0.02 2024-10-12

  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.

0.03 2024-04-03

  - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.
    Donec sodales sagittis magna.

0.01 2024-02-28

  - Initial release.

EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("0.02 vs. 0.03: wrong order of versions");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
  {
    note("version dates chronologically inconsistent");
    my $fname = write_changes(<<"EOF");
Revision history for distribution Foo-Bar-Baz

1.00 2025-01-21

  - Bugfix.

0.03 2024-04-03

  - Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo
    ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis
    dis parturient montes, nascetur ridiculus mus.

0.02 2024-10-12

  - Donec quam felis.
  - Etiam ultricies nisi vel augue. Curabitur ullamcorper ultricies nisi.
    Donec sodales sagittis magna.

0.01 2024-02-28

  - Initial release.
EOF
    test_out("not ok 1 - Changes file passed strict checks");
    test_fail(+2);
    test_diag("date 2024-04-03 < 2024-10-12: chronologically inconsistent");
    changes_strict_ok(changes_file => $fname);
    test_test("fail works");
  }
}


# -------------------------------------------------------------------------------------------------

done_testing;

