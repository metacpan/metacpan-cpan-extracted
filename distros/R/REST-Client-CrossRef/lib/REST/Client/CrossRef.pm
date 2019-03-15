package REST::Client::CrossRef;
use strict;
use warnings;
use Moo;

use JSON;
use URI::Escape;
use REST::Client;

#use Data::Dumper;
use Carp;
use Log::Any;
use HTTP::Cache::Transparent;

#use JSON::MultiValueOrdered;
#use YAML;
use JSON::Path;

use namespace::clean;

=head1 NAME

REST::Client::CrossRef - Read data from CrossRef using its REST API

=cut

our $VERSION = '0.007';

=head1 VERSION

Version 0.007

=cut

=head1 DESCRIPTION

This module use L<CrossRef REST API|https://github.com/CrossRef/rest-api-doc> to read the data from the CrossRef repository.

=cut

=head1 SYNOPSIS

   use Log::Any::Adapter( 'File', './log.txt', 'log_level'=> 'info');
   use REST::Client::CrossRef;

   #the mail address is added in the request's header
   #return the data without transformation

   my $cr = REST::Client::CrossRef->new(
      mailto        => 'you@somewhre.com', 
      spit_raw_data => 1,
   );

   #cache the data with HTTP::Cache::Transparent
   $cr->init_cache(
    {   BasePath => ".\cache",
        NoUpdate => 60 * 60,
        verbose  => 0
    });

   my $data =  $cr->journal_from_doi('10.1088/0004-637X/722/2/971');

   print Dumper($data), "\n";   #$data is a hash ref of the json data converted to perl

   #unfold the data to something like
   # field1/subfield1/subfield2 : value 
   #add an undef value after each item fields
   #output only the fields given with keys_to_keep, with the same ordering

   my $cr = REST::Client::CrossRef->new(
         mailto        => 'you@somewhere.com',
         add_end_flag  => 1,
         keys_to_keep => [
             ['author'], ['title'], ['container-title'],
             ['volume'],['issue'], ['page'],['issued/date-parts'], ['published-print/date-parts']
    ],);

    my $data = $cr->article_from_doi('10.1088/0004-637X/722/2/971');

    for my $row (@$data) {
        if (! $row) {
            print "\n";
            next;
         }
         while ( my ($f, $v) = each  %$row) {
            print "$f : $v \n";
        }
    }


    #display the item's fields in alphabetic order
    #add 'end of data' field after each item

    my $cr = REST::Client::CrossRef->new(
        mailto       => 'you@somewhre.com',
        add_end_flag => 1,
        sort_output => 1,
     );

    $cr->init_cache(
    {   BasePath => "C:\\Windows\\Temp\\perl",
        NoUpdate => 60 * 60,
        verbose  => 0
    });

    my @fields = (qw/author title/);
    my @values = (qw/allan electron/);

    #return 100 items by page

    $cr->rows(100);
    my $data = $cr->query_articles( \@fields, \@values );
    while () {
        last unless $data;

        for my $row (@$data) {
            print "\n" unless ($row);
            for my $field (keys %$row) {
                print $field, ": ", $row->{$field}. "\n";
            }
        }
        $data = $cr->get_next();
    }

    Example output:

    author : Wilke, Ingrid;
    MacLeod, Allan M.;
    Gillespie, William A.;
    Berden, Giel;
    Knippels, Guido M. H.;
    van der Meer, Alexander F. G.;
    container-title : Optics and Photonics News
    issue : 12
    issued/date-parts : 2002, 12, 1, 
    page : 16
    published-online/date-parts : 2002, 12, 1, 
    published-print/date-parts : 2002, 12, 1, 
    title : Detectors: Time-Domain Terahertz Science Improves Relativistic Electron-Beam Diagnostics
    volume : 13

    my $cr = REST::Client::CrossRef->new(
        mailto        => 'dokpe@unifr.ch',
        spit_raw_data => 0,
        add_end_flag  => 1,
        json_path     => [
            ['$.author[*]'],
            ['$.title'], 
            ['$.container-title'],
            ['$.volume'], ['$.issue'], ['$.page'], 
            ['$.issued..date-parts'],
            ['$.published-print..date-parts']
        ],
        json_path_callback => { '$.items[*].author[*]' => \&unfold_authors },
    );
    
    sub unfold_authors {
        my ($data_ar) = @_;
        my @res;
        for my $aut (@$data_ar) {
            my $line;
            if ( $aut->{affiliation} ) {
                my @aff;
                for my $hr ( @{$aut->{affiliation}} ) {
                    my @aff = values %$hr;
                    $aff[0] =~ s/\r/ /g;
                    $line .= " " . $aff[0];
                }
            }
            my $fn = (defined $aut->{given}) ?( ", " . $aut->{given} . "; " ): "; "; 
            push @res,  $aut->{family} . $fn . ($line // "");
        }
        return \@res;
    }

     my $data = $cr->article_from_doi($doi);
     next unless $data;
    for my $row (@$data) {
        if ( !$row ) {
            print "\n";
            next;
        }
        while ( my ( $f, $v ) = each %$row ) {
            print "$f : $v \n";
        }
    }

    Example of output:
    $.author[*] : Pelloni, Michelle;  University of Basel, Department of Chemistry, Mattenstrasse 24a, BPR 1096, CH 4002 Basel, Switzerland
    Cote, Paul;  School of Chemistry and Biochemistry, University of Geneva, Quai Ernest Ansermet 30, CH-1211 Geneva, Switzerland
    ....
    Warding, Tom.;  University of Basel, Department of Chemistry, Mattenstrasse 24a, BPR 1096, CH 4002 Basel, Switzerland
    $.title : Chimeric Artifact for Artificial Metalloenzymes
    $.container-title : ACS Catalysis
    $.volume : 8
    $.issue : 2
    $.page : 14-18
    $.issued..date-parts : 2018, 1, 24
    $.published-print..date-parts : 2018, 2, 2
      
     my $cr = REST::Client::CrossRef->new( mailto => 'you@somewher.com'
       ,keys_to_keep => [["breakdowns/id", "id"], ["location"], [ "primary-name", "breakdowns/primary-name", "name" ]],
      ); 

    $cr->init_cache(
        {   BasePath => "C:\\Windows\\Temp\\perl",
            NoUpdate => 60 * 60,
            verbose  => 0
        });

    $cr->rows(100);

    my $rs_ar = $cr->get_members;

    while () {
        last unless $rs_ar;
        for my $row_hr (@$rs_ar) {
             for my $k (keys  %$row_hr) {
                   print $k . " : " . $row_hr->{$k} . "\n";
             }
         } 
         $rs_ar = $cr->get_next();
     }

    Example of items in the output above

    id : 5007
    location : W. Struve 1 Tartu 50091 Estonia
    primary-name : University of Tartu Press

    id : 310
    location : 23 Millig Street Helensburgh Helensburgh Argyll G84 9LD United Kingdom
    primary-name : Westburn Publishers

    id : 183
    location : 9650 Rockville Pike Attn: Lynn Willis Bethesda MD 20814 United States
    primary-name : Society for Leukocyte Biology

=cut

has baseurl => ( is => 'ro', default => sub {'https://api.crossref.org'} );
has modified_since => ( is => 'ro' );

#has version => (is => 'ro', default => sub {'v1'} );

has rows => (
    is      => 'rw',
    default => sub {0},
    isa     => sub { croak "rows must be under 1000" unless $_[0] < 1000 }
);
has code    => ( is => 'rw' );
has sleep   => ( is => 'rw', default => sub {0} );
has log     => ( is => 'lazy' );
has client  => ( is => 'lazy' );
has decoder => ( is => 'lazy' );

=head2  C<$cr = REST::Client::CrossRef-E<gt>new( ... mailto =E<gt> your@email.here, ...)>

The email address is placed in the header of the page.
See L<https://github.com/CrossRef/rest-api-doc#good-manners--more-reliable-service>

=cut

has mailto => ( is => 'lazy', default => sub {0} );

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... sort_output =E<gt>1, ...)>

