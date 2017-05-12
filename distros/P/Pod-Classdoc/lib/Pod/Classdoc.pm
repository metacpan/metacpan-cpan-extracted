=pod

=begin classdoc

Generate javadoc-like class documentation from embedded POD.
Uses <cpan>PPI::Find</cpan> to locate POD, packages, and methods, then
processes the extracted POD into a javadoc-ish HTML format. Classdoc POD
is defined within <code>=begin classdoc</code> and 
<code>=end classdoc</code> sections. Each such section is associated
with its immediately succeding package or method statement, unless
the <code>@xs</code> directive is specified, in which case
the classdoc is assumed to be for an external (e.g., XS) method.
Multiple external method classdoc sections may be specified within a single
<code>=pod ... =cut</code> section, with the final such classdoc section
associated with any trailing method definition.

@author Dean Arnold
@see <cpan>PPI</cpan>
@see <cpan>PPI::Find</cpan>
@see <a href='http://java.sun.com/j2se/javadoc/writingdoccomments/'>"How to Write Doc Comments for the Javadoc Tool"</a>
@since 2007-Jun-10
@instance hash
@self $self

=end classdoc

=cut

package Pod::Classdoc;

use PPI;
use PPI::Document;
use PPI::Find;
use File::Path;

use strict;
use warnings;

our $VERSION = '1.01';

my %validpkgtags = (qw(
	author 2
	deprecated 1
	exports 1
	ignore 1
	imports 1
	instance 1
	member 1
	see 2
	self 1
	since 1
));

my %validsubtags = (qw(
	author 2
	constructor 1
	deprecated 1
	ignore 1
	param 1
	optional 1
	return 1
	returnlist 1
	see 2
	self 1
	simplex 1
	since 1
	static 1
	urgent 1
));

my %secttags = ( 
	'export' => '_e_', 
	'import' => '_i_', 
	'member' => '_m_', 
	'method' => '_f_', 
	'package' => '_p_' 
);
#
#	our default color theme; change these
#	for different look
#
my $aqua = '#98B5EB';

#
#	our database:
#		key is class name
#		contents are
#			author => '',
#			since => '',
#			version => '',
#			InheritsFrom => {},
#			SubclassedBy => {},
#			Description => '',
#			File => '',
#			Line => '',
#			see => [],
#			deprecated => undef|1,
#			exports => [],
#			imports => [],
#			members => [],
#			instance => '',
#			self => '',
#			Methods =>
#			{
#				$name =>
#				{
#					Description => '',
#					File => '',
#					Line => '',
#					static => undef|1,
#					self => '',
#					deprecated => undef|1,
#					see => [],
#					since => '',
#					param => [ 'name', 'description', ... ],
#					return => 'description',
#					returnlist => 'description',
#					simplex => undef|1,
#					urgent => undef|1,
#					constructor => 1|undef
#				}
#			}
#

=pod

=begin classdoc

Creates a new empty Pod::Classdoc object.

@constructor

@optional $path directory path for output documents; default is './classdocs'
@optional $title title string to use for head of classdocs
@optional $verbose if true, enables diagnostic output (default false)

@return	a new Pod::Classdoc object

=end classdoc

=cut

sub new {
	my ($class, $path, $title, $verbose) = @_;
	$path ||= './classdocs';
	$path=~s/\/+$// unless ($path eq '/');
	my $self = {
		_path => $path,
		_classes => {}, 
		_title => $title, 
		_verbose => $verbose || 0,
	};
	return bless $self, $class;
}

=pod

=begin classdoc

Scan the provided text for Perl packages, adding the packages
to the current collection of classes. When a package is located,
it is scanned for its inherited classes and classdoc'd methods.

@param $txt	the package text as either a scalar string, or an arrayref of
	the lines of the package
@optional $file full path of source file

@return the PPI::Document object generated from the input text

=end classdoc

=cut

