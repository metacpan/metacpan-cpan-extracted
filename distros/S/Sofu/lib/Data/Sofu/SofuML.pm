###############################################################################
#SofuML.pm
#Last Change: 2009-28-01
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.3
####################
#This file is part of the sofu.pm project, a parser library for an all-purpose
#ASCII file format. More information can be found on the project web site
#at http://sofu.sourceforge.net/ .
#
#sofu.pm is published under the terms of the MIT license, which basically means
#"Do with it whatever you want". For more information, see the license.txt
#file that should be enclosed with libsofu distributions. A copy of the license
#is (at the time of this writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

=head1 NAME

Data::Sofu::SofuML - Interface to various binary drivers

=head1 DESCRIPTION

This Module is used to convert Sofu Trees to XML Tree.

This is mostly for convertig Sofu data via XSLT or similar.

You don't need to use this module directly.

=head1 Synopsis 
	
	use Data::Sofu;
	my $sofu = readSofu("file.sofu");
	writeSofuML("file.xml",$sofu,getSofucomments());
	#And back
	my $xml = readSofu("file.xml"); #readSofu can detect SofuML files.
	writeSofu("file.sofu",$xml,getSofucomments());

Using the Sofu OO syntax:

	require Data::Sofu;
	my $s = Data::Sofu::new();
	my $sofu = $s->read("file.sofu");
	$s->writeML("file.xml",$sofu,$s->comments());
	#And back
	my $xml = $s->read("file.xml"); #read also detects SofuML files.
	$s->write("file.sofu",$xml,$s->comments());

Using scalars instead of files:

	require Data::Sofu;
	my $s = Data::Sofu::new();
	my $sofu = $s->read("file.sofu");
	my $xmlstring = $s->packML($sofu,$s->comments()); #Contains now the xml files content
	my $xml = $s->unpack($xmlstring);
	$s->write($xml,$s->comments());

But: $scalar=packML() is not the same as writeML(\$scalar), packML will not indent the file.

	

=head1 SYNTAX

This Module is pure OO, exports nothing

=cut

package Data::Sofu::SofuML;
use strict;
use warnings;

our $VERSION="0.3";
#We are really going to need these modules:
use Encode;
use Carp qw/confess cluck/;
require Data::Sofu;

=head1 METHODS

Most of these Methods (except pack()) are ony for internal use.

=head2 new()

Creates a new C<Data::Sofu::SofuML> and returns it.

=cut 

sub new {
	my $self={};
	bless $self,shift;
	$self->{IDS} = {};
	$self->{ID} = 0;
	$self->{INDENT} = "\t";
	return $self;
}

=head2 whiteescape (STRING)

Escapes whitespace for use in XML

=cut

sub whiteescape {
	my $self=shift;
	my $data = shift;
	return $data if ($data eq " ");
	my $f = "";
	$data=~s/(.)/sprintf("&#x%X;",ord($1))/esg;
	
	return $f.$data;
}

=head2 XMLescapeOld(STRING,LEVEL)

Older version of XMLescape, still need by some.

=cut

sub XMLescapeOld {
	my $self=shift;
	my $string=shift;
	my $level=shift;
	$string =~ s/\&/&amp;/g;
	$string =~ s/\</&lt;/g;
	$string =~ s/\>/&gt;/g;
	$string =~ s/\"/&quot;/g;
	$string =~ s/\'/&apos;/g;
	$string=~s"^([\s\n\x0A]+)"join '',map {sprintf('&#x%X;' ,ord($_))} split //,$1"emg;
	$string=~s/([\s\n\x0A]+)$/join '',map {sprintf('&#x%X;' ,ord($_))} split m##,$1/emg;
	$string =~ s/([\s]+)/$self->whiteescape($1)/eg;
	$string=~s/([\ ]{2,})/join '',map {sprintf('&#x%X;' ,ord($_))} split m##,$1/eg;
	$string=~s/\n/"\n".$self->indent($level)/eg;
	#$string=~s/\n/$self->indent($level)."\n"/eg;
	return $string;
	#return $self->indent($level).$string; #makes bad Juju with XSLT
}

