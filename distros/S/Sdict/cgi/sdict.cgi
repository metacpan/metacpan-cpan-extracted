#!/usr/local/bin/perl
#
# $RCSfile: sdict.cgi,v $
# $Author: swaj $
# $Revision: 1.23 $
#
# Sdict Web Dictionary.
#
# Copyright (c) Alexey Semenoff 2001-2007. All rights reserved.
# Distributed under GNU Public License.
#
#

#
# Installation tips for Unix/Apache
#
#  1. Make sure you have Compress::Zlib module installed, type
#
#       perl -MCompress::Zlib -e 'print "$Compress::Zlib::VERSION \n"';
#
#  2. Copy sdict.cgi into server cgi-bin directory (it also supportmod_perl);
#
#  3. Copy Sdict.pm to any of the directories listed by
#
#       perl -e 'for (@INC) { print "$_\n" unless /^\./}'
#
#  4. Edit sdict.cgi 'BEGIN {' section ,
#
#       line:
#
#       $dct_path = '/var/lib/sdict';
#
#       '$dct_path' should point to directory contains .dct files;
#

use 5.008;
use strict;
use warnings;
use Encode qw /encode decode from_to /;
use CGI qw/:standard/;
use Fcntl ':flock';

$CGI::POST_MAX=1024 * 10;
$CGI::DISABLE_UPLOADS = 1;

use vars qw /
    $DIC_VERSION
    $timeout
    $dct_path
    $q
    $sname
    $sd
    $debug
    $dct
    $word
    $letter
    $offset
    $search
    $restrict
    $reqs_per_ip
    $ip_db
    $lock_file
    $nph_mode
    $image
    $document_root
    $log_file
    $strip_all_tags
  /;

use constant {
    SDICT_LOAD_ITEMS       => 10 ,
    SDICT_ARTICLE_LEN      => 240,
};


BEGIN {
    push @INC, '/usr/local/lib' ;
    $dct_path = '/var/lib/sdict';

    $timeout = 30;
    $SIG{'ALRM'} = sub { $_ = localtime (time); print STDERR "Script timeout: $_\n"; exit; };
    alarm $timeout;
    $DIC_VERSION='1.2.2';
    $ip_db = '/tmp/sdict-cgi-db';
    $lock_file = '/tmp/sdict-cgi.lock';
    $reqs_per_ip = 10;
    $restrict = 0;
    $image = '';
    $strip_all_tags = 0;
    $offset = 0;
    $dct = q{};
    $word = q{};
    $letter = q{};

    $debug = 0;
}

use Sdict;

sub printd (;@);

$sd = Sdict->new unless $sd;

$q = new CGI;
$sname = $ENV{'SCRIPT_NAME'};

$search = $q->param ( 'search'  );
$dct    = $q->param ( 'dicname' );
$word   = $q->param ( 'word'    );
$letter = $q->param ( 'letter'  );
$offset = $q->param ( 'offset'  );

log_hit() if (defined ($log_file) );

if ( defined ( $ENV{ 'PATH_INFO' } ) &&
     $ENV{ 'PATH_INFO' } eq '/logo' ) {
    print $q->header (
		      -expires => 'now',
		      -type=>'image/png',
		      );

    $image .= $_ while (<DATA>);
    print $image;
    exit 0;
}


if ($sname =~ /nph\-/ ) {
    printd 'sending nph header';     
    print $q->header (
		      -nph => 1,
		      -expires => 'now',
		      -charset => 'utf-8'
		      );

}
else {
    printd 'sending normal header';     
    print $q->header (
		      -expires => 'now',
		      -charset => 'utf-8'
		      );
}

print $q->start_html (
		      -title=> 'Sdictionary - GNU Web Sdictionary',
		      -BGCOLOR=>'lightblue'
		      );

print hr;
print h1 "<a href=\"$sname\">Online Sdictionary</a>";


if ( defined ( $ENV{ 'PATH_INFO' } ) && $ENV{ 'PATH_INFO' } eq '/help' ) {
    print_help();
    print_footer();
    print $q->end_html;
    exit 0;
}

print_form();
print_about();


if ( defined ( $ENV{ 'PATH_INFO' } )   &&
     $ENV{ 'PATH_INFO' } eq '/browse'  &&
     ! defined ($search) ) {
    handle_browse() if check_limit();
}
elsif ( defined ( $word ) ) {
    print_results() if check_limit();
}

