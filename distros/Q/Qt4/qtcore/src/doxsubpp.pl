
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $perl = $ARGV[0];
my $in   = $ARGV[1];
my $out  = $ARGV[2];

my $mm = ExtUtils::MakeMaker->new( {
    NAME => 'PerlQt4',
    NEEDS_LINKING => 1,
} );

my $perl_include_path = $mm->{PERL_INC};
my @xsubinfo = split "\n", $mm->tool_xsubpp();

my ($xsubppdir) = map{ m/^XSUBPPDIR = (.*)/ } grep{ m/^XSUBPPDIR =/ } @xsubinfo;
my $xsubpp = "$xsubppdir/xsubpp";

my ($xsubppargs) = map{ m/^XSUBPPARGS = (.*)/ } grep{ m/^XSUBPPARGS =/ } @xsubinfo;

my @xsubppargs = split m/ /, $xsubppargs;

my @cmd = ($perl, $xsubpp, @xsubppargs, $in);
my $xsubpp_gencode = `@cmd`;
my $status = $? >> 8;
if ( $status != 0 ){
    die "Unable to run xsubpp to generate .c code from .xs: $!\n";
}

open my $FH, '>', $out;
print $FH $xsubpp_gencode;
close $FH;

exit 0;