=head2 XMLescape(STRING,LEVEL)

Returns the (quite badly) escaped form of STRING

=cut

sub XMLescape {
	my $self=shift;
	my $string=shift;
	my $level=shift;
	$string =~ s/\&/&amp;/g;
	$string =~ s/\</&lt;/g;
	$string =~ s/\>/&gt;/g;
	$string =~ s/\"/&quot;/g;
	$string =~ s/\'/&apos;/g;
	$string=~s"^([\s\n\x0A]+)"join '',map {sprintf('&#x%X;' ,ord($_))} split //,$1"emg;
	$string=~s/([\s\n\x0A]+)$/join '',map {sprintf('&#x%X;' ,ord($_))} split m##,$1/emg;
	$string =~ s/([\s\n\x0A]+)/$self->whiteescape($1)/eg;
	#$string=~s/\n/$self->indent($level)."\n"/eg;
	return $string;
	#return $self->indent($level).$string; #makes bad Juju with XSLT
}

=head2 XMLunescape(STRING)

Inversion of XMLescape

=cut

sub XMLunescape {
	my $string=shift;
	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;
	$string =~ s/\s*\n\s*/\n/g;
	$string =~ s/[\s[^\n]]+/ /g;
	$string =~ s/&#x([\dabcdefABCDEF]+);/chr(hex($1))/eg;
	$string =~ s/&#([\dabcdefABCDEF]+);/chr($1)/eg;
	$string =~ s/&lt;/</g;
	$string =~ s/&gt;/>/g;
	$string =~ s/&quot;/"/g;
	$string =~ s/&apos;/'/g;
	$string =~ s/&amp;/&/g;
	return $string;
}

=head2 XMLunescapeRestrictive(STRING)

Like XMLunescape, but more restrictive (currently not used)

=cut

sub XMLunescapeRestrictive {
	my $string=shift;
	$string =~ s/^\s+//g;
	$string =~ s/\s+$//g;
	$string =~ s/\s*\n\s*/ /g;
	$string =~ s/[\s[^\n]]+/ /g;
	$string =~ s/&#x([\dabcdefABCDEF]+);/chr(hex($1))/eg;
	$string =~ s/&#([\dabcdefABCDEF]+);/chr($1)/eg;
	$string =~ s/&lt;/</g;
	$string =~ s/&gt;/>/g;
	$string =~ s/&quot;/"/g;
	$string =~ s/&apos;/'/g;
	$string =~ s/&amp;/&/g;
	return $string;
}

=head2 XMLKeyescape(KEY)

Returns the (quite badly) escaped form of KEY

=cut


sub XMLKeyescape {
	my $self=shift;
	my $string=shift;
	$string =~ s/\&/&amp;/g;
	$string =~ s/\</&lt;/g;
	$string =~ s/\>/&gt;/g;
	$string =~ s/\"/&quot;/g;
	$string =~ s/\'/&apos;/g;
	$string =~ s/([^[:print:]])/sprintf("&#x%X;",ord($1))/eg;
	return $string;
}

=head2 genID() 

Returns a new unqiue ID

=cut

sub genID {
	my $self=shift;
	return $self->{ID}++;
}

=head2 indent(LEVEL)

Returns the indentation for LEVEL

=cut

sub indent {
	my $self=shift;
	my $level = shift;
	return $self->{INDENT} x $level;
}

=head2 packObjectComment(OBJECT)

Returns the packed comment of OBJECT

=cut

sub packObjectComment {
	my $self=shift;
	my $data=shift;
	if ($data->hasComment()) {
		my $str = join("\n",@{$data->getComment()});
		$str=~s/&gt;/&amp;gt;/g;
		$str=~s/-->/--&gt;/g;
		return "<!-- $str -->" ;
	}
	return "";
}

=head2 packComment(TREE)

