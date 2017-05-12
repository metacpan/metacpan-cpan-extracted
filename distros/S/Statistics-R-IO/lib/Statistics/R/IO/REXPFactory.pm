package Statistics::R::IO::REXPFactory;
# ABSTRACT: Functions for parsing R data files
$Statistics::R::IO::REXPFactory::VERSION = '1.0001';
use 5.010;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';

our @EXPORT = qw( );
our @EXPORT_OK = qw( unserialize );

our %EXPORT_TAGS = ( all => [ @EXPORT_OK ], );

use Statistics::R::IO::Parser qw( :all );
use Statistics::R::IO::ParserState;
use Statistics::R::REXP::Character;
use Statistics::R::REXP::Double;
use Statistics::R::REXP::Integer;
use Statistics::R::REXP::List;
use Statistics::R::REXP::Logical;
use Statistics::R::REXP::Raw;
use Statistics::R::REXP::Language;
use Statistics::R::REXP::Symbol;
use Statistics::R::REXP::Null;
use Statistics::R::REXP::Closure;
use Statistics::R::REXP::GlobalEnvironment;
use Statistics::R::REXP::EmptyEnvironment;
use Statistics::R::REXP::BaseEnvironment;

use Carp;

sub header {
    seq(choose(xdr(),
               bin()),
        uint32(2),         # serialization format v2
        \&any_uint32,      # creator's R version
        uint32(0x020300)   # min R version to read (2.3.0 as of 3.0.2)
    )
}


sub xdr {
    bind(string("X\n"),         # XDR header
         sub {
             endianness('>');
             mreturn shift;
         })
}


sub bin {
    bind(string("B\n"),         # "binary" header
         sub {
             endianness('<');
             mreturn shift;
         })
}


sub object_content {
    bind(&unpack_object_info,
         \&object_data)
}


sub unpack_object_info {
    bind(\&any_uint32,
         sub {
             my $object_info = shift or return;
             mreturn { is_object => $object_info & 1<<8,
                       has_attributes => $object_info & 1<<9,
                       has_tag => $object_info & 1<<10,
                       object_type => $object_info & 0xFF,
                       levels => $object_info >> 12,
                       flags => $object_info,
                     };
         })
}


sub object_data {
    my $object_info = shift;
    
    if ($object_info->{object_type} == 10) {
        # logical vector
        lglsxp($object_info)
    } elsif ($object_info->{object_type} == 13) {
        # integer vector
        intsxp($object_info)
    } elsif ($object_info->{object_type} == 14) {
        # numeric vector
        realsxp($object_info)
    } elsif ($object_info->{object_type} == 15) {
        # complex vector
        cplxsxp($object_info)
    } elsif ($object_info->{object_type} == 16) {
        # character vector
        strsxp($object_info)
    } elsif ($object_info->{object_type} == 24) {
        # raw vector
        rawsxp($object_info)
    } elsif ($object_info->{object_type} == 19) {
        # list (generic vector)
        vecsxp($object_info)
    } elsif ($object_info->{object_type} == 20) {
        # expression vector
        expsxp($object_info)
    } elsif ($object_info->{object_type} == 9) {
        # internal character string
        charsxp($object_info)
    } elsif ($object_info->{object_type} == 2) {
        # pairlist
        listsxp($object_info)
    } elsif ($object_info->{object_type} == 6) {
        # language object
        langsxp($object_info)
    } elsif ($object_info->{object_type} == 1) {
        # symbol
        symsxp($object_info)
    } elsif ($object_info->{object_type} == 4) {
        # environment
        envsxp($object_info)
    } elsif ($object_info->{object_type} == 3) {
        # closure
        closxp($object_info)
    } elsif ($object_info->{object_type} == 25) {
        # closure
        s4sxp($object_info)
    } elsif ($object_info->{object_type} == 0xfb) {
        # encoded R_MissingArg, i.e., empty symbol
        mreturn(Statistics::R::REXP::Symbol->new)
    } elsif ($object_info->{object_type} == 0xf1) {
        # encoded R_BaseEnv
        mreturn(Statistics::R::REXP::BaseEnvironment->new)
    } elsif ($object_info->{object_type} == 0xf2) {
        # encoded R_EmptyEnv
        mreturn(Statistics::R::REXP::EmptyEnvironment->new)
    } elsif ($object_info->{object_type} == 0xfd) {
        # encoded R_GlobalEnv
        mreturn(Statistics::R::REXP::GlobalEnvironment->new)
    } elsif ($object_info->{object_type} == 0xfe) {
        # encoded Nil
        mreturn(Statistics::R::REXP::Null->new)
    } elsif ($object_info->{object_type} == 0xff) {
        # encoded reference to a stored singleton
        refsxp($object_info)
    } else {
        error "unimplemented SEXPTYPE: " . $object_info->{object_type}
    }
}


