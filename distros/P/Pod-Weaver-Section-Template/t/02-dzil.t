#!/usr/bin/env perl
use strict;
use warnings;
BEGIN {
    unless (eval "require Dist::Zilla; require Dist::Zilla::Plugin::PodWeaver; 1") {
        require Test::More;
        Test::More::plan(skip_all => 'Dist::Zilla and Dist::Zilla::Plugin::PodWeaver are required for this test');
    }
}

use Test::More;

use Dist::Zilla::Tester;
use FindBin;
use File::pushd;
use Path::Class;
use Pod::Elemental;
use Pod::Weaver;
use lib "$FindBin::Bin/../lib";

my $zilla = Dist::Zilla::Tester->from_config({
    dist_root => dir($FindBin::Bin, '02'),
});
$zilla->build;

sub get_foo
{
  my $content = file('lib', 'Foo', shift)->slurp;

  # Standardize whitespace:
  $content =~ s/\s*__END__\s+=pod\s+/\n\n__END__\n\n=pod\n\n/;
  $content =~ s/^=cut\s*\z/=cut\n/m;

  $content;
} # end get_foo

#---------------------------------------------------------------------
my $pushed = pushd($zilla->tempdir->subdir('build'));
is(get_foo('Bar.pm'), <<'PM', "got the right Bar.pm file contents");
package Foo::Bar;
# ABSTRACT: turns trinkets into baubles

sub bar {
}

1;

__END__

=pod

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-foo-bar at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Foo-Bar>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Foo::Bar

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Foo-Bar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Foo-Bar>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Foo-Bar>

=item * Search CPAN

L<http://search.cpan.org/dist/Foo-Bar>

=back

=cut
PM

#---------------------------------------------------------------------
is(get_foo('Baz.pm'), <<'PM', "got the right Baz.pm file contents");
package Foo::Baz;

sub baz {
}

1;

__END__

=pod

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Foo::Bar

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Foo-Bar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Foo-Bar>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Foo-Bar>

=item * Search CPAN

L<http://search.cpan.org/dist/Foo-Bar>

=back

=cut
PM

done_testing;
