package Pod::RTF;

sub import {}

use Pod::Simplify;

$type   ='{\uldb ';
$head   = '\b\f1\fs28 ';
$head1  = '\b\f1\fs28 ';
$head2  = '\b\i\f1\fs24 ';
$indent = '\li360\widctlpar';
$bullet = '\par{\f3\\\'B7}\tab';


sub findindex {
	my(@a) = @_;
	shift @a;
	my(@look) = map(join("/",@$_),@a);
	my($match)=0;
	foreach(@look) {
		if($match = $idx{$_}) {
			last;
		}
	}
	$match;
}

sub flowed {
	my($out);
	foreach $i (@_) {
		if(ref $i eq "ARRAY") {
			my(@i) = (@$i);
			my($c) = shift @i;
			if($c eq "B" or $c eq "I") { # Bold/italic
				$out .= "<$c>" . flowed(@i) . "</$c>";
			}
			elsif($c eq "V") { # Variable
				$out .= "``<CODE>{v}". flowed(@i) . "</CODE>''";
			}
			elsif($c eq "P") { # Procedure
				$out .= "<I>{p}". flowed(@i) . "</I>";
			}
			elsif($c eq "F") { # Filename
				$out .= "<EM>{f}". flowed(@i) . "</EM>";
			}
			elsif($c eq "S") { # Switch
				$out .= "<B>{s}". flowed(@i) . "</B>";
			}
			elsif($c eq "C") { # Code
				$out .= "<CODE>". flowed(@i) . "</CODE>";
			}
			elsif($c eq "R") { # Reference
				my($id) = findindex(@i);
				$out .= '<A HREF="' if $id;
				$out .= $id->[2] if $id and $id->[2] ne "foo";
				$out .= '#'.$id->[0].'">' if $id;
				$out .= "{r}". flowed(@{$i[0]});
				$out .= "</A>" if $id;
#				$out .= "{R:".Pod::Simplify::dumpout([@i])."} ";
			}
			elsif($c eq "X") { # Index
				my($id) = findindex(@i);
				$out .= '<A NAME="'.$id->[0].'">'.flowed(@{$i[0]})."</A>";
#				$out .= "{X:".Pod::Simplify::dumpout([@i])."} ";
			} 
			elsif($c eq "E") { # Escape
				$out .= '&'.$i[0].';';
			}
			else {
				$out .= "{$c".":". flowed(@i) ."}"; 
			}
		} else {
			while(@waitingindex and length($i)) {
				my($c) = substr($i,0,1);
				$c =~ s/([<>&])/ '&'.$Pod::Simplify::ASCII2Escape{$1}.';' /ge;
				$out .= '<A NAME="'.(shift @waitingindex).'">'.$c.'</A>';
				substr($i,0,1)="";
			}
			$i =~ s/([<>&])/ '&'.$Pod::Simplify::ASCII2Escape{$1}.';' /ge;
			$out .= $i;
		}
	}
	$out;
}

@listtype=();

$idx=0;

sub doindex {
	foreach (@_) {
		if(ref $_ eq "ARRAY") {
			my(@i) = @$_;
			my($i) = shift @i;
			if( $i eq "X") {
				shift @i; # discard printable block
				$idx++;
				$name = join("/",@{$i[0]});
				$name =~ s/([^A-Za-z0-9_])/ "%".sprintf("%.2X",ord($1)) /ge;
				foreach (@i) {
					$idx{join("/",@$_)} = [$name,$idx,"perlvar.pod"];
				}
				#print "Index: ",Pod::Simplify::dumpout([@i]),"\n";
			} else {
				doindex(@i);
			}
		}
	}
}

sub dump1 {
	my($par,$line,$pos,$cmd,$var1,$var2) = @_;
	
	# Save the parsed data for later processing
	push(@results,@_);
	
	if( $cmd =~ /^(item|head|flow|index)$/) {
		doindex(@$var2);
	}
}

