use utf8;
use Test::More tests => 23;
BEGIN {
	use_ok('Data::Sofu');
}

use Encode;

use Data::Sofu qw/readSofu writeSofu getSofuComments/; #We will need all of that.

my $VAR1 = {
          'List' => [
                    '',
                    '0',
                    undef,
                    '3'
                  ],
          'Sub Entry' => {
                         'Foo' => decode('ISO-8859-1', "Me\x{c4}ep!")
                       },
          'Testing' => [
                       '  Text with leading whitepace, and with 2 trailing spaces  ',
                       "\n2.Line\n3.Line\n",
                       "\r",
                       "Space \n Newline \n Space",
                       '4Spaces    end'
                     ],
          'Text' => 'Hello World',
          'Ruler' => [
                     '1',
                     '2',
                     '3',
                     decode('ISO-8859-1', "Me\x{c4}ep!"),
                     {
                       'SubSub' => {
                                   'Blubber' => [
                                                '1',
                                                '2',
                                                undef,
                                                '3'
                                              ],
                                   'Test' => undef
                                 }
                     },
                     [
                       decode('ISO-8859-1', "Me\x{c4}ep!")
                     ]
                   ]
        };
$VAR1->{Ruler}->[4]->{SubSub}->{Blubber}->[2]=[
                                                  '4',
                                                  $VAR1,
                                                  '5',
                                                  decode('ISO-8859-1', "Me\x{c4}ep!")
                                                ];
$VAR1->{Ruler}->[4]->{SubSub}->{Test}=$VAR1->{'Ruler'}[4];

#Prepearations done!
#print $dumptext,"\n";

#UTF 8
open $fh,">:raw:encoding(UTF-8)","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 8 Data (Unix, no BOM))");
#print Data::Dumper->Dump([scalar readSofu("test2.sofu")]);

open $fh,">:raw:encoding(UTF-8)","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 8 Data (Unix, with BOM))");

open $fh,">:raw:encoding(UTF-8):crlf:utf8","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 8 Data (Windows, no BOM))");

open $fh,">:raw:encoding(UTF-8):crlf:utf8","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 8 Data (Windows, with BOM))");


#UTF-16
open $fh,">:raw:encoding(UTF-16)","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Unix, machineorder, auto BOM))");

open $fh,">:raw:encoding(UTF-16):crlf:utf8","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Windows, machineorder, auto BOM))");

open $fh,">:raw:encoding(UTF-16LE)","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Unix, little endian, no BOM))");

open $fh,">:raw:encoding(UTF-16LE):crlf:utf8","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Windows, little endian, no BOM))");

open $fh,">:raw:encoding(UTF-16LE)","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Unix, little endian, forced BOM))");

open $fh,">:raw:encoding(UTF-16LE):crlf:utf8","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Windows, little endian, forced BOM))");

open $fh,">:raw:encoding(UTF-16BE)","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Unix, big endian, no BOM))");

open $fh,">:raw:encoding(UTF-16BE):crlf:utf8","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Windows, big endian, no BOM))");

open $fh,">:raw:encoding(UTF-16BE)","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Unix, big endian, forced BOM))");

open $fh,">:raw:encoding(UTF-16BE):crlf:utf8","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 16 Data (Windows, big endian, forced BOM))");

#UTF-32
open $fh,">:raw:encoding(UTF-32)","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Unix, machineorder, auto BOM))");

open $fh,">:raw:encoding(UTF-32):crlf:utf8","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Windows, machineorder, auto BOM))");

open $fh,">:raw:encoding(UTF-32LE)","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Unix, little endian, no BOM))");

open $fh,">:raw:encoding(UTF-32LE):crlf:utf8","test2.sofu";
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Windows, little endian, no BOM))");

open $fh,">:raw:encoding(UTF-32LE)","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Unix, little endian, forced BOM))");

open $fh,">:raw:encoding(UTF-32LE):crlf:utf8","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Windows, little endian, forced BOM))");

# These don't work for now:
#open $fh,">:raw:encoding(UTF-32BE)","test2.sofu";
#writeSofu($fh,$VAR1);
#close $fh;
#is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Unix, big endian, no BOM))");

#open $fh,">:raw:encoding(UTF-32BE):crlf:utf8","test2.sofu";
#writeSofu($fh,$VAR1);
#close $fh;
#is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Windows, big endian, no BOM))");

open $fh,">:raw:encoding(UTF-32BE)","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Unix, big endian, forced BOM))");

open $fh,">:raw:encoding(UTF-32BE):crlf:utf8","test2.sofu";
print $fh chr(65279); #BOM
writeSofu($fh,$VAR1);
close $fh;
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"readSofu (UTF 32 Data (Windows, big endian, forced BOM))");

unlink "test.sofu";
unlink "test2.sofu";

