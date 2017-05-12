#!/usr/bin/perl
#Copyright (C) 2004 by Zahatski Aliaksndr
use XML::Simple;
use OpenOffice::OOSheets;
use Text::Iconv;
use utf8;
use strict;
use Filesys::SmbClient;
use Archive::Zip;

my $flag = 0;
my $recs;

sub traverse
{
    my $node = shift;
    if(ref $node eq 'HASH') { 
	foreach my $element(keys %$node) {
	    if($element eq 'query'){
		$flag++;
		traverse($node -> {$element});
		$flag--;
    	    }
	    else{
		    traverse($node -> {$element});
	    }	    	 

	}
    }
    if(ref $node eq 'ARRAY'){
	foreach my $element (@$node){
	    if($flag > 0){
		push(@$recs, $element);
	    }
	    traverse($element);
	}
    }
}

my ($i,@xml_header);
my $inputfile = "";
while (my $line = <> ) {
    $inputfile .= $line;
    if ($line =~ m/\?xml/) {
	push @xml_header,$line ;
    }
}

$/=undef;
my $simple = XML::Simple ->new();
my $ref = $simple -> XMLin($inputfile, ForceArray => 1);
my $cfg = $ref->{config};
traverse($ref);
my $conv=new Text::Iconv ("utf-8","koi8-r");
#group by src and sheets
my $all;
foreach my $one (@$recs) {
push @{$all->{$one->{source}}->{$one->{table}}},$one;
}
foreach my $key (keys %$all) {
	my ($src)=(grep {$_->{srcname} eq $key } @$cfg);
	die 'not found src for source $key' unless $src;
	my $tmp_file_name="/tmp/".rand(20).time().rand(10);
	open TMP,">$tmp_file_name";
	$src->{filepath}=$conv->convert($src->{filepath});
	if ($src->{filepath} =~/^smb/) {
		next;
		my $smb_path=$src->{filepath};
		my $smb = new Filesys::SmbClient(username  => $src->{username} || "guest",
		password  => $src->{password}||"",
		workgroup => $src->{workgroup}||"GAS",
		debug     => 0);
		my $fd = $smb->open($smb_path, '0666') or die "Open $smb_path fail: $!";
		while (defined(my $l= $smb->read($fd,50))) {print TMP $l; }
		$smb->close($fd);
	} else {
	my ($filename)=($src->{filepath}=~m%file://(.*)%);
	open FH, "<$filename" or die "$! file $filename";
	$/=undef;
	print TMP <FH>;
	close FH;
	}
	close TMP;
	my $zip = Archive::Zip->new($tmp_file_name);
	my $content=$zip->contents('content.xml');
	my $table=$all->{$key};
	my @pars=
	map {
		{table=>$_,
		cells=>[map {$_->{addr}}  @{$table->{$_}}]}
	} keys %$table;
	my $res=OpenOffice::OOSheets::GetData (text=>$content,ref=>\@pars);

	while (my ($key,$val)=each %$res) {
		if (my $ref = $table->{$key}) {
			my %table_res=%{$res->{$key}};
			map {$_->{value}=$table_res{$_->{addr}}} @$ref;
			}
	};
	unlink $tmp_file_name;
}
 print @xml_header;
 foreach my $key (keys %$ref){
    if($key eq 'config'){
	$ref -> {$key} = undef;
    }	
 }
 print XMLout($ref);


__END__

Print config data from  STDIN
my $ref={
config=>[
	{
	'srcname'=>'src1',
	'workgroup' => 'MY',
        'password' => '11',
        'filepath' => 'smb://192.168.1.90/d/ZAGAS/Document.swx',
        'username' => 'guestt'
         },
	{
	'srcname'=>'buhgal',
        'filepath' => 'file:///tmp/Document.swx',
         },
	 ],
query=>[
	{
	addr=>'C11',
	table=>'sheet1',
	description=>"Parametr su",
	source=>'src1',
	},
	{
	addr=>'C12',
	table=>'sheet10',
	description=>"Parametr 12",
	source=>'buhgal',
	},
	]
};
print q!<?xml version="1.0" encoding="UTF-8"?>
!.XMLout ($ref);die;