print_footer();
print $q->end_html;
exit 0;

####
#  #
####

sub check_limit {
    printd 'check_limit()';
    my %ips;
    my $cnt = 0;

    return 1 unless ($restrict);

    unless (-e $lock_file) {
	printd 'creating lock file';
	unless (open (LF, ">$lock_file")) {
	    printd "unable to create lock file: $!";
	    return 1;
	}
	close LF;
    }

    unless (open (LF, "< $lock_file")) {
	printd "unable to open lock file: $!";
	return 1;
    }

    flock(LF, LOCK_EX);

    if (dbmopen(%ips, $ip_db, 0600)) {
	$cnt = ++$ips{$ENV{'REMOTE_ADDR'}};
	dbmclose(%ips);
    }

    flock(LF, LOCK_UN);
    close LF;

    printd "connects from $ENV{'REMOTE_ADDR'} = $cnt"; 

    if ($cnt > $reqs_per_ip) {
	print h1 'Too many requests from your IP, sorry';
	return 0;
    } else {
	return 1;
    }
}


sub print_results {
    printd 'print_results()';
    
    printd "dct '$dct'";
    printd "word '$word'";

    return unless (check_or_load_dct() );

    printd "Searching for '$word'";

    my $art = $sd->search_word($word);

    $art =~ s|<t>| [|;
    $art =~ s|</t>|] |;
    $art =~ s|<.+?>||g if ($strip_all_tags);

    if ($art ne ``) {
	printd 'got normal art';
	print <<EOS;
        <hr>
        <center>
	<table cellpadding=5 cellspacing=5 border=0 width="90%">
	    <tr><td><h1>$word</h1></td></tr>
	    <tr><td><hr></td></tr>
	    <tr><td align=left> $art </td></tr>
        </table>
        </center>
EOS
	return;
    } else {
	printd 'Trying to print_by_letters()';
	unless (print_by_letters()) {
	    not_found();
	    printd 'Not found';
	}
    }
}


sub new_search {
    printd 'new_search()';
    print "<p><br><a href=\"$ENV{'SCRIPT_NAME'}?dicname=$dct\">New search</a>\n" if ($dct);
}


sub handle_browse {
    printd 'handle_browse()';
    
    $offset = 0 unless (defined ($offset) );

    printd "dct '$dct'";
    printd "word '$word'";
    printd "letter '$letter'";

    if ( $dct eq q{} ) {
	printd 'No dictionary selected!';
	print hr;
	print_dic_list();
	return;
    }

    if ( $letter eq q{} ) {
	printd 'No letters!';
	print hr;
	print_dic_letters();
	return;
    }

    if ( $word eq q{} ) {
	printd 'No word!';
	print hr;
	print_by_letter();
	return;
    }

    else {
	print_results ();
	my $ltr = decode ( "utf8", $letter );
	$ltr = encode ( "utf8", $ltr );
	my $back = $sname . $ENV{ 'PATH_INFO' } . "?dicname=$dct&letter=$ltr";
	$back .= "&offset=$offset" if ($offset);

	print "<p> <a href=\"$back\">Back to \"$ltr\"</a>";
    }
}


sub print_dic_list {
    printd 'print_dic_list()';

    my %dd = get_avail_dicts ();
    my @vals = sort (keys %dd);

    unless (@vals) {
	print h1 'No dictionaries found!';
    }
    else {
	my $burl = $sname . $ENV{ 'PATH_INFO' };

	print h1 'Available dictionaries:';

	print '<ul type=circle>';
	for my $j (@vals) {
	    my $href = $burl . "?dicname=$j";
	    print "<li><a href=\"$href\">", $dd{ $j } , '</a>';
	}
	print '</ul>';
    }
}


sub check_or_load_dct {
    printd 'check_or_load_dict()';

    if ($sd->{infile} eq "$dct_path/$dct") {
	printd "dct '$dct_path/$dct' already loaded";
    } else { 
	$sd->init ( { file => "$dct_path/$dct" } );
	unless ($sd->read_header) {
	    printd "Unable to load dictionary header from file '$dct'";
	    print h1 'Unable to load dictionary';
	    $sd->{infile}= undef;
	    return 0;
	}
           
	unless ($sd->load_dictionary_fast) {
	    printd "Unable to load dictionary from file '$dct'";
	    print h1 'Unable to load dictionary';
	    return 0;
	}
    }    
    return 1;
}