Rows can be sorted using the key name with sort_ouput => 1.
Default to 0.
In effect only if C<spit_raw_data> is false.

=cut

has sort_output => ( is => 'lazy', default => sub {0} );
has test_data   => ( is => 'lazy', default => sub {0} );

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... spit_raw_data =E<gt>1, ...)>

Display the data as a hashref if 0 or as an array ref of hasref, 
where each hashref is a row of key => value that can be sorted with sort_ouput => 1. 
C<spit_raw_data> default to 0.

=cut

has spit_raw_data => ( is => 'lazy', default => sub {0} );
has cursor        => ( is => 'rw' );
has page_start_at => ( is => 'rw',   default => sub {0} );

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... add_end_flag =E<gt>1, ...)>

Add undef after an item's fields.
Default to 1.

=cut

has add_end_flag => ( is => 'lazy', default => sub {1} );

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... keys_to_keep =E<gt> [[key1, key1a, ...], [key2], ... ], ...)>

An array ref of array ref, the inner array ref give a key name and the possible alternative keys for the same value, 
for example [ "primary-name", "breakdowns/primary-name", "name" ] in the member road (url ending with /members).
The keys enumeration starts below C<message>, or C<message> - C<items> if the result is a list.
This filters the values that are returned and preserves the ordering of the array ref given in argument.
The ouput is an array ref of hash ref, each hash having the key and the values. 
Values are flattened as string. In effect only if spit_raw_data is false.

=cut

has keys_to_keep => ( is => 'lazy' );

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... json_path =E<gt> [[$path1, path1a, ...], [path2], ... ], ...)>

An array ref of array ref, the inner array refs give a L<JSONPath|https://goessner.net/articles/JsonPath/>  
and the possible alternative path for the same value. See also L<JSON::Path>.
The json path starts below C<message>, or C<message> - C<items> if the result is a list.
The output, ordering, filtering and flattening is as above. In effect only if spit_raw_data is false.

