package Test::Changes::Strict::Simple;

use 5.010;
use strict;
use warnings;
use parent 'Exporter';
our @EXPORT = qw(changes_strict_ok);

use version;

use Test::Builder;

use Time::Local;
use Carp;


our $VERSION = '0.01';

#
# The use of global variables is acceptable, as we never check more than one
# Changes file at a time.
#
my $TB = Test::Builder->new;

my $Ver_Re = qr/\d+\.\d+/;

use constant {
              NOW => time,
              map { $_ => $_ } qw(
                                   st_chlog_head
                                   st_empty_after_head
                                   st_version
                                   st_empty_after_version
                                   st_item
                                   st_item_cont
                                   st_empty_after_item
                                   st_EOF
                                )
             };


my $Test_Name = "Changes file passed strict checks";
my $Empty_Line_After_Version;
my $Chk_Dots = 1;

sub import {
  my $class = shift;

  my %opts;                     # Option key/value pairs.
  my @exports;                  # Requested symbols to export.

  # Separate options (starting with '-') from export symbols.
  while (@_) {
    if (@_ >= 2 && $_[0] =~ /^-/) {
      my ($key, $val) = splice(@_, 0, 2);
      $key =~ s/^-//;           # Remove leading dash.
      $opts{$key} = $val;
    } else {
      push(@exports, shift);
    }
  }

  # Process known options.
  my $no_export = delete $opts{no_export};
  $Empty_Line_After_Version = delete $opts{empty_line_after_version};
  if (exists($opts{version_re})) {
    $Ver_Re = delete $opts{version_re};
    croak("-version_re: option has an invalid value") if ref($Ver_Re) ne "Regexp";
  }
  $Chk_Dots = delete $opts{check_dots} if exists($opts{check_dots});

  # Fail on unknown options.
  croak("Unknown option(s): " . join(", ", keys %opts)) if %opts;

  # Export logic.

  if (@exports) {
    # Explicit symbol list provided ==> export exactly those.
    __PACKAGE__->export_to_level(1, $class, @exports);
  } elsif ($no_export) {
    # -no_export requested ==> export nothing.
    return;
  } else {
    # No arguments ==> preserve standard Exporter behaviour.
    # This keeps the distinction between:
    #   use Test::Changes::Strict::Simple;
    #   use Test::Changes::Strict::Simple ();
    __PACKAGE__->export_to_level(1, $class, @EXPORT);
  }
}


# ------------------

sub changes_strict_ok {
  my %args = @_;
  my $changes_file = delete($args{changes_file}) // "Changes";
  my $mod_version  = delete($args{module_version});
  croak("Unknown arguments(s): " . join(", ", keys %args)) if %args;

  my $test_name = "Changes file passed strict checks";

  my @lines;
  _read_file($changes_file, \@lines) or return;

  _check_and_clean_spaces(\@lines) or return;

  my $trailing_empty_lines = _trim_trailing_empty_lines(\@lines);
  _check_title(\@lines) or return;

  my @versions;
  _check_changes(\@lines, \@versions) or return;
  _check_version_monotonic(\@versions) or return;
  if ($mod_version) {
    my $top_ver = $versions[0]->{version_str};
    $mod_version eq $top_ver or
      return _not_ok("Highest version in changelog is $top_ver, not $mod_version as expected");
  }

  my $ok = $TB->ok($trailing_empty_lines <= 3, $Test_Name) or
    $TB->diag("more than 3 empty lines at end of file");
  return $ok;
}


sub _read_file {
  my ($fname, $lines) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  -e $fname or return _not_ok("The '$fname' file does not exist");
  -f $fname && -r $fname && -T $fname or
    return _not_ok("The '$fname' file is not a readable text file");
  open(my $fh, '<', $fname) or return _not_ok("Cannot open '$fname': $!");
  @$lines = <$fh> or return _not_ok("The '$fname' file empty");
  substr($lines->[-1], -1) eq "\n" or return _not_ok("'$fname': no newline at end of file");
  chomp(@$lines);
  return !0;
}


sub _trim_trailing_empty_lines {
  my ($aref) = @_;
  my $removed = 0;

  while (@$aref && $aref->[-1] eq '') {
    pop(@$aref);
    $removed++;
  }
  push(@$aref, q{});            # We need exactly 1 trailing empty line.
  return $removed;
}


