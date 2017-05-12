#!/usr/bin/perl -w
#
# update-copyright - Perl script to update copyright years

use strict;
use warnings;
our $VERSION = '1.00';
use File::Find;
use File::stat;
require File::Temp;
use File::Temp ();
use Getopt::Long qw(:config no_ignore_case bundling);
use Encode;
use Pod::Simple::Text;

=head1 NAME

update-copyright.pl - Tool to update copyright years

=head1 SYNOPSIS

B<update-copyright.pl> S<[I<options>]> I<path...>

=head1 OPTIONS

 -q [--quiet]           : Do not show per file progress messages
 -v [--verbose]         : Show diffs to changed files
 -i [--ignore-years]    : Ignore the years already present use history only

=head1 DESCRIPTION

B<update-copyright.pl> is a script that uses svk to figure out when each file
in your project has changed and updates the copyright headers in those files
accordingly.

Run C<update-copyright.pl help> to access the built-in tool documentation.

=cut

=head1 CODE
=cut

=head3 $current_year

The year in which we live today.  This is added to the copyright of any file
that is modified, since we're modifying it today.  If we didn't do this a
subsequent run of this script would add it anyway.

=cut

my $current_year = `date '+%Y'`;
chop $current_year;

# Command line options

# Show what's going on
my $show_progress = 1;

# Show the actual changes made
my $show_diffs = 0;

# Iff true, use the years already present in each file, otherwise use the
# svk history only.
my $use_file_years = 1;


=head3 flushline ()

Helper function to clear a console line.

=cut

sub flushline
{
    print "\r                                                                              \r";
    flush STDOUT;
}

=head3 expandRange ($years)

Take the string C<$years> containing comma separated years or dash
separated year ranges and returns a list of years.

For example the string '1998, 2000-2002, 2004'
results in the list qw(1998 2000 2001 2002 2004).

=cut

