package News::Newsrc;

use 5;
use strict;
use Set::IntSpan;

$News::Newsrc::VERSION      = '1.11';
$Set::IntSpan::Empty_String = '';


sub new
{
    my ($class, $file, %options) = @_;

    my $newsrc = { group => {},
		   list  => [] };

    bless $newsrc, ref $class || $class;

    $newsrc->load($file) or $options{create} or die "Can't load $file: $!\n" if $file;

    return $newsrc;
}


sub load
{
    my($newsrc, $file) = @_;

    $file or $file = "$ENV{HOME}/.newsrc";
    $newsrc->{file } = $file;
    $newsrc->{group} = { };
    $newsrc->{list } = [ ];

    open(NEWSRC, $file) or return '';
    my $lines = [ <NEWSRC> ];          # whole file
    close(NEWSRC);

    eval { $newsrc->import_rc($lines) };
    $@ and die "News::Newsrc::load: file $file: $@";

    1
}


sub _scan    # Initializes a Newsrc object from a string.  Used for testing.
{
    my($newsrc, $lines) = @_;

    my @lines = split /\n/, $lines;
    $newsrc->import_rc(@lines);
}


sub import_rc
{
    my $newsrc = shift;
    my $lines = ref $_[0] ? $_[0] : [ @_ ];

    $newsrc->{group} = { };
    $newsrc->{list } = [ ];

    my $line_number = 1;
    for my $line (@$lines)
    {
	eval { $newsrc->parse($line) };
	$@ and die "News::Newsrc::import_rc: line $line_number: $@";

	$line_number++;
    }
}


sub parse   # parses a single line from a newsrc file
{
    my($newsrc, $line) = @_;

    $line =~ /\S/ or return;
    $line =~ s/\s//g;

    $line =~ /^ ([^!:]+) ([!:]) (.*) $/x or
	die "News::Newsrc::parse: Bad newsrc line: $line";

    my($name, $mark, $articles) = ($1, $2, $3);

    valid Set::IntSpan $articles or
	die "News::Newsrc::parse: Bad article list: $line";

    my $group = { name       => $name,
		  subscribed => $mark eq ':',
		  articles   => Set::IntSpan->new($articles) };

    $newsrc->{group}{$name} = $group;
    push(@{$newsrc->{list}}, $group);
}


sub save
{
    my $newsrc = shift;

    $newsrc->{file} or $newsrc->{file} = "$ENV{HOME}/.newsrc";
    $newsrc->save_as($newsrc->{file});
}


sub save_as
{
    my($newsrc, $file) = @_;

    -e $file and
	(rename($file, "$file.bak") or
	 die "News::Newsrc::save_as: Can't rename $file, $file.bak: $!\n");

    open(NEWSRC, "> $file") or
	die "News::Newsrc::save_as: Can't open $file: $!\n";

    $newsrc->{file} = $file;
    eval { $newsrc->format($file) };
    close NEWSRC;
    die $@ if $@;
}


sub format
{
    my($newsrc, $file) = @_;

    for my $group (@{$newsrc->{list}})
    {
	my $name     = $group->{name};
	my $sub      = $group->{subscribed} ? ':' : '!';
	my $articles = $group->{articles}->run_list;
	my $space    = $articles ? ' ' : '';
	print NEWSRC "$name$sub$space$articles\n" or
	    die "News::Newsrc::format: Can't write $file: $!\n";
    }
}


sub export_rc
{
    my $newsrc = shift;

    my @lines = map { my $group    = $_;
          	      my $name     = $group->{name};
	  	      my $sub      = $group->{subscribed} ? ':' : '!';
	  	      my $articles = $group->{articles}->run_list;
	  	      my $space    = $articles ? ' ' : '';
	  	      "$name$sub$space$articles\n" }  @{$newsrc->{list}};

    wantarray ? @lines : \@lines
}


sub _dump	# Formats a Newsrc object to a string.  Used for testing
{
    my $newsrc = shift;

    my $dump = '';
    for my $group (@{$newsrc->{list}})
    {
	my $name     = $group->{name};
	my $sub      = $group->{subscribed} ? ':' : '!';
	my $articles = $group->{articles}->run_list;
        $articles    = ' ' . $articles if $articles =~ /^\d/;
	$dump       .= "$name$sub$articles\n";
    }

    $dump
}


