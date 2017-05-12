#
#===============================================================================
#
#         FILE:  Parse.pm
#
#  DESCRIPTION:  SOAP::DirectI::Parse -- parsing SOAP DirectI's responses
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  17.03.2009 20:52:05 MSK
#     REVISION:  ---
#===============================================================================

package SOAP::DirectI::Parse;

use strict;
use warnings;

use Data::Dumper;
use Smart::Comments -ENV;

use Carp;

local $Data::Dumper::Purity = 1;
local $Data::Dumper::Indent = 1;

#my $slurp = do {
#    local $/;
#    <>;
#};

#$slurp =~ s/.*(<soapenv:Body)/$1/;
#$slurp =~ s/(<\/soapenv:Body>).*/$1/;

sub new {
    my $class = shift;
    $class = ref( $class ) || $class;

    my $self = {};
    bless $self, $class;

    return $self;
}

#bless my $obj = {}, __PACKAGE__;
#$obj->parse_xml_string( $slurp );

#warn Dumper $obj->{tree};

#warn Dumper [ $obj->parse_to_data_and_signature ];

sub parse_xml_string {
    my $self = shift;
    my $str = shift;

    my $parent_tag = shift;

    #my @tag = ($str =~ m/^<(\w*:)?(\w+)([^>]*)(?:\/>|>(.*?)<\/\1?\2>)$/mxogs);

    ### parse_xml_string: $str

#    my @tag = ( $str =~ m{\G<(\w*:)?(\w+)([^>]*)(?:/>|>(.*?)</\1?\2>)}gms );

    if ( ! $parent_tag && not $str =~ s{\A\s*<\?xml[^>]*\?>}{} ) {
	croak "Not an XML data\n";
    }

    #use re 'debug';

    while ( $str =~ s{\A\s* # start of string
	    <([\w\-]+:)? # start of tag and namespace (if any)
	    (\w+)	# name of tag
	    ([^>]*)	# attributes in string form
	    (?:
		/>
		|
		(?<!/)>	# end of tag either by /> or >
		(.*?)	# content of tag
		</\1?\2>	# namespace and tagname in closing tag
	    )
	    }{}gxs ) {
	my @tag_arr = my ($namespace, $name, $attr, $content) = ($1, $2, $3, $4);

	if ( ! defined $name ) {
	    croak "Unable to parse: $str";
	}


	my $tag = {};

	if ( $namespace ) {
	    $namespace =~ tr/://d;
	    $tag->{namespace}   = $namespace;
	}

	$tag->{name}	    = $name	    if $name	    ;

	### @tag_arr

	if ( $content ) {
	    $tag->{content} = $content;

	    if ( $content =~ m/[<>]/ ) {
		$self->parse_xml_string( $content, $tag );
	    }

	}

	$tag->{attrs} = $attr;

	while( $attr =~ s{^\s*((?:[a-zA-Z-_]+:)?[a-zA-Z-_]+)=[\'\"]([^'"]*)[\'\"]}{}mgosx ) {
	    $tag->{attr}{ $1 } = $2;
	}


	if ( ! $parent_tag ) {
	    $self->{tree} = $tag;
	    last;
	}

	push @{ $parent_tag->{siblings} }, $tag;
    }

    if ( ! $parent_tag && ! $self->{tree} ) {
	croak "Could not parse $str: $.";
    }
}

sub fetch_data_and_signature {
    my $self = shift;

    my $signature = {};

    ### $self->{tree}

    my $tree_root = $self->{tree};

    while( 
	    @{ $tree_root->{siblings} || [] } == 1 
	&&     $tree_root->{siblings}[0]{namespace} =~ /soap/i
    ) {

	$tree_root = $tree_root->{siblings}[0];
    }

    my ($data, $args_sig);

    my @tags = 
	grep { not $_->{name} =~ m/multiRef/ } @{ $tree_root->{siblings} };

    ### @tags
    ### $tree_root

    if ( @tags == 1 && $tags[0]->{name} =~ m/Response/i ) {
	my %multirefs = 
	    map	{ $_->{attr}{id} => $_ } 
	    grep    { $_->{name} =~ m/multiRef/ } 
		    @{ $tree_root->{siblings} };

	### %multirefs

	$self->{multirefs} = \%multirefs;

	#warn "multirefs: ", scalar keys %multirefs;

	my ($main_tag, $other) = @{ $tags[0]->{siblings} };
	if ( $other ) {
	    croak "Something bad happened";
	}
	
	#local $main_tag->{ name } = $tags[0]->{name};

	#warn $main_tag->{name};
	$signature->{name} = $tags[0]->{name};

	@tags = ({ %$main_tag, name => $tags[0]->{name} });
    }
    elsif( @tags == 1 ) {
	$tree_root = $tags[0];
	@tags = @{ $tags[0]->{siblings} };
    }

    foreach my $sibling ( @tags ) {
	my @ret = $self->_parse_tag( $sibling );

	my $tname = $ret[1]->{key};
	$tname = join '_', map { lc } split /(?=[A-Z])/, $tname;

	$data->{ $tname } =	$ret[0];
	push @$args_sig,	$ret[1];
    }

    if ( @tags != 1 && $tree_root->{namespace} ) {
	my $ns = $self->{tree}{attr}{ 'xmlns:'.$tree_root->{namespace} };
	$signature->{namespace} = $ns if $ns;
    }

    $signature->{name} ||= $tree_root->{name};
    $signature->{args} = $args_sig;

    if ( @tags == 1 ) {
	return (values %$data, $signature);
    }

    return ($data, $signature);
}

sub _get_type {
    my $self = shift;
    my $tag  = shift;

    if ( $tag->{name} =~ m/^fault/ || $tag->{name} eq 'detail' ) {
	$tag->{attr}{'xsi:type'} = 'xsd:string';
	return 'string';
    }

    return $tag->{attr}{'xsi:type'};
}

sub _parse_tag {
    my $self = shift;
    my $tag  = shift;

    $tag or croak "No tag given";

    if ( my $href = $tag->{attr}{href} ) {
	$href =~ s/^#//;
	if ( ! wantarray ) {
	    return $self->_parse_tag( $self->{multirefs}{ $href } );
	}
	else {
	    my @ret = $self->_parse_tag( $self->{multirefs}{ $href } );

	    $ret[1]->{key} = $tag->{name};

	    return @ret;
	}
    }

    my $type = $self->_get_type( $tag )
	or croak "Unknown type for tag $tag->{name}";

    $type =~ s/.*?://;

    $type = lc $type;
    if ( my $s = $self->can('_parse_'.$type) ) {
	return $s->( $self, $tag );
    }

    croak "Cannot parse $type";
}

sub unescape_xml {
    $_ = shift;

    return $_ unless $_;

    s/&amp;/&/xgs;
    s/&lt;/</xgs;
    s/&gt;/>/xgs;
    s/&quot;/\"/xgs;

    return $_;
}

sub _parse_string {
    my ($self, $tag) = @_;

    my $c = unescape_xml( $tag->{content} );

    return $c if not wantarray;

    my @ret = ($c);

    my $t = $tag->{attr}{'xsi:type'};
    $t =~ s/^.*://;

    push @ret, {
	key	=> $tag->{name},
	type	=> $t,
    };

    return @ret;
}

sub _parse_boolean {
    my ($self, $tag) = @_;

    my ($val, $sig);

    if ( wantarray ) {
	($val, $sig) = $self->_parse_string( $tag );
    }
    else {
	$val = $self->_parse_string( $tag );
    }

    if ( lc $val eq 'true' ) {
	$val = 1;
    }
    elsif( $val eq 'false' ) {
	$val = 0;
    }

    return wantarray ? ($val, $sig) : $val;
}


sub _parse_int {
    my ($self, $tag) = @_;

    return int( $self->_parse_string( $tag ) ) if not wantarray;

    my @ret = $self->_parse_string( $tag );
    $ret[0] = int( $ret[0] );

    return @ret;
}

sub _parse_vector_or_array {
    my $self = shift;
    my $tag  = shift;

    my $array = [];
    my $items = $tag->{siblings};

    my $elem_sig;

    foreach my $item (@$items) {
	if ( $item->{name} ne 'item' ) {
	    croak "Vector or Array item has no name 'item'";
	}

	my $value;
	
	if ( $elem_sig ) {
	    $value = $self->_parse_tag($item);
	}
	else {
	    ($value, $elem_sig) = $self->_parse_tag($item);
	}

	push @$array, $value;
    }

    return $array if not wantarray;

    my $type = $tag->{attr}{'xsi:type'};

    $type =~ m/(array|vector)/i;

    my $signature = {
	key	    => $tag->{name},
	type	    => lc $1,
	elem_sig    => $elem_sig,
    };

    return ($array, $signature);
}

sub _parse_vector {
    shift->_parse_vector_or_array( @_ );
}

sub _parse_array {
    shift->_parse_vector_or_array( @_ );
}

sub _parse_map {
    my $self = shift;
    my $tag  = shift;

    my $hash = {};

    my $items = $tag->{siblings};

    my ($key_sig, $value_sig);

    foreach my $item (@$items) {
	if ( $item->{name} ne 'item' ) {
	    croak "Map item has no name 'item'";
	}

	my ($key, $value);

	if ( $key_sig ) {
	    $key    = $self->_parse_tag($item->{siblings}[0]);
	    $value  = $self->_parse_tag($item->{siblings}[1]);
	}
	else {
	    ($key,   $key_sig)    = $self->_parse_tag($item->{siblings}[0]);
	    ($value, $value_sig)  = $self->_parse_tag($item->{siblings}[1]);

	    #$key_type   = ref $key   ? $key_sig   : $key_sig->{type}
	    #or croak "No key type given for $tag->{name}";
	    #$value_type = ref $value ? $value_sig : $value_sig->{type}
	    #or croak "No value type given for $tag->{name}";
	}


	$hash->{ $key } = $value;
    }

#    warn Dumper $items;

    return $hash if not wantarray;

    my $signature = {};

    $signature->{key}	    = $tag->{name};
    $signature->{type}	    = 'map';

    $signature->{key_sig}	= $key_sig	;
    $signature->{value_sig}	= $value_sig	;


    return ($hash, $signature);
}

1;
