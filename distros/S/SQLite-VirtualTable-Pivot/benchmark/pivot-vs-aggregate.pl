#!/usr/bin/perl

use strict;
use IO::File;
use File::Temp;

#my $template = "select attribute_001 from %s where attribute_001 < %d;";
my $template = "select * from %s where attribute_001=%d and attribute_002 > 0;";
#my $template = "select * from %s where attribute_001=%d;";
#my $template = "select attribute_001, count(1) from %s group by 1 limit %d;";
#my $template = <<FIN;
#select id,attribute_001,attribute_002 from %s
#where (attribute_001 between 100 and 900)
#    and (attribute_002 between %d and 900)
#    and (attribute_003 < 800 or attribute_003 > 900) order by id;
#FIN

sub _do_query {
    my $query = shift;
    my $do_twice = shift;

    my $outfile = "/tmp/sqlout"; unlink $outfile;
    my $errfile = "/tmp/sqlerr"; unlink $errfile;
    my $timefile = "/tmp/sqltime"; unlink $timefile;
    my $fp = File::Temp->new();

    print $fp ".output $outfile\n";
    print $fp ".header off\n";
    print $fp ".mode columns\n";
    #print $fp ".echo  on\n";
    print $fp ".load perlvtab.so\n";
    print $fp "$query\n" if $do_twice;
    print $fp ".timer on\n";
    print $fp "$query\n";
    $fp->close or die;

    system ("/usr/bin/sqlite3 -init $fp /tmp/vpt_test.db < /dev/null > $timefile")==0 or die "system call failed: $!";
    my @rows = IO::File->new("<$outfile")->getlines; 
    my @time = IO::File->new("<$timefile")->getlines; 
    #print "got ".( @got - 2 )." rows\n";
    #print for @rows;
    #print for @time;
    my ($time) = $time[0] =~ /user (\S+)/;

    #printf ("rows : %5d  time: %2.1f\n",scalar(@rows)-2,$time);
    return ( (scalar(@rows)), $time );
}

printf "%10s %10s %10s %10s %10s %10s\n", "X","rows", "aggregate", "virtual (first)", "virtual (second)";
for my $i (0,1,2,3,10,20,30,40,50,100,200,500) {
    my ($vrows,$vtime) =_do_query( sprintf($template,"virtual_pivot_table",$i)     );
    my ($arows,$atime) =_do_query( sprintf($template,"aggregate_pivot_table",$i)   );
    my ($vrows2,$vtime2) =_do_query( sprintf($template,"virtual_pivot_table",$i)  ,1 );
    die "$arows != $vrows" unless $arows==$vrows;
    die "$arows *2 != $vrows2" unless $arows * 2==$vrows2;
    printf("%10d %10d %10.1f %10.1f %10.1f\n",$i,$arows,$atime,$vtime,$vtime2);
}