=cut

has json_path => ( is => 'lazy' );

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... json_path_callback =E<gt> {$path =E<gt> \&some_function }>

An hash ref that associates a JSON path and a function that will be run on the data return by C<$jpath-E<gt>values($json_data)>.
The function must accept an array ref as first argument and must return an array ref.

=cut

has json_path_callback => ( is => 'lazy' );

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... json_path_safe =E<gt> "0", ... )>

To turn off the message C<non-safe evaluation, died at...> set this to 0.
Default to 1.

=cut

has json_path_safe => (is => 'lazy', default=> sub{1});

=head2 C<$cr = REST::Client::CrossRef-E<gt>new( ... version =E<gt> "v1", ... )>

To use a defined version of the api.
See L<https://github.com/CrossRef/rest-api-doc#api-versioning>

=cut

has version => ( is => 'ro' );

sub _build_client {
    my ($self) = @_;
    my $client = REST::Client->new();

#HTTP::Cache::Transparent::init( { BasePath => './cache', NoUpdate  => 15*60, verbose=>1 } );
#$self->cache()

    if ( $self->version ) {
        $self->log->notice( "< Crossref-API-Version: " . $self->version );
        $client->addHeader( 'api-version', $self->version );
    }
    if ( defined $self->mailto ) {

        #my $authorization = 'Bearer ' . $self->key;
        $self->log->notice( "< Mailto: " . $self->mailto );
        $client->addHeader( 'mailto', $self->mailto );

    }

    $client;
}

sub _build_decoder {
    my $self = shift;
    return JSON->new;

    #return JSON::MultiValueOrdered->new;

}

sub _build_log {
    my ($self) = @_;
    Log::Any->get_logger( category => ref($self) );
}

=head2 C<$cr-E<gt>init_cache( @args )> C<$cr-E<gt>init_cache( $hash_ref )>

See L<HTTP::Cache::Transparent>.
The array of args is passed to the object constructor.
The log file shows if the data has been fetch from the cache and if the server has been queryied to detect any change.

=cut

sub init_cache {
    my ( $self, @args ) = @_;
    my $href;
    if ( ref $args[0] eq "HASH" ) {
        $href = $args[0];
    }
    else {
        my %h;
        %h    = @args;
        $href = \%h;
    }
    HTTP::Cache::Transparent::init($href);
}

sub _build_filter {
    my ( $self, $ar ) = @_;

    #die Dumper $self->{keys_to_keep};
    # die "ar:" . Dumper $ar;
    my %filter;
    for my $filter_name (qw(keys_to_keep json_path)) {

        #  my %keys_to_keep;
        next if ( !exists $ar->{$filter_name} );

        #print "_build_filter: $filter_name\n";
        my $pos;
        my %pos_seen;
        my %key_seen;

        for my $ar ( @{ $self->{$filter_name} } ) {
            $pos++;
            for my $k (@$ar) {
                $filter{$k}           = $pos - 1;
                $pos_seen{ $pos - 1 } = 0;
                $key_seen{ $pos - 1 } = $k;
            }

        }
        $self->{pos_seen}     = \%pos_seen;
        $self->{key_seen}     = \%key_seen;
        $self->{$filter_name} = \%filter;
    }

}

sub BUILD {

    my ( $self, $ar ) = @_;
    croak "Can't use both keys_to_keep and json_path"
        if ( $ar->{json_path} && $ar->{keys_to_keep} );
    $self->_build_filter($ar);
}

sub _crossref_get_request {
    my ( $self, $path, $query_ar, %param ) = @_;
    return 1 if ( $self->test_data() );
    my $url = sprintf "%s%s%s", $self->baseurl,
        $self->version ? "/" . $self->version : "", $path;

    my @params = ();

    if ($query_ar) {

        for my $p (@$query_ar) {

            #print "$p\n";
            push @params, $p;

        }
    }
    for my $name ( keys %param ) {
        my $value = $param{$name};

      #location:United Kingdom space is uri_escape twice
      #push @params, uri_escape($name) . "=" . uri_escape($value) if ($value);
        push @params, $name . "=" . $value if ($value);

    }
    push @params, "rows=" . $self->rows     if ( $self->rows );
    push @params, "cursor=" . $self->cursor if ( $self->cursor );

    #if the first url as &offset=1 we missed the first item
    #1 in page_start_at means "paginate with offset"
    #offset : page_start_at -1
    push @params, "offset=" . ( $self->page_start_at - 1 )
        if ( $self->page_start_at && $self->page_start_at > $self->rows );
    $url .= '?' . join( "&", @params ) if @params > 0;

    #die Dumper @params;
    # The server asked us to sleep..
    if ( $self->sleep > 0 ) {
        $self->log->notice( "sleeping: " . $self->sleep . " seconds" );
        sleep $self->sleep;
        $self->sleep(0);
    }
    $self->log->notice(" ");
    $self->log->notice("requesting: $url");
    my $response = $self->client->GET($url);
    my $val      = $response->responseHeader('Backoff');
    my $backoff  = defined $val ? $val : 0;
    $val = $response->responseHeader('Retry-After');
    my $retryAfter = defined $val ? $val : 0;
    my $code = $response->responseCode();

    $self->log->notice("> Code: $code");
    $self->log->notice("> Backoff: $backoff");
    $self->log->notice("> Retry-After: $retryAfter");
    for my $k (qw/X-Cached X-Content-Unchanged X-No-Server-Contact/) {
        $self->log->notice( "> $k: " . $response->responseHeader($k) )
            if $response->responseHeader($k);
    }

    if ( $backoff > 0 ) {
        $self->sleep($backoff);
    }
    elsif ( $code eq '429' || $code eq '503' ) {
        $self->sleep( defined $retryAfter ? $retryAfter : 60 );
        return;
    }

    $self->log->notice( "> Content: " . $response->responseContent );

    $self->code($code);

    return unless $code eq '200';

    $response;
}

