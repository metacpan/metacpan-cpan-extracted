package PICA::Field;
{
  $PICA::Field::VERSION = '0.585';
}
#ABSTRACT: Perl extension for handling PICA+ fields
use strict;

use base qw(Exporter);

use Carp qw(croak);
use XML::Writer;
use PICA::Record;
use PICA::Writer;

our @EXPORT = qw(parse_pp_tag);

our $SUBFIELD_INDICATOR = "\x1F"; # 31
our $START_OF_FIELD     = "\x1E"; # 30
our $END_OF_FIELD       = "\x0A"; # 10

our $FIELD_TAG_REGEXP = qr/[012][0-9][0-9][A-Z@]$/;
our $FIELD_OCCURRENCE_REGEXP = qr/[0-9][0-9]$/;
our $SUBFIELD_CODE_REGEXP = qr/^[0-9a-zA-Z]$/;

use overload 
    'bool' => sub { ! $_[0]->empty; },
    '""'   => sub { $_[0]->string; };

use sort 'stable';


sub new($) {
    my $class = shift;
    $class = ref($class) || $class;

    my $tag = shift;
    $tag or croak( "No tag provided." );

    if (not @_) { # empty field
        return PICA::Field->parse($tag); 
    }

    my ($occurrence, $tagno) = parse_pp_tag($tag);

    defined $tagno or croak( "\"$tag\" is not a valid tag." );

    my $self = bless {
        _tag => $tagno,
        _occurrence => $occurrence,
        _subfields => [],
    }, $class;

    $self->add(@_);

    return $self;
}


sub copy {
    my $self = shift;

    my $tagno = $self->{_tag};
    my $occurrence = $self->{_occurrence};

    my $copy = bless {
        _tag => $tagno,
        _occurrence => $occurrence,
    }, ref($self);

    $copy->add( @{$self->{_subfields}} );

    return $copy;
}


sub parse {
    my $class = shift;
    $class = ref($class) || $class;

    my $data = shift;
    my $tag_filter_func = shift;

    # TODO: better manage different parsing modes (normalized, plain, WinIBW...)
    my $END_OF_FIELD = qr/[\x0A\x0D]+/; # local

    $data =~ s/^$START_OF_FIELD//;
    $data =~ s/$END_OF_FIELD$//;

    my $self = bless {}, $class;

    my ($tagno, $subfields) = ($data =~ /([^\$\x1F\x83\s]+)\s?(.*)/);

    return if $tag_filter_func and !$tag_filter_func->($tagno);

    # TODO: better manage different parsing modes (normalized, plain, WinIBW...)
    my $sfreg;
    my $sf = defined $subfields ? substr($subfields, 0, 1) : '';
    if ($sf eq "\x1F") { $sfreg = '\x1F'; }
    elsif ( $sf eq '$' ) { $sfreg = '\$'; }
    elsif( $sf eq "\x83" ) { $sfreg = '\x83'; }
    elsif( $sf eq "\x9f" ) { $sfreg = '\x9f'; }
    elsif( $sf eq '') {
        return $self->new($tagno,'');
    } else {
        croak("not allowed subfield indicator (ord: " . ord($sf) . ") specified");
    }
    $sfreg = '('.$sfreg.'[0-9a-zA-Z])';

    my @sfields = split($sfreg, $subfields);
    shift @sfields;

    my @subfields = ();
    my ($value, $code);
    while (@sfields) {
        $code = shift @sfields;
        $code = substr($code, 1);
        $value = shift @sfields;
        next unless defined $value;
        $value =~ s/\$\$/\$/g if $sf eq '$';
        $value =~ s/\s+/ /gm;
        push(@subfields, ($code, $value));
    }

    return $self->new($tagno, @subfields);
}


sub tag {
    my $self = shift;
    my $tag = shift;

    if (defined $tag) {
        my ($occurrence, $tagno) = parse_pp_tag($tag);
        defined $tagno or croak( "\"$tag\" is not a valid tag." );

        $self->{_tag} = $tagno;
        $self->{_occurrence} = $occurrence;
    }

    return $self->{_tag} . ($self->{_occurrence} ?  ("/" . $self->{_occurrence}) : "");
}


sub occurrence {
    my $self = shift;
    my $occurrence = shift;

    if (defined $occurrence) {
        croak unless $occurrence >= 0 and $occurrence <= 99;
        $self->{_occurrence} = sprintf("%02d", $occurrence);
    }

    return $self->{_occurrence};
}

