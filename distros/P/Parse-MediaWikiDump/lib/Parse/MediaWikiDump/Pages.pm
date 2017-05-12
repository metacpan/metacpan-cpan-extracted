package Parse::MediaWikiDump::Pages;

our $VERSION = '1.0.4';

use base qw(Parse::MediaWikiDump::Revisions);

use strict;
use warnings;
use Scalar::Util qw(weaken);

#the only difference between this class and ::Revisions
#is that this class enforces a single revision per each
#page node
sub new_accumulator_engine {
	my ($self) = @_;
	
	weaken($self);
	
	my $f = Parse::MediaWikiDump::XML::Accumulator->new;
	my $store_siteinfo = $self->{SITEINFO};
	my $store_page = $self->{PAGE_LIST};
	
	my $root = $f->root;
	my $mediawiki = $f->node('mediawiki', Start => \&handle_mediawiki_node);
	
	#stuff for siteinfo
	my $siteinfo = $f->node('siteinfo', End => sub { %$store_siteinfo = %{ $_[1] } } );
	my $sitename = $f->textcapture('sitename');
	my $base = $f->textcapture('base');
	my $generator = $f->textcapture('generator');
	my $case = $f->textcapture('case');
	my $namespaces = $f->node('namespaces', Start => sub { $_[1]->{namespaces} = []; } );
	my $namespace = $f->node('namespace', Character => \&save_namespace_node);
	
	#stuff for page entries
	my $page = $f->node('page', Start => sub { $_[0]->accumulator( {} ) } );
	my $title = $f->textcapture('title');
	my $id = $f->textcapture('id');
	my $revision = $f->node('revision', 
		Start => sub { $_[1]->{minor} = 0 }, 
		End => sub { 
			if (defined($_[1]->{seen_revision})) {
				$self->{DIE_REQUESTED} = "only one revision per page is allowed";
			}
			
			$_[1]->{seen_revision} = 1;
			
			push(@$store_page, { %{ $_[1] } } );
		} );
	my $rev_id = $f->textcapture('id', 'revision_id');
	my $minor = $f->node('minor', Start => sub { $_[1]->{minor} = 1 } );
	my $time = $f->textcapture('timestamp');
	my $contributor = $f->node('contributor');
	my $username = $f->textcapture('username');
	my $ip = $f->textcapture('ip', 'userip');
	my $contrib_id = $f->textcapture('id', 'userid');
	my $comment = $f->textcapture('comment');
	my $text = $f->textcapture('text');
	my $restr = $f->textcapture('restrictions');
	
	#put together the tree
	$siteinfo->add_child($sitename, $base, $generator, $case, $namespaces);
	  $namespaces->add_child($namespace);
	
	$page->add_child($title, $id, $revision, $restr);
	  $revision->add_child($rev_id, $time, $contributor, $minor, $comment, $text);
	    $contributor->add_child($username, $ip, $contrib_id);
	
	$mediawiki->add_child($siteinfo, $page);
	$root->add_child($mediawiki);
	
	my $engine = $f->engine($root, {});

	return $engine;	
}

sub handle_mediawiki_node {
	return Parse::MediaWikiDump::Revisions::handle_mediawiki_node(@_);
}

sub save_namespace_node {
	return Parse::MediaWikiDump::Revisions::save_namespace_node(@_);
}

1;

__END__
=head1 NAME

Parse::MediaWikiDump::Pages - Object capable of processing dump files with a single revision per article

=head1 ABOUT

This object is used to access the metadata associated with a MediaWiki instance and provide an iterative interface
for extracting the individual articles out of the same. This module does not allow more than one revision
for each specific article; to parse a comprehensive dump file use the Parse::MediaWikiDump::Revisions object. 

=head1 SYNOPSIS
  
  $pmwd = Parse::MediaWikiDump->new;
  $pages = $pmwd->pages('pages-articles.xml');
  $pages = $pmwd->pages(\*FILEHANDLE);
  
  #print the title and id of each article inside the dump file
  while(defined($page = $pages->next)) {
    print "title '", $page->title, "' id ", $page->id, "\n";
  }

=head1 STATUS

=head1 STATUS

This software is being RETIRED - MediaWiki::DumpFile is the official successor to
Parse::MediaWikiDump and includes a compatibility library called MediaWiki::DumpFile::Compat
that is 100% API compatible and is a near perfect standin for this module. It is faster
in all instances where it counts and is actively maintained. Any undocumented deviation
of MediaWiki::DumpFile::Compat from Parse::MediaWikiDump is considered a bug and will
be fixed. 

=head1 METHODS

=over 4

=item $pages->new

Open the specified MediaWiki dump file. If the single argument to this method
is a string it will be used as the path to the file to open. If the argument
is a reference to a filehandle the contents will be read from the filehandle as
specified. 