sub listsxp {
    my $object_info = shift;
    my $sub_items = 1;          # CAR, CDR will be read separately
    if ($object_info->{has_attributes}) {
        $sub_items++;
    }
    if ($object_info->{has_tag}) {
        $sub_items++;
    }
    
    bind(seq(bind(count($sub_items, object_content),
                  sub {
                      my @args = @{shift or return};
                      my %value = (value => $args[-1]);
                      $value{tag} = $args[-2] if $object_info->{has_tag};
                      $value{attributes} = $args[0] if $object_info->{has_attributes};
                      mreturn { %value };
                  }),
             object_content),   # CDR
         sub {
             my ($car, $cdr) = @{shift or return};
             my @elements = ($car);
             if (ref $cdr eq ref []) {
                 push( @elements, @{$cdr})
             }
             elsif (!$cdr->is_null) {
                 push( @elements, $cdr)
             }
             mreturn [ @elements ]
         })
}


## Language expressions are pairlists, but with a certain structure:
## - the first element is the reference (name or another language
##   expression) to the function call
## - the rest of the list are the arguments of the call, with optional
##   tags to name them
sub langsxp {
    ## After the pairlist has been parsed by `listsxp`, we want to
    ## separate the tags from the elements before invoking the Language
    ## constructor, with the tags becoming the names attribute
    bind(listsxp(@_),
         sub {
             my $list = shift or return;
             my @elements;
             my @names;
             my %attributes;
             foreach my $element (@$list) {
                 my $tag = $element->{tag};
                 my $value = $element->{value};
                 push @elements, $value;
                 push @names, $tag ? $tag->name : '';

                 if (exists $element->{attributes}) {
                     my %attribute_hash = tagged_pairlist_to_attribute_hash($element->{attributes});
                     while(my ($key, $value) = each %attribute_hash) {
                         die "Duplicate attribute $key" if
                             exists $attributes{$key};
                         $attributes{$key} = $value;
                     }
                 }
             }
             my %args = (elements => [ @elements ]);
             ## if no element is tagged, then don't construct the
             ## 'names' attribute
             if (grep {exists $_->{tag}} @$list) {
                 $attributes{names} = Statistics::R::REXP::Character->new([ @names ]);
             }
             $args{attributes} = \%attributes if %attributes;

             mreturn(Statistics::R::REXP::Language->new(%args))
         })
}


sub tagged_pairlist_to_rexp_hash {
    my $list = shift;
    return unless ref $list eq ref [];

    my %rexps;
    foreach my $element (@$list) {
        croak "Tagged element has an attribute?!"
            if exists $element->{attribute};
        my $name = $element->{tag}->name;
        $rexps{$name} = $element->{value};
    }
    %rexps
}


## Attributes are recorded as a pairlist, with attribute name in the
## element's tag, and attribute value in the element itself. Pairlists
## that serialize attributes should not have their own attribute.
sub tagged_pairlist_to_attribute_hash {
    my %rexp_hash = tagged_pairlist_to_rexp_hash @_;
    
    my $row_names = $rexp_hash{'row.names'};
    if ($row_names && $row_names->type eq 'integer' &&
        ! defined $row_names->elements->[0]) {
        ## compact encoding when rownames are integers 1..n: the
        ## length n is in the second element, but can be negative to
        ## denote "automatic" rownames
        my $n = abs($row_names->elements->[1]);
        $rexp_hash{'row.names'} = Statistics::R::REXP::Integer->new([1..$n]);
    }

    %rexp_hash
}