# Shortcut
*occ = \&occurrence;


sub level {
    my $self = shift;
    return substr($self->{_tag},0,1);
}


sub subfield {
    my $self = shift;
    my $codes = $_[0];
    if (ref($codes) ne 'Regexp') {
        $codes = join('',@_);
        if ($codes eq '') {
            $codes = qr/./;
        } else {
            $codes = qr/[$codes]/;
        }
    }

    my @list;
    my @data = @{$self->{_subfields}};

    for ( my $i=0; $i < @data; $i+=2 ) {
        next unless $data[$i] =~ $codes;
        my $value = $data[$i+1];
        $value =~ s/\s+/ /gm;
        if ( wantarray ) {
            push( @list,  $value );
        } else {
            return $value;
        }
    }

    return $list[0] unless wantarray;
    return @list;
}

# Shortcut
*sf = \&subfield;


sub content {
    my $self = shift;
    my $codes = join('',@_);
    $codes = $codes eq '' ? '.' : "[$codes]";
    $codes = qr/$codes/;

    my @list;
    my @data = @{$self->{_subfields}};

    for ( my $i=0; $i < @data; $i+=2 ) {
        next unless $data[$i] =~ $codes;
        push( @list, [ $data[$i], $data[$i+1] ] );
    }

    return @list;
}


sub add {
    my $self = shift;
    my $nfields = @_ / 2;

    ($nfields >= 1) or return 0;

    for my $i ( 1..$nfields ) {
        my $offset = ($i-1)*2;
        my $code = $_[$offset];
        my $value = $_[$offset+1];
        $value = defined $value ? "$value" : "";
        $value =~ s/\s+/ /gm;

        croak( "Subfield code \"$code\" is not a valid subfield code" )
            if !($code =~ $SUBFIELD_CODE_REGEXP);

        push( @{$self->{_subfields}}, $code, $value );
    }

    return $nfields;
}


sub update {
    my $self = shift;
    my %values;
    my @order;

    # collect values into a hash of array references
    while( @_ ) {
        my $c = shift;
        croak( "Subfield code \"$c\" is not a valid subfield code" )
            unless $c =~ $SUBFIELD_CODE_REGEXP;
        my $v = shift;
        if ( exists $values{$c} ) {
            push @{$values{$c}}, (UNIVERSAL::isa($v,'ARRAY') ? @{$v} : $v);
        } else {
            push @order, $c;
            $values{$c} = UNIVERSAL::isa($v,'ARRAY') ? $v : [ $v ];
        }
    }

    my @data;
    my $changes = 0;

    while ( @{$self->{_subfields}} ) {
        my $code = shift @{$self->{_subfields}};
        my $value = shift @{$self->{_subfields}};

        if ( exists $values{$code} ) {
            if ( defined $values{$code} ) {
                my @vals = grep { defined $_ } @{$values{$code}};
                push @data, map { $code => "$_" } @vals;
                $changes += scalar @vals;
                $values{$code} = undef;
            } 
            # TODO: better count
        } else {
            # keep subfield unchanged
            push @data, $code => $value;
        }
    }

    ## append new subfields in their order
    foreach my $code ( @order ) {
        next unless defined $values{$code};
        my @vals = grep { defined $_ } @{$values{$code}};
        $changes += scalar @vals;
        push @data, map { $code => "$_" } @vals;
    }

    ## synchronize our subfields
    $self->{_subfields} = \@data;

    return $changes;
}


sub replace {
    my $self = shift;
    my $new;

    if (@_ and UNIVERSAL::isa($self,'PICA::Field')) {
        $new = shift;
    } else {
        $new = PICA::Field->new(@_);
    }

    %$self = %$new;
}


sub empty_subfields {
    my $self = shift;

    my @list;
    my @data = @{$self->{_subfields}};

    while ( defined( my $code = shift @data ) ) {
        push (@list, $code) if shift @data eq "";
    }

    return @list;
}


sub empty {
    my $self = shift;

    return 1 unless @{$self->{_subfields}};

    my @data = @{$self->{_subfields}};

    while ( defined( my $code = shift @data ) ) {
        return 0 if shift @data ne "";
    }

    return 1;
}


