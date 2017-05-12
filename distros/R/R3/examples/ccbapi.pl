#!/usr/bin/perl

use R3;

%logon = (
	client=>"100", 
	user=>"USER116",
	passwd=>"SECRET",
		host=>"shiva",
	sysnr=>0,
	pre4=>0,
);

print "\nCompany codes:\n";
eval {
	$conn=new R3::conn (%logon);
	$cc_tabl=new R3::itab ($conn, "BAPI0002_1");
	$bapireturn=new R3::itab ($conn, "BAPIRETURN");
	$func=new R3::func ($conn, "BAPI_COMPANYCODE_GETLIST");
	call $func ([], [COMPANYCODE_LIST=>$cc_tabl], RETURN=>$r);
	printf "\n%-4.4s %-25.25s\n\n", "CC", "NAME";
	for ($i=1; $i<=$cc_tabl->get_lines(); $i++)
	{
		%cc=$cc_tabl->get_record($i);
		printf "%-4.4s %-25.25s\n", $cc{COMP_CODE}, $cc{COMP_NAME};
	}
};
print $@ if $@;
%ret = $bapireturn->line2record($r);
print "$ret{TYPE}:$ret{CODE}:$ret{MESSAGE}\n" if ($ret && $ret ne "S");