## Vector lengths are encoded as signed integers. This was fine when
## the maximum allowed length was 2^31-1; long vectors were introduced
## in R 3.0 and their length is encoded in three bytes: -1, followed
## by high and low word of a 64-bit length.
sub maybe_long_length {
    bind(\&any_int32,
         sub {
             my $len = shift;
             if ($len >= 0) {
                 mreturn $len;
             } elsif ($len == -1) {
                 error 'TODO: Long vectors are not supported';
             } else {
                 error 'Negative length detected: ' . $len;
             }
         })
}


## Vectors are serialized first with a SEXP for the vector elements,
## followed by attributes stored as a tagged pairlist.
sub vector_and_attributes {
    my ($object_info, $element_parser, $rexp_class) = @_;

    my @parsers = ( with_count(maybe_long_length, $element_parser) );
    if ($object_info->{has_attributes}) {
        push @parsers, object_content
    }

    bind(seq(@parsers),
         sub {
             my @args = @{shift or return};
             my %args = (elements => (shift(@args) || []));
             if ($object_info->{has_attributes}) {
                 $args{attributes} = { tagged_pairlist_to_attribute_hash(shift @args) };
             }
             mreturn($rexp_class->new(%args))
         })
}


sub lglsxp {
    my $object_info = shift;
    vector_and_attributes($object_info,
                          bind(\&any_uint32,
                               sub {
                                   my $x = shift;
                                   mreturn ($x != 0x80000000 ?
                                            $x : undef)
                               }),
                          'Statistics::R::REXP::Logical')
}


sub intsxp {
    my $object_info = shift;
    vector_and_attributes($object_info,
                          any_int32_na,
                          'Statistics::R::REXP::Integer')
}


sub realsxp {
    my $object_info = shift;
    vector_and_attributes($object_info,
                          any_real64_na,
                          'Statistics::R::REXP::Double')
}


sub cplxsxp {
    my $object_info = shift;
    
    my @parsers = ( with_count(maybe_long_length, count(2, any_real64_na)) );
    if ($object_info->{has_attributes}) {
        push @parsers, object_content
    }

    bind(seq(@parsers),
         sub {
             my @args = @{shift or return};
             my @elements = @{shift(@args) || []};
             my @cplx;
             foreach my $element (@elements) {
                 my ($re, $im) = @{$element};
                 if (defined($re) && defined($im)) {
                     push(@cplx, Math::Complex::cplx($re, $im))
                 }
                 else {
                     push(@cplx, undef)
                 }
             }
             my %args = (elements => [ @cplx ]);
             if ($object_info->{has_attributes}) {
                 $args{attributes} = { tagged_pairlist_to_attribute_hash(shift @args) };
             }
             mreturn(Statistics::R::REXP::Complex->new(%args))
         })
}


sub strsxp {
    my $object_info = shift;
    vector_and_attributes($object_info, object_content,
                          'Statistics::R::REXP::Character')
}


sub rawsxp {
    my $object_info = shift;
    return error "No attributes are allowed on raw vectors"
        if $object_info->{has_attributes};

    bind(with_count(maybe_long_length, \&any_uint8),
         sub {
             mreturn(Statistics::R::REXP::Raw->new(shift or return));
         })
}


sub vecsxp {
    my $object_info = shift;
    vector_and_attributes($object_info, object_content,
                          'Statistics::R::REXP::List')
}


sub expsxp {
    my $object_info = shift;
    vector_and_attributes($object_info, object_content,
                          'Statistics::R::REXP::Expression')
}