sub purged {
    my $self = shift;

    my @subfields;
    my $code;
    foreach (@{$self->{_subfields}}) {
        if (defined $code) {
            push @subfields, ($code, $_) if defined $_ and $_ ne "";
            undef $code;
        } else {
            $code = $_;
        }
    }

    return unless @subfields;

    my $copy = bless {
        _tag => $self->{_tag},
        _occurrence => $self->{_occurrence},
        _subfields => \@subfields
    }, ref($self);

    return $copy;
}


sub normalized {
    my $self = shift;
    my $subfields = shift;

    return $self->string( 
      subfields => $subfields,
      startfield => $START_OF_FIELD,
      endfield => $END_OF_FIELD,
      startsubfield => $SUBFIELD_INDICATOR
    );
}


sub sort {
    my ($self, $order) = @_;
    return unless @{$self->{_subfields}};
    $order = "" unless defined $order;

    my (%pos,$i);
    for (split('',$order.'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')) {
        $pos{$_} = $i++ unless defined $pos{$_};
    }

    my @sf = @{$self->{_subfields}};
    my $n = @sf / 2 - 1;
    my @sorted = ();

    @sorted = sort { 
        $pos{$sf[2*$a]} <=> $pos{$sf[2*$b]}
    } (0..$n);

    $self->{_subfields} = [ map { $sf[2*$_] => $sf[2*$_+1] } @sorted ];
}


sub size {
    my $self = shift;
    return @{$self->{_subfields}} / 2;
}


sub string {
    my $self = shift;
    my (%args) = @_ ? @_ : ();

    my $subfields = defined($args{subfields}) ? $args{subfields} : '';
    my $startfield = defined($args{startfield}) ? $args{startfield} : '';
    my $endfield  = defined($args{endfield}) ? $args{endfield} : "\n";
    my $startsubfield = defined($args{startsubfield}) ? $args{startsubfield} : '$';

    my @subs;

    my $subs = $self->{_subfields};
    my $nfields = @$subs / 2;

    for my $i ( 1..$nfields ) {
        my $offset = ($i-1)*2;
        my $code = $subs->[$offset];
        my $value = $subs->[$offset+1];
        if (!$subfields || $code =~ /^[$subfields]$/) {
            $value =~ s/\$/\$\$/g if $startsubfield eq '$';
            push( @subs, $code.$value ) 
        }
    } # for

    return "" unless @subs; # no subfields => no field

    my $occ = '';
    $occ = "/" . $self->{_occurrence} if defined $self->{_occurrence};

    return $startfield .
           $self->{_tag} . $occ . ' ' .
           $startsubfield . join( $startsubfield, @subs ) .
           $endfield;
}

# Write the field to a L<XML::Writer> object
my $write_xml = sub {
    my ($self, $writer) = @_;

    my ($datafield, $subfield);

    if (UNIVERSAL::isa( $writer, 'XML::Writer::Namespaces' )) {
        $datafield = [$PICA::Record::XMLNAMESPACE, 'datafield'];
        $subfield  = [$PICA::Record::XMLNAMESPACE, 'subfield'];
    } else {
        $datafield = 'datafield';
        $subfield = 'subfield';    
    }

    my %attr = ('tag' =>  $self->{_tag});
    $attr{occurrence} = $self->{_occurrence} if defined $self->{_occurrence};

    $writer->startTag( $datafield, %attr );

    my $subs = $self->{_subfields};
    my $nfields = @$subs / 2;

    if ($nfields) {
        for my $i ( 1..$nfields ) {
            my $offset = ($i-1)*2;
            $writer->startTag( $subfield, code =>  $subs->[$offset] );
            $writer->characters(  $subs->[$offset+1] );
            $writer->endTag(); # subfield
        }
    }

    $writer->endTag(); # datafield

    $writer;
};


sub xml {
    my $self = shift;

    my %param;
    if ( UNIVERSAL::isa( $_[0], 'XML::Writer' ) ) {
        (%param) = ( writer => @_ );
    } elsif ( ref($_[0]) ) {
        (%param) = ( OUTPUT => @_ );
    } else {
        (%param) = @_;
    }

    if ( defined $param{writer} ) {
        $write_xml->( $self, $param{writer} );
        return $param{writer};
    } else {
        my ($string, $sref);
        if (not defined $param{OUTPUT}) {
            $sref = \$string;
            $param{OUTPUT} = $sref;
        }

        my $writer = PICA::Writer::xmlwriter( %param );

        $write_xml->( $self, $writer );

        return defined $sref ? "$string" : $writer;
    }
}