sub expandRange ($)
{
    my @result;
    my $range = $_[0];

    $range =~ s/ //g;
    for my $range (split /,/, $range)
    {
        my $year;
        my @years = split /-/, $range;

        if ($#years > 0)
        {
            for ($year = $years[0]; $year < $years[1]; $year++)
            {
                push @result, $year;
            }
        }
        else
        {
            $year = $range;
        }
        push @result, $year;
    }

    return @result;
}

=head3 createRange (@years)

Takes a sorted list of years C<@years> and returns a string of comma separated
years or dash separated year ranges.

For example the list qw(1998 2000 2001 2002 2004)
results in the string '1998-2002, 2004'.

=cut

sub createRange (@)
{
    my $pyear = 0;
    my $inrange = 0;
    my $range;

    for my $year (@_)
    {
        if ($pyear + 1 == $year)
        {
            $inrange = 1;
        }
        elsif ($pyear < $year)
        {
            if (!$inrange)
            {
                if ($pyear == 0)
                {
                    $range = $year;
                }
                else
                {
                    $range = $range.",".$year;
                }
            }
            else
            {
                $range = $range."-".$pyear.",".$year;
                $inrange = 0;
            }
        }
        $pyear = $year;
    }

    if ($inrange)
    {
        $range = $range."-".$pyear;
    }

    return $range;
}

=head3 transform_line($line, @years)

If C<$line> contains a copyright message add the years in C<@years> to it and
return the resulting line.  If there is no Copyright on a line return undef.
If C<@years> is not specified Copyright lines are returned as is.

=cut

sub transform_line
{
    my ($line, @years) = @_;
    my ($prefix, $suffix);
    if ($line =~ /^(.*[Cc]opyright\s+)([0-9][0-9-, ]*)(.*)$/)
    {
        return $_ unless @years;
        $prefix = $1;
        $suffix = $3;
        @years = sort (@years, expandRange $2) if $use_file_years;
    }
    else
    {
        return undef;
    }

    my $yearstr = createRange(@years);
    return "$prefix$yearstr $suffix\n";
}

=head3 get_file_changed_years($filename)

Return a sorted list of years in which $filename was modified.

=cut

sub get_file_changed_years
{
    my $filename = $_[0];

    my %years;
    open(my $log, '-|', 'svk', 'log', '-qx', "$filename") or die;
    while (<$log>)
    {
        if (/^r[^|]+[|][^\d]+(\d+)/)
        {
            $years{$1} = 1;
        }
    }
    close($log);
    return sort(keys %years);
}

=head3 update_file_copyright($filename)

Update the copyright of one file.

=cut

sub update_file_copyright
{
    my $filename = $File::Find::name;
    my $relativename = $_;
    return unless -f $_;
    #my $name_is_text = $filename =~ /([.](h|c|cpp|m|cp|plist|pbxproj|strings|pbxuser|1|8|pl|order|defs|mm|mdsinfo|cvsignore|sh|r|mk|exp|toolbar|txt|rtf|pch|html|cf|cfg|t|m4|asn|asn1|s|pm|mds|l|def|i|pem|asm|js|css|gdb_history|htm|nb|mode[0-9])|\/(info.nib|classes.nib|ChangeLog|[A-Z_]+|script[^\/]*)),v$|[Mm]akefile/;
    return unless $_ =~
        /[.]([cChHmrsx]|cp|cpp|defs|java|keyboard|mk|pl|pm|t|exp)$|^[Mm]akefile$/;

    my $file;
    unless (open($file, $_))
    {
        print STDERR "Can't open $filename: $!\n";
        return;
    }

    print "$filename: scanning" if $show_progress;

    my $found_copyright = 0;
    while (<$file>)
    {
        if (defined transform_line($_))
        {
            $found_copyright = 1;
        }
    }

    if ($found_copyright)
    {
        print "\r$filename: checking" if $show_progress;
        my @years = get_file_changed_years($relativename);
        if (!@years)
        {
            flushline if $show_progress;
            print STDERR "$filename: not under source control\n";
        }
        else
        {
            my @cyears = sort (@years, $current_year);
            my $updated_copyright = 0;
            my $line_number = 0;
            my $tmp = new File::Temp( TEMPLATE => 'update-copyrightXXXXX');
            seek ($file, 0, 0);
            while (<$file>)
            {
                $line_number++;
                my $new_copyright = transform_line($_, @years);
                if (defined $new_copyright)
                {
                    if ($_ ne $new_copyright)
                    {
                        $new_copyright = transform_line($_, @cyears);
                        if ($_ ne $new_copyright)
                        {
                            flushline if $show_progress;
                            printf("\r%s:%s:\n<%s>%s", $filename, $line_number,
                                $_, $new_copyright) if $show_diffs;
                            $updated_copyright = 1;
                        }
                    }
                    print $tmp $new_copyright;
                }
                else
                {
                    print $tmp $_;
                }
            }

            flushline if $show_progress;

            if ($updated_copyright)
            {
                close $tmp;
                # @@@ We need an exchangedata($tmp, relativename) type call.
                my $st = stat($relativename) or die "stat $filename: $!\n";
                chmod $st->mode, $tmp or die "chmod $st->mode $tmp: $!\n";
                rename $tmp, $relativename or die "rename $tmp to $relativename: $!\n";
                print STDERR "$filename: updated\n";
            }
        }
    }
    else
    {
        flushline if $show_progress;
        print STDERR "$filename: *** No Copyright found ***\n";
    }

    unless (close($file))
    {
        print STDERR "Can't close $filename: $!\n";
        return;
    }
}

sub help {

    my $file = __FILE__;
    open my $fh, '<:utf8', $file or die $!;
    my $parser = Pod::Simple::Text->new;
    my $buf;
    $parser->output_string(\$buf);
    $parser->parse_file($fh);

    $buf =~ s/^NAME\s+SVK::Help::\S+ - (.+)\s+DESCRIPTION/    $1:/;

    print Encode::find_encoding('utf8')->encode($buf);
}

{
    my ($quiet, $verbose, $ignore_years, $show_version, $show_help);
    GetOptions ('q|quiet' => \$quiet,
                'v|verbose' => \$verbose,
                'i|ignore-years' => \$ignore_years,
                'h|help' => \$show_help) or exit;

    $show_progress = 0 if $quiet;
    $show_diffs = 1 if $verbose;
    $use_file_years = 0 if $ignore_years;

    if ($show_version) {
        print "This is submit, version $VERSION.\n";
        exit 0;
    }
}

if (!@ARGV) {
    help;
    exit 0;
}

find(\&update_file_copyright, @ARGV);

1;

=head1 AUTHORS

Michael L.H. Brouwer E<lt>michael@tlaloc.net<gt>

=head1 COPYRIGHT

Copyright 2006 by Michael L.H. Brouwer E<lt>michael@tlaloc.netE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