sub add {
	my ($self, $txt, $file) = @_;
	$txt = join("\n", @$txt)
		if ref $txt;
#
#	grab version as for MakeMaker;
#	note only one version per source file
#
	my $version;
	if ($txt=~/\n\s*((my|our|local)\s+)?\$[\w\:\']*?\bVERSION\s*?\=([^;]+?);/) {
		eval "\$version = $3;";
	}

	$self->{_state} = 0;
	$self->{_currpkg} = '';
	$self->{_currpod} = '';
	$self->{_currsub} = '';
	$self->{_currloc} = undef;
	$self->{_currtext} = $txt;
	$self->{_currfile} = $file;
	$self->{_nosubs} = 0;

	my $Document = PPI::Document->new(\$txt) or die "Can't process into PPI::Document";

	# Create the Find object
	my $Finder = PPI::Find->new( sub { $self->_wanted(@_); } ) or die "Can't create PPI::Find";
# Use the object as an iterator
	$Finder->start($Document) or die "Failed to execute search";
#
#	process any trailing classdoc section
#
	$self->{_nosubs} += _processClassdocs(undef, $self->{_currpod}, $self->{_currloc}, $self->{_currloc}, $file, $self->{_classes}, $self->{_currpkg})
		if $self->{_currpod};
#
#	process any open package
#
	$self->_processPackage() if $self->{_currpkg};

	warn "$self->{_nosubs} classdoc sections found without matching methods." 
		if $self->{_nosubs} && $self->{_verbose};

	if ($self->{_verbose} > 1) {

		foreach my $currpkg (sort keys %{$self->{_classes}}) {
			my $pkg = $self->{_classes}{$currpkg};
			print "Package $currpkg at line $pkg->{File}:$pkg->{Line}:\n$pkg->{Description}\n\nhas the following methods:\n\n";
			my $sub;
			$sub = $pkg->{Methods}{$_},
			print "**********\n$_ at line $sub->{File}:$sub->{Line}:\n$sub->{Description}\n\n"
				foreach (sort keys %{$pkg->{Methods}});
		}
	}

	return $Document;
}

=pod

=begin classdoc

Load the specified package file.

@param $path	path to the package file.
@param $pkg		Perl name of the package

@return the PPI::Document object generated from the input file

=end classdoc

=cut

sub open {
	my ($self, $path, $pkg) = @_;

	my $file = $pkg ? "$path/$pkg" : $path;
	$file=~s/::/\//g;
	$file .= '.pm' if $pkg;
	$@ = "Cannot open $file: $!" and
	return undef
		unless open(INF, $file);

	my $oldsep = $/;
	$/ = undef;
	my $doc = <INF>;
	close INF;
	$/ = $oldsep;

	return $self->add($doc, $file);
}

=pod

=begin classdoc

Load all the package files within a specified project directory.
Recurses into subdirectories as needed.

@param @projects	list of pathnames of root project directories

@return this Pod::Classdoc object

=end classdoc

=cut

sub openProject {
	my $self = shift;

	$self->_getSubDirs($_)
		foreach @_;
	my $dirs = $self->{_dirs};
	print "Scanning ", join("\n", @$dirs), "\n"
		if $self->{_verbose};

	my @files = ();
	foreach my $path (@$dirs) {
		unless (opendir(PATH, $path)) {
			warn "directory $path not found"
				if $self->{_verbose};
			next;
		}
#
#	glob the directory for all .pm files;
#
		my @tfiles = readdir PATH;
		closedir PATH;

		push @files, map "$path/$_", grep /\.pm$/, @tfiles;
	}

	foreach (@files) {
		return undef
			unless $self->open($_);
	}
	return $self;
}

sub _processClassdocs {
	my ($currsub, $currpod, $podloc, $subloc, $file, $packages, $currpkg) = @_;
#
#	collect all classdocs first, there may be a list of @xs before a real sub
#
	my @classdocs = $currpod ? 
		($currpod=~/\n=begin\s+classdoc[ \r\t]*\n(.*?)\n=end\s+classdoc[ \r\t]*\n/gs) :
		();
	if ($currsub) {
#
#	if a real sub, grab the last one...but make sure it isn't for @xs
#
		$currpod = pop @classdocs;
		if ((!$currpod) || ($currpod=~/\n\s*\@xs\s+/)) {
			push @classdocs, $currpod if $currpod;
			_processSub($currsub, undef, $subloc, $file, $packages, $currpkg);
		}
		else {
			_processSub($currsub, $currpod, $subloc, $file, $packages, $currpkg);
		}
	}
	my $nosubs = 0;
	foreach (@classdocs) {
#
#	flag unexpected classdocs
#
		if (s/\n\s*\@xs\s+([\w\:]+)[ \t\r]*\n/\n/s) {
			_processSub($1, $_, $podloc, $file, $packages, $currpkg);
		}
		else {
			$nosubs++;
		}
	}
	return $nosubs;
}

sub _processSub {
	my ($currsub, $currpod, $subloc, $file, $packages, $currpkg) = @_;
#
#	need to check for fully qualified sub name
#
	my @parts = split /\:\:/, $currsub;
	if (@parts > 1) {
		$currsub = pop @parts;
		$currpkg = join('::', @parts);
	}
	$packages->{$currpkg} = {
		File => '',
		Line => 0,
		Description => undef,
		Methods => {}
		}
		unless exists $packages->{$currpkg};

	if (exists $packages->{$currpkg}{Methods}{$currsub}) {
		$packages->{$currpkg}{Methods}{$currsub}{File} = $file, 
		$packages->{$currpkg}{Methods}{$currsub}{Line} = $subloc, 
		$packages->{$currpkg}{Methods}{$currsub}{Description} = $currpod
			unless $packages->{$currpkg}{Methods}{$currsub}{File};
	}
	else {
		$packages->{$currpkg}{Methods}{$currsub} = {
			File => $file, 
			Line => $subloc, 
			Description => $currpod 
			};
	}
}

sub _wanted {
	my ($self, $token, $parent) = @_;
	
	print "*** Got a ", ref $token, "\n" 
		if ($self->{_verbose} > 2) && ($token->significant || $token->isa('PPI::Token::Pod'));

	return 0 if ($self->{_state} == 0) && (!$token->isa('PPI::Token::Pod'));

	my $content;
	if ($self->{_state} == 0) {
		$content = $token->content;
		return 0 unless $content=~/\n=begin\s+classdoc[ \r\t]*\n.*?\n=end\s+classdoc[ \r\t]*\n/s;
		print "** Process a new POD\n"
			if ($self->{_verbose} > 1);
		$self->{_currpod} = $content;
		$self->{_currloc} = ${$token->location}[0];
		$self->{_state} = 1;
	}
	elsif ($self->{_state} == 1) {
#
#	we'll support dangling classdocs and nested POD (have to, to support @xs!)
#
		if ($token->isa('PPI::Token::Pod')) {
			$content = $token->content;
			return 0 unless $content=~/\n=begin\s+classdoc[ \r\t]*\n.*?\n=end\s+classdoc[ \r\t]*\n/s;
#
#	process prior classdoc section
#
			print "** Process a new dangling POD\n"
				if ($self->{_verbose} > 1);
			$self->{_nosubs} += _processClassdocs(undef, $self->{_currpod}, $self->{_currloc}, $self->{_currloc}, $self->{_currfile}, $self->{_classes}, $self->{_currpkg});
			$self->{_currpod} = $1;
			$self->{_currloc} = ${$token->location}[0];
		}
		elsif ($token->isa('PPI::Statement::Package')) {
			print "** Process a Package\n"
				if ($self->{_verbose} > 1);
#
#	if a prior namespace defined, save its body and recover any
#	inheritance info; we should really try to use PPI here...
#
			$self->_processPackage(${$token->location}[0])
				if $self->{_currpkg};
			$self->{_currpkg} = $token->namespace;

			if (exists $self->{_classes}{$self->{_currpkg}}) {
				$self->{_classes}{$self->{_currpkg}}{File} = $self->{_currfile},
				$self->{_classes}{$self->{_currpkg}}{Line} = ${$token->location}[0],
				$self->{_classes}{$self->{_currpkg}}{Description} = 
					($self->{_currpod} && $self->{_currpod}=~/\n=begin\s+classdoc[ \r\t]*\n(.*?)\n=end\s+classdoc[ \r\t]*\n/gs) ? $1 : undef
					unless $self->{_classes}{$self->{_currpkg}}{File};
			}
			else {
				$self->{_classes}{$self->{_currpkg}} = {
					File => $self->{_currfile},
					Line => ${$token->location}[0],
					Description => ($self->{_currpod} && $self->{_currpod}=~/\n=begin\s+classdoc[ \r\t]*\n(.*?)\n=end\s+classdoc[ \r\t]*\n/gs) ? $1 : undef,
					Methods => {}
					};
			}
			$self->{_currpod} = '';
			$self->{_currloc} = undef;
			$self->{_state} = 0;
		}
		elsif ($token->isa('PPI::Statement::Sub')) {
			die "Unexpected sub $content at line " . ${$token->location}[0]
				unless $self->{_currpkg};

			print "** Process a Sub\n"
				if ($self->{_verbose} > 1);
			$self->{_nosubs} += _processClassdocs($token->name, $self->{_currpod}, $self->{_currloc}, ${$token->location}[0], $self->{_currfile}, $self->{_classes}, $self->{_currpkg});
			$self->{_currpod} = '';
			$self->{_currloc} = undef;
			$self->{_state} = 0;
		}
	}
	return 1;
}

sub _processPackage {
	my ($self, $end) = @_;
#
#	if a prior namespace defined, save its body and recover any
#	inheritance info; we should really try to use PPI here...
#
	my $pkg = $self->{_classes}{$self->{_currpkg}};
	my $txt = "\n" . 
		(defined $end ? 
			substr($self->{_currtext}, $pkg->{Line}, $end - $pkg->{Line}) : 
			substr($self->{_currtext}, $pkg->{Line}));

	my @parents = ($txt=~/\n\s*use\s+base\s+([^;]+);/gs);
	foreach my $base (@parents) {
		my @bases = ();
		eval "\@bases = $base;";
		map $pkg->{InheritsFrom}{$_} = 1, @bases;
	}
	@parents = ($txt=~/\n\s*(?:(?:my|our)\s+)?\@ISA\s+=\s+([^;]+);/gs);
	foreach my $base (@parents) {
		my @bases = ();
		eval "\@bases = $base;";
		map $pkg->{InheritsFrom}{$_} = 1, @bases;
	}
}

=pod

=begin classdoc

Get or set the output directory path for rendered documents.

@optional $path	root directory where classdocs are to be written; if not provided,
		a Get operation is executed

@returns	for a Get operation, the current output path;
			for a Set operation, the prior output path

=end classdoc

=cut

sub path {
	my ($self, $path) = @_;
	
	return $self->{_path} unless $path;
	$path=~s/\/+$// unless ($path eq '/');
	my $old = $self->{_path};
	$self->{_path} = $path;
	return $old;
}

=pod

=begin classdoc

Render the loaded packages into classdocs. Creates
subdirectories for subordinate classdocs as needed.
Package files containing multiple package definitions
will result in individual files for each package.

@optional $use_private	include private methods. By default,
	only public methods are included in the output; setting this flag
	causes any documented private methods (methods beginning with an
	underscore) to be included as well. Note that constructors
	are always considered public.

@returns	on success, a hashref mapping classnames to an arrayref 
			of the classdoc formatted output, the input source file name and line number
			of the class's associated classdoc'd package definition, and
			a hashref mapping method names to an arrayref of source file name and
			linenumber; 
			undef on failure, with error message in $@

=end classdoc

=cut

sub render {
	my ($self, $use_private) = @_;

	my $descr;
	my $version = '';
	my $accum = '';
	my $indoc;
	my $inpod;
	my $classes = $self->{_classes};
	my ($class, $content);
	my $path = $self->{_path};
#
#	now create crossref of inherits/subclasses
#
	foreach $class (keys %$classes) {
		foreach (keys %$classes) {
			$classes->{$class}{SubclassedBy}{$_} = 1
				if exists $classes->{$_}{InheritsFrom}{$class};
		}
	}
#
#	parse each description for tags
#
	my ($method, $info);
	foreach $class (keys %$classes) {
		if ($classes->{$class}{Description}) {
			$self->_parseTags($class, $classes->{$class}, \%validpkgtags);
		}
		elsif ($self->{_verbose} > 1) {
			warn "No classdoc for $class\n";
		}

		while (($method, $info) = each %{$classes->{$class}{Methods}}) {
			if ($info->{Description}) {
				$self->_parseTags($class, $info, \%validsubtags);
			}
			elsif ($self->{_verbose} > 1) {
				warn "No classdoc for $class\::$method\n";
			}
		}
	}
	my %classlist;
	$classlist{$_} = $self->_generateDoc($_, $path, $use_private)
		foreach (keys %$classes);

	return \%classlist;
}

=pod

=begin classdoc

Clear this object. Removes all currently loaded packages.

@return	this object

=end classdoc

=cut

sub clear {
	my $self = shift;

	$self->{_classes} = {};
	return $self;
}

=pod

=begin classdoc

Write out a toplevel container document for the TOC and
classdoc frames. Assumes the TOC is named 'toc.html'.

@param $container name of output file without path; path is taken
	from the path specified via <method>new<method>() or 
	<method>path<method>()
@optional $home	pathname of a toplevel document to be included in index

@return	this object on success, undef on failure, with error message in $@

=end classdoc

=cut

sub writeFrameContainer {
	my ($self, $container, $home) = @_;
	my $path = $self->{_path};
	$@ = "Can't open $path/$container: $!",
	return undef
		unless CORE::open(OUTF, ">$path/$container");

	print OUTF $self->getFrameContainer($home);
	close OUTF;
	return $self;
}

=pod

=begin classdoc

Generate a toplevel container document for the TOC and
classdoc frames. Assumes the TOC is named 'toc.html'.

@optional $home	pathname of a toplevel document to be included in index

@return	the frame container document

=end classdoc

=cut

sub getFrameContainer {
	my ($self, $home) = @_;

	my $path = $self->{_path};
	my $title = $self->{_title};

	return $home ?
"<html><head><title>$title</title></head>
<frameset cols='15%,85%'>
<frame name='navbar' src='toc.html' scrolling=auto frameborder=0>
<frame name='mainframe' src='$home'>
</frameset>
</html>
" :
"<html><head><title>$title</title></head>
<frameset cols='15%,85%'>
<frame name='navbar' src='toc.html' scrolling=auto frameborder=0>
<frame name='mainframe'>
</frameset>
</html>
";

}

=pod

=begin classdoc

Write out an table of contents document for the current collection of
classdocs as a nested HTML list. The output filename is 'toc.html'.
The caller may optionally specify the order of classes in the menu.

@optional @order	list of packages in the order in which they should appear in TOC; if a partial list,
					any remaining packages will be appended to the TOC in alphabetical order
@return	this object on success, undef on failure, with error message in $@

=end classdoc

=cut

sub writeTOC {
	my $self = shift;
	my $path = $self->{_path};
	$@ = "Can't open $path/toc.html: $!",
	return undef
		unless CORE::open(OUTF, ">$path/toc.html");

	print OUTF $self->getTOC(@_);
	close OUTF;
	return $self;
}

=pod

=begin classdoc

Generate a table of contents document for the current collection of
classdocs as a nested HTML list. Caller may optionally specify
the order of classes in the menu.

@optional @order	list of packages in the order in which they should appear in TOC; if a partial list,
					any remaining packages will be appended to the TOC in alphabetical order
@return	the TOC document

=end classdoc

=cut

sub getTOC {
	my $self = shift;

	my @order = @_;
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
	foreach (sort keys %{$self->{_classes}}) {
		push @order, $_ unless exists $ordered{$_};
	}
		
	foreach my $class (@order) {
#
#	due to input @order, we might get classes that don't exist
#
		next unless exists $self->{_classes}{$class};

		$base = $class;
		$base =~s/::/\//g;
		$doc .=  "<li><a href='$base.html' target='mainframe'>$class</a>
		<ul>
		<li><a href='$base.html#summary' target='mainframe'>Summary</a></li>
		";
		my $info = $self->{_classes}{$class};
		my %t;
		my ($k, $v);
		if (exists $info->{exports} && @{$info->{exports}}) {
			$doc .=  "<li><a href='$base.html#exports' target='mainframe'>Exports</a>
			<ul>
			";
			%t = @{$info->{exports}};
			$doc .=  "<li><a href='$base.html#_e_$_' target='mainframe'>$_</a></li>\n"
				foreach (sort keys %t);
			$doc .=  "</ul>\n</li>\n";
		}
		if (exists $info->{imports} && @{$info->{imports}}) {
			$doc .=  "<li><a href='$base.html#imports' target='mainframe'>Imports</a>
			<ul>
			";
			%t = @{$info->{imports}};
			$doc .=  "<li><a href='$base.html#_i_$_' target='mainframe'>$_</a></li>\n"
				foreach (sort keys %t);
			$doc .=  "</ul>\n</li>\n";
		}
		if (exists $info->{member} && @{$info->{member}}) {
			$doc .=  "<li><a href='$base.html#members' target='mainframe'>Public Members</a>
			<ul>
			";
			%t = @{$info->{member}};
			$doc .=  "<li><a href='$base.html#_m_$_' target='mainframe'>$_</a></li>\n"
				foreach (sort keys %t);
			$doc .=  "</ul>\n</li>\n";
		}
		if (exists $info->{constructors} && %{$info->{constructors}}) {
			$doc .=  "<li><a href='$base.html#constructor_detail' target='mainframe'>Constructors</a>
			<ul>
			";
			$doc .=  "<li><a href='$base.html#_f_$_' target='mainframe'>$_</a></li>\n"
				foreach (sort keys %{$info->{constructors}});
			$doc .=  "</ul>\n</li>\n";
		}
		if (exists $info->{Methods} && %{$info->{Methods}}) {
			$doc .=  "<li><a href='$base.html#method_detail' target='mainframe'>Methods</a>
			<ul>
			";
			$doc .=  "<li><a href='$base.html#_f_$_' target='mainframe'>$_</a></li>\n"
				foreach (sort keys %{$info->{Methods}});
			$doc .=  "</ul>\n</li>\n";
		}
		$doc .=  "</ul>\n</li>\n";
	}

	$doc .=  "
</ul>
<!-- INDEX END -->
</small>
</body>
</html>
";

	return $doc;
}

=pod

=begin classdoc

Write out the documents for the current collection of
classdocs. Renders the current set of classdocs before
writing.

@optional $use_private	include private methods. By default,
	only public methods are included in the output; setting this flag
	causes any documented private methods (methods beginning with an
	underscore) to be included as well. Note that constructors
	are always considered public.

@return	undef on failure, with error message in $@; otherwise, a hashref
	mapping classnames to an arrayref of the full pathname of the classdoc formatted output file,
	the input source file name and line number of the class's associated classdoc'd package 
	definition, and a hashref mapping method names to an arrayref of source file name and
	linenumber.

=end classdoc

=cut

sub writeClassdocs {
	my ($self, $use_private) = @_;
	
	my $classdocs = $self->render($use_private)
		or return undef;

	my $path = $self->{_path};
	foreach (sort keys %$classdocs) {
		my $fname = $self->makeClassPath($_);

		$@ = "Cannot open $fname: $!",
		return undef
			unless CORE::open(OUTF, ">$fname");

		print OUTF $classdocs->{$_}[0];
		close(OUTF);
		$classdocs->{$_}[0] = $fname;
	}
	return $classdocs;
}

=pod

=begin classdoc

Generate fully qualified pathname of output classdoc
file for a given package name. Also creates the path
if needed.

@param $class	package name to be resolved to output classdoc file

@return	the fully qualified pathname to the classdocs for $class,
	with a '.html' qualifier.

=end classdoc

=cut

sub makeClassPath {
	my ($self, $class) = @_;
	my $path = $self->{_path};
	$class=~s!::!/!g;
	$class = join('/', $path, $class);
	my ($dir) = ($class=~/^(.*)\/[^\/]+$/);
	mkpath $dir 
		unless -d $dir;
	return "$class.html";
}

sub _generateDoc {
	my ($self, $class, $path, $use_private) = @_;
	my $info = $self->{_classes}{$class};
	my @parts = split /\:\:/, $class;
	my $fname = pop @parts;
	my $dir = @parts ? join('/', @parts) : '';
#
#	create nav path prefix
#
	my $pfxcnt = 1 + ($dir=~tr'/'');
	my $pathpfx = '../' x $pfxcnt;

	my ($constrsum, $constrdet, $methsum, $methdet) = 
		(
		"<a href='#constructor_summary'>CONSTR</a>",
		"<a href='#constructor_detail'>CONSTR</a>",
		"<a href='#method_summary'>METHOD</a>",
		"<a href='#method_detail'>METHOD</a>"
		);

	my $doc = "
<html>
<head>
<title>$class</title>
</head>
<body>
<table width='100%' border=0 CELLPADDING='0' CELLSPACING='3'>
<TR>
<TD VALIGN='top' align=left><FONT SIZE='-2'>
 SUMMARY:&nbsp;$constrsum&nbsp;|&nbsp;$methsum
 </FONT></TD>
<TD VALIGN='top' align=right><FONT SIZE='-2'>
DETAIL:&nbsp;$constrdet&nbsp;|&nbsp;$methdet
</FONT></TD>
</TR>
</table><hr>
<h2>Class $class</h2>
";
#
#	process InheritsFrom
#
	my $base;
	my @bases = ();
	foreach (keys %{$info->{InheritsFrom}}) {
		$base = $_;
		$base=~s/::/\//g;
#		$base=~s/^$dir\///;	# remove matching headers
		push @bases, "<a href='$pathpfx$base.html'>$_</a>";
	}

	$doc .=  "
<p>
<dl>
<dt><b>Inherits from:</b>
<dd>" . join("</dd>\n<dd>", @bases) . "</dd>
</dt>
</dl>
"
		if scalar @bases;
#
#	process SubclassedBy
#
	@bases = ();
	foreach (keys %{$info->{SubclassedBy}}) {
		$base = $_;
		$base=~s/::/\//g;
#		$base=~s/^$dir\///;	# remove matching headers
		push @bases, "<a href='$pathpfx$base.html'>$_</a>";
	}

	$doc .=  "
<p>
<dl>
<dt><b>Known Subclasses:</b>
<dd>" . join("</dd>\n<dd>", @bases) . "</dd>
</dt>
</dl>
"
		if scalar @bases;
#
#	process package tags
#
	$doc .=  '
<hr>
';
	$doc .=  "<b>Deprecated.</b>" .
		(($info->{deprecated} ne '1') ? " <i>$info->{deprecated}</i>\n" : "\n") .
		"<p>\n"
		if $info->{deprecated};

	$doc .=  "
$info->{Description}
<p>
"
		if $info->{Description};

	$doc .=  '
<dl>
';
	$doc .=  "
<dt><b>Author:</b></dt>
	<dd>$info->{author}</dd>
"
		if $info->{author};

	$doc .=  "
<dt><b>Version:</b></dt>
	<dd>$info->{Version}</dd>
"
		if $info->{Version};

	$doc .=  "
<dt><b>Since:</b></dt>
	<dd>$info->{since}</dd>
"
		if $info->{since};

	$doc .=  join('', "
<dt><b>See Also:</b></dt>
	<dd>", _makeSeeLinks($info->{see}, $pathpfx), "</dd>
")
		if $info->{see};

	$doc .=  "
<p>
<i>Class instances are $info->{instance} references.</i>
<p>"
		if $info->{instance};

	$doc .=  "
<p>
<i>Unless otherwise noted, <code>$info->{self}</code> is the object instance variable.</i>
<p>"
		if $info->{self};

#
#	process imports
#
	$doc .=  join('', "
<a name='imports'></a>
<table border=1 cellpadding=3 cellspacing=0 width='100%'>
<tr bgcolor='$aqua'><th colspan=2 align=left><font size='+2'>Imported Symbols</font></th></tr>
", _makeExportDesc($info->{imports}, '_i_'), "
</table>
<p>
")
		if $info->{imports};
#
#	process exports
#
	$doc .=  join('', "
<a name='exports'></a>
<table border=1 cellpadding=3 cellspacing=0 width='100%'>
<tr bgcolor='$aqua'><th colspan=2 align=left><font size='+2'>Exported Symbols</font></th></tr>
", _makeExportDesc($info->{exports}, '_e_'), "
</table>
<p>
")
		if $info->{exports};
#
#	process members
#
	$doc .=  join('', "
<a name='members'></a>
<table border=1 cellpadding=3 cellspacing=0 width='100%'>
<tr bgcolor='$aqua'><th colspan=2 align=left><font size='+2'>Public Instance Members</font></th></tr>
", _makeExportDesc($info->{member}, '_m_'), "
</table>
<p>
")
		if $info->{member};
#
#	collect method map info before processing
#
	my %methodmap = ();
	while (my($sub, $methodinfo) = each %{$info->{Methods}}) {
		$methodmap{$sub} = [ $methodinfo->{File}, $methodinfo->{Line} ]
			unless (!$use_private) && 
				(substr($sub, 0, 1) eq '_') && 
				(!$methodinfo->{constructor});
	}
#
#	process constructors. Scan for methods with descriptions with '@constructor'
#
	$doc .=  "
<a name='summary'></a>
";
	
	my %constructors = ();
	my $constructor;
	my $anchored;
	foreach (sort keys %{$info->{Methods}}) {
		next
			unless exists $info->{Methods}{$_}{constructor};
		$anchored = 1,
		$doc .= "
<a name='constructor_summary'></a>
",
			unless $anchored;

		$doc .=  "
<table border=1 cellpadding=3 cellspacing=0 width='100%'>
<tr bgcolor='$aqua'><th align=left><font size='+2'>Constructor Summary</font></th></tr>
"
			unless $constructor;

		$constructor = $constructors{$_} = delete $info->{Methods}{$_};

		$doc .=  join('', "
<tr><td align=left valign=top>
<code><a href='#_f_$_'>$_</a>", _makeParamList($constructor->{param}), "</code>
");
		if ($constructor->{deprecated}) {
			$doc .=  '
<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<B>Deprecated.</B>&nbsp;' .
				(($constructor->{deprecated} ne '1') ? "<i>$constructor->{deprecated}</i>" : '');
		}
		elsif ($constructor->{Description}) {
			my $descr =  $constructor->{Description};
			my $brief = _briefDescription(($descr=~/^\s*Constructor\.\s*(.*)$/s) ? $1 : $descr);
			$doc .=  "
<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$brief
";
		}
		$doc .=  "</td></tr>\n";
	} # end for constructors
	$info->{constructors} = \%constructors;
	if ($constructor) {
		$doc .=  "</table><p>\n" 
	}
	else {
		$doc=~s!<a href='#constructor_summary'>CONSTR</a>!CONSTR!;
		$doc=~s!<a href='#constructor_detail'>CONSTR</a>!CONSTR!;
	}
#
#	process methods
#
	my @methods = sort keys %methodmap;
	my $methcount = @methods;
	if ($methcount) {
		$doc .=  "
<a name='method_summary'></a>
<table border=1 cellpadding=3 cellspacing=0 width='100%'>
<tr bgcolor='$aqua'><th align=left><font size='+2'>Method Summary</font></th></tr>
";
		foreach (@methods) {
			my $method = $info->{Methods}{$_};
			$doc .=  join('', "
<tr><td align=left valign=top>
<code><a href='#_f_$_'>$_</a>", _makeParamList($method->{param}), "</code>
");
			if ($method->{deprecated}) {
				$doc .=  '
<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<B>Deprecated.</B>&nbsp;' .
				(($method->{deprecated} ne '1') ? "<i>$method->{deprecated}</i>" : '');
			}
			elsif ($method->{Description}) {
				my $descr = ($method->{static} ? "<i>(class method)</i> " : '') . $method->{Description};
				my $brief = _briefDescription($descr);
				$doc .=  "
<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$brief
";
			}
			$doc .=  "</td></tr>\n";
		}
		$doc .=  "</table>
<p>
";
	}
	else {
		$doc=~s!<a href='#method_summary'>METHOD</a>!METHOD!;
		$doc=~s!<a href='#method_detail'>METHOD</a>!METHOD!;
	}

	if (keys %constructors) {
		$doc .=  "
<a name='constructor_detail'></a>
<table border=1 cellpadding=3 cellspacing=0 width='100%'>
<tr bgcolor='$aqua'>
	<th align=left><font size='+2'>Constructor Details</font></th>
</tr>
</table>
";
		foreach (sort keys %constructors) {
			my $method = $constructors{$_};
			my $returns = $method->{return};
			my $descr =  $method->{Description} || '&nbsp;';
			$descr=~s/^\s*Constructor\.\s*//;
			$doc .=  join('', "
<a name='_f_$_'></a>
<h3>$_</h3>
<pre>
$_", _makeParamList($method->{param}), "
</pre><p>
<dl>
<dd>$descr
<p>
<dd><dl>
");
			$doc .=  join('', "<dt><b>Parameters:</b>\n", _makeParamDesc($method->{param}))
				if $method->{param};

			$doc .=  "<dt><b>Returns:</b><dd>$returns</dd>\n"
				if $returns;

			$doc .=  "<dt><b>Since:</b></dt><dd>$method->{since}</dd>\n"
				if $method->{since};

			$doc .=  join('', "<dt><b>See Also:</b></dt><dd>", _makeSeeLinks($method->{see}, $pathpfx), "</dd>\n")
				if $method->{see};

			$doc .=  "</dl></dd></dl><hr>\n";
		}
		$doc .=  "\n<p>\n";
	} # end if constructor

	if ($methcount) {
		$doc .=  "
<a name='method_detail'></a>
<table border=1 cellpadding=3 cellspacing=0 width='100%'>
<tr bgcolor='$aqua'>
	<th align=left><font size='+2'>Method Details</font></th>
</tr></table>
";
		foreach (@methods) {
			my $method = $info->{Methods}{$_};
			my $returns = $method->{return};
			my $returnlist = $method->{returnlist};
			my $descr =  ($method->{static} ? "<i>(class method)</i> " : '') .
				($method->{Description} || '&nbsp;');
			$doc .=  join('', "
<a name='_f_$_'></a>
<h3>$_</h3>
<pre>
$_", _makeParamList($method->{param}), "
</pre><p>
<dl>
<dd>$descr
<p>
<dd><dl>
");

			if ($method->{simplex}) {
				$doc .=  ($method->{urgent} ?
					"<dt><b>Simplex, Urgent</b></dt>\n" :
					"<dt><b>Simplex</b></dt>\n");
			}
			elsif ($method->{urgent}) {
				$doc .=  "<dt><b>Urgent</b></dt>\n";
			}

			$doc .=  join('', "<dt><b>Parameters:</b>\n", _makeParamDesc($method->{param}))
				if $method->{param};

			if ($returns) {
				$doc .=  ($returnlist ?
					"<dt><b>In scalar context, returns:</b><dd>$returns</dd>\n" :
					"<dt><b>Returns:</b><dd>$returns</dd>\n");
			}

			$doc .=  ($returns ?
				"<dt><b>In list context, returns:</b><dd>($returnlist)</dd>\n" :
				"<dt><b>Returns:</b><dd>($returnlist)</dd>\n")
				if $returnlist;

			$doc .=  "<dt><b>Since:</b></dt><dd>$method->{since}</dd>\n"
				if $method->{since};

			$doc .=  join('', "<dt><b>See Also:</b></dt><dd>", _makeSeeLinks($method->{see}, $pathpfx), "</dd>\n")
				if $method->{see};

			$doc .=  "</dl></dd></dl><hr>\n";
		}	# end foreach method
	} # end if methods
#
#	finish up
#
	my $tstamp = scalar localtime();

	$doc .=  "
<small>
<center>
<i>Generated by POD::ClassDoc $VERSION on $tstamp</i>
</center>
</small>
</body>
</html>
";
	return [ $doc, $info->{File}, $info->{Line}, \%methodmap ];
}
#
#	generate a path from a class, along with
#	an updir path from the class
#
sub _pathFromClass {
	my $class = shift;
	my @parts = split /\:\:/, $class;
	pop @parts;
	return ( '../' x (scalar @parts), join('/', @parts));
}

sub _parseTags {
	my ($self, $class, $info, $validtags) = @_;
#
#	expand all <cpan>, <member>, <method>, and <package> tags
#	NOTE: need a nesting level to construct updir prefixes
#
	my ($updir, $path) = _pathFromClass($class);
	my @parts = ();
	my $method;
	$updir ||= '';
	$info->{Description}=~s!<cpan>([^<]+)</cpan>!<a href='http://search.cpan.org/perldoc\?$1'>$1</a>!g;
	$info->{Description}=~s!<(export|import|method|member)>(\w+)</(?:export|import|method|member)>!<a href='#$secttags{$1}$2'>$2</a>!g;
	$info->{Description}=~s!<(export|import|method|member|package)>([\w\:]+)</(?:export|import|method|member|package)>!
		{ @parts = split('\:\:', $2); $method = ($1 eq 'package') ? '' : pop @parts;
			"<a href='$updir" . join('/', @parts) . '.html' . (($1 eq 'package') ? '' : "#$secttags{$1}") . "$method'>$2</a>" }!egx;
#
#	process classdoc sections
#
	my $desc = '';
	my @lines = split /\n/, $info->{Description};
	my $tag = 'Description';
	my $param;
	my ($ttag, $tdesc);
	my $sep = "\n";
	foreach (@lines) {
		s/^#\*?\s*//;

		$desc .= "$_$sep",
		next
			unless /^\@(\w+)(\s+(.*))?$/ && $validtags->{$1};

		($ttag, $tdesc) = ($1, $3);
		if (($tag eq 'param') || ($tag eq 'optional') || ($tag eq 'exports') || ($tag eq 'imports') || ($tag eq 'member')) {
			($param, $desc) = ($desc=~/^\s*((?:[\\]?[\$\%\@\*\&])?[\w\:]+)\s*(.*)$/s);
			$tag = 'param',
			$desc = '<i>(optional)</i>' . $desc 
				if ($tag eq 'optional');
			push @{$info->{$tag}}, $param, $desc;
		}
		elsif ($tag eq 'see') {
			push @{$info->{$tag}}, $desc;
		}
		else {
			chop $desc, chop $desc if ($sep ne "\n");
			$info->{$tag} = $desc;
		}
		$tag = $ttag;
		$desc = $tdesc || 1;
		$sep = ($validtags->{$tag} == 1) ? "\n" : ",\n";
		$desc .= $sep;
	}
#
#	don't forget the last one!
#
	if (($tag eq 'param') || ($tag eq 'optional') || ($tag eq 'exports') || ($tag eq 'imports') || ($tag eq 'member')) {
		($param, $desc) = ($desc=~/^\s*((?:[\\]?[\$\%\@\*\&])?[\w\:]+)\s*(.*)$/s);
		$tag = 'param',
		$desc = '<i>(optional)</i>' . $desc 
			if ($tag eq 'optional');
		push @{$info->{$tag}}, $param, $desc;
	}
	elsif ($tag eq 'see') {
		push @{$info->{$tag}}, $desc;
	}
	else {
		chop $desc, chop $desc if ($sep ne "\n");
		$info->{$tag} = $desc;
	}
}

sub _makeParamList {
	my $params = shift;
	my $p = '(';
	my $t;
	my $i = 0;

	$t = $params->[$i++],
	$i++,
	$p .= ($t=~/^[\\]?[\$\%\@\*\&]/) ? "$t, " : "$t =&gt; <i>value</i>, "
		while ($i < $#$params);

	chop $p,
	chop $p
		if (length($p) > 1);

	return "$p)";
}

sub _makeParamDesc {
	my $params = shift;
	my $p = '<dd><table border=0>';
	my ($t, $d, $sep);
	my $i = 0;

	$t = $params->[$i++],
	$d = $params->[$i++],
	$sep = ($t=~/^[\\]?[\$\%\@\*\&]/) ? ' - ' : ' =&gt; ',
	$p .= "<tr><td align=left valign=top><code>$t</code></td><td valign=top align=center>$sep</td><td align=left>$d</td></tr>\n"
		while ($i < $#$params);

	return $p . "</table></dd>\n";
}

sub _makeExportDesc {
	my ($params, $pfx) = @_;
	my $p = '';

	my %t = @$params;
	return join("\n", 
		map "<tr><td align=right valign=top><a name='$pfx$_'></a><code>$_</code></td><td align=left valign=top>$t{$_}</td></tr>", sort keys %t) . "\n";
}

sub _getSubDirs {
	my ($self, $path) = @_;
	$@ = "$path directory not found",
	return undef
		unless opendir(PATH, $path);
	push @{$self->{_dirs}}, $path; 
#
#	glob the directory for all subdirs
#
	my @files = readdir PATH;
	closedir PATH;

	foreach (@files) {
		push(@{$self->{_dirs}}, "$path/$_")
			if ($_ ne '.') && ($_ ne '..') && (-d "$path/$_");
	}
	return $self;
}

sub _makeSeeLinks {
	$_[0][-1]=~s/,\n$/\n/;
	return join("<br>\n", @{$_[0]}) . "\n";
}

sub _briefDescription {
	my $descr = shift;
	while ($descr=~/\G.*?((?:<a [^>]*>[^<]*<\/a>)|\.|\?|\!)/igcs) {
		return substr($descr, 0, $+[1]) if ($1 eq '.') || ($1 eq '?') || ($1 eq '!');
	}
	return $descr;
}

1;