Returns the packed comment of the object reference by TREE

=cut

sub packComment {
	my $self=shift;
	my $tree=shift;
	return "" unless $self->{COMMENT}->{$tree};
	return "" unless ref $self->{COMMENT}->{$tree};
	return "" unless ref $self->{COMMENT}->{$tree} eq "ARRAY";
	my $str = join("\n",@{$self->{COMMENT}->{$tree}});
	$str=~s/&gt;/&amp;gt;/g;
	$str=~s/-->/--&gt;/g;
	return "<!-- $str -->" ;
}

=head2 packElement(ELEMENT,OBJECT,LEVEL,ID) 

Returns the ELEMENT for OBJECT

=cut

sub packElement {
	my $self=shift;
	my $elem=shift;
	my $data=shift;
	my $level=shift;
	my $id=shift;
	return $self->indent($level)."<$elem id=\"$id\">".$self->packObjectComment($data);
}

=head2 packElement2(ELEMENT,OBJECT,LEVEL,ID) 

Same as packElement, without comments.

=cut

sub packElement2 {
	my $self=shift;
	my $elem=shift;
	my $data=shift;
	my $level=shift;
	my $id=shift;
	return $self->indent($level)."<$elem id=\"$id\">";
}

=head2 packItem(ELEMENT,LEVEL,ID,TREE) 

Returns the the XML version of an item

=cut

sub packItem {
	my $self=shift;
	my $elem=shift;
	my $level=shift;
	my $id=shift;
	my $tree=shift;
	return $self->indent($level)."<$elem id=\"$id\">".$self->packComment($tree)
}

=head2 packItem2(ELEMENT,LEVEL,ID,TREE) 

Same as packItem, but doesn't write a comment.

=cut

sub packItem2 {
	my $self=shift;
	my $elem=shift;
	my $level=shift;
	my $id=shift;
	my $tree=shift;
	return $self->indent($level)."<$elem id=\"$id\">"
}


=head2 packObjectData(OBJECT,LEVEL)

Converts one Data::Sofu::Object into its XML representation

=cut

sub packObjectData {
	my $self=shift;
	my $data=shift;
	my $level=shift;
	my $id = $self->genID();
	my $r = ref $data;
	#Maybe call packData on unknown Datastructures..... :)
	die ("Unknown Datastructure, can only work with Arrays and Hashes but not $r") unless $r and $r =~ m/Data::Sofu/ and $r->isa("Data::Sofu::Object");

	my $odata=$data;
	if ($data->isReference() and $data->valid()) {
		$data=$data->follow();
	}
	if ($data->isReference()) { #Reference to a Reference not yet allowed!
		croak("No Reference to a Reference allowed for now!");
		return $self->indent($level)."<Undefined id=\"$id\" />\n".$self->packObjectComment($odata)."\n";
	}
	if ($self->{IDS}->{$data}) {
		return $self->indent($level)."<Reference idref=\"$self->{IDS}->{$data}\" />".$self->packObjectComment($odata)."\n";
	}
	$self->{IDS}->{$data}=$id;
	$self->{IDS}->{$odata}=$id;
	if ($data->isValue()) {
		return $self->packElement2("Value",$odata,$level,$id).$self->XMLescape($data->toString(),$level+1)."</Value>".$self->packObjectComment($odata)."\n" if $data->toString() ne "";
		return $self->indent($level)."<Value id=\"$id\" />".$self->packObjectComment($odata)."\n";
	}
	if ($data->isMap()) {
		my $str=$self->packElement("Map",$odata,$level,$id)."\n";
		foreach my $key	($data->orderedKeys()) {
			$str.=$self->indent($level+1)."<Element key=\"".$self->XMLKeyescape($key)."\">\n";
			$str.=$self->packObjectData($data->object($key),$level+2);
			$str.=$self->indent($level+1)."</Element>\n";
		}
		return $str.$self->indent($level)."</Map>\n";
	}
	if ($data->isList()) {
		my $str=$self->packElement("List",$odata,$level,$id)."\n";
		while (my $element = $data->next()) {
			$str.=$self->packObjectData($element,$level+1);
		}
		return $str.$self->indent($level)."</List>\n"
	}
	return $self->indent($level)."<Undefined id=\"$id\" />\n".$self->packObjectComment($odata);
}

