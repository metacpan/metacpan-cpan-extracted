package Syntax::Kamelon::Format::HTML4;

use strict;
use warnings;
use Carp;
use List::Util 'any';

use vars qw($VERSION);
$VERSION="0.15";

use base qw(Syntax::Kamelon::Format::Base);

my $default_header = <<__EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
<head>
[% IF foldmarkers == 1 ~%]
	[% javascript ~%]
[% END ~%]
[% IF inlinecss == 1 ~%]
	<style>
   [%- layoutcss ~%]
   [%- themecss ~%]
   </style>
[% ELSE ~%]
   <link rel="stylesheet" href="[% layoutcss %]" type="text/css">
   <link rel="stylesheet" href="[% themecss %]" type="text/css">
[% END ~%]
<title>[% title %]</title>
</head>
<body>
__EOF

my $default_footer = <<__EOF;
</body>
</html>
__EOF

my $default_template = <<__EOF;
[% header %]
[% panel.begin ~%]
[% IF lineoffset.defined ~%]
	[% linenum = lineoffset ~%]
[% ELSE ~%]
	[% linenum = 1 ~%]
[% END ~%]
[% FOREACH line = content ~%]
	[% IF folds.exists(linenum) ~%]
		[% node = folds.\$linenum ~%]
	[% END ~%]
	[% IF sections == 1 ~%]
		[% IF folds.exists(linenum) ~%]
			[% IF node.depth == 1 ~%]
				[% panel.end ~%]
				<br>
				[% panel.begin ~%]
			[% END ~%]
		[% END ~%]
	[% END ~%]
	<div id="[% linenum %]" class="line">
	[%~ IF foldmarkers == 1 ~%]
		[% IF folds.exists(linenum) ~%]
			<div id="[% linenum %]f" class="fold" onclick="block_fold('[% linenum %]', '[% node.end %]')">-</div><div id="[% linenum %]e" class="fold" onclick="block_expand('[% linenum %]', '[% node.end %]')" style="display:none;">+</div>
		[% ELSE ~%]
			<div class="fold">&nbsp;</div>
		[% END ~%]
	[% END ~%]
	[% IF lineoffset.defined ~%]
		<div class="number">[% linenum %]</div>
	[%~ END ~%]
	[%~ FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
			[%~ snippet.text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %]</br></div>
	[%~ linenum = linenum + 1 %]
[% END ~%]
[% panel.end ~%]
[% footer %]
__EOF

my $default_script = <<__EOF;
<script type="text/javascript" language="JavaScript"><!--
function block_expand(b, e) {
	var marker_e = b.concat('e');
	var marker_f = b.concat('f');
	document.getElementById(marker_e).style.display="none";
	document.getElementById(marker_f).style.display="inline";
	for (i = Number(b) + 1; i <= Number(e); ++i) {
		document.getElementById(i).style.display="inline";
		var im_e = i.toString().concat('e');
		var im_f = i.toString().concat('f');
		if (document.getElementById(im_f) !== null) {
			document.getElementById(im_e).style.display="none";
			document.getElementById(im_f).style.display="inline";
		}
	}
}
function block_fold(b, e) {
	var marker_e = b.concat('e');
	var marker_f = b.concat('f');
	document.getElementById(marker_e).style.display="inline";
	document.getElementById(marker_f).style.display="none";
	for (i = Number(b) + 1; i <= Number(e); ++i) {
		document.getElementById(i).style.display="none";
	}
}
//--></script>
__EOF

my $style_plain_begin = <<__EOF;
<div class="content">
__EOF

my $style_plain_end = <<__EOF;
</div>
__EOF

my $style_scrolled_begin = <<__EOF;
<div class="content" style="overflow:scroll; height:750px;">
__EOF

my $style_scrolled_end = <<__EOF;
</div>
__EOF


sub new {
   my $class = shift;
   my $engine = shift;
	my %args = (@_);

	#We overwrite the following options for parent Base unless the user already set an option
	unless (exists $args{template}) { $args{template} = \$default_template }
	unless (exists $args{tagend}) { $args{tagend} = </font> }

	#We retrieve our own options
	my $foldmarkers = delete $args{foldmarkers};
	unless (defined $foldmarkers) { $foldmarkers = 0 }
	if ($foldmarkers eq 1) {
		unless (exists $args{foldingdepth}) {
			$args{foldingdepth} = 99
		}
	}

	my $footer = delete $args{footer};
	unless (defined $footer) { $footer = \$default_footer }

	my $header = delete $args{header};
	unless (defined $header) { $header = \$default_header }

	my $inlinecss = delete $args{inlinecss};
	unless (defined $inlinecss) { $inlinecss = 1 }

	my $javascript = delete $args{javascript};
	unless (defined $javascript) { 
		$javascript = \$default_script
	};

	#We deal with the layoutcss later on
	my $layoutcss = delete $args{layoutcss};

	my $plainpanel = delete $args{plainpanel};
	unless (defined $plainpanel) { $plainpanel = {
		begin => \$style_plain_begin,
		end => \$style_plain_end,
	}};

	my $scrolled = delete $args{scrolled};
	unless (defined $scrolled) { $scrolled = 0 }

	my $scrolledpanel = delete $args{scrolledpanel};
	unless (defined $scrolledpanel) { $scrolledpanel = {
		begin => \$style_scrolled_begin,
		end => \$style_scrolled_end,
	}};

	my $sections = delete $args{sections};
	unless (defined $sections) { $sections = 0 }
	if ($sections) {
		unless (exists $args{foldingdepth}) {
			$args{foldingdepth} = 1
		}
	}

	#We deal with the themecss later on
	my $themecss = delete $args{themecss};


	my $themefolder = delete $args{themefolder};
	unless (defined $themefolder) {
		$themefolder = $engine->GetIndexer->FindINC('Syntax/Kamelon/Format/HTML4')
	}
	unless (defined $themefolder) {
		die "theme folder not found"
	}
	unless (-e $themefolder) {
		die "theme folder does not exist"
	}
	unless (-d $themefolder) {
		die "theme folder is not a folder"
	}


	unless (defined $layoutcss) { 
		$layoutcss = "$themefolder/layout.css";
	}
	unless (-e $layoutcss) { die "layout stylesheet not found" }

	my $theme = delete $args{theme};
	unless (defined $theme) { $theme = 'DarkGray' }

	unless (defined $themecss) {
		$themecss = "$themefolder/$theme.css";
	}
	unless (-e $themecss) { die "theme stylesheet not found" }

	my $title = delete $args{title};
	unless (defined $title) { $title = 'Kamelon output' }

	my $self = $class->SUPER::new($engine, %args);

	$self->{FOLDMARKERS} = $foldmarkers;
	$self->{FOOTER} = $footer;
	$self->{HEADER} = $header;
	$self->{INLINECSS} = $inlinecss;
	$self->{JAVASCRIPT} = $javascript;
	$self->{LAYOUTCSS} = $layoutcss;
	$self->{PLAINPANEL} = $plainpanel;
	$self->{SCROLLED} = $scrolled;
	$self->{SCROLLEDPANEL} = $scrolledpanel;
	$self->{SECTIONS} = $sections;
	$self->{THEMECSS} = $themecss;
	$self->{THEMEFOLDER} = $themefolder;
	$self->{TITLE} = $title;
	return $self;
}

sub FoldMarkers {
	my $self = shift;
	if (@_) { $self->{FOLDMARKERS} = shift }
	return $self->{FOLDMARKERS}
}

sub Format {
	my $self = shift;

	#processing the header
	my $themecss;
	my $layoutcss;
	my $javascript;
	my $d = $self->{DATA};
	if ($self->{FOLDMARKERS}) {
		$javascript = $self->Process($self->{JAVASCRIPT}, $d);
	}
	if ($self->{INLINECSS}) {
		$themecss = $self->LoadFile($self->{THEMECSS});
		$layoutcss = $self->LoadFile($self->{LAYOUTCSS});
	} else {
		$themecss = $self->{THEMECSS};
		$layoutcss = $self->{LAYOUTCSS};
	}
	my %data = (%$d,
		foldmarkers => $self->{FOLDMARKERS},
		javascript=> $javascript,
		inlinecss => $self->{INLINECSS},
		layoutcss => $layoutcss,
		themecss => $themecss,
		title => $self->{TITLE},
	);
	$self->{HEADERTEXT} = $self->Process($self->{HEADER}, \%data,);

	#process the footer
	$self->{FOOTERTEXT} = $self->Process($self->{FOOTER}, $d);

	#processing the style elements
	my $panel_begin = '';
	my $panel_end = '';
	if ($self->{SCROLLED}) {
		$panel_begin = $self->Process($self->{SCROLLEDPANEL}->{begin}, $self->{DATA});
		$panel_end = $self->Process($self->{SCROLLEDPANEL}->{end}, $self->{DATA});
	} else {
		$panel_begin = $self->Process($self->{PLAINPANEL}->{begin}, $self->{DATA});
		$panel_end = $self->Process($self->{PLAINPANEL}->{end}, $self->{DATA});
	}
	$self->{PANELTEXT} = {
		begin => $panel_begin,
		end => $panel_end,
	};

	#format the whole bunch with the parsed text
	return $self->SUPER::Format;
}

sub Footer {
	my $self = shift;
	if (@_) { $self->{FOOTER} = shift }
	return $self->{FOOTER}
}

sub GetData {
	my $self = shift;
	my $data = $self->SUPER::GetData;
	$data->{foldmarkers} = $self->{FOLDMARKERS};
	$data->{header} = $self->{HEADERTEXT};
	$data->{footer} = $self->{FOOTERTEXT};
	$data->{panel} = $self->{PANELTEXT};
	$data->{sections} = $self->{SECTIONS};
	return $data
}

sub Header {
	my $self = shift;
	if (@_) { $self->{HEADER} = shift }
	return $self->{HEADER}
}

sub InlineCSS {
	my $self = shift;
	if (@_) { $self->{INLINECSS} = shift }
	return $self->{INLINECSS}
}

sub Javascript {
	my $self = shift;
	if (@_) { $self->{JAVASCRIPT} = shift }
	return $self->{JAVASCRIPT}
}

sub LayoutCSS {
	my $self = shift;
	if (@_) { $self->{LAYOUTCSS} = shift }
	return $self->{LAYOUTCSS}
}

sub LoadFile {
	my ($self, $file) = @_;
	open IN, "<$file" or return undef;
	my $out = '';
	while (my $line = <IN>) {
		$out = $out . $line;
	}
	close IN;
	return $out
}

sub PlainPanel {
	my $self = shift;
	if (@_) { $self->{PLAINPANEL} = shift }
	return $self->{PLAINPANEL}
}

sub Scrolled {
	my $self = shift;
	if (@_) { $self->{SCROLLED} = shift }
	return $self->{SCROLLED}
}

sub ScrolledPanel {
	my $self = shift;
	if (@_) { $self->{SCROLLEDPANEL} = shift }
	return $self->{SCROLLEDPANEL}
}

sub Sections {
	my $self = shift;
	if (@_) { $self->{SECTIONS} = shift }
	return $self->{SECTIONS}
}

sub ThemeCSS {
	my $self = shift;
	if (@_) { $self->{THEMECSS} = shift }
	return $self->{THEMECSS}
}

sub ThemeFolder {
	my $self = shift;
	if (@_) { $self->{THEMEFOLDER} = shift }
	return $self->{THEMEFOLDER}
}

sub Title {
	my $self = shift;
	if (@_) { $self->{TITLE} = shift }
	return $self->{TITLE}
}

1;
__END__