sub _get_metadata {
    my ( $self, $path, $query_ar, $filter, $select ) = @_;
    $self->log->notice( "test_data: ",
        ( $self->test_data() ? " 1 " : " 0 " ) );
    $self->page_start_at(0);
    my $response =
        $self->_crossref_get_request( $path,
        $query_ar, ( filter => $filter, select => $select ) );

    #   print Dumper $response;
    return unless $response;

    #my $hr        = decode_json $response->responseContent;

    my $hr =
          $self->test_data()
        ? $self->_decode_json( $self->test_data() )
        : $self->_decode_json( $response->responseContent );
    my $res_count = $hr->{message}->{'total-results'};

    #print $res_count;
    if ( defined $res_count && $res_count > 0 ) {

        # my $keys;
        # my $data_ar        = $hr->{message}->{items};
        my $returned_items = @{ $hr->{message}->{items} };
        $self->_set_cursor( $hr->{message}, $returned_items );

        #push @$keys, "items";
        #die $self->spit_raw_data;
        #$self->_display_data($hr);
    }
    return $self->_display_data($hr);
}

sub _get_page_metadata {
    my ( $self, $path, $param_ar ) = @_;

    my $response;
    my $out;
    $self->cursor(undef);
    if ($param_ar) {
        my $filter = join( ",", @$param_ar );

        $response =
            $self->_crossref_get_request( $path, undef,
            ( filter => $filter ) );
    }
    else {
        $response = $self->_crossref_get_request($path);
    }

    if ($response) {

        #my $hr        = decode_json $response->responseContent;
        my $hr =
              $self->test_data()
            ? $self->_decode_json( $self->test_data() )
            : $self->_decode_json( $response->responseContent );
        my $res_count = $hr->{message}->{'total-results'};

        if ( defined $res_count ) {

            # print "from metadata: ", $res_count, "\n";
            if ( $res_count > 0 ) {

                #die Dumper $hr->{message}->{items};
                my $returned_items_count = @{ $hr->{message}->{items} };

                $self->{last_page_items_count} = $returned_items_count;
                $out = $self->_display_data($hr);

            }
        }
        else {    #singleton
            $out = $self->_display_data($hr);

        }
    }

    return $out;

}

sub _display_data {
    my ( $self, $hr ) = @_;

    return $hr if ( $self->spit_raw_data );
    my $formatter = REST::Client::CrossRef::Unfolder->new();

    my $data_ar;
    if ( $hr->{message}->{items} ) {
        $data_ar = $hr->{message}->{items};
    }
    else {
        $data_ar = [ $hr->{message} ];
    }

    my @data;
    if ( defined $self->{json_path} ) {

        my %result;
        my %keys = %{ $self->{json_path} };
        my %selectors;
        $JSON::Path::Safe=$self->json_path_safe;
        for my $path ( keys %keys ) {

            #print $path, "\n";
            $selectors{$path} = JSON::Path->new($path);
        }

        for my $data_hr (@$data_ar) {

            for my $path ( keys %selectors ) {

                #my @val   = $jpath->values( $hr->{message} );
                my @val = $selectors{$path}->values($data_hr);

                if (   $self->{json_path_callback}
                    && $self->{json_path_callback}->{$path} )
                {
                    my @data;
                    my $cb = $self->{json_path_callback}->{$path};
                    eval { @data = @{ $cb->( \@val ) }; };
                    croak "Json callback failed : $@\n" if ($@);
                    $result{$path} = join( "\n", @data );

                }
                elsif (@val) {

                    my %res_part;
                    %res_part =
                        %{ $formatter->_unfold_array( \@val, [$path] ) };
                    @result{ keys %res_part } = values %res_part;
                }

            }

            push @data,
                @{ $self->_sort_output( $self->{json_path}, \%result ) };
        }

    }
    elsif ( defined $self->{keys_to_keep} ) {

        my $new_ar;

        #$data_ar :array ref of rows items
        $formatter->set_keys_to_keep( $self->{keys_to_keep} );

        for my $data_hr (@$data_ar) {

            #https://www.perlmonks.org/?node_id=1224994
            #my $result_hr = {};
            #$formatter->_unfold_hash($data_hr, undef, $result_hr);
            my $result_hr = $formatter->_unfold_hash($data_hr);

            #  $self->log->debug("display_data\n", Dumper $result_hr);
            push @data,
                @{ $self->_sort_output( $self->{keys_to_keep}, $result_hr ) };

        }

    }
    else { #neither json_path nor keys_to_keep defined, spit_raw_data set to 0

        for my $data_hr (@$data_ar) {
            my $val_hr = $formatter->_unfold_hash($data_hr);
            my @keys;
            if ( $self->{sort_output} ) {
                @keys = sort { lc($a) cmp lc($b) } keys %$val_hr;
            }
            else {
                @keys = keys %$val_hr;
            }
            for my $k (@keys) {
                push @data, { $k, $val_hr->{$k} };
            }

            push @data, undef if $self->add_end_flag;
        }

    }
    return \@data;
}