=head2 packData(DATA,LEVEL,TREE)

Converts one perl structure into its XML representation

=cut

sub packData {
	my $self=shift;
	my $data=shift;
	my $level=shift;
	my $tree=shift;
	my $id = $self->genID();
	if (ref $data) {
		if ($self->{IDS}->{$data}) {
			return $self->indent($level)."<Reference idref=\"$self->{IDS}->{$data}\" />".$self->packComment($tree)."\n";
		}
		$self->{IDS}->{$data}=$id;
		if (ref $data eq "HASH") {
			my $str=$self->packItem("Map",$level,$id,$tree)."\n";
			foreach my $key	(sort keys %{$data}) {
				$str.=$self->indent($level+1)."<Element key=\"".$self->XMLKeyescape($key)."\">\n";
				$str.=$self->packData($data->{$key},$level+2,$tree."->".Data::Sofu::Sofukeyescape($key));
				$str.=$self->indent($level+1)."</Element>\n";
			}
			return $str.$self->indent($level)."</Map>\n";
		}
		if (ref $data eq "ARRAY") {
			my $str=$self->packItem("List",$level,$id,$tree)."\n";
			my $i=0;
			foreach my $element (@{$data}) {
				$str.=$self->packData($element,$level+1,$tree."->".$i++);
			}
			return $str.$self->indent($level)."</List>\n"
		}
		else {
			confess "Can't pack: ",ref $data," @ $tree";
		}
	}
	if (defined ($data)) {
		return $self->packItem2("Value",$level,$id,$tree).$self->XMLescape($data,$level+1)."</Value>".$self->packComment($tree)."\n" if $data ne "";
		return $self->indent($level)."<Value id=\"$id\" />".$self->packComment($tree)."\n";
	}
	return $self->indent($level)."<Undefined id=\"$id\" />\n".$self->packComment($tree);
}


=head2 packObject(OBJECT,[HEADER])

Converts one Data::Sofu::Object into its XML representation

=cut

