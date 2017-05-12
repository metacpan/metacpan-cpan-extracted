use utf8;
use Test::More tests => 136;

use Encode;

use Data::Sofu qw/loadSofu readSofu writeBinarySofu getSofuComments packBinarySofu/; #We will need all of that.

{
	open FH,">:raw:encoding(UTF-16)","test.sofu";
	print FH q(#Text:  Text file
Sub<20>Entry = { #A map
	Foo = "MeÄep!"
}# End of Map
Ruler = (
	"1"
	"2" #This is the second Value
	"3"
	@Sub<20>Entry->Foo
	{
		SubSub= {
			Blubber = ("1" "2" (4 @-> 5 @->Sub<20>Entry->Foo) "3")
			Test = @->Ruler->4 #new Comment here
		}
	}
	(
		@->Sub<20>Entry->Foo
	)
)
Text = "Hello World"
List = (
""
0
UNDEF
3
)
Testing = (
	"  Text with leading whitepace, and with 2 trailing spaces  "
	"\n2.Line\\n3.Line\n"
	"\r"
	"Space \n Newline \n Space"
	"4Spaces    end"
)
);
	close FH;
}

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
#Evil References!
$VAR1->{Ruler}->[4]->{SubSub}->{Blubber}->[2]=[
                                                  '4',
                                                  $VAR1,
                                                  '5',
                                                  decode('ISO-8859-1', "Me\x{c4}ep!")
                                                ];
$VAR1->{Ruler}->[4]->{SubSub}->{Test}=$VAR1->{'Ruler'}[4];

my $objects;
my $tree;
my $comments;
eval {
$objects = loadSofu("test.sofu");
$tree = readSofu("test.sofu"); #Reading comments
$comments=getSofuComments();
};
ok(not($@),"loadSofu");
diag($@) if $@;
undef $@;
is_deeply($tree,$VAR1,"readSofu (Sanity check)");
#Screwed up Order.
eval {
writeBinarySofu("test.bsofu",$tree,$comments);
};
ok(not($@),"writeBinarySofu");
diag($@) if $@;
undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary (default)");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,0,undef,undef);};ok(not($@),"writeBinarySofu encoding utf-8, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding utf-8, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,1,undef,undef);};ok(not($@),"writeBinarySofu encoding utf-7, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding utf-7, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-16",undef,undef);};ok(not($@),"writeBinarySofu encoding UTF-16, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-16BE",undef,undef);};ok(not($@),"writeBinarySofu encoding UTF-16BE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16BE, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-16LE",undef,undef);};ok(not($@),"writeBinarySofu encoding UTF-16LE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16BE, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");


eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-32",undef,undef);};ok(not($@),"writeBinarySofu encoding UTF-16, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-32BE",undef,undef);};ok(not($@),"writeBinarySofu encoding UTF-16BE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16BE, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-32LE",undef,undef);};ok(not($@),"writeBinarySofu encoding UTF-16LE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16BE, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"latin1",undef,undef);};ok(not($@),"writeBinarySofu encoding latin1, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding latin1, byteorder default, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");


eval {writeBinarySofu("test.bsofu",$tree,$comments,0,"7Bit",undef);};ok(not($@),"writeBinarySofu encoding utf-8, byteorder 7Bit, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding utf-8, byteorder 7Bit, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,1,"LE",undef);};ok(not($@),"writeBinarySofu encoding utf-7, byteorder LE, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding utf-7, byteorder LE, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-16","BE",undef);};ok(not($@),"writeBinarySofu encoding UTF-16, byteorder BE, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16, byteorder BE, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-16BE","NOFORCE7BIT",undef);};ok(not($@),"writeBinarySofu encoding UTF-16BE, byteorder NOFORCE7BIT, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16BE, byteorder NOFORCE7BIT, Sofumark default");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-16LE","7Bit",0);};ok(not($@),"writeBinarySofu encoding UTF-16LE, byteorder 7Bit, Sofumark 0%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16LE, byteorder 7Bit, Sofumark 0%");
is_deeply(getSofuComments(),$comments,"Comments assertion");


eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-32","LE",1);};ok(not($@),"writeBinarySofu encoding UTF-16, byteorder LE, Sofumark 100%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16, byteorder LE, Sofumark 100%");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-32BE","BE",0.5);};ok(not($@),"writeBinarySofu encoding UTF-16BE, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16BE, byteorder BE, Sofumark 50%");
is_deeply(getSofuComments(),$comments,"Comments assertion");

