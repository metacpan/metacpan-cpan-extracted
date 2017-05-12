use strict;
use warnings;
package Test::Bomb;
# ABSTRACT: a test which succeeds until a deadline passes ( a time bomb )

our $VERSION = 0.007;

use Exporter qw/import/;
use Date::Parse;
use Test::More;

our @EXPORT = qw/ bomb /;


my @configFiles = (
    $ENV{TESTBOMBCONFIG} || '',
    './t/tbc', './t/testbombconfig',
    './.tbc', './.testbombconfig',
    './tbc', './testbombconfig',
    ($ENV{HOME}||'.').'/.tbc',
    ($ENV{HOME}||'.').'/.testbombconfig',
);


%Test::Bomb::groups = ( );


sub bomb {
    local( $Test::Builder::Level ) = 2;
    ok( 0, 'Don\'t send me out there! I can\'t take the preasure!'), return
                         if releasing(); 
    if( $_[0] eq '-after' ) {
	checkDate($_[1]);
    } elsif( $_[0] eq '-with' ) {
        my $name = $_[1];
	if( exists $Test::Bomb::groups{$name} ) {
	    checkDate($Test::Bomb::groups{$name})
	} else {
	    checkDate(readConfig($name));
	}
    } else {
        ok 0, 'invalid parameter: \''. $_[0] . "'";
    }
    return
}


sub readConfig {
    local( $Test::Builder::Level ) = 3;
    my $name = shift;
    my $stringDate;
    my $configFile = ( grep { -f $_ } @configFiles )[0] || '';
    open IN, $configFile or ok( 0, 'failed to open config file'),
                           return 'configFail';
    ($stringDate) = map { $_->[0] eq $name ? $_->[1] : () }
		    map { s/(^\s+|\s+$|['"])//g; chomp; [split /\s*=\s*/,$_] }
			     ( <IN> );
    close IN;
    ok( 0, 'bomb group is not defined: '.$name), return 'configFail'
			if not defined $stringDate;
    return $stringDate;
}


sub checkDate {
    local( $Test::Builder::Level ) = 3;
    my $dateStr = shift;
    return if $dateStr eq 'configFail' ;
    my $time = str2time($dateStr);
    ok(0, "invalid date: '$dateStr'"), return unless $time;
    my $res = time < $time;
    my $name = $res ? "bomb after $dateStr" : 'deadline passed' ;
    ok $res, $name ;
}


sub releasing {
    return 1 if exists $ENV{DZIL_RELEASING};
}


1; # End of Test::Bomb


__END__
=pod

=head1 NAME

Test::Bomb - a test which succeeds until a deadline passes ( a time bomb )

=head1 VERSION

version 0.007

=head1 SYNOPSIS

use this test to ignore part of your system until
a deadline passes.  After the deadline the test will
fail unless you replace it.   I use it for large 
projects where I want to forget about some subsystems
until after other parts are done.

usage( in a test script ):

    bomb -after => 'Jan 31 2011';

before Jan 31 prints:

    ok 1 - bomb after Jan 31 2011

after deadline prints

    nok 1 - deadline passed

using bomb groups:

    bomb -with => 'pluginSystem' ;

looks for 'pluginSystem' in the config file and uses the date
assigned there to exire the test.

=head1 NAME

Test::Bomb

=head1 NOTE

this is a development tool.  if you release code that uses this test
I expect you will have some very upset users.

=head1 Global variables

=over

=item @configFiles

this is a list of filenames where the test will look
to find bomb groups.  File format is:

name=date

all whitespace is ignored. everything on the matching line is used
for the test.  Non-matching lines are ignored.

The first file found is used, the first file checked is the environment
variable TESTBOMBCONFIG followed by [.]tbc and [.]testbombconfig in various
places

=item %groups

This variable allow groups to be assigned programatically.
Just assign hash element for the name of the group like this:

$Test::Bomb::group{DateCalculations} = 'Jan 1, 2000'; # RIP Y2K :)

Probably inside some module included by each test script so that they
all get the same date;

=back

=head1 TODO

=over

=item 1

find more ways to check to see if the user is building a release.  if that
is the case then fail.

=back

=head1 EXPORT

bomb is automatically exported; if you don't want to use the function
why did you use the package?

=head1 SUBROUTINES/METHODS

=head2 bomb -after => 'date to expire'

acts like a test; 
errors cause test failure

=head2 readConfig

look for a group name in a config file

=head2 checkDate dateStr

compare the expiration date with today

=head2 releasing

check for various signs of project release
so we can fail if a release is being generated
( perhaps there should be a way to override this
for testing purposes.. )

NOTE:  any flags added here need to be undone at the
top of the test script; otherwise every test will fail
when distributing this package

=head1 AUTHOR

David Delikat, C<< <david-delikat at usa.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-bomb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=test-bomb>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Bomb

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=test-bomb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/test-bomb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/test-bomb>

=item * Search CPAN

L<http://search.cpan.org/dist/test-bomb/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Delikat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

David Delikat <david-delikat@usa.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Delikat.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