sub packObject {
	my $self=shift;
	my $data=shift;
	my $r = ref $data;
	my $header=shift;
	my $level=int(shift || 0);
	$level=0 unless $level;
	#Maybe call packData on unknown Datastructures..... :)
	die ("Unknown Datastructure, can only work with Data::Sofu::Object's but not $r, did you mean pack() ?") unless $r and $r =~ m/Data::Sofu/ and $r->isa("Data::Sofu::Object");
	unless ($data->isMap()) {
		my $m = new Data::Sofu::Map();
		$m->setAttribute("Value",$data);
		$data=$m;
	}
	$self->{IDS} = {};
	$self->{ID} = 1;
	my $id = $self->genID();
	$self->{IDS}->{$data}=$id;
	my $str="";
	$str.=qq(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">\n) unless ($header);
	$str.=$header if $header;
	$str.=$self->packElement("Sofu",$data,$level,$id)."\n";
	foreach my $key	($data->orderedKeys()) {
		$str.=$self->indent($level+1)."<Element key=\"".$self->XMLKeyescape($key)."\">\n";
		$str.=$self->packObjectData($data->object($key),$level+2);
		$str.=$self->indent($level+1)."</Element>\n";
	}
	return $str.$self->indent($level)."</Sofu>\n";
}

=head2 pack(TREE,[COMMENTS,[HEADER]])

packs TREE to XML using Comments

=over

=item TREE

Perl datastructure to pack. Can be a hash, array or scalar (or array of hashes of hashes of arrays or whatever). Anything NOT a hash will be converted to TREE={Value=>TREE};

It can also be a Data::Sofu::Object or derived (Data::Sofu::Map, Data::Sofu::List, Data::Sofu::Value, Data::Sofu::...).
Anything not a Data::Sofu::Map will be converted to one (A Map with one attribute called "Value" that holds TREE).

=item COMMENTS

Comment hash (as returned by Data::Sofu::getSofucomments() or Data::Sofu->new()->comments() after any file was read).

These are ignored if TREE is a Data::Sofu::Object or derived. Data::Sofu::Object's store their comments in themselves. See Data::Sofu::Object->importComments() to import them.

Can be undef or {}.

=back

=cut

sub pack {
	my $self=shift;
	my $data=shift;
	my $r = ref $data;
	my $comments=shift;
	$comments = {} unless defined $comments;
	return $self->packObject($data,@_) if $r and $r =~ m/Data::Sofu::/ and $data->isa("Data::Sofu::Object"); 
	my $header=shift;
	$data = {Value=>$data} unless ref $data and ref $data eq "HASH";
	$data = {Value=>$data} unless ref $data and ref $data eq "HASH";
	#$self->die("Data format wrong, must be hashref") unless (ref $data and ref $data eq "HASH");
	my $level=int(shift || 0);
	$self->{COMMENT}=$comments;
	$level=0 unless $level;
	$self->{IDS} = {};
	$self->{ID} = 1;
	my $id = $self->genID();
	$self->{IDS}->{$data}=$id;
	my $str="";
	$str.=qq(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">\n) unless ($header);
	$str.=$header if $header;
	$str.=$self->packItem("Sofu",$level,$id,"=")."\n";
	foreach my $key	(keys %{$data}) {
		$str.=$self->indent($level+1)."<Element key=\"".$self->XMLKeyescape($key)."\">\n";
		$str.=$self->packData($data->{$key},$level+2,"->".Data::Sofu::Sofukeyescape($key));
		$str.=$self->indent($level+1)."</Element>\n";
	}
	return $str.$self->indent($level)."</Sofu>\n";

}

my @tree = ();
my @ids =();
my $tree =();
my @ref = ();
my %id = ();
my $ret = "";
my @keys = ();
my %com = ();
my $end=0;

=head2 read(STRING)

Unpacks a SofuML string to perl datastructures

Don't use this, use readSofu("file.xml") instead.

=cut

sub read {
	my $self=shift;
	my $data=shift;
	eval {
		local $^W = 0;
		require XML::Parser;
	};
	@tree = ();
	@ids =();
	$tree =();
	@ref = ();
	%id = ();
	$ret = "";
	@keys = ();
	%com = ();
	confess "You will need XML::Parser for reading SofuML files" if ($@);
	#my $parser =XML::Parser->new(Style=>"Tree");
	#my $tree=$parser->parse($data); 
	#use Data::Dumper;
	#print Data::Dumper->Dump([$tree]);
	my $parser =XML::Parser->new(Handlers=>{Start => \&tag_start,End   => \&tag_end,Char  => \&characters, Comment=>\&comment});
	$parser->parse($data); 
	foreach my $e (@ref) {
		my $target = $$$e;
		$$e = undef;
		$$e = $id{$target} if $id{$target};
	}
	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,\%id,\%com],[qw/@tree $ret %com @ref %id %com/]);
	return ($ret,{%com}) if wantarray;
	return $ret;
}

=head2 load(STRING)

Unpacks SofuML string to Data::Sofu::Object's from STRING

Don't use this, use readSofu("file.xml") instead.

=cut

