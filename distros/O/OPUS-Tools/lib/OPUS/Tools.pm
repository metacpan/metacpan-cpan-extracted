#-*-perl-*-
#---------------------------------------------------------------------------
# Copyright (C) 2004-2017 Joerg Tiedemann
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#---------------------------------------------------------------------------

=head1 NAME

OPUS::Tools - a collection of tools for processing OPUS corpora

=head1 SYNOPSIS

# read bitexts (print aligned sentences to screen in readable format)
opus-read OPUS/corpus/RF/xml/en-fr.xml.gz | less

# convert an OPUS bitext to plain text (Moses) format
zcat OPUS/corpus/RF/xml/en-fr.xml.gz | opus2moses -d OPUS/corpus/RF/xml -e RF.en-fr.en -f RF.en-fr.fr

# create a multilingual corpus from the parallel RF corpus
# using 'en' as the pivot language
opus2multi OPUS/corpus/RF/xml sv de en es fr


=head1 DESCRIPTION

This is not a library but just a collection of scripts for processing/converting OPUS corpora.
Download corpus data in XML from L<http://opus.lingfil.uu.se>


=cut

package OPUS::Tools;

use strict;
use DB_File;
use Exporter 'import';

use Archive::Zip qw/ :ERROR_CODES :CONSTANTS /;
use Archive::Zip::MemberRead;
use File::Basename qw(dirname basename);

use OPUS::Tools::ISO639 qw / iso639_TwoToThree iso639_ThreeToName /;


our @EXPORT = qw(set_corpus_info delete_all_corpus_info
                 find_opus_document find_opus_documents 
                 find_bitext find_sentalign_file
                 open_bitext open_opus_document
                 $OPUS_HOME $OPUS_CORPUS $OPUS_HTML 
                 $OPUS_DOWNLOAD $OPUS_RELEASES
                 $OPUS_PUBLIC);


# set OPUS home dir
my @ALT_OPUS_HOME = ( '/proj/OPUS',                # taito
		      '/projects/nlpl/data/OPUS',  # abel
		      '/home/opus/OPUS',           # lingfil
		      $ENV{HOME}.'/OPUS',          # user home
		      $ENV{HOME}.'/research/OPUS');

our $OPUS_HOME;
foreach (@ALT_OPUS_HOME){
    if (-d $_){
	$OPUS_HOME = $_;
	last;
    }
}


## set OPUS release dir
my @ALT_OPUS_NLPL = ( '/projappl/nlpl/data/OPUS',  # puhti
		      '/proj/nlpl/data/OPUS',      # taito
		      '/projects/nlpl/data/OPUS',  # abel
                      $OPUS_HOME.'/releases');

our $OPUS_RELEASES = $OPUS_HOME;
foreach (@ALT_OPUS_NLPL){
    if (-d $_){
	$OPUS_RELEASES = $_;
	last;
    }
}


# our $OPUS_HOME     = '/proj/nlpl/data/OPUS';
our $OPUS_PUBLIC   = $OPUS_HOME.'/public_html';
# our $OPUS_PUBLIC   = $OPUS_HOME.'/web';
our $OPUS_HTML     = $OPUS_HOME.'/html';
our $OPUS_CORPUS   = $OPUS_HOME.'/corpus';
our $OPUS_DOWNLOAD = $OPUS_HOME.'/download';
our $INFODB_HOME   = $OPUS_PUBLIC;

our $VERBOSE = 0;



## variables for info databases

my %LangNames;
my %Corpora;
my %LangPairs;
my %Bitexts;
my %Info;

my $DBOPEN = 0;

## ZipFiles = hash of zip file handles (key = zipfile)
## CorpusBase = corpus base dir of zip archives
my %ZipFiles;
my %CorpusBase;


## various database files that keep information about corpora
##
## LangNames: maps language names to language Ids
##   Corpora: "language" -> list-of-corpora
## LangPairs: "source-lang" -> list-of-target-langs
##   Bitexts: "src-trg" -> list-of-corpora
##      Info: "corpus/src-trg" -> list-of-files-and-statistics

