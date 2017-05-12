package SVK::Log::Filter::Mndrix;

use warnings;
use strict;

use base qw( SVK::Log::Filter::Output );
use Perl6::Form;
use Text::Autoformat;
use Time::Local qw( timegm );
use POSIX qw( strftime );
use Term::ReadKey;

our $VERSION = '0.0.3';

sub revision {
    my ($self, $args) = @_;
    my $props = $args->{props};
    my $rev = $args->{rev};
    my $stash = $args->{stash};

    my $author  = $props->{'svn:author'} || '(none)';
    my $message = $props->{'svn:log'};
    $message = q{} if !defined $message;
    my $columns = $stash->{quiet}
                ? $ENV{COLUMNS} || (GetTerminalSize())[0] || 80
                : 80
                ;

    # clean up messages with SVK lump headers
    if ( $message =~ s{\A \s* r\d+ [@] .*? $ \s* }{}xms ) {
        $message =~ s/^ \s //xmsg;
    }
    my ($first, $rest) = split /\n\n+/, $message, 2;
    $message = autoformat(
        $first || q{},
        {
            left   => 0,
            right  => $columns - 28,
        }
    );
    $message .= $rest if $stash->{verbose} and $rest;

    my ($day, $date, $time) = date_and_time(
        $props->{'svn:date'},
        $stash->{quiet} ? '-' : ' ',
    );

    # determine the formats for the log message
    my $quiet_format  = '{' . q{'}x($columns-28) . '}';

    # handle the quiet form
    print form
        # r    author   date        log message
        "{<<<} {<<<<<<} {<<<<<<<<<} $quiet_format",
         $rev, $author,$date,      $message
    if $stash->{quiet};
    return if $stash->{quiet};

    # handle the other form
    my $get_remote_rev = $args->{get_remoterev} || sub {};
    my $remote_rev = $get_remote_rev->($rev) || 'no';
    $message = ' ' if !defined($message) or !length($message);
    print form
        '-----------------------------[ Revision : {>>>>} ]-----------------------------',
                                                   $rev,
        'Author: {<<<<<<}    Log:',
                  $author,
        "Day   : {<<<<<<<}      {''''''''''''''''''''''''''''''''''''''''''''''''''''''''}",
                  $day,          $message,
        'Date  : {<<<<<<<<<}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
                  $date,
        'Time  : {<<<<<<}       {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
                  $time,
        'Remote: {<<<<}         {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
                 $remote_rev,
        '                       {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
    ;

}

sub date_and_time {
    my ($raw, $s) = @_;

    my (
        $year,
        $month,
        $d,
        $hour,
        $minute,
        $second,
        $nanos
    ) = split /[-T:.]/, $raw;
    $year -= 1900;
    $month--;

    my $t = timegm($second, $minute, $hour, $d, $month, $year);
    my $day  = strftime('%A',            localtime($t) );
    my $time = strftime('%T',            localtime($t) );
    my $date = strftime("\%e$s\%b$s\%Y", localtime($t) );

    return ($day, $date, $time);
}

1;

__END__

=head1 NAME

SVK::Log::Filter::Mndrix - my pretty-ish output format

=head1 VERSION

This documentation refers to SVK::Log::Filter::Mndrix version 0.0.1


=head1 SYNOPSIS

 > svk log --output mndrix -l3 -q
 4353  mndrix   3-Aug-2006  Refactor log filters for a cleaner implementation
 4351  glasser  2-Aug-2006  In SVK::Root::Checkout, add a list of unimplemented
 4350  clkao    2-Aug-2006  Make nearest_copy work with 1.2.x. Spotted by
 
 > svk log --output mndrix -l2
 -----------------------------[ Revision :   4353 ]-----------------------------
 Author: mndrix      Log:
 Day   : Thursday       Refactor log filters for a cleaner implementation
 Date  : 3 Aug 2006     allowing filters to be subclassed. The new approach
 Time  : 14:07:21       also avoids naming collisions by avoiding the stash
 Remote: 1881           as much as possible.

 -----------------------------[ Revision :   4351 ]-----------------------------
 Author: glasser     Log:
 Day   : Wednesday      In SVK::Root::Checkout, add a list of unimplemented
 Date  : 2 Aug 2006     svn_fs_root_t methods.
 Time  : 22:44:33
 Remote: 1880

=head1 DESCRIPTION

The Mndrix filter is an output log filter for SVK which displays log messages
and revision properties in a way that I consider useful.  Under normal usage,
it displays author, day, date, time, remote revision number (if applicable)
and the first paragraph of the log message.  The layout has the log message in
the right column and all other information in the left column.

Once installed, I make it my default output log filter by setting the
environment variable SVKLOGOUTPUT to 'mndrix'.  For specific invocations of
the log command, you can still get the default behavior by specifying
"--output std" 

=head2 quiet

Display a one-line summary of each revision including: revision number,
author, date and log message

=head2 verbose

Display the entire log message instead of just the first paragraph.
Eventually, this should show the files that were modified, but it doesn't do
this now.

=head1 STASH/PROPERTY MODIFICATIONS

Stats leaves all properties intact and does not modify the stash.

=head1 DEPENDENCIES

=over

=item *

SVK 1.99 or newer

=item *

Perl6::Form

=item *

Text::Autoformat

=item *

Term::ReadKey

=item *

Time::Local

=item *

POSIX

=back

=head1 INCOMPATIBILITIES

Incompatible with any other output log filter.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-svk-log-filter-mndrix at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVK-Log-Filter-Mndrix>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVK::Log::Filter::Mndrix

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVK-Log-Filter-Mndrix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVK-Log-Filter-Mndrix>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVK-Log-Filter-Mndrix>

=item * Search CPAN

L<http://search.cpan.org/dist/SVK-Log-Filter-Mndrix>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
The MIT License

Copyright (c) 2006 Michael Hendricks (<michael@ndrix.org>).

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
