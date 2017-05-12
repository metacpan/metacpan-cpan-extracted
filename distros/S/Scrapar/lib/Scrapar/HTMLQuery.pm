# this part is directly taken from HTML::Query, and some more
# selectors are added.

package Scrapar::HTMLQuery;

use Badger::Class
    version   => 0.02,
    debug     => 0,
    base      => 'Badger::Base',
    utils     => 'blessed',
    import    => 'class CLASS',
    vars      => 'AUTOLOAD',
    constants => 'ARRAY',
    constant  => {
        ELEMENT => 'HTML::Element',
        BUILDER => 'HTML::TreeBuilder',
    },
    exports   => {
        any   => 'Query',
        hooks => {
            query => \&_export_query_to_element,
        },
    },
    messages  => {
        no_elements => 'No elements specified to query',
        no_query    => 'No query specified',
        no_source   => 'No argument specified for source: %s',
        bad_element => 'Invalid element specified: %s',
        bad_source  => 'Invalid source specified: %s',
        bad_query   => 'Invalid query specified: %s',
        bad_spec    => 'Invalid specification "%s" in query: %s',
        is_empty    => 'The query does not contain any elements',
    };


our $SOURCES = {
    text => sub {
        class(BUILDER)->load;
        BUILDER->new_from_content(shift);
    },
    file => sub {
        class(BUILDER)->load;
        BUILDER->new_from_file(shift);
    },
    tree => sub {
        $_[0]
    },
    query => sub {
        ref $_[0] eq ARRAY
            ? @{ $_[0] }
            :    $_[0];
    },
};


sub _export_query_to_element {
    class(ELEMENT)->load->method(
        # this Just Works[tm] because first arg is HTML::Element object
        query => \&Query,
    );
}


sub Query (@) {
    CLASS->new(@_);
}


sub new {
    my $class = shift;
    my ($element, @elements, $type, $code, $select);

    # expand a single list ref into items
    unshift @_, @{ shift @_ } 
        if @_ == 1 && ref $_[0] eq ARRAY;

    $class = ref $class || $class;
    
    # each element should be an HTML::Element object, although we might
    # want to subclass this module to recognise a different kind of object,
    # so we get the element class from the ELEMENT constant method which a 
    # subclass can re-define.
    my $element_class = $class->ELEMENT;
    
    while (@_) {
        $element = shift;
        $class->debug("argument: $element") if DEBUG;
        
        if (! ref $element) {
            # a non-reference item is a source type (text, file, tree)
            # followed by the source, or if it's the last argument following
            # one ore more element options or named argument pairs then it's
            # a selection query
            if (@_) {
                $type = $element;
                $code = $SOURCES->{ $type }
                    || return $class->error_msg( bad_source => $type );
                $element = shift;
                $class->debug("source $type: $element") if DEBUG;
                unshift(@_, $code->($element));
                next;
            }
            elsif (@elements) {
                $select = $element;
                last;
            }
        }
        elsif (blessed $element) {
            # otherwise it should be an HTML::Element object or another
            # HTML::Query object
            if ($element->isa($element_class)) {
                push(@elements, $element);
                next;
            }
            elsif ($element->isa($class)) {
                push(@elements, @$element);
                next;
            }
        }

        return $class->error_msg( bad_element => $element );
    }
        
    my $self = bless \@elements, $class;
    
    return defined $select
        ? $self->query($select)
        : $self;
}