=item $pages->next

Returns an instance of the next available Parse::MediaWikiDump::page object or returns undef
if there are no more articles left.

=item $pages->version

Returns a plain text string of the dump file format revision number

=item $pages->sitename

Returns a plain text string that is the name of the MediaWiki instance.

=item $pages->base

Returns the URL to the instances main article in the form of a string.

=item $pages->generator

Returns a string containing 'MediaWiki' and a version number of the instance that dumped this file.
Example: 'MediaWiki 1.14alpha'

=item $pages->case

Returns a string describing the case sensitivity configured in the instance.

=item $pages->namespaces

Returns a reference to an array of references. Each reference is to another array with the first
item being the unique identifier of the namespace and the second element containing a string
that is the name of the namespace.

=item $pages->namespaces_names

Returns an array reference the array contains strings of all the namespaces each as an element. 

=item $pages->current_byte

Returns the number of bytes that has been processed so far

=item $pages->size

Returns the total size of the dump file in bytes. 

=back

=head2 Scan an article dump file for double redirects that exist in the most recent article revision

  #!/usr/bin/perl
  
  #progress information goes to STDERR, a list of double redirects found
  #goes to STDOUT
  
  binmode(STDOUT, ":utf8");
  binmode(STDERR, ":utf8");
  
  use strict;
  use warnings;
  use Parse::MediaWikiDump;
  
  my $file = shift(@ARGV);
  my $pmwd = Parse::MediaWikiDump->new;
  my $pages;
  my $page;
  my %redirs;
  my $artcount = 0;
  my $file_size;
  my $start = time;
  
  if (defined($file)) {
  	$file_size = (stat($file))[7];
  	$pages = $pmwd->pages($file);
  } else {
  	print STDERR "No file specified, using standard input\n";
  	$pages = $pmwd->pages(\*STDIN);
  }
  
  #the case of the first letter of titles is ignored - force this option
  #because the other values of the case setting are unknown
  die 'this program only supports the first-letter case setting' unless
  	$pages->case eq 'first-letter';
  
  print STDERR "Analyzing articles:\n";
  
  while(defined($page = $pages->next)) {
    update_ui() if ++$artcount % 500 == 0;
  
    #main namespace only
    next unless $page->namespace eq '';
    next unless defined($page->redirect);
  
    my $title = case_fixer($page->title);
    #create a list of redirects indexed by their original name
    $redirs{$title} = case_fixer($page->redirect);
  }
  
  my $redir_count = scalar(keys(%redirs));
  print STDERR "done; searching $redir_count redirects:\n";
  
  my $count = 0;
  
  #if a redirect location is also a key to the index we have a double redirect
  foreach my $key (keys(%redirs)) {
    my $redirect = $redirs{$key};
  
    if (defined($redirs{$redirect})) {
      print "$key\n";
      $count++;
    }
  }
  
  print STDERR "discovered $count double redirects\n";
  
  #removes any case sensativity from the very first letter of the title
  #but not from the optional namespace name
  sub case_fixer {
    my $title = shift;
  
    #check for namespace
    if ($title =~ /^(.+?):(.+)/) {
      $title = $1 . ':' . ucfirst($2);
    } else {
      $title = ucfirst($title);
    }
  
    return $title;
  }
  
  sub pretty_bytes {
    my $bytes = shift;
    my $pretty = int($bytes) . ' bytes';
  
    if (($bytes = $bytes / 1024) > 1) {
      $pretty = int($bytes) . ' kilobytes';
    }
  
    if (($bytes = $bytes / 1024) > 1) {
      $pretty = sprintf("%0.2f", $bytes) . ' megabytes';
    }
  
    if (($bytes = $bytes / 1024) > 1) {
      $pretty = sprintf("%0.4f", $bytes) . ' gigabytes';
    }
  
    return $pretty;
  }
  
  sub pretty_number {
    my $number = reverse(shift);
    $number =~ s/(...)/$1,/g;
    $number = reverse($number);
    $number =~ s/^,//;
  
    return $number;
  }
  
  sub update_ui {
    my $seconds = time - $start;
    my $bytes = $pages->current_byte;
  
    print STDERR "  ", pretty_number($artcount),  " articles; "; 
    print STDERR pretty_bytes($bytes), " processed; ";
  
    if (defined($file_size)) {
      my $percent = int($bytes / $file_size * 100);
  
      print STDERR "$percent% completed\n"; 
    } else {
      my $bytes_per_second = int($bytes / $seconds);
      print STDERR pretty_bytes($bytes_per_second), " per second\n";
    }
  }

=head1 LIMITATIONS

=head2 Version 0.4

This class was updated to support version 0.4 dump files from
a MediaWiki instance but it does not currently support any of
the new information available in those files. 