sub open_info_dbs{
    system("mkdir -p $INFODB_HOME") unless (-d $INFODB_HOME);
    print STDERR "open info DBs in $INFODB_HOME\n";
    tie %LangNames,"DB_File","$INFODB_HOME/LangNames.db";
    tie %Corpora,"DB_File","$INFODB_HOME/Corpora.db";
    tie %LangPairs,"DB_File","$INFODB_HOME/LangPairs.db";
    tie %Bitexts,"DB_File","$INFODB_HOME/Bitexts.db";
    tie %Info,"DB_File","$INFODB_HOME/Info.db";
    $DBOPEN = 1;
}

sub close_info_dbs{
    untie %LangNames;
    untie %Corpora;
    untie %LangPairs;
    untie %Bitexts;
    untie %Info;
    $DBOPEN = 0;
}

sub set_corpus_info{
    my ($corpus,$release,$src,$trg,$infostr) = @_;

    unless (defined $corpus && defined $src && defined $trg){
	print STDERR "specify corpus src trg";
	return 0;
    }
    $release = get_corpus_version($corpus) unless ($release);

    my $ReleaseBase = $corpus.'/'.$release;
    my $ReleaseDir  = $OPUS_RELEASES.'/'.$ReleaseBase;
    my $corpuskey   = $corpus.'@'.$release;

    &open_info_dbs unless ($DBOPEN);

    ## set corpus for source and target language
    foreach my $l ($src,$trg){
	if (! exists $LangNames{$l}){
	    $LangNames{$l} = &iso639_ThreeToName(&iso639_TwoToThree($l));
	}
	if (exists $Corpora{$l}){
	    my @corpora = split(/\:/,$Corpora{$l});
	    my ($found) = grep(index($_,$corpus.'@') == 0,@corpora);
	    if ($found){
		my @releases = split(/\@/,$found);
		shift(@releases);
		unless (grep($_ eq $release,@releases)){
		    $found .= '@'.$release;
		    @corpora = grep(index($_,$corpus.'@') != 0,@corpora);
		    push(@corpora,$found);
		}
	    }
	    else{
		push(@corpora,$corpuskey);
	    }
	    @corpora = sort @corpora;
	    $Corpora{$l} = join(':',@corpora);
	}
	else{
	    $Corpora{$l} = $corpuskey;
	}
    }

    ## set corpus for bitext
    my $langpair = join('-',sort ($src,$trg));
    if (exists $Bitexts{$langpair}){
	my @corpora = split(/\:/,$Bitexts{$langpair});
	my ($found) = grep(index($_,$corpus.'@') == 0,@corpora);
	if ($found){
	    my @releases = split(/\@/,$found);
	    shift(@releases);
	    unless (grep($_ eq $release,@releases)){
		$found .= '@'.$release;
		@corpora = grep(index($_,$corpus.'@') != 0,@corpora);
		push(@corpora,$found);
	    }
	}
	else{
	    push(@corpora,$corpuskey);
	}
	@corpora = sort @corpora;
	$Bitexts{$langpair} = join(':',@corpora);
    }
    else{
	$Bitexts{$langpair} = $corpuskey;
    }


    ## set src-trg
    if (exists $LangPairs{$src}){
	my @lang = split(/\:/,$LangPairs{$src});
	unless (grep($_ eq $trg,@lang)){
	    push(@lang,$trg);
	    @lang = sort @lang;
	    $LangPairs{$src} = join(':',@lang);
	}
    }
    else{
	$LangPairs{$src} = $trg;
    }

    ## set trg-src
    if (exists $LangPairs{$trg}){
	my @lang = split(/\:/,$LangPairs{$trg});
	unless (grep($_ eq $src,@lang)){
	    push(@lang,$src);
	    @lang = sort @lang;
	    $LangPairs{$trg} = join(':',@lang);
	}
    }
    else{
	$LangPairs{$trg} = $src;
    }

    unless ($infostr){
	$infostr = read_info_files($corpus,$release,$src,$trg);
    }

    my $key = $corpus.'/'.$release.'/'.$langpair;
    if ($infostr){
	if ($VERBOSE){
	    if (exists $Info{$key}){
		my $info = $Info{$key};
		print STDERR "overwrite corpus info!\n";
		print STDERR "old = ",$Info{$key},"\n";
		print STDERR "new = ",$infostr,"\n";
	    }
	}
	$Info{$key} = $infostr;
    }

    ## info for monolingual data
    for my $l ($src,$trg){
	$infostr = read_info_files($corpus,$release,$l);
	if ($infostr){
	    $key = $corpus.'/'.$release.'/'.$l;
	    $Info{$key} = $infostr;
	}
    }
}


