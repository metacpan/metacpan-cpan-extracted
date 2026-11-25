# ABSTRACT: Test that the POD of a module says what each sub takes, returns, and how it fails
# PODNAME: Test::Pod::Coverage::More

package Test::Pod::Coverage::More 0.003;

use 5.036;
use warnings FATAL => q{all};

use Exporter qw{import};
use Test::Builder;
use Test::Pod::Coverage ();

use Pod::Coverage::More;

# A test module exports its test functions, as Test::More and Test::Pod::Coverage do.
our @EXPORT = qw{pod_coverage_more_ok all_pod_coverage_more_ok};    ## no critic (Modules::ProhibitAutomaticExportation)


our $TEST = Test::Builder->new;

sub pod_coverage_more_ok {
    my ( $module, $options, $name ) = @_;
    my %args   = %{ $options // {} };
    my $checks = delete( $args{checks} ) // \@Pod::Coverage::More::CHECKS;
    $name //= "POD coverage of $module";

    my $pc     = Pod::Coverage::More->new( package => $module, %args );
    my $rating = $pc->coverage;
    my @failures;
    if ( !defined $rating ) {
        my $why = $pc->why_unrated // 'it could not be rated';
        push @failures, "$module: $why" if $why ne 'no public symbols defined';
    }
    elsif ( $rating < 1 ) {
        push @failures, map { "$module: $_ is not documented" } sort $pc->naked;
    }

    my $report = $pc->coverage_report // {};
    foreach my $sub ( sort keys %$report ) {
        foreach my $check (@$checks) {
            push @failures, map { "$module: $_" } @{ $report->{$sub}{failures}{$check} || [] };
        }
    }

    my $ok = $TEST->ok( !@failures, $name );
    foreach my $failure (@failures) {
        $TEST->diag($failure);
    }
    return $ok;
}


sub all_pod_coverage_more_ok {
    my ($options) = @_;
    my @modules = Test::Pod::Coverage::all_modules();
    $TEST->plan( tests => scalar @modules ) if !$TEST->has_plan;
    my $ok = 1;
    foreach my $module (@modules) {
        $ok = 0 if !pod_coverage_more_ok( $module, $options );
    }
    return $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Pod::Coverage::More - Test that the POD of a module says what each sub takes, returns, and how it fails

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Test::More;
    use Test::Pod::Coverage::More;

    pod_coverage_more_ok( 'Pod::Coverage::More', { checks => [qw{arguments returns termination}] } );

    done_testing;

=head1 DESCRIPTION

Runs the checks of L<Pod::Coverage::More> as tests: one test per module,
which fails with one diagnostic line per thing that the POD does not cover.

=head1 OPTIONS

Each function takes an optional HASHREF of options.  C<checks> is an ARRAYREF of the names of the checks to run,
from THE CHECKS of L<Pod::Coverage::More>, and all of them by default.
Every other option goes to C<new> of L<Pod::Coverage>, such as C<trustme> and C<also_private>.

=head1 FUNCTIONS

=head2 pod_coverage_more_ok(MODULE, OPTIONS, NAME)

Runs one test, named NAME or "POD coverage of MODULE": it passes when the POD documents each public sub of MODULE,
as L<Pod::Coverage> counts, and each sub that it documents passes the checks that OPTIONS names.
A module with no public subs passes, as L<Test::Pod::Coverage> rates it.

=over 4

=item MODULE - Str - the name of the module

=item OPTIONS - HashRef - optional: the options that OPTIONS describes

=item NAME - Str - optional: the name of the test

=back

Returns true when the test passed.

    pod_coverage_more_ok( 'Some::Module', { checks => ['arguments'] }, 'the arguments of Some::Module' );

=head2 all_pod_coverage_more_ok(OPTIONS)

Runs C<pod_coverage_more_ok> for each module under F<blib>, or else under F<lib>, as L<Test::Pod::Coverage> finds them,
and plans that many tests when nothing planned them yet.

=over 4

=item OPTIONS - HashRef - optional: the options that OPTIONS describes, for every module

=back

Returns true when every test passed.

    all_pod_coverage_more_ok( { checks => [ 'arguments', 'returns' ] } );

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage::More|Pod::Coverage::More>

=item *

L<Pod::Coverage::More>

=item *

L<Test::Pod::Coverage>

=item *

L<Dist::Zilla::Plugin::Test::Pod::Coverage::More>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Pod-Coverage-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2026 George S. Baugh


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
