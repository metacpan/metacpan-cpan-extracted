
=head1 NAME

MyConText - Indexing documents with MySQL as storage

=cut

package MyConText;
use strict;

use vars qw($errstr $VERSION);
$errstr = undef;
$VERSION = '0.49';

my %DEFAULT_PARAMS = (
	'num_of_docs' => 0,	# statistical value, should be maintained
	'word_length' => 30,	# max length of words we index

	'protocol' => 40,	# we only support protocol with the same numbers

	'blob_direct_fetch' => 20,	# with the blob store, when we stop searching
				# and fetch everything at once
	'data_table' => undef,	# table where the actual index is stored
	'name_length' => 255,	# for filenames or URLs, what's the max length

	'word_id_bits' => 16,	# num of bits for word_id (column store)
	'doc_id_bits' => 16,	# num of bits for doc_id
	'count_bits' => 8,	# num of bits for count value
	'position_bits' => 32,	# num of bits for word positions

	'backend' => 'blob',	# what database backend (way the data is
				# stored) we use
	'frontend' => 'none',	# what application frontend we use (how
				# the index behaves externaly)
	'filter' => 'map { lc $_ }',
	'splitter' => ' $data =~ /(\w{2,$word_length})/g',
				# can use the $data and $word_length
				# variables
	'init_env' => 'use locale'
	);
my %backend_types = (
	'blob' => 'MyConText::Blob',
	'column' => 'MyConText::Column',
	'phrase' => 'MyConText::Phrase',
	);
my %frontend_types = (
	'none' => 'MyConText',
	'default' => 'MyConText',
	'file' => 'MyConText::File',
	'string' => 'MyConText::String',
	'url' => 'MyConText::URL',
	'table' => 'MyConText::Table',
	);

use vars qw! %BITS_TO_PACK %BITS_TO_INT %BITS_TO_PRECISION %PRECISION_TO_BITS !;
%BITS_TO_PACK = qw! 0 A0 8 C 16 S 32 L !;
%BITS_TO_INT = qw! 8 tinyint 16 smallint 24 mediumint 32 int 64 bigint !;
%BITS_TO_PRECISION = qw! 8 4 16 6 24 9 32 11 !;
%PRECISION_TO_BITS = map { ( $BITS_TO_PRECISION{$_} => $_ ) } keys %BITS_TO_PRECISION;

# Open reads in the information about existing index, creates an object
# in memory
sub open {
	my ($class, $dbh, $TABLE) = @_;
	$errstr = undef;

	# the $dbh is either a real dbh of a DBI->connect parameters arrayref
	my $mydbh = 0;
	if (ref $dbh eq 'ARRAY') {
		$dbh = DBI->connect(@$dbh) or
				do { $errstr = $DBI::errstr; return; };
		
		$mydbh = 1;
		}

	# load the parameters to the object
	my %PARAMS = %DEFAULT_PARAMS;
	my $sth = $dbh->prepare("select * from $TABLE");
	$sth->{'PrintError'} = 0;
	$sth->{'RaiseError'} = 0;
	$sth->execute or do {
		if (not grep { $TABLE eq $_ }
					MyConText->list_context_indexes($dbh)) {
			$errstr = "ConText index $TABLE doesn't exist.";
			}
		else { $errstr = $sth->errstr; }
		return;
		};
	while (my ($param, $value) = $sth->fetchrow_array) {
		$PARAMS{$param} = $value;
		}
	my $self = bless {
		'dbh' => $dbh,
		'table' => $TABLE,
		%PARAMS,
		}, $class;
	my $data_table = $self->{'data_table'};
	
	# we should disconnect if we've opened the dbh here
	if ($mydbh) { $self->{'disconnect_on_destroy'} = 1; }

	# some basic sanity check
	defined $dbh->selectrow_array("select count(*) from $data_table")
		or do { $errstr = "Table $data_table not found in the database\n"; return; };


	# load and set the application frontend
	my $front_module = $frontend_types{$PARAMS{'frontend'}};
	if (defined $front_module) {
		if ($front_module ne $class) {
			eval "use $front_module";
			die $@ if $@;
			}
		bless $self, $front_module;
		$self->_open_tables;
		}
	else { $errstr = "Specified frontend type `$PARAMS{'frontend'}' is unknown\n"; return; }

	# load and set the backend (actual database access) module
	my $back_module = $backend_types{$PARAMS{'backend'}};
	if (defined $back_module) {
		eval "use $back_module";
		die $@ if $@;
		$self->{'db_backend'} = $back_module->open($self);
		}
	else { $errstr = "Specified backend type `$PARAMS{'backend'}' is unknown\n"; return; }

	# finally, return the object
	$self;
	}