sub _sort_output {
    my ( $self, $filter_hr, $result_hr ) = @_;

    my @data;

    if ($filter_hr) {

        my %keys_to_keep = %{$filter_hr};
        my %pos_seen     = %{ $self->{pos_seen} };
        my %key_seen     = %{ $self->{key_seen} };
        $pos_seen{$_} = 0 foreach ( keys %pos_seen );

        my @item_data;
        for my $key ( keys %$result_hr ) {

            my $pos = $keys_to_keep{$key};
            next unless defined $pos;

            # print "pos undef for $key\n" unless defined $pos;
            #$key_unseen{$pos}= $key;
            $pos_seen{$pos} = 1;
            my $value =
                ( defined $result_hr->{$key} )
                ? $result_hr->{$key}
                : "";
            $self->log->debug( $key, " - ", $value );
            $item_data[$pos] = { $key => $value };

        }

        my @unseen = grep { !$pos_seen{$_} } keys %pos_seen;

        for my $pos (@unseen) {
            $item_data[$pos] = { $key_seen{$pos}, "" };

        }
        push @data, @item_data;
        push @data, undef if $self->add_end_flag;

    }
    else {
        my @keys;
        if ( $self->{sort_output} ) {
            @keys = sort { lc($a) cmp lc($b) } keys %$result_hr;
        }
        else {
            @keys = keys %$result_hr;
        }
        for my $k (@keys) {

            push @data, { $k, $result_hr->{$k} };
        }

        push @data, undef if $self->add_end_flag;
    }

    return \@data;

}

=head2 C<$cr-E<gt>rows( $row_value )>

Set the rows parameter that determines how many items are returned in one page

=cut

=head2 C<$cr-E<gt>works_from_doi( $doi )>

Retrive the metadata from the work road (url ending with works) using the article's doi.
Return undef if the doi is not found.
You may pass a select string with the format "field1,field2,..." to return only these fields.
Fields that may be use for selection are (October 2018):
abstract, URL, member, posted, score, created, degree, update-policy, short-title, license, ISSN, 
container-title, issued, update-to, issue, prefix, approved, indexed, article-number, clinical-trial-number, 
accepted, author, group-title, DOI, is-referenced-by-count, updated-by, event, chair, standards-body, original-title, 
funder, translator, archive, published-print, alternative-id, subject, subtitle, published-online, publisher-location, 
content-domain, reference, title, link, type, publisher, volume, references-count, ISBN, issn-type, assertion, 
deposited, page, content-created, short-container-title, relation, editor.
Use keys_to_keep or json_path to define an ordering in the ouptut. Use select to filter the fields to be returned from the server.

=cut

sub works_from_doi {
    my ( $self, $doi, $select ) = @_;
    croak "works_from_doi: need doi" unless defined $doi;
    $self->_get_metadata( "/works", undef, "doi:$doi", $select );
}

=head2 C<$cr-E<gt>journal_from_doi( $doi )>

A shortcut for C<works_from_doi( $doi,  "container-title,page,issued,volume,issue")>

=cut

sub journal_from_doi {
    my ( $self, $doi ) = @_;
    croak "journal_from_doi: need doi" unless defined $doi;
    $self->_get_metadata( "/works", undef, "doi:$doi",
        "container-title,page,issued,volume,issue" );

}

=head2 C<$cr-E<gt>article_from_doi( $doi )>

A shortcut for C<works_from_doi( $doi,  "title,container-title,page,issued,volume,issue,author,published-print,published-online")>

=cut

sub article_from_doi {
    my ( $self, $doi ) = @_;
    croak "article_from_doi: need doi" unless defined $doi;
    $self->_get_metadata( "/works", undef, "doi:$doi",
        "title,container-title,page,issued,volume,issue,author,published-print,published-online"
    );
}

=head2 C<$cr-E<gt>article_from_funder( $funder_id, {name=E<gt>'smith'}, $select )>

Retrive the metadata from the works road for a given funder, searched with an author's name or orcid.
C<$select> default to  "title,container-title,page,issued,volume,issue,published-print,DOI". Use * to retrieve all fields.

=cut

