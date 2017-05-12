#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2011 Christopher J. Madsen
#
# Test Pod::Loom
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.008;
use utf8;

use Test::More 0.88;            # want done_testing

# Load Test::Differences, if available:
BEGIN {
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

use Encode qw(find_encoding);
use Pod::Loom;

#=====================================================================
my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>:utf8', '/tmp/10-weave.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} else {
  plan tests => 14 * 2;
}

binmode DATA, ':utf8';

while (<DATA>) {
  print OUT $_ if $generateResults;

  next if /^#[^#]/ or not /\S/;

  /^##\s*(.+)/ or die "Expected test name, got $_";
  my $name = $1;

  # Read the constructor parameters:
  my $param = '';
  while (<DATA>) {
    print OUT $_ if $generateResults;
    last if $_ eq "<<'---SOURCE---';\n";
    $param .= $_;
  } # end while <DATA>

  die "Expected <<'---SOURCE---';" unless defined $_;

  # Read the source text:
  my $source = '';
  while (<DATA>) {
    print OUT $_ if $generateResults;
    last if $_ eq "---SOURCE---\n";
    # Having multiple lines matching ^=encoding confuses the MetaCPAN indexer.
    # So, I use ~encoding instead and convert it during I/O.
    s/^~encoding/=encoding/;
    $source .= $_;
  }

  die "Expected ---SOURCE---" unless defined $_;
  $_ = <DATA>;
  die "Expected <<'---EXPECTED---';" unless $_ eq "<<'---EXPECTED---';\n";

  # Read the expected results:
  my $expected = '';
  while (<DATA>) {
    last if $_ eq "---EXPECTED---\n";
    s/^~encoding/=encoding/;
    $expected .= $_;
  }

  die "Expected ---EXPECTED---" unless defined $_;

  # Run the test:
  my $hash = eval $param;
  die $@ unless ref $hash;

  my $enc = find_encoding(delete $hash->{-encoding} || 'iso-8859-1')
      or die "$name encoding not found";

  $source = $enc->encode($source);

  my $template = delete $hash->{-template} || 'Default';

  my $loom = Pod::Loom->new(template => $template);

  isa_ok($loom, 'Pod::Loom', $name) unless $generateResults;

  my $got = $enc->decode( $loom->weave(\$source, $name, $hash) );

  $got =~ s/^(?:[ \t]*\n)+//;
  $got =~ s/\s+\z/\n/;

  # Either print the actual results, or compare to expected results:
  if ($generateResults) {
    $got =~ s/^=encoding/~encoding/mg;
    print OUT "<<'---EXPECTED---';\n$got---EXPECTED---\n";
  } else {
    eq_or_diff($got, $expected, "$name output");
  }
} # end while <DATA>

done_testing unless $generateResults;

#=====================================================================

__DATA__

## identity
{
  '-template' => 'Identity',
}
<<'---SOURCE---';
---SOURCE---
<<'---EXPECTED---';
---EXPECTED---

## simplest default
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
  license_notice => 'No license.',
}
<<'---SOURCE---';
---SOURCE---
<<'---EXPECTED---';
=head1 NAME

Foo::Bar - boring description

=head1 CONFIGURATION AND ENVIRONMENT

Foo::Bar requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=head1 COPYRIGHT AND LICENSE

No license.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
---EXPECTED---

## omit lots
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
}
<<'---SOURCE---';
=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
=head1 NAME

Foo::Bar - boring description

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut
---EXPECTED---

## with synopsis
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
}
<<'---SOURCE---';
=head1 SYNOPSIS

  use Foo::Bar;

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut
---EXPECTED---

## with Latin-1
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ["E. X\xE4vier \xC2mple <example\@example.org>"],
}
<<'---SOURCE---';
=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=head1 AUTHOR

E. Xävier Âmple  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut
---EXPECTED---

## with =encoding Latin-1
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ["E. X\xE4vier \xC2mple <example\@example.org>"],
}
<<'---SOURCE---';
~encoding Latin-1

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=head1 AUTHOR

E. Xävier Âmple  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut
---EXPECTED---

## with encoding utf8
{
  '-encoding'    => 'utf8',
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ["E. X\xE4vier \xC2mple <example\@example.org>"],
}
<<'---SOURCE---';
~encoding utf8

=head1 DESCRIPTION

This is ä déscription.

=head1 SYNOPSIS

  use Foo::Bar;

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
~encoding utf8

=head1 NAME

Foo::Bar - boring description

=head1 SYNOPSIS

  use Foo::Bar;

=head1 DESCRIPTION

This is ä déscription.

=head1 AUTHOR

E. Xävier Âmple  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut
---EXPECTED---

## bugtracker web
{
  dist           => 'Foo-Bar',
  authors        => ['E. Xavier Ample <example@example.org>'],
  bugtracker     => { web => 'http://example.org' },
}
<<'---SOURCE---';
=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
NAME
---SOURCE---
<<'---EXPECTED---';
=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
through the web interface at
L<< http://example.org >>.

=cut
---EXPECTED---

## bugtracker mailto
{
  dist           => 'Foo-Bar',
  authors        => ['E. Xavier Ample <example@example.org>'],
  bugtracker     => { mailto => 'bugs@example.org' },
}
<<'---SOURCE---';
=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
NAME
---SOURCE---
<<'---EXPECTED---';
=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bugs AT example.org> >>>.

=cut
---EXPECTED---

## bugtracker both
{
  dist           => 'Foo-Bar',
  authors        => ['E. Xavier Ample <example@example.org>'],
  bugtracker     => {mailto => 'bugs@example.org', web => 'http://example.org'},
}
<<'---SOURCE---';
=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
NAME
---SOURCE---
<<'---EXPECTED---';
=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bugs AT example.org> >>>
or through the web interface at
L<< http://example.org >>.

=cut
---EXPECTED---

## no bugtracker
{
  dist           => 'Foo-Bar',
  authors        => ['E. Xavier Ample <example@example.org>'],
  bugtracker     => {},
}
<<'---SOURCE---';
=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
NAME
---SOURCE---
<<'---EXPECTED---';
=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

=cut
---EXPECTED---

## use __END__ when file contains code
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
}
<<'---SOURCE---';
our $VERSION = '1.0';

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES
---SOURCE---
<<'---EXPECTED---';
our $VERSION = '1.0';

__END__

=head1 NAME

Foo::Bar - boring description

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut
---EXPECTED---

## other data after __END__
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
}
<<'---SOURCE---';
our $VERSION = '1.0';

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES

=cut

__END__
This is data.
---SOURCE---
<<'---EXPECTED---';
our $VERSION = '1.0';

=head1 NAME

Foo::Bar - boring description

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut

__END__
This is data.
---EXPECTED---

## other data after __DATA__
{
  dist           => 'Foo-Bar',
  module         => 'Foo::Bar',
  abstract       => 'boring description',
  authors        => ['E. Xavier Ample <example@example.org>'],
}
<<'---SOURCE---';
=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
COPYRIGHT AND LICENSE
DISCLAIMER OF WARRANTY
INCOMPATIBILITIES

=cut

__DATA__
This is data.
---SOURCE---
<<'---EXPECTED---';
=head1 NAME

Foo::Bar - boring description

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

Please report any bugs or feature requests
to S<C<< <bug-Foo-Bar AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Foo-Bar >>.

=cut

__DATA__
This is data.
---EXPECTED---

# Local Variables:
# compile-command: "perl 10-weave.t gen"
# End:
