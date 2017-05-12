package Search::Glimpse::Index;

use warnings;
use strict;

use Search::Glimpse::ConfigData;
use File::Path qw.make_path.;

our $VERSION = '0.01';

=encoding UTF-8

=head1 NAME

Search::Glimpse::Index - Interface to glimpseindex

=head1 SYNOPSIS

  use Search::Glimpse::Index;

  my %opt = (
      timeindex   => 1,
      dryrun      => 0,
      indexall    => 0,
      indexnum    => 0,
      incremental => 0,
      structural  => 0,
      destdir     => "$ENV{HOME}/myindexes",
      stopword    => 90,     # must appear in 90% of files
  );
  my $indexer = Search::Glimpse::Index( %opt );

  $indexer->index("/path/to/folder/to/index");

=head1 DESCRIPTION

This module is a Perl interface to glimpseindex binary. It (hopefully)
makes easier to use the application from within Perl scripts or
modules.

=head2 Available Methods

=over 4

=item C<new>

The constructor receives a hash with the indexing options to use. Note
that all these values have sensible defaults (mosty, the glimpseindex
defaults). Although I describe briefly what each option represent, I
suggest to read the complete manpage for C<glimpseindex>.

Known options are:

=over 4

=item C<destdir> (C<glimpseindex -H> option)

This is the folder where C<glimpseindex> will store its index
files. This is also the path where you should put your exclude/include
files. Future versions of this module might include an interface for
those files.

=item C<dryrun> (C<glimpseindex -I> option)

This option is a boolean value, and sets whether C<glimpseindex>
should really index the files or just output the files that would be
indexed in a real run.

=item C<bigindex> (C<glimpseindex -b> option)

C<glimpseindex> has three different index sizes. By default the medium
index is used (C<glimpseindex -o>). Use this option for bigger indexes
and (hopefully) faster results.

=item C<smallindex>

C<glimpseindex> has three different index sizes. By default the medium
index is used (C<glimpseindex -o>). Use this option for smaller
indexes (not using any C<glimpseindex> switch).

=item C<indexnum> (C<glimpseindex -n> option)

By default, tokens with digits are not indexed. Therefore, things like
C<abc123> or a date will not be indexed. Use this option to force
tokens with digits to be indexed.

=item C<indexall> (C<glimpseindex -E> option)

Makes C<glimpseindex> to index all files, independently of their file
type. Note that C<glimpseindex> will honor C<.glimpse_exclude> files.

=item C<timeindex> (C<glimpseindex -t> option)

This option is only available for C<glimpse> version 3.5 or newer. It
changes the order by which files are indexed. By default files are
indexed in a mostly arbitraty order. With this option (which doesn't
work in C<smallindex> mode), the index will store files in a reversed
order of modification time (recent files first). Therefore, results of
queries are returned by this order, and glimpse is able t filter
results by age.

=item C<incremental> (C<glimpseindex -f> option)

Useful if you have run a C<glimpseindex> earlier and need to
reindex. This option will perform an incremental indexing. If there is
no current index or if this procedure fails, glimpseindex
automatically reverts to the default mode (which is to index
everything from scratch).

=item C<structural> (C<glimpseindex -s> option)

Use this option if you want to support structured queries.

=item C<swsize> (C<glimpseindex -S> option)

This option is used to control the amount of stop words to be
considered. For further details on how the values of this option
behave, please check C<glimpseindex> manpage.

=back

=cut

sub new {
    my $class = shift;
    my %ops = @_;

    make_path $ops{destdir}                           unless -d $ops{destdir};
    die "Can't use $ops{destdir}. Permission denied?" unless -d $ops{destdir};

    my $self = bless
      {
       timeindex   => $ops{timeindex}   ? "-t" : "",
       dryrun      => $ops{dryrun}      ? "-I" : "",
       indexall    => $ops{indexall}    ? "-E" : "",
       indexnum    => $ops{indexnum}    ? "-n" : "",
       incremental => $ops{incremental} ? "-f" : "",
       structural  => $ops{structural}  ? "-s" : "",
       destdir     => $ops{destdir}     ? "-H $ops{destdir}" : "",
       stopword    => $ops{swsize}      ? "-S $ops{swsize}" : "",
       indexsize   => $ops{smallindex}  ? ""   : ($ops{bigindex} ? "-b" : "-o"),

       bin         => Search::Glimpse::ConfigData->config('glimpseindex')
      } => $class;

    return $self;
}

# check how to support .glimpse files

# -z     Allow customizable filtering, using the file .glimpse_filters to
#        perform the programs listed there  for  each  match.   The  best
#        example is compress/decompress.  If .glimpse_filters include the
#        line
#        *.Z   uncompress <
#        (separated by tabs) then before indexing any file  that  matches
#        the  pattern "*.Z" (same syntax as the one for .glimpse_exclude)
#        the command listed is executed first  (assuming  input  is  from
#        stdin, which is why uncompress needs <) and its output (assuming
#        it goes to stdout) is indexed.  The file itself is  not  changed
#        (i.e.,  it  stays  compressed).  Then if glimpse -z is used, the
#        same program is used on these files on the fly.  Any program can
#        be  used (we run 'exec').  For example, one can filter out parts
#        of files that should not  be  indexed.   Glimpseindex  tries  to
#        apply  all  filters  in  .glimpse_filters  in the order they are
#        given.  For example, if you want to uncompress a file  and  then
#        extract  some part of it, put the compression command (the exam-
#        ple above) first  and  then  another  line  that  specifies  the
#        extraction.  Note that this can slow down the search because the
#        filters need to be run before files are searched.

