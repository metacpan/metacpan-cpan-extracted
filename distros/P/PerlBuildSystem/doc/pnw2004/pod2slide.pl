
#!/usr/local/bin/perl -w

# pod2slide.pl (C) 2004, 2007
#Hereby release to the public domain by Nadim Ibn Hamouda El Khmir.

use strict ;
use warnings ;
use Digest::MD5 qw(md5_hex) ;
use Pod::Html;
use File::Slurp ;

my $in_slide = 0 ;
my $undone_flag = '' ; # use '' and '*' for 0 and 1.

my $slide_index = 0 ; # should use the first header name
my @slides ;

my $title = "PBS: A build tool for complex systems" ;
my $copyright = "2004 - Nadim Khemir and Anders Lindgren" ;
my $out_dir = "slides/" ;

my $regenerated_slides = 0 ;

mkdir($out_dir) ;

while(<>)
	{
	if(/^=slide\s*(.*?)\s*$/)
		{
		close(SLIDE_POD) ;
		
		if(@slides)
			{
			$slides[-1][2] = $undone_flag ;
			}
			
		$undone_flag = '' ;
		$in_slide = 1 ;
		$slide_index++ ;
		
		my $slide_file = $1 ;
		$slide_file =~ s/-+$// ;
		
		$slide_file = $slide_file ne '' ? $slide_file : $slide_index ;
		
		my $unmodified_slide_name = $slide_file ;
		
		$slide_file =~ s/[^a-z_A-Z0-9]+/_/g ;
		$slide_file = sprintf("%03d_${slide_file}_slide", $slide_index) ;
		
		#~ print "Generating '$unmodified_slide_name'  => '$slide_file.pod'\n" ;
		
		open SLIDE_POD, ">", "$out_dir$slide_file.pod" or die "can't open '$out_dir$slide_file.pod': $!" ;
		print SLIDE_POD "=begin html\n\n<div class=pod>\n\n=end html\n\n" ;
		push @slides, [$slide_file, $unmodified_slide_name, ''] ;
		next ;
		}
		
	if(/^=slide_end/ || /^=end_slide/ || /^=slide_cut/ || /^=cut_slide/)
		{
		$in_slide = 0 ;
		close(SLIDE_POD) ;
		}
		
	$undone_flag = '*' if(/^=for undone_slide/ && $in_slide) ;
	
	print SLIDE_POD $_ if($in_slide) ;
	}
	
close(SLIDE_POD) ;

my $index_text = '' ;
my $number_of_undone_slides = 0 ;
my $number_of_slides = @slides ;

for(my $slide_index = 0 ;  $slide_index < $number_of_slides ; $slide_index++)
	{
	my $previous = $slides[$slide_index - 1][0] ;
	my ($slide_file, $unmodified_slide_name, $undone_flag) = @{$slides[$slide_index]} ;
	$number_of_undone_slides ++ if $undone_flag eq '*' ;
	
	my $next ;
	
	if($slide_index == $number_of_slides - 1)
		{
		$next = 'index_slide' ;
		}
	else
		{
		$next = $slides[$slide_index + 1][0] ;
		}
		
	my $head_arrows_html = <<EOA ;

=begin html
<br>
<table width=100%>
<tr>
<td align="right" width=33%>
  <a href='${previous}.html'>&lt;&lt;</a>&nbsp
 <a href='index_slide.html'>^</a>&nbsp
 <a href='${next}.html'>&gt;&gt;</a>
 [@{[$slide_index+1]}/$number_of_slides]
</td>
</tr>
</table>
<div class="">

=end html

EOA

	my $arrows_html = <<EOA ;

=begin html

<br>
<div class="path">
<table width=100%>
<tr>
<td width=33%>$title [@{[$slide_index+1]}/$number_of_slides]</a></td>
<td width=33% align=center>
 <a href='${previous}.html'>&lt;&lt;</a>&nbsp
 <a href='index_slide.html'>^</a>&nbsp
 <a href='${next}.html'>&gt;&gt;</a>
</td>
<td align="right" width=33%>Copyright &copy; $copyright</td>
</tr>
</table>
<div class="">

=end html

EOA


	my $pod = read_file("$out_dir$slide_file.pod") ;
	write_file("$out_dir$slide_file.pod", $pod, $arrows_html) ;

	my $md5 = 'error' ;
	if(open(FILE, "$out_dir$slide_file.pod"))
		{
		binmode(FILE);
		
		$md5 = Digest::MD5->new->addfile(*FILE)->hexdigest ;
		close(FILE) ;
		}
		
	my $previous_md5 = "doesn't exist" ;
	
	if(open(FILE, "$out_dir$slide_file.md5"))
		{
		$previous_md5 = <FILE> ;
		}
		
	if($md5 ne $previous_md5)
		{
		$regenerated_slides++ ;
		
		print "Generating slide @{[$slide_index + 1]}: '$unmodified_slide_name' $undone_flag.\n" ;
		
		pod2html
			(
			  "--infile=$out_dir$slide_file.pod"
			, "--outfile=$out_dir$slide_file.html"
			, "--css"
			, "perl_style.css"
			, "--noindex"
			) ;
			
		open(FILE, ">", "$out_dir$slide_file.md5") or die "can't open '$out_dir$slide_file.md5': $!" ;
		print FILE $md5 ;
		close FILE ;
		}
	else
		{
		print "Undone flag set for: '$unmodified_slide_name'.\n" if $undone_flag eq '*' ;
		}
		
	#~ unlink("$out_dir$slide_file.pod") ;
	
	# Arfff!
	{
	open(FILE, "+<", "$out_dir$slide_file.html") or die "can't open '$out_dir$slide_file.html: $!" ;
	local $/ = undef ;
	my $text = <FILE> ;
	$text =~ s~<p><a name="__index__"></a></p>~~ ;
	$text =~ s~<hr />\n<h1>~<h1>~g ;
	$text =~ s~<div class=pod><p>\n</p>~<div class=pod>~ ;
	
	seek(FILE, 0, 0) ;
	print FILE $text ;
	truncate(FILE, tell(FILE)) ;
	close(FILE) ;
	}

	$slide_file =~ s/^$out_dir// ;
	
	$index_text .= sprintf("%03d ", $slide_index + 1) ;
	$index_text .= "<a href='$slide_file.html'>$unmodified_slide_name$undone_flag</a><br>\n\n" ;
	}
	
# generate index
print "Generating index => $number_of_slides/$regenerated_slides/$number_of_undone_slides\n" ;

open INDEX, ">", "${out_dir}index_slide.html" or die "can't open '${out_dir}index_slide.html': $!" ;

print INDEX <<EOHTML ;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<link rel="stylesheet" href="perl_style.css" type="text/css" />
</head>

<div class="pod">
<body>
<H1>$title</H1>
$index_text
<br>
<div class="path">
<table width=100%>
<tr>
<td width=50%>$title</a></td>
<td align="right" width=50%>Copyright &copy; $copyright</td>
</tr>
</table>
</body>
</html>
EOHTML

close INDEX ;



