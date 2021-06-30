#======================================================================
package Pod::POM::Web::Indexer;
#======================================================================

use strict;
use warnings;

use Pod::POM;
use Pod::POM::Web::Util qw/slurp_native_or_utf8/;
use List::Util          qw/min max/;
use List::MoreUtils     qw/part/;
use Search::Indexer 1.0;
use Path::Tiny          qw/path/;
use Params::Validate    qw/validate_with SCALAR BOOLEAN ARRAYREF/;
use Time::HiRes         qw/time/;
use IO::Handle;         # for the 'autoflush' method

our $VERSION = 1.23;

#----------------------------------------------------------------------
# GLOBAL VARIABLES
#----------------------------------------------------------------------

# regex for Perl identifiers
my $id_regex = qr/
                  \w{2,}     # start with 2 or more word chars ..
                  (?:::\w+)* # .. and  possibly ::some::more::components
                 /x;


# what is considered a "word" when parsing Perl sources
my $wregex   = qr/(?:                   # either a Perl variable:
                    (?: \$\#?|\@|\%)    #   initial sigil
                    (?:                 #     followed by
                       $id_regex        #       an id
                       |                #     or
                       \^[A-Z]\b        #       builtin var with '^' prefix and single letter
                       |                #     or
                       (?:[\#\$](?!\w)) #       just '$$' or '$#'
                       |                #     or
                       [^\{\w\s\$]      #       builtin vars with 1 special char
                     )
                     |                  # or
                     $id_regex          #   a module name or just a plain word
                   )
                 /x;



# common words not to be indexed
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

# directories not to be indexed
my $ignore_dirs = qr[
      auto | unicore | DateTime/TimeZone | DateTime/Locale | Text/Unidecode
  ]x;

# headings not to be indexed
my $ignore_headings = qr[
      SYNOPSIS | DESCRIPTION | METHODS   | FUNCTIONS |
      BUGS     | AUTHOR      | SEE\ ALSO | COPYRIGHT | LICENSE
  ]x;


#----------------------------------------------------------------------
# CONSTRUCTOR
#----------------------------------------------------------------------

sub new {
  my $class = shift;

  # attributes passed to the constructor
  my $self = validate_with(
    params      => \@_,
    spec        => {index_dir    => {type => SCALAR},
                    module_dirs  => {type => ARRAYREF},
                    from_scratch => {type => BOOLEAN, optional => 1},
                    positions    => {type => BOOLEAN, optional => 1},
                    max_size     => {type => SCALAR,  default  => 300 << 10}, # 300K
                  },
    allow_extra => 0,
   );


  bless $self, $class;
}


#----------------------------------------------------------------------
# LAZY ATTRIBUTES
#----------------------------------------------------------------------

sub docs_db {
  my ($self) = @_;

  my $docs_file  = "$self->{index_dir}/docs.txt";
  my $mtime      = (stat $docs_file)[9]
    or return; # there is no index
  my $last_mtime = $self->{docs_db}{mtime} // 0;

  if ($mtime > $last_mtime) {
    # read the file and cache the results
    my %docs_db = (mtime => $mtime);
    open my $docs_fh, "<:encoding(UTF-8)", $docs_file or die "open $docs_file: $!";
    while (<$docs_fh>) {
      chomp;
      my ($id, $path, $module_mtime, $descr) = split /\t/;
      $docs_db{path}   {$id}   = $path;
      $docs_db{details}{$path} = [$module_mtime, $descr];
    }
    $self->{docs_db} = \%docs_db;
  }

  return $self->{docs_db};
}


sub has_index {
  my ($self) = @_;

  return Search::Indexer->has_index_in_dir($self->{index_dir});
}


#----------------------------------------------------------------------
# RETRIEVING
#----------------------------------------------------------------------

sub search {
  my ($self, $search_string, $start_record, $end_record, $get_doc_content) = @_;

  # force Some::Module::Name into "Some::Module::Name" to prevent
  # interpretation of ':' as a field name by Query::Parser
  $search_string =~ s/(^|\s)([\w]+(?:::\w+)+)(\s|$)/$1"$2"$3/g;

  my $indexer = Search::Indexer->new(dir       => $self->{index_dir},
                                     wregex    => $wregex,
                                     preMatch  => '[[',
                                     postMatch => ']]');
  my $search_result = $indexer->search($search_string, 'implicit_plus');
  my $scores        = $search_result->{scores};
  my $search_regex  = $search_result->{regex};
  my @doc_ids       = sort {$scores->{$b} <=> $scores->{$a}} keys %$scores;
  my $n_total       = @doc_ids;

  # loop over the relevant slice
  my @slice = @doc_ids[$start_record .. min($end_record, $#doc_ids)];
  my @modules;
  my $docs_db = $self->docs_db;
  foreach my $doc_id (@slice) {
    my $doc_path    = $docs_db->{path}{$doc_id};
    my $description = $self->get_module_description($doc_path);
    my $excerpts    = $indexer->excerpts($get_doc_content->($doc_path), $search_regex);
    push @modules, [$doc_path, $description, $excerpts];
  };

  return {n_total => $n_total, modules => \@modules, killedWords => $search_result->{killedWords}};
}


sub modules_matching_prefix {
  my ($self, $search_string) = @_;

  length($search_string) >= 2 or die "module_list: arg too short";
  $search_string =~ s[::][/]g;

  my @paths = grep {/^\Q$search_string\E/} values %{$self->{doc_db}{path}};
  s[/][::]g foreach @paths;

  return @paths;
}


sub get_module_description {
  my ($self, $path) = @_;

  my $description = $self->{docs_db}{details}{$path}[1] or return;
  $description =~ s/^.*?-\s*//;
  return $description;
}


#----------------------------------------------------------------------
# INDEXING
#----------------------------------------------------------------------

sub start_indexing_session {
  my ($self) = @_;

  # with option "from_scratch", throw away the old index
  if ($self->{from_scratch}) {
    unlink $_ foreach glob("$self->{index_dir}/*.bdb");
    delete $self->{docs_db};
  }
  elsif ($self->docs_db) {
    # if there is already an existing index, build a reverse hash $path => $id
    $self->{docs_db}{id} = { reverse %{$self->{docs_db}{path}} };
    $self->{max_doc_id}  = max keys %{$self->{docs_db}{path}};
  }

  # initialization of other attributes
  $self->{seen_path}      = {},
  $self->{max_doc_id}   //= 0;
  $self->{previous_index} = {};
  $self->{search_indexer} = Search::Indexer->new(dir       => $self->{index_dir},
                                                 writeMode => 1,
                                                 positions => $self->{positions},
                                                 wregex    => $wregex,
                                                 stopwords => \@stopwords);

  # turn on autoflush on STDOUT so that messages can be piped to the web app
  my $previous_autoflush_value = STDOUT->autoflush(1);

  # also pipe STDERR to the web app
  local *STDERR;
  open STDERR, '>&STDOUT'
    or die "can't redirect STDERR";

  # main indexing loop
  my $t0 = time;
  print "FULLTEXT INDEX IN PROGRESS .. wait for message 'DONE' at the end of this page\n\n";
  $self->index_dir($_) foreach @{$self->{module_dirs}};

  # free the indexer to unlock the .bdb files
  delete $self->{search_indexer};

  # write the "docs_db.txt" file (inventory of document ids with their path and descr)
  printf "\n=============\nEnd of fulltext indexing -- writing docs_db\n";
  my $docs_file  = "$self->{index_dir}/docs.txt";
  open my $docs_fh, ">:encoding(UTF-8)", $docs_file or die "open $docs_file: $!";
  foreach my $id (sort {$a <=> $b} keys %{$self->{docs_db}{path}}) {
    my $path    = $self->{docs_db}{path}{$id} or die "no path for doc $id";
    my $details = $self->{docs_db}{details}{$path};
    print $docs_fh join("\t", $id, $path, @$details), "\n";
  }
  close $docs_fh;

  # close the report and set back to previous autoflush status
  my $t1 = time;
  printf "\n=============\nDONE. Total indexing time : %0.3f s.\n", $t1-$t0;
  STDOUT->autoflush(0) if !$previous_autoflush_value;
}


sub index_dir {
  my ($self, $rootdir, $path) = @_;
  return if $path && $path =~ /$ignore_dirs/;

  my $dir = $rootdir;
  if ($path) {
    $dir .= "/$path";
    return print "SKIP DIR $dir (already in \@INC)\n"
      if grep {m[^\Q$dir\E]} @{$self->{module_dirs}};
  }

  print "DIR $dir\n";

  opendir my $dh, $dir or die $^E;
  my ($dirs, $files) = part { -d "$dir/$_" ? 0 : 1} grep {!/^\./} readdir $dh;
  $dirs ||= [], $files ||= [];
  closedir $dh;

  my %extensions;
  foreach my $file (sort @$files) {
    next unless $file =~ s/\.(pm|pod)$//;
    $extensions{$file}{$1} = 1;
  }

  foreach my $base (keys %extensions) {
    $self->index_file($dir, $path, $base, $extensions{$base});
  }

  my @subpaths = map {$path ? "$path/$_" : $_} @$dirs;
  $self->index_dir($rootdir, $_) foreach @subpaths;
}


sub index_file {
  my ($self, $dir, $path, $file, $has_ext) = @_;

  my $fullpath = $path ? "$path/$file" : $file;
  return print "SKIP $dir/$file (already met in a previous directory)\n"
    if $self->{seen_path}{$fullpath};

  $self->{seen_path}{$fullpath} = 1;
  my $max_mtime = 0;
  my ($size, $mtime, @filenames);
 EXT:
  foreach my $ext (qw/pm pod/) {
    next EXT unless $has_ext->{$ext};
    my $filename = "$dir/$file.$ext";
    ($size, $mtime) = (stat $filename)[7, 9] or die "stat $filename: $!";
    $size < $self->{max_size} or
      print "$filename too big ($size bytes), skipped\n" and next EXT;
    $mtime = max($max_mtime, $mtime);
    push @filenames, $filename;
  }

  my $prev_mtime = $self->{docs_db}{details}{$fullpath}[0]; 
  return print "SKIP $dir/$file (index up to date)\n" if $prev_mtime && $mtime <= $prev_mtime;

  if (@filenames) {
    my $old_doc_id = $self->{docs_db}{id}{$fullpath};
    my $doc_id     = $old_doc_id || ++$self->{max_doc_id};

    print "INDEXING $dir/$file (id $doc_id) ... ";

    my $t0 = time;
    #my $buf = join "\n", map {decode("Detect", path($_)->slurp_raw)} @filenames;
    my $buf = join "\n", map {slurp_native_or_utf8($_)} @filenames;
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
      # ridiculous but is necessary to avoid having the same
      # doc listed twice in inverted lists.
      $self->{search_indexer}->remove($old_doc_id, $buf);
    }

    $self->{search_indexer}->add($doc_id, $buf);
    my $interval = time - $t0;
    printf "%0.3f s.", $interval;

    $self->{docs_db}{path}{$doc_id}      = $fullpath;
    $self->{docs_db}{details}{$fullpath} = [$mtime, $description];
  }

  print "\n";
}


1;

__END__

=head1 NAME

Pod::POM::Web::Indexer - full-text search for Pod::POM::Web

=head1 SYNOPSIS

  perl -MPod::POM::Web::Indexer -e index

=head1 DESCRIPTION

Adds full-text search capabilities to the
L<Pod::POM::Web|Pod::POM::Web> application.
This requires L<Search::Indexer|Search::Indexer> to be installed.

Queries may include plain terms, "exact phrases",
'+' or '-' prefixes, Boolean operators and parentheses.
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


=cut

