package SWISH;
use strict;

use vars (qw/$VERSION $errstr/);

$VERSION = 0.08;


sub connect {
    my $class = shift;
    my $driver = shift;


    unless ( $driver ) {
        $errstr = "Must supply Access Method";
        return;
    }

    eval { require "SWISH/$driver.pm"; };
    if ( $@ ) {
        $errstr = $@;
        return;
    }


    $driver = "SWISH::$driver";

    my $drh;

    eval { $drh = $driver->new( @_ ); };

    return $drh if ref $drh;

    $errstr = $driver->errstr || $@ || "Unknown error calling $driver->new()";
    return;
}

sub get_header {
    my ($self, $name, $index) = @_;

    # Return the entire hash
    die "SWISH headers not defined\n" unless ref $self->{_indexheaders};
    return $self->{_indexheaders} unless $name;

    # Return the default headers
    unless ( $index ) {
        return unless exists $self->{_indexheaders}{lc $name};
        return wantarray
               ? @{$self->{_indexheaders}{lc $name}}
               : $self->{_indexheaders}{lc $name}->[0];
    }


    # Return for a specific index file

    die "Invalid index file name '$index' passed to get_header()\n"
        unless exists $self->{_indexheaders}{INDEX}{$index};

    return unless exists $self->{_indexheaders}{INDEX}{$index}{lc $name};
    return wantarray
           ? @{$self->{_indexheaders}{INDEX}{$index}{lc $name}}
           : $self->{_indexheaders}{INDEX}{$index}{lc $name}->[0];


}



package SWISH::Results;
use strict;
use vars ( '$AUTOLOAD' );



sub new {
    my ( $class, $attr ) = @_;
    my %attr = %$attr if $attr;
    return bless \%attr, $class;
}

# Some default methods
sub disconnect {}
sub close {}

sub as_string {
    my $self = shift;
    my $delimiter = shift || ' ';

    my $blank = $delimiter =~ /^\s+$/;

    my @properties = qw/swishrank swishdocpath swishtitle swishdocsize/;

    push @properties, @{$self->{_settings}{properties}} if $self->{_settings}{properties};

    return join $delimiter, map { $blank && /\s/ ? qq["$_"] : $_ }
                            map( { $self->{$_} || '???' } @properties ),
                            "($self->{swishreccount}/$self->{total_hits})" ;
}


sub DESTROY {
}

sub field_names {
    my $self = shift;
    return grep { defined $self->{$_} } grep { !/^_/ } keys %$self;
}
    


sub AUTOLOAD {
    my $self = shift;

    if ( $AUTOLOAD =~ /.*::(\w+)/ ) {
        my $attribute = $1;

        return defined $self->{$attribute} ? $self->{$attribute} : undef;
    }

}


1;
__END__

=head1 NAME

SWISH - Perl interface to the SWISH-E search engine.

=head1 SYNOPSIS

    use SWISH;

    $sh = SWISH->connect('Fork',
        prog     => '/usr/local/bin/swish-e',
        indexes  => 'index.swish-e',
        results  => sub { print $_[1]->as_string,"\n" },
    );

    die $SWISH::errstr unless $sh;    

    $hits = $sh->query('metaname=(foo or bar)');

    print $hits ? "Returned $hits documents\n" : 'failed query:' . $sh->errstr . "\n";

    # Variations

    $sh = SWISH->connect('Fork',
        prog     => '/usr/local/bin/swish-e',
        indexes  => \@indexes,
        results  => \&results,      # callback
        headers  => \&headers,
        maxhits  => 200,
        timeout  => 20,
        -e       => undef,      # add just a switch

        version  => 2.2,
        output_format => {
            FIELDS = \@fields,
            FORMAT = \%format,
        },
    );

    $sh = SWISH->connect('Library', %parameters );
    $sh = SWISH->connect('Library', \%parameters );

    $sh = SWISH->connect('Server',
        port     => $port_number,
        host     => $host_name,
        %parameters,
    );

    $hits = $sh->query( $query_string );
    $hits = $sh->query( query => $query_string );

    $hits = $sh->query(
        query       => $query_string,
        results     => \&results,
        headers     => \&headers,
        properties  => [qw/title subject/],
        sortorder   => 'subject',
        startnum    => 100,
        maxhits     => 1000,
    );

    $error_msg = $sh->error unless $hits;


    # Unusual, but might want to use in your headers() callback.
    $sh->abort_query;

    @raw_results = $sh->raw_query( \%query_settings );


    $r = $sh->index( '/path/to/config' );
    $r = $sh->index( \%indexing_settings );

    # If all config settings were stored in the index header
    $r = $sh->reindex;


    $wordchars = $sh->get_header( 'WordCharacters' );
    $run_time  = $sh->get_header( 'run time');

    # swish-e version >= 2.2
    $wordchars = $sh->get_header( 'WordCharacters', $index_1 );

    $header_hash_ref  = $sh->get_header;
    $wordchars = $header_hash_ref->{wordchars}->[0];
    


    # returns words as swish sees them for indexing
    $search_words = $sh->swish_words( \$doc );

    $stemmed = $sh->stem_word( $word );


    $sh->disconnect;
    # or an alias: 
    $sh->close;

                   

