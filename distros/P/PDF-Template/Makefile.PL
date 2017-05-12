use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;

my $prereqs = {
    'pdflib_pl'      => 3.00,
    'Test::More'     => 0.01,
    'XML::Parser'    => 0.01,
    'IO::File'       => 0.01,
    'File::Basename' => 0.01,
};

# The assumption is Perl 5.8.0 and greater doesn't need Unicode::String.

my $use_unicode = 0;
if ($] < 5.008)
{
    print "Do you want Unicode support (y/N)? ";
    my $answer = <STDIN>;

    if ($answer =~ /^[Yy]/)
    {
            $prereqs->{'Unicode::String'} = '0.01';
            $use_unicode = 1;
    }
}

my $pm_filter = $use_unicode
    ? q{perl -pi -e "s!UNI_YES ! !g;s!UNI_NO  !\\#!g"}
    : q{perl -pi -e "s!UNI_NO  ! !g;s!UNI_YES !\\#!g"};

WriteMakefile(
    NAME         => 'PDF::Template',
    VERSION_FROM => 'lib/PDF/Template.pm', # finds $VERSION
    AUTHOR       => 'Rob Kinyon (rob.kinyon@gmail.com)',
    ABSTRACT     => 'PDF::Template',
    PREREQ_PM    => $prereqs,
    PM_FILTER    => $pm_filter,
);