sub print_dic_letters {
    printd 'print_dic_letters()';

    return unless (check_or_load_dct() );

    my $tit = $sd->{header}->{title};

    my $durl = $sname . $ENV{ 'PATH_INFO' } . "?dicname=$dct";
    print h1 "<a href=\"$durl\">$tit</a>";


    my $burl = $sname . $ENV{ 'PATH_INFO' } . "?dicname=$dct&letter=";

    for my $j ( @{ $sd->{ sindex_1 } } ) {
	my ( $wo, $ndx ) = @$j;
	
	#printd "wo>$wo<";
	$wo = encode ( "utf8", $wo );
	my $wou = $wo;
	utf8_to_url_string (\$wou);

	my $href = $burl . $wou ;

	print "<a href=\"$href\">" , '[' , $wo , ']</a> ' ;
    }
}

sub utf8_to_url_string {
    my $ref_line = $_[0];

    $$ref_line =~ s|\%|%25|g;


    $$ref_line =~ s| |%20|g;
    $$ref_line =~ s|\!|%21|g;
    $$ref_line =~ s|\"|%22|g;
    $$ref_line =~ s|\#|%23|g;
    $$ref_line =~ s|\$|%24|g;

    $$ref_line =~ s|\&|%26|g;
    $$ref_line =~ s|\'|%27|g;
    $$ref_line =~ s|\(|%28|g;
    $$ref_line =~ s|\)|%29|g;
    $$ref_line =~ s|\*|%2A|g;
    $$ref_line =~ s|\+|%2B|g;
    $$ref_line =~ s|\,|%2C|g;
    $$ref_line =~ s|\-|%2D|g;
    $$ref_line =~ s|\.|%2E|g;
    $$ref_line =~ s|\/|%2F|g;

    $$ref_line =~ s|\:|%3A|g;
    $$ref_line =~ s|\;|%3B|g;
 
    $$ref_line =~ s|\<|%3C|g;
    $$ref_line =~ s|\=|%3D|g;
    $$ref_line =~ s|\>|%3E|g;
    $$ref_line =~ s|\?|%3F|g;

    $$ref_line =~ s|\\|%5C|g;
    $$ref_line =~ s|\^|%5E|g;
    $$ref_line =~ s|\`|%60|g;
    $$ref_line =~ s|\{|%7B|g;
    $$ref_line =~ s/\|/%7C/g;
    $$ref_line =~ s|\}|%7D|g;
    $$ref_line =~ s|\~|%7E|g;
}


sub print_by_letters {
    printd 'print_by_letters()';

# dictionary already loaded, search string is in '$word'

    #printd "word = '$word'";

    my $word_d = q{};
    eval { $word_d = decode ("utf8", $word); };

    #printd "word_d = '$word_d'";

    my $word_len = length ($word_d);

    my $sndx_ref = undef;

    my $sl;

    if ($word_len == 1) {
	$sndx_ref = $sd->{ sindex_1 };
	$sl = 1;
    }
    elsif  ($word_len == 2) {
	$sndx_ref = $sd->{ sindex_2 };
	$sl = 2;
    }
    else  { # >=3
	$sndx_ref = $sd->{ sindex_3 };
	$sl = 3
    }
    my $wrd = q{};
    eval { $wrd = substr ( decode ("utf8", $word), 0, $sl); };

    my $p = undef;

    my $size = scalar ( @{ $sndx_ref } );
    printd "size = '$size'";

    for my $j ( @{ $sndx_ref } ) {

	my ( $wo, $ndx ) = @$j;

	eval { $wo =  decode ("utf8", $wo); };

	if (0) { #$debug) { 
	    my $st = $wo;
	    eval { from_to($st, "utf8", "KOI8-R"); };
	    printd "st = '$st'";
	}

	if ( $wo eq $wrd ) {
	    $p = $ndx;
	    printd "hit p = '$p'";
	    last;
	}

    }

    printd 'zero returning';

    return 0 unless (defined ($p) );

    $sd->{ f_index_pos_cur } = $sd->{ f_index_pos } + $p; 

    my $found = 0;


    printd "word_len '$word_len'";

    my $cw = q{};

    for (my $i = 0; $i < $size; $i++) {

	eval { $cw = decode ( "utf8", $sd->get_next_word ); };

	#my $cwe =  encode ( "utf8", $cw );
	#from_to($cwe, "utf8", "koi8-r"); 
	#printd "ZZ cw '$cwe'";

	if ( $word_d eq substr ( $cw , 0, $word_len ) ) {
	    printd 'match (1)';
	    $found = 1;
	    $sd->get_prev_word;
	    last;
	}
    } 

    return 0 unless ($found);

    $sname =~ s|browse||;
    my $burl = $sname . $ENV{ 'PATH_INFO' } . "?search=search&dicname=$dct&word=";

    $cw = q{};
    my $ii = 0;

    if ( $offset ) {
	for (my $iii = 0; $iii < $offset; $iii++) {
	    $sd->get_next_word;
	}
    }

    for ( $ii=0; $ii < SDICT_LOAD_ITEMS; $ii++ ) {

        eval { $cw = decode ( "utf8", $sd->get_next_word ); };
	printd "cw = '$cw'";

	last if ( substr ( $cw, 0, $word_len ) ne $word_d or $cw eq {}  );

	$cw = encode ( "utf8", $cw );

	my $cwu = $cw;
	utf8_to_url_string (\$cwu);	
	my $href = $burl . $cwu ;

	$href .= "&offset=$offset" if ($offset);

	my $art_full = q{};
	eval { $art_full =  decode ( "utf8", $sd->read_unit ( $sd->{ articles_pos } +
						    $sd->{ cur_word_pos }
						    )
				     ); };

	my $art = substr ( $art_full, 0, SDICT_ARTICLE_LEN );

	my $bigger = (length ($art_full) > length ($art)) ? 1 : 0;

	$art =~ s|<t>| [|;
	$art =~ s|</t>|] |;
	$art =~ s|<.+?>||g;

	$art = encode ( "utf8", $art ) ;

	print "<p> <b><a href=\"$href\">$cw</a></b><br> $art";

	print "<a href=\"$href\">[...]</a>" if ($bigger);

	print '</p>';
    }

    my $nextoffset = $offset + SDICT_LOAD_ITEMS ;
    my $prevoffset = $offset > SDICT_LOAD_ITEMS ? $offset - SDICT_LOAD_ITEMS  : -1;

    my $purl = $sname . $ENV{ 'PATH_INFO' } . "?search=search&dicname=$dct&word=$word&offset=";

    #printd "1>>>$ii<<<"; printd "2>>>$cw<<<"; printd "3>>>$offset<<<"; printd "4>>>$prevoffset<<<";

    if ( $ii >= SDICT_LOAD_ITEMS && $cw ne q{} ) {
	printd "Prev: '$prevoffset'  Next: '$nextoffset'";
	print '<p><strong>';

	if ($offset >= SDICT_LOAD_ITEMS ) {
	    $prevoffset = 0 if $prevoffset < 0; 
	    print "<a href=\"$purl$prevoffset\">[Prev]</a> ";
	}
	print "<a href=\"$purl$nextoffset\">[Next]</a> ";
	print '</strong></p>';
    }
    elsif ($offset && $prevoffset) {
	print "<p><strong><a href=\"$purl$prevoffset\">[Prev]</a></strong></p>";
    }

    return 1;
}


sub print_by_letter {
    printd 'print_by_letter()';

    return unless (check_or_load_dct() );

    my $tit = $sd->{header}->{title};

    my $durl = $sname . $ENV{ 'PATH_INFO' } . "?dicname=$dct";
    print h1 "<a href=\"$durl\">$tit</a>";

    print '<p>';
    my $sletter = $letter;
    utf8_to_url_string (\$sletter);

    my $lurl = $sname . $ENV{ 'PATH_INFO' } . "?dicname=$dct&letter=$sletter";

    my $href = "<a href=\"$lurl\">$letter</a>:";    

    print h1 "$href";

    my $wrd = q{};
    eval { $wrd = substr ( decode ("utf8", $letter), 0, 1 ); };

    my $p = undef;

    my $size = scalar ( @{ $sd->{ sindex_1 } } );
    printd "size = '$size'";

    for my $j ( @{ $sd->{ sindex_1 } } ) {
	my ( $wo, $ndx ) = @$j;
	if ($wo eq $wrd) {
		$p = $ndx;
		printd "hit p = '$p'";
		last;
	    }
    }

    unless (defined ($p) ) {
	printd 'Not found';
	not_found();
	return;
    }
 
    $sd->{ f_index_pos_cur } = $sd->{ f_index_pos } + $p;

    my $burl = $sname . $ENV{ 'PATH_INFO' } . "?dicname=$dct&letter=$letter&word=";

    my $cw = q{};
    my $ii = 0;

    if ( $offset ) {
	for (my $iii = 0; $iii < $offset; $iii++) {
	    $sd->get_next_word;
	}
    }

    for ( $ii=0; $ii < SDICT_LOAD_ITEMS; $ii++ )
    {
        eval { $cw = decode ( "utf8", $sd->get_next_word ); };
	last if ( substr ( $cw, 0, 1 ) ne $wrd or $cw eq {}  );
	eval { $cw = encode ( "utf8", $cw ); };

	printd 'printing item';

	if (0) # $debug
	{
	    my $cwt = $cw;
	    from_to($cwt, "utf8", "KOI8-R");	
	    printd "cwt= '$cwt'"; 
	}

	my $cwu = $cw;
	utf8_to_url_string (\$cwu);	
	my $href = $burl . $cwu ;


	$href .= "&offset=$offset" if ($offset);
	my $art_full = q{};
	eval { $art_full =  decode ( "utf8", $sd->read_unit ( $sd->{ articles_pos } +
						    $sd->{ cur_word_pos }
						    )
				     ); };

	my $art = substr ( $art_full, 0, SDICT_ARTICLE_LEN );

	my $bigger = (length ($art_full) > length ($art)) ? 1 : 0;

	$art =~ s|<t>| [|;
	$art =~ s|</t>|] |;
	$art =~ s|<.+?>||g;

	eval { $art = encode ( "utf8", $art ) ; };

	print "<p> <b><a href=\"$href\">$cw</a></b><br> $art";
	print "<a href=\"$href\">[...]</a>" if ($bigger);
	print '</p>';
    }

    my $nextoffset = $offset + SDICT_LOAD_ITEMS ;
    my $prevoffset = $offset > SDICT_LOAD_ITEMS ? $offset - SDICT_LOAD_ITEMS  : -1;
    my $purl = $sname . $ENV{ 'PATH_INFO' } . "?dicname=$dct&letter=$letter&offset=";

    #printd "1>>>$ii<<<"; printd "2>>>$cw<<<"; printd "3>>>$offset<<<"; printd "4>>>$prevoffset<<<";

    if ( $ii >= SDICT_LOAD_ITEMS && $cw ne q{} ) {
	printd "Prev: '$prevoffset'  Next: '$nextoffset'";
	print '<p><strong>';

	if ($offset >= SDICT_LOAD_ITEMS ) {
	    $prevoffset = 0 if $prevoffset < 0; 
	    print "<a href=\"$purl$prevoffset\">[Prev]</a> ";
	}
	print "<a href=\"$purl$nextoffset\">[Next]</a> ";
	print '</strong></p>';
    }
    elsif ($offset && $prevoffset) {
	print "<p><strong><a href=\"$purl$prevoffset\">[Prev]</a></strong></p>";
    }
}


sub not_found {
    printd 'not_found()';
    print h1 'Not found in dictionary';
}


sub get_avail_dicts {
    printd 'get_avail_dicts()';

    my %DICTS = ();
    my @files = glob ("$dct_path/*.dct");

    unless (@files) {
	printd 'No dictionaries found';
	return %DICTS; 
    } else {
        for my $j (sort @files) {
	    printd "Looking at '$j'";

            $sd->init ( { file => $j } );

            unless ($sd->read_header) {
                printd "Unable to load dictionary from file '$j'";
                next;
            }

	    $j =~ s|.+/||;
	    $DICTS{$j} = $sd->{header}->{title};

	    $sd->unload_dictionary;
	}

	return %DICTS;
    }
}


sub print_form {
    printd 'print_form()';

    my %DICTS = get_avail_dicts();
    
    my @vals = sort (keys %DICTS);

    print $q->startform (-method=>'GET');

    print '<table nowrap border=0><tr><td>';
    print $q->submit('search','Search');
    print "</td><td>";
    print $q->textfield( -name=>'word', -default=>'', -size=>20, -maxlength=>255);
    print '</td><td> in </td><td>';

    print $q->popup_menu( -name=>'dicname', -values=> \@vals, -labels=>\%DICTS );
    print "</td><td>";
    
    print "</td></tr></table></center>\n";
    print $q->endform;

}


sub print_about {
    my $snameb = $sname . '/browse';
    my $snameh = $sname . '/help';
    print <<EOF;
    <p><table width="100%" border=0 nowrap>
        <tr>
            <td align=left><small><a href=$snameb><strong>Dictionary browser</strong></a> </td>
        </tr></table>
EOF
}


sub printd (;@) {
    $debug && eval { no warnings ; print STDERR '"DEBUG: ', @_, "\n"; };
}


sub print_help {
    printd 'print_help()';
    my $snamei = $sname . '/logo';

    print <<EOF;
    <h1>About:</h1>

     <table cellpadding=4 cellspacing=5 border=0>
        <tr>
           <td rowspan=5> <img src="$snamei" alt="logo"> </td>
	   <td><strong>Sdictionary, CGI module, ver. $DIC_VERSION. Written by (c) Alexey Semenoff, 2001-2007.</strong><td>
        </tr>
        <tr> <td><strong>This script is part of the <a href="http://swaj.net/sdict/index.html">Sdictionary project</a>.</td> </tr>
        <tr><td><strong>Distributed under GNU General Public License.</strong><td></tr>
        <tr><td><strong>SysInfo: Perl: $]; Sdict: $Sdict::VERSION.</td></tr>
     </table>
EOF

}


sub print_footer {
    printd 'print_footer()';

    my $snameh = $sname . '/help';

    print hr;
    print <<EOF;
    <p><table width="100%" border=0 nowrap>
        <tr>
            <td align=right><small><i><a href=$snameh>GNU Web Sdictionary</a>. Ver $DIC_VERSION.</i></td>
        </tr></table>
EOF
}


sub log_hit {
    my %month_of_day = qw(Jan 01 Feb 02 Mar 03 Apr 04 May 05 Jun 06
                         Jul 07 Aug 08 Sep 09 Oct 10 Nov 11 Dec 12);

    $_ = localtime ( time ); @_ = split ( /\s+|:/) ;
    $_ = $_[2];
    unless (/\d\d/) { $_ = '0'. $_[2]; }
    my $cdate = "$_[6]/$month_of_day{$_[1]}/$_ $_[3]:$_[4]:$_[5]";

    my $req_uri              = $ENV{'REQUEST_URI'};
    my $remote_addr          = $ENV{'REMOTE_ADDR'};
    my $remote_host          = $ENV{'REMOTE_HOST'};
    my $http_referer         = $ENV{'HTTP_REFERER'};
    my $http_user_agent      = $ENV{'HTTP_USER_AGENT'};
    my $http_via             = $ENV{'HTTP_VIA'};
    my $http_x_forwarded_for = $ENV{'HTTP_X_FORWARDED_FOR'};

    $req_uri =~ s|/cgi-bin||;

    my $s = "$cdate=ñ1ñ=$req_uri=ñ2ñ=$remote_addr=ñ3ñ=$remote_host=ñ4ñ=$http_referer=ñ5ñ=$http_user_agent=ñ6ñ=$http_via=ñ7ñ=$http_x_forwarded_for";

    open (F, ">> $log_file" ) or return;
    flock F, LOCK_EX;
    print F "$s\n";
    flock(F, LOCK_UN);
    close F;
}




#
# __END__
#





__DATA__
‰PNG

   IHDR           szzô   bKGD ÿ ÿ ÿ ½§“   	pHYs    d_‘   tIMEÕ
bşğ  IDATxœÅ×}põğïîŞİŞŞK’#É‘@^hB»´*ˆ‘Ñ)D,âÛt°¾ [°v2yéĞÒiÅq†F†hÕ‚cS†N­èŒâû˜ 	(0‘äòz¹÷»İ½ÛİÛ»ÛÛş£3É&Ğñùs÷ÙçùÌovŸßo8-IÛ?÷ZZ;ûÖ°áÈJA”\‚ ØŒz*A@ıJG'ìfªåì®Õ§H‚Pà¾}UË_=ÿ·Ï?¾è†K›/>ôy_yvVB–dı¥¦úcr*b4KEÊ\JÒf"Ë¨sëHõíü|;ÇñÑu3>ñäî§“Õ×MØüõ§ÅH`¯>%ŒNÆ.î G»^íîú"öMÎıë·V\IlPè™:=³%Æ±Ğ'%Ğ¤ze²æÖ\îõö2dš e65ƒ¿üàáƒ¯´^Ÿ÷qóî ë75µpDÁ{r4Â#—`˜ïÒÒd¦‹ªª"—^Ñ%xÂ¨Æ¡‹ÿãğş—¾ÓüÛqä¥-­…jøA›Í¦Ìš¿ tÆÊÏ|:¼ˆRÓ•òx/,FúTK±7±BÜaahĞ:Mïwf@*¿ÍB“ ’Ì4Ê`T4UPç(n2ë	7­§¦È³ÒÅ&•*)Á^æX©ğ‡Çï•òs¬ÿfhÃôŠ˜õ$Š~TŞ=€‚Ò¹Oız{ãOµ"Ê‹g¶˜LÓÛc¡u 	¥eHK¼>^Í‡Ï4íDKÑ{kgó­Æ“Zr3¾)ûuÑ…"{¶Í‘çdå@bıo÷4<÷»u-¦ €]Z~UR^¹¯ïü—(«r!•R066Š,{$IòEƒÍbĞ}àÅ?nøÿ ş{¥Ÿè<ß»»¢Ê¹ùrO7löBächp²¢Â’[ H²¾¿ÿåÃgo:à›h>ppÓ<§ë¿ß¯÷xáª©EL’16:
sö&ç‚{äàè³O=ñÓ ĞøâËn­Yø†½p¶£³³[Êª\àÙæ”U@MˆCŞá«ëW­XÖ6€¦iÑv¨ÕÃ…Í¹¹¶dµË¹Èjfô—Î~‰Â‚™¨œ[Îï†É Ë©v:Ö®üÙòFG´Ÿé>—¾i  èëíU>8øîqCÿgváÌ¢[o¹ÅÉ…ü¼ŠÚE5 dmï¿…şëÄ‘êú‡}ÿØg“NPm;CìüëÎ»U•{ué„ãØá˜%¹iPF–ÔT`Ğ'09~±¦®nÉ„+¡y®ööö¡ÑÑ‘ú{¿0ÖVÒµås²‰ùb,«sàÔ¹a¸Êó«;;z?:Ösf¢:Ó^oÇMËëk
Ş‰FcV¤U˜=œîÃŒ«ÿÄ¸½dWc£ü}ÏfŞÇ[u¼vVÀš-{u]SW(2r¢"â’RvDú–MôlF€ôÜéß¨  <ù—ËCìö“C>HÀíe¡Kp•Sœ€8ÏİõÜŸ·Y¦‚È©¨k„DV–d¤I»CéÜ)8V€*Kf+{ñçS,®_-‹Bü´,Æqu4*­ =S°\á0Z‘şÔğÛuÚN_‡ÉÃˆ‡Ç‹$Lî™¬€PˆGZŠÍeüvjm>Ø¶O	±5cD1+_ú åè©©¸İ}>€n^·Ô¹UàtË»›ÇÜ¡¢Aw‰4ëV‚˜øKÏ8ˆ–/¨Z8<0°bĞÇCI$Èâ=?)É«¾ãÇs»ÎŒ³×ç÷µ¾NÏ§ÃÛ®ïô‡£DL”S1½mÓ''Ï¿9:#¯é75\è<şwA¡Â$IøL”:OU’¤Bè‹ÕzÔbaHµ/;ËjK+)§,ÇEø"^•q‘ÉÛĞŞİûŞdÍïù3ÊeäÚ¬ıc(½½íØqnı“kòMŞûe.´LâKy–­§õ0T¨
…º&Æı(uìio=tcÇµ3»WÛ^Xåš™é^€cÉµ­*¹³ˆ©zÌ™Sµt¹ªnám%²šÖXÿ'M»F÷•”F    IEND®B`‚