sub html  {
    my $self = shift;
    my %options = @_;

    # CSS classes (TODO: customize)
    my $field = 'field';
    my $tag = 'tag';
    my $tagcode = 'tagcode';
    my $occurrence = 'occurrence';
    my $sfcode = 'sfcode';
    my $sfindicator = 'sfindicator';

    my $html = "<div class='$field'><span class='$tag'>" 
             . "<span class='$tagcode'>" . $self->{_tag} . "</span>";
    if (defined $self->{_occurrence}) {
        $html .= "/<span class='$occurrence'>"
               . $self->{_occurrence} . "</span>";
    } else {
        # TODO: in monospaced mode only
        # $html .= "&#xA0;&#xA0;&#xA0;";
    }
    $html .= "</span> "; # tag

    my $subs = $self->{_subfields};
    my $nfields = @$subs / 2;
    if ($nfields) {
    for my $i ( 1..$nfields ) {
        my $offset = ($i-1)*2;
        my $code = $subs->[$offset];
        my $text = $subs->[$offset+1];
        $html .= "<span class='$sfindicator'>\$</span>"
               . "<span class='$sfcode'>$code</span>";
        $text =~ s/&/&amp;/g;
        $text =~ s/</&lt;/g;
        $html .= $text; # TODO: character encoding (?)
    }
    }
    return $html . "</div>\n";
}