sub articles_from_funder {
    my ( $self, $id, $href, $select ) = @_;

    croak "articles_from_funder: need funder id" unless defined $id;
    $select = (
          $select
        ? $select
        : "title,container-title,page,issued,volume,issue,published-print,DOI"
    );
    $self->{select} = $select eq "*" ? undef : $select;
    $self->{path} = "/funders/$id/works";
    $self->cursor("*");
    for my $k ( keys %$href ) {
        if ( $k eq "name" ) {
            my $query = [ "query.author=" . uri_escape( $href->{$k} ) ];
            $self->{param} = $query;

            return $self->_get_metadata( "/funders/$id/works", $query,
                undef, $self->{select} );
        }
        elsif ( $k eq "orcid" ) {
            my $url =
                  $href->{$k} =~ /^https*:\/\/orcid.org\//
                ? $href->{$k}
                : "http://orcid.org/" . $href->{$k};

            # $self->{param} = "orcid:" . uri_escape($url);
            $self->{filter} = "orcid:" . uri_escape($url);
            return $self->_get_metadata( "/funders/$id/works", undef,
                $self->{filter}, $self->{select} );
        }
        else { croak "articles_from_funder : unknown key : $k"; }
    }
    return $self->_get_metadata( "/funders/$id/works", undef, undef,
        $self->{select} );

}

=head2 C<$cr-E<gt>get_types()>

Retrieve all the metadata from the types road.

=cut

sub get_types {
    my $self = shift;
    $self->_get_metadata("/types");
}

=head2 C<$cr-E<gt>get_members()>