sub charsxp {
    my $object_info = shift;
    ## TODO: handle character set encodings (UTF8, LATIN1, native)
    bind(\&any_int32,
         sub {
             my $len = shift;
             if ($len >= 0) {
                 bind(count( $len, \&any_char),
                      sub {
                          my @chars = @{shift or return};
                          mreturn join('', @chars);
                      })
             } elsif ($len == -1) {
                 mreturn undef;
             } else {
                 error 'Negative length detected: ' . $len;
             }
         })
}


sub symsxp {
    my $object_info = shift;
    bind(object_content,        # should be followed by a charsxp
         sub {
             add_singleton(Statistics::R::REXP::Symbol->new(shift or return));
         })
}


sub refsxp {
    my $object_info = shift;
    my $ref_id = $object_info->{flags} >> 8;
    return error 'TODO: only packed reference ids' if $ref_id == 0;
    get_singleton($ref_id-1)
}


sub envsxp {
    my $object_info = shift;
    reserve_singleton(
        bind(\&any_uint32,
             sub {
                 my $locked = shift;
                 bind(count(4, object_content),
                      sub {
                          my ($enclosure, $frame, $hash, $attributes) = @{$_[0]};
                          
                          ## Frame is a tagged pairlist with tag the symbol and CAR the value
                          my %vars = tagged_pairlist_to_rexp_hash $frame;

                          ## Hash table is a Null or a VECSXP with hash chain per element
                          if ($hash->can('elements')) {
                              ## It appears that a variable appears either in the frame *or*
                              ## in the hash table, so we have to merge the two
                              foreach my $chain (@{$hash->elements}) {
                                  ## Hash chain is a tagged pairlist
                                  my %chain_vars = tagged_pairlist_to_rexp_hash $chain;
                                  
                                  ## Merge the variables from the hash chain
                                  while (my ($name, $value) = each %chain_vars) {
                                      $vars{$name} = $value unless exists $vars{$name} and
                                          die "Variable $name is already defined in the environment";
                                  }
                              }
                          }
                          
                          my %args = (
                              frame => \%vars,
                              enclosure => $enclosure,
                              );
                          if (ref $attributes eq ref []) {
                              $args{attributes} = { tagged_pairlist_to_attribute_hash $attributes };
                          }
                          mreturn(Statistics::R::REXP::Environment->new( %args ));
                      })
             }))
}

sub closxp {
    my $object_info = $_[0];
    
    bind(listsxp(@_),
         sub {
             my ($head, $body) = @{shift()};
             
             my $attributes = $head->{attributes};
             my $environment = $head->{tag};
             my $arguments = $head->{value};
             
             my (@arg_names, @arg_defaults);
             if (ref $arguments eq ref []) {
                 foreach my $arg (@{$arguments}) {
                     push @arg_names, $arg->{tag}->name;
                     
                     my $default = $arg->{value};
                     if (Statistics::R::REXP::Symbol->new('') eq $default) {
                         push @arg_defaults, undef
                     }
                     else {
                         push @arg_defaults, $default
                     }
                 }
             }
             
             my %args = (
                 body => $body // Statistics::R::REXP::Null->new,
                 args => [@arg_names],
                 defaults => [@arg_defaults],
                 environment => $environment);
             if ($object_info->{has_attributes}) {
                 $args{attributes} = { tagged_pairlist_to_attribute_hash $attributes };
             }
             
             mreturn(Statistics::R::REXP::Closure->new( %args ));
         })
}


sub s4sxp {
    my $object_info = shift;
    bind(object_content,
         sub {
             my $attr = shift;
             my $attributes = { tagged_pairlist_to_attribute_hash($attr) };
             my $class = $attributes->{class}->elements;
             croak "S4 'class' must be a single-element array" unless
                 ref($class) eq 'ARRAY' && scalar(@{$class}) == 1;
             my $package = $attributes->{class}->attributes->{package}->elements;
             croak "S4 'package' must be a single-element array" unless
                 ref($package) eq 'ARRAY' && scalar(@{$package}) == 1;
             
             # the remaining attributes should be object's slots
             delete $attributes->{class};
             my $slots = $attributes;
             
             mreturn(Statistics::R::REXP::S4->new(class => $class->[0],
                                                  package => $package->[0],
                                                  slots => $slots))
         })
}


