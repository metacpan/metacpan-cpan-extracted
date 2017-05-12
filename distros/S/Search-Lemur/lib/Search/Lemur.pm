package Search::Lemur;

use warnings;
use strict;
use Carp qw( carp ); 

use Search::Lemur::Result;
use Search::Lemur::ResultItem;
use Search::Lemur::Database;

use LWP;
use Data::Dumper;

use vars qw( $VERSION );

=head1 NAME

Lemur - class to query a Lemur server, and parse the results

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSYS

 use Search::Lemur;

 my $lem = Search::Lemur->new("http://url/to/lemur.cgi");

 # run some queries, and get back an array of results
 # a query with a single term:
 my @results1 = $lem->query("encryption");
 # a query with two terms:
 my @results2 = $lem->query("encryption MD5");

 # get corpus term frequency of 'MD5':
 my $md5ctf = $results2[1]->ctf();

=head1 DESCRIPTION

This module will make it easy to interact with a Lemur
Toolkit for Language Modeling and Information Retrieval 
server for information retreival exercises.  For more
information on Lemur, see L<http://www.lemurproject.org/>.  

This module takes care of all parsing of responses from
the server. You can just pass a query as a 
space-separated list of terms, and the module will give
you back an array of C<result> objects.

=cut


=head2 Main Methods

=over 2

=item new($url)

Create a new Lemur object, connecting to the given Lemur server.
The C<$url> should be a full URL, ending in something like 'lemur.cgi'.

=cut

sub new {
    my $class = shift;
    my $url;
    if (@_) { $url = shift; 
    } else { return undef; }
    my $self = { baseurl => $url,
                 db => 0,
                 n => undef,
                 fullurl => undef };
    bless $self, $class;
    $self->{fullurl} = $self->_makeurl();
    return $self;
}

=item url()

Return the URL of the Lemur server

=cut

sub url {
    my $self = shift;
    return $self->{baseurl};
}

=item listdb()

Get some information about the databases available

Returns an array of Lemur::Database objects.

=cut

sub listdb {
    my $self = shift;
    $self->_makeurl();
    my $url = $self->{fullurl} . "&d=?";
    my $result = $self->_strip($url);
    return $self->_makedbs($result);
}

=item d([num])

Set the database number to query.  This will specify the 
database number instead of just using the default databse 0.

If the C<num> is not specified, the the current database is returned.

=cut

sub d {
    my $self = shift;
    if (@_) { $self->{d} = shift; $self->_makeurl(); }
    return $self->{d};
}

    

=item v(string)

Make a query to the Lemur server.  The query should be a space-delimited 
list of query terms.  If the URL is has not been specified, this will die.

Be sure there is only one space between words, or something unexpected may 
happen.

Returns an array of results (See L<Lemur::result>).  There will
be a result for each query term.

=cut

# This method really just queries the server, and passes the response on to 
# &_parse(string). This was done to make testing easier, without having to 
# query a real server for testing.
sub v {
    my $self = shift;
    my $query = shift;
    $query =~ s/ +/ /g;
    croak("Something went wrong; I have no URL") unless $self->{baseurl};
    my @terms = split(/ +/, $query);
    my $url = $self->{fullurl};
    foreach my $term (@terms) {
        $url = "$url&v=$term";
    }
    return $self->_parse([$query, $self->_strip($url)]);
}

=item m(string)

Returns the lexicalized (stopped & stemmed) version of the given
word.  This is affected by weather or not the current database
is stemmed and/or stopworded.  Basically, this is the real word 
you will end up searching for.

Returns a string.

=cut

sub m {
    my $self = shift;
    my $word = shift;
    my $url = $self->{fullurl} . "&m=$word";
    my $return = $self->_strip($url);
    if ($return eq "[OOV]") { $return = ""; }
    return $return;
}