Retrieve all the metadata (> 10'000 items) from the members road.

=cut

sub get_members {
    my $self = shift;

    $self->page_start_at(1);
    $self->{path} = "/members";
    $self->_get_page_metadata("/members");

}

=head2 C<$cr-E<gt>member_from_id( $member_id )>

Retrieve a members from it's ID

=cut

sub member_from_id {
    my ( $self, $id ) = @_;
    croak "member_from_id: need id" unless ($id);
    my $rows = $self->rows();
    $self->rows(0);
    my $rs = $self->_get_page_metadata("/members/$id");
    $self->rows($rows);
    return $rs;

}

=head2 C<$cr-E<gt>get_journals()>

Retrieve all the metadata (> 60'000 items) from the journals road.

=cut

sub get_journals {
    my $self = shift;
    $self->{path} = "/journals";
    $self->page_start_at(1);
    $self->_get_page_metadata("/journals");

}

=head2 C<$cr-E<gt>get_licences()>

Retrieve all the metadata (> 700 items) from the licenses road.

=cut

sub get_licences {
    my $self = shift;
    $self->{path} = "/licences";
    $self->page_start_at(1);
    $self->_get_page_metadata("/licences");

}

=head2 C<$cr-E<gt>query_works( $fields_array_ref, $values_array_ref, $select_string )>

See L<Field Queries|https://github.com/CrossRef/rest-api-doc#field-queries> for the fields that can be searched.
You may omit the "query." part in the field name.
The corresponding values are passed in a second array, in the same order.
Beware that searching with first and family name is treated as an OR not and AND:
C<query_works([qw(name name)], [qw(Tom Smith)], $select)> will retrieve all the works where and author has Tom in the name field or all works where an author has Smith in the name field.
See C<works_from_doi> above for the fields that can be selected.
Use keys_to_keep or json_path to define an ordering in the ouptut. Use select to filter the fields to be returned from the server.
=cut

sub query_works {
    my ( $self, $field_ar, $value_ar, $select ) = @_;
    my $i;
    my @params;
    for my $field (@$field_ar) {
        croak "unknown field $field"
            unless ( $field
            =~ /(?:container-)*title$|author$|editor$|chair$|translator$|contributor$|bibliographic$|affiliation$/
            );
        $field = "query." . $field unless ( $field =~ /^query\./ );
        push @params, $field . "=" . uri_escape( $value_ar->[ $i++ ] );
    }
    $self->cursor("*");
    $self->{path}   = "/works";
    $self->{param}  = \@params;
    $self->{select} = $select;
    $self->_get_metadata( "/works", \@params, undef, $select );

}

=head2 C<$cr-E<gt>query_articles( $fields_array_ref, $values_array_ref )>

A shortcut for C<$cr-E<gt>query_works($fields_array_ref, $values_array_ref,  "title,container-title,page,issued,volume,issue,author,published-print,published-online")>

=cut

sub query_articles {
    my ( $self, $field_ar, $value_ar ) = @_;
    $self->query_works( $field_ar, $value_ar,
        "title,container-title,page,issued,volume,issue,author,published-print,published-online"
    );
}

=head2 C<$cr-E<gt>query_journals( $fields_array_ref, $values_array_ref )>

A shortcut for C<$cr-E<gt>query_works($fields_array_ref, $values_array_ref, "container-title,page,issued,volume,issue">

=cut

sub query_journals {
    my ( $self, $field_ar, $value_ar ) = @_;
    $self->query_works( $field_ar, $value_ar,
        "container-title,page,issued,volume,issue" );

}

=head2 C<$cr-E<gt>get_next()>

Return the next set of data in the /works, /members, /journals, /funders, /licences roads, 
Return undef after the last set.

=cut

sub get_next {
    my $self = shift;
    $self->log->debug( "get_next cursor: ",
        ( defined $self->cursor ? " defined " : " undef" ) );
    $self->log->debug( "get_next page_start_at: ", $self->page_start_at );

    if ( $self->cursor ) {
        $self->_get_metadata(
            $self->{path},   $self->{param},
            $self->{filter}, $self->{select}
        );
    }
    my $last_start = $self->page_start_at;

#as long as the count of items returned is equal to ->rows
#there should be a next page to ask for: increment page_start_at to page_start_at + row
    if ( $last_start && $self->{last_page_items_count} >= $self->rows ) {
        $self->page_start_at( $last_start + $self->rows );
        $self->_get_page_metadata( $self->{path}, $self->{param} );
    }

}

=head2 C<$cr-E<gt>agencies_from_dois( $dois_array_ref )>

Retrieve the Registration agency (CrossRef, mEdra ...) using an array ref of article doi.
L<See|https://www.doi.org/registration_agencies.html>

=cut

sub agencies_from_dois {
    my ( $self, $dois_ar ) = @_;
    my @results;

    # die Dumper $dois_ar;
    my $rows = $self->rows;
    $self->rows(0);
    for my $doi (@$dois_ar) {

        #print "looking for $doi\n";
        my $response =
            $self->_crossref_get_request( "/works/" . $doi . "/agency" );
        if ($response) {
            my $hr = $self->_decode_json( $response->responseContent );

            # my @items = $hr->{message}->{items};
            my $res = $self->_display_data($hr);
            return $res if ($self->spit_raw_data);
            push @results, $res;

        }

    }
    $self->rows($rows);

    return \@results;
}

=head2 C<$cr-E<gt>funders_from_location( $a_location_name )>

Retrieve the funder from a country. Problem is that there is no way of having a list of country name used.
These locations has been succefully tested: United Kingdom, Germany, Japan, Morocco, Switzerland, France.

=cut

sub funders_from_location {
    my ( $self, $loc ) = @_;
    croak "funders_from_location : need location" unless $loc;
    my $rows = $self->rows;

    #$self->rows(0);
    my $data;
    my @params;
    push @params, "location:" . uri_escape($loc);
    $self->page_start_at(1);
    $self->{path}   = "/funders";
    $self->{param}  = \@params;
    $self->{select} = undef;
    $self->_get_page_metadata( "/funders", \@params );

    #$self->rows($rows);
    #return $data;
}

sub _set_cursor {
    my ( $self, $msg_hr, $n_items ) = @_;
    my %msg = %$msg_hr;
    if ( exists $msg{'next-cursor'} && $n_items >= $self->rows ) {

        # print "_set_cursor:  ", uri_escape( $msg{'next-cursor'} ), "\n";
        $self->cursor( uri_escape( $msg{'next-cursor'} ) );
    }
    else {
        # print "_set_cursor: undef\n";
        $self->cursor(undef);
    }
}

sub _decode_json {
    my ( $self, $json ) = @_;
    my $data = $self->decoder->decode($json);
    return $data;

}

package REST::Client::CrossRef::Unfolder;

#use Data::Dumper;
use Carp;
use Log::Any;

sub new {
    my ($class) = shift;
    my $self = { logger => Log::Any->get_logger( category => "unfolder" ), };
    return bless $self, $class;

}

sub log {
    my $self = shift;
    return $self->{logger};
}

# This setting of the array ref could be removed since the ordering in display_data
# also remove the keys that are not wanted. But the hash builded is smaller
# with adding only the key that are needed.
sub set_keys_to_keep {
    my ( $self, $ar_ref ) = @_;
    $self->{keys_to_keep} = $ar_ref;

}

sub _unfold_hash {
    my ( $self, $raw_hr, $key_ar, $result_hr ) = @_;

    $self->log->debug( "unfold_hash1: ",
        ( $result_hr ? scalar %$result_hr : 0 ) );
    for my $k ( keys %$raw_hr ) {

        # $self->log->debug( "key: ", $k );

        push @$key_ar, $k;

        if ( ref $raw_hr->{$k} eq "HASH" ) {

            $result_hr =
                $self->_unfold_hash( $raw_hr->{$k}, $key_ar, $result_hr );

            $self->log->debug( "1 size ",
                $result_hr ? scalar %$result_hr : 0 );
        }
        elsif ( ref $raw_hr->{$k} eq "ARRAY" ) {
            $result_hr =
                $self->_unfold_array( $raw_hr->{$k}, $key_ar, $result_hr );

            $self->log->debug( "2 size ",
                $result_hr ? scalar %$result_hr : 0 );

            $result_hr->{ $key_ar->[$#$key_ar] } =~ s/,\s$//
                if ( defined $result_hr->{ $key_ar->[$#$key_ar] } );

        }

        else {

            $self->log->debug( "ref: ", ref $raw_hr->{$k} )
                if ( ref $raw_hr->{$k} );
            my $key = join( "/", @$key_ar );

            if (   defined $self->{keys_to_keep}
                && defined $self->{keys_to_keep}->{$key} )
            {
                $result_hr->{$key} = $raw_hr->{$k}

            }
            else {
                $self->log->debug( "key : ", $key, " value: ",
                    $raw_hr->{$k} );
                $result_hr->{$key} = $raw_hr->{$k};
            }

        }

        my $tmp = pop @$key_ar;

    }

    $self->log->debug( "_unfold_hash3: ",
        $result_hr ? scalar(%$result_hr) : 0 );
    return $result_hr;
}

sub _unfold_array {
    my ( $self, $ar, $key_ar, $res_hr ) = @_;

    $self->log->debug( "_unfold_array0: ", $res_hr ? scalar(%$res_hr) : 0 );
    my $last_key = join( "/", @{$key_ar} );
    my $key = $key_ar->[$#$key_ar];

    $self->log->debug( "_unfold array1 key: ", $key );
    if ( $key eq "author" ) {
        my @first;
        my @groups;
        my $first;
        my @all;
        for my $aut (@$ar) {
            if ( $aut->{sequence} eq 'first' ) {
                if ( $aut->{family} ) {
                    $first =
                          "\n"
                        . $aut->{family}
                        . (
                        defined $aut->{given} ? ", " . $aut->{given} : " " )
                        . $self->_unfold_affiliation( $aut->{affiliation} );
                    push @first, $first;
                }
                elsif ( $aut->{name} ) {
                    $first = "\n"
                        . $aut->{name}
                        . $self->_unfold_affiliation( $aut->{affiliation} );
                    push @groups, $first;

                }

            }
            else {
                if ( $aut->{family} ) {
                    push @all,
                          "\n"
                        . $aut->{family}
                        . (
                        defined $aut->{given} ? ", " . $aut->{given} : " " )
                        . $self->_unfold_affiliation( $aut->{affiliation} );
                }
                elsif ( $aut->{name} ) {
                    push @groups,
                          "\n"
                        . $aut->{name}
                        . $self->_unfold_affiliation( $aut->{affiliation} );

                }
            }

        }

        unshift @all, @first;
        unshift @all, @groups;
        $res_hr->{$key} = join( "", @all );

    }

    else {

        for my $val (@$ar) {

            if ( ref $val eq "HASH" ) {
                $res_hr = $self->_unfold_hash( $val, $key_ar, $res_hr );
                my $last = $#$key_ar;
                $res_hr->{ $key_ar->[$last] } =~ s/,\s$//
                    if ( defined $res_hr->{ $key_ar->[$last] } );

                $self->log->debug( "_unfold_array2: ",
                    $res_hr ? scalar(%$res_hr) : 0 );
            }
            elsif ( ref $val eq "ARRAY" ) {
                $res_hr = $self->_unfold_array( $val, $key_ar, $res_hr );

                $self->log->debug( "_unfold_array3: ",
                    $res_hr ? scalar(%$res_hr) : 0 );

            }
            else {

                if (   defined $self->{keys_to_keep}
                    && defined $self->{keys_to_keep}->{$last_key} )
                {
                    if ( defined $val ) {
                        $res_hr->{$last_key} .= $val . ", ";
                    }
                    else {
                        $res_hr->{$last_key} = "";
                    }

                }
                else {
                    $res_hr->{$last_key} .= $val;
                }

            }
        }    #for

    }

    $self->log->debug( "_unfold_array4: ", $res_hr ? scalar(%$res_hr) : 0 );
    return $res_hr;
}

sub _unfold_affiliation {
    my ( $self, $ar ) = @_;
    my $line = ";";
    my @aff;
    for my $hr (@$ar) {

        # my @k = keys %$hr;
        my @aff = values %$hr;
        $aff[0] =~ s/\r/ /g;
        $line .= " " . $aff[0];
    }

    return $line;
}

=head1 INSTALLATION

To install this module type the following:
	perl Makefile.PL
	make
	make test
	make install

On windows use nmake or dmake instead of make.

=head1 DEPENDENCIES

The following modules are required in order to use this one

     Moo => 2,
     JSON => 2.90,
     URI::Escape => 3.31,
     REST::Client => 273,
     Log::Any => 1.049,
     HTTP::Cache::Transparent => 1.4,
     Carp => 1.40,
     JSON::Path => 0.420

=head1 BUGS

See below.

=head1 SUPPORT

Any questions or problems can be posted to me (rappazf) on my gmail account.

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/rest-client-crossref/> 

=head1 AUTHOR

    F. Rappaz
    CPAN ID: RAPPAZF 

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Catmandu::Importer::CrossRef> Catmandu is a toolframe, *nix oriented.  

L<Bib::CrossRef> Import data from CrossRef using the CrossRef search, not the REST Api, and convert the XML result into something simpler.

=cut

1;