sub load {
	my $self=shift;
	my $data=shift;
	eval {
		local $^W = 0;
		require XML::Parser;
	};
	@tree = ();
	@ids =();
	$tree =();
	@ref = ();
	%id = ();
	$ret = "";
	@keys = ();
	%com = ();
	confess "You will need XML::Parser for reading SofuML files" if ($@);
	require Data::Sofu::Object;
	#my $parser =XML::Parser->new(Style=>"Tree");
	#my $tree=$parser->parse($data); 
	#use Data::Dumper;
	#print Data::Dumper->Dump([$tree]);
	my $parser =XML::Parser->new(Handlers=>{Start => \&otag_start,End   => \&otag_end,Char  => \&ocharacters, Comment=>\&ocomment});
	$parser->parse($data); 
	foreach my $e (@ref) {
		my $target = $e->follow();
		$e->dangle($id{$target}) if $id{$target};
	}
	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,\%id],[qw/@tree $ret %com @ref %id/]);	
	return $ret;
}

## XML Parser Handlers

=head2 tag_start

Handler for L<XML::Parser>

=cut

sub tag_start {
	my $xp=shift;
	my $tag=lc(shift);
	my $key="";
	my $id = -1;
	my $idref="";
	$end=0;
	while (@_) {
		my $k=lc shift;
		my $v=shift;
		$id = $v if $k eq "id";
		$idref = $v if $k eq "idref";
		$key = $v if $k eq "key";
	}
	if ($tag eq "value") {
		push @tree,"";
		push @ids,$id;
	}
	elsif ($tag eq "undefined") {
		push @tree,undef;
		push @ids,$id;
	}
	elsif ($tag eq "reference") {
		push @tree,\$idref;
		push @ids,-1;
	}
	elsif ($tag eq "sofu") {
		push @tree,{};
		push @ids,$id;
	}
	elsif ($tag eq "map") {
		push @tree,{};
		push @ids,$id;
	}
	elsif ($tag eq "list") {
		push @tree,[];
		push @ids,$id;
		push @keys,0;
	}
	elsif ($tag eq "element") {
		push @keys,$key;
	}
	else {
		die "Unknown Tag $tag";
	}

	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,$tag,$key],[qw/@tree $ret %com @ref $tag $key/]);<>;
}

=head2 characters

Handler for L<XML::Parser>

=cut

sub characters {
	my $xp=shift;
	my $data=$xp->recognized_string;
	$tree[-1].= $data unless ref $tree[-1] or not defined $tree[-1]; #Ignore chars in everything but a Value
	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,$data],[qw/@tree $ret %com @ref $data/]);<>;
}

=head2 comment

Handler for L<XML::Parser>

=cut

sub comment {
	my $xp=shift;
	my $data=shift;
	$data=~s/^ //g;
	$data=~s/ $//g;
	$keys[-1]-- if ($end);
	my $tree=join("->",map{Data::Sofu::Sofukeyescape($_)} @keys);
	$tree="->".$tree if $tree;
	$tree="=" unless $tree;
	push @{$com{$tree}},split /\n/,$data;
	$keys[-1]++ if ($end);
}

=head2 tag_end

Handler for L<XML::Parser>

=cut

sub tag_end {
	my $xp=shift;
	my $tag=lc(shift);
	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,$tag],[qw/@tree $ret %com @ref $tag/]);<>;
	if ($tag eq "element") {
		my $key = pop @keys;
		$tree[-1]->{$key}=$ret;
		if (ref $ret and ref $ret eq "SCALAR") {
			push @ref,\$tree[-1]->{$key};
		}
		return;
	}
	$ret=pop @tree;
	$ret = XMLunescape($ret) unless ref $ret or not defined $ret;
	pop @keys if ($tag eq "list");
	$id{pop @ids}=$ret;
	if ($tree[-1] and ref $tree[-1] and ref $tree[-1] eq "ARRAY") {
		push @{$tree[-1]}, $ret;
		if (ref $ret and ref $ret eq "SCALAR") {
			push @ref,\$tree[-1]->[-1];
		}
		$end = -1;
		$keys[-1]++;
	}
}

my $elem = 0;

=head2 otag_start

Handler for L<XML::Parser>, object mode

=cut