sub add_group
{
    my($newsrc, $name, %options) = @_;

    if ($newsrc->{group}{$name})
    {
	$options{replace} or return 0;
	$newsrc->del_group($name);
    }

    my $group = { name       => $name,
		  subscribed => 1,
		  articles   => Set::IntSpan->new };

    $newsrc->{group}{$name} = $group;
    $newsrc->_insert($group, %options);

    1
}


sub move_group
{
    my($newsrc, $name, %options) = @_;
    my $group = $newsrc->{group}{$name};
    $group or return 0;

    $newsrc->{list} = [ grep { $_->{name} ne $name } @{$newsrc->{list}} ];
    $newsrc->_insert($group, %options);
    1
}


sub Splice(\@$$@)
{
    my($array, $offset, $length, @list) = @_;

    $offset >  @$array and $offset =  @$array;
    $offset < -@$array and $offset = -@$array;
    splice @$array, $offset, $length, @list;
}


sub _insert
{
    my($newsrc, $group, %options) = @_;

    my $list = $newsrc->{list};

    my($where, $arg) = ('', '');
    $options{where} and $where = $options{where};
    ref $where and ($where, $arg) = @$where;

    for ($where)
    {
	/first/  and unshift @$list, $group;
	/last/   and push    @$list, $group;
	/^$/     and push    @$list, $group;	# default
	/alpha/  and Alpha   ($list, $group);
	/before/ and Before  ($list, $group, $arg);
	/after/  and After   ($list, $group, $arg);
	/number/ and Splice  @$list, $arg, 0, $group;
    }
}


