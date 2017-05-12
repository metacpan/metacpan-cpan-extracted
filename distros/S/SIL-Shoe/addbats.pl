#! perl
foreach $f (qw(csv2sh.bat sh2csv.bat sh2odt.bat sh2sh.bat sh2xml.bat sh_rtf.bat shadd.bat shdiff3.bat shdiffn.bat shed.bat shintr.bat shlex.bat xml2sh.bat zipdiff.bat zipmerge.bat zippatch.bat encrem.bat))
{
    if ($ARGV[0] eq '-r')
    {
        unlink "$ARGV[1]\\$f";
    }
    else
    {
        my ($pl) = $f;
        $pl =~ s/\.bat//o;
        open(FH, "> $ARGV[0]\\$f") || die $@;
        print FH "@\"$ARGV[0]\\parl.exe\" \"$ARGV[0]\\shutils.par\" $pl %1 %2 %3 %4 %5 %6 %7 %8 %9\n";
        close(FH);
    }
}