sub Format {
	my($par,$line,$pos,$cmd,$var1,$var2) = @_;
	
	#print "cmd = $cmd\n";
	
	if( $cmd eq "begin" ) {
		if($var1 eq "list") {
			if($var2 eq "bullet") {
				#                                    
				#print "<UL><!-- begin bulleted list -->\n";
			}
			elsif($var2 eq "number") {
				print "<OL><!-- begin numbered list -->\n";
			} else {
				print "<DL><!-- begin glossary list -->\n";
			}
			unshift(@listtype,$var2);
		}
		elsif($var1 eq "pod") {
			print <<'RTFEOQ';
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
RTFEOQ
			print $var2->[0],'\pard}';
					
			#print "<HTML><HEAD>\n".
			#	  "<CENTER><TITLE>".$var2->[0]."</TITLE></CENTER>\n".
			#	  "</HEAD><BODY>\n";
		}
	}
	elsif( $cmd eq "end" ) {
		if($var1 eq "list") {
			print "\n\\pard\\page \n";
			#if($var2 eq "bullet") {
			#	print "</UL><!-- end bulleted list -->\n";
			#}
			#elsif($var2 eq "number") {
			#	print "</OL><!-- end numbered list -->\n";
			#} else {
			#	print "</DL><!-- end glossary list -->\n";
			#}
			#shift(@listtype);
		}
		elsif($var1 eq "pod") {
			print "</BODY>\n";
		}
	}
	elsif( $cmd eq "item") {
#		print "v=".Pod::Simplify::dumpout($var2)."\n";
		if($var1->[0] eq "bullet") {
			print "\n{\\li0\\b ";
			print flowed(@$var2);
			#print "$title";
			print '}\par ';
			print "{$indent }";
		} else {
	        print "{\\f3\\\'B7}\\tab";
			print flowed(@$var2),"\n";
		}
		print "\n";
	}
	elsif( $cmd eq "head") {
		if($var == 1) {
	        print "\\par {$head1";
        } elsif ($var == 2) {
            print "\\par {$head2";
        } else {
            print "\\par {$head";
        }
        print flowed(@$var2);
        print '}\par';
		#print "<HR><H$var1>", flowed(@$var2), "</H$var1>\n";
	}
	elsif( $cmd eq "verb") {
		print "<PRE>\n";
		$var1 =~ s/^/        /gm;
		while(@waitingindex and length($var1)) {
			my($c) = substr($var1,0,1);
			$c =~ s/([<>&])/ '&'.$Pod::Simplify::ASCII2Escape{$1}.';' /ge;
			print '<A NAME="'.(shift @waitingindex).'">'.$c.'</A>';
			substr($var1,0,1)="";
		}
		$var1 =~ s/([<>&])/ "&".$Pod::Simplify::ASCII2Escape{$1}.";" /ge;
		#$var1 =~ s/([<>])/$1$1/g;
		print $var1;
		print "\n</PRE>\n\n";
	}
	elsif( $cmd eq "flow") {
		$f = Pod::Simplify::wrap(flowed(@$var2),75);
		print $f, "<P>\n\n";
	}
	elsif( $cmd eq "comment" ) {
		$var1 =~ s/--/- -/g;
		$var1 =~ s/</lt/g;
		$var1 =~ s/>/gt/g;
		print "<!--\n${var1}-->\n";
	}
	elsif( $cmd eq "index") {
		push(@waitingindex,map(join("/",@$_),@{$var2->[0]}));
	}
}

sub FormatFile {
	my($file) = @_;
	my($x) = new Pod::Simplify;
	$x->parse_from_file_by_name($file,\&Format);
}

#$x->parse_from_file_by_name("newvar.pod",\&dump1);
#$x->parse_from_file_by_name($ARGV[0] || "newfunc.pod",\&dump2);

#write index
#foreach (sort keys %idx) {
#	print join(" ",$_,@{$idx{$_}}),"\n";
#}

#dump2(@_) while(@_=splice(@results,0,6));

1;