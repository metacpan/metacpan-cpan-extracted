######################################################################
package Net::Amazon::Request;
######################################################################

use Log::Log4perl qw(:easy get_logger);
use Net::Amazon::Validate::Type;
use Net::Amazon::Validate::ItemSearch;

use Data::Dumper;

use warnings;
use strict;
use constant DEFAULT_MODE          => 'books';
use constant DEFAULT_TYPE          => 'Large';
use constant DEFAULT_PAGE_COUNT    => 1;
use constant DEFAULT_FORMAT        => 'xml';
use constant PAGE_NOT_VALID        => qw(TextStream);

# Attempt to provide backward compatability for AWS3 types.
use constant AWS3_VALID_TYPES_MAP => {
	'heavy' => 'Large',
	'lite'  => 'Medium',
};

# Each key represents the REST operation used to execute the action.
use constant SEARCH_TYPE_OPERATION_MAP => {
    Actor        => 'ItemSearch',
    Artist       => 'ItemSearch',
    All          => 'ItemSearch',
    Author       => 'ItemSearch',
    ASIN         => 'ItemLookup',
    Blended      => 'ItemSearch',
    BrowseNode   => 'ItemSearch',
    Director     => 'ItemSearch',
    EAN          => 'ItemLookup',
    Exchange     => 'SellerListingLookup',
    ISBN         => 'ItemLookup',
    Keyword      => 'ItemSearch',
    Keywords     => 'ItemSearch',
    Manufacturer => 'ItemSearch',
    MP3Downloads => 'ItemSearch',
    MusicLabel   => 'ItemSearch',
    Power        => 'ItemSearch',
    Publisher    => 'ItemSearch',
    Seller       => 'SellerListingSearch',
    Similar      => 'SimilarityLookup',
    TextStream   => 'ItemSearch',
    Title        => 'ItemSearch',
    UPC          => 'ItemLookup',
};

# if it isn't defined it defaults to salesrank
use constant DEFAULT_SORT_CRITERIA_MAP => {
    All          => '',
    Blended      => '',
    Seller       => '',
    Exchange     => '',
};

# if it isn't defined it defaults to ItemPage
use constant DEFAULT_ITEM_PAGE_MAP => {
    Seller   => 'ListingPage',
};

our $AMZN_XML_URL  = 'http://webservices.amazon.com/onca/xml?Service=AWSECommerceService';

##################################################
sub amzn_xml_url {
##################################################
    return $AMZN_XML_URL;
}

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my ($operation) = $class =~ m/([^:]+)$/;

    my $self = {
        Operation  => SEARCH_TYPE_OPERATION_MAP->{$operation},
        %options,
    };

    $self->{page} = DEFAULT_PAGE_COUNT unless exists $self->{page};

    # TextStream doesn't allow a page (ItemPage) parameter
    delete $self->{page} if grep{$operation eq $_} (PAGE_NOT_VALID);

    # salesrank isn't a valid sort criteria for all operations
    if (! exists $self->{sort}) {
        my $sort = (defined DEFAULT_SORT_CRITERIA_MAP->{$operation}) 
            ? DEFAULT_SORT_CRITERIA_MAP->{$operation} : 'salesrank';
        $self->{sort} = $sort if length($sort);
    }

    my $valid = Net::Amazon::Validate::Type::factory(operation => $self->{Operation});

    # There is no initial default type (ResponseGroup) defined, 
    # if there is, then attempt to map the AWS3 type to the
    # AWS4 type.
    if ($self->{type}) {
        if ( ref $self->{type} eq 'ARRAY' ) {
            my @types;
            for (@{$self->{type}}) {
                push @types, _get_valid_response_group($_, $valid);
            }
            $self->{type} = join(',', @types);
        } else {
            $self->{type} = _get_valid_response_group($self->{type}, $valid);
        }
    } 
    # If no type was defined then try to default to Large, which is a good
    # all around response group.  If Large is not a valid response group
    # let Amazon pick.
    else {
        eval { $valid->ResponseGroup(DEFAULT_TYPE) };
        $self->{type} = DEFAULT_TYPE unless $@;
    }

    my $item_page = (defined DEFAULT_ITEM_PAGE_MAP->{$operation}) 
        ? DEFAULT_ITEM_PAGE_MAP->{$operation} : 'ItemPage';
    
    __PACKAGE__->_convert_option($self, 'page', $item_page);
    __PACKAGE__->_convert_option($self, 'sort', 'Sort');
    __PACKAGE__->_convert_option($self, 'type', 'ResponseGroup') if defined $self->{type};

    # Convert all of the normal user input into Amazon's expected input.  Do it
    # here to allow a user to narrow down there based on any field that is valid
    # for a search operation.
    #
    # One could add all of the different qualifiers for an ItemSearch for free.
    if (SEARCH_TYPE_OPERATION_MAP->{$operation} eq 'ItemSearch' ) {
        for (keys %{(SEARCH_TYPE_OPERATION_MAP)}) {
            __PACKAGE__->_convert_option($self, lc($_), $_) if defined $self->{lc($_)};
        }
    }

    bless $self, $class;
}

