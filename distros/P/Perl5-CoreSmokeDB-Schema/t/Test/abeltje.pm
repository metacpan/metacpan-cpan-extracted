package t::Test::abeltje;
use v5.10.1;
use warnings;
use strict;

our $VERSION = '1.07';

use parent 'Test::Builder::Module';

use Test::Builder::Module;
use Test::More;
use Test::Fatal qw( exception success dies_ok lives_ok );
use Test::Warnings qw( :all );

our @EXPORT = (
    'abeltje_done_testing',

    @Test::More::EXPORT,
    @Test::Fatal::EXPORT_OK,
    @Test::Warnings::EXPORT_OK
);

sub import_extra {
    # use Test::Warnings 'warnings' interferes
    # with warnings->import()
    warnings::import('warnings');
    strict->import();

    require feature;
    feature->import(':5.10');

    require lib;
    lib->import('t/lib');

    if ($Devel::Cover::VERSION) { # don't run_end_test when Devel::Cover
        Test::Warnings->import(':no_end_test');
    }
}

*abeltje_done_testing = \&Test::More::done_testing;

1;

=head1 NAME

t::Test::abeltje - Helper Test module that imports useful stuff.

=head1 SYNOPSIS

    #! perl -I.
    use t::Test::abeltje;

    # Don't forget -I. on the shebang line
    # this is where you have your Fav. test-routines.

    abeltje_done_testing();

=head1 DESCRIPTION

Mostly nicked from other modules (like L<Modern::Perl>)...

This gives you L<Test::More>, L<Test::Fatal>, L<Test::Warnings> and also imports
for you: L<strict>, L<warnings>, the L<feature> with the C<:5.10> tag and L<lib>
with the C<t/lib> path.

=head2 abeltje_done_testing

Just for fun, an alias for L<Test::More/done_testing()>.

=head2 import_extra

This module works by the use of L<Test::Builder::Module/import_extra()>.

=head1 COPYRIGHT

E<copy> MMXX - Abe Timmerman <abeltje@cpan.org>

=cut