# -B     uses  a  hash table that is 4 times bigger (256k entries instead
#        of 64K) to speed up indexing.  The memory  usage  will  increase
#        typically  by  about  2  MB.   This  option is only for indexing
#        speed; it does not affect the final index.

# -i     Make .glimpse_include (SEE GLIMPSEINDEX FILES)  take  precedence
#        over  .glimpse_exclude,  so  that,  for example, one can exclude
#        everything (by putting *) and then explicitly include files.

# -M x   Tells  glimpseindex  to use x MB of memory for temporary tables.
#        The more memory you allow the faster glimpseindex will run.  The
#        default  is  x=2.   The  value  of x must be a positive integer.
#        Glimpseindex will need more memory than x for other things,  and
#        glimpseindex may perform some 'forks', so you'll have to experi-
#        ment if you want to use this option.  WARNING: If x is too large
#        you may run out of swap space.

# -z     Allow customizable filtering, using the file .glimpse_filters to
#        perform the programs listed there  for  each  match.   The  best
#        example is compress/decompress.  If .glimpse_filters include the
#        line
#        *.Z   uncompress <
#        (separated by tabs) then before indexing any file  that  matches
#        the  pattern "*.Z" (same syntax as the one for .glimpse_exclude)
#        the command listed is executed first  (assuming  input  is  from
#        stdin, which is why uncompress needs <) and its output (assuming
#        it goes to stdout) is indexed.  The file itself is  not  changed
#        (i.e.,  it  stays  compressed).  Then if glimpse -z is used, the
#        same program is used on these files on the fly.  Any program can
#        be  used (we run 'exec').  For example, one can filter out parts
#        of files that should not  be  indexed.   Glimpseindex  tries  to
#        apply  all  filters  in  .glimpse_filters  in the order they are
#        given.  For example, if you want to uncompress a file  and  then
#        extract  some part of it, put the compression command (the exam-
#        ple above) first  and  then  another  line  that  specifies  the
#        extraction.  Note that this can slow down the search because the
#        filters need to be run before files are searched.


# sub index_files { }
#
# -F     Glimpseindex  receives  the list of files to index from standard
#        input.


=item C<index>

Use with a path to be indexed.

=cut

sub index {
    my $self = shift;
    my $path = shift;

    my $commandline = join(" ",
                           $self->{bin},
                           $self->{timeindex},
                           $self->{dryrun},
                           $self->{indexall},
                           $self->{indexnum},
                           $self->{indexsize},
                           $self->{stopword},
                           $self->{destdir},
                           $self->{structural},
                           $self->{incremental},
                           $path);

    $ENV{LC_ALL} = 'C';
    my $output;
    open PIPE, "-|", $commandline or die "Can't execute glimpseindex";
    $output = join("" => <PIPE>);
    close PIPE;

    $self->{output} = $output || "";
    return $self;
}

#sub append { #... -a }

#sub delete { -d && -D (force) }

### PROBABLY NOTS

# -R     Recompute .glimpse_filenames_index from .glimpse_filenames.  The
#        file .glimpse_filenames_index speeds up processing.   Glimpsein-
#        dex  usually  computes  it  automatically.  However, if for some
#        reason one wants to change the path names of the files listed in
#        .glimpse_filenames,  then  running  glimpseindex  -R  recomputes
#        .glimpse_filenames_index.  This is useful if the index  is  com-
#        puted  on  one  machine,  but  is used on another (with the same
#        hierarchy).  The names of the files listed in .glimpse_filenames
#        are used in runtime, so changing them can be done at any time in
#        any way (as long as just the names not the content is  changed).
#        This  is  not really an option in the regular sense;  rather, it
#        is a program by itself, and it is  meant  as  a  post-processing
#        step.  (Avaliable only from version 3.6.)

# -w k   Glimpseindex does a reasonable, but not a perfect, job of deter-
#        mining which files should not be  indexed.   Sometimes  a  large
#        text  file  should not be indexed; for example, a dictionary may
#        match most queries.  The -w  option  stores  in  a  file  called
#        .glimpse_messages  (in the same directory as the index) the list
#        of all files that contribute at least k new words to the  index.
#        The  user can look at this list of files and decide which should
#        or should not be indexed.  The  file  .glimpse_exclude  contains
#        files  that  will not be indexed (see more below).  We recommend
#        to set k to about 1000.  This is  not  an  exact  measure.   For
#        example,  if  the  same file appears twice, then the second copy
#        will not contribute any new words to the dictionary (but if  you
#        exclude  the  first  copy  and index again, the second copy will
#        contribute).

# -X     (starting at version 4.0B1) Extract titles from HTML  pages  and
#        add the titles to the index (in .glimpse_filenames).  (This fea-
#        ture was added to improve the performance of WebGlimpse.)  Works
#        only  on  files  whose  names  end with .html, .htm, .shtml, and
#        .shtm.  (see glimpse.h/EXTRACT_INFO_SUFFIX to add to these  suf-
#        fixes.)   The  routine to extract titles is called extract_info,
#        in index/filetype.c.  This feature can be  modified  in  various
#        ways  to  extract  info  from  many  filetypes.   The titles are
#        appended to the corresponding filenames with a space  separator.
#        Glimpseindex assumes that filenames don't have spaces in them.


=back

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Alberto Manuel Brandão Simões

=cut


!0;
