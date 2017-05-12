package PBS::Graph::Html ;
use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;

use Data::Dumper ;
use Data::TreeDumper ;
use File::Path ;

use PBS::Output ;
use PBS::Constants ;
use PBS::GraphViz;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

sub GenerateHtmlGraph
{
my ($html_data) = @_ ;

PrintInfo("Generating html graph documentation.\n") ;

my $directory_name = $html_data->{DIRECTORY} ;
mkpath($directory_name) ;
	
open(PNG, ">", "$directory_name/graph.png") or die qq[Can't open $directory_name/graph.png : $!] ;
print PNG $html_data->{PNG} ;
delete $html_data->{PNG} ;
close(PNG) ;

my $frame_link = '' ;
my $graph_file_name = '' ;

if($html_data->{USE_FRAME})
	{
	$frame_link = ' target="data" ' ;
	
	# generate empty page and graph_frame
	open(EMPTY, ">", "$directory_name/empty.html") or die qq[Can't open $directory_name/empty.html : $!] ;
	print EMPTY "<html></html>\n" ;
	close(EMPTY) ;
	
	open(FRAME, ">", "$directory_name/index.html") or die qq[Can't open $directory_name/graph_frame.html : $!] ;
	print FRAME <<EOH ;
<html>
<frameset cols="60%,40%">
  <frame src="graph.html">
  <frame src="empty.html" name="data">
</frameset>
</html>
EOH
	close(FRAME) ;
	
	$graph_file_name = "$directory_name/graph.html"
	}
else
	{
	$graph_file_name = "$directory_name/index.html" ;
	}

$html_data->{CMAP} =~ s/(alt|title)="(\\.|[^"])*"/$frame_link/g ;

open(HTML, ">", $graph_file_name) or die qq[Can't open $directory_name/graph.html : $!] ;

print HTML <<EOH ;
<html>

<IMG SRC="graph.png" USEMAP=#mainmap>

<MAP NAME="mainmap">
$html_data->{CMAP}
</MAP>

</html>
EOH

close(HTML) ;

# command line, environement variables, prf  are still missing from the generated HTML.

# Pbs config
for my $pbs_config_name (keys %{$html_data->{PBS_CONFIG}})
	{
	my $pbs_config = $html_data->{PBS_CONFIG}{$pbs_config_name} ;
	
	open(HTML, ">", "$directory_name/$pbs_config->{FILE}") or die qq[Can't open $directory_name/$pbs_config->{FILE} : $!] ;
	
	my $body = <<EOH ;
#-------------------
# PBS configuration
#-------------------

PACKAGE :        $pbs_config->{DATA}{PACKAGE} ($pbs_config->{DATA}{LOAD_PACKAGE})
PARENT_PACKAGE : @{[$pbs_config->{DATA}{PARENT_PACKAGE} || 'undef']}
PBSFILE:         $pbs_config->{DATA}{PBSFILE}

#-------------------
EOH
	
	$body .= Data::TreeDumper::TreeDumper
					(
					$pbs_config->{DATA}
					,	{
						  FILTER      => \&Data::TreeDumper::HashKeysSorter
						, START_LEVEL => 1
						, USE_ASCII   => 1
						, TITLE       => "All Config :\n"
						}
					) ;
	$body =~ s/ /&nbsp;/g  ;
	$body =~ s/\n/<br>\n/g  ;
	
	print HTML "<html><tt>$body</tt>\n</html>\n" ;
	close(HTML) ;
	}
	
# config
for my $config_name (keys %{$html_data->{CONFIG}})
	{
	my $config = $html_data->{CONFIG}{$config_name} ;
	
	open(HTML, ">", "$directory_name/$config->{FILE}") or die qq[Can't open $directory_name/$config->{FILE} : $!] ;
	
	my $body = <<EOH ;
#---------------
# Configuration
#---------------
EOH
	
	for my $config_entry (sort keys %{$config->{DATA}})
		{
		my $value = defined $config->{DATA}{$config_entry} ? $config->{DATA}{$config_entry} : 'undef' ;
		$body .= "$config_entry = $value\n"  ;
		}
		
	$body =~ s/\n/<br>\n/g  ;
	$body =~ s/ /&nbsp;/g  ;
	
	print HTML "<html><tt>\n$body\n</tt></html>\n" ;
	close(HTML) ;
	}

#---------------
# nodes
#---------------
for my $node_name (keys %{$html_data->{NODES}})
	{
	my $node_data = $html_data->{NODES}{$node_name} ;
	my $node = $node_data->{DATA} ;
	
	open(HTML, ">", "$directory_name/$node_data->{FILE}") or die qq[Can't open $directory_name/$node_data->{FILE} : $!] ;
	
	my $build_name = "($node->{__BUILD_NAME})" ;
	$build_name = '' if exists $node->{__VIRTUAL} ;
	
	my $body = <<EOH ;

Node: $node->{__NAME} $build_name

@{[GetInsertionData($node)]}

#----------------------------------

Dependencies: @{[GetDependencies($node)]}
Package     : @{[$node->{__PACKAGE} || '']}
Depended at : $node->{__DEPENDED_AT}
Linked      : @{[$node->{__LINKED} || '0']}
EOH
	
	my $triggers ;
	if($node->{__TRIGGERED})
		{
		$triggers = Data::TreeDumper::TreeDumper
						(
						$node->{__TRIGGERED}
						,	{
							  FILTER      => \&Data::TreeDumper::HashKeysSorter
							, START_LEVEL => 1
							, USE_ASCII   => 1
							, TITLE       => "Triggered   :\n"
							}
						) ;
		}
	else
		{
		$triggers =  "Triggered   : No\n"
		}
	
	$body .= $triggers ;
	$body =~ s/ /&nbsp;/g  ;
	$body =~ s/\n/<br>\n/g  ;
	
	print HTML "<html><tt>\n$body\n</tt></html>\n" ;
	close(HTML) ;
	}
}

#-------------------------------------------------------------------------------

sub GetDependencies
{
my $node = shift ;

my $dependencies_text ;

for my $rule_data (@{$node->{__MATCHING_RULES}})
	{
	my $rule_number = $rule_data->{RULE}{INDEX} ;
	my $rule        = $rule_data->{RULE}{DEFINITIONS}[$rule_number] ;
	my $rule_info   = "'$rule->{NAME}' @ $rule->{FILE}:$rule->{LINE}" ;
	
	for my $dependency (@{$rule_data->{DEPENDENCIES}})
		{
		next if $dependency->{NAME} =~ /^__/ ;
		
		$dependencies_text .= "    $dependency->{NAME} inserted by rule: $rule_info\n" ;
		}
	}

return($dependencies_text ? "\n$dependencies_text" : 'None.');
} ;

#-------------------------------------------------------------------------------

sub GetInsertionData
{
my $node = shift ;

my $insertion_data = $node->{__INSERTED_AT} ;

if(exists $insertion_data->{ORIGINAL_INSERTION_DATA})
	{
	"Inserted by rule '$insertion_data->{ORIGINAL_INSERTION_DATA}{INSERTION_RULE}'"
	. "\nDepended in subpbs file '$insertion_data->{INSERTION_FILE}'.";
	}
else
	{
	if(exists $insertion_data->{INSERTION_RULE})
		{
		"Inserted by rule '$insertion_data->{INSERTION_RULE}'.";
		}
	else
		{
		'Inserted by PBS.'
		}
	}
} ;

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Graph::Html -

=head1 DESCRIPTION

Helper module to B<PBS::Graph>. I<GenerateHtmlGraph> generates a HTML document with a dependency graph linked to a set 
of HTML (text) files containing pertinent information about the node that was clicked in the main HTML document (index.html).
It can also add a frame to the main document so the graph and the textual inforamtion are displayed simulteanously.

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

	B<PBS::Graph>.
	B<--gtg> and B<--gtg_tn>
	B<--gtg_html>.
	B<--gtg_html_frame>.

=cut
