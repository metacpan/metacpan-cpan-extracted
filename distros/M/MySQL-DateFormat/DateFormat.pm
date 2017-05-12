package MySQL::DateFormat;

use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use Date::Calc;

use vars qw($VERSION $VERSION_DATE);

$VERSION = "2.04";
$VERSION_DATE = "May 31, 2015";

enum 'format_code'   => [qw( eu us )];
has 'format'         => ( is => 'ro', isa => 'format_code', required => 1 );
enum 'informal_code' => [qw ( 0 1 2 )];
has 'informal'       => ( is => 'ro', isa => 'informal_code', default => 0 );
has 'century_cutoff' => ( is => 'ro', isa => 'Int', default => 20 );
has 'separator'      => ( is => 'ro', isa => 'Str', default => '/' );

sub toMySQL {

    my $self = shift;
    my $date = shift;

    unless ($date) {
        carp "[$$] No date supplied";
        return 0;
    }

    $date =~ s#/#-#g; # we accept either as a separator

    my ($d, $m, $y);
    my ($a, $b, $c) = split("-", $date);

    unless ($a and $b and $c) {
        carp "[$$] Invalid date [$a/$b/$c]";
        return 0;
    }

    if ($self->format eq 'eu') {
        # Europe format: DD/MM/YYYY
        $d = $a; $m = $b; $y = $c;
    } elsif ($self->format eq 'us') {
        # USA format: MM/DD/YYYY
        $m = $a; $d = $b; $y = $c;
    } else {
        carp "[$$] Invalid format specified. Value of 'format' arg must be 'us' or 'eu'.";
        return 0;
    }

    if ($self->century_cutoff eq 'disallow' and $y !~ m/^\d{4}$/) {
        carp "[$$] Two-digit year supplied when four digits required.";
        return 0;
    } elsif ($self->century_cutoff !~ m/^\d{1,2}$/) {
        carp "[$$] Invalid century_cutoff specified. Value of 'century_cutoff' arg must be a two-digit integer or 'disallow'.";
        return 0;
    } 
    $y = ($y < 100) ? ($y > $self->century_cutoff) ? $y + 1900 : $y + 2000 : $y;
    $m = sprintf("%0.2d", $m);
    $d = sprintf("%0.2d", $d);

    unless (Date::Calc::check_date($y,$m,$d)) {
        carp "[$$] Invalid date [y:$y m:$m d:$d]";
        return 0;
    }

    return join("-", $y, $m, $d);

}

sub frMySQL {
    my $self = shift;
    my $date = shift;

    unless ($date) {
        carp "[$$] No date supplied";
        return 0;
    }

    $date =~ s#/#-#g;
    my ($y,$m,$d) = split("-", $date);

    unless (Date::Calc::check_date($y,$m,$d)) {
        carp "[$$] Invalid date [y:$y m:$m d:$d]";
        return 0;
    }

    if ($self->informal > 0) {
        $m =~ s/^0//;
        $d =~ s/^0//;
    }
    if ($self->informal > 1) {
        $y =~ s/^..//;
    }

    my @elements = $self->format eq 'us' ? ($m,$d,$y) : ($d,$m,$y);

    return join($self->separator, @elements);

}

1;
__END__


=pod

=head1 NAME

MySQL::DateFormat -- Manipulate dates back and forth between human-readable and MySQL formats

=head1 SYNOPSIS

 use MySQL::DateFormat;           
 my $md = MySQL::DateFormat->new(format => 'us');
 print $md->toMySQL("5/31/87");    # prints "1987-05-31"
 print $md->frMySQL("1987-05-31"); # prints "05-31-1987"

=head1 DESCRIPTION

The MySQL RDBMS requires dates to be supplied in YYYY-MM-DD format[1,2,3], but many humans expect dates to be presented, and to be able to enter them, in MM-DD-YY or DD-MM-YY format or similar. This module converts dates back and forth between human-readable and MySQL format.

While there are multiple ways in Perl to format dates, and while certain modules on CPAN exist that perform the date formatting that is part of this module's functionality, the author believes that there is a place for a package tailored to the MySQL database. Even if one used Date::Format and the super-configurability of its underlying C routines, there would still be a need in a large application for a package containing routines to reformat the dates coming in and going out of the database server. And that's not all:

The module allows the user to configure the format for dates used in the application code, whether to use or require four digits for the year, what year to use as century cutoff if two-digit years are allowed, etc., etc. All these configuration options are managed by the user through an extrememly simple interface. In the realm in which this module is intended to be used, the author has found this to be a significant advantage.

Another very important task when using MySQL is error checking of the "human-readable" dates supplied. This is because MySQL does not raise an error when given an invalid date, but simply inserts "0000-00-00". The module handles error-checking transparently.

Errors are reported with Carp and the module returns 0 -- the author feels that dieing is unnecessary so long as the programmer remembers to check the values returned.

This version of the module requires Moose. Version 1.x is maintained for use by those who prefer not to install Moose and its dependencies on their system.

-------------------------------------

[1] This format is accepted in many, but not apparently all, circles as ISO format.

[2] MySQL also accepts strings as dates, but that behavior is not dealt with here.

[3] To quote from the MySQL docs: "Although MySQL tries to interpret values in several formats, it always expects the year part of date values to be leftmost. Dates must be given in year-month-day order (for example, '98-09-04'), rather than in the month-day-year or day-month-year orders commonly used elsewhere (for example, '09-04-98', '04-09-98')."

=head1 USAGE

To use this module you must first "use" it in your Perl program:

 use MySQL::DateFormat;

