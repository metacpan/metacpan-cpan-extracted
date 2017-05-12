###############################################################################
#Sofu.pm
#Last Change: 2009-01-28
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

package Data::Sofu;
use strict;
use warnings;
use utf8;
require Exporter;
use Carp qw/croak confess/;
$Carp::Verbose=1;
use vars qw($VERSION @EXPORT @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw/Exporter/;
use Encode; 
use Encode::Guess qw/UTF-16BE UTF-16LE UTF-32LE UTF-32BE latin1/; 

@EXPORT= qw/readSofu writeSofu getSofucomments writeSofuBinary writeBinarySofu writeSofuML loadSofu/;
@EXPORT_OK= qw/readSofu writeSofu getSofucomments writeSofuBinary writeBinarySofu packBinarySofu packSofu unpackSofu getSofu packSofuBinary SofuloadFile getSofuComments writeSofuML packSofuML loadSofu/;
%EXPORT_TAGS=("all"=>[@EXPORT_OK]);

$VERSION= 0.3;
my $sofu;
my $bdriver; #Binary Interface (new File)
my $mldriver; #SofuML Interface
our $fullescape = 0;

sub refe {
	my $ref=shift;
	return 0 unless ref $ref;
	return 1 if ref $ref eq "SCALAR";
	return 1 if ref $ref eq "Data::Sofu::Reference";
	return 0;
}

sub readSofu {
	$sofu=Data::Sofu->new() unless $sofu;
	if (wantarray) {
		return $sofu->read(@_);
	}
	else {
		return scalar $sofu->read(@_);
	}
}
sub getSofu {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->from(@_);
}
sub loadSofu {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->load(@_);
}
sub SofuloadFile {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->load(@_);
}

sub writeSofu {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->write(@_);
}

sub writeSofuML {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->writeML(@_);
}

sub loadFile {
	$sofu=Data::Sofu->new() unless $sofu;
	my $class=shift;
	if ($class eq "Data::Sofu") {
		return $sofu->load(@_);
	}
	#croak ("Usage: Data::Sofu->loadFile(\$file)\nFile can be: Filehandle, Filename or reference to a scalar") if (ref $class or $class ne "Data::Sofu");
	return $sofu->load($class,@_);

}
sub getSofucomments {
	$sofu->warn("Can't get comments: No File read") unless $sofu;
	return $sofu->comments;
}

sub getSofuComments {
	$sofu->warn("Can't get comments: No File read") unless $sofu;
	return $sofu->comments;
}

sub packSofu {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->pack(@_);
}

sub packSofuML {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->packML(@_);
}

sub writeBinarySofu {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->writeBinary(@_);
}

sub writeSofuBinary {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->writeBinary(@_);
}

sub packSofuBinary {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->packBinary(@_);
}

sub packBinarySofu {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->packBinary(@_);
}

sub unpackSofu {
	$sofu=Data::Sofu->new() unless $sofu;
	return $sofu->unpack(@_);
}

sub new {
	my $self={};
	shift;
	$$self{CurFile}="";
	$$self{Counter}=0;
	$$self{WARN}=1;
	$$self{Debug}=0;
	$$self{Ref}={};
	$$self{Indent}="";
	$self->{String}=0;
	$self->{Escape}=0;
	$$self{SetIndent}="";
	$$self{READLINE}="";
	$self->{COUNT}=0;
	$$self{Libsofucompat}=0;
	$$self{Commentary}={};
	$$self{PreserveCommentary}=1;
	$$self{TREE}="";
	$$self{OBJECT}="";
	$self->{COMMENT}=[];
	bless $self;
	return $self;
}

sub toObjects {
	my $self=shift;
	my $data=shift;
	my $comment=shift;
	Data::Sofu::Object->clear();
	my $tree=Data::Sofu::Object->new($data);
	foreach my $key (keys %$comment) {
		my $wkey=$key;
		$wkey=~s/^->//;
		$wkey="" if $key eq "=";
		$tree->storeComment($wkey,$comment->{$key});
	}
	return $tree;
}

sub from {  #deprecated but still in use requires to runs through the tree :(((
	require Data::Sofu::Object;
	my $self=shift;
	my $file=shift;
	if (ref $file and ref $file ne "GLOB") {
		carp("Can't call \"from\" on an Object, it is used to create an object tree: my \$tree=Data::Sofu::from(\$file)!");
	}
	Data::Sofu::Object->clear();
	#$self->object(1); #Use the object parser;
	my $tree=$self->read($file);
	$tree=Data::Sofu::Object->new($tree);
	my $c=$self->comment;
	foreach my $key (keys %$c) {
		#print "Key = $key Comment = @{$c->{$key}}\n";
		my $wkey=$key;
		$wkey=~s/^->//;
		$wkey="" if $key eq "=";
		$tree->storeComment($wkey,$c->{$key});
	}
	return $tree;
}

sub wasbinary {
	my $self=shift;
	if (@_) {
		$self->{BINARY}=shift;
	}
	return $self->{BINARY};
}

sub load {
	my $self=shift;
	#TODO pure Object Based Parser!! NOT really possible to hack in with Ref-Detection and stuff (Complete rewrite needed, lex based like Sofud)
	#return $self->from(@_);
	require Data::Sofu::Object;	
	#my $self=shift;
	local $_;
	my $file=shift;
	my $fh;
	$$self{TREE}="";
	$self->{OBJECT}=1;
	$$self{CURRENT}=0;
	$$self{References}=[];
	$self->{Commentary}={};
	%{$$self{Ref}}=();
	my $guess=0;
	unless (ref $file) {
		$$self{CurFile}=$file;
		open $fh,"<:raw",$$self{CurFile} or die "Sofu error open: $$self{CurFile} file: $!";
		$guess=1;
		binmode $fh;
		#eval {require File::BOM;my ($e,$sp)=File::BOM::defuse($fh);$$self{Ret}.=$sp;$e=$e;};undef $@;
	}
	elsif (ref $file eq "SCALAR") {
		$$self{CurFile}="Scalarref";
		open $fh,"<:utf8",$file or die "Can't open perlIO: $!" if utf8::is_utf8($$file);
		open $fh,"<",$file or die "Can't open perlIO: $!"  if !utf8::is_utf8($$file);;
	}
	elsif (ref $file eq "GLOB") {
		$$self{CurFile}="FileHandle";
		$fh=$file;
	}
	else {
		$self->warn("The argument to load or loadfile has to be a filename, reference to a scalar or filehandle");
		return;
	}
	my $text=do {local $/,<$fh>};
	{
		my $b = substr($text,0,2);
		my $c= substr($text,2,1);
		if ($b eq "So") {
			$b=substr($text,0,4);
			if ($b eq "Sofu") {
				$b=substr($text,4,2);
				$c=substr($text,6,1);
			}
		}
		if (($b eq "\x{00}\x{00}" or $b eq "\x{01}\x{00}" or $b eq "\x{00}\x{01}") and $c ne "\x{FE}") { #Assume Binary
			require Data::Sofu::Binary;
			$bdriver = Data::Sofu::Binary->new() unless $bdriver;
			my $tree = $bdriver->load(\$text);
			$self->wasbinary(1);
			if (wantarray) {
				return %{$tree};
			}
			return $tree;
		}

	}
	if ($guess)  {
		my $enc=guess_encoding($text);
		$text=$enc->decode($text) if ref $enc;
		$text=Encode::decode("UTF-8",$text) unless ref $enc;
	}
	substr($text,0,1,"") if substr($text,0,1) eq chr(65279); # UTF-8 BOM (Why ain't it removed ?)
	close $fh if ref $file;
	$$self{CurFile}="";
	my $u=$self->unpack($text);
	$self->{OBJECT}=0;
	return $u;
}

sub noComments {
	my $self=shift;
	$$self{PreserveCommentary}=0;
}
sub object {
	my $self=shift;
	$$self{OBJECT}=shift;
}
sub comment {
	my $self=shift;
	my $data=undef;
	if ($_[0]) {
		if (ref $_[0] eq "HASH") {
			$data=shift;
		}
		else {	
			$data={@_};
		}
	}
	$$self{Commentary}=$data if $data;;
	return $self->{Commentary};
}
sub comments {
	my $self=shift;
	my $data=undef;
	if ($_[0]) {
		if (ref $_[0] eq "HASH") {
			$data=shift;
		}
		else {	
			$data={@_};
		}
	}
	$$self{Commentary}=$data if $data;;
	return $self->{Commentary};
}
sub setIndent {
	my $self=shift;
	local $_;
	$$self{SetIndent}=shift;
}
sub setWarnings {
	my $self=shift;
	local $_;
	$$self{WARN}=shift;
}
sub allWarn {
	my $self=shift;
	local $_;
	$$self{WARN}=1;
}
sub noWarn {
	my $self=shift;
	local $_;
	$$self{WARN}=0;
}
sub iKnowWhatIAmDoing {
	my $self=shift;
	local $_;
	$$self{WARN}=0;
}
sub iDontKnowWhatIAmDoing {
	my $self=shift;
	local $_;
	$$self{WARN}=1;
}
sub commentary {
	my $self=shift;
	return "" unless $self->{PreserveCommentary};
	my $tree=$self->{TREE};
	$tree="=" unless $tree;
	if ($self->{Commentary}->{$tree}) {
		my $res;
		$res=" " if $self->{TREE};
		foreach (@{$self->{Commentary}->{$tree}}) {
		#	print ">>$_<<\n";
			$res.="\n" if $res and $res ne " ";
			$res.="# $_";
		}
		return $res;
	}
	return "";
}
sub writeList {
	my $self=shift;
	local $_;
	my $deep=shift;
	my $ref=shift;
	my $res="";
	my $tree=$self->{TREE};
	if ($$self{Ref}->{$ref} and $self->{TREE}) {
		#confess($tree);
		$res.="@".$$self{Ref}->{$ref}."\n";
		#$self->warn("Cross-reference ignored");
		return $res;
	}
	$$self{Ref}->{$ref}=($tree || "->");
	$res.="(".$self->commentary."\n";
	my $i=0;
	foreach my $r (@{$ref}) {
		$self->{TREE}=$tree."->$i";
		if (not ref($r)) {
			$res.=$$self{Indent} x $deep.$self->escape($r).$self->commentary."\n";
		}
		elsif (ref $r eq "HASH") {
			$res.=$$self{Indent} x $deep;
			$res.=$self->writeMap($deep+1,$r);
		}
		elsif (ref $r eq "ARRAY") {
			$res.=$$self{Indent} x $deep;
			$res.=$self->writeList($deep+1,$r);
		}
		else {
			$self->warn("Non sofu reference");
		}
		$i++;
		
	}
	return $res.$$self{Indent} x --$deep.")\n";
}
sub writeMap {
	my $self=shift;
	local $_;
	my $deep=shift;
	my $ref=shift;
	my $tree=$self->{TREE};
	my $res="";
	#print Data::Dumper->Dump([$$self{Ref}]);
	if ($$self{Ref}->{$ref} and $self->{TREE}) {
		#confess();
		$res.="@".$$self{Ref}->{$ref}."\n";
		#$self->warn("Cross-reference ignored");
		return $res;
	}
	$$self{Ref}->{$ref}=($tree || "->");
	$res.="{".$self->commentary."\n" if $deep or not $$self{Libsofucompat};
	foreach (sort keys %{$ref}) {
		my $wkey=$self->keyescape($_);
		$self->warn("Impossible Name for a Map-Entry: \"$wkey\"") if not $wkey or $wkey=~m/[\=\"\}\{\(\)\s\n]/;
		$self->{TREE}=$tree."->$_";
		unless (ref $$ref{$_}) {
			$res.=$$self{Indent} x $deep."$wkey = ".$self->escape($$ref{$_}).$self->commentary."\n";
		}
		elsif (ref $$ref{$_} eq "HASH") {
			$res.=$$self{Indent} x $deep."$wkey = ";
			$res.=$self->writeMap($deep+1,$$ref{$_});
		}
		elsif (ref $$ref{$_} eq "ARRAY") {
			$res.=$$self{Indent} x $deep."$wkey = ";
			$res.=$self->writeList($deep+1,$$ref{$_});
		}
		else {
			$self->warn("non Sofu reference");
		}
		
	}
	$res.=$$self{Indent} x --$deep."}\n" if $deep or not $$self{Libsofucompat};
	return $res;
}
sub write {
	my $self=shift;
	local $_;
	my $file=shift;
	my $fh;
	$$self{TREE}="";
	unless (ref $file) {
		$$self{CurFile}=$file;
		open $fh,">:raw:encoding(UTF-16)",$$self{CurFile} or die "Sofu error open: $$self{CurFile} file: $!";
	}
	elsif (ref $file eq "SCALAR") {
		$$self{CurFile}="Scalarref";
		utf8::upgrade($$file);
		open $fh,">:utf8",$file or die "Can't open perlIO: $!";
	}
	elsif (ref $file eq "GLOB") {
		$$self{CurFile}="FileHandle";
		$fh=$file;
	}
	else {
		$self->warn("The argument to read or write has to be a filename, reference to a scalar or filehandle");
		return;
	}
	my $ref=shift;
	#use Data::Dumper;
	#print Data::Dumper->Dump([$ref]);
	$self->{Commentary}={};
	$self->comment(@_);
	$$self{Indent}="\t" unless $$self{SetIndent};
	$$self{Libsofucompat}=1;
	%{$$self{Ref}}=();
	#$self->{Ref}->{$ref}="->";
	print $fh $self->commentary,"\n";
	unless (ref $ref) {
		print $fh "Value=".$self->escape($ref);
	}
	elsif (ref $ref eq "HASH") {
		print $fh $self->writeMap(0,$ref);
	}
	elsif (ref $ref eq "ARRAY") {
		print $fh "Value=".$self->writeList(0,$ref);
	}
	else {
		$self->warn("non Sofu reference");
		return "";
	}
	$$self{Libsofucompat}=0;
	$$self{Indent}="";
	#close $fh if ref $file;
	$$self{CurFile}="";
	return 1;
}


sub read {
	my $self=shift;
	local $_;
	my $file=shift;
	my $fh;
	$$self{TREE}="";
	$$self{OBJECT}=0;
	$$self{CURRENT}=0;
	$$self{References}=[];
	$self->{Commentary}={};
	%{$$self{Ref}}=();
	my $guess=0;
	unless (ref $file) {
		$$self{CurFile}=$file;
		open $fh,$$self{CurFile} or die "Sofu error open: $$self{CurFile} file: $!";
		$guess=1;
		binmode $fh;
		#eval {require File::BOM;my ($e,$sp)=File::BOM::defuse($fh);$$self{Ret}.=$sp;$e=$e;};undef $@;
	}
	elsif (ref $file eq "SCALAR") {
		$$self{CurFile}="Scalarref";
		open $fh,"<:utf8",$file or die "Can't open perlIO: $!" if utf8::is_utf8($$file);
		open $fh,"<",$file or die "Can't open perlIO: $!" if !utf8::is_utf8($$file);
	}
	elsif (ref $file eq "GLOB") {
		$$self{CurFile}="FileHandle";
		$fh=$file;
	}
	else {
		$self->warn("The argument to read or write has to be a filename, reference to a scalar or filehandle");
		return;
	}
	my $text=do {local $/,<$fh>};
	{
		my $b = substr($text,0,2);
		my $u = substr($text,2,1);
		if ($b eq "So") {
			$b=substr($text,0,4);
			if ($b eq "Sofu") {
				$b=substr($text,4,2);
				$u=substr($text,6,1);
			}
		}
		if (($b eq "\x{00}\x{00}" or $b eq "\x{01}\x{00}" or $b eq "\x{00}\x{01}") and $u ne "\x{fe}") { #Assume Binary
			require Data::Sofu::Binary;
			$bdriver = Data::Sofu::Binary->new() unless $bdriver;
			my ($tree,$c) = $bdriver->read(\$text);
			$self->comment($c);
			$self->wasbinary(1);
			if (wantarray) {
				return %{$tree};
			}
			return $tree;
		}

	}
	if ($guess)  {
		my $enc=guess_encoding($text);
		$text=$enc->decode($text) if ref $enc;
		$text=Encode::decode("UTF-8",$text) unless ref $enc;
	}
	close $fh if ref $file;
	$$self{CurFile}="";
	substr($text,0,1,"") if substr($text,0,1) eq chr(65279); # UTF-8 BOM (Why ain't it removed ?)
	my $u=$self->unpack($text);
	#print Data::Dumper->Dump([$u]);
	if (wantarray) {
		return () unless $u;	
		return %{$u} if ref $u eq "HASH";
		return (Value=>$u);
	}
	return unless $u;
	return $u if ref $u eq "HASH";
	return {Value=>$u};
#	$self->warn("Unpack error: $u") unless ref $u;
#	return %{$u};
}

sub pack {
	my $self=shift;
	my $ref=shift;
	local $_;
	$self->{Commentary}={};
	$self->comment(@_);
	$$self{TREE}="";
	%{$$self{Ref}}=();
	#$self->{Ref}->{$ref}="->";
	$$self{Indent}=$$self{SetIndent} if $$self{SetIndent};
	$$self{Counter}=0;
	unless (ref $ref) {
		return $self->commentary.$self->escape($ref);
	}
	elsif (ref $ref eq "HASH") {
		return $self->commentary.$self->writeMap(0,$ref);
	}
	elsif (ref $ref eq "ARRAY") {
		return $self->commentary.$self->writeList(0,$ref);
	}
	else {
		$self->warn("non Sofu reference");
		return "";
	}
}
sub unpack($) {
	my $self=shift;
	local $_;
	$$self{TREE}="";
	$$self{Counter}=0;
	($self->{Escape},$self->{String},$self->{COUNT})=(0,0,0);
	$$self{Line}=1;
	$$self{READLINE}=shift()."\n";
	$$self{LENGTH}=length $$self{READLINE};
	%{$$self{Ref}}=();
	$$self{CURRENT}=0;
	$$self{References}=[];
	$self->{Commentary}={};
	my $c;
	my $bom=chr(65279);
	1 while ($c=$self->get() and ($c =~ m/\s/ or $c eq $bom));
	return unless defined $c;
	if ($c eq "{") {
		my $result;
		$result=$self->parsMap;
		$$self{Ref}->{""}=$result;
		$self->postprocess();
		1 while ($c=$self->get() and $c =~ m/\s/);
		if ($c=$self->get()) {
			$self->warn("Trailing Characters: $c");
		}
		return $result;
	}
	elsif ($c eq "(") {
		my $result;
		$result=$self->parsList;
		$$self{Ref}->{""}=$result;
		$self->postprocess();
		1 while ($c=$self->get() and $c =~ m/\s/);
		if ($c=$self->get()) {
			$self->warn("Trailing Characters: $c");
		}
		return $result;
		
	}
	elsif ($c eq "\"") {
		my $result;
		$result=$self->parsValue;
		$$self{Ref}->{""}=$result;
		$self->postprocess();
		1 while ($c=$self->get() and $c =~ m/\s/);
		if ($c=$self->get()) {
			$self->warn("Trailing Characters: $c");
		}
		return $result;
	}
	elsif ($c eq "<") {
		my $x;
		1 while ($x=$self->get() and $x =~ m/\s/);
		if ($x eq "!" or $x eq "S" or $x eq "?") { # <! or <S not valid Sofu, so it might be XML
			require Data::Sofu::SofuML;
			$mldriver=Data::Sofu::SofuML->new unless $mldriver;
			if ($$self{OBJECT}) {
				return $mldriver->load($$self{READLINE});
			}
			my ($r,$c) = $mldriver->read($$self{READLINE});
			$self->{Commentary}=$c;
			return $r;
		}
		else {
			$self->{COUNT}=0;
			my $result=$self->parsMap;
			$$self{Ref}->{""}=$result;
			$self->postprocess();
			1 while ($c=$self->get() and $c =~ m/\s/);
				if ($c=$self->get()) {
			$self->warn("Trailing Characters: $c");
			}
			return $result;
		}
	}
	elsif ($c!~m/[\=\"\}\{\(\)\s\n]/) {
		$$self{Ret}=$c;		
		my $result;
		$result=$self->parsMap;
		$$self{Ref}->{""}=$result;
		$self->postprocess();
		1 while ($c=$self->get() and $c =~ m/\s/);
		if ($c=$self->get()) {
			$self->warn("Trailing Characters: $c");
		}
		return $result;
	}
	else {
		$self->warn("Nothing to unpack: $c");
		return 0;
	}
}
sub get() {
	my $self=shift;
	local $_;
	if ($$self{Ret}) {
		my $ch=substr($$self{Ret},0,1,"");
		return $ch;
	}
	return shift if @_ and $_[0] and $_[0]!="";
	$self->{LENGTH}=length $$self{READLINE} unless $self->{LENGTH};
	$self->storeComment and return undef if $self->{COUNT}>=$self->{LENGTH};
	my $c=substr($$self{READLINE},$self->{COUNT}++,1);
	print "GET '$c'\n" if $$self{Debug};
	#print "DEBUG: $self->{COUNT}=$c\n";
	if ($c eq "\"") {
		$self->{String}=!$self->{String} unless $self->{Escape};
	}
	if ($c eq "\\") {
		$self->{Escape}=!$self->{Escape};
	}
	else {
		$self->{Escape}=0;
	}
	if ($c eq "#" and not $self->{String} and not $self->{Escape}){
		my $i=index($$self{READLINE},"\n",$self->{COUNT});
		my $comm = substr($$self{READLINE},$self->{COUNT},$i-$self->{COUNT});
		chomp $comm;
		$comm=~s/\r//g; #I hate Windows...!
		#die $comm;
		push @{$self->{COMMENT}},$comm;
		#push @{$self->{COMMENT}},substr($$self{READLINE},$self->{COUNT},$i-$self->{COUNT});
		#print "DEBUG JUMPING FROM $self->{COUNT} to INDEX=$i";
		$self->{COUNT}=$i+1;
		$c="\n";
	}	
	++$$self{Counter};
	if ($c and $c eq "\n") {
		$$self{Counter}=0;
		$$self{Line}++;
	}
	print "END" if not defined $c and $$self{Debug} ;
	return $c;
}
sub storeComment {
	my $self=shift;
	#if ($$self{OBJECT}) {
	#	$$self{Ref}->{$self->{TREE}}->appendComment($self->{COMMENT});
	#}
	my $tree=$self->{TREE};
	$tree="=" unless $tree;
	#print "DEBUG: $tree, @{$self->{COMMENT}} , ".join(" | ",caller())."\n";
	push @{$self->{Commentary}->{$tree}},@{$self->{COMMENT}} if @{$self->{COMMENT}};
	$self->{COMMENT}=[];
}

sub postprocess {
	my $self=shift;
	$self->{Ref}->{"="} = $self->{Ref}->{"->"} = $self->{Ref}->{""};
	if ($$self{OBJECT}) {
		foreach my $e (@{$$self{References}}) {
			next if ${$e}->valid();
			my $target = ${$e}->follow()."";
			$target="->".$target if $target and $target !~ m/^->/;
			${$e}->dangle($self->{Ref}->{$target}) if $self->{Ref}->{$target};
		}
		foreach my $key (keys %{$$self{Commentary}}) {
			$self->{Ref}->{$key}->setComment($$self{Commentary}->{$key}) if $self->{Ref}->{$key};
		}
	}
	else {
		foreach my $e (@{$$self{References}}) {
			my $target = $$$e;
			$target="->".$target if $target and $target !~ m/^->/;
			$$e = undef;
			$$e = $self->{Ref}->{$target} if $self->{Ref}->{$target};
		}
	}
}
sub warn {
	no warnings;
	my $self=shift;
	local $_;
	confess "Sofu warning: \"".shift(@_)."\" File: $$self{CurFile}, Line : $$self{Line}, Char : $$self{Counter},  Caller:".join(" ",caller);
	1;
}
sub escape {
	shift;
	my $text=shift;
	return Sofuescape($text);
}
sub Sofuescape {
	my $text=shift;
	return "UNDEF" unless defined $text; #TODO: UNDEF = Undefined
	if ($fullescape) {
		#print "$text : ";
		$text=~s/([[:^print:]\s\<\>\=\"\}\{\(\)])/ord($1) > 65535 ? sprintf("\\U%08x",ord($1)) : sprintf("\\u%04x",ord($1))/eg;
		#print "$text \n";
		return "\"$text\"";
	}
	else {
		$text=~s/\\/\\\\/g;
		$text=~s/\n/\\n/g;
		$text=~s/\r/\\r/g;
		$text=~s/\"/\\\"/g;
		return "\"$text\"";
	}
}
sub deescape {
	my $self=shift;
	local $_;
	my $text="";
	my $ttext=shift;
	my $noescape=shift;
	if ($noescape) {
		if ($ttext =~ m/^\@(.+)$/) {
			#return $$self{Ref}->{$1} || $self->warn("Can't find reference to $1.. References must first defined then called. You can't reference a string or number") 
			if ($$self{OBJECT}) {
				return Data::Sofu::Reference->new($1);
			}
			my $text=$1;
			return \$text;

		}
		if ($$self{OBJECT}) {
			return Data::Sofu::Undefined->new() if $ttext eq "UNDEF";
			return Data::Sofu::Value->new($ttext);
		}
		return undef if $ttext eq "UNDEF";
		return $ttext;
	}
	else {
		my $char;
		my $escape=0;
		my $count=0;
		my $len=length $ttext;
		while ($count <= $len) {
			my $char=substr($ttext,$count++,1);
			if ($char eq "\\") {
				$text.="\\" if $escape;
				$escape=!$escape;
			}
			else {
				if ($escape) {
					if (lc($char) eq "n") {
						$text.="\n";
					}
					elsif (lc($char) eq "r") {
						$text.="\r";
					}
					elsif (lc($char) eq "\"") {
						$text.="\"";
					}
					elsif ($char eq "u") {
						my $val=hex(substr($ttext,$count,4));
						$text.=chr($val);
						$count+=4;
					}
					elsif ($char eq "U") {
						my $val=hex(substr($ttext,$count,8));
						$count+=8;
						$text.=chr($val);
					}
					else {
						$self->warn("Deescape: Can't deescape: \\$char");
					}
					$escape=0;
				}
				else {
					$text.=$char;
				}
			}
		}
		return Data::Sofu::Value->new($text) if $self->{OBJECT};;
		return $text;
	}
}
sub parsMap {
	my $self=shift;
	local $_;
	my %result;
	my $comp="";
	my $eq=0;
	my $char;
	my $tree=$self->{TREE};
	my @order;
	while (defined($char=$self->get())) {
		print "ParsCompos  $char\n" if $$self{Debug};
		if ($char!~m/[\=\"\}\{\(\)\s\n]/s) {
			if ($eq) {
				$self->storeComment;
				my $keyu = $self->keyunescape($comp);
				$self->{TREE}=$tree."->".$comp;
				#print ">> > >> > > > > DEBUG: tree=$self->{TREE}\n";
				$result{$keyu}=$self->getSingleValue($char);
				push @order,$keyu;
				push @{$$self{References}},\$result{$keyu} if refe $result{$keyu};
				$comp="";
				$eq=0;
			}
			else {
				$comp.=$char;
			}
		}
		elsif ($char eq "=") {
			$self->warn("MapEntry unnamed!") if ($comp eq "");
			$self->storeComment;
			$self->{TREE}=$tree."->".$comp;
			$eq=1;
		}
		elsif ($char eq "{") {
			$self->warn("Missing \"=\"!") unless $eq;
			$self->warn("MapEntry unnamed!") if ($comp eq "");
			$self->storeComment;
			$self->{TREE}=$tree."->".$comp;
			my $res={};
			$res=$self->parsMap();
			$$self{Ref}->{$self->{TREE}}=$res;
			my $kkey=$self->keyunescape($comp);
			push @order,$kkey;
			$result{$kkey} = $res;
			$comp="";
			$eq=0;
		}
		elsif ($char eq "}") {
			$self->storeComment;
			$self->{TREE}=$tree;
			return Data::Sofu::Map->new(\%result,[@order]) if $self->{OBJECT};
			return \%result;
		}
		elsif ($char eq "\"") {
			if (not $eq) {
				$self->warn("Unclear Structure detected: was the last entry a value or a key (maybe you forgot either \"=\" before this or the \'\"\' around the value"); 
				$eq=1;
			}
			$self->storeComment;
			$self->{TREE}=$tree."->".$comp;
			#print ">>>>>>>>>>>>>>>>>>>>>>>>DEBUG: tree=$self->{TREE}\n";
			$self->warn("Missing \"=\"!") unless $eq;
			$self->warn("MapEntry unnamed!") if ($comp eq "");
			
			my $kkey=$self->keyunescape($comp);
			push @order,$kkey;
			$result{$kkey}=$self->parsValue();
			$comp="";
			$eq=0;
		}
		elsif ($char eq "(") {
			if (not $eq) {
				return $self->parsList();
			}					
			$self->warn("Missing \"=\"!") unless $eq;
			$self->warn("MapEntry unnamed!") if ($comp eq "");
			$self->storeComment;
			$self->{TREE}=$tree."->".$comp;
			my $res=[];
			$res=$self->parsList();
			$$self{Ref}->{$self->{TREE}}=$res;
			my $kkey=$self->keyunescape($comp);
			push @order,$kkey;
			$result{$kkey} = $res;
			$comp="";
			$eq=0;
		}
		elsif ($char eq ")") {
			$self->warn("What's a \"$char\" doing here?");
		}
	}
	return Data::Sofu::Map->new(\%result,[@order]) if $self->{OBJECT};
	return \%result;
}
sub parsValue {
	my $self=shift;
	local $_;
	my @result;
	my $cur="";
	my $in=1;
	my $escape=0;
	my $char;
	my $i=0;
	my $tree=$self->{TREE};
	my $starttree=$self->{TREE};
	$self->storeComment;
	$self->{TREE}=$tree."->0";
	while (defined($char=$self->get())) {
	print "ParsValue  $char\n" if $$self{Debug};
		if ($in) {
			if ($char eq "\"") {
				if ($escape) {
					$escape=0;
					$cur.=$char;
				}
				else {
					push @result,$self->deescape($cur,0);
					push @{$$self{References}},\$result[-1] if refe $result[-1];
					$self->storeComment;
					$self->{TREE}=$tree."->".$i++;
					$$self{Ref}->{$self->{TREE}}=$result[-1];
					$cur="";
					$in=0;
				}
			}
			elsif ($char eq "\\") {
				if ($escape) {
					$escape=0;
				}
				else {
					$escape=1;
				}
				$cur.=$char;
			}
			else {
				$escape=0;
				$cur.=$char;
			}

		}
		else {
			if ($char!~m/[\=\"\}\{\(\)\s\n]/s) {
				$$self{Ret}=$char;
				if (@result>1) {
					$self->{TREE}=$tree."->$#result";
					$self->storeComment;
					my $res=[@result];
					$res=Data::Sofu::List->new($res) if $self->{OBJECT};
					$$self{Ref}->{$tree}=$res;
					return $res;
				}
				elsif (@result) {
					$self->{TREE}=$tree;
					$self->storeComment;
					$$self{Ref}->{$tree}=\$result[0];
					return $result[0];
				}
				else { #This can't happen
					return undef;
				}
			}
			elsif ($char eq "=") {
				$self->warn("What's a \"$char\" doing here?");
			}
			elsif ($char eq "\"") {
				$in=1;
			}
			elsif ($char eq "{") {
				$self->storeComment;
				$self->{TREE}=$tree."->".++$i;
				my $res={};
				%{$res}=$self->parsMap();
				$$self{Ref}->{$self->{TREE}}=$res;
				push @result,$res;
			}
			elsif ($char=~m/[\}\)]/) {
				$$self{Ret}=$char;
				if ($cur ne "") {
					$cur=Data::Sofu::Value->new($cur) if $self->{OBJECT};
					if (@result) {
						$self->{TREE}=$tree."->".$#result+1;
						$self->storeComment;
						my $res={@result,$cur};
						$res=Data::Sofu::List->new($res) if $self->{OBJECT};
						$$self{Ref}->{$tree}=$res;
						return $res;
					}
					else { 
						$self->{TREE}=$tree;
						$self->storeComment;
						#$self{Ref}->{$tree}=\$cur;
						$$self{Ref}->{$tree}=$cur;
						return $cur;
					}
				}
				else {
					if (@result>1) {
						$self->{TREE}=$tree."->$#result";
						$self->storeComment;
						my $res=[@result];
						$res=Data::Sofu::List->new($res) if $self->{OBJECT};
						$$self{Ref}->{$tree}=$res;
						return $res;
					}
					elsif (@result) {
						$self->{TREE}=$tree;
						$self->storeComment;
						#$$self{Ref}->{$tree}=\$result[0];
						$$self{Ref}->{$tree}=$result[0];
						return $result[0];
					}
					else {
						#$$self{Ref}->{$tree}=\$cur;
						$cur=Data::Sofu::Value->new($cur) if $self->{OBJECT};
						$$self{Ref}->{$tree}=$cur;
						return $cur;
					}
				}
			}
			elsif ($char eq "(") {
				$self->storeComment;
				$self->{TREE}=$tree."->".++$i;
				my $res=[];
				$res=$self->parsList();
				$$self{Ref}->{$self->{TREE}}=$res;
				push @result,$res;
			}
			elsif ($char eq ")") {
				$self->warn("What's a \"$char\" doing here?");
			}
		}
	}
	if ($cur ne "") {
		$cur=Data::Sofu::Value->new($cur) if $self->{OBJECT};
		if (@result) {
			$self->{TREE}=$tree."->".$#result+1;
			$self->storeComment;
			push @result,$cur;
			my $res=[@result];
			$res=Data::Sofu::List->new($res) if $self->{OBJECT};
			$$self{Ref}->{$tree}=$res;
			return $res;
		}
		else { 
			$self->{TREE}=$tree;
			#$$self{Ref}->{$tree}=\$cur;
			$$self{Ref}->{$tree}=$cur;
			$self->storeComment;
			return $cur;
		}
	}
	else {
		if (@result>1) {
			$self->{TREE}=$tree."->$#result";
			$self->storeComment;
			my $res=[@result];
			$res=Data::Sofu::List->new($res) if $self->{OBJECT}; 
			$$self{Ref}->{$tree}=$res;
			return $res;
		}
		elsif (@result) {
			$self->{TREE}=$tree;
			$self->storeComment;
			#$$self{Ref}->{$tree}=\$result[0];
			$$self{Ref}->{$tree}=$result[0];
			return $result[0];
		}
		else {
			$cur=Data::Sofu::Value->new($cur) if $self->{OBJECT};
			$$self{Ref}->{$tree}=$cur;
			return $cur;
		}
	}
}
sub getSingleValue {
	my $self=shift;
	local $_;
	my $res="";
	$res=shift if @_;
	my $char;
	while (defined($char=$self->get())) {
		print "ParsSingle $char\n" if $$self{Debug};
		if ($char!~m/[\=\"\}\{\(\)\s]/) {
			$res.=$char;
		}
		elsif ($char=~m/[\=\"\{\(]/) {
			$self->warn("What's a \"$char\" doing here?");
		}
		elsif ($char=~m/[\}\)]/) {
			$$self{Ret}=$char;
			return $$self{Ref}->{$self->{TREE}}=$self->deescape($res,1);
		}
		elsif ($char=~m/\s/) {
			return $$self{Ref}->{$self->{TREE}}=$self->deescape($res,1);
			return $res;
		}
	}
	$self->warn ("Unexpected EOF");
	return $$self{Ref}->{$self->{TREE}}=$self->deescape($res,1);
}
sub parsList {
	my $self=shift;
	local $_;
	my @result;
	my $cur="";
	my $in=0;
	my $escape=0;	
	my $char;
	my $i=0;
	my $tree=$self->{TREE};
	$self->storeComment;
	#$self->{TREE}=$tree."->0";
	while (defined($char=$self->get())) {
	print "ParsList   $char\n" if $$self{Debug};
		if ($in) {
			if ($char eq "\"") {
				if ($escape) {
					$escape=0;
					$cur.=$char;
				}
				else {
					push @result,$self->deescape($cur,0);
					push @{$$self{References}},\$result[-1] if refe $result[-1];
					$self->storeComment;
					$self->{TREE}=$tree."->".$i++;
					$$self{Ref}->{$self->{TREE}}=$result[-1];
					$cur="";
					$in=0;
				}
			}
			elsif ($char eq "\\") {
				if ($escape) {
					$escape=0;
				}
				else {
					$escape=1;
				}
				$cur.=$char;
			}
			else {
				$escape=0;
				$cur.=$char;
			}

		}
		else {
			if ($char!~m/[\=\"\}\{\(\)\s\n]/) {
				$self->storeComment;
				$self->{TREE}=$tree."->".$i++;
				push @result,$self->getSingleValue($char);
				push @{$$self{References}},\$result[-1] if refe $result[-1];
			}
			elsif ($char eq "=") {
				$self->warn("What's a \"$char\" doing here?");
			}
			elsif ($char eq "\"") {
				$in=1;
			}
			elsif ($char eq "{") {
				$self->storeComment;
				$self->{TREE}=$tree."->".$i++;
				my $res={};
				$res=$self->parsMap();
				$$self{Ref}->{$self->{TREE}}=$res;
				push @result,$res;
			}
			elsif ($char eq "}") {
				$self->warn("What's a \"$char\" doing here?");
			}
			elsif ($char eq "(") {
				$self->storeComment;
				$self->{TREE}=$tree."->".$i++;
				my $res=[];
				$res=$self->parsList();
				$$self{Ref}->{$self->{TREE}}=$res;
				push @result,$res;
			}
			elsif ($char eq ")") {
				$self->storeComment;
				$self->{TREE}=$tree;
				return Data::Sofu::List->new(\@result) if $self->{OBJECT};
				return \@result;
			}
		}
	}
	$self->warn ("Unexpected EOF");
	push @result,$cur if ($cur ne "");
	return Data::Sofu::List->new(\@result) if $self->{OBJECT};
	return \@result;
}
sub Sofukeyescape { #Other escaping (can be parsed faster and is Sofu 0.1 compatible)
	my $key=shift;
	return "<UNDEF>" unless defined $key;
	return "<>" unless $key;
	$key=~s/([[:^print:]\s\<\>\=\"\}\{\(\)])/sprintf("\<\%x\>",ord($1))/eg;
	return $key;
}

sub Sofukeyunescape { #Other escaping (can be parsed faster)
	my $key=shift;
	return "" if $key eq "<>";
	return undef if $key eq "<UNDEF>";
	$key=~s/\<([0-9abcdef]*)\>/chr(hex($1))/egi;
	return $key;
}
sub keyescape { #Other escaping (can be parsed faster and is Sofu 0.1 compatible)
	my $self=shift;
	return Sofukeyescape(@_);
}

sub keyunescape { #Other escaping (can be parsed faster)
	my $self=shift;
	return Sofukeyunescape(@_);
}

sub packBinary {
	my $self=shift;
	require Data::Sofu::Binary;
	$bdriver = Data::Sofu::Binary->new() unless $bdriver;
	return $bdriver->pack(@_);
}

sub writeML {
	my $self=shift;
	my $file=shift;
	my $fh;
	require Data::Sofu::SofuML;
	$mldriver = Data::Sofu::SofuML->new() unless $mldriver;
	unless (ref $file) {
		open $fh,">:encoding(UTF-8)",$file or die "Sofu error open: $$self{CurFile} file: $!";
	}
	elsif (ref $file eq "SCALAR") {
		open $fh,">:utf8",$file or die "Can't open perlIO: $!";
	}
	elsif (ref $file eq "GLOB") {
		$fh=$file;
	}
	else {
		$self->warn("The argument to writeML has to be a filename, reference to a scalar or filehandle");
		return;
	}
	binmode $fh;
	print $fh $mldriver->pack(@_);
	#$fh goes out of scope here!
}

sub packML {
	require Data::Sofu::SofuML;
	my $self=shift;
	$mldriver = Data::Sofu::SofuML->new() unless $mldriver;
	$mldriver->{INDENT} = "";
	my $a=$mldriver->pack(@_);
	$mldriver->{INDENT} = "\t";
	return $a;
}

sub writeBinary {
	my $self=shift;
	my $file=shift;
	my $fh;
	require Data::Sofu::Binary;
	$bdriver = Data::Sofu::Binary->new() unless $bdriver;
	unless (ref $file) {
		open $fh,">:raw",$file or die "Sofu error open: $$self{CurFile} file: $!";
	}
	elsif (ref $file eq "SCALAR") {
		open $fh,">",$file or die "Can't open perlIO: $!";
	}
	elsif (ref $file eq "GLOB") {
		$fh=$file;
	}
	else {
		$self->warn("The argument to writeBinary has to be a filename, reference to a scalar or filehandle");
		return;
	}
	binmode $fh;
	print $fh $bdriver->pack(@_);
	#$fh goes out of scope here!
}

1;
__END__

=head1 NAME

Data::Sofu - Perl extension for Sofu data

=head1 Synopsis 

	use Data::Sofu;
	%hash=readSofu("file.sofu");
	...
	writeSofu("file.sofu",\%hash);
	
Or a litte more complex:

	use Data::Sofu qw/packSofu unpackSofu/;
	%hash=readSofu("file.sofu");
	$comments=getSofucomments;
	open fh,">:UTF16-LE","file.sofu";
	writeSofu(\*fh,\$hash,$comments);
	close fh;
	$texta=packSofu($arrayref);
	$texth=packSofu($hashref);
	$arrayref=unpackSofu($texta);
	$arrayhash=unpackSofu($texth);

=head1 Synopsis - oo-style

	require Data::Sofu;
	my $sofu=new Sofu;
	%hash=$sofu->read("file.sofu");
	$comments=$sofu->comments;
	$sofu->write("file.sofu",$hashref);
	open fh,">:UTF16-LE",file.sofu";
	$sofu->write(\*fh,$hashref,$comments);
	close fh;
	$texta=$sofu->pack($arrayref);
	$texth=$sofu->pack($hashref);
	$arrayref=$sofu->unpack($texta);
	$arrayhash=$sofu->unpack($texth);

=head1 DESCRIPTION

This Module provides the ability to read and write sofu files of the versions 0.1 and 0.2. Visit L<http://sofu.sf.net> for a description about sofu. 

It can also read not-so-wellformed sofu files and correct their errors. 

Additionally it provides the ability to pack HASHes and ARRAYs to sofu strings and unpack those.

The comments in a sofu file can be preserved if they're saved with $sofu->comment or getSofucomments or if loadFile/load is used.

It also provides a compatibility layer for sofud via Data::Sofu::Object and Data::Sofu->loadFile();

Data::Sofu::Binary provides an experimental interface to Binary Sofu (.bsofu) files and streams. 

=head1 SYNTAX

This module can either be called using object-orientated notation or using the funtional interface.

Some features are only avaiable when using OO.

=head1 FUNCTIONS

=head2 getSofucomments()

Gets the comments of the last file read

=head2 writeSofu(FILE,DATA,[COMMENTS])

Writes a sofu file with the name FILE.

FILE can be:

A reference to a filehandle with the right encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

An existing file of this name will be overwritten.

DATA can be a scalar, a hashref or an arrayref.

The top element of sofu files must be a hash, so any other datatype is converted to {Value=>DATA}.
	
	@a=(1,2,3);
	$sofu->write("Test.sofu",\@a);
	%data=$sofu->read("Test.sofu");
	@a=@{$data->{Value}}; # (1,2,3)

COMMENTS is a reference to hash with comments like the one retuned by comments()

=head2 readSofu(FILE)

Reads the sofu file FILE and returns a hash with the data.

FILE can be:

A reference to a filehandle with the right encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)


These methods are not exported by default:

=head2 loadSofu(FILE)

Reads a .sofu file and converts it to Sofud compatible objects

FILE can be:

A reference to a filehandle with the right encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

Returns a C<Data::Sofu::Object>

=head2 getSofu(HASHREF)

Converts a hashref (like returned from readSofu) to Sofud compatible objects.

Returns a C<Data::Sofu::Object>

=head2 packSofu(DATA,[COMMENTS])

Packs DATA to a sofu string.

DATA can be a scalar, a hashref or an arrayref.

This is different from a normal write(), because the lines are NOT indented and there will be placed brackets around the topmost element. (Which is not Sofu 0.2 conform, please use write(\$scalar,$data) instead).

COMMENTS is a reference to hash with comments like the one retuned by comments().

=head2 packBinarySofu(DATA,[COMMENTS])

Same as packSofu(DATA,[COMMENTS]) but the output is binary.

=head2 packSofuBinary(DATA,[COMMENTS])

Same as packSofu(DATA,[COMMENTS]) but the output is binary.

=head2 unpackSofu(SOFU STRING)

This function unpacks SOFU STRING and returns a scalar, which can be either a string or a reference to a hash or a reference to an array.

Can read Sofu and SofuML files but not binary Sofu files

Note you can also read packed Data with readSofu(\<packed Data string>):

	my $packed = packSofu($tree,$comments);
	my $tree2 = unpackSofu($packed);
	my $tree3 = readSofu(\$packed); 
	# $tree2 has the same data as $tree3 (and $tree of course)

=head2 writeSofuBinary(FILE, DATA, [Comments, [Encoding, [ByteOrder, [SofuMark]]]])

Writes the Data as a binary file.

FILE can be:

A reference to a filehandle with raw encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

DATA has to be a reference to a Hash or Data::Sofu::Object

COMMENTS is a reference to hash with comments like the one retuned by comments

More info on the other parameters in Data::Sofu::Binary

To write other Datastructures use this:

	writeSofuBinary("1.sofu",{Value=>$data});

=head2 writeBinarySofu(FILE, DATA, [Comments, [Encoding, [ByteOrder, [SofuMark]]]])

Same as writeSofuBinary()

=head2 writeSofuML(FILE, DATA, [COMMENTS,[HEADER]])

Writes the Data as an XML file (for postprocessing with XSLT or CSS)

FILE can be:

A reference to a filehandle with some encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

DATA has to be a reference to a Hash or Data::Sofu::Object

COMMENTS is a reference to hash with comments like the one retuned by comments, only used when DATA is not a Data::Sofu::Object

HEADER can be an costum file header, (defaults to C<< qq(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">\n) >> );

Default output (when given a filename) is UTF-8.

=head2 packSofuML(DATA, [COMMENTS, [HEADER]])

Returns DATA as an XML file (for postprocessing with XSLT or CSS) with no Indentation

DATA has to be a reference to a Hash or Data::Sofu::Object

COMMENTS is a reference to hash with comments like the one retuned by comments, only used when DATA is not a Data::Sofu::Object

HEADER can be an costum file header, (defaults to C<< qq(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">\n) >> );

Those are not (quite) the same:

	use Data::Sofu qw/packSofuML writeSofuML/;
	$string = packSofuML($tree,$comments) #Will not indent.
	writeSofuML(\$string,$tree,$comments)# Will indent.


=head1 CLASS-METHODS

=head2 loadFile(FILE)

Reads a .sofu file and converts it to Sofud compatible objects.

FILE can be:

A reference to a filehandle with the right encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)


Returns a C<Data::Sofu::Object>

	my $tree=Data::Sofu->loadFile("1.sofu");
	print $tree->list("Foo")->value(5);
	$tree->list("Foo")->appendElement(new Data::Sofu::Value(8));
	$tree->write("2.sofu");

=head1 METHODS (OO)

=head2 new()

Creates a new Data::Sofu object.

=head2 setIndent(INDENT)

Sets the indent to INDENT. Default indent is "\t".

=head2 setWarnings( 1/0 )

Enables/Disables sofu syntax warnings.

=head2 comments()

Gets/sets the comments of the last file read

=head2 write(FILE,DATA,[COMMENTS])

Writes a sofu file with the name FILE.

FILE can be:

A reference to a filehandle with the right encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

An existing file of this name will be overwritten.

DATA can be a scalar, a hashref or an arrayref.

The top element of sofu files must be a hash, so any other datatype is converted to {Value=>DATA}.
	
	@a=(1,2,3);
	$sofu->write("Test.sofu",\@a);
	%data=$sofu->read("Test.sofu");
	@a=@{$data->{Value}}; # (1,2,3)

COMMENTS is a reference to hash with comments like the one retuned by comments()

=head2 read(FILE)

Reads the sofu file FILE and returns a hash with the data.

FILE can be:

A reference to a filehandle with the right encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)


=head2 pack(DATA,[COMMENTS])

Packs DATA to a sofu string.

DATA can be a scalar, a hashref or an arrayref.

COMMENTS is a reference to hash with comments like the one retuned by comments

This is different from a normal write(), because the lines are NOT indented and there will be placed brackets around the topmost element. (Which is not Sofu 0.2 conform, please use write(\$scalar,$data) instead).

=head2 packBinary(DATA,[COMMENTS])

Same as pack(DATA,[COMMENTS]), but output is binary.

=head2 unpack(SOFU STRING)

This function unpacks SOFU STRING and returns a scalar, which can be either a string or a reference to a hash or a reference to an array.

=head2 load(FILE)

Reads a .sofu file and converts it to Sofud compatible objects

FILE can be:

A reference to a filehandle with the right encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

Returns a C<Data::Sofu::Object>

=head2 toObjects(DATA, [COMMENTS])

Builds a Sofu Object Tree from a perl data structure

DATA can be a scalar, a hashref or an arrayref.

COMMENTS is a reference to hash with comments like the one retuned by comments

Returns a C<Data::Sofu::Object>

=head2 writeBinary(FILE, DATA, [Comments, [Encoding, [ByteOrder, [SofuMark]]]])

Writes the Data as a binary file.

FILE can be:

A reference to a filehandle with raw encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

DATA has to be a reference to a Hash or Data::Sofu::Object

COMMENTS is a reference to hash with comments like the one retuned by comments

More info on the other parameters in C<Data::Sofu::Binary>

To write other Datastructures use this:

	$sofu->writeBinary("1.sofu",{Value=>$data});

=head2 writeML(FILE, DATA, [COMMENTS,[HEADER]])

Writes the Data as an XML file (for postprocessing with XSLT or CSS)

FILE can be:

A reference to a filehandle with some encoding set or

a filename or

a reference to a scalar (Data will be read from a scalar)

DATA has to be a reference to a Hash or Data::Sofu::Object

COMMENTS is a reference to hash with comments like the one retuned by comments, only used when DATA is not a Data::Sofu::Object

HEADER can be an costum file header, (defaults to C<< qq(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">\n) >> );

Default output (when given a filename) is UTF-8.

=head2 packML (DATA, COMMENTS,[HEADER])

Returns DATA as an XML file (for postprocessing with XSLT or CSS) with no Indentation

DATA has to be a reference to a Hash or Data::Sofu::Object

COMMENTS is a reference to hash with comments like the one retuned by comments, only used when DATA is not a Data::Sofu::Object

HEADER can be an costum file header, (defaults to C<< qq(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<!DOCTYPE Sofu SYSTEM "http://sofu.sf.net/Sofu.dtd">\n) >> );

Those are not (quite) the same:

	$string = $sofu->packML($tree,$comments) #Will not indent.
	$sofu->writeML(\$string,$tree,$comments)# Will indent.

=head1 INTERNAL METHODS

=head2 Sofuescape

Escapes a value for Sofu

=head2 Sofukeyescape

Escapes a sofu key

=head2 Sofukeyunescape 

Inversion of Sofukeyescape().

=head2 SofuloadFile

Same as loadSofu().

=head2 allWarn

Turns on all warnings

=head2 comment

like comments()

=head2 commentary

This is used to print the comments into the file

=head2 escape

Method that calls Sofuescape()

=head2 deescape

When parsing a file this one tries to filter out references and deescape sofu strings.

=head2 get

Gets the next char from the input or the buffer. Also takes care of comments.

=head2 getSingleValue

Tries to parse a single value or list

=head2 getSofuComments

Same as getSofucomments().

=head2 iDontKnowWhatIAmDoing()

Turns on warnings.

=head2 iKnowWhatIAmDoing()

Turns on warnings.

=head2 warn()

Turns on warnings.

=head2 noWarn()

Turns off warnings.

=head2 keyescape()

Same as Sofukeyescape only as a method.

=head2 keyunescape()

Same as Sofukeyunescape only as a method.

=head2 noComments()

Discards all commentary from the file while reading.

=head2 object([0/1]).

Enables/disables the object parser (done by readSofu and loadSofu)

=head2 parsList()

Reads a Sofu list from the input buffer.

=head2 parsMap()

Reads a Sofu map from the input buffer.

=head2 parsValue()

Reads a Sofu value / Sofu 0.1 list from the input buffer.

=head2 postprocess()

Corrects references and puts comments into the objects (if load/loadSofu is used)

=head2 refe()

Tests if the input is a reference.

=head2 storeComment()

Stores a comment into the database while reading a sofu file.

=head2 wasbinary()

True when the read file was binary.

=head2 writeList() 

Used to pack/write a sofu list.

=head2 writeMap() 

Used to pack/write a sofu map.

=head1 CHANGES

Keys are now automatically escaped according to the new sofu specification.

Double used references will now be converted to Sofu-References.

read, load, readSofu, loadSofu and Data::Sofu::loaFile now detect binary sofu (and load Data::Sofu::Binary)

read, load, readSofu, loadSofu, Data::Sofu::loaFile, unpackSofu and unpack detect SofuML (and load Data::Sofu::SofuML)

=head1 BUGS

Comments written after an object will be rewritten at the top of an object:

	foo = { # Comment1
		Bar = "Baz"
	} # Comment2

will get to:

	foo = { # Comment1
	# Comment 2
		Bar = "Baz"
	} 


=head1 NOTE on Unicode

Sofu File are normally written in a Unicode format. C<Data::Sofu> is trying to guess which format to read (usually works, thanks to Encode::Guess).

On the other hand the output defaults to UTF-16 (UNIX) (like SofuD). If you need other encoding you will have to prepare the filehandle yourself and give it to the write() funktions...

	open my $fh,">:encoding(latin1)","out.sofu";
	writeSofu($fh,$data);

Warning: UTF32 BE is not supported without BOM (looks too much like Binary);

Notes:

As for Encodings under Windows you should always have a :raw a first layer, but to make them compatible with Windows programs you will have to access special tricks:

	open my $fh,">:raw:encoding(UTF-16):crlf:utf8","out.sofu" #Write Windows UTF-16 Files
	open my $fh,">:raw:encoding(UTF-16)","out.sofu" #Write Unix UTF-16 Files
	#Same goes for UTF32
	
	#UTF-8: Don't use :utf8 or :raw:utf8 alone here, 
	#Perl has a different understanding of utf8 and UTF-8 (utf8 allows some errors).
	open my $fh,">:raw:encoding(UTF-8)","out.sofu" #Unix style UTF-8 
	open my $fh,">:raw:encoding(UTF-8):crlf:utf8","out.sofu" #Windows style UTF-8

	#And right after open():
	print $fh chr(65279); #Print UTF-8 Byte Order Mark (Some programs want it, some programs die on it...)
	
One last thing:

	open my $out,">:raw:encoding(UTF-16BE):crlf:utf8","out.sofu";
	print $out chr(65279); #Byte Order Mark
	#Now you can write out UTF16 with BOM in BigEndian (even if you machine in Little Endian)


=head1 SEE ALSO

perl(1),L<http://sofu.sf.net>

For Sofud compatible Object Notation: L<Data::Sofu::Object>

For Sofu Binary: L<Data::Sofu::Binary>

For SofuML L<Data::Sofu::SofuML>

=cut

1;