eval {writeBinarySofu("test.bsofu",$tree,$comments,"UTF-32LE","NOFORCE7BIT",0.66);};ok(not($@),"writeBinarySofu encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu("test.bsofu"),$VAR1,"writeBinary encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");
is_deeply(getSofuComments(),$comments,"Comments assertion");


my $str;
eval {$str = packBinarySofu($tree,$comments,"UTF-7","7Bit",0);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-7, byteorder 7Bit, Sofumark 0%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-7, byteorder 7Bit, Sofumark 0%");


eval {$str = packBinarySofu($tree,$comments,"UTF-16BE","LE",1);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-16BE, byteorder LE, Sofumark 100%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-16BE, byteorder LE, Sofumark 100%");

eval {$str = packBinarySofu($tree,$comments,"UTF-8","BE",0.5);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-8, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-8, byteorder BE, Sofumark 50%");

eval {$str = packBinarySofu($tree,$comments,"UTF-16LE","NOFORCE7BIT",0.66);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-16, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");

$str="";
eval {writeBinarySofu(\$str,$tree,$comments,"UTF-7","7Bit",0);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-7, byteorder 7Bit, Sofumark 0%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-7, byteorder 7Bit, Sofumark 0%");


eval {writeBinarySofu(\$str,$tree,$comments,"UTF-16BE","LE",1);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-16BE, byteorder LE, Sofumark 100%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-16BE, byteorder LE, Sofumark 100%");

eval {writeBinarySofu(\$str,$tree,$comments,"UTF-8","BE",0.5);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-8, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-8, byteorder BE, Sofumark 50%");

eval {writeBinarySofu(\$str,$tree,$comments,"UTF-16LE","NOFORCE7BIT",0.66);};ok((not($@) and $str),"packBinarySofu(Object) encoding UTF-16, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar readSofu(\$str),$VAR1,"loadSofu encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");


eval {
writeBinarySofu("test.bsofu",$objects,undef);
};
ok(not($@),"writeBinary(Object)");
diag($@) if $@;
undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu (default)");

eval {writeBinarySofu("test.bsofu",$objects,undef,0,undef,undef);};ok(not($@),"writeBinary(Object) encoding utf-8, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding utf-8, byteorder default, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,1,undef,undef);};ok(not($@),"writeBinary(Object) encoding utf-7, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding utf-7, byteorder default, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-16",undef,undef);};ok(not($@),"writeBinary(Object) encoding UTF-16, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16, byteorder default, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-16BE",undef,undef);};ok(not($@),"writeBinary(Object) encoding UTF-16BE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16BE, byteorder default, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-16LE",undef,undef);};ok(not($@),"writeBinary(Object) encoding UTF-16LE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16BE, byteorder default, Sofumark default");


eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-32",undef,undef);};ok(not($@),"writeBinary(Object) encoding UTF-16, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16, byteorder default, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-32BE",undef,undef);};ok(not($@),"writeBinary(Object) encoding UTF-16BE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16BE, byteorder default, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-32LE",undef,undef);};ok(not($@),"writeBinary(Object) encoding UTF-16LE, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16BE, byteorder default, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"latin1",undef,undef);};ok(not($@),"writeBinary(Object) encoding latin1, byteorder default, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding latin1, byteorder default, Sofumark default");


eval {writeBinarySofu("test.bsofu",$objects,undef,0,"7Bit",undef);};ok(not($@),"writeBinary(Object) encoding utf-8, byteorder 7Bit, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding utf-8, byteorder 7Bit, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,1,"LE",undef);};ok(not($@),"writeBinary(Object) encoding utf-7, byteorder LE, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding utf-7, byteorder LE, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-16","BE",undef);};ok(not($@),"writeBinary(Object) encoding UTF-16, byteorder BE, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16, byteorder BE, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-16BE","NOFORCE7BIT",undef);};ok(not($@),"writeBinary(Object) encoding UTF-16BE, byteorder NOFORCE7BIT, Sofumark default");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16BE, byteorder NOFORCE7BIT, Sofumark default");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-16LE","7Bit",0);};ok(not($@),"writeBinary(Object) encoding UTF-16LE, byteorder 7Bit, Sofumark 0%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16LE, byteorder 7Bit, Sofumark 0%");


eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-32","LE",1);};ok(not($@),"writeBinary(Object) encoding UTF-16, byteorder LE, Sofumark 100%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16, byteorder LE, Sofumark 100%");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-32BE","BE",0.5);};ok(not($@),"writeBinary(Object) encoding UTF-16BE, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16BE, byteorder BE, Sofumark 50%");

eval {writeBinarySofu("test.bsofu",$objects,undef,"UTF-32LE","NOFORCE7BIT",0.66);};ok(not($@),"writeBinary(Object) encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test.bsofu"),$objects,"loadSofu encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");

#is_deeply(scalar loadSofu("test.bsofu"),$objects,"writeBinary (default)");

my $stro;
eval {$stro = packBinarySofu($objects,undef,"UTF-7","7Bit",0);};ok((not($@) and $stro),"packBinarySofu(Object) encoding UTF-7, byteorder 7Bit, Sofumark 0%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-7, byteorder 7Bit, Sofumark 0%");


eval {$stro = packBinarySofu($objects,undef,"UTF-16BE","LE",1);};ok((not($@) and $stro),"packBinarySofu(Object) encoding UTF-16BE, byteorder LE, Sofumark 100%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-16BE, byteorder LE, Sofumark 100%");

eval {$stro = packBinarySofu($objects,undef,"UTF-8","BE",0.5);};ok((not($@) and $stro),"packBinarySofu(Object) encoding UTF-8, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-8, byteorder BE, Sofumark 50%");

eval {$stro = packBinarySofu($objects,undef,"UTF-16LE","NOFORCE7BIT",0.66);};ok((not($@) and $stro),"packBinarySofu(Object) encoding UTF-16, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");

$stro="";
eval {writeBinarySofu(\$stro,$objects,undef,"UTF-7","7Bit",0);};ok((not($@) and $stro),"WriteBinarySofu(Scalarref)(Object) encoding UTF-7, byteorder 7Bit, Sofumark 0%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-7, byteorder 7Bit, Sofumark 0%");


eval {writeBinarySofu(\$stro,$objects,undef,"UTF-16BE","LE",1);};ok((not($@) and $stro),"WriteBinarySofu(Scalarref)(Object) encoding UTF-16BE, byteorder LE, Sofumark 100%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-16BE, byteorder LE, Sofumark 100%");

eval {writeBinarySofu(\$stro,$objects,undef,"UTF-8","BE",0.5);};ok((not($@) and $stro),"WriteBinarySofu(Scalarref)(Object) encoding UTF-8, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-8, byteorder BE, Sofumark 50%");

eval {writeBinarySofu(\$stro,$objects,undef,"UTF-16LE","NOFORCE7BIT",0.66);};ok((not($@) and $stro),"WriteBinarySofu(Scalarref)(Object) encoding UTF-16, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-16LE, byteorder NOFORCE7BIT, Sofumark 66%");



eval {$stro = $objects->binaryPack("UTF-8","BE",0.5);};ok((not($@) and $stro),"packBinarySofu(Object based writer) encoding UTF-8, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-8, byteorder BE, Sofumark 50%");

eval {$stro = $objects->binaryPack("latin1","NOFORCE7BIT",0.66);};ok((not($@) and $stro),"packBinarySofu(Object based writer) encoding latin1, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding latin1, byteorder NOFORCE7BIT, Sofumark 66%");

$stro="";
eval {$objects->writeBinary(\$stro,"UTF-7","7Bit",0);};ok((not($@) and $stro),"WriteBinarySofu(Scalarref)(Object based writer) encoding UTF-7, byteorder 7Bit, Sofumark 0%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding UTF-7, byteorder 7Bit, Sofumark 0%");


eval {$objects->writeBinary(\$stro,"latin1","LE",1);};ok((not($@) and $stro),"WriteBinarySofu(Scalarref)(Object based writer) encoding latin1, byteorder LE, Sofumark 100%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu(\$stro),$objects,"loadSofu encoding latin1, byteorder LE, Sofumark 100%");

eval {$objects->writeBinary("test2.sofu","UTF-8","BE",0.5);};ok((not($@) and $stro),"WriteBinarySofu(Object based writer) encoding UTF-8, byteorder BE, Sofumark 50%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test2.sofu"),$objects,"loadSofu encoding UTF-8, byteorder BE, Sofumark 50%");

eval {$objects->writeBinary("test2.sofu","latin1","NOFORCE7BIT",0.66);};ok((not($@) and $stro),"WriteBinarySofu(Object based writer) encoding latin1, byteorder NOFORCE7BIT, Sofumark 66%");diag($@) if $@;undef $@;
is_deeply(scalar loadSofu("test2.sofu"),$objects,"loadSofu encoding latin1, byteorder NOFORCE7BIT, Sofumark 66%");





unlink "test.sofu";
unlink "test2.sofu";
unlink "test.bsofu";

