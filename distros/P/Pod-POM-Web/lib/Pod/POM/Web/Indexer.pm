package Pod::POM::Web::Indexer;

use strict;
use warnings;
no warnings 'uninitialized';

use Pod::POM;
use List::Util      qw/min max/;
use List::MoreUtils qw/part/;
use Time::HiRes     qw/time/;
use Search::Indexer 0.75;
use BerkeleyDB;

use parent 'Pod::POM::Web';
our $VERSION = 1.22;

#----------------------------------------------------------------------
# Initializations
#----------------------------------------------------------------------

my $defaut_max_size_for_indexing = 300 << 10; # 300K

my $ignore_dirs = qr[
      auto | unicore | DateTime/TimeZone | DateTime/Locale    ]x;

my $ignore_headings = qr[
      SYNOPSIS | DESCRIPTION | METHODS   | FUNCTIONS |
      BUGS     | AUTHOR      | SEE\ ALSO | COPYRIGHT | LICENSE ]x;

(my $index_dir = __FILE__) =~ s[Indexer\.pm$][index];

my $id_regex = qr/(?![0-9])       # don't start with a digit
                  \w\w+           # start with 2 or more word chars ..
                  (?:::\w+)*      # .. and  possibly ::some::more::components
                 /x; 

my $wregex   = qr/(?:                  # either a Perl variable:
                    (?:\$\#?|\@|\%)    #   initial sigil
                    (?:                #     followed by
                       $id_regex       #       an id
                       |               #     or
                       \^\w            #       builtin var with '^' prefix
                       |               #     or
                       (?:[\#\$](?!\w))#       just '$$' or '$#'
                       |               #     or
                       [^{\w\s\$]      #       builtin vars with 1 special char
                     )
                     |                 # or
                     $id_regex         # a plain word or module name
                 )/x;


my @stopwords = (
  'a' .. 'z', '_', '0' .. '9',
  qw/__data__ __end__ $class $self
     above after all also always an and any are as at
     be because been before being both but by
     can cannot could
     die do don done
     defined do does doesn
     each else elsif eq
     for from
     ge gt
     has have how
     if in into is isn it item its
     keys
     last le lt
     many may me method might must my
     ne new next no nor not
     of on only or other our
     package perl pl pm pod push
     qq qr qw
     ref return
     see set shift should since so some something sub such
     text than that the their them then these they this those to tr
     undef unless until up us use used uses using
     values
     was we what when which while will with would
     you your/
);


#----------------------------------------------------------------------
# RETRIEVING
#----------------------------------------------------------------------


sub fulltext {
  my ($self, $search_string) = @_;

  my $indexer = eval {
    new Search::Indexer(dir       => $index_dir,
                        wregex    => $wregex,
                        preMatch  => '[[',
                        postMatch => ']]');
  } or die <<__EOHTML__;
No fulltext index found ($@). 
<p>
Please ask your system administrator to run the 
command 
</p>
<pre>
  perl -MPod::POM::Web::Indexer -e "Pod::POM::Web::Indexer->new->index"
</pre>

Indexing may take about half an hour and will use about
10 MB on your hard disk.
__EOHTML__



  my $lib = "$self->{root_url}/lib";
  my $html = <<__EOHTML__;
<html>
<head>
  <link href="$lib/GvaScript.css" rel="stylesheet" type="text/css">
  <link href="$lib/PodPomWeb.css" rel="stylesheet" type="text/css">
  <style>
    .src {font-size:70%; float: right}
    .sep {font-size:110%; font-weight: bolder; color: magenta;
          padding-left: 8px; padding-right: 8px}
    .hl  {background-color: lightpink}
  </style>
</head>
<body>
__EOHTML__


  # force Some::Module::Name into "Some::Module::Name" to prevent 
  # interpretation of ':' as a field name by Query::Parser
  $search_string =~ s/(^|\s)([\w]+(?:::\w+)+)(\s|$)/$1"$2"$3/g;

  my $result = $indexer->search($search_string, 'implicit_plus');

  my $killedWords = join ", ", @{$result->{killedWords}};
  $killedWords &&= " (ignoring words : $killedWords)";
  my $regex = $result->{regex};

  my $scores = $result->{scores};
  my @doc_ids = sort {$scores->{$b} <=> $scores->{$a}} keys %$scores;

  my $nav_links = $self->paginate_results(\@doc_ids);

  $html .= "<b>Fulltext search</b> for '$search_string'$killedWords<br>"
         . "$nav_links<hr>\n";

  $self->_tie_docs(DB_RDONLY);

  foreach my $id (@doc_ids) {
    my ($mtime, $path, $description) = split "\t", $self->{_docs}{$id};
    my $score     = $scores->{$id};
    my @filenames = $self->find_source($path);
    my $buf = join "\n", map {$self->slurp_file($_)} @filenames;

    my $excerpts = $indexer->excerpts($buf, $regex);
    foreach (@$excerpts) {
      s/&/&amp;/g,  s/</&lt;/g, s/>/&gt;/g; # replace entities
      s/\[\[/<span class='hl'>/g, s/\]\]/<\/span>/g; # highlight
    }
    $excerpts = join "<span class='sep'>/</span>", @$excerpts;
    $html .= <<__EOHTML__;
<p>
<a href="$self->{root_url}/source/$path" class="src">source</a>
<a href="$self->{root_url}/$path">$path</a>
(<small>$score</small>) <em>$description</em>
<br>
<small>$excerpts</small>
</p>
__EOHTML__
  }

  $html .= "<hr>$nav_links\n";
  return $self->send_html($html);
}



sub paginate_results {
  my ($self, $doc_ids_ref) = @_;

  my $n_docs       = @$doc_ids_ref;
  my $count        = $self->{params}{count} || 50;
  my $start_record = $self->{params}{start} || 0;
  my $end_record   = min($start_record + $count - 1, $n_docs - 1);
  @$doc_ids_ref    = @$doc_ids_ref[$start_record ... $end_record];
  my $prev_idx     = max($start_record - $count, 0);
  my $next_idx     = $start_record + $count;
  my $base_url     = "?source=fulltext&search=$self->{params}{search}";
  my $prev_link
    = $start_record > 0 ? uri_escape("$base_url&start=$prev_idx") : "";
  my $next_link
    = $next_idx < $n_docs ? uri_escape("$base_url&start=$next_idx") : "";
  $_ += 1 for $start_record, $end_record;
  my $nav_links = "";
  $nav_links .= "<a href='$prev_link'>[Previous &lt;&lt;]</a> " if $prev_link;
  $nav_links .= "Results <b>$start_record</b> to <b>$end_record</b> "
              . "from <b>$n_docs</b>";
  $nav_links .= " <a href='$next_link'>[&gt;&gt; Next]</a> " if $next_link;
  return $nav_links;
}





sub modlist { # called by Ajax
  my ($self, $search_string) = @_;

  $self->_tie_docs(DB_RDONLY);

  length($search_string) >= 2 or die "module_list: arg too short";
  my $regex = qr/^\d+\t(\Q$search_string\E[^\t]*)/i;

  my @modules;
  foreach my $val (values %{$self->{_docs}}) {
    $val =~ $regex or next;
    (my $module = $1) =~ s[/][::]g;
    push @modules, $module;
  }

  my $json_names = "[" . join(",", map {qq{"$_"}} sort @modules) . "]";
  return $self->send_content({content   => $json_names,
                              mime_type => 'application/x-json'});
}


sub get_abstract {  # override from Web.pm
  my ($self, $path) = @_;
  if (!$self->{_path_to_descr}) {
    eval {$self->_tie_docs(DB_RDONLY); 1} 
      or return; # database not found
    $self->{_path_to_descr} = { 
      map {(split /\t/, $_)[1,2]} values %{$self->{_docs}} 
     };
  }
  my $description = $self->{_path_to_descr}->{$path} or return;
  (my $abstract = $description) =~ s/^.*?-\s*//;
  return $abstract;
}


#----------------------------------------------------------------------
# INDEXING
#----------------------------------------------------------------------

sub import { # export the "index" function if called from command-line
  my $class = shift;
  my ($package, $filename) = caller;

  no strict 'refs';
  *{'main::index'} = sub {$class->new->index(@_)} 
    if $package eq 'main' and $filename eq '-e';
}


sub index {
  my ($self, %options) = @_;

  # check invalid options
  die "invalid option : $_" 
    if grep {!/^-(from_scratch|max_size|positions)$/} keys %options;

  # make sure index dir exists
  -d $index_dir or mkdir $index_dir or die "mkdir $index_dir: $!";

  # if -from_scratch, throw away old index 
  if ($options{-from_scratch}) {
    unlink $_ or die "unlink $_ : $!" foreach glob("$index_dir/*.bdb");
  }

  # store global info for indexing methods
  $self->{_seen_path}             = {};
  $self->{_last_doc_id}           = 0;
  $self->{_max_size_for_indexing} = $options{-max_size}
                                 || $defaut_max_size_for_indexing;

  # tie to docs.bdb, storing {$doc_id => "$mtime\t$pathname\t$description"}
  $self->_tie_docs(DB_CREATE);

  # build in-memory reverse index of info contained in %{$self->{_docs}}
  $self->{_max_doc_id}     = 0;
  $self->{_previous_index} = {};
  while (my ($id, $doc_descr) = each %{$self->{_docs}}) {
    $self->{_max_doc_id} = max($id, $self->{_max_doc_id});
    my ($mtime, $path, $description) = split /\t/, $doc_descr;
    $self->{_previous_index}{$path}
      = {id => $id, mtime => $mtime, description => $description};
  }

  # open the index
  $self->{_indexer} = new Search::Indexer(dir       => $index_dir,
                                          writeMode => 1,
                                          positions => $options{-positions},
                                          wregex    => $wregex,
                                          stopwords => \@stopwords);

  # main indexing loop
  $self->index_dir($_) foreach @Pod::POM::Web::search_dirs; 

  $self->{_indexer} = $self->{_docs} = undef;
}


sub index_dir {
  my ($self, $rootdir, $path) = @_;
  return if $path =~ /$ignore_dirs/;

  my $dir = $rootdir;
  if ($path) {
    $dir .= "/$path";
    return print STDERR "SKIP DIR $dir (already in \@INC)\n"
      if grep {m[^\Q$dir\E]} @Pod::POM::Web::search_dirs;
  }

  chdir $dir or return print STDERR "SKIP DIR $dir (chdir $dir: $!)\n";

  print STDERR "DIR $dir\n";
  opendir my $dh, "." or die $^E;
  my ($dirs, $files) = part { -d $_ ? 0 : 1} grep {!/^\./} readdir $dh;
  $dirs ||= [], $files ||= [];
  closedir $dh;

  my %extensions;
  foreach my $file (sort @$files) {
    next unless $file =~ s/\.(pm|pod)$//; 
    $extensions{$file}{$1} = 1;
  }

  foreach my $base (keys %extensions) {
    $self->index_file($path, $base, $extensions{$base});
  }

  my @subpaths = map {$path ? "$path/$_" : $_} @$dirs;
  $self->index_dir($rootdir, $_) foreach @subpaths;
}


sub index_file {
  my ($self, $path, $file, $has_ext) = @_;

  my $fullpath = $path ? "$path/$file" : $file;
  return print STDERR "SKIP $fullpath (shadowing)\n"
    if $self->{_seen_path}{$fullpath};

  $self->{_seen_path}{$fullpath} = 1;
  my $max_mtime = 0;
  my ($size, $mtime, @filenames);
 EXT:
  foreach my $ext (qw/pm pod/) { 
    next EXT unless $has_ext->{$ext};
    my $filename = "$file.$ext";
    ($size, $mtime) = (stat $filename)[7, 9] or die "stat $filename: $!";
    $size < $self->{_max_size_for_indexing} or 
      print STDERR "$filename too big ($size bytes), skipped " and next EXT;
    $mtime   = max($max_mtime, $mtime);
    push @filenames, $filename;
  }

  if ($mtime <= $self->{_previous_index}{$fullpath}{mtime}) {
    return print STDERR "SKIP $fullpath (index up to date)\n";
  }

  if (@filenames) {
    my $old_doc_id = $self->{_previous_index}{$fullpath}{id};
    my $doc_id     = $old_doc_id || ++$self->{_max_doc_id};

    print STDERR "INDEXING $fullpath (id $doc_id) ... ";

    my $t0 = time;
    my $buf = join "\n", map {$self->slurp_file($_)} @filenames;
    my ($description) = ($buf =~ /^=head1\s*NAME\s*(.*)$/m);
    $description ||= '';
    $description =~ s/\t/ /g;
    $buf =~ s/^=head1\s+($ignore_headings).*$//m; # remove full line of those
    $buf =~ s/^=(head\d|item)//mg; # just remove command of =head* or =item
    $buf =~ s/^=\w.*//mg;          # remove full line of all other commands 

    if ($old_doc_id) {
      # Here we should remove the old document from the index. But
      # we no longer have the document source! So we cheat with the current
      # doc buffer, hoping that most words are similar. This step sounds
      # ridiculous but is necessary to avoid having twice the same
      # doc listed twice in inverted lists.
      $self->{_indexer}->remove($old_doc_id, $buf);
    }

    $self->{_indexer}->add($doc_id, $buf);
    my $interval = time - $t0;
    printf STDERR "%0.3f s.", $interval;

    $self->{_docs}{$doc_id} = "$mtime\t$fullpath\t$description";
  }

  print STDERR "\n";

}


#----------------------------------------------------------------------
# UTILITIES
#----------------------------------------------------------------------

sub _tie_docs {
  my ($self, $mode) = @_;

  # tie to docs.bdb, storing {$doc_id => "$mtime\t$pathname\t$description"}
  tie %{$self->{_docs}}, 'BerkeleyDB::Hash', 
      -Filename => "$index_dir/docs.bdb", 
      -Flags    => $mode
	or die "open $index_dir/docs.bdb : $^E $BerkeleyDB::Error";
}



sub uri_escape { 
  my $uri = shift;
  $uri =~ s{([^;\/?:@&=\$,A-Za-z0-9\-_.!~*'()])}
           {sprintf("%%%02X", ord($1))         }ge;
  return $uri;
}


1;

__END__

=head1 NAME

Pod::POM::Web::Indexer - fulltext search for Pod::POM::Web

=head1 SYNOPSIS

  perl -MPod::POM::Web::Indexer -e index

=head1 DESCRIPTION

Adds fulltext search capabilities to the 
L<Pod::POM::Web|Pod::POM::Web> application.
This requires L<Search::Indexer|Search::Indexer> to be installed.

Queries may include plain terms, "exact phrases", 
'+' or '-' prefixes, boolean operators and parentheses.
See L<Search::QueryParser|Search::QueryParser> for details.


=head1 METHODS

=head2 index

    Pod::POM::Web::Indexer->new->index(%options)

Walks through directories in C<@INC> and indexes 
all C<*.pm> and C<*.pod> files, skipping shadowed files
(files for which a similar loading path was already
found in previous C<@INC> directories), and skipping
files that are too big.

Default indexing is incremental : files whose modification
time has not changed since the last indexing operation will
not be indexed again.

Options can be 

=over

=item -max_size

Size limit (in bytes) above which files will not be indexed.
The default value is 300K. 
Files of size above this limit are usually not worth
indexing because they only contain big configuration tables
(like for example C<Module::CoreList> or C<Unicode::Charname>).

=item -from_scratch

If true, the previous index is deleted, so all files will be freshly
indexed. If false (the default), indexation is incremental, i.e. files
whose modification time has not changed will not be re-indexed.

=item -positions

If true, the indexer will also store word positions in documents, so
that it can later answer to "exact phrase" queries. 

So if C<-positions> are on, a search for C<"more than one way"> will
only return documents which contain that exact sequence of contiguous
words; whereas if C<-positions> are off, the query is equivalent to
C<more AND than AND one AND way>, i.e. it returns all documents which
contain these words anywhere and in any order.

The option is off by default, because it requires much more disk
space, and does not seem to be very relevant for searching
Perl documentation.

=back

The C<index> function is exported into the C<main::> namespace if perl
is called with the C<-e> flag, so that you can write

  perl -MPod::POM::Web::Indexer -e index


=head1 PERFORMANCES

On my machine, indexing a module takes an average of 0.2 seconds, 
except for some long and complex sources (this is why sources
above 300K are ignored by default, see options above).
Here are the worst figures (in seconds) :

  Date/Manip            39.655
  DBI                   30.73
  Pod/perlfunc          29.502
  Module/CoreList       27.287
  CGI                   16.922
  Config                13.445
  CPAN                  12.598
  Pod/perlapi           10.906
  CGI/FormBuilder        8.592
  Win32/TieRegistry      7.338
  Spreadsheet/WriteExcel 7.132
  Pod/perldiag           5.771
  Parse/RecDescent       5.405
  Bit/Vector             4.768

The index will be stored in an F<index> subdirectory 
under the module installation directory.
The total index size should be around 10MB if C<-positions> are off, 
and between 30MB and 50MB if C<-positions> are on, depending on
how many modules are installed.


=head1 TODO

 - highlights in shown documents
 - paging

=cut