sub delete_all_corpus_info{
    my ($corpus) = @_;

    unless (defined $corpus){
	print STDERR "specify corpus src trg";
	return 0;
    }

    &open_info_dbs unless ($DBOPEN);

    foreach my $c (keys %Corpora){
	my @corpora = split(/\:/,$Corpora{$c});
	if (grep($_ eq $corpus,@corpora)){
	    @corpora = grep(index($_,$corpus.'@') != 0,@corpora);
	    @corpora = grep($_ ne '',@corpora);
	    $Corpora{$c} = join(':',@corpora);
	}
    }

    my %src2trg=();

    foreach my $c (keys %Bitexts){
	my @corpora = split(/\:/,$Bitexts{$c});
	if (grep($_ eq $corpus,@corpora)){
	    @corpora = grep(index($_,$corpus.'@') != 0,@corpora);
	    @corpora = grep($_ ne '',@corpora);
	    if (@corpora){
		$Bitexts{$c} = join(':',@corpora);
		my ($s,$t) = split(/\-/,$c);
		$src2trg{$s}{$t}++;
		$src2trg{$t}{$s}++;
	    }
	    else{
		delete $Bitexts{$c};
	    }
	}
	else{
	    my ($s,$t) = split(/\-/,$c);
	    $src2trg{$s}{$t}++;
	    $src2trg{$t}{$s}++;
	}
    }
    
    foreach my $l (keys %LangPairs){
	$LangPairs{$l}=join(':',sort keys %{$src2trg{$l}});
    }

    foreach my $i (keys %Info){
	my ($c,$l,$r) = split(/\//,$i);
	if ($c eq $corpus){
	    delete $Info{$i};
	}
    }
}


sub get_corpus_version{
    my ($corpus) = @_;
    if (-e "$OPUS_HOME/corpus/Makefile.def"){
	open F, "<$OPUS_HOME/corpus/Makefile.def";
	while (<F>){
	    if (/VERSION\s+=\s+(\S+)(\s|\Z)/){
		return $1;
	    }
	}
    }
    return 'latest';
}


sub read_info_files{
    my ($corpus,$release,$src,$trg) = @_;

    return &read_bitext_info(@_) if ($trg);
    return &read_monolingual_info(@_) if ($src);
    return '';
}

sub read_bitext_info{
    my ($corpus,$release,$src,$trg) = @_;

    my $langpair    = join('-',sort ($src,$trg));
    $release        = get_corpus_version($corpus) unless ($release);
    my $ReleaseBase = $corpus.'/'.$release;
    my $ReleaseDir  = $OPUS_RELEASES.'/'.$ReleaseBase;
    my $InfoDir     = $ReleaseDir.'/info';

    my $moses = 'moses='.$ReleaseBase.'/moses/'.$langpair.'.txt.zip';
    my $tmx   = 'tmx='.$ReleaseBase.'/tmx/'.$langpair.'.tmx.gz';
    my $xces  = 'xces='.$ReleaseBase.'/xml/'.$langpair.'.xml.gz:';
    $xces    .= $ReleaseBase.'/xml/'.$src.'.zip:';
    $xces    .= $ReleaseBase.'/xml/'.$trg.'.zip';

    # my $moses = 'moses=moses/'.$langpair.'.txt.zip';
    # my $tmx   = 'tmx=tmx/'.$langpair.'.tmx.gz';
    # my $xces  = 'xces=xml/'.$langpair.'.xml.gz:';
    # $xces    .= 'xml/'.$src.'.zip:';
    # $xces    .= 'xml/'.$trg.'.zip';

    my @infos = ();

    if (-e "$InfoDir/$langpair.txt.info"){
	open F, "<$InfoDir/$langpair.txt.info";
	my @val = <F>;
	chomp(@val);
	$moses .= ':'.join(':',@val);
	push(@infos,$moses);
    }

    if (-e "$InfoDir/$langpair.tmx.info"){
	open F, "<$InfoDir/$langpair.tmx.info";
	my @val = <F>;
	chomp(@val);
	$tmx .= ':'.join(':',@val);
	push(@infos,$tmx);
    }

    if (-e "$InfoDir/$langpair.info"){
	open F, "<$InfoDir/$langpair.info";
	my @val = <F>;
	chomp(@val);
	$xces .= ':'.join(':',@val);
	push(@infos,$xces);
    }

    if (-e "$ReleaseDir/smt/$langpair.alg.zip"){
	push(@infos,"alg=$ReleaseBase/smt/$langpair.alg.zip");
    }
    if (-e "$ReleaseDir/smt/$langpair.zip"){
	push(@infos,"smt=$ReleaseBase/smt/$langpair.zip");
    }
    if (-e "$ReleaseDir/dic/$langpair.dic.gz"){
	push(@infos,"dic=$ReleaseBase/dic/$langpair.dic.gz");
    }

    return join('+',@infos);
}


sub read_monolingual_info{
    my ($corpus,$release,$lang) = @_;

    $release        = get_corpus_version($corpus) unless ($release);
    my $ReleaseBase = $corpus.'/'.$release;
    my $ReleaseDir  = $OPUS_RELEASES.'/'.$ReleaseBase;
    my $InfoDir     = $ReleaseDir.'/info';

    my @infos = ();

    my @langstats = ();
    if (-e "$InfoDir/$lang.info"){
	open F, "<$InfoDir/$lang.info";
	@langstats = <F>;
	chomp(@langstats);
    }

    if (-e "$ReleaseDir/xml/$lang.zip"){
	my $resource = "xml=$ReleaseBase/xml/$lang.zip";
	$resource .= ':'.join(':',@langstats) if (@langstats);
	push(@infos,$resource);
    }
    if (-e "$ReleaseDir/raw/$lang.zip"){
	my $resource = "raw=$ReleaseBase/raw/$lang.zip";
	pop(@langstats);
	$resource .= ':'.join(':',@langstats) if (@langstats);
	push(@infos,$resource);
    }
    if (-e "$ReleaseDir/mono/$lang.txt.gz"){
	push(@infos,"mono=$ReleaseBase/mono/$lang.txt.gz");
    }
    if (-e "$ReleaseDir/mono/$lang.tok.gz"){
	push(@infos,"monotok=$ReleaseBase/mono/$lang.tok.gz");
    }
    if (-e "$ReleaseDir/freq/$lang.freq.gz"){
	push(@infos,"freq=$ReleaseBase/freq/$lang.freq.gz");
    }
    if (-e "$ReleaseDir/parsed/$lang.zip"){
	push(@infos,"parsed=$ReleaseBase/parsed/$lang.zip");
    }

    return join('+',@infos);
}





# old style of download files in tar

sub read_old_info_files{
    my ($corpus,$src,$trg) = @_;

    my $CorpusXML = $OPUS_HOME.'/corpus/'.$corpus.'/xml';
    my $langpair  = join('-',sort ($src,$trg));

    my $key = $corpus.'/'.$langpair;
    my $moses = 'moses='.$key.'.txt.zip';
    my $tmx = 'tmx='.$key.'.tmx.gz';
    my $xces = 'xces='.$key.'.xml.gz:';
    $xces .= $corpus.'/'.$src.'.tar.gz:';
    $xces .= $corpus.'/'.$trg.'.tar.gz';

    my @infos = ();

    if (-e "$CorpusXML/$langpair.txt.info"){
	open F, "<$CorpusXML/$langpair.txt.info";
	my @val = <F>;
	chomp(@val);
	$moses .= ':'.join(':',@val);
	push(@infos,$moses);
    }

    if (-e "$CorpusXML/$langpair.tmx.info"){
	open F, "<$CorpusXML/$langpair.tmx.info";
	my @val = <F>;
	chomp(@val);
	$tmx .= ':'.join(':',@val);
	push(@infos,$tmx);
    }

    if (-e "$CorpusXML/$langpair.info"){
	open F, "<$CorpusXML/$langpair.info";
	my @val = <F>;
	chomp(@val);
	$xces .= ':'.join(':',@val);
	push(@infos,$xces);
    }

    return join('+',@infos);
}


sub open_bitext{
    my ($Bitext,$CorpusName,$CorpusRelease,$CorpusType,$SrcId,$TrgId) = @_;
    my ($SentAlignFile, $CorpusDir) = find_bitext($Bitext,$CorpusName,
						  $CorpusRelease,$CorpusType,
						  $SrcId,$TrgId);
    my $fh;
    if ($SentAlignFile=~/\.gz/){
	open $fh,"gzip -cd <$SentAlignFile |";
    }
    else{
	open $fh,"<$SentAlignFile";
    }
    return wantarray ? ($fh,$CorpusDir) : $fh;
}


## find the bitext given some parameters
## return (SentAlignFile,CorpusDir)

sub find_bitext{
    my ($Bitext,$CorpusName,$CorpusRelease,$CorpusType,$SrcId,$TrgId) = @_;

    ## bitext = langpair if not specified otherwise
    $Bitext = join('-',sort($SrcId,$TrgId)) unless ($Bitext);

## unless we have the path to the sentence alignment file
## split into components giving either
##
##    CorpusName/Release/Type/LangPair
##    CorpusName/Type/LangPair
##    CorpusName/LangPair
##
## sentence alignments are expected to be in either
##    OPUS_RELEASES/CorpusName/Release/xml/LangPair.xml.gz  OR
##    OPUS_CORPUS/CorpusName/xml/LangPair.xml.gz

    unless (-e $Bitext){
	my @parts = split(/\//,$Bitext);
	my $LangPair   = pop(@parts);
	$CorpusName    = shift(@parts) if (@parts);
	$CorpusType    = pop(@parts) if (@parts);
	$CorpusRelease = pop(@parts) if (@parts);

	$Bitext = join('/',($OPUS_RELEASES,$CorpusName,
			    $CorpusRelease,'xml',$LangPair));
	$Bitext .= '.xml.gz';
	unless (-e $Bitext){
	    $Bitext = join('/',($OPUS_CORPUS,$CorpusName,
				'xml',$LangPair));
	    $Bitext .= '.xml.gz';
	}
    }

## set corpus home dir 
## (relative to aligned documents in sentence alignment file)
##
## - use CorpusName if it is a directory OR
## - OPUS_RELEASES/CorpusName/CorpusRelease/CorpusType OR
## - OPUS_CORPUS/CorpusName/CorpusType

    my $CorpusDir = undef;
    if (-d $CorpusName){
	$CorpusDir = $CorpusName;
    }
    elsif ($CorpusName){
	$CorpusDir = join('/',($OPUS_RELEASES,$CorpusName,
			       $CorpusRelease,$CorpusType));
	unless (-d $CorpusDir){
	    $CorpusDir = join('/',($OPUS_CORPUS,$CorpusName,$CorpusType));
	}
    }
    return ($Bitext,$CorpusDir);
}





## make some guesses to find a document if the path in doc does not exist
sub find_sentalign_file{
    my ($dir,$SrcID,$TrgID,$ALIGN,$release) = @_;

    if ($dir && -d $dir){
	return "$dir/$SrcID-$TrgID.xml.gz" if (-e "$dir/$SrcID-$TrgID.xml.gz");
	return "$dir/$TrgID-$SrcID.xml.gz" if (-e "$dir/$TrgID-$SrcID.xml.gz");
    }

    return $ALIGN if (-e $ALIGN);
    return "$ALIGN.gz" if (-e "$ALIGN.gz");
    return "$dir/$ALIGN" if (-d $dir && -e "$dir/$ALIGN");
    return "$dir/$ALIGN.gz" if (-d $dir && -e "$dir/$ALIGN.gz");

    $dir = dirname($ALIGN) unless ($dir);
    my @ALTDIR = ( $dir,
		   "$OPUS_RELEASES/$dir/$release",
		   "$OPUS_RELEASES/$dir",
		   "$OPUS_CORPUS/$dir" );

    foreach (@ALTDIR){
	if (-d "$_/xml"){
	    $dir = "$_/xml";
	    last;
	}
	elsif (-d "$_/raw"){
	    $dir = "$_/raw";
	    last;
	}
    }

    unless($ALIGN){
	return "$dir/$SrcID-$TrgID.xml.gz" if (-e "$dir/$SrcID-$TrgID.xml.gz");
	return "$dir/$TrgID-$SrcID.xml.gz" if (-e "$dir/$TrgID-$SrcID.xml.gz");
    }

    my $base = basename($ALIGN);
    if (-f "$dir/$base"){ $ALIGN = "$dir/$base"; }
    elsif (-f "$dir/$base.gz"){ return "$dir/$base.gz"; }
    elsif (-f "$dir/$base.xml.gz"){ return "$dir/$base.xml.gz"; }
}




## make some guesses to find a document if the path in doc does not exist
sub find_opus_document{
    my ($dir,$doc) = @_;

    return "$dir/$doc" if (-e "$dir/$doc");
    return $doc if (-e $doc);

    ## gzipped and w/o dir
    return "$doc.gz" if (-e "$doc.gz");
    return "$dir/$doc.gz" if (-e "$dir/$doc.gz");

    ## various alternatives in OPUS_CORPUS homedir
    return "$OPUS_CORPUS/$dir/$doc" if (-e "$OPUS_CORPUS/$dir/$doc");
    return "$OPUS_CORPUS/$dir/$doc.gz" if (-e "$OPUS_CORPUS/$dir/$doc.gz");
    return "$OPUS_CORPUS/$doc" if (-e "$OPUS_CORPUS/$doc");
    return "$OPUS_CORPUS/$doc.gz" if (-e "$OPUS_CORPUS/$doc.gz");
    return "$OPUS_CORPUS/$dir/xml/$doc" if (-e "$OPUS_CORPUS/$dir/xml/$doc");
    return "$OPUS_CORPUS/$dir/xml/$doc.gz" if (-e "$OPUS_CORPUS/$dir/xml/$doc.gz");
    return "$OPUS_CORPUS/$dir/raw/$doc" if (-e "$OPUS_CORPUS/$dir/raw/$doc");
    return "$OPUS_CORPUS/$dir/raw/$doc.gz" if (-e "$OPUS_CORPUS/$dir/raw/$doc.gz");

    ## try /raw/ instead of /xml/
    my $tmpdoc = $doc;
    $tmpdoc =~s/(\A|\/)xml\//${1}raw\//;
    return find_opus_document($dir,$tmpdoc) if ($doc ne $tmpdoc);

    my $tmpdir = $dir;
    $tmpdir =~s/(\A|\/)xml(\/|\Z)/${1}raw$2/;
    return find_opus_document($tmpdir,$doc) if ($dir ne $tmpdir);

    if (($doc ne $tmpdoc) && ($dir ne $tmpdir)){
	return find_opus_document($tmpdir,$tmpdoc);
    }
    return undef;
}



## open zip files and store a handle in ZipFiles
sub open_zip_file{
    my $corpus = shift;
    if (exists $ZipFiles{$corpus}){
	return $ZipFiles{$corpus};
    }

    my $zipfile = $corpus;
    unless (-e $zipfile){
	my @parts = split(/\//,$zipfile);
	if ($#parts){
	    $parts[-2] = 'raw';
	    $zipfile = join('/',@parts);
	}
    }
    if (-e $zipfile){
	$ZipFiles{$corpus} = Archive::Zip->new($zipfile);
	my $basename = basename($zipfile);
	$basename =~s/\.zip$//;
	my $fh = Archive::Zip::MemberRead->new($ZipFiles{$corpus},
					       $basename.'/'.'INFO');
	unless ($fh->{member}){
	    $fh = Archive::Zip::MemberRead->new($ZipFiles{$corpus},'INFO');
	}
	if ($fh->{member}){
	    my $line = $fh->getline();
	    my ($name,$type) = split(/\//,$line);
	    $CorpusBase{$corpus} = $name.'/'.$type;
	}
	return $ZipFiles{$corpus} if ($ZipFiles{$corpus});
    }

    delete $ZipFiles{$zipfile};
    return undef;
}


## make some guesses to find a document if the path in doc does not exist
sub open_opus_document{
    my ($fh,$dir,$doc) = @_;

    my ($lang) = split(/\//,$doc);
    my $zipfile = $dir.'/'.$lang.'.zip';

    ## try to open a zip file
    my $zip = open_zip_file($zipfile);
    if ($zip){
	$doc =~s/\.gz$//;                      # remove .gz extension
	my $FileBase = $CorpusBase{$zipfile};  # file base in the corpus
	$$fh = Archive::Zip::MemberRead->new($zip,$FileBase.'/'.$doc);
	return 1 if ($$fh);
    }

    ## no zip file? then look for physical file
    if ($doc = find_opus_document($dir,$doc)){
	close $$fh if (defined $$fh);
	if ($doc=~/\.gz$/){
	    return open $$fh,"gzip -cd <$doc |";
	}
	else{
	    return open $$fh,"<$doc";
	}
    }
    ## no file found - try zip archives
    return 0;
}



=head1

find_opus_documents($dir,$ext[,$mindepth[,$depth]])

=cut

sub find_opus_documents{
    my $dir      = shift;
    my $ext      = shift;
    my $mindepth = shift;
    my $depth    = shift;

    my $ext = 'xml' unless (defined $ext);

    ## return files in zip files if available
    my $zip = open_zip_file($dir.'.zip');
    if ($zip){
	return $zip->memberNames(); 
    }

    my @docs=();
    if (opendir(DIR, $dir)){
	my @files = grep { /^[^\.]/ } readdir(DIR);
	closedir DIR;
	foreach my $f (@files){
	    if (-f "$dir/$f" && $f=~/\.$ext(.gz)?$/){
		if ((not defined($mindepth)) ||
		    ($depth>=$mindepth)){
		    push (@docs,"$dir/$f");
		}
	    }
	    if (-d "$dir/$f"){
		$depth++;
		push (@docs,FindDocuments("$dir/$f",$ext,$mindepth,$depth));
	    }
	}
    }
    return @docs;
}

# my @files = $zip->memberNames(); 



1;

__END__

=head1 AUTHOR

Joerg Tiedemann, L<https://bitbucket.org/tiedemann>

=head1 TODO

Better documentation in the individual scripts.

=head1 BUGS AND SUPPORT

Please report any bugs or feature requests to
L<https://bitbucket.org/tiedemann/opus-tools>.

=head1 SEE ALSO

L<http://opus.lingfil.uu.se>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Joerg Tiedemann.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
