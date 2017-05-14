
#/usr/local/bin/perl
# pod2rtf - convert pod format to rtf (for Winhelp compiler HC)
#
# given to the public domain 1996 by Reini Urban,
#   <rurban@xarch.tu-graz.ac.at>
#
# usage: pod2rtf [podfiles]
# will read the cwd and parse all files with .pod extension
# if no arguments are given on the command line.
# derived from Larry Wall's pod2html.pl
#
# Translation:
# Bold     {\b text}
# Italic   {\i text}
# Code     {\f2 text}
# =back    \page
# PopupLink-To  {\ul link-text}{\v link-key}
# Link-To  {\uldb link-text}{\v link-key}
# Link-Def {\super #}{\footnote link-key}
#          {\super $}{\footnote link-title}
#          {\super K}{\footnote link-search}
# =item
#---------------------------------------------------------------
BEGIN {
# thats for my ntperl only
#    push @INC, qw( \\reini\public\dosapp\perl\dll-src\ext \\reini\public\dosapp\perl\lib \\reini\p
ublic\dosapp\perl\ext );

%HTML_Escapes = (
    'amp'       =>      '&',    #   ampersand
    'lt'        =>      '<',    #   left chevron, less-than
    'gt'        =>      '>',    #   right chevron, greater-than
    'quot'      =>      '"',    #   double quote

    "Aacute"    =>      "\\\'e7",       #   capital A, acute accent
    "aacute"    =>      "\\\'87",       #   small a, acute accent
    "Acirc"     =>      "\\\'e5",       #   capital A, circumflex accent
    "acirc"     =>      "\\\'89",       #   small a, circumflex accent
    "AElig"     =>      '\\\'ae',       #   capital AE diphthong (ligature)
    "aelig"     =>      '\\\'be',       #   small ae diphthong (ligature)
    "Agrave"    =>      "\\\'cb",       #   capital A, grave accent
    "agrave"    =>      "\\\'88",       #   small a, grave accent
    "Aring"     =>      '\\\'81',       #   capital A, ring
    "aring"     =>      '\\\'8c',       #   small a, ring
    "Atilde"    =>      '\\\'cc',       #   capital A, tilde
    "atilde"    =>      '\\\'8b',       #   small a, tilde
    "Auml"      =>      '\\\'80',       #   capital A, dieresis or umlaut mark
    "auml"      =>      '\\\'8a',       #   small a, dieresis or umlaut mark
    "Ccedil"    =>      '\\\'82',       #   capital C, cedilla
    "ccedil"    =>      '\\\'8d',       #   small c, cedilla
    "Eacute"    =>      "\\\'83",       #   capital E, acute accent
    "eacute"    =>      "\\\'8e",       #   small e, acute accent
    "Ecirc"     =>      "\\\'e6",       #   capital E, circumflex accent
    "ecirc"     =>      "\\\'90",       #   small e, circumflex accent
    "Egrave"    =>      "\\\'e9",       #   capital E, grave accent
    "egrave"    =>      "\\\'8f",       #   small e, grave accent
    "Euml"      =>      "\\\'e8",       #   capital E, dieresis or umlaut mark
    "euml"      =>      "\\\'91",       #   small e, dieresis or umlaut mark
    "Iacute"    =>      "\\\'ea",       #   capital I, acute accent
    "iacute"    =>      "\\\'92",       #   small i, acute accent
    "Icirc"     =>      "\\\'eb",       #   capital I, circumflex accent
    "icirc"     =>      "\\\'90",       #   small i, circumflex accent
    "Igrave"    =>      "\\\'e9",       #   capital I, grave accent
    "igrave"    =>      "\\\'93",       #   small i, grave accent
    "Iuml"      =>      "\\\'ec",       #   capital I, dieresis or umlaut mark
    "iuml"      =>      "\\\'95",       #   small i, dieresis or umlaut mark
    "Ntilde"    =>      '\\\'84',       #   capital N, tilde
    "ntilde"    =>      '\\\'96',       #   small n, tilde
    "Oacute"    =>      "\\\'ee",       #   capital O, acute accent
    "oacute"    =>      "\\\'97",       #   small o, acute accent
    "Ocirc"     =>      "\\\'ef",       #   capital O, circumflex accent
    "ocirc"     =>      "\\\'99",       #   small o, circumflex accent
    "Ograve"    =>      "\\\'f1",       #   capital O, grave accent
    "ograve"    =>      "\\\'98",       #   small o, grave accent
    "Oslash"    =>      "\\\'af",       #   capital O, slash
    "oslash"    =>      "\\\'bf",       #   small o, slash
    "Otilde"    =>      "\\\'cd",       #   capital O, tilde
    "otilde"    =>      "\\\'9b",       #   small o, tilde
    "Ouml"      =>      "\\\'85",       #   capital O, dieresis or umlaut mark
    "ouml"      =>      "\\\'9a",       #   small o, dieresis or umlaut mark
    "Uacute"    =>      "\\\'f2",       #   capital U, acute accent
    "uacute"    =>      "\\\'9c",       #   small u, acute accent
    "Ucirc"     =>      "\\\'f3",       #   capital U, circumflex accent
    "ucirc"     =>      "\\\'9e",       #   small u, circumflex accent
    "Ugrave"    =>      "\\\'f4",       #   capital U, grave accent
    "ugrave"    =>      "\\\'9d",       #   small u, grave accent
    "Uuml"      =>      "\\\'86",       #   capital U, dieresis or umlaut mark
    "uuml"      =>      "\\\'9f",       #   small u, dieresis or umlaut mark
    "yuml"      =>      "\\\'d8",       #   small y, dieresis or umlaut mark
);
}

