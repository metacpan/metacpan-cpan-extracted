package SVN::Log::Index;

use strict;
use warnings;

use File::Path;

use KinoSearch::InvIndexer;
use KinoSearch::Searcher;

use Params::Validate qw(:all);
use Exception::Class(
    'SVN::Log::Index::X::Args'
	=> { alias => 'throw_args', },
    'SVN::Log::Index::X::Fault'
	=> { alias  => 'throw_fault', },
);

Params::Validate::validation_options(
    on_fail => sub { throw_args error => shift },
);

use SVN::Log;
use YAML ();

our $VERSION = '0.51';

=head1 NAME

SVN::Log::Index - Index and search over Subversion commit logs.

=head1 SYNOPSIS

  my $index = SVN::Log::Index->new({ index_path => '/path/to/index' });

  if($creating) {    # Create from scratch if necessary
    $index->create({ repo_url => 'url://for/repo' });
  }

  $index->open();    # And then open it

  # Now add revisions from the repo to the index
  $index->add({ start_rev => $start_rev,
                end_rev   => $end_rev);

  # And query the index
  my $results = $index->search('query');

=head1 DESCRIPTION

SVN::Log::Index builds a KinoSearch index of commit logs from a
Subversion repository and allows you to do arbitrary full text searches
over it.

=head1 METHODS

=head2 new

  my $index = SVN::Log::Index->new({
      index_path => '/path/to/index'
  });

Create a new index object.

The single argument is a hash ref.  Currently only one key is valid.

=over 4

=item index_path

The path that contains (or will contain) the index files.

=back

This method prepares the object for use, but does not make any changes
on disk.

=cut

sub new {
  my $proto = shift;
  my $args  = validate(@_, {
      index_path => 1,
  });

  my $class = ref($proto) || $proto;
  my $self  = {};

  $self->{index_path} = $args->{index_path};

  bless $self, $class;
}

=head2 create

  $index->create({
      repo_url       => 'url://for/repo',
      analyzer_class => 'KinoSearch::Analysis::PolyAnalyzer',
      analyzer_opts  => [ language => 'en' ],
      overwrite      => 0, # Optional
  });

This method creates a new index, in the C<index_path> given when the
object was created.

The single argument is a hash ref, with the following possible keys.

=over 4

=item repo_url

The URL for the Subversion repository that is going to be indexed.

=item analyzer_class

A string giving the name of the class that will analyse log message
text and tokenise it.  This should derive from the
L<KinoSearch::Analysis::Analyzer> class.  SVN::Log::Index will call this
class' C<new()> method.

Once an analyzer class has been chosen for an index it can not be
changed without deleting the index and creating it afresh.

The default value is C<KinoSearch::Analysis::PolyAnalyzer>.

=item analyzer_opts

A list of options to be passed, as is, to the constructor for the
C<analyzer_class> object.

=item overwrite

A boolean indicating whether or not a pre-existing index_path should
be overwritten.

Given this sequence;

  my $index = SVN::Log::Index->new({index_path => '/path'});
  $index->create({repo_url => 'url://for/repo'});

The call to C<create()> will fail if C</path> already exists.

If C<overwrite> is set to a true value then C</path> will be cleared.

The default is false.

=back

After creation the index directory will exist on disk, and a
configuration file containing the create()-time parameters will be
created in the index directory.

Newly created indexes must still be opened.

=cut

sub create {
  my $self = shift;
  my $args = validate(@_, {
      repo_url => {
	  type => SCALAR,
	  regex => qr{^[a-z/]},
      },
      analyzer_class => {
	  type => SCALAR,
	  default => 'KinoSearch::Analysis::PolyAnalyzer',
      },
      analyzer_opts => {
	  type => ARRAYREF,
	  default => [ language => 'en' ],
      },
      overwrite => {
	  type => BOOLEAN,
	  default => 0,
      },
  });

  throw_fault("Can't call create() after open()")
      if exists $self->{config};

  if(-d $self->{index_path} and ! $args->{overwrite}) {
    throw_fault("create() $self->{index_path} exists and 'overwrite' is false");
  }

  if($args->{repo_url} !~ m/^(http|https|svn|file|svn\+ssh):\/\//) {
    $args->{repo_url} = 'file://' . $args->{repo_url};
  }

  $self->{config} = $args;
  $self->{config}{last_indexed_rev} = 0;

  $self->_create_analyzer();
  $self->_create_writer($args->{overwrite});

  $self->_save_config();

  delete $self->{config};	# Gets reloaded in open()
}

sub _save_config {
  my $self = shift;

  YAML::DumpFile($self->{index_path} . '/config.yaml', $self->{config})
      or throw_fault("Saving config failed: $!");
}

sub _load_config {
  my $self = shift;

  $self->{config} = YAML::LoadFile($self->{index_path} . '/config.yaml')
    or throw_fault("Could not load state from $self->{index_path}/config.yaml: $!");
}

sub _create_writer {
  my $self = shift;
  my $create = shift;

  return if exists $self->{writer} and defined $self->{analyzer};

  throw_fault("_create_analyzer() must be called first")
      if ! exists $self->{analyzer};
  throw_fault("analyzer is empty") if ! defined $self->{analyzer};

  $self->{writer} = KinoSearch::InvIndexer->new(
      invindex => $self->{index_path},
      create   => $create,
      analyzer => $self->{analyzer},
  ) or throw_fault("error creating writer: $!");

  foreach my $field (qw(paths revision author date message)) {
      $self->{writer}->spec_field(name => $field);
  }

  return;
}

sub _delete_writer {
    my $self = shift;
    my $optimize = shift;

    $self->{writer}->finish(optimize => $optimize);
    delete $self->{writer};
    return;
}

sub _create_analyzer {
  my $self = shift;

  return if exists $self->{analyzer} and defined $self->{analyzer};

  eval "require $self->{config}{analyzer_class}"
      or throw_fault "require($self->{config}{analyzer_class} failed: $!";

  $self->{analyzer} = $self->{config}{analyzer_class}->new(
      @{ $self->{config}{analyzer_opts} }
  ) or throw_fault("error creating $self->{config}{analyzer_class} object: $!");
}

=head2 open

  $index->open();

Opens the index, in preparation for adding or removing entries.

=cut

sub open {
  my $self = shift;
  my $args = shift;

  throw_fault("$self->{index_path} does not exist")
      if ! -d $self->{index_path};
  throw_fault("$self->{index_path}/config.yaml does not exist")
      if ! -f "$self->{index_path}/config.yaml";

  $self->_load_config();
  $self->_create_analyzer();
}

=head2 add

  $index->add ({
      start_rev      => $start_rev,  # number, or 'HEAD'
      end_rev        => $end_rev,    # number, or 'HEAD'
  });

Add one or more log messages to the index.

The single argument is a hash ref, with the following possible keys.

=over

=item start_rev

The first revision to add to the index.  May be given as C<HEAD> to mean
the repository's most recent (youngest) revision.

This key is mandatory.

=item end_rev

The last revision to add to the index.  May be given as C<HEAD> to mean
the repository's most recent (youngest) revision.

This key is optional.  If not included then only the revision specified
by C<start_rev> will be indexed.

=back

Revisions from C<start_rev> to C<end_rev> are added inclusive.
C<start_rev> and C<end_rev> may be given in ascending or descending order.
Either:

  $index->add({ start_rev => 1, end_rev => 10 });

or

  $index->add({ start_rev => 10, end_rev => 1 });

In both cases, revisons are indexed in ascending order, so revision 1,
followed by revision 2, and so on, up to revision 10.

=cut

sub add {
  my $self = shift;
  my $args = validate(@_, {
      start_rev => {
	  type => SCALAR
      },
      end_rev => {
	  type => SCALAR,
	  optional => 1
      },
  });

  $args->{end_rev} = $args->{start_rev} unless defined $args->{end_rev};

  foreach (qw(start_rev end_rev)) {
    throw_args("$_ value '$args->{$_}' is invalid")
      if $args->{$_} !~ /^(?:\d+|HEAD)$/;
  }

  # Get start_rev and end_rev in to ascending order.
  if($args->{start_rev} ne $args->{end_rev} and $args->{end_rev} ne 'HEAD') {
    if(($args->{start_rev} eq 'HEAD') or ($args->{start_rev} > $args->{end_rev})) {
      ($args->{start_rev}, $args->{end_rev}) =
	($args->{end_rev}, $args->{start_rev});
    }
  }

  $self->_create_writer(0);

  SVN::Log::retrieve ({ repository => $self->{config}{repo_url},
                        start      => $args->{start_rev},
                        end        => $args->{end_rev},
                        callback   => sub { $self->_handle_log({ rev => \@_ }) }
		    });

  $self->_delete_writer(1);

  return 1;
}

sub _handle_log {
  my ($self, $args) = @_;

  my ($paths, $rev, $author, $date, $msg) = @{$args->{rev}};

  my $doc = $self->{writer}->new_doc();

  $doc->set_value(revision => $rev);

  # it's certainly possible to get a undefined author, you just need either
  # mod_dav_svn with no auth, or svnserve with anonymous write access turned
  # on.
  $doc->set_value(author => $author) if defined $author;

  # XXX might want to convert the date to something more easily searchable,
  # but for now let's settle for just not tokenizing it.
  $doc->set_value(date => $date);

  $doc->set_value(paths => join(' ', keys %$paths))
    if defined $paths; # i'm still not entirely clear how this can happen...

  $doc->set_value(message => $msg)
    unless $msg =~ m/^\s*$/;

  $self->{writer}->add_doc($doc);

  $self->{config}{last_indexed_rev} = $rev;

  $self->_save_config();

  return;
}

=head2 get_last_indexed_rev

  my $rev = $index->get_last_indexed_rev();

Returns the revision number that was most recently added to the index.

Most useful in repeated calls to C<add()>.

  # Loop forever.  Every five minutes wake up, and add all newly
  # committed revisions to the index.
  while(1) {
    sleep 300;
    $index->add({ start_rev => $index->get_last_indexed_rev() + 1,
                  end_rev   => 'HEAD' });
  }

The last indexed revision number is saved as a property of the index.

=cut

sub get_last_indexed_rev {
  my $self = shift;

  throw_fault("Can't call get_last_indexed_rev() before open()")
    unless exists $self->{config};
  throw_fault("Empty configuration") unless defined $self->{config};

  return $self->{config}{last_indexed_rev};
}

=head2 search

  my $hits = $index->search($query);

Search for $query and returns a KinoSearch::Search::Hits object which
contains the result.

=cut

sub search {
  my ($self, $query) = @_;

  throw_fault("open() must be called first")
      unless exists $self->{config};

  my $searcher = KinoSearch::Searcher->new(
      invindex => $self->{index_path},
      analyzer => $self->{analyzer},
  );

  return $searcher->search(query => $query);
}

=head1 QUERY SYNTAX

This module supports the Lucene query syntax, described in detail at
L<http://lucene.apache.org/java/docs/queryparsersyntax.html>.  A brief
overview follows.

=over

=item *

A query consists of one or more terms, joined with boolean operators.

=item *

A term is either a single word, or two or more words, enclosed in double
quotes.  So

  foo bar baz

is a different query from

  "foo bar" baz

The first searches for any of C<foo>, C<bar>, or C<baz>, the second
searches for any of C<foo bar>, or C<baz>.

=item *

By default, multiple terms in a query are OR'd together.  You may also
use C<AND>, or C<NOT> between terms.

  foo AND bar
  foo NOT bar

Use C<+> before a term to indicate that it must appear, and C<->
before a term to indicate that it must not appear.

  foo +bar
  -foo bar

=item *

Use parantheses to control the ordering.

  (foo OR bar) AND baz

=item *

Searches are conducted in I<fields>.  The default field to search is
the log message.  Other fields are indicated by placing the field name
before the term, separating them both with a C<:>.

Available fields are:

=over

=item revision

=item author

=item date

=item paths

=back

For example, to find all commit messages where C<nik> was the committer,
that contained the string "foo bar":

  author:nik AND "foo bar"

=back

=head1 DIAGNOSTICS

Any of these methods may fail.  If they do, they throw an
L<Exception::Class> subclass representing the error, trappable with
C<eval>.  Uncaught exceptions will cause the client application to
C<die>.

=head2 SVN::Log::Index::X::Args

Represents an error that occurs if the parameters given to any of the
methods are wrong.  This might be because there are too few or too many
parameters, or that the types of those parameters are wrong.

The text of the error can be retrieved with the C<error()> method.

=head2 SVN::Log::Index::X::Fault

Represents any other error.

=head2 Example

  my $e;
  eval { $index->search('query string'); };

  if($e = SVN::Log::Index::X::Fault->caught()) {
      print "An error occured: ", $e->string(), "\n";
  } elsif ($e = Exception::Class->caught()) {
      # Something else failed, rethrow the error
      ref $e ? $e->rethrow() : die $e;
  }

=head1 SEE ALSO

L<SVN::Log>, L<KinoSearch>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-svn-log-index@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Log-Index>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

The current maintainer is Nik Clayton, <nikc@cpan.org>.

The original author was Garrett Rooney, <rooneg@electricjellyfish.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 Nik Clayton.  All Rights Reserved.

Copyright 2004 Garrett Rooney.  All Rights Reserved.

This software is licensed under the same terms as Perl itself.

=cut

1;