##################################################
sub page {
##################################################
    my($self) = @_;
    return $self->{$self->_page_type};
}

##################################################
sub params {
##################################################
    my ($self, %options) = @_;

    my $class = ref $self;
    my ($operation) = $class =~ m/([^:]+)$/;

    unless (grep{$operation eq $_} (PAGE_NOT_VALID)) {
        my $type = $self->_page_type;
        $self->{$type} = $options{page};
    }

    return(%$self);
}

##################################################
# Figure out the Response class to a given Request
# class. To be used by sub classes.
##################################################
sub response_class {
##################################################
    my($self) = @_;

    my $response_class = ref($self);
    $response_class =~ s/Request/Response/;
    return $response_class;
}

##
## 'PRIVATE' METHODS
##

# A subroutine (not a class method), to map a response group
# to from AWS3 to AWS4, or validate that a response group
# is valid for AWS4.
sub _get_valid_response_group {
    my ($response_group, $valid) = @_;

    if (defined AWS3_VALID_TYPES_MAP->{$response_group}) {
        return AWS3_VALID_TYPES_MAP->{$response_group};
    } elsif ($valid->ResponseGroup($response_group)) {
        return $response_group;
    }

    # never reached, valid-> will die if the response group
    # is not valid for AWS4.
    return undef;
}

# CLASS->_convert_option( OPTIONS, ORIGINAL, TARGET [, CALLBACK] )
#
# Takes a reference to a hash of OPTIONS and renames the
# ORIGINAL key name to the TARGET key name. If the optional
# CALLBACK subroutine reference is defined, that subroutine
# is invoked with two arguments:
#
#     CALLBACK->( OPTIONS, TARGET )
#
# The result of the CALLBACK's execution is then returned to
# the caller. No assumptions are made about what the CALLBACK
# should return (or even *if* is should return)--that's the
# caller's responsibility.
#
# Returns 1 in the absensence of a CALLBACK.
#
sub _convert_option {
    my ($class, $options, $original, $target, $callback) = @_;

    if ( exists $options->{$original} ) {
        $options->{$target} = $options->{$original};
        delete $options->{$original};
    }

    return 1 unless ( $callback );
    
    # The key name is explicitly passed-in so that the caller doesn't
    # have think "Hrmm..  now which key am I working on, the original
    # or the target key?" Confusion is bad.
    return $callback->($options, $target);
}

# CLASS->_assert_options_defined( OPTIONS, KEYS )
#
# Takes a reference to a hash of OPTIONS and a list of
# one or more KEYS. Tests to see if each key in KEYS
# has a defined value. Calls die() upon the first
# missing key. Otherwise, returns undef.
#
sub _assert_options_defined {
    my ($class, $options, @keys) = @_;
    
    foreach my $key ( @keys ) {
        die "Mandatory parameter '$key' not defined"
            unless ( defined $options->{$key} );
    }
}

