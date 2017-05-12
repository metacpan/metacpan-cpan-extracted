
package PBS::Documentation::Indexer ;

use strict ;
use warnings ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

use Pod::Parser;
use PBS::ProgressBar ;

our @ISA = qw(Exporter Pod::Parser) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.02' ;

#-------------------------------------------------------------------------------------------------------------------------------

sub GetIndex
{
return($_[0]->{__INDEX}) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub GetCapturedText
{
return($_[0]->{__CAPTURED_TEXT}) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub command 
{ 
my ($parser, $command, $paragraph, $line_num, $pod_para) = @_ ;

my $ptree = $parser->parse_text({}, $paragraph) ;
my $file  = $parser->input_file() ;

my $original_paragraph = $paragraph ;
$paragraph =~ s/\s+$// ;

$parser->{__CAPTURE_LEVEL} = 0 unless defined $parser->{__CAPTURE_LEVEL} ;

if($command =~ /^head([0-9]+)/)
	{
	my $current_level = $1 ;
	$parser->{__CAPTURE_LEVEL} = 0 if $parser->{__CAPTURE_LEVEL} >= $current_level ;
		
	$parser->{__CAPTURED_TEXT} .= "=$command $original_paragraph" if $parser->{__CAPTURE_LEVEL} ;
	
	if(defined $parser->{__CAPTURE_REGEX} && $paragraph =~ $parser->{__CAPTURE_REGEX})
		{
		$parser->{__CAPTURE_LEVEL} = $current_level ;
		$parser->{__CAPTURED_TEXT} .= "=$command $original_paragraph" ;
		}
		
	push @{$parser->{__INDEX}{$file}}, {TEXT => $paragraph, LEVEL => $current_level} ;	
	}
else
	{
	$parser->{__CAPTURED_TEXT} .= "=$command $original_paragraph" if($parser->{__CAPTURE_LEVEL}) ;
	}
}

#-------------------------------------------------------------------------------------------------------------------------------

sub verbatim 
{
my ($parser, $paragraph) = @_;
$parser->{__CAPTURED_TEXT} .= $paragraph if($parser->{__CAPTURE_LEVEL}) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

sub textblock 
{
my ($parser, $paragraph) = @_;
$parser->{__CAPTURED_TEXT} .= $paragraph if($parser->{__CAPTURE_LEVEL}) ;
}

#-------------------------------------------------------------------------------------------------------------------------------

#~ sub interior_sequence 
#~ {
#~ my ($parser, $paragraph) = @_;
#~ $parser->{__CAPTURED_TEXT} .= $paragraph if($parser->{__CAPTURE_LEVEL}) ;
#~ }

#-------------------------------------------------------------------------------------------------------------------------------

1 ;

#-------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------

package PBS::Documentation ;

use strict ;
use warnings ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;

our %EXPORT_TAGS = 
	(
	'all' => [ qw() ]
	) ;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw() ;
our $VERSION = '0.02' ;

use PBS::Output ;
use Term::ReadLine ;
use IO::String ;
use Pod::Text; ;
use Pod::Simple::Search ;

#-------------------------------------------------------------------------------

our $use_pager = 0 ;

sub DisplayPodDocumentation
{
my $pbs_config = shift ;
my $command    = shift || '' ;

eval { use Pod::Simple::Search ;} ;
die $@ if $@ ;

my @extra_paths = (@{$pbs_config->{LIB_PATH}}, @{$pbs_config->{PLUGIN_PATH}}) ;
my ($index_by_file, $index_by_section) = Generateindexes(@extra_paths) ;

my $terminal = new Term::ReadLine 'Pbs documentation search' ;

$terminal->addhistory('index') ;

do
	{
	chomp $command ;
	return if $command =~ /^q$/i || $command =~ /^quit$/i ;
	
	$terminal->addhistory($command) if $command =~ /\S/;
	
	
	if($command =~ s/^pager\s+// && defined $ENV{PAGER})
		{
		$use_pager = 1 ;
		}
	else
		{
		$use_pager = 0 ;
		}
			
	for ($command)
		{
		/^(?:p|print)\s+(.*)\s*/ and do
			{
			my $module = $1 || '' ;
			
			if(defined $module && $module ne '')
				{
				PrintModule($module, @extra_paths) ;
				last ;
				}
			} ;
			
		/^(?:o|outline)\s+(.*)\s*/ and do
			{
			my $module = $1 || '' ;
			
			if(defined $module && $module ne '')
				{
				OutlineModule($module, @extra_paths) ;
				last ;
				}
			} ;
			
		(/^(?:i|index)\s+(.*)\s*/ || /^(?:i|index)\s*/) and do
			{
			my $regex = $1 || '.' ;
			print join("\n", grep {/$regex/i} sort {uc($a) cmp uc($b)} keys %$index_by_section) . "\n" ;
			
			last ;
			} ;
			
		/^(?:s|search)\s+(.*)\s*/ and do
			{
			my $section = $1 || '.' ;
			SearchPodDocumentation($section, $index_by_section) ;
			last ;
			} ;
			
		(/^h\s*$/ || /^help\s*$/) and do
			{
			DisplayDocumentationHelp() ;
			last ;
			}
		}
	}
while(defined ($command = $terminal->readline('Documentation command > ')))
}

#-------------------------------------------------------------------------------

sub SearchPodDocumentation
{
my ($section, $index) = @_ ;

my (@found_at, $file, $section_full_name) ;

for my $matching_section (keys %{$index})
	{
	if($matching_section=~ /$section/i)
		{
		for my $section_entry (@{$index->{$matching_section}})
			{
			push @found_at, {SECTION => $matching_section, FILE => $section_entry->{FILE}} ;
			#~ print "Found '$matching_section' in file '$section_entry->{FILE}'.\n" ;
				
			$file = $section_entry->{FILE} ;
			$section_full_name = $matching_section ;
			}
		}
	}

@found_at = sort {uc($a->{SECTION}) cmp uc($b->{SECTION})} @found_at ;

my $selected_entry = SelectEntry(map{"'$_->{SECTION}' => $_->{FILE}"} @found_at) ;

if(defined $selected_entry)
	{
	$section_full_name = $found_at[$selected_entry]{SECTION} ;
	$file              = $found_at[$selected_entry]{FILE} ;
	}
else
	{
	undef $section ;
	undef $file ;
	}
	
if(defined $file)
	{
	my $parser = PBS::Documentation::Indexer->new(__CAPTURE_REGEX => $section_full_name);
	$parser->parse_from_file($file) ;
	
	my $fh = IO::String->new($parser->GetCapturedText() || 'none!') ;
	
	if($use_pager)
		{
		open my $out, "| $ENV{PAGER}" or die "Can't redirect to system pager: $!\n";
		print $out "In file '$file':\n" ;
		
		Pod::Text->new (alt => 1, sentence => 0, width => 78)->parse_from_filehandle($fh, $out) ;
		}
	else
		{
		my $textified_pod = IO::String->new() ;
		Pod::Text->new (alt => 1, sentence => 0, width => 78)->parse_from_filehandle($fh, $textified_pod) ;
		
		print ("In file '$file':\n", ${$textified_pod->string_ref()}) ;
		}
	}
else
	{
	print "No documentation found for section '$section'.\n" if defined $section ;
	}
}

#-------------------------------------------------------------------------------

sub OutlineModule
{
my $module_regex = shift ;
my @extra_paths = @_ ;

my $parser = PBS::Documentation::Indexer->new();

my @files = values %{Pod::Simple::Search->new->shadows(1)->limit_glob($module_regex)->survey()} ;
push @files, grep {/$module_regex/} values %{Pod::Simple::Search->new->shadows(1)->inc(0)->survey(@extra_paths)} ;
@files = sort @files ;

my $selected_entry = SelectEntry(@files) ;

if(defined $selected_entry)
	{
	my $file = $files[$selected_entry] ;
	
	print "In '$file'\n" ;
	
	eval {$parser->parse_from_file($file) ;	} ;
	print "Error in file'$file': $@" if $@ ;
	
	my ($index_by_file) = $parser->GetIndex() ;
	
	for my $level_data (@{$index_by_file->{$file}})
		{
		print '   ' x ($level_data->{LEVEL} - 1) ;
		print $level_data->{TEXT} . "\n" ;
		}
	}
}

#-------------------------------------------------------------------------------

sub PrintModule
{
my $module_regex = shift ;
my @extra_paths = @_ ;

my @files = values %{Pod::Simple::Search->new->shadows(1)->limit_glob($module_regex)->survey()} ;
push @files, grep {/$module_regex/} values %{Pod::Simple::Search->new->shadows(1)->inc(0)->survey(@extra_paths)} ;
@files = sort @files ;

my $selected_entry = SelectEntry(@files) ;

if(defined $selected_entry)
	{
	my $file = $files[$selected_entry] ;
	
	open my $fh, '<', $file or die "Can't open '$file': $!\n";
	
	if($use_pager)
		{
		open my $out, "| $ENV{PAGER}" or die "Can't redirect to system pager$!\n";
		print $out "In file '$file':\n" ;
		
		Pod::Text->new (alt => 1, sentence => 0, width => 78)->parse_from_filehandle($fh, $out) ;
		}
	else
		{
		open my $out, '>', \my $textified_pod or die "Can't redirect to scalar output: $!\n";
		Pod::Text->new (alt => 1, sentence => 0, width => 78)->parse_from_filehandle($fh, $out) ;
		print ("In file '$file':\n", $textified_pod) ;
		}
	}
}

#-------------------------------------------------------------------------------

sub DisplayDocumentationHelp
{
print <<EOH ;

   [pager] s[earch] section => search for a section.
				'section_name' is a perl regex.

   i[ndex] [regex]          => display an index of all the PBS help sections.
				'regex' is a perl regex.

   o[utline] module         => prints an outline of a module documentation.
				ex: 'o PBS::Build::Forked'.
			   
   [pager] p[rint] module   => prints a module pod.
   
   q[uit]                   => to quit.
   
   
   * optional 'pager' redirects output to the system pager.

EOH
}

#-------------------------------------------------------------------------------

sub SelectEntry
{
my @entries = @_ ;
my $selection ;

my $terminal ;
{
local $SIG{'__WARN__'} = sub {} ;
$terminal = new Term::ReadLine 'Pbs documentation search' ;
}

if(@entries > 1)
	{
	my $index = 0 ;
	
	for my $entry (@entries)
		{
		printf "%3d: $entry\n", $index ;
		$index++ ;
		}
		
	if(defined ($selection = $terminal->readline('Select section > ')))
		{
		chomp $selection ;
		if($selection =~ /^[0-9]+$/)
			{
			if($selection < @entries)
				{
				return($selection) ;
				}
			else
				{
				return(undef) ;
				}
			}
		else
			{
			return(undef) ;
			}
		}
	else
		{
		return(undef) ;
		}
	}
else
	{
	if(@entries)
		{
		return(0) ;
		}
	else
		{
		return(undef) ;
		}
	}
}

#-------------------------------------------------------------------------------

sub Generateindexes
{
my @extra_paths = @_ ;

my $parser = PBS::Documentation::Indexer->new();

print "Searching and indexing pod sections.\n" ;

my (undef, $path2name_pbs) = Pod::Simple::Search->new->limit_glob('PBS::*')->survey() ;
my (undef, $path2name_extra) = Pod::Simple::Search->new->shadows(1)->inc(0)->survey(@extra_paths) ;

my @files = (keys %$path2name_pbs, keys %$path2name_extra) ;

my $progress_bar = PBS::ProgressBar->new
		({
		  count => scalar(grep {/\.pm$/} @files)
		});

my $file_index = 1 ;

for my $file (sort grep {/\.pm$/} @files)
	{
	eval {$parser->parse_from_file($file) ;	} ;
	print "Skipping '$file': $@" if $@ ;
	
	$progress_bar->update($file_index) ;
	$file_index++ ;
	}

print "\n" ;

my $index_by_file = $parser->GetIndex() ;

my $index_by_section ;
for my $file_entry (keys %$index_by_file)
	{
	for my $level_data (@{$index_by_file->{$file_entry}})
		{
		push @{$index_by_section->{$level_data->{TEXT}}},
			{
			  LEVEL => $level_data->{LEVEL}
			, FILE  => $file_entry
			} ;
		}
	}

return($index_by_file, $index_by_section) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Documentation  -

=head1 SYNOPSIS

  pbs -d 

=head1 DESCRIPTION

=head2 EXPORT

Nothing.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
