=pod

=begin classdoc

Generates and merges <cpan>Pod::ProjectDocs</cpan>, <cpan>Pod::Classdoc</cpan>,
and <cpan>PPI::HTML::CodeFolder</cpan>output, then generates a Javascripted 
tree widget (via <cpan>HTML::ListToTree</cpan>) to navigate the merged
manuals, classdocs, and folded/highlighted source code.

@author Dean Arnold
@exports renderProject()	the only public method
@see <cpan>Pod::ProjectDocs</cpan>
@see <cpan>Pod::Classdoc</cpan>
@see <cpan>PPI::HTML::CodeFolder</cpan>
@see <cpan>HTML::ListToTree</cpan>

=end classdoc

=cut

package Pod::Classdoc::Project;

use Pod::ProjectDocs;
use Pod::Classdoc;
use JSON;
use Exporter;

use base('Exporter');

@EXPORT = ('renderProject');

use strict;
use warnings;

our $VERSION = '1.01';

our %defaults = (
'Heredocs', 1,
'POD', 1,
'Comments', 1,
'Expandable', 1,
'Imports', 1,
'MinFoldLines', 4,
);

=pod

=begin classdoc

Generates merged project documentation from <cpan>Pod::ProjectDocs</cpan>,
<cpan>Pod::Classdoc</cpan>, and <cpan>PPI::HTML::CodeFOlder</cpan> output,
with a table of contents widget generated from <cpan>HTML::ListToTree</cpan>.

@optional Additions		HTML document to be appended to the TOC widget
@optional Comments		boolean; if true (the default), fold comments in PPI::HTML::CodeFolder output
@optional Charset		specifies character set for Pod::ProjectDocs
@optional CloseImage	name of closed node icon in TOC; default 'closedbook.gif'
@optional CSSPath		path to CSS files; default is <code>&lt;Output&gt;/css</code>
@optional Description	specifies description header for Pod::ProjectDocs
@optional Download		specifies a download file to be appended to the TOC widget
@optional Expandable	boolean; if true (the default), folds in PPI::HTML::CodeFolder output are expandable
@optional Force			boolean; if true, forces generation of all Pod::ProjectDocs documents
@optional Heredoc   	boolean; if true (the default), fold heredocs in PPI::HTML::CodeFolder output
@optional Imports		boolean; if true (the default), fold imports in PPI::HTML::CodeFolder output
@optional IconPath		path to icon images for TOC; default is <code>&lt;Output&gt;/img</code>
@optional JSPath		path to Javascript files; default is <code>&lt;Output&gt;/js</code>
@optional Language		specifies language info for Pod::ProjectDocs
@optional Libs			library directories to be processed; defaults to './lib' and './bin'
@optional MinFoldLines	minimum number of lines for codefolding; default 4
@optional NoIcons		boolean; if true (default false), TOC will not use icons
@optional NoSource		boolean; if true (default false), omit PPI::HTML::CodeFolder source processing
@optional OpenImage		name of open node icon in TOC; default 'openbook.gif'
@optional Order			arrayref of package/script names; TOC nodes will be ordered in same order
						as this list. Any unlisted packages/scripts will be alphabetically ordered
						after these nodes are included.
@optional Output		root path of output files; default './classdocs'
@optional POD			boolean; if true (the default), fold POD in PPI::HTML::CodeFolder output
@optional RootImage		name of root node icon in TOC; default 'globe.gif'
@optional Title			title string for HTML document, and root node of TOC
@optional Verbose		boolean; if true, emits lots of diagnostic info

@static

=end classdoc

=cut