# parse information about available databases into an array of 
# Search::Lemur::Database objects
#
# string -> arrayref
sub _makedbs {
    my $self = shift;
    my $input = shift;
    my @input = split(/\n/, $input);
    my @return;
    my ($num, $title, $stop, $stem, $numdocs, 
        $numterms, $numuniq, $avgdoclen);
    while (scalar(@input) >= 1){
        my $line = shift(@input);
        if ($line =~ m/(\d*):  ([\w|\d|\s]*) (NOSTOP|STOP) (NOSTEMM|STEMM);/){
            $num = $1;
            $title = $2;
            $stop = ($3 eq "STOP") ? 1 : 0;
            $stem = ($4 eq "STEMM") ? 1 : 0;
        } elsif ($line =~ m/ NUM_DOCS = ?(\d*);/){
            $numdocs = $1;
        } elsif ($line =~ m/ NUM_UNIQUE_TERMS = ?(\d*);/){
            $numuniq = $1;
        } elsif ($line =~ m/ NUM_TERMS = ?(\d*);/){
            $numterms = $1;
        } elsif ($line =~ m/ AVE_DOCLEN = ?(\d*);/){
            $avgdoclen = $1;
        } elsif ($line =~ m/<BR>/){
            my $db = Search::Lemur::Database->_new($num, $title, $stop, 
                $stem, $numdocs, $numterms, $numuniq, $avgdoclen);
            push @return, $db;
        }
    }
    return \@return;
}

# parse the result from the server
#
# Takes a reference to an array with two items:
#   - a string containing the query terms, separated by spaces
#   - a string containing the response
# 
# returns array of results
sub _parse {
    my $self = shift;
    my $inputref = shift;
    my @input = @$inputref;
    my @terms = split(/ /, $input[0]);
#    print Dumper($input[1]);
    my @response = split(/\D+/, $input[1]);
    shift(@response) if ($response[0] eq ""); #TODO Why am I doing this? this makes tests fail.
    my $numterms = scalar(@terms);

    my @return;
    
    # build a result object for each term
    foreach my $term (@terms) {
#        print Dumper(@response);
        my $ctf = shift(@response);
        my $df = shift(@response);
        my $result = Search::Lemur::Result->_new($term, $ctf, $df);
        # build a resultItem object for each document
        for (my $i = 0; $i < $df; $i++){
            my $docid = shift(@response);
            my $doclen = shift(@response);
            my $tf = shift(@response);
            my $resultItem = Search::Lemur::ResultItem->_new($docid, $doclen, $tf);
            $result->_add($resultItem);
        }
        push(@return, $result);
    }

    return \@return;
}

# build the full url to use for all queries
# This url consists of the base url (ending in lemur.cgi) plus
# d=n (specifies the database) and n=x (the number of results
# to return.  If either of these are undef, then they are left
# off, and the server is free to use its defaults
#
# the n value seems to only affect the q= query, and not the
# inverted list v= query.
#
# returns a string, and updates the fullurl instance variable 
sub _makeurl {
    my $self = shift;
    my $return = $self->url() . "?g=p";
    if ($self->{d}) { $return = $return . "&d=$self->{d}"; }
    if ($self->{n}) { $return = $return . "&n=$self->{n}"; }
    $self->{fullurl} = $return;
    return $return;
}
    
# strip_: make a request to the server, and strip out anything
# useless
#
# This will get the result from the server, and strip put any 
# html, etc that is not useful to the parser.
#
# string -> string
#
# takes in a url argument to fetch, and returns the stripped 
# result.
sub _strip {
    my $self = shift;
    my $url = shift;
#    print "$url\n\n";
    my $ua = LWP::UserAgent->new;
    $ua->agent("Lemur.pm/$VERSION");
    my $req = HTTP::Request->new(GET => $url);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content('query=libwww-perl&mode=dist');
    # make request
    my $res = $ua->request($req);

    if ($res->is_success) {
        $res->content() =~ m/.*<BODY>\n\n((\s|\d|\n|\w|\[|\]|:|;|=|<|>)*?)\n<HR>/;
#        print $1 . "\n\n";
        return $1;
    }
    else {
        Carp::carp($res->status_line, "\n");
        return undef;
    }
}




=back

=head1 AUTHOR

Patrick Kaeding, C<< <pkaeding at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-search-lemur at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Lemur>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Lemur

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Lemur>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Lemur>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Lemur>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Lemur>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Patrick Kaeding, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Search::Lemur
