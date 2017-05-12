#!/usr/bin/env perl -w
## ----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2004 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings;
1;

# -----------------------------------------------------------------------------
# extract text part.
#
sub text($)
{
	my $txt = shift;
	$txt =~ s/^\s+X ?//gm;
	$txt;
}

# -----------------------------------------------------------------------------
# mlpod2pod.
# my $pod = to_pod($mlpod);
# my $pod = to_pod(\%opts, $mlpod);
#
sub to_pod($;$)
{
	my $opts = ref($_[0]) ? shift : {};
	my $text = text(shift);
	
	my $ifh = TextReader->new("=pod\n\n".$text);
	my $ofh = TextWriter->new();
	
	my $parser = Pod::MultiLang::Pod->new($opts);
	$parser->parse_from_filehandle($ifh,$ofh);
	my $out = $ofh->get();
	$out =~ s/^=pod\n\n//;
	$out =~ s/^\n+//g;
	$out =~ s/\n\n\n+/\n\n/g;
	$out =~ s/\n\n+$/\n/g;
	$out;
};

# -----------------------------------------------------------------------------
# mlpod2html
# my $html = to_html($mlpod);
# my $html = to_html(\%opts, $mlpod);
#
sub to_html($;$)
{
	my $opts = ref($_[0]) ? shift : {};
	my $text = text(shift);
	my $parser = Pod::MultiLang::Html->new($opts);
	
	my $ifh = TextReader->new("=pod\n\n$text");
	my $ofh = TextWriter->new();
	$parser->parse_from_filehandle($ifh,$ofh);
	my $html = $ofh->get();
	#print "# $html\n";
	
	my ($content) = $html=~/<!-- Begin CONTENT -->\n(.*)<!-- End CONTENT -->/s
		or die "parse result failed";
	$content =~ s/^<p>\n(.*)<\/p>\n$/$1/s;
	$content =~ s/^<span class="pod_lang">(.*?)<\/span>\n$/$1/s;
	$content =~ s/\n+$//s;
	#print "# [$text] ==> [$content]\n";
	#print unpack("H*",$content)."\n";
	$content;
}
  
package TextReader;
sub new
{
  my ($pkg,$text) = @_;
  my $this = bless[map{$_.$/}split($/,$text)],$pkg;
  $this;
}
sub getline
{
  my $this = shift;
  shift(@$this);
}

package TextWriter;
use Tie::Handle;
use base qw(Tie::Handle);
sub new
{
  my $pkg = shift;
  use vars qw(*HANDLE);
  my $this = \*HANDLE;
  tie(*$this,$pkg,@_);
  bless $this, $pkg;
  $this;
}
sub TIEHANDLE
{
  my ($pkg,$out) = @_;
  my $this = bless[$out],$pkg;
  if( !UNIVERSAL::isa($this->[0],'SCALAR') )
  {
    my $o = !ref($this->[0]) && $this->[0];
    $this->[0] = \$o;
  }
  $this;
}
sub BINMODE
{
  1;
}
sub PRINT
{
  my $this = shift;
  defined($this->[0]) or $this->[0] = '';
  my $o = join(defined($,)?$,:'',@_);
  ${$this->[0]}.=$o;
  length($o);
}
sub get
{
  my $this = shift;
  my $obj = tied(*$this);
  ${$obj->[0]};
}

__END__
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