sub renderProject {
	my %args = @_;

	my $out = $args{Output} || './classdocs';
	my $csspath = $args{CSSPath} || "$out/css";
	my $jspath = $args{JSPath} || "$out/js";
	my $imgpath = $args{Iconpath} || "$out/img";
	my $openimg = $args{OpenImage} || 'openbook.gif';
	my $closeimg = $args{CloseImage} || 'closedbook.gif';
	my $rootimg = $args{RootImage} || 'globe.gif';
	$args{Title} ||= 'My Project';

	while (my ($k, $v) = each %defaults) {
		$args{$k} = $v unless exists $args{$k};
	}

	unless ($args{NoSource}) {
		eval {
			require PPI::HTML::CodeFolder;
		};
		$args{NoSource} = 1,
		warn "Cannot generate codefolded sources:\n$@\n"
			if $@;
	}

	my $notree;
	eval {
		require HTML::ListToTree;
	};
	$notree = 1,
	warn "Cannot generate tree table of contents:\n$@\n"
		if $@;
#
#	first generate project docs; note that this
#	copies source files into the outroot/src path
#
	print "\nGenerating ProjectDocs..."
		if $args{Verbose};

	$args{Libs} = [ './lib', './bin' ] 
		unless $args{Libs} && ref $args{Libs} && ($#{$args{Libs}} >= 0);

	Pod::ProjectDocs->new(
	    outroot  => $out,
	    libroot  => $args{Libs},
	    title    => $args{Title},
	    desc     => $args{Description},
	    charset  => $args{CharSet},
	    index    => 1,
	    verbose  => $args{Verbose},
	    forcegen => $args{Force},
	    lang     => $args{Language},
	)->gen() or die $@;
#
#	then generate classdocs
#
	print "done\nCollecting source files..."
		if $args{Verbose};

	my $path = "$out/src";
	my @dirs = ();
	die $@
		unless _recurseDirs($path, \@dirs);

	print "done\nScanning ", join(', ', @dirs), "\n"
		if $args{Verbose};

	my @files = ();
	foreach my $p (@dirs) {
		warn "$p directory not found" and
		next
			unless opendir(PATH, $p);
#
#	recurse the directory to find all .pm files;
#
		my @tfiles = readdir PATH;
		closedir PATH;

		push @files, map "$p/$_", grep /\.pm$/, @tfiles;
	}

	my $classdocs = Pod::Classdoc::ForProjectTOC->new($out, $args{Title}, $args{Verbose}) or die $@;

	my %sources = ();
	my $HTML;
	unless ($args{NoSource}) {
		my %tagcolors = (
	    cast => '#339999',
	    comment => '#008080',
	    core => '#FF0000',
	    double => '#999999',
	    heredoc => '#FF0000',
	    heredoc_content => '#FF0000',
	    heredoc_terminator => '#FF0000',
	    interpolate => '#999999',
	    keyword => '#0000FF',
	    line_number => '#666666',
	    literal => '#999999',
	    magic => '#0099FF',
	    match => '#9900FF',
	    number => '#990000',
	    operator => '#DD7700',
	    pod => '#008080',
	    pragma => '#990000',
	    regex => '#9900FF',
	    single => '#999999',
	    substitute => '#9900FF',
	    transliterate => '#9900FF',
	    word => '#999999',
		);

		$HTML = PPI::HTML::CodeFolder->new(
		    line_numbers => 1,
		    page         => 1,
		    colors       => \%tagcolors,
		    verbose      => $args{Verbose},
		    fold          => {
		    	Abbreviate    => 1,
		        Heredocs      => $args{Heredocs},
		        POD           => $args{POD},
		        Comments      => $args{Comments},
		        Expandable    => $args{Expandable},
		        Imports       => $args{Imports},
		        MinFoldLines  => $args{MinFoldLines},
		        Javascript    => "$jspath/ppicf.js",
		        Stylesheet    => "$csspath/ppicf.css",
		        },
		    )
		    or die "\nFailed to create a PPI::HTML::CodeFolder";
	}

	foreach my $file (@files) {
#
#	add a file to the classdocs
#
		print "$file: generating classdocs...\r"
			if $args{Verbose};
		my $Document = $classdocs->open($file);

		unless ($args{NoSource}) {
#
#	codefold/highlight the file
#
			print "$file: generating codefolded source...\r"
				if $args{Verbose};

			my $outfile = substr($file, length($path) + 1);
			my $t = $HTML->html( $Document, "$out/$outfile.html" )
			    or die "\nFailed to generate HTML";
#
#	create output in output file
#
			open(OUTF, ">$out/$outfile.html") or die "Can't create $out/$outfile.html: $!";
			print OUTF $t;
			close OUTF;
#
#	don't need the original sources now
#
			unlink $file;
		}
	}

	foreach ($out, $csspath, $jspath, $imgpath) {
		mkdir $_
			unless -d $_;
	}

	print "\nRendering classdocs...\n"
		if $args{Verbose};

	$classdocs->writeClassdocs(1);
#
#	generate the TOC
#
	$/ = undef;
	print "Generating table of contents...\n"
		if $args{Verbose};
#
#	extract index from root document
#
	open INF, "$out/index.html" or die $!;
	my $html = <INF>;
	close INF;
#
#	get rid of search box and adjust path separators as needed
#
	$html=~s!<div\s+class="box">\s*<h2\s+class="t2">Search</h2>.*?</div>!!s;
	$html=~s!\.\\!./!gs;
	$html=~s!\\\\!/!gs;
#
#	replace current index page after edits
#
	open OUTF, ">$out/project.html"
		or die "Cannot create $out/project.html: $!";
	print OUTF $html;
	close OUTF;

	my ($list) = ($html=~/var\s+managers\s*=\s*([^\n]+)\n/);

	$list = substr($list, 0, -1) if (substr($list, -1) eq ';');

	$list = jsonToObj($list);

	my $mans = $list->[0];
	die "Unrecognizable project index\n" 
		unless ($mans->{desc} eq 'Package Manuals') ||
			($mans->{desc} eq 'Perl Manuals');
#
#	locate any manfiles and map to package names
#
	my %manuals = ();
	$_->{name}=~s/-/::/g,
	$_->{path}=~tr/\\/\//,
	$manuals{$_->{name}} = {
		Manual => $_->{path},
		TOC    => _extractTOC(join('/', $out, $_->{path}), $csspath)
	}
		foreach (@{$mans->{records}});

	my $toc = $classdocs->getProjectTOC(
		Manuals => \%manuals, 
		SourceMap => $HTML ? $HTML->getCrossReference() : undef,
		GroupExternals => 1,
		Additions => $args{Additions},
		Order => $args{Order}
	);
	($toc) = ($toc=~/<!--\s+INDEX BEGIN\s+-->(.*?)<!--\s+INDEX END\s+-->/s);
	
#	open OUTF, ">testoc.html";
#	print OUTF $toc;
#	close OUTF;
#
#	replace index page with frameset
#
	open(INDEX, ">$out/index.html") or die $!;
	print INDEX
"<html>
<head>
<title>$args{Title}</title>
</head>
<frameset cols='15%,*'>
<frame name='navbar' src='toc.html' frameborder=1>
<frame name='mainframe' src='project.html'>
</frameset>
</html>
";
	close INDEX;
#
#	render the TOC and write it out;
#	add any download link, and current generate timestamp
#
	my $download = $args{Download};
	if ($download) {
		my @parts = split /[\\\/]/, $download;
		$download = "<a href='$download'>$parts[-1]</a><p>";
	}
	else {
		$download = '';
	}

	$download .= "<span style='font-size: 12px; font-style: italic;'>Generated by<br>Pod::Classdoc::Project v.$VERSION<br>at " . _trimtime() . '</span>';
	unless ($notree) {
		my $tree = HTML::ListToTree->new(
			Text => $args{Title}, 
			Link => 'project.html', 
			Source => $toc
			)
			or die $@;
		my $widget = $tree->render(
				CloseIcon => $closeimg,
				OpenIcon => $openimg,
				RootIcon => $rootimg,
				IconPath => _pathAdjust($out, $imgpath),
				CSSPath => _pathAdjust($out, $csspath) . '/dtree.css',
				JSPath => _pathAdjust($out, $jspath) . '/dtree.js',
				UseIcons => (!$args{NoIcons}),
				Additions => $download,
				BasePath => $out
			);

		open(TREE, ">$out/toc.html") or die $!;
		print TREE $widget;
		close TREE;
#
#	make sure to write out the extras
#
		die $@
			unless $tree->writeJavascript("$jspath/dtree.js") && 
				$tree->writeCSS("$csspath/dtree.css") && 
				$tree->writeIcons($imgpath) &&
				((!$HTML) ||
					($HTML->writeJavascript("$jspath/ppicf.js") && 
					$HTML->writeCSS("$csspath/ppicf.css")));
	}
	return 1;
}

sub _trimtime {
	my @parts = split /\s+/, (scalar localtime());
	shift @parts;
	($parts[0], $parts[1], $parts[2]) = ($parts[2], $parts[0], $parts[1] . ',');
	return join(' ', @parts);
}

sub _recurseDirs {
	my ($path, $dirs) = @_;
	
	$@ = "$path directory not found",
	return undef
		unless opendir(PATH, $path);
#
#	recurse the directory to find all subdirs
#
	my @files = readdir PATH;
	closedir PATH;
	push @$dirs, $path;
	foreach (@files) {
		return undef
			if ($_ ne '.') && ($_ ne '..') && (-d "$path/$_") && (!_recurseDirs("$path/$_", $dirs));
	}
	return 1;
}

#
#	extract index from a manual file, and otherwise
#	beautify the file
#
sub _extractTOC {
	my ($file, $css) = @_;

	my $oldsep = $/;
	$/ = undef;
	open INF, $file or die $!;
	my $html = <INF>;
	close INF;
	$/ = $oldsep;

	$html=~s/<title>([^<]+)<\/title>//s;

	return undef
		unless ($html=~s/<!--\s+INDEX START\s+-->\s+(.+)<!--\s+INDEX END\s+-->//s);
	my $index = $1;
#
#	clean up stuff we've changed or don't want
#
	$html=~s!(href=["'])([^"']+)!{ my $t = $2; $t=~tr/\\/\//; $1 . $t; }!egs
		if ($^O eq 'MSWin32');
	$html=~s/<a\s+href="\#TOP".+?<\/a>//gs;
	$html=~s/<a\s+href="[^"]+">Source<\/a>//s;
	
	$html=~s!<div class="path">.+?</div>!!s;

	$index=~s!<h3 id="TOP">Index</h3>\s*<ul>\s*<li><a href="#NAME">NAME</a></li>!<ul>\n!s;
	$index=~s!<hr\s*/>!!s;

# " to keep textpad happy
	open FRAME, ">$file" or die $!;
	print FRAME $html;
	close FRAME;
	return $index;
}

sub _pathAdjust {
	my ($path, $jspath) = @_;
#	return $jspath
#		unless (substr($jspath, 0, 2) eq './') && (substr($path, 0, 2) eq './');
#
#	relative path, adjust as needed from current base
#
	my @parts = split /\//, $path;
	my @jsparts = split /\//, $jspath;
#	my $jsfile = pop @jsparts;	# get rid of filename
#	pop @parts;		# remove filename
	shift @parts;
	shift @jsparts;	# and the relative lead
	my $prefix = '';
	shift @parts, 
	shift @jsparts
		while @parts && @jsparts && ($parts[0] eq $jsparts[0]);
#	push @jsparts, $jsfile;
	return ('../' x scalar @parts) . join('/', @jsparts)
}


1;

=pod

=begin classdoc

Subclass of <cpan>Pod::Classdoc</cpan> providing methods to
write a project TOC.

=end classdoc

=cut

package Pod::Classdoc::ForProjectTOC;

use base ('Pod::Classdoc');

=pod

=begin classdoc

Write out a project table of contents document for the current collection of
classdocs as a nested HTML list. The output filename is 'toc.html'.
The caller may optionally specify the order of classes in the menu.

@optional Additions	string of additional HTML list elements to append to TOC
@optional Manuals	hashref mapping package names to manual files
@optional SourceMap	hashref mapping packages and methods to their source filename
@optional Order	arrayref of packages in the order in which they should appear in TOC; if a partial list,
					any remaining packages will be appended to the TOC in alphabetical order
@optional GroupExternals if true, group external methods separately

@return	this object on success, undef on failure, with error message in $@

=end classdoc

=cut

sub writeProjectTOC {
	my $self = shift;
	my $path = $self->{_path};
	$@ = "Can't open $path/toc.html: $!",
	return undef
		unless CORE::open(OUTF, ">$path/toc.html");

	print OUTF $self->getProjectTOC(@_);
	close OUTF;
	return $self;
}

=pod

=begin classdoc

Generate a project table of contents document for the current collection of
classdocs as a nested HTML list. Caller may optionally specify
the order of classes in the menu.

@optional Additions	string of additional HTML list elements to append to TOC
@optional Manuals	hashref mapping package names to manual files
@optional SourceMap	hashref mapping packages and methods to their source filename
@optional Order	arrayref of package names in the order in which they should appear in TOC; if a partial list,
					any remaining packages will be appended to the TOC in alphabetical order
@optional GroupExternals if true, group external methods separately

@return	the TOC document

=end classdoc

=cut

sub getProjectTOC {
	my $self = shift;
	my %args = @_;
	my @order = $args{Order} ? @{$args{Order}} : ();
	my $sources = $args{SourceMap} || {};
	my $manuals = $args{Manuals} || {};
	my $path = $self->{_path};
	my $title = $self->{_title};
	my $base;
	my $doc =
"<html>
<body>
<small>
<!-- INDEX BEGIN -->
<ul>
";
	my %ordered = ();
	$ordered{$_} = 1 foreach (@order);
#
#	merge any undoc'd packages
#
	while (my ($pkg, $pkginfo) = each %$sources) {
		$self->{_classes}{$pkg} = { }
			unless exists $self->{_classes}{$pkg};

		my $info = $self->{_classes}{$pkg};
		$info->{URL} = exists $info->{File} ? join('#', $self->makeClassPath($pkg), $pkg) : $pkginfo->{URL};
		$info->{Methods} ||= {};
		$info->{constructors} ||= {};
		my $methods = $info->{Methods};
		my $constr = $info->{constructors};
		while (my ($sub, $suburl) = each %{$pkginfo->{Methods}}) {
			$constr->{$sub}{URL} = join('#_f_', $self->makeClassPath($pkg), $sub),
			$constr->{$sub}{Source} = $suburl,
			next
				if exists $constr->{$sub};

			print STDERR "*** $pkg\::$sub has no classdocs.\n"
				unless (substr($sub, 0, 1) eq '_') || exists $methods->{$sub};

			$methods->{$sub}{URL} = $suburl,
			next
				unless exists $methods->{$sub};

			$methods->{$sub}{URL} = join('#_f_', $self->makeClassPath($pkg), $sub);
			$methods->{$sub}{Source} = $suburl;
		}
	}
#
#	merge in any manuals
#
	my ($pkg, $manual, $key, $info);
	$self->{_classes}{$pkg} ||= { },
	$info = $self->{_classes}{$pkg},
	$key = exists $info->{URL} ? 'Manual' : 'URL',
	$info->{$key} = $manual->{Manual}
		while (($pkg, $manual) = each %$manuals);

	foreach (sort keys %{$self->{_classes}}) {
		push @order, $_ unless exists $ordered{$_};
	}

	foreach $pkg (@order) {
#
#	due to input @order, we might get classes that don't exist
#
		next unless exists $self->{_classes}{$pkg};

		my $info = $self->{_classes}{$pkg};
		$base = $pkg;
		$base =~s/::/\//g;
		$doc .=  "<li><a href='$info->{URL}'>$pkg</a>\n<ul>\n";
#
#	only point to classdocs if we have some
#
		$doc .= "<li><a href='$base.html#summary'>Summary</a></li>
			<li><a href='$base.html'>Description</a></li>\n"
			if $info->{File};
#
#	ditto for manuals
#	if no source or docs, dump manual TOC and skip the rest
#
		$doc .= $info->{Manual} ?
			"<li><a href='$info->{Manual}'>Manual</a>\n$manuals->{$pkg}{TOC}<!-- END MANUAL -->\n</li>\n" :
			join( '', $manuals->{$pkg}{TOC}, "\n</ul></li>\n")
			if exists $manuals->{$pkg};

		my %t;
		my ($k, $v);
		if (exists $info->{exports} && @{$info->{exports}}) {
			$doc .=  "<li><a href='$base.html#exports'>Exports</a>
			<ul>
			";
			%t = @{$info->{exports}};
			$doc .=  "<li><a href='$base.html#_e_$_'>$_</a></li>\n"
				foreach (sort keys %t);
			$doc .=  "</ul><!-- END EXPORTS -->\n</li>\n";
		}
		if (exists $info->{imports} && @{$info->{imports}}) {
			$doc .=  "<li><a href='$base.html#imports'>Imports</a>
			<ul>
			";
			%t = @{$info->{imports}};
			$doc .=  "<li><a href='$base.html#_i_$_'>$_</a></li>\n"
				foreach (sort keys %t);
			$doc .=  "</ul><!-- END IMPORTS -->\n</li>\n";
		}
		if (exists $info->{member} && @{$info->{member}}) {
			$doc .=  "<li><a href='$base.html#members'>Public Members</a>
			<ul>
			";
			%t = @{$info->{member}};
			$doc .=  "<li><a href='$base.html#_m_$_'>$_</a></li>\n"
				foreach (sort keys %t);
			$doc .=  "</ul><!-- END MEMBERS -->\n</li>\n";
		}
		if (exists $info->{constructors} && %{$info->{constructors}}) {
			$doc .=  "<li><a href='$base.html#constructor_detail'>Constructors</a>
			<ul>
			";
			my $constr = $info->{constructors};
			foreach (sort keys %$constr) {
				$doc .=  "<li><a href='$constr->{$_}{URL}'>$_</a>";
				$doc .= "<i>(ext.)</i></li>\n",
				next
					if $constr->{$_}{External};

				$doc .= "</li>\n",
				next
					unless $constr->{$_}{Source};

				$doc .= "	<ul>
			<li><a href='$constr->{$_}{Source}'>Source</a></li>
		</ul></li>\n";
			}
			$doc .=  "</ul><!-- END CONSTRUCTORS -->\n</li>\n";
		}
		if (exists $info->{Methods} && %{$info->{Methods}}) {
			my %externals = ();
			if ($args{GroupExternals}) {
				while (my ($sub, $subinfo) = each %{$info->{Methods}}) {
					$externals{$sub} = $subinfo
						if $subinfo->{External};
				}
			}
			$doc .=  "<li><a href='$base.html#method_detail'>Methods</a>
			<ul>
			";
			my $methods = $info->{Methods};
			foreach (sort keys %$methods) {
				$doc .=  exists $methods->{$_}{Source} ?
					"<li><a href='$methods->{$_}{URL}'>$_</a>\n<ul>\n<li><a href='$methods->{$_}{Source}'>Source</a></li>\n</ul>\n</li>\n" :
					"<li><a href='$methods->{$_}{URL}'>$_</a></li>\n"
					unless exists $externals{$_};
			}
			if (%externals) {
				$doc .=  "<li>External Methods
				<ul>
				";
				$doc .=  "<li><a href='$methods->{$_}{URL}'>$_</a></li>\n"
					foreach (sort keys %externals);
				$doc .=  "</ul>\n</li>\n";
			}
			$doc .=  "</ul><!-- END METHODS -->\n</li>\n";
		}
		$doc .=  "</ul>\n</li><!-- END PACKAGE -->\n";
	}
	$args{Additions} ||= '';
	$doc .=  "\n$args{Additions}
</ul>
<!-- INDEX END -->
</small>
</body>
</html>
";

	return $doc;
}

1;