sub _check_and_clean_spaces {
  my ($lines) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my (@other_spaces, @trailing_spaces);
  for (my $i = 1; $i <= @$lines; ++$i) {
    $lines->[$i - 1] =~ s/[^\S\ ]/\ /g and push(@other_spaces, $i);
    $lines->[$i - 1] =~ s/\s+$// and push(@trailing_spaces, $i);
  }
  my $diag;
  if (@other_spaces) {
    my $plural = @other_spaces > 1 ? "s" : "";
    $diag = "Non-space white character found at line$plural " . join(', ', @other_spaces);
  }
  if (@trailing_spaces) {
    my $plural = @trailing_spaces > 1 ? "s" : "";
    $diag = join('. ',
                 ($diag // ()),
                 "Trailing white character at line$plural " . join(', ', @trailing_spaces));
  }
  return $diag ? _not_ok($diag) : !0;
}


sub _check_title {
  my ($lines) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $test_name = "Header line ok";
  my $ok = $lines->[0] =~ qr/
                              ^
                              Revision\ history\ for\ (?:
                                (?:perl\ )?
                                (?:
                                  (?:module\ \w+(?:::\w+)*)
                                |
                                  (?:distribution\ \w+(?:-\w+)*)
                                )
                              )
                              $
                            /x;
  return $ok ? !0 : _not_ok("Missing or malformed 'Revision history ...' at line 1");
}


sub _check_changes {
  my ($lines, $versions) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my %states = (
                +st_chlog_head          => [st_empty_after_head],
                +st_empty_after_head    => [st_version],
                $Empty_Line_After_Version ? (
                                             +st_version             => [st_empty_after_version],
                                             +st_empty_after_version => [st_item],
                                            )
                                          : (
                                             +st_version             => [st_item],
                                            ),
                +st_item                => [st_item, st_item_cont, st_empty_after_item, st_EOF],
                +st_item_cont           => [st_item, st_item_cont, st_empty_after_item],
                +st_empty_after_item    => [st_version, st_EOF],
                +st_EOF                 => [],
               );
  $_ = { map { $_ => undef } @$_ } for values %states;
  my %empty_line_st = (+st_chlog_head => st_empty_after_head,
                       +st_item       => st_empty_after_item,
                       $Empty_Line_After_Version ? (+st_version => st_empty_after_version) : (),
                      );
  my %item_line = (+st_item => undef, +st_item_cont => undef);
  my $indent;
  my $state = st_chlog_head;
  my %errors;
  my $err = sub { push(@{$errors{$_[0]}}, $_[1]); };
  my $i = 2;
  for (; $i <= @$lines; ++$i) {
    my $line = $lines->[$i - 1];
    if ($line eq "") {
      my $old_state = $state;
      $err->($i - 1, "missing dot at end of line")
        if $Chk_Dots && (exists($item_line{$old_state}) && $lines->[$i - 2] !~ /\.$/);


      if (exists($item_line{$old_state}) || $old_state eq st_empty_after_item) {
        my $next_line = $lines->[$i];
        if (defined($next_line) && $next_line !~ /^\S/) {
          $err->($i, "unexpected empty line");
          last;
        }
        $state = st_empty_after_item;
      } else {
        $state = $empty_line_st{$old_state} or do { $err->($i, "unexpected empty line");
                                                    last;
                                                  };
      }
    } elsif ($line =~ /^[^-\s]/) {
      exists($states{$state}->{+st_version}) or do { $err->($i, "unexpected version line");
                                                     last;
                                                   };
      $state = st_version;
      my $result = _version_line_check($line);
      if (ref($result)) {
        $result->{line} = $i;
        push(@$versions, $result);
      } else {
        $err->($i, "version check: $result");
        last;
      }
    } elsif ($line =~ s/^(\s*)-//) {
      my $heading_spaces = $1;
      exists($states{$state}->{+st_item}) or do { $err->($i, "unexpected item line");
                                                  last;
                                                };
      $err->($i - 1, "missing dot at end of line")
        if $Chk_Dots && (exists($item_line{$state}) && $lines->[$i - 2] !~ /\.$/);
      $line =~ /^ \S+/ or do { $err->($i, "invalid item content");
                               last;
                             };
      $state = st_item;
      if ($heading_spaces eq "") {
        $err->($i, "no indentation");
      } elsif (defined($indent)) {
        $err->($i, "wrong indentation") if length($heading_spaces) != $indent;
      } else {
        $indent = length($heading_spaces);
      }
    } elsif ($line =~ /^(\s+)[^-\s]/) {
      exists($states{$state}->{+st_item_cont}) or do { $err->($i, "unexpected item continuation");
                                                       last;
                                                     };
      my $state = st_item_cont;
      my $heading_spaces = $1;
      length($heading_spaces) == $indent + 2 or do { $err->($i, "wrong indentation"); };
    }
  }
  my $diag;
  if (%errors || ($i > @$lines && !exists($states{$state}->{+st_EOF}))) {
    if (%errors) {
      $diag = join("\n",
                   (map {"Line $_: " . join("; ", @{$errors{$_}})}
                    (sort { $a <=> $b } keys(%errors))));
    }
    $diag = join("\n", ($diag // ()), "Unexpected end of file")
      if ($i > @$lines && !exists($states{$state}->{+st_EOF}));
  }
  return $diag ? _not_ok($diag) : !0;
}


sub _check_version_monotonic {
  my ($versions) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $diag;
  if (@$versions) {
    for (my $i = 0; $i < $#$versions; ++$i) {
      my ($v1, $e1) = @{$versions->[$i]    }{qw(version epoch)};
      my ($v2, $e2) = @{$versions->[$i + 1]}{qw(version epoch)};
      unless ($v1 > $v2) {
        my $vs1 = $versions->[$i]->{version_str};
        my $vs2 = $versions->[$i + 1]->{version_str};
        $diag = $v1 == $v2 ? "$vs1: duplicate version" : "$vs1 vs. $vs2: wrong order of versions";
        last;
      }
      if ($e1 < $e2) {
        my $d1 = $versions->[$i]->{date};
        my $d2 = $versions->[$i + 1]->{date};
        $diag = "date $d1 < $d2: chronologically inconsistent";
        last;
      }
    }
  } else {
    $diag = "No versions to check";
  }
  return $diag ? _not_ok($diag) : !0;
}


# ---------------------------- Helper functions ---------------------------------------

sub _version_line_check {
  # Line is already trimmed!
  my $line = shift;
  (my ($ver_str, $date) = split(/\s+/, $line)) == 2 or return("not exactly two values");
  $ver_str =~ /^$Ver_Re$/ or return "$ver_str: invalid version";
  my $version;
  eval { $version = version->parse($ver_str); 1; } or return("$ver_str: invalid version");
  $date =~ /^(\d{4})-(\d{2})-(\d{2})$/ or return("$date: invalid date: wrong format");
  my ($y, $m, $d) = ($1, $2, $3);
  my $epoch;
  eval {
    $epoch = Time::Local::timegm(0, 0, 0, $d, $m - 1, $y);
    1;
  } or return "'$date': invalid date";
  $y     >= 1987 or return "$date: before Perl era";
  $epoch <= NOW  or return "$date: date is in the future.";
  return { version     => $version,
           version_str => $ver_str,
           date        => $date,
           epoch       => $epoch};
}


#---------------------------------------------------------

sub _not_ok {
  my ($diag) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  $TB->ok(0, $Test_Name);
  $TB->diag($diag);
  return !1;
}


1; # End of Test::Changes::Strict::Simple



__END__


=pod

=head1 NAME

Test::Changes::Strict::Simple - Strict semantic validation for CPAN Changes files

=head1 SYNOPSIS

    use Test::More;
    use Test::Changes::Strict::Simple qw(changes_strict_ok);

    changes_strict_ok('Changes');

    done_testing;

Typically used in C<xt/release/> and guarded by:

    plan skip_all => 'Release tests only'
        unless $ENV{RELEASE_TESTING};

=head1 DESCRIPTION

C<Test::Changes::Strict::Simple> provides strict semantic validation for
CPAN-style F<Changes> files.

While other modules focus primarily on structural validation,
this module performs additional consistency checks, including:

=over 4

=item *

The indentations must be uniform.

=item *

No trailing spaces.

=item *

No white characters other than spaces.

=item *

No more than three blank lines at the end of the file.

=item *

No version without items

=item *

First line must be a title matching:

   qr/
      ^
       Revision\ history\ for\ (?:
         (?:perl\ )?
         (?:
           (?:module\ \w+(?:::\w+)*)
         |
           (?:distribution\ \w+(?:-\w+)*)
         )
       )
       $
     /x;

=item *

Title lines and version lines are never indented.

=item *

A version line consists of a version string and a date separated by blanks.

=item *

Dates match C</\d+\.\d+/>.

=item *

Versions are strictly monotonically increasing.

=item *

Release dates are valid calendar dates. Only dates, no time.

=item *

Release dates are not in the future.

=item *

Release dates are not earlier than the first public Perl release (1987).

=item *

Release dates are monotonically non-decreasing
(multiple releases on the same day are allowed).

=back

Note: an item can span more than one line.

Example of a valid Changes file:

   Revision history for distribution Foo-Bar-Baz

   0.03 2024-03-01
     - Another version, same day.

   0.02 2024-03-01
     - Bugfix.
     - Added a very fancy feature that alllows this
       and that.
     - Another bugfix.

   0.01 2024-02-28
     - Initial release. This will hopefully work
       fine.

If you do not want periods at the end of the items, set the import option
C<-check_dots> to 0. If you want an empty line after each version line, set
the import option C<-empty_line_after_version> to 1.

The module is intended for use in release testing and helps
detect common mistakes such as version regressions, invalid
dates, and chronological inconsistencies.

=head1 EXPORT

By default, the following symbols are exported:

   changes_strict_ok


=head1 IMPORT OPTIONS

=head2 -check_dots => I<BOOL>

By default, items must end with a period. This check can be disabled by
passing C<-check_dots> with a value of I<C<false>>. Example:

    use Test::Changes::Strict::Simple -check_dots => 0;


=head2 -empty_line_after_version => I<BOOL>

By default, the first element must immediately follow the version line.
Passing C<-empty_line_after_version> with a I<C<true>> value changes this
behavior so that there must be exactly one blank line between a version line
and the first element. Example:

    use Test::Changes::Strict::Simple -empty_line_after_version => 1;


=head2 -no_export => I<BOOL>

If true, no symbols are exported.

   use Test::Changes::Strict::Simple -no_export => 1;

is equivalent to:

   use Test::Changes::Strict::Simple ();

This option is useful in conjunction with other import options. Example:

   use Test::Changes::Strict::Simple -empty_line_after_version => 1, -no_export => 1


=head2 -version_re => I<REGEXP>

By default, version numbers must match C<qr/\d+\.\d+/>. This can be overridden
by passing a custom compiled regular expression via C<-version_re>. Note that
version strings must be valid with respect to the C<version> module.


=head1 FUNCTIONS

=head2 changes_strict_ok(I<C<NAMED_ARGUMENTS>>)

Runs strict validation on the given Changes file.

Named arguments:

=over

=item C<changes_file>

Optional. File to be validated. If no file is provided, C<Changes> is assumed.

=item C<module_version>

Optional. If specified, the function checks whether the highest version is
equal to I<C<module_version>>. This is done by comparing strings.

=back

The function emits one test event using C<Test::Builder> and can output
diagnostic messages if necessary.
It does not plan tests and does not call C<done_testing>.

Returns I<C<true>> if all checks pass, I<C<true>> otherwise.


=head1 LIMITATIONS

The module expects a traditional CPAN-style Changes format:

    1.23 2024-03-01
      - Some change.

Exotic or highly customized Changes formats may not be supported.


=head1 BUGS

Please report any bugs or feature requests to C<bug-test-changes-strict-simple
at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Changes-Strict-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Changes::Strict::Simple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Changes-Strict-Simple>

=item * Search CPAN

L<https://metacpan.org/release/Test-Changes-Strict-Simple>

=item * GitHub Repository

L<https://github.com/klaus-rindfrey/perl-test-changes-strict-simple>


=back


=head1 SEE ALSO

=over 4

=item *

L<Test::CPAN::Changes>

Basic structural validation of CPAN Changes files.

=item *

L<Test::CPAN::Changes::ReallyStrict>

Stricter validation rules for Changes files.

=item *

L<Test::Version>

Checks module version consistency.

=item *

L<CPAN::Changes>

Parser and model for Changes files.

=back

Furthermore: L<Test::Builder>, L<Time::Local>, L<version>


=head1 AUTHOR

Klaus Rindfrey, C<< <klausrin at cpan.org.eu> >>


=head1 LICENSE

This software is copyright (c) 2026 by Klaus Rindfrey.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