=head1 DESCRIPTION

NOTE: This is alpha code and is not to be used in a production environment and the interface
is expected to change while swish 2.2 is being developed.  Testing and feedback
on using this module is B<gratefully appreciated>.

B<NOTE:> This module is now depreciated.  Use the SWISH::API module instead.
SWISH::API is bundled with Swish-e version 2.4.0, but will soon be available
from the CPAN.  SWISH::API is an xs interface to the Swish-e library.


This module provides a standard interface to the SWISH-E search engine.
With this interface your program can use SWISH-E in the standard forking/exec
method, or with the SWISH-E C library routines, and, if ever developed, the SWISH-E
server with only a small change.

The idea is that you can change the way your program accesses a SWISH-E index without having
to change your code.  Much, that is.

The module has been used (I didn't say "tested" did I?) on SWISH 1.2, SWISH 1.3, and SWISH 2.04 and later.
If you are using anything below 2.0 please try out the current version.  Indexing is much faster than with
the old versions of SWISH.

There are other programs called "swish".  Here we are only talking about SWISH-E, but sometimes will
use "SWISH", "swish", "swish-e", and sometimes "the program".  This is just being lazy while typing.

=head1 METHODS

Most methods will take either a hash, or a reference to a hash as a named parameter list.
Parameters set in the connect() method will be defaults, with parameters in other methods
overriding the defaults.

=over 4

=item B<connect>

C<$sh = SWISH-E<gt>connect( $access_method, \%params );>

The connect method uses the C<$access_method> to initiate a connection with SWISH-E.
What exactly that means depends on the access method.
The return value is an object used to access methods below, or undefined if failed.
Errors may be retrieved with the package variable $SWISH::errstr.

The SWISH module will load the driver for the type of access specified in the access method, if
available, by loading the C<SWISH::$access_method module>.

The Fork access method will attempt to run
swish when connecting to determine the version number.
B<Please> set the version number when calling C<connect> -- otherwise you will be forking an extra
process for every call to C<connect> you make.  (So, for example, don't call C<connect> under mod_perl
for every request.)

Parameters are described below in B<PARAMETERS>, but must include the path to the
swish binary program (and perhaps the swish-e version) when using the Fork access method,
and the index files when using the Library (or soon?) the Server access methods.

=item B<query>

C<$hits = $sh-E<gt>query( query =E<gt> $query, \%parameters );>

The query method executes a query and returns the number of hits found.  C<$hits> is undefined
if there is an error.  The last error may be retrieved with C<$sh-E<gt>error>.

query can be passed a single scalar as the search string, a hash, or a reference to a hash.
Parameters passed override the defaults specified in the connect method (except index file names cannot be
passed to C<query> with Library or Server access methods).

    Examples:
        $hits = $sh->query( 'foo or bar' );
        $hits = $sh->query( 'subject=(foo or bar)' );
        $hits = $sh->query( query => 'foo or bar' );
        $hits = $sh->query( %parameters );
        $hits = $sh->query( \%parameters );
        


=item B<raw_query>

A raw_query returns a list containing every output line from the query, including index
header lines.  This can generate a large list, so using C<query> with a callback function
is recommended.

    Example:
        @results = $sh->raw_query('foo');
        

=item B<get_header>

Returns the value of the supplied header name or C<undef> if the header is not set.

As of version 2.2 additional headers are returned with each query.  Some headers are related to the
the index file(s) being searched (e.g. WordCharacters), and some are not (e.g. Number of hits).

For example, the number of hits are not related to any index, rather to the results of the entire
query:

    $hits = $sh->get_header('Number of Hits');

On the otherhand, WordCharacters is related to a specific index file:

    # swish-e version >= 2.2 only
    $wchr1 = $sh->get_header('wordcharacters', $index1 );
    $wchr2 = $sh->get_header('wordcharacters', $index2 );

As a convenience, all headers may be retrieved without specifying the index file.  This is
useful when only searching with one index file, or when you know all the settings are the same
for all index files that you are searching.

So, when searching one index file, these are the same:

    $wchr = $sh->get_header('wordcharacters', $index1 );
    $wchr = $sh->get_header('wordcharacters');

Internally, the headers are stored as arrays.  So, if you have two index files as above,
calling in list context will retrieve all values.

    ($wchr1, $wchr2) = $sh->get_header('wordcharacters');

The headers are stored internally as a hash of arrays.  The arrays allows storage of multiple headers
of the same name.  You may retrieve this hash by calling get_header without any parameters:

    use Data::Dumper;
    my $headers = $sh->get_header;
    print Dumper $headers;


Under the "Fork" access method the headers will be available after the C<query> call,
otherwise the headers are available at any point after the C<connect> call (except for headers that
change on each query (e.g. Number of Hits);

Most application do not need such fine access to the headers returned by swish.  But, for example,
to correctly highlight terms you would need to know the wordcharacters setting used while indexing.

   my $wordchars = $sh->get_header( 'wordcharacters', $result->{swishdbfile} );


=item B<abort_query>

Calling $sh->abort_query within your callback handlers (C<results> and C<headers>) will terminate
the current request.  You could also probably just die() and get the same results.

=item B<index>

** To Be Implemented **

The index method creates a swish index file.  You may pass C<index> either
a path to a SWISH-E configuration file, or reference to a hash with the index parameters.

The parameters in the hash will be written to a temporary file
before indexing in with the Fork method.  If passing a reference to a hash, you may include a key B<tempfile>
that specifies the location of the temporary file.  Otherwise, /tmp will be assumed.

If a parameter is not passed it will look in the object for an attribute named B<indexparam>

=item B<reindex>

** To Be Implemented? **

This is a wish list method.  The idea is all the indexing parameters would be stored in the
header on an index so to all one would need to do to reindex is call swish with the name of
the index file.

=item B<stem_word>

** To Be Implemented **

stem_word returns the stem of the word passed.  This may be left to a separate module, but
could be require()d on the fly.  The swish stemming routine is needed to highlight search terms
when the index contains stemmed words.

=item B<swish_words>

** To Be Implemented **

swish_words takes a scalar or a reference to a scalar and tokenizes the words as swish would
do during indexing. The return value is a reference to an array where each element is a token.
Each token is also a reference to an array where the first element is the word, and the second
element is a flag indicating if this is an indexable word.  Confused?

This requires HTML::Parser (HTML::TokeParser?) to be installed.

The point of this is for enable phrase highlighting.  You can read your source and,
if lucky, highlight phrase found in searches.

    Example:
        $words = $sh->swish_words( 'This is a phrase of words' );
                                      0 1 2345   6  7 89  10

        $words->[0][0] is 'This'
        $words->[0][1] is 1 indicating that swish would have this indexed
        $words->[0][2] is 0 this is swish word zero
        $words->[0][3] is the stemmed version of 'This', if using stemming.

        $words->[1][0] is ' '
        $words->[1][1] is 0 indicating that swish would not index
        $words->[1][2] is undef (not a word)
    
        $words->[2][0] is 'is'
        $words->[2][1] is 0 indicating that swish would not index (stop word)
        $words->[2][2] is undef (not a word)

        $words->[6][0] is 'phrase'
        $words->[6][1] is 1 indicating that it is a swish word
        $words->[6][2] is 2 this is the second swish word
                          ('is' and 'a' are stop words)

=back

=head1 ACCESS METHODS

Two access methods are available:  `Fork' and `Library'.

The B<Fork> method requires a C<prog> parameter passed to the C<connect> class method.
This parameter specifies the location of the swish-e executable program

The B<Library> method does not require any special parameters, but does require that the
SWISH::Library module is installed and can be found within @INC.

The B<Server> method is a proposed method to access a SWISH-E server.  Required
parameters may include C<port>, C<host>, C<user>, and C<password> to gain access
to the SWISH-E server.

=head1 PARAMETERS

Parameters can be specified when starting a swish connection.  The parameters are stored
as defaults within the object and will be used on each query, unless other overriding
parameters are specified in an individual method call.

Most parameters have been given longer names (below).  But, any valid parameter may be specified
by using the standard dash followed by a letter.  That is:

    maxhits => 100,

is the same as

    -m      => 100,

And to add just a switch without a parameter:

    -e      => undef,

Keep in mind that not all switches may work with all access methods.  The swish
binary may have different options than the swish library.
    


=over 4

=item B<prog>

prog defines the path to the swish executable.  This is only used in the B<Fork> access method.

    Example:
        $parameters{ path } = '/usr/local/bin/swish-e';

=item B<indexes>

indexes defines the index files used in the next query or raw_query operation.

    Examples:
        $parameters{ indexes } = '/path/to/index.swish-e';
        $parameters{ indexes } = ['/path/to/index.swish-e', '/another/index'];

=item B<query>

query defines the search words (-w switch for SWISH-E)

    Example:
        $parameters{ query } = 'keywords=(apples or oranges) and subject=(trees)';

=item B<tags> or B<context>

tags (or the alias context) is a string that defines where to look in a HTML document (-t switch)

=item B<properties>

properties defines which properties to return in the search results.
Properties must be defined during indexing.
You must pass an array reference if using more than one property.

    Examples:
        $sh = query( query => 'foo', properties => 'title' );
        $sh = query( query => 'foo', properties => [qw/title subject/] );


See also B<output_format> for another way to access properties.

=item B<maxhits>

Define the maximum number of results to return.  Currently, If you specify more than one index
file maxhits is B<per index file>.

=item B<startnum>

Defines the starting number in the results.  This is used for generating paged results.
Should there be pagesize and pagenum parameters?

=item B<sortorder>

Sorts the results based on properties listed.  Properties must be defined during indexing.
You may specify ascending or descending sorts in future version of swish.

    Example:
        $parameters{ sortorder } = 'subject';

        # under developement
        $parameters{ sortorder } = [qw/subject category/];
        $parameters{ sortorder } = [qw/subject asc category desc/];

=item B<start_date>

** Not implemented **

Specify a starting dates in unix seconds.  Only results after this date will be returned.

=item B<end_date>

** Not implemented **

Ending date in unix seconds.


=item B<results>

results defines a callback subroutine.  This routine is called for each result returned
by a query.

    Example:
        $parameters{ results } = \&display_results
        $parameters{ results } = sub { print $_[1]->file, "\n" };

Two paramaters are passed: the current search object (created by C<connect>) and
an object blessed into the SWISH::Results class.  There are methods for a formatted string, for each
result field, and for accessing properties.


    Examples:

        sub display_results {
            my ($sh, $hit) = @_;

            # Display as a formatted string (in version <= 2.0 format)
            $hit->as_string;

            # Get the list of field names
            # Only returns defined fields
            
            my @fields = $hit->field_names;
            print "Field '$_' = '", $hit->$_, "'\n" for sort @fields;
        }

As of SWISH-E 2.2 all data is stored in the index as properties.  For backward compatibility, SWISH-E returns the standard
fields called C<swishrank>, C<swishdocpath>, C<swishtitle>, and C<swishdocsize>.  Other fields may be available, so use the
B<field_names> method to get a complete list of fields.  Use the field name as the method name to retrieve the data.
That is,

    $title = $hit->swishtitle

will return the title of the document.  Here's a list of the field names -- more may be added as time goes on.

Standard fields available before version 2.2:

    swishrank     - score (rank) returned by swish
    swishdocpath  - filename/URL of the document indexed
    swishtitle    - doc title (HTML only)
    swishdocsize  - doc size


Standar fields available before version 2.2:

    swishrank
    swishdocpath
    swishtitle
    swishlastmodified - last modified date
    swishdescription  - document summary
    swishstartpos     - offset within the document
    swishdocsize      
    swishdbfile       - index file where the result was found

Additional fields that are available in all versions:

    total_hits        - total hits found for the query (not just maxhits)
    swishreccount     - result number (sequence)


Property values are returned by the same method:

    $property_name_one = $hit->prop1

When C<prop1> is the property name passed in the
C<connect> or C<query> method.  Properites can be added to the defaults listed above by using
the C<properties> parameter.  Otherwise, property values listed in C<output_format> (see below) will be available
(along with only the other fields listed in C<output_format>).

Field names are case sensitive -- you must ask for the same property (including case) as you specified when making the
query. See SWISH-E documentation for more information.

B<Exception Handling>

The callback routines (C<results> and C<headers>)
are called while inside an eval block (the eval block is used to for the timeout feature).
If you die within your C<results> and C<headers> handlers the program will NOT exit,
but any message you pass to die() will be available in $sh->errstr.
In general, do as little as possible with your callback routines.

The SWISH::Results class is currently within the SWISH module.  This may change.        

=item B<output_format>

This feature requires SWISH-E 2.2 or above.

This can be used to specify what fields are returned by swish (and their format).  You must pass a
hash reference that contains two keys, C<FIELDS> (an array reference) and C<FORMAT> (a hash reference).

    $hits = $sh->query( {
        query => 'metaname=(foo or bar)',
        output_format => {
            FIELDS  => [qw/
                swishrank
                swishdocpath
                swishtitle
                swishlastmodified
                property_one
            ]/,
            FORMAT => {
                swishlastmodified => '%d',
            },
        }, );
            
The above tells swish to return only the fields specified in the FIELDS array, plus to apply the
C<%d> format specification to the last modified date.
The fields listed above are available are available in your C<results> callback subroutine:

   sub display_results {
        my ($sh, $hit) = @_;

        my $prop = $hit->property_one;
        my $unix_time = $hit->swishlastmodified;
        ...

   }
   
See the SWISH-E documentation for a description of the available format specifications.

=item B<-x> Format specification

This feature requires SWISH-E 2.2 or above.

When the C<-x> switch is used it is passed B<directly> to swish-e.  This provides direct access
to the swish-e output format feature, but requires you to parse the results, and the query will
return an error C<Failed to find results> since the module will have not parsed any results.

This method is useful if you want more control over the output, or want to tweak out a tiny bit more
speed.

When using C<-x> your B<results> callback function will receive two parameters, the swish object and
the raw line (with newlines removed).

Your B<format> you specify needs should end with a new line, or results may not be what you expect.  For example, the
Fork access method reads results from swish one line at a time.  If you fail to place a newline code
in your format then all results will be returned as a single line.

For example, you can do this:

    $options{'-x'} = 'Rank: <swishrank>, File: <swishdocpath>\n';

Important: Note the use of single quotes to prevent \n from being converted to a new line.    

Then in your callbac routine:

   sub display_results {
        my ($sh, $chomped_line ) = @_;

        print $chomped_line,"\n";
   }



=item B<headers>

headers defines a callback subroutine.  This routine is called for each result returned
by a query.

    Example:
        $parameters{ headers } = \&headers;

Your callback subroutine is called with four parameters: the current object, the header and the value,
and the current index file that applies, if any.

    sub headers {
        my ( $sh, $header, $value, $cur_index ) = @_;
        print "$header: $value\n";
    }

The C<$cur_index> will be the name of the index file the header is related to, if any, otherwise it
will be undefined.

In general, it will be better to call the C<headers> method.

=item B<timeout>

timeout is the number of seconds to wait before aborting a query request.
Don't spend too much time in your results callback routine if you are using a timeout.
Timeout is emplemented as a $SIG{ALRM} handler and funny things happen with perl's signal
handlers.



=back

=head1 TO DO

=over 4

How to detect a new index if library holds the file open?

Is it ok to change index files on the same object?
Does the library keep the index file open between requests?

Interface for Windows platform?

=back

=head1 SEE ALSO

http://sunsite.berkeley.edu/SWISH-E/

=head1 AUTHOR

Bill Moseley E<lt>moseley@hank.orgE<gt>


=cut