sub _apply_filters {
    my $filters_ref = shift;
    my @elements = @_;

    while (my $filter = shift @{$filters_ref}) {
	for (my $i = 0; $i < @elements; $i++) {
	    for ($filter->[0]) {
		undef $elements[$i]
		    if
		    (m[first] && $i != 0)
		    ||
		    (m[last] && $i != $#elements) 
		    ||
		    (m[eq] && $i != $filter->[1])
		    ||
		    (m[lt] && $i >= $filter->[1])
		    ||
		    (m[gt] && $i <= $filter->[1])
		    ||
		    (m[even] && $i % 2)
		    ||
		    (m[odd] && $i % 2 == 0)
		    ||
		    (m[empty] && $elements[$i]->content_list)
		    ||
		    (m[parent] && !$elements[$i]->content_list)
		    ;
		if (m[left]) {
		    $elements[$i] = $elements[$i]->left;
		}
		elsif (m[right]) {
		    $elements[$i] = $elements[$i]->right;
		}
		elsif (m[upper]) {
		    $elements[$i] = $elements[$i]->parent;
		}
		elsif (m[contains|lacks] && $filter->[1]) {
		    my $regexp = quotemeta $filter->[1];
		    my $text = $elements[$i]->as_text;
		    if ($_ eq q[contains]) {
			undef $elements[$i] if $text !~ m[$regexp];
		    }
		    else {
			undef $elements[$i] if $text =~ m[$regexp];
		    }
		}
		elsif (m[grep] && ref $filter->[1] eq 'CODE') {
 		    undef $elements[$i] if !$filter->[1]->($elements[$i]);
		}
	    }
	}
	@elements = grep { defined } @elements;
    }
    return @elements;
}

sub query {
    my ($self, $query) = @_;
    my @result;
    my $ops = 0;
    my $pos = 0;
    
    return $self->error_msg('no_query')
        unless defined $query
            && length  $query;

    # replace some selectors
    $query =~ s[:header][h1, h2, h3, h4, h5, h6];
    $query =~ s[:input][input];
    $query =~ s/:(text|password|radio|checkbox|submit|image|reset|button|file|hidden)/[type=$1]/;
    $query =~ s/:(checked|selected)/[$1]/;

    # multiple specs can be comma separated, e.g. "table tr td, li a, div.foo"
    COMMA: while (1) {
        # each comma-separated traversal spec is applied downward from 
        # the source elements in the @$self query
        my @elements = @$self;
        my $comops   = 0;
        
        # for each whitespace delimited descendant spec we grok the correct
        # parameters for look_down() and apply them to each source element
        # e.g. "table tr td"
        SEQUENCE: while (1) {
            my @args;
	    my @filters;
            $pos = pos($query) || 0;
        
            # ignore any leading whitespace
            $query =~ / \G \s+ /cgsx;

            # optional leading word is a tag name
            if ($query =~ / \G (\w+) /cgx) {
                push( @args, _tag => $1 );
            }
        
            # that can be followed by (or the query can start with) a #id
            if ($query =~ / \G \# ([\w\-]+) /cgx) {
                push( @args, id => $1 );
            }
        
            # and/or a .class 
            if ($query =~ / \G \. ([\w\-]+) /cgx) {
                push( @args, class => qr/ (^|\s+) $1 ($|\s+) /x );
            }
        
            # and/or none or more [ ] attribute specs
            while ($query =~ / \G \[ (.*?) \] /cgx) {
		my $criteria = $1;
		$criteria =~ /^(.+?)\s*([!\^\$\*]?=)\s*(.+?)$/;
                my ($name, $op, $value) = ($1, $2, $3);

                if (defined $value) {
                    for ($value) {
                        s/^['"]//;
                        s/['"]$//;
                    }
		    if ($op eq '=') {
		      push( @args, $name => $value);
		    }
		    elsif ($op eq '!=') {
		      push( @args, sub { $_[0]->attr($name) ne $value } );
		    }
		    elsif ($op eq '^=') {
		      push( @args, sub { $_[0]->attr($name) =~ m[^$value] } );
		    }
		    elsif ($op eq '$=') {
		      push( @args, sub { $_[0]->attr($name) =~ m[$value$] } );
		    }
		    elsif ($op eq '*=') {
		      push( @args, sub { $_[0]->attr($name) =~ m[$value] } );
		    }
                }
                else {
                    # add a regex to match anything (or nothing)
                    push( @args, $name => qr/.*/ );
                }
            }

	    if ($query =~ / \G : (first | last | even | odd | empty | parent) /cgx) {
                push( @filters, [ $1 ] );
            }
        
	    if ($query =~ / \G : (eq | gt | lt 
			    | contains | lacks ) \((.+)\) /cgx) {
                push( @filters, [ $1 => $2 ] );
            }

	    use Regexp::Common qw /balanced/;

	    if ($query =~ / \G : (grep) \s* ($RE{balanced}{-parens=>'{}'}) /cgx) {
                push( @filters, [ $1 => eval "sub $2" ] );
		die $@ if $@;
            }

	    while ($query =~ / \G : (left | right | upper) /cgx) {
                push( @filters, [ $1 ] );
            }
        
            # we must have something in @args by now or we didn't find any
            # valid query specification this time around
            last SEQUENCE unless @args;
    
            $self->debug(
                'Parsed ', substr($query, $pos, pos($query) - $pos),
                ' into args [', join(', ', @args), ']'
            ) if DEBUG;

            # call look_down() against each element to get the new elements
            @elements = _apply_filters \@filters, map { $_->look_down(@args) } @elements;
            
            # so we can check we've done something
            $comops++;
        }

        if ($comops) {
            $self->debug(
                'Added', scalar(@elements), ' elements to results'
            ) if DEBUG;

            push(@result, @elements);
            
            # update op counter for complete query to include ops performed
            # in this fragment
            $ops += $comops;
        }
        else {
            # looks like we got an empty comma section, e.g. : ",x, ,y,"
            # so we'll ignore it
        }

        last COMMA 
            unless $query =~ / \G \s*,\s* /cgsx;
    }
    
    # check for any trailing text in the query that we couldn't parse
    return $self->error_msg( bad_spec => $1, $query )
        if $query =~ / \G (.+?) \s* $ /cgsx;

    # check that we performed at least one query operation 
    return $self->error_msg( bad_query => $query )
        unless $ops;
 
    return wantarray 
        ? @result
        : $self->new(@result);
}


sub list {
    return wantarray
        ?   @{ $_[0] }      # return list of items
        : [ @{ $_[0] } ];   # return unblessed list ref of items
}


sub size {
    return scalar @{ $_[0] };
}


sub first {
    my $self = shift;
    return @$self
        ? $self->[0]
        : $self->error_msg('is_empty');
}


sub last {
    my $self = shift;
    return @$self
        ? $self->[-1]
        : $self->error_msg('is_empty');
}


sub AUTOLOAD {
    my $self     = shift;
    my ($method) = ($AUTOLOAD =~ /([^:]+)$/ );
    return if $method eq 'DESTROY';

    # we allow Perl to catch any unknown methods that the user might
    # try to call against the HTML::Element objects in the query
    my @results = 
        map  { $_->$method(@_) }
        @$self;
    
    return wantarray
        ?  @results
        : \@results;
}

package HTML::Element;

use strict;
use warnings;
use Scrapar::Util;

sub html_query {
    my $self = shift;
    my $query = shift || return;

    return Scrapar::Util::html_query($self->as_HTML, $query);
}

1;