*RS = */;
*ERRNO = *!;

use Carp;

$gensym = 0;

while ($ARGV[0] =~ /^-d(.*)/) {
    shift;
    $Debug{ lc($1 || shift) }++;
}

# look in these pods for things not found within the current pod
@inclusions = qw[
     perlfunc perlvar perlrun perlop
];

# ck for podnames on command line
while ($ARGV[0]) {
    push(@Pods,shift);
}
$A={};

# location of pods
$dir=".";
$debug = 0;

# rtf tokens
$type   ='{\uldb ';
$head   = '\b\f1\fs28 ';
$head1  = '\b\f1\fs28 ';
$head2  = '\b\i\f1\fs24 ';
$indent = '\li360\widctlpar';
$bullet = '\par{\f3\\\'B7}\tab';

unless(@Pods){
    opendir(DIR,$dir)  or  die "Can't opendir $dir: $ERRNO";
    @Pods = grep(/\.pod$/,readdir(DIR));
    closedir(DIR) or die "Can't closedir $dir: $ERRNO";
}
@Pods or die "expected pods";

# loop twice through the pods, first to learn the links, then to produce rtf
for $count (0,1){
    (print "Scanning pods...\n") unless $count;
    foreach $podfh ( @Pods ) {
        ($pod = $podfh) =~ s/\.pod$//;
        Debug("files", "opening 2 $podfh" );
        (print "Creating $pod.rtf from $podfh\n") if $count;
        $RS = "\n=";
        open($podfh,"<".$podfh)  || die "can't open $podfh: $ERRNO";
        @all=<$podfh>;
        close($podfh);
        $RS = "\n";
        $all[0]=~s/^=//;
        for(@all){s/=$//;}
        $Podnames{$pod} = 1;
        $in_list=0;
        $rtf=$pod.".rtf";
        if($count){
            for(@all){
                s/\\/\\\\/gm;
                s/{/\\{/gm;
                s/}/\\}/gm;
                }
            open(RTF,">$rtf") || die "can't create $rtf: $ERRNO";
#             <!-- \$RCSfile\$\$Revision\$\$Date\$ -->
#             <!-- \$Log\$ -->
            print RTF <<'RTF__EOQ';
{\rtf1\ansi \deff0\deflang1024

{\fonttbl
{\f0\froman Times New Roman;}
{\f1\fswiss Arial;}
{\f2\fmodern Courier New;}
{\f3\froman Symbol;}
}
{\colortbl;
\red0\green0\blue0;
\red0\green0\blue255;
\red0\green255\blue0;
\red255\green0\blue0;
\red255\green255\blue255;}
{\info{\author Reini Urban}}
\pard\plain {\b\f1\fs28\li120\sb340\sa120\sl-320
RTF__EOQ
            print RTF def_name($pod,$pod);
            print RTF '\pard}';
        }

        for($i=0;$i<=$#all;$i++){

            $all[$i] =~ /^(\w+)\s*(.*)\n?([^\0]*)$/ ;
            ($cmd, $title, $rest) = ($1,$2,$3);
            if ($cmd eq "item") {
                if($count ){
                    ($depth) or do_list("over",$all[$i],\$in_list,\$depth);
                    do_item($title,$rest,$in_list);
                }
                else{
                    # scan item
                    scan_thing("item",$title,$pod);
                }
            }
            elsif ($cmd =~ /^head([12])/){
                $num=$1;
                if($count){
                    do_hdr($num,$title,$rest,$depth);
                }
                else{
                    # header scan
                    scan_thing($cmd,$title,$pod); # skip head1
                }
            }
            elsif ($cmd =~ /^over/) {
                $count and $depth and do_list("over",$all[$i+1],\$in_list,\$depth);
            }
            elsif ($cmd =~ /^back/) {
                if($count){
                    ($depth) or next; # just skip it
                    do_list("back",$all[$i+1],\$in_list,\$depth);
                    do_rest("$title.$rest");
                }
            }
            elsif ($cmd =~ /^cut/) {
                next;
            }
            elsif($Debug){
                (warn "unrecognized header: $cmd") if $Debug;
            }
        }
        # close open lists without '=back' stmts
        if($count){
            while($depth){
                 do_list("back",$all[$i+1],\$in_list,\$depth);
            }
            print RTF "\n} \n";
        }
    }
    # print "execute HC to compile to WinHelp\n";
}

sub do_list{
    my($which,$next_one,$list_type,$depth)=@_;
    my($key);
    if($which eq "over"){
        ($next_one =~ /^item\s+(.*)/ ) or (warn "Bad list, $1\n") if $Debug;
        $key=$1;
        if($key =~ /^1\.?/){
        $$list_type = "OL";
        }
        elsif($key =~ /\*\s*$/){
        $$list_type="UL";
        }
        elsif($key =~ /\*?\s*\w/){
        $$list_type="DL";
        }
        else{
        (warn "unknown list type for item $key") if $Debug;
        }
#        print RTF '\par ';
#        print RTF '{\li284\widctlpar ';
#        print RTF qq{<$$list_type>};
        $$depth++;
    }
    elsif($which eq "back"){
        print RTF "\n\\pard\\page \n";    #qq{\par</$$list_type>\n};
        $$depth--;
    }
}

sub do_hdr{
    my($num,$title,$rest,$depth)=@_;
    ($num == 1) and print RTF '\par\sln ';
    # def_link($title,"");
    process_thing(\$title,"NAME");
    if ($num==1) {
        print RTF "\\par {$head1";
    } elsif ($num == 2) {
        print RTF "\\par {$head2";
    } else {
        print RTF "\\par {$head";
    }
    print RTF $title;
    print RTF '}\par';
    do_rest($rest);
}

sub do_item{
    my($title,$rest,$list_type)=@_;
    process_thing(\$title,"NAME");
    if($list_type eq "DL"){
         print RTF "\n{\\li0\\b ";
         print RTF "$title";
         print RTF '}\par ';
         print RTF "{$indent ";
    }
    else{
        print RTF "{\\f3\\\'B7}\\tab";
        ($list_type ne "OL") && (print RTF $title,"\n");
    }
    do_rest($rest) if $rest ne "\n";
    print RTF ($list_type eq "DL" )? "}\n" : "\n";
}

sub do_rest{
    my($rest)=@_;
    my(@lines,$p,$q,$line,,@paras,$inpre);
    @paras=split(/\n\n+/,$rest);
    for($p=0;$p<=$#paras;$p++){
        @lines=split(/\n/,$paras[$p]);
        if($lines[0] =~ /^\s+\w*\t.*/){  # listing or unordered list
            print RTF "{$indent ";
            foreach $line (@lines){
                ($line =~ /^\s+(\w*)\t(.*)/) && (($key,$rem) = ($1,$2));
                print RTF defined($Podnames{$key}) ?
                    "$bullet {\\uldb $key}{\\v $key}\\tab $rem\n" :
                    "$bullet $line\n";
            }
            print RTF "}\n\\par";
        }
        elsif($lines[0] =~ /^\s/){       # preformatted code
            if($paras[$p] =~/>>|<</){
                print RTF "{\\f2 ";
                $inpre=1;
            }
            else{
                print RTF "{\\f2 ";
                $inpre=0;
            }
inner:
            while(defined($paras[$p])){
                @lines=split(/\n/,$paras[$p]);
                foreach $q (@lines){
                    if($paras[$p]=~/>>|<</){
                        if($inpre){
                            process_thing(\$q,"RTF");
                        }
                        else {
                            print RTF "\n}";
                            print RTF '\par{\f2 ';
                            $inpre=1;
                            process_thing(\$q,"RTF");
                        }
                    }
                    while($q =~  s/\t+/' 'x (length($&) * 8 - length($`) % 8)/e){
                        1;
                    }
                    print RTF  $q,"\n\\par ";
                }
                last if $paras[$p+1] !~ /^\s/;
                $p++;
            }
            print RTF ($inpre==1) ? "\n} " : "\n} ";
        }
        else{                             # other text
            @lines=split(/\n/,$paras[$p]);
            foreach $line (@lines){
                process_thing(\$line,"RTF");
                print RTF "$line\n\\par ";
            }
        }
        print RTF '\par ';
    }
}

sub process_thing{
    my($thing,$htype)=@_;
    pre_escapes($thing);
    find_refs($thing,$htype);
    post_escapes($thing);
}

sub scan_thing{
    my($cmd,$title,$pod)=@_;
    $_=$title;
    s/\n$//;
    s/E<(.*?)>/isokey($1)/eg;
    # remove any formatting information for the headers
    s/[SFCBI]<(.*?)>/$1/g;
    # the "don't format me" thing
    s/Z<>//g;
    if ($cmd eq "item") {

        if (/^\*/)      {  return }     # skip bullets
        if (/^\d+\./)   {  return }     # skip numbers
        s/(-[a-z]).*/$1/i;
        trim($_);
        return if defined $A->{$pod}->{"Items"}->{$_};
        $A->{$pod}->{"Items"}->{$_} = gensym($pod, $_);
        $A->{$pod}->{"Items"}->{(split(' ',$_))[0]}=$A->{$pod}->{"Items"}->{$_};
        Debug("items", "item $_");
        if (!/^-\w$/ && /([%\$\@\w]+)/ && $1 ne $_
            && !defined($A->{$pod}->{"Items"}->{$_}) && ($_ ne $1))
        {
            $A->{$pod}->{"Items"}->{$1} = $A->{$pod}->{"Items"}->{$_};
            Debug("items", "item $1 REF TO $_");
        }
        if ( m{^(tr|y|s|m|q[qwx])/.*[^/]} ) {
            my $pf = $1 . '//';
            $pf .= "/" if $1 eq "tr" || $1 eq "y" || $1 eq "s";
            if ($pf ne $_) {
                $A->{$pod}->{"Items"}->{$pf} = $A->{$pod}->{"Items"}->{$_};
                Debug("items", "item $pf REF TO $_");
            }
        }
    }
    elsif ($cmd =~ /^head[12]/){
        return if defined($Headers{$_});
        $A->{$pod}->{"Headers"}->{$_} = gensym($pod, $_);
        Debug("headers", "header $_");
    }
    else {
        (warn "unrecognized header: $cmd") if $Debug;
    }
}

sub def_name {
    my ($value, $bigkey) = @_;
    $bigkey = $value if $bigkey eq "";
    return "\n{\\super \#{\\footnote \# $value}}\n".
                "{\\super \${\\footnote \$ $bigkey}}\n".
                "{\\super K{\\footnote K $bigkey}}\n".
                " $bigkey\n";
}
sub def_link {
    my ($value, $bigkey) = @_;
    return "\n{\\uldb $bigkey}{\\v $value}";
}

sub picrefs {
    my($char, $bigkey, $lilkey,$htype) = @_;
    my ($key,$ref,$podname);
    for $podname ($pod,@inclusions){
        for $ref ( "Items", "Headers" ) {
            if (defined $A->{$podname}->{$ref}->{$bigkey}) {
                $value = $A->{$podname}->{$ref}->{$key=$bigkey};
                Debug("subs", "bigkey is $bigkey, value is $value\n");
            }
            elsif (defined $A->{$podname}->{$ref}->{$lilkey}) {
                $value = $A->{$podname}->{$ref}->{$key=$lilkey};
                return "" if $lilkey eq '';
                Debug("subs", "lilkey is $lilkey, value is $value\n");
            }
        }
        if (length($key)) {
            ($pod2,$num) = split(/_/,$value,2);
            if($htype eq "NAME"){
                return def_name($value, $bigkey);
            } else{
                return def_link($value, $bigkey);
            }
        }
    }
    if ($char =~ /[IF]/) {
        return "{\\i $bigkey} ";
    } elsif($char =~ /C/) {
        return "{\\f2 $bigkey} ";
    } else {
        return "{\\b $bigkey} ";
    }
}

sub find_refs {
    my($thing,$htype)=@_;
    my($orig) = $$thing;
    # LREF: a manpage(3f) we don't know about
    $$thing=~s:L<([a-zA-Z][^\s\/]+)(\([^\)]+\))>:the I<$1>$2 section:g;
    $$thing=~s/L<([^>]*)>/lrefs($1,$htype)/ge;
    $$thing=~s/([CIBF])<(\W*?(-?\w*).*?)>/picrefs($1, $2, $3, $htype)/ge;
    $$thing=~s/((\w+)\(\))/picrefs("I", $1, $2,$htype)/ge;
    $$thing=~s/([\$\@%](?!&[gl]t)([\w:]+|\W\b))/varrefs($1,$htype)/ge;
    (($$thing eq $orig) && ($htype eq "NAME")) &&
        ($$thing=picrefs("I", $$thing, "", $htype));
}

sub lrefs {
    my($page, $item) = split(m#/#, $_[0], 2);
    my($htype)=$_[1];
    my($podname);
    my($section) = $page =~ /\((.*)\)/;
    my $selfref;
    if ($page =~ /^[A-Z]/ && $item) {
        $selfref++;
        $item = "$page/$item";
        $page = $pod;
    }  elsif (!$item && $page =~ /[^a-z\-]/ && $page !~ /^\$.$/) {
        $selfref++;
        $item = $page;
        $page = $pod;
    }
    $item =~ s/\(\)$//;
    if (!$item) {
        if (!defined $section && defined $Podnames{$page}) {
            return "\n\\par {\\uldb the {\\i $page} manpage}{\\v $page}\n";
        } else {
            (warn "Bizarre entry $page/$item") if $Debug;
            return "the {\\i $_[0]}  manpage\n";
        }
    }

    if ($item =~ s/"(.*)"/$1/ || ($item =~ /[^\w\/\-]/ && $item !~ /^\$.$/)) {
        $text = "{\\i $item} ";
        $ref = "Headers";
    } else {
        $text = "{\\i $item} ";
        $ref = "Items";
    }
    for $podname ($pod, @inclusions){
        undef $value;
        if ($ref eq "Items") {
            if (defined($value = $A->{$podname}->{$ref}->{$item})) {
                ($pod2,$num) = split(/_/,$value,2);
                return (($pod eq $pod2) && ($htype eq "NAME"))
                ? def_name($value, $bigkey)
                : def_link($value, $bigkey);
            }
        }
        elsif($ref eq "Headers") {
            if (defined($value = $A->{$podname}->{$ref}->{$item})) {
                ($pod2,$num) = split(/_/,$value,2);
                return (($pod eq $pod2) && ($htype eq "NAME"))
                ? def_name($value, $text)
                : def_link($value, $text);
            }
        }
    }
    (warn "No $ref reference for $item (@_)") if $Debug;
    return $text;
}

sub varrefs {
    my ($var,$htype) = @_;
    for $podname ($pod,@inclusions){
        if ($value = $A->{$podname}->{"Items"}->{$var}) {
            ($pod2,$num) = split(/_/,$value,2);
            Debug("vars", "way cool -- var ref on $var");
            return (($pod eq $pod2) && ($htype eq "NAME"))  # INHERIT $_, $pod
                ? def_name($value, $text)
                : def_link($value, $text);
        }
    }
    Debug( "vars", "bummer, $var not a var");
    return "{\\b $var} ";
}

# convert illegal names
sub gensym {
    my($podname, $key) = @_;
    $key =~ s/\s.*/_/;         # trim whitespace
    $key =~ s/\$/VAR_/;        # $ARG -> VAR_ARG
    $key =~ s/\@/LIST_/;       # @ARG -> LIST_ARG
    ($key = lc($key)) =~ tr/a-z/_/cs;
    my $name = "${podname}_${key}_0";
    # $name =~ s/__/_/g;
    while ($sawsym{$name}++) {
        $name =~ s/_?(\d+)$/'_' . ($1 + 1)/e;
    }
    return $name;
}

sub pre_escapes {
    my($thing)=@_;
    $$thing=~s/(?:[^ESIBLCF])</noremap("<")/eg;
    $$thing=~s/E<([^\/][^<>]*)>/isokey($1)/eg;              # embedded special
}

sub isokey {
    $char = $_[0];
    exists $HTML_Escapes{$char}
        ? $char = $HTML_Escapes{$char}
        : $char =~ s/([0-9A-F][0-9A-F])/\\\'$1 /;
    $char;
}

sub noremap {
    my $hide = $_[0];
    $hide =~ tr/\000-\177/\200-\377/;
    $hide;
}

sub post_escapes {
    my($thing)=@_;
#    $$thing=~s/[^GM]>>/\&gt\;\&gt\;/g;
#    $$thing=~s/([^"MGAE])>/$1>/g;
    $$thing=~tr/\200-\377/\000-\177/;
}

sub Debug {
    my $level = shift;
    print STDERR @_,"\n" if $Debug{$level};
}

sub dumptable  {
    my $t = shift;
    print STDERR "TABLE DUMP $t\n";
    foreach $k (sort keys %$t) {
        printf STDERR "%-20s <%s>\n", $t->{$k}, $k;
    }
}
sub trim {
    for (@_) {
        s/^\s+//;
        s/\s\n?$//;
    }
}