sub otag_start {
	my $xp=shift;
	my $tag=lc(shift);
	my $key="";
	my $id = -1;
	my $idref="";
	$end=0;
	while (@_) {
		my $k=lc shift;
		my $v=shift;
		$id = $v if $k eq "id";
		$idref = $v if $k eq "idref";
		$key = $v if $k eq "key";
	}
	if ($tag eq "value") {
		push @tree,Data::Sofu::Value->new("");
		push @ids,$id;
	}
	elsif ($tag eq "undefined") {
		push @tree,Data::Sofu::Undefined->new();
		push @ids,$id;
	}
	elsif ($tag eq "reference") {
		my $r=Data::Sofu::Reference->new($idref);
		push @tree,$r;
		push @ref,$r;
		push @ids,-1;
	}
	elsif ($tag eq "sofu") {
		$elem=0;
		push @tree,Data::Sofu::Map->new();
		push @ids,$id;
	}
	elsif ($tag eq "map") {
		$elem=0;
		push @tree,Data::Sofu::Map->new();
		push @ids,$id;
	}
	elsif ($tag eq "list") {
		push @tree,Data::Sofu::List->new();
		push @ids,$id;
		push @keys,0;
	}
	elsif ($tag eq "element") {
		push @keys,$key;
		$elem=1;
	}
	else {
		die "Unknown Tag $tag";
	}
	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,$tag,$key],[qw/@tree $ret %com @ref $tag $key/]);<>;
}

=head2 ocharacters

Handler for L<XML::Parser>, object mode

=cut

sub ocharacters {
	my $xp=shift;
	my $data=$xp->recognized_string;
	$tree[-1]->set($tree[-1]->toString().$data) if $tree[-1] and $tree[-1]->isValue(); #Ignore chars in everything but a Value
	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,$data],[qw/@tree $ret %com @ref $data/]);<>;
}

=head2 ocomment

Handler for L<XML::Parser>, object mode

=cut

sub ocomment {
	my $xp=shift;
	my $data=shift;
	$data=~s/^ //g;
	$data=~s/ $//g;
	if ($end or $elem) {
		$ret->appendComment([split /\n/,$data]) if $ret;
	}
	else {
		$tree[-1]->appendComment([split /\n/,$data]) if $tree[-1];
	}
}

=head2 otag_end

Handler for L<XML::Parser>, object mode

=cut

sub otag_end {
	my $xp=shift;
	my $tag=lc(shift);
	$end=0;
	#print Data::Dumper->Dump([\@tree,$ret,\%com,\@ref,$tag],[qw/@tree $ret %com @ref $tag/]);<>;
	if ($tag eq "element") {
		my $key = pop @keys;
		$tree[-1]->setAttribute($key,$ret);
		$elem=0;
		return;
	}
	$ret=pop @tree;
	$ret->set(XMLunescape($ret->toString())) if $ret->isValue();
	pop @keys if ($tag eq "list");
	$id{pop @ids}=$ret;
	if ($tree[-1] and $tree[-1]->isList()) {
		$tree[-1]->appendElement($ret);
		$keys[-1]++;
		$end=-1;
	}
}



#sub convert { ##Forget it, no comments returned!!!
#	my $self=shift;
#	my $tree=shift;
#	if ($tree[0] eq "Sofu" or $tree[0] eq "Map") {#Don't care if <Sofu> or <Map> descripes a Map
#		my $res = {};
#		$self->{IDS}->{$tree[1]->{id})}=$res if ($tree[1] and $tree[1]->{id});
#		while (@{$tree}) {
#			my $key = shift @{$tree};
#			my $value = shift @{$tree};
#			if (lc $key eq "element") {
#
#			}
#		}
#	}
#
#}

=head1 BUGS

Reading SofuML files need XML::Parser.

The Old escaping mechanism didn't escape newlines in Values (at least not the ones in the middle)

The new mechanism escapes them all.

This Module can read both, but if you encounter NewLines in your Source file that don't belong there it might give you an additional newline you didn't want.

=head1 See Also

L<Data::Sofu>, L<Data::Sofu::Object>, L<http://sofu.sf.net>

=cut

1;