Then create a new object using the constructor provided:

 my $md = MySQL::DateFormat->new(format => 'eu');

(Note that it is required to specify a value for the 'format' argument.)

=head2 ARGUMENTS

=over 4 

=item B<format>

Since there are different standard date formats in use around the world, the module requires that you specify the format you need. Failure to supply a value for the 'format' argument to the constructor will result in the module croaking. Supported formats are 'us' and 'eu'.

 my $md = MySQL::DateFormat->new(format => 'eu');
 # returns and expects human-readable dates in DD-MM-YYYY format

 my $md = MySQL::DateFormat->new(format => 'us');
 # returns and expects human-readable dates in MM-DD-YYYY format

There is no default format.

=item B<century_cutoff>

If you want to change the default behavior of the toMySQL() method regarding two-digit years (see below) you can use the 'century_cutoff' argument:

 my $md = MySQL::DateFormat->new(century_cutoff => 15, format => 'us');
 # means a two-digit year of '16' will be read as '1916'

Or you can force the application to provide four-digit years (good Y2K practise but resisted by many human users):

 my $md = MySQL::DateFormat->new(century_cutoff => 'disallow', format => 'us');
 # carps and returns 0 unless the year has four digits

=item B<informal>

You can tell the module to return your dates in informal format, i.e. not include leading zeroes for months and days, and for years`:

 my $md = MySQL::DateFormat->new(format => 'us');
 # returns something like "05/09/1987"
 my $md = MySQL::DateFormat->new(informal => 1, format => 'us');
 # returns something like "5/9/1987"
 my $md = MySQL::DateFormat->new(informal => 2, format => 'us');
 #returns something like "5/9/87"

 Note that it is not required to allow informal (single-digit month and date) input; that's on by default

=item B<separator>

You can specify the separator you want to get in dates returned by frMySQL():

 my $md = MySQL::DateFormat->new(separator => "!");
 # will return something like "05!09!1987"

=back

=head2 METHODS

Now you can use your object to format dates:

 my $mysql_format_date = $md->toMySQL("5/09/87");
 my $human_format_date = $md->frMySQL("1987-05-09");

Here's a little more information on each of these methods:

=over 4

=item B<toMySQL()>

This method takes a date in human-readable format and reformats it for insertion into a MySQL database.

The method will return false if not provided a valid date, so programmers should check the return value.

It accepts date separators of '-' and '/' and will convert the latter to the former for MySQL.

 my $md = MySQL::DateFormat->new(format => 'eu');
 print $md->toMySQL("09/05/1987");
 # prints "1987-05-09"

It accepts months and dates of single-digit format, padding with a leading zero where the value is less than 10.

It accepts years of two-digit format, unless this is disallowed by setting the value of the constructor argument 'century_cutoff' to 'disallow', as shown above.

If two-digit years are allowed, the program adds the century thus: two-digit years from 00 to 20 are assigned to the 21st century (they have 2000 added to them) while two-digit years from 21 to 99 are assigned to the 20th century (they have 1900 added to them). This arbitrary default rule works for me; you can override it by setting the value of the constructor argument 'century_cutoff' to the highest number year you want to assign to the 21st century.

 my $md = MySQL::DateFormat->new(format => 'us');
 print $md->toMySQL("5/09/87");
 # prints "1987-05-09"

 $md = MySQL::DateFormat->new(century_cutoff => 87, format => 'us');
 print $md->toMySQL("5/09/87");
 # prints "2087-05-09"

=item B<frMySQL()>

This method takes a date returned from a MySQL query and reformats it for reading by a human.

The method will return false if not provided a valid date, so programmers should check the return value.

By default it returns dates with a separator of '/'; you can override this by setting the value of the constructor 'separator' argument to the character you wish to use.

 my $md = MySQL::DateFormat->new(separator => '!', format => 'us');
 print $md->frMySQL("1987-05-09");
 # prints "05!09!1987"

By default it returns dates with leading zeroes in months and dates less than 10, and years with four digits. You can turn this behavior off by setting the value of the constructor argument 'informal' to '1' or '2'; 

 my $md = MySQL::DateFormat->new(informal => 1, format => 'us');
 print $md->frMySQL("1987-05-09");
 # prints "5/9/1987"
 my $md = MySQL::DateFormat->new(informal => 2, format => 'us');
 print $md->frMySQL("1987-05-09");
 # prints "5/9/87"


=back

=head1 CHANGES

 v2.04
 o Added META.yml and META.json to the distribution

 v2.03
 o Fixed warning about not having Moose's enum values in an arrayref

 v2.02
 o Fixed a couple of typos in the documentation

 v2.01
 o Added a second true value for 'informal' argument so the year returned from MySQL can be trimmed to two digits

 v2.00
 o Rewritten using Moose

 v1.03
 o Previous version wasn't packaged right for PAUSE

 v1.02
 o Fixed missing prerequisite of Date::Calc in Makefile.PL

 v1.01
 o Fixed typo that was breaking European output format (Jorn Holm, jorn@zirus.no)

 v1.00
 o Repackaged for CPAN as MySQL::DateFormat as suggested on modules@perl.org

 v0.92
 o Removed default format; required format to be specified (suggested by several European members on datetime@perl.org)
 o Added discussion to docs of error-checking

=head1 AUTHOR

Author: Nick Tonkin (nick@websitebackendsolutions.com)

=head1 COPYRIGHT

Copyright (c) 2001-2015 Nick Tonkin. All rights reserved.

=head1 LICENSE

You may distribute this module under the same license as Perl itself.

=head1 SEE ALSO

L<Date::Calc>.

=cut