# Create creates tables in the database according to the options, then
# calls open to load the object to memory
sub create {
	my ($class, $dbh, $TABLE, %OPTIONS) = @_;
	$errstr = undef;
	my $mydbh = 0;
	if (ref $dbh eq 'ARRAY') {
		$dbh = DBI->connect(@$dbh) or
				do { $errstr = $DBI::errstr; return; };
		$mydbh = 1;
		}

	my $self = bless {
		'dbh' => $dbh,
		'table' => $TABLE,
		%DEFAULT_PARAMS,
		%OPTIONS
		}, $class;

	$self->{'data_table'} = $TABLE.'_data'
					unless defined $self->{'data_table'};

	my $CREATE_PARAM = <<EOF;
		create table $TABLE (
			param varchar(16) binary not null,
			value varchar(255),
			primary key (param)
			)
EOF
	$dbh->do($CREATE_PARAM) or do { $errstr = $dbh->errstr; return; };
	push @{$self->{'created_tables'}}, $TABLE;

	# load and set the frontend database structures
	my $front_module = $frontend_types{$self->{'frontend'}};
	if (defined $front_module) {
		eval "use $front_module";
		die $@ if $@;
		bless $self, $front_module;
		$errstr = $self->_create_tables;
		if (defined $errstr) { $self->clean_failed_create; return; }
		}
	else { $errstr = "Specified frontend type `$self->{'frontend'}' is unknown\n"; $self->clean_failed_create; return; }

	# create the backend database structures
	my $back_module = $backend_types{$self->{'backend'}};
	if (defined $back_module) {
		eval "use $back_module";
		die $@ if $@;
		$errstr = $back_module->_create_tables($self);
		if (defined $errstr) { $self->clean_failed_create; return; }
		}
	else { $errstr = "Specified backend type `$self->{'backend'}' is unknown\n"; $self->clean_failed_create; return; }
	
	for (grep { not ref $self->{$_} } keys %$self) {
		$dbh->do("insert into $TABLE values (?, ?)", {}, $_, $self->{$_});
		}
	
	return $class->open($dbh, $TABLE);
	}

sub _create_tables {}
sub _open_tables {}

sub clean_failed_create {
	my $self = shift;
	my $dbh = $self->{'dbh'};
	for my $table (@{$self->{'created_tables'}}) {
		$dbh->do("drop table $table");
		}
	}

sub drop {
	my $self = shift;
	my $dbh = $self->{'dbh'};
	for my $tag (keys %$self) {
		next unless $tag =~ /(^|_)table$/;
		$dbh->do("drop table $self->{$tag}");
		}
	1;
	}
sub errstr {
	my $self = shift;
	ref $self ? $self->{'errstr'} : $errstr;
	}