# CLASS->_option_or_default( OPTIONS, DEFAULT, USER )
#
# Takes a list of options, a default option, and a 
# possibly supplied user option.  If the user option
# is defined, it is verified that the option is valid.
# If no user option is supplied, the default option is
# used.
sub _option_or_default {
    my ($self, $options, $default, $user) = @_;
#     if(defined $user) {
#         unless(grep {$user eq $_} @$options) {
#            die "User supplied value, $user, is not a valid option" 
#         }
#         return $user;
#     }
    return $default;
}

# CLASS->_itemsearch_factory()
#
# Create an instance of an ItemSearch validator based on the
# Request class.  This class is used to validate user input
# against valid options for a given mode, and the type of 
# Request.
sub _itemsearch_factory {
    my($self) = @_;

    my $request_class = ref($self);
    my $request_type = (split(/::/, $request_class))[-1];

    # XXX: I'm not sure what to do here.  The ItemSearch validate class
    # is called Keywords, but the Request/Response class is called
    # Keyword.  For now I'm going to special case Keywords to map
    # to Keyword.
    $request_type = 'Keywords' if $request_type eq 'Keyword'; 

    return Net::Amazon::Validate::ItemSearch::factory(search_index => $request_type); 
}

sub _convert_itemsearch {
    my($self) = @_;

    my $is = $self->_itemsearch_factory();
    $self->{mode} = $is->user_or_default($self->{mode});

    __PACKAGE__->_convert_option($self, 'mode', 'SearchIndex');
}

sub _page_type {
    my ($self, %options) = @_;

    my $class = ref $self;
    my ($operation) = $class =~ m/([^:]+)$/;

    my $type = (defined DEFAULT_ITEM_PAGE_MAP->{$operation}) 
            ? DEFAULT_ITEM_PAGE_MAP->{$operation} : 'ItemPage';

    return $type;
}


1;

__END__

=head1 NAME

Net::Amazon::Request - Baseclass for requests to Amazon's web service

=head1 SYNOPSIS

    my $req = Net::Amazon::Request::XXX->new(
                     [ type  => 'Large', ]
                     [ page  => $start_page, ]
                     [ mode  => $mode, ]
                     [ offer => 'All', ]
                     [ sort => $sort_type, ]
    );

=head1 DESCRIPTION

Don't use this class directly, use derived classes (like
C<Net::Amazon::Request::ASIN>, etc.) instead to specify the type of request and
its parameters.

However, there's a bunch of parameters to the constructor
that all request types have in common, here they are:

=over 4

=item type

Defaults to C<Large>, but can also be set to C<Medium>, or C<Small>.

=over 8

=item Large

The C<Large> type provides everything in C<Medium> as well as music track
information, customer reviews, similar products, offers, and accessory data,
i.e. the kitchen sink.

=item Medium

The C<Medium> type provides everything in C<Small> as well as sales rank,
editorial reviews, and image URLs.

=item Small

The C<Small> type provies ASIN, product title, creator (author, artist, etc.),
product group, URL, and manufacturer.

=back

=item mode

Defaults to C<books>, but can be set to other catalog values.

=item page

Defaults to C<1>, but can be set to a different number to 
start with a different result page. Used in conjunction with the
C<max_pages> parameter of the C<Net::Amazon> object. C<page> is the
offset, C<max_pages> is the maximum number of pages pulled in starting
at C<page>.

=item sort

Defaults to C<salesrank>, but search results can be sorted in various
ways, depending on the type of product returned by the search.  Search
results may be sorted by the following criteria:

=over 8

=item *
Featured Items                                                           

=item *
Bestselling                                                              

=item *
Alphabetical (A-Z and Z-A)                                               

=item *
Price (High to Low and Low to High)                                      

=item *
Publication or Release Date                                              

=item *
Manufacturer                                                             

=item *
Average Customer Review                                                  

=item *
Artist Name                                   

=back

Consult L<Net::Amazon::Request::Sort> for details.

=item offer

To receive values for the fields
C<CollectibleCount>, C<NumberOfOfferings>, C<UsedCount>, 
specify C<offer =E<gt> "All">.

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