sub unserialize {
    my $data = shift;
    return error "Unserialize requires a scalar data" if ref $data && ref $data ne ref [];

    my $result =
        bind(header,
             \&object_content,
        )->(Statistics::R::IO::ParserState->new(data => $data));
    
    if ($result) {
        my $state = $result->[1];
        carp("remaining data: " . (scalar(@{$state->data}) - $state->position))
            unless $state->eof;
    }
    
    $result;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::IO::REXPFactory - Functions for parsing R data files

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::IO::REXPFactory qw( unserialize );

    # Assume $data was created by reading, say, an RDS file
    my ($rexp, $state) = @{unserialize($data)}
        or die "couldn't parse";
    
    # If we're reading an RDS file, there should be no data left
    # unparsed
    die 'Unread data remaining in the RDS file' unless $state->eof;

    # the result of the unserialization is a REXP
    say $rexp;

    # REXPs can be converted to the closest native Perl data type
    print $rexp->to_pl;

=head1 DESCRIPTION

This module implements the actual reading of serialized R objects
and their conversion to a L<Statistics::R::REXP>. You are not
expected to use it directly, as it's normally wrapped by
L<Statistics::R::IO/readRDS> and L<Statistics::R::IO/readRData>.

=head1 SUBROUTINES

=over

=item unserialize $data

Constructs a L<Statistics::R::REXP> object from its serialization in
C<$data>. Returns a pair of the object and the
L<Statistics::R::IO::ParserState> at the end of serialization.

=item intsxp, langsxp, lglsxp, listsxp, rawsxp, realsxp, refsxp,
strsxp, symsxp, vecsxp, envsxp, charsxp, cplxsxp, closxp, expsxp,
s4sxp

Parsers for the corresponding R SEXP-types.

=item object_content

Parses object info and its data by sequencing L</unpack_object_info>
and L</object_data>.

=item unpack_object_info

Parser for serialized object info structure. Returns a hash with
keys "is_object", "has_attributes", "has_tag", "object_type", and
"levels", each corresponding to the field in R serialization
described in
L<http://cran.r-project.org/doc/manuals/r-release/R-ints.html#Serialization-Formats>.
An additional key "flags" contains the full 32-bit value as stored
in the file.

=item object_data $obj_info

Parser for a serialized R object, using the object type stored in
C<$obj_info> hash's "object_type" key to use the correct parser for
the particular type.

=item vector_and_attributes $object_info, $element_parser, $rexp_class

Convenience parser for vectors, which are serialized first with a
SEXP for the vector elements, followed by attributes stored as a
tagged pairlist. Attributes are stored only if C<$object_info>
indicates their presence, while vector elements are parsed using
C<$element_parser>. Finally, the parsed attributes and elements are
used as arguments to the constructor of the C<$rexp_class>, which
should be a subclass of L<Statistics::R::REXP::Vector>.

=item header

Parser for header of R serialization: the serialization format (XDR,
binary, etc.), the version number of the serialization (currently
2), and two 32-bit integers indicating the version of R which wrote
the file followed by the minimal version of R needed to read the
format.

=item xdr, bin

Parsers for RDS header indicating files in XDR or native-binary
format.

=item maybe_long_length

Parser for vector length, allowing for the encoding of 64-bit long
vectors introduced in R 3.0.

=item tagged_pairlist_to_rexp_hash

Converts a pairlist to a REXP hash whose keys are the pairlist's
element tags and values the pairlist elements themselves.

=item tagged_pairlist_to_attribute_hash

Converts object attributes, which are serialized as a pairlist with
attribute name in the element's tag, to a hash that can be used as
the C<attributes> argument to L<Statistics::R::REXP> constructors.

Some attributes are serialized using a compact encoding (for
instance, when a table's row names are just integers 1:nrows), and
this function will decode them to a complete REXP.

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