sub Alpha
{
    my($list, $group, $before) = @_;
    my $name = $group->{name};

    for my $i (0..$#$list)
    {
	if ($name lt $list->[$i]{name})
	{
	    splice @$list, $i, 0, $group;
	    return;
	}
    }

    push @$list, $group;
}


sub Before
{
    my($list, $group, $before) = @_;
    my $name = $group->{name};

    for my $i (0..$#$list)
    {
	if ($list->[$i]{name} eq $before)
	{
	    splice @$list, $i, 0, $group;
	    return;
	}
    }

    push @$list, $group;
}


sub After
{
    my($list, $group, $after) = @_;
    my $name = $group->{name};

    for my $i (0..$#$list)
    {
	if ($list->[$i]{name} eq $after)
	{
	    splice @$list, $i+1, 0, $group;
	    return;
	}
    }

    push @$list, $group;
}


sub del_group
{
    my($newsrc, $name) = @_;

    $newsrc->{group}{$name} or return 0;

    delete $newsrc->{group}{$name};
    $newsrc->{list} = [ grep { $_->{name} ne $name } @{$newsrc->{list}} ];

    1
}


sub subscribe
{
    my($newsrc, $name, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    $newsrc->{group}{$name}{subscribed} = 1;
}


sub unsubscribe
{
    my($newsrc, $name, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    $newsrc->{group}{$name}{subscribed} = 0;
}


sub mark
{
    my($newsrc, $name, $article, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    $newsrc->{group}{$name}{articles}->insert($article);
}


sub mark_list
{
    my($newsrc, $name, $list, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    my $group = $newsrc->{group}{$name};
    my $articles = union { $group->{articles} } $list;
    $group->{articles} = $articles;
}


sub mark_range
{
    my($newsrc, $name, $from, $to, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    my $group = $newsrc->{group}{$name};
    my $range = new Set::IntSpan "$from-$to";
    my $articles = union { $group->{articles} } $range;
    $group->{articles} = $articles;
}


sub unmark
{
    my($newsrc, $name, $article, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    $newsrc->{group}{$name}{articles}->remove($article);
}


sub unmark_list
{
    my($newsrc, $name, $list, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    my $group = $newsrc->{group}{$name};
    my $articles = diff { $group->{articles} } $list;
    $group->{articles} = $articles;
}


sub unmark_range
{
    my($newsrc, $name, $from, $to, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    my $group = $newsrc->{group}{$name};
    my $range = new Set::IntSpan "$from-$to";
    my $articles = diff { $group->{articles} } $range;
    $group->{articles} = $articles;
}


sub exists
{
    my($newsrc, $name) = @_;
    $newsrc->{group}{$name} ? 1 : ''
}


sub subscribed
{
    my($newsrc, $name) = @_;
    $newsrc->exists($name) and $newsrc->{group}{$name}{subscribed}
}


sub marked
{
    my($newsrc, $name, $article) = @_;

    $newsrc->exists($name) and
	member {  $newsrc->{group}{$name}{articles} } $article
}


sub num_groups
{
    my $newsrc = shift;
    my $list = $newsrc->{list};
    scalar @$list
}


sub groups
{
    my $newsrc = shift;
    my $list = $newsrc->{list};
    my @list = map { $_->{name} } @$list;
    wantarray ? @list : \@list;
}


sub sub_groups
{
    my $newsrc = shift;
    my $list = $newsrc->{list};
    my @list = map { $_->{name} } grep { $_->{'subscribed'} } @$list;
    wantarray ? @list : \@list;
}


sub unsub_groups
{
    my $newsrc = shift;
    my $list = $newsrc->{list};
    my @list = map { $_->{name} } grep { not $_->{'subscribed'} } @$list;
    wantarray ? @list : \@list;
}


sub marked_articles
{
    my($newsrc, $name, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    my @marked = elements { $newsrc->{group}{$name}{articles} };
    wantarray ? @marked : \@marked
}


sub unmarked_articles
{
    my($newsrc, $name, $from, $to, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    my $range = new Set::IntSpan "$from-$to";
    my $unmarked = diff $range $newsrc->{group}{$name}{articles};
    my @unmarked = elements $unmarked;
    wantarray ? @unmarked : \@unmarked
}

sub get_articles
{
    my($newsrc, $name, %options) = @_;
    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    $newsrc->{group}{$name}{articles}->run_list;
}


sub set_articles
{
    my($newsrc, $name, $articles, %options) = @_;

    valid Set::IntSpan $articles or return 0;
    my $set = new Set::IntSpan $articles;
    finite $set or return 0;
    my $min = $set->min;
    defined $min and $min < 0 and return 0;

    $newsrc->{group}{$name} or $newsrc->add_group($name, %options);
    $newsrc->{group}{$name}{articles} = $set;
    1
}

1

__END__

=head1 NAME

News::Newsrc - manage newsrc files

=head1 SYNOPSIS

  use News::Newsrc;

  $newsrc   = new News::Newsrc;
  $newsrc   = new News::Newsrc $file;
  $newsrc   = new News::Newsrc $file, create => 1;

  $ok       = $newsrc->load;
  $ok       = $newsrc->load             ( $file);
              $newsrc->import_rc        ( @lines);
              $newsrc->import_rc        (\@lines);

              $newsrc->save;
              $newsrc->save_as          ($file);
  @lines    = $newsrc->export_rc;

  $ok       = $newsrc-> add_group       ($group,             %options);
  $ok       = $newsrc->move_group       ($group,             %options);
  $ok       = $newsrc-> del_group       ($group);

              $newsrc->  subscribe      ($group,             %options);
              $newsrc->unsubscribe      ($group,             %options);

              $newsrc->mark             ($group,  $article , %options);
              $newsrc->mark_list        ($group, \@articles, %options);
              $newsrc->mark_range       ($group, $from, $to, %options);

              $newsrc->unmark           ($group,  $article , %options);
              $newsrc->unmark_list      ($group, \@articles, %options);
              $newsrc->unmark_range     ($group, $from, $to, %options);

       ... if $newsrc->exists           ($group);
       ... if $newsrc->subscribed       ($group);
       ... if $newsrc->marked           ($group, $article);

  $n        = $newsrc->  num_groups;
  @groups   = $newsrc->      groups;
  @groups   = $newsrc->  sub_groups;
  @groups   = $newsrc->unsub_groups;

  @articles = $newsrc->  marked_articles($group,             %options);
  @articles = $newsrc->unmarked_articles($group, $from, $to, %options);

  $articles = $newsrc->get_articles     ($group,             %options);
  $ok       = $newsrc->set_articles     ($group, $articles,  %options);


=head1 REQUIRES

Perl 5.6.0, Set::IntSpan 1.17


=head1 EXPORTS

Nothing


=head1 DESCRIPTION

C<News::Newsrc> manages newsrc files, of the style

    alt.foo: 1-21,28,31-34
    alt.bar! 3,5,9-2900,2902

Methods are provided for

=over 4

=item *

reading and writing newsrc files

=item *

adding and removing newsgroups

=item *

changing the order of newsgroups

=item *

subscribing and unsubscribing from newsgroups

=item *

testing whether groups exist and are subscribed

=item *

marking and unmarking articles

=item *

testing whether articles are marked

=item *

returning lists of newsgroups

=item *

returning lists of articles

=back


=head1 NEWSRC FILES

A newsrc file is an ASCII file that lists newsgroups and article numbers.
Each line of a newsrc file describes a single newsgroup.
Each line is divided into three fields:
a I<group>, a I<subscription mark> and an I<article list>.

Lines containing only whitespace are ignored.
Whitespace within a line is ignored.

=over 4

=item Group

The I<group> is the name of the newsgroup.
A group name may not contain colons (:) or exclamation points (!).

Group names must be unique within a newsrc file.
The group name is required.

=item Subscription mark

The I<subscription mark> is either a colon (:), for subscribed groups,
or an exclamation point (!), for unsubscribed groups.
The subscription mark is required.

=item Article list

The I<article list> is a comma-separated list of positive integers.
The integers must be listed in increasing order.
Runs of consecutive integers may be abbreviated a-b,
where a is the first integer in the run and b is the last.
The article list may be empty.

=back


=head1 NEWSGROUP ORDER

C<News::Newsrc> preserves the order of newsgroups in a newsrc file:
if a file is loaded and then saved,
the newsgroup order will be unchanged.

Methods that add or move newsgroups affect the newsgroup order.
By default,
these methods put newsgroups at the end of the newsrc file.
Other locations may be specified by passing an I<%options> hash
with a C<where> key to the method.
Recognized locations are:

=over 4

=item C<where> => C<'first'>

Put the newsgroup first.

=item C<where> => C<'last'>

Put the newsgroup last.

=item C<where> => C<'alpha'>

Put the newsgroup in alphabetical order.

If the other newsgroups are not sorted alphabetically,
put the group at an arbitrary location.

=item C<where> => [ C<before> => I<$group> ]

Put the group immediately before I<$group>.

If I<$group> does not exist,
put the group last.

=item C<where> => [ C<after> => I<$group> ]

Put the group immediately after I<$group>.

If I<$group> does not exist,
put the group last.

=item C<where> => [ C<number> => I<$n> ]

Put the group at position I<$n> in the group list.
Indices are zero-based.
Negative indices count backwards from the end of the list.

=back


=head1 METHODS

=over 4


=item I<$newsrc> = C<new> C<News::Newsrc>

=item I<$newsrc> = C<new> C<News::Newsrc> I<$file>, I<%options>

Creates and returns a C<News::Newsrc> object.

If I<$file> is specified,
C<new> loads the newsgroups in I<$file> into the object.
Subsequent calls to C<save> will write to I<$file>.

If I<$file> exists and the load fails, C<new> C<die>s.

If I<$file> doesn't exist and the C<< create => 1 >> option is supplied in I<%options>,
then C<new> doesn't load any newsgroups.

If I<$file> doesn't exist and the C<< create => 1 >> option is not supplied in I<%options>,
then C<new> dies.


=item I<$ok> = I<$newsrc>->C<load>

=item I<$ok> = I<$newsrc>->C<load>(I<$file>)

Loads the newsgroups in I<$file> into I<$newsrc>.
If I<$file> is omitted, reads F<$ENV{HOME}/.newsrc>.
Any existing data in I<$newsrc> is discarded.
Returns true on success.

If I<$file> can't be opened,
C<load> discards existing data from I<$newsrc> and returns null.

If I<$file> contains invalid lines, C<load> will C<die>.
When this happens, the state of I<$newsrc> is undefined.


=item I<$newsrc>->C<import_rc>(I<@lines>)

=item I<$newsrc>->C<import_rc>([I<@lines>])

Imports the newsgroups in I<@lines> into I<$newsrc>.
Any existing data in I<$newsrc> is discarded.

Each line in I<@lines> describes a single newsgroup,
and must have the format described in L<"NEWSRC FILES">.
If I<@lines> contains invalid lines, C<import_rc> will C<die>.
When this happens, the state of I<$newsrc> is undefined.

C<import_rc> accepts either an array or an array reference.


=item I<$newsrc>->C<save>

Writes the contents of I<$newsrc> back to the file
from which it was C<load>ed.
If C<load> has not been called, writes to F<$ENV{HOME}/.newsrc>.
In either case, if the destination I<file> exists,
it is renamed to I<file>C<.bak>.

C<save> will C<die> if there is an error writing the file.


=item I<$newsrc>->C<save_as>(I<$file>)

Writes the contents of I<$newsrc> to I<$file>.
If I<$file> exists, it is renamed to I<$file>C<.bak>.
Subsequent calls to C<save> will write to I<$file>.

C<save_as> will C<die> if there is an error writing the file.


=item I<@lines> = I<$newsrc>->C<export_rc>

Returns the contents of I<$newsrc> as a list of lines.
Each line describes a single newsgroup,
and has the format described in L<"NEWSRC FILES">.

In scalar context, returns an array reference.


=item I<$ok> = I<$newsrc>->C<add_group>(I<$group>, I<%options>)

Adds I<$group> to the list of newsgroups in I<$newsrc>.
I<$group> is initially subscribed.
The article list for I<$group> is initially empty.

By default,
I<$group> is added to the end of the list of newsgroups.
Other locations may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.

By default,
C<add_group> does nothing if I<$group> already exists.
If the C<replace> => C<1> option is provided,
then C<add_group> will delete I<$group> if it exists,
and then add it.

C<add_group> returns true iff I<$group> was added.


=item I<$ok> = I<$newsrc>->C<move_group>(I<$group>, I<%options>)

Changes the position of I<$group> in I<$newsrc>
according to I<%options>.
See L<"NEWSGROUP ORDER"> for details.

If I<$group> does not exist,
C<move_group> does nothing and returns false.
Otherwise, it returns true.


=item I<$ok> = I<$newsrc>->C<del_group>(I<$group>)

If I<$group> exists in I<$newsrc>,
C<del_group> removes it and returns true.
The article list for I<$group> is lost.

If I<$group> does not exist in I<$newsrc>,
C<del_group> does nothing and returns false.


=item I<$newsrc>->C<subscribe>(I<$group>, I<%options>)

Subscribes to I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<unsubscribe>(I<$group>, I<%options>)

Unsubscribes from I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<mark>(I<$group>, I<$article>, I<%options>)

Adds I<$article> to the article list for I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<mark_list>(I<$group>, I<\@articles>, I<%options>)

Adds I<@articles> to the article list for I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<mark_range>(I<$group>, I<$from>, I<$to>, I<%options>)

Adds all the articles from I<$from> to I<$to>, inclusive,
to the article list for I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<unmark>(I<$group>, I<$article>, I<%options>)

Removes I<$article> from the article list for I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<unmark_list>(I<$group>, I<\@articles>, I<%options>)

Removes I<@articles> from the article list for I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<unmark_range>(I<$group>, I<$from>, I<$to>, I<%options>)

Removes all the articles from I<$from> to I<$to>, inclusive,
from the article list for I<$group>.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$newsrc>->C<exists>(I<$group>)

Returns true iff I<$group> exists in I<$newsrc>.


=item I<$newsrc>->C<subscribed>(I<$group>)

Returns true iff I<$group> exists and is subscribed.


=item I<$newsrc>->C<marked>(I<$group>, I<$article>)

Returns true iff I<$group> exists and its article list contains I<$article>.


=item I<$n> = I<$newsrc>->C<num_groups>

Returns the number of groups in I<$newsrc>.


=item I<@groups> = I<$newsrc>->C<groups>

Returns the list of groups in I<$newsrc>,
in newsrc order.
In scalar context, returns an array reference.


=item I<@groups> = I<$newsrc>->C<sub_groups>

Returns the list of subscribed groups in I<$newsrc>,
in newsrc order.
In scalar context, returns an array reference.


=item I<@groups> = I<$newsrc>->C<unsub_groups>

Returns the list of unsubscribed groups in I<$newsrc>,
in newsrc order.
In scalar context, returns an array reference.


=item I<@articles> = I<$newsrc>->C<marked_articles>(I<$group>)

Returns the list of articles in the article list for I<$group>.
In scalar context, returns an array reference.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<@articles> = I<$newsrc>->C<unmarked_articles>(I<$group>, I<$from>, I<$to>, I<%options>)

Returns the list of articles from I<$from> to I<$to>, inclusive,
that do B<not> appear in the article list for I<$group>.
In scalar context, returns an array reference.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.


=item I<$articles> = I<$newsrc>->C<get_articles>(I<$group>, I<%options>)

Returns the article list for I<$group> as a string,
in the format described in L<"NEWSRC FILES">.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.

If you plan to do any nontrivial processing on the article list,
consider converting it to a C<Set::IntSpan> object:

  $articles = Set::IntSpan->new($newsrc->get_articles('alt.foo'))


=item I<$ok> = I<$newsrc>->C<set_articles>(I<$group>, I<$articles>, I<%options>)

Sets the article list for $group.
Any existing article list is lost.

I<$articles> is a string,
as described in L<"NEWSRC FILES">.

I<$group> will be created if it does not exist.
Its location may be specified in I<%options>;
see L<"NEWSGROUP ORDER"> for details.

If I<$articles> does not have the format described in L<"NEWSRC FILES">,
C<set_articles> does nothing and returns false.
Otherwise, it returns true.

=back


=head1 DIAGNOSTICS

=over 4


=item Bad newsrc line

A line in the newsrc file does not have the format described in
L<"NEWSRC FILES">.


=item Bad article list

The article list for a newsgroup does not have the format described in
L<"NEWSRC FILES">.


=item News::Newsrc::save_as: Can't rename $file, $file.bak: $!


=item News::Newsrc::save_as: Can't open $file: $!


=item News::Newsrc::format: Can't write $file: $!

=back


=head1 NOTES


=head2 Error Handling

"Don't test for errors that you can't handle."

C<load> returns null if it can't open the newsrc file,
and dies if the newsrc file contains invalid data.
This isn't as schizophrenic as it seems.

There are several ways a program could handle an open failure on the newsrc file.
It could prompt the user to reenter the file name.
It could assume that the user doesn't have a newsrc file yet.
If it doesn't want to handle the error, it could go ahead and die.

On the other hand,
it is very difficult for a program to do anything sensible
if the newsrc file opens successfully
and then turns out to contain invalid data.
Was there a disk error?
Is the file corrupt?
Did the user accidentally specify his kill file instead of his newsrc file?
And what are you going to do about it?

Rather than try to handle an error like this,
it's probably better to die and let the user sort things out.
By the same rational,
C<save> and C<save_as> die on failure.

Programs that must retain control can use eval{...}
to protect calls that may die.
For example, Perl/Tk runs all callbacks inside an eval{...}.
If a callback dies,
Perl/Tk regains control and displays $@ in a dialog box.
The user can then decide whether to continue or quit from the program.


=head2 C<import_rc>/C<export_rc>

I was going to call these methods C<import> and C<export>,
but C<import> turns out not to be a good name for a method,
because C<use> also calls C<import>,
and expects different semantics.

I added the C<_rc> suffix to C<import> to avoid this conflict.
It's reasonably short and somewhat mnemonic
(the module manages newsI<rc> files).
I added the same suffix to C<export> for symmetry.


=head2 use integer

Up until version 1.09, C<News::Newsrc> specified C<use integer>.
As of 2012, users are reporting newsgroups with article numbers above
0x7fffffff, which break the underlying C<Set::IntSpan> module on 32-bit processors.

Version 1.10 removes the C<use integer> from C<News::Newsrc>.
This extends the usable range of C<Set::IntSpan> to (typically) 9e15,
which ought to be enough, even for usenet.

If you want C<use integer> back, either for performance,
or because you are somehow dependent on its semantics, write

  BEGIN { $Set::IntSpan::integer = 1 }
  use News::Newsrc;

See C<Set::IntSpan> for more information.


=head1 ACKNOWLEDGMENTS

=over 4

=item *

Neil Bowers <neilb@cre.canon.co.uk>

=item *

Matthew Darwin <matthew@davin.ottawa.on.ca>

=item *

Philip Hallstrom <philip.hallstrom@cendantsoft.com>

=item *

M. Hedlund <hedlund@best.com>

=item *

Bruce J. Keeler <bruce@gridpoint.com>

=item *

Chris Leach <Chris.Leach@epa.ericsson.se>

=item *

Abhijit Menon-Sen <ams@wiw.org>

=item *

J.B. Nicholson-Owens <jbn@pop-a-wheelie.midwest.net>

=item *

Lars Balker Rasmussen <gnort@daimi.aau.dk>

=item *

Nicholas Redgrave <baron@bologrew.net>

=item *

Mike Stok <mike@stok.co.uk>

=item *

Bennett Todd <bet@onyx.interactive.net>

=item *

Larry W. Virden <lvirden@cas.org>

=item *

Chris Szurgot <szurgot@itribe.net>

=back


=head1 AUTHOR

Steven McDougall, swmcd@world.std.com


=head1 SEE ALSO

perl(1), Set::IntSpan


=head1 COPYRIGHT

Copyright 1996-2013 by Steven McDougall. This module is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