sub parse_pp_tag {
    my $tag = shift;

    my ($tagno, $occurrence) = split ('/', $tag);
    undef $tagno unless defined $tagno and $tagno =~ $FIELD_TAG_REGEXP;
    undef $occurrence unless defined $occurrence and $occurrence =~ $FIELD_OCCURRENCE_REGEXP;

    return ($occurrence, $tagno);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PICA::Field - Perl extension for handling PICA+ fields

=head1 VERSION

version 0.585

=head1 SYNOPSIS

  use PICA::Field;
  my $field = PICA::Field->new( '028A',
    '9' => '117060275',
    '8' => 'Martin Schrettinger'
  );

  $field->add( 'd' => 'Martin', 'a' => 'Schrettinger' );
  $field->update( "8", "Schrettinger, Martin" );

  print $field->normalized;
  print $field->xml;

=head1 DESCRIPTION

Defines PICA+ fields for use in the PICA::Record module.

=head1 EXPORT

The method C<parse_pp_tag> is exported.

=head1 METHODS

=head2 new ( [...] )

The constructor, which will return a C<PICA::Field> object or croak on error.
You can call the constructor with a tag and a list of subfields:

  PICA::Field->new( '028A',
    '9' => '117060275',
    '8' => 'Martin Schrettinger'
  );

With a string of normalized PICA+ data of one field:

  PICA::Field->new("\x1E028A \x1F9117060275\x1F8Martin Schrettinger\x0A');

With a string of readable PICA+ data:

  PICA::Field->new('028A $9117060275$8Martin Schrettinger');

=head2 copy ( $field )

Creates and returns a copy of this object.

=head2 parse ( $string, [, \&tag_filter_func ] )

The constructur will return a PICA::Field object based on data that is 
parsed if null if the filter dropped the field. Dropped fields will not 
be parsed so they are also not validated.

The C<$tag_filter_func> is an optional reference to a user-supplied 
function that determines on a tag-by-tag basis if you want the tag to 
be parsed or dropped. The function is passed the tag number (including 
occurrence), and must return a boolean. 

For example, if you only want to 021A fields, try this:

The filter function can be used to select only required fields

   sub filter {
        my $tagno = shift;
        return $tagno eq "021A";
    }
    my $field = PICA::Field->parse( $string, \&filter );

=head2 tag ( [ $tag ] )

Returns the PICA+ tag and occurrence of the field. Optionally sets tag (and occurrence) to a new value.

=head2 occurrence ( [ $occurrence ] ) or occ ( ... )

Returns the ocurrence or undef. Optionally sets the ocurrence to a new value.

=head2 level ( )

Returns the level (0: main, 1: local, 2: copy) of this field.

=head2 subfield ( [ $code(s) ] ) or sf ( ... )

Return selected or all subfield values. If you specify 
one ore more subfield codes, only matching subfields are 
returned. When called in a scalar context returns only the
first (matching) subfield. You may specify multiple subfield codes:

    my $subfield = $field->subfield( 'a' );   # first $a
    my $subfield = $field->subfield( 'acr' ); # first of $a, $c, $r
    my $subfield = $field->subfield( 'a', 'c', 'r' ); # the same

    my @subfields = $field->subfield( '0-9' );     # $0 ... $9
    my @subfields = $field->subfield( qr/[0-9]/ ); # $0 ... $9

    my @subfields = $field->subfield( 'a' );
    my @all_subfields = $field->subfield();

If no matching subfields are found, C<undef> is returned in a scalar
context or an empty list in a list context.

Remember that there can be more than one subfield of a given code!

=head2 content ( [ $code(s) ] )

Return selected or all subfields as an array of arrays. If you specify 
one ore more subfield codes, only matching subfields are returned. See
the C<subfield> method for more examples.

This shows the subfields from a 021A field:

        [
          [ 'a', '@Traité de documentation' ],
          [ 'd', 'Le livre sur le livre ; Théorie et pratique' ],
          [ 'h', 'Paul Otlet' ]
        ]

=head2 add ( $code, $value [, $code, $value ...] )

Adds subfields to the end of the subfield list.
Whitespace in subfield values is normalized.

    $field->add( 'c' => '1985' );

Returns the number of subfields added. 

=head2 update ( $sf => $value [ $sf => $value ...] )

Allows you to change the values of the field for one or more given subfields:

  $field->update( a => 'Little Science, Big Science' );

If you attempt to update a subfield which does not currently exist in the field,
then a new subfield will be appended. If you don't like this auto-vivification
you must check for the existence of the subfield prior to update.

  if ( defined $field->subfield( 'a' ) ) {
      $field->update( 'a' => 'Cryptonomicon' );
  }

Instead of a single value you can also pass an array reference. The following
statements should have the same result:

  $field->update( 'x', 'foo', 'x', 'bar' );
  $field->update( 'x' => ['foo', 'bar'] );

To remove a subfield, update it to undef or an empty array reference:

  $field->update( 'a' => undef );
  $field->update( 'a' => [] );

=head2 replace ( $field | ... )

Allows you to replace an existing field with a new one. You may pass a
C<PICA::Field> object or parameters for a new field to replace the
existing field with. Replace does not return a meaningful or reliable value.

=head2 empty_subfields ( )

Returns a list of all codes of empty subfields.

=head2 empty ( )

Test whether there are no subfields or all subfields are empty. This method 
is automatically called by overloading whenever a PICA::Field is converted 
to a boolean value.

=head2 purged ( )

Remove a copy of this field with empty subfields
removed or undef if the whole field is empty.

=head2 normalized ( [$subfields] )

Returns the field as a string. The tag number, occurrence and 
subfield indicators are included. 

If C<$subfields> is specified, then only those subfields will be included.

=head2 sort ( [ $order ] )

Sort subfields by subfield indicators. You can optionally specify an order as string of subfield codes.

=head2 size

Returns the number of subfields (no matter if empty or not).

=head2 string ( [ %params ] )

Returns a pretty string for printing.

Returns the field as a string. The tag number, occurrence and 
subfield indicators are included. 

If C<subfields> is specified, then only those subfields will be included.

Fields without subfields return an empty string.

=head2 xml ( [ [ writer => ] $writer | [ OUTPUT ] => \$sref | %param ] )

Return the field in PICA-XML format or write it to an L<XML::Writer>
and return the writer. If you provide parameters, they will be passed
to a newly created XML::Writer that is used to write to a string.

By default the PICA-XML namespaces with namespace prefix 'pica' is 
included. In addition to XML::Writer this methods knows the 'header'
parameter that first adds the XML declaration.

=head2 html ( [ %options ] )

Returns a HTML representation of the field for browser display. See also
the C<pica2html.xsl> script to generate a more elaborated HTML view from
PICA-XML.

=head1 STATIC METHODS

=head2 parse_pp_tag tag ( $tag )

Tests whether a string can be used as a tag/occurrence specifier. A tag
indicator consists of a 'type' (00-99) and an 'indicator' (A-Z and @),
both conflated as the 'tag', and an optional occurrence (00-99). This
method returns a list of two values: occurrence and tag (this order!).
It can be used to parse and test tag specifiers this ways:

  ($occurrence, $tag) = parse_pp_tag( $t );
  parse_pp_tag( $t ) or print STDERR "Not a valid tag: $t\n";

=head1 SEE ALSO

This module was inspired by L<MARC::Field> by Andy Lester.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Verbundzentrale Goettingen (VZG) and Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