sub list_context_indexes {
	my ($class, $dbh) = @_;
	my %tables = map { ( $_->[0] => 1 ) }
			@{$dbh->selectall_arrayref('show tables')};
	my %indexes = ();
	for my $table (keys %tables) {
		local $dbh->{'PrintError'} = 0;
		local $dbh->{'RaiseError'} = 0;
		if ($dbh->selectrow_array("select param, value from $table
				where param = 'data_table'")) {
			$indexes{$table} = 1;
			}
		}
	return sort keys %indexes;
	}

sub index_document {
	my ($self, $id, $data) = @_;
	return unless defined $id;

	my $dbh = $self->{'dbh'};

	my $param_table = $self->{'table'};

	my $adding_doc = 0;

	my $adding = 0;
	if (not defined $self->{'max_doc_id'} or $id > $self->{'max_doc_id'}) {
		$self->{'max_doc_id'} = $id;
		my $update_max_doc_id_sth =
			( defined $self->{'update_max_doc_id_sth'}
				? $self->{'update_max_doc_id_sth'}
				: $self->{'update_max_doc_id_sth'} = $dbh->prepare("replace into $param_table values (?, ?)"));
		$update_max_doc_id_sth->execute('max_doc_id', $id);
		$adding_doc = 1;
		}

	my $init_env = $self->{'init_env'};	# use packages, etc.
	eval $init_env if defined $init_env;
	print STDERR "Init_env failed with $@\n" if $@;

	$data = '' unless defined $data;
	return $self->{'db_backend'}->parse_and_index_data($adding_doc,
		$id, $data);
	}

# used for backends that need a count for each of the words
sub parse_and_index_data_count {
	my ($backend, $adding_doc, $id, $data) = @_;
		## note that this is run with backend object
	my $self = $backend->{'ctx'};

	my $word_length = $self->{'word_length'};
	# this needs to get parametrized (lc, il2_to_ascii, parsing of
	# HTML tags, ...)
	
	my %words;

	use locale;
	my $filter = $self->{'filter'} . ' ' . $self->{'splitter'};
	for my $word ( eval $filter ) {
		$words{$word} = 0 if not defined $words{$word};
		$words{$word}++;
		} 

	my @result;
	if ($adding_doc) {
		@result = $backend->add_document($id, \%words);
		}
	else {
		@result = $backend->update_document($id, \%words);
		}

	if (wantarray) {
		return @result;
		}
	return $result[0];
	}

# used for backends where list of occurencies is needed
sub parse_and_index_data_list {
	my ($backend, $adding_doc, $id, $data) = @_;
		## note that this is run with backend object
	my $self = $backend->{'ctx'};

	my $word_length = $self->{'word_length'};
	# this needs to get parametrized (lc, il2_to_ascii, parsing of
	# HTML tags, ...)
	
	my %words;

	use locale;
	my $filter = $self->{'filter'} . ' ' . $self->{'splitter'};

	my $i = 0;
	for my $word ( eval $filter ) {
		push @{$words{$word}}, ++$i;
		} 

	my @result;
	if ($adding_doc) {
		@result = $backend->add_document($id, \%words);
		}
	else {
		@result = $backend->update_document($id, \%words);
		}

	if (wantarray) {
		return @result;
		}
	return $result[0];
	}
sub delete_document {
	my $self = shift;
	$self->{'db_backend'}->delete_document(@_);
	}

sub contains_hashref {
	my $self = shift;
	my $filter = $self->{'filter'};
	$self->{'db_backend'}->contains_hashref(eval $filter.' @_');
	}
sub contains {
	my $self = shift;
	my $res = $self->contains_hashref(@_);
	if (not $self->{'count_bits'}) { return keys %$res; }
	return sort { $res->{$b} <=> $res->{$a} } keys %$res;
	}
sub econtains_hashref {
	my $self = shift;
	my $docs = {};
	my $word_num = 0;

	my $is_some_plus = grep /^\+/, @_;

	for my $word ( map { /^\+(.+)$/s } @_) {
		$word_num++;
		my $oneword = $self->contains_hashref($word);
		if ($word_num == 1) { $docs = $oneword; next; }
		for my $doc (keys %$oneword) {
			$docs->{$doc} += $oneword->{$doc} if defined $docs->{$doc};
			}
		for my $doc (keys %$docs) {
			delete $docs->{$doc} unless defined $oneword->{$doc};
			}
		}

	for my $word ( map { /^([^+-].*)$/s } @_) {
		my $oneword = $self->contains_hashref($word);
		for my $doc (keys %$oneword) {
			if ($is_some_plus) {
				$docs->{$doc} += $oneword->{$doc} if defined $docs->{$doc};
				}
			else {
				$docs->{$doc} = 0 unless defined $docs->{$doc};
				$docs->{$doc} += $oneword->{$doc};
				}
			}
		}

	for my $word ( map { /^-(.+)$/s } @_) {
		my $oneword = $self->contains_hashref($word);
		for my $doc (keys %$oneword) {
			delete $docs->{$doc};
			}
		}
	$docs;
	}
sub econtains {
	my $self = shift;
	my $res = $self->econtains_hashref(@_);
	if (not $self->{'count_bits'}) { return keys %$res; }
	return sort { $res->{$b} <=> $res->{$a} } keys %$res;
	}

1;

=head1 SYNOPSIS

    use MyConText;
    use DBI;
    # connect to database (regular DBI)
    my $dbh = DBI->connect('dbi:mysql:database', 'user', 'passwd');
    # create a new index
    my $ctx = MyConText->create($dbh, 'ctx_web_1',
		'frontend' => 'string', 'backend' => 'blob');
    # or open existing one
    # my $ctx = MyConText->open($dbh, 'ctx_web_1');

    # index documents
    $ctx->index_document('krtek', 'krtek leze pod zemi');
    $ctx->index_document('jezek', 'Jezek ma ostre bodliny.');

    # search for matches
    my @documents = $ctx->contains('krtek');
    my @docs = $ctx->econtains('+krtek', '-Jezek');


=head1 DESCRIPTION

MyConText is a pure man's solution for indexing contents of documents.
It uses the MySQL database to store the information about words and
documents and provides Perl interface for indexing new documents,
making changes and searching for matches.  For MyConText, a document
is nearly anything -- Perl scalar, file, Web document, database field.

The basic style of interface is shown above. What you need is a MySQL
database and a DBI with DBD::mysql. Then you create a MyConText index
-- a set of tables that maintain all necessary information. Once created
it can be accessed many times, either for updating the index (adding
documents) or searching.

MyConText uses one basic table to store parameters of the index. Second
table is used to store the actual information about documents and words,
and depending on the type of the index (specified during index creation)
there may be more tables to store additional information (like
conversion from external string names (eg. URL's) to internal numeric
form). For a user, these internal thingies and internal behaviour of the
index are not important. The important part is the API, the methods to
index document and ask questions about words in documents. However,
certain understanding of how it all works may be usefull when you are
deciding if this module is for you and what type of index will best
suit your needs.

=head2 Frontends

From the user, application point of view, the MyConText index stores
documents that are named in a certain way, allows adding new documents,
and provides methods to ask: "give me list of names of documents that
contain this list of words". The MyConText index doesn't store the
documents itself. Instead, it stores information about words in the
documents in such a structured way that it makes easy and fast to look
up what documents contain certain words and return names of the
documents.

MyConText provides a couple of predefined frontend classes that specify
various types of documents (and the way they relate to their names).

=over 4

=item default

By default, user specifies the integer number of the document and the
content (body) of the document. The code would for example read

	$ctx->index_document(53, 'zastavujeme vyplaty vkladu');

and MyConText will remember that the document 53 contains three words.
When looking for all documents containing word (string) vklad, a call

	my @docs = $ctx->contains('vklad%');

would return numbers of all documents containing words starting with
'vklad', 53 among them.

So here it's user's responsibility to maintain a relation between the
document numbers and their content, to know that a document 53 is about
vklady. Perhaps the documents are already stored somewhere and have
inique numeric id.

=item string

Frontend B<string> allows the user to specify the names of the documents as
strings, instead of numbers. Still the user has to specify both the
name of the document and the content:

	$ctx->index_document('upozorneni',
			'Odstrante z dosadu deti!');

After that,

	$ctx->contains('deti')

will return 'upozorneni' as one of the names of documents with word
'deti' in it.

=item file

To index files, use the frontend B<file>. Here the content of the document
is clearly the content of the file specified by the filename, so in
a call to index_document, only the name is needed -- the content of the
file is read by the MyConText transparently:

	$ctx->index_document('/usr/doc/FAQ/Linux-FAQ');
	my @files = $ctx->contains('penguin');

=item url

Web document can be indexed by the frontend B<url>. MyConText uses LWP to
get the document and then parses it normally:

	$ctx->index_document('http://www.perl.com/');

=item table

You can have a MyConText index that indexes char or blob fields in MySQL
table. Since MySQL doesn't support triggers, you have to call the
index_document method of MyConText any time something changes in the
table. So the sequence probably will be

	$dbh->do('insert into the_table (id, data, other_fields)
		values (?, ?, ?)', {}, $name, $data, $date_or_something);
	$ctx->index_document($name);

When calling contains, the id (name) of the record will be returned. If
the id in the_table is numeric, it's directly used as the internal
numeric id, otherwise a string's way of converting the id to numeric
form is used.

=back

The structure of MyConText is very flexible and adding new frontend
(what will be indexed) is very easy.

=head2 Backends

While frontend specifies what is indexed and how the user sees the
collection of documents, backend is about low level database way of
actually storing the information in the tables. Three types are
available:

=over 4

=item blob

For each word, a blob holding list of all documents containing that word
is stored in the table, with the count (number of occurencies)
associated with each document number. That makes it for very compact
storage. Since the document names (for example URL) are internally
converted to numbers, storing and fetching the data is fast. However,
updating the information is very slow, since information concerning one
document is spread across all table, without any direct database access.
Updating a document (or merely reindexing it) requires update of all
blobs, which is slow.

The list of documents is stored sorted by document name so that
fetching an information about a document for one word is relatively
easy, still a need to update (or at least scan) all records in the table
makes this storage unsuitable for collections of documents that often
change.

=item column

The B<column> backend stores a word/document pair in database fields,
indexing both, thus allowing both fast retrieval and updates -- it's
easy to delete all records describing one document and insert new ones.
However, the database indexes that have to be maintained are large.

Both B<blob> and B<column> backends only store a count -- number of
occurencies of the word in the document (and even this can be switched
off, yielding just a yes/no information about the word's presence).
This allows questions like

	all documents containing words 'voda' or 'Mattoni'
		but not a word 'kyselka'

but you cannot ask whether a document contains a phrase 'kyselka
Mattoni' because such information is not maintained by these types of
backends.

=item phrase

To allow phrase matching, a B<phrase> backend is available. For each word
and document number it stores a blob of lists of positions of the word
in the document. A query

	$ctx->contains('kyselk%', 'Mattoni');

then only returns those documents (document names/numbers) where word
kyselka (or kyselky, or so) is just before word Mattoni.

=back

=head2 Mixing frontends and backends

Any frontend can be used with any backend in one MyConText index. You
can index Web documents with B<url> frontend and B<phrase> backend
to be able to find phrases in the documents. And you can use the
default, number based document scheme with B<blob> backend to use the disk
space as efficiently as possible -- this is usefull for example for
mailing-list archives, where we need to index huge number of documents
that do not change at all.

Finding optimal combination is very important and may require some
analysis of the document collection and manipulation, as well as the
speed and storage requirements. Benchmarking on actual target platform
is very usefull during the design phase.

=head1 METHODS

The following methods are available on the user side as MyConText API.

=over 4

=item create

	my $ctx = MyConText->create($dbh, $index_name, %opts);

The class method B<create> creates index of given name (the name of the
index is the name of its basic parameter table) and all necessary
tables, returns an object -- newly created index. The options that may
be specified after the index name define the frontend and backend types,
storage parameters (how many bits for what values), etc. See below for
list of create options and discussion of their use.

=item open

	my $ctx = MyConText->open($dbh, $index_name);

Opens and returns object, accessing specifies MyConText index. Since all
the index parameters and information are stored in the $index_name table
(including names of all other needed tables), the database handler and
the name of the parameter table are the only needed arguments.

=item index_document

	$ctx->index_document(45, 'Sleva pri nakupu stribra.');
	$ctx->index_document('http://www.mozilla.org/');

For the default and B<string> frontends, two arguments are expected -- the
name (number or string) of the document and its content. For B<file> and
B<url> frontends only the name of the document is needed. The method
returns number of words indexed (subject to wild change).

=item delete_document

	$ctx->delete_document('http://www.mozilla.org/');

Removes information about document from the index. Note that for B<blob>
backend this is very time consuming process.

=item contains

	my @docs = $ctx->contains('sleva', 'strib%');

Returns list of names (numbers or strings, depending on the frontend)
of documents that contain some of specified words.

=item econtains

	my @docs = $ctx->contains('sleva', '+strib%', '-zlato');

Econtains stands for extended contains and allows words to be prefixed
by plus or minus signs to specify that the word must or mustn't be
present in the document for it to match.

=item contains_hashref, econtains_hashref

Similar to B<contains> and B<econtains>, only instead of list of document
names, there methods return a hash reference to a hash where keys are
the document names and values are the number of occurencies of the
words.

=item drop

Removes all tables associated with the index, including the base
parameter table. Effectivelly destroying the index form the database.

=back

=head1 INDEX OPTIONS

Here we list the options that may be passed to MyConText->create call.
These allow to specify the style and storage parameters in great detail.

=over 4

=item backend

The backend type, default B<blob>, possible values blob, column and phrase
(see above for explanation).

=item frontend

The frontend type. The default frontend requires the user to specify
numeric id of the document together with the content of the document,
other possible values are string, file and url (see above for
more info).

=item word_length

Maximum length of words that may be indexed, default 30.

=item data_table

Name of the table where the actual data about word/document relation is
stored. By default, the name of the index (of the base table) with _data
suffix is used.

=item name_length

Any frontend that uses strings as names of documents needs to maintain
a conversion table from these names to internal integer ids. This value
specifies maximum length of these string names (URLs, file names, ...).

=item blob_direct_fetch

Only for blob backend. When looking for information about specific
document in the list stored in the blob, the blob backend uses division
of interval to find the correct place in the blob. When the interval
gets equal or shorter that this value, all values are fetched from the
database and the final search is done in Perl code sequentially.

=item word_id_bits

With column or phase backends, MyConText maintains a numeric id for each
word to optimize the space requirements. The word_id_bits parameter
specifies the number of bits to reserve for this conversion and thus
effectively limits number of distinct words that may be indexed. The
default is 16 bits and possible values are 8, 16, 24 or 32 bits.

=item word_id_table

Name of the table that holds conversion from words to their numeric id
(for column and phrase backends). By default is the name of the index
with _words suffix.

=item doc_id_bits

A number of bits to hold a numeric id of the document (that is either
provided by the user (with default frontend) or generated by the module
to accomplish the conversion from the string name of the document). This
value limits the maximum number of documents to hold. The default is 16
bits and possible values are 8, 16 and 32 bits for blob backend and 8,
16, 24 and 32 bits for column and phrase backends.

=item doc_id_table

Name of the table that holds conversion from string names of documents
to their numeric id, by default the name of the index with _docid
suffix.

=item count_bits

Number of bits reserved for storing number of occurencies of each word
in the document. The default is 8 and possible values are the same as
with doc_id_bits.

=item position_bits

With phrase backend, MyConText stores positions of each word of the
documents. This value specifies how much space should be reserved for
this purpose. The default is 32 bits and possible values are 8, 16 or 32
bits. This value limits the maximum number of words of each document
that can be stored.

=item splitter

MyConText allows the user to provide any Perl code that will be used to
split the content of the document to words. The code will be evalled
inside of the MyConText code. The default is

	$data =~ /(\w{2,$word_length})/g

and shows that the input is stored in the variable C<$data> and the code
may access any other variable available in the perl_and_index_data_*
methods (see source), especially C<$word_length> to get the maximum length
of words and C<$backend> to get the backend object.

The default value also shows that by default, the minimum length of
words indexed is 2.

=item filter

The output words of splitter (and also any parameter of (e)contains*
methods) are send to filter that may do further processing. Filter is
again a Perl code, the default is

	map { lc $_ }

showing that the filter operates on input list and by default does
conversion to lowercase (yielding case insensitive index).

=item init_env

Because user defined splitter or filter may depend on other things that
it is reasonable to set before the actual procession of words, you can
use yet another Perl hook to set things up. The default is

	use locale

=item table_name

For table frontend; this is the name of the table that will be indexed.

=item column_name

For table frontend; this is the name of the column in the table_name
that contains the documents -- data to be indexed. It can also have
a form table.column that will be used if the table_name option is not
specified.

=item column_id_name

For table frontend; this is the name of the field in table_name that
holds names (ids) of the records. If not specified, a field that has
primary key on it is used. If this field is numeric, it's values are
directly used as identifiers, otherwise a conversion to numeric values
is made.

=back

=head1 ERROR HANDLING

The create and open methods return the MyConText object on success, upon
failure they return undef and set error message in $MyConText::errstr
variable.

All other methods return reasonable (documented above) value on success,
failure is signalized by unreasonable (typically undef or null) return
value; the error message may then be retrieved by $ctx->errstr method
call.

=head1 VERSION

This documentation describes MyConText module version 0.49.

=head1 BUGS

Error handling needs more polishing.

We do not check if the stored values are larger that specified by the
*_bits parameters.

No CGI administration tool at the moment.

Econtains doesn't work with phrase backend.

No scoring algorithm implemented.

No support for stop words at the moment.

=head1 AUTHOR

(c) 1999 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

DBI(3), mycontextadmin(1).

=head1 OTHER PRODUCTS and why I've written this module

I'm aware of DBIx::TextIndex module and about UdmSearch utility, and
about htdig and glimpse on the non-database side of the world.

To me, using a database gives reasonable maintenance benefits. With
products that use their own files to store the information (even if the
storage algorithms are efficient and well thought of), you always
struggle with permissions on files and directories for various users,
with files that somebody accidently deleted or mungled, and making the
index available remotely is not trivial.

That's why I've wanted a module that will use a database as a storage
backend. With MySQL, you get remote access and access control for free,
and on many web servers MySQL is part of the standard equipment. So
using it for text indexes seemed natural.

However, existing DBIx::TextIndex and UdmSearch are too narrow-aimed to
me. The first only supports indexing of data that is stored in the
database, but you may not always want or need to store the documents in
the database as well. The UdmSearch on the other hand is only for web
documents, making it unsuitable for indexing mailing-list archives or
local data.

I believe that MyConText is reasonably flexible and still very
efficient. It doesn't enforce its own idea of what is good for you --
the number of options is big and you can always extend the module with
your own backend of frontend if you feel that those provided are not
sufficient. Or you can extend existing by adding one or two parameters
that will add new features. Of course, patches are always welcome.
MyConText is a tool that can be deployed in many projects. It's not
a complete environment since different people have different needs. On
the other hand, the methods that it provides make it easy to build
a complete solution on top of this in very short course of time.

I was primarily inspired by the ConText cartrige of Oracle server. Since
MySQL doesn't support triggers, it showed up that Perl interface will be
needed. Of course, porting this module to (for example) PostgreSQL
should be easy, so different name is probably needed. On the other hand,
the code is sometimes very MySQL specific to make the module work
efficiently, so I didn't want a name that would suggest that it's
a generic tool that will work with any SQL database.

=cut

