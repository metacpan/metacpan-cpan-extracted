use Test::More tests => 19;

use Encode;

use Data::Sofu qw/loadSofu readSofu unpackSofu writeSofuML getSofuComments packSofuML/; #We will need all of that.

{
	open FH,">:raw:encoding(UTF-16)","test.sofu";
	print FH q(#Text:  Text file
Sub<20>Entry = { #A map
	Foo = "Meep!"
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
                         'Foo' => "Meep!"
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
                     "Meep!",
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
                       "Meep!"
                     ]
                   ]
        };
#Evil References!
$VAR1->{Ruler}->[4]->{SubSub}->{Blubber}->[2]=[
                                                  '4',
                                                  $VAR1,
                                                  '5',
                                                  "Meep!"
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
my $string;
writeSofuML(\$string,$tree,$comments);
is($string,q(<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">
<Sofu id="1"><!-- Text:  Text file -->
	<Element key="List">
		<List id="2">
			<Value id="3" />
			<Value id="4">0</Value>
			<Undefined id="5" />
			<Value id="6">3</Value>
		</List>
	</Element>
	<Element key="Sub Entry">
		<Map id="7"><!-- A map
 End of Map -->
			<Element key="Foo">
				<Value id="8">Meep!</Value>
			</Element>
		</Map>
	</Element>
	<Element key="Testing">
		<List id="9">
			<Value id="10">&#x20;&#x20;Text with leading whitepace, and with 2 trailing spaces&#x20;&#x20;</Value>
			<Value id="11">&#xA;2.Line&#xA;3.Line&#xA;</Value>
			<Value id="12">&#xD;</Value>
			<Value id="13">Space&#x20;&#xA;&#x20;Newline&#x20;&#xA;&#x20;Space</Value>
			<Value id="14">4Spaces&#x20;&#x20;&#x20;&#x20;end</Value>
		</List>
	</Element>
	<Element key="Text">
		<Value id="15">Hello World</Value>
	</Element>
	<Element key="Ruler">
		<List id="16">
			<Value id="17">1</Value>
			<Value id="18">2</Value><!-- This is the second Value -->
			<Value id="19">3</Value>
			<Value id="20">Meep!</Value>
			<Map id="21">
				<Element key="SubSub">
					<Map id="22">
						<Element key="Blubber">
							<List id="23">
								<Value id="24">1</Value>
								<Value id="25">2</Value>
								<List id="26">
									<Value id="27">4</Value>
									<Reference idref="1" />
									<Value id="29">5</Value>
									<Value id="30">Meep!</Value>
								</List>
								<Value id="31">3</Value>
							</List>
						</Element>
						<Element key="Test">
							<Reference idref="21" /><!-- new Comment here -->
						</Element>
					</Map>
				</Element>
			</Map>
			<List id="33">
				<Value id="34">Meep!</Value>
			</List>
		</List>
	</Element>
</Sofu>
),"writeSofuML to scalarref");
is(packSofuML($tree,$comments),q(<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">
<Sofu id="1"><!-- Text:  Text file -->
<Element key="List">
<List id="2">
<Value id="3" />
<Value id="4">0</Value>
<Undefined id="5" />
<Value id="6">3</Value>
</List>
</Element>
<Element key="Sub Entry">
<Map id="7"><!-- A map
 End of Map -->
<Element key="Foo">
<Value id="8">Meep!</Value>
</Element>
</Map>
</Element>
<Element key="Testing">
<List id="9">
<Value id="10">&#x20;&#x20;Text with leading whitepace, and with 2 trailing spaces&#x20;&#x20;</Value>
<Value id="11">&#xA;2.Line&#xA;3.Line&#xA;</Value>
<Value id="12">&#xD;</Value>
<Value id="13">Space&#x20;&#xA;&#x20;Newline&#x20;&#xA;&#x20;Space</Value>
<Value id="14">4Spaces&#x20;&#x20;&#x20;&#x20;end</Value>
</List>
</Element>
<Element key="Text">
<Value id="15">Hello World</Value>
</Element>
<Element key="Ruler">
<List id="16">
<Value id="17">1</Value>
<Value id="18">2</Value><!-- This is the second Value -->
<Value id="19">3</Value>
<Value id="20">Meep!</Value>
<Map id="21">
<Element key="SubSub">
<Map id="22">
<Element key="Blubber">
<List id="23">
<Value id="24">1</Value>
<Value id="25">2</Value>
<List id="26">
<Value id="27">4</Value>
<Reference idref="1" />
<Value id="29">5</Value>
<Value id="30">Meep!</Value>
</List>
<Value id="31">3</Value>
</List>
</Element>
<Element key="Test">
<Reference idref="21" /><!-- new Comment here -->
</Element>
</Map>
</Element>
</Map>
<List id="33">
<Value id="34">Meep!</Value>
</List>
</List>
</Element>
</Sofu>
),"writeSofuML to scalarref");
writeSofuML(\$string,$objects);
unlink "test.sofu";
unlink "test.xml";
is($string,q(<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">
<Sofu id="1"><!-- Text:  Text file -->
	<Element key="Sub Entry">
		<Map id="2"><!-- A map
 End of Map -->
			<Element key="Foo">
				<Value id="3">Meep!</Value>
			</Element>
		</Map>
	</Element>
	<Element key="Ruler">
		<List id="4">
			<Value id="5">1</Value>
			<Value id="6">2</Value><!-- This is the second Value -->
			<Value id="7">3</Value>
			<Reference idref="3" />
			<Map id="9">
				<Element key="SubSub">
					<Map id="10">
						<Element key="Blubber">
							<List id="11">
								<Value id="12">1</Value>
								<Value id="13">2</Value>
								<List id="14">
									<Value id="15">4</Value>
									<Reference idref="1" />
									<Value id="17">5</Value>
									<Reference idref="3" />
								</List>
								<Value id="19">3</Value>
							</List>
						</Element>
						<Element key="Test">
							<Reference idref="9" /><!-- new Comment here -->
						</Element>
					</Map>
				</Element>
			</Map>
			<List id="21">
				<Reference idref="3" />
			</List>
		</List>
	</Element>
	<Element key="Text">
		<Value id="23">Hello World</Value>
	</Element>
	<Element key="List">
		<List id="24">
			<Value id="25" />
			<Value id="26">0</Value>
			<Undefined id="27" />
			<Value id="28">3</Value>
		</List>
	</Element>
	<Element key="Testing">
		<List id="29">
			<Value id="30">&#x20;&#x20;Text with leading whitepace, and with 2 trailing spaces&#x20;&#x20;</Value>
			<Value id="31">&#xA;2.Line&#xA;3.Line&#xA;</Value>
			<Value id="32">&#xD;</Value>
			<Value id="33">Space&#x20;&#xA;&#x20;Newline&#x20;&#xA;&#x20;Space</Value>
			<Value id="34">4Spaces&#x20;&#x20;&#x20;&#x20;end</Value>
		</List>
	</Element>
</Sofu>
),"writeML (Object tree)");
is(packSofuML($objects),q(<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">
<Sofu id="1"><!-- Text:  Text file -->
<Element key="Sub Entry">
<Map id="2"><!-- A map
 End of Map -->
<Element key="Foo">
<Value id="3">Meep!</Value>
</Element>
</Map>
</Element>
<Element key="Ruler">
<List id="4">
<Value id="5">1</Value>
<Value id="6">2</Value><!-- This is the second Value -->
<Value id="7">3</Value>
<Reference idref="3" />
<Map id="9">
<Element key="SubSub">
<Map id="10">
<Element key="Blubber">
<List id="11">
<Value id="12">1</Value>
<Value id="13">2</Value>
<List id="14">
<Value id="15">4</Value>
<Reference idref="1" />
<Value id="17">5</Value>
<Reference idref="3" />
</List>
<Value id="19">3</Value>
</List>
</Element>
<Element key="Test">
<Reference idref="9" /><!-- new Comment here -->
</Element>
</Map>
</Element>
</Map>
<List id="21">
<Reference idref="3" />
</List>
</List>
</Element>
<Element key="Text">
<Value id="23">Hello World</Value>
</Element>
<Element key="List">
<List id="24">
<Value id="25" />
<Value id="26">0</Value>
<Undefined id="27" />
<Value id="28">3</Value>
</List>
</Element>
<Element key="Testing">
<List id="29">
<Value id="30">&#x20;&#x20;Text with leading whitepace, and with 2 trailing spaces&#x20;&#x20;</Value>
<Value id="31">&#xA;2.Line&#xA;3.Line&#xA;</Value>
<Value id="32">&#xD;</Value>
<Value id="33">Space&#x20;&#xA;&#x20;Newline&#x20;&#xA;&#x20;Space</Value>
<Value id="34">4Spaces&#x20;&#x20;&#x20;&#x20;end</Value>
</List>
</Element>
</Sofu>
),"packSofuML (Object tree)");

	use Data::Dumper;
SKIP: {
	eval {
		require XML::Parser;
	};
	skip("XML::Parser not installed",13) if $@;
	my $string;
	writeSofuML(\$string,$tree,$comments);
	is_deeply(scalar readSofu(\$string),$VAR1,"Parsed SofuML from scalarref");
	is_deeply(getSofuComments(),$comments,"Comments assertion");
	is_deeply(scalar unpackSofu($string),$VAR1,"unpacked SofuML from scalarref");
	is_deeply(getSofuComments(),$comments,"Comments assertion");
	$string=packSofuML($tree,$comments);
	is_deeply(scalar readSofu(\$string),$VAR1,"Parsed SofuML from scalar");
	is_deeply(getSofuComments(),$comments,"Comments assertion");
	is_deeply(scalar unpackSofu($string),$VAR1,"unpacked SofuML from scalar");
	is_deeply(getSofuComments(),$comments,"Comments assertion");
	writeSofuML("test.xml",$tree,$comments);
	is_deeply(scalar readSofu("test.xml"),$VAR1,"Parsed SofuML from file");
	is_deeply(getSofuComments(),$comments,"Comments assertion");

	writeSofuML(\$string,$objects);
	is_deeply(scalar loadSofu(\$string),$objects,"Parsed Sofu-Objects from scalarref");
	$string=packSofuML($objects);
	is_deeply(scalar loadSofu(\$string),$objects,"Parsed Sofu-Objects from scalar");
	writeSofuML("test.xml",$objects);
	is_deeply(scalar loadSofu("test.xml"),$objects,"Parsed Sofu-Objects from file");

};
unlink "test.sofu";
unlink "test.xml";
