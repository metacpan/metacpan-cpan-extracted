package POE::XUL::RDF;
# $Id$
# Copyright Philip Gwyn 2008-2010.  All rights reserved.

use strict;
use warnings;

use URI;
use HTML::Entities qw( encode_entities_numeric );

our $VERSION = '0.0601';

##############################################################
sub new
{
    my( $package, %init ) = @_;
    my $self = bless { data=>[] }, $package;

    # XXX: baseref from current server 
    $self->baseref( $init{baseref} ) if $init{baseref};
    $init{baserdf} ||= 'rdf';
    $self->baserdf( $init{baserdf} ) if $init{baserdf};
    $self->NS( $init{NS} )           if $init{NS};
    $self->data( $init{data} )       if $init{data};
    if( exists $init{dataref} ) {
        $self->dataref( $init{dataref} );
    }
    elsif( ($self->{data}[0]||'') eq 'RDF:about' ) {
        $self->dataref( $self->{data}[1] );
    }

    return $self;
}

##############################################################
sub fragment
{
    my( $self, $name ) = @_;
    my $ret = URI->new( $self->{baserdf} );
    $ret->fragment( $name );
    return $ret;
}

sub rdf_fragment
{
    my( $self, $name ) = @_;
    my $ret = $self->fragment( $name );
    return "rdf:$ret";
}

##############################################################
sub data
{
    my( $self, $data ) = @_;
    return $self->{data} if 1==@_;
    $self->{data} = $data;
}

sub NS
{
    my( $self, $NS ) = @_;
    return $self->{NS} if 1==@_;
    $self->{NS} = $NS;
}

sub baseref
{
    my( $self, $baseref ) = @_;
    return $self->{baseref} if 1==@_;
    $self->{baseref} = URI->new( $baseref );
}

sub baserdf
{
    my( $self, $baserdf ) = @_;
    return $self->{baserdf} if 1==@_;
    if( $self->{baseref} ) {
        $self->{baserdf} = URI->new_abs( $baserdf, $self->{baseref} );
    }
    else {
        $self->{baserdf} = URI->new( $baserdf );
    }
    $self->{baserdf}->fragment( '' );
    return $self->{baserdf};        
}

sub dataref
{
    my( $self, $dataref ) = @_;
    return $self->{dataref} if 1==@_;
    if( $self->{baseref} ) {
        $self->{dataref} = URI->new_abs( $dataref, $self->{baseref} );
    }
    else {
        $self->{dataref} = URI->new( $dataref );
    }
    return $self->{dataref};
}


##############################################################
sub mime_type
{
    return 'application/rdf+xml';
}

##############################################################
## Linear search for the true row that was selected.
sub index_of
{
    my( $self, $col, $primary ) = @_;
    my $offset=0;
    for( my $q=0; $q <= $#{$self->{data}}; $q++ ) {
        if( not ref $self->{data}[$q] ) {
            $offset+=2;
            $q+=2;
        }
        next unless exists $self->{data}[$q]{$col} and
                           $self->{data}[$q]{$col} eq $primary;
        return $q-$offset;
    }
    return -1;
}

##############################################################
sub as_xml
{
    my( $self, $data ) = @_;

    $data ||= $self->{data};
    my @Seq = ( 'RDF:Seq', {}, [] );

    my @RDF = [ 'RDF:RDF', { 'xmlns:RDF' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
                             "xmlns:$self->{NS}" => $self->{baserdf}
                           }, 
                [ \@Seq ]
              ];

    if( $data->[0] eq 'RDF:about' ) {
        $Seq[1]{about} = URI->new_abs( $data->[1], $self->{baseref} );
        $data = [ @{ $data }[ 2..$#$data ] ];
    }

    foreach my $row ( @$data ) {
        push @{ $Seq[2] }, [ 'RDF:li', {}, 
                                [[ 'RDF:Description', {}, [] ]]
                           ];
        my $li = $Seq[2][-1][2][0][2];
        my $att = $Seq[2][-1][2][0][1];
        while( my( $k, $v ) = each %$row ) {
            if( $k =~ /^RDF:(\w+)$/ ) {
                my $a = $1;
                if( $a eq 'about' ) {
                    $att->{$a} = URI->new_abs( $v, $self->{baseref} );
                }
                else {
                    $att->{$a} = $v;
                }
            }
            else {
                push @$li, [ "$self->{NS}:$k", {}, [ $v ] ];
            }
        }
    }
#    use Data::Dumper;
#    warn Dumper \@RDF;

    return $self->_rdf2xml( [@RDF], '' );
}

##############################################################
sub _rdf2xml
{
    my( $self, $rdf, $prefix ) = @_;

    my @ret;
    foreach my $el ( @$rdf ) {
        if( ref $el ) {
            push @ret, "$prefix<$el->[0]".$self->_att2xml( $el->[1] );
            if( $el->[2] and @{ $el->[2] } ) {
                $ret[-1] .= ">";
                if( ref $el->[2][0] ) {
                    push @ret, $self->_rdf2xml( $el->[2], "$prefix  " );
                    push @ret, "$prefix</$el->[0]>";
                }
                else {
                    $ret[-1] .= "$el->[2][0]</$el->[0]>";
                }
            }
            else {
                $ret[-1] .= "/>";
            }
        }
        else {
            push @ret, $el;
        }
    }

    return join "\n", @ret;
}

sub _att2xml
{
    my( $self, $att ) = @_;
    return '' unless keys %$att;
    return join ' ', '', map { 
                join '', 
                    encode_entities_numeric( $_, "\x00-\x1f<>&\'\x80-\xff" ),
                    '="', 
                    encode_entities_numeric( $att->{$_}, "\x00-\x1f<>&\'\x80-\xff" ),
                    '"'
                } keys %$att;
}

1;

__END__

=head1 NAME

POE::XUL::RDF - RDF builder class

=head1 SYNOPSIS

    use POE::XUL::RDF;

    my $data = [
        'RDF:about' => "all-animals",
        { name => 'Lion', species => 'Panthera leo', class => 'Mammal',
            'RDF:about' => "mammals/lion" },
        { name => 'Tarantula', species => 'Avicularia avicularia',
                        class => 'Arachnid',
            'RDF:about' => "arachnids/tarantula" },
        { name => 'Hippopotamus', species => 'Hippopotamus amphibius',
                        class => 'Mammal',
            'RDF:about' => 'mammals/hippopotamus'
        }
    ];

    my $rdf = POE::XUL::RDF->new( baseref => "http://some-url.com" );
    $rdf->baserdf( 'rdf' );
    $rdf->data( $data );

    my $tree = Tree( datasources => $rdf, 
                     ref => $ref->dataref
                     # ...
                   );


=head1 DESCRIPTION

Primitive RDF generation for XUL trees.

=head1 METHODS

=head2 new

    my $rdf = POE::XUL::RDF->new( %params );

Creates a new object.  C<%params> may contain L</NS>, L</baseref>,
L</baserdf>, L</dataref> or L</data>.

=head2 NS

Namespace of the XML tags your data tuples will live in.

=head2 baseref

    $rdf->baseref( $url );
    $url = $rdf->baseref;

Get or set the base URL used to create L</baserdf>, L</dataref> and L</about>.

=head2 baserdf

    $rdf->baserdf( $url );
    $url = $rdf->baserdf;

Get or set the base URL of the data.  Defaults to 'rdf' under L</baseref>.

=head2 dataref

    $rdf->baserdf( $url );
    $tree->setAttribute( ref => $rdf->dataref );

Get or set the URL of the main data sequence.  Can also be set if
you have an L</RDF:about> in your data.

=head2 data

    $rdf->data( $AoH );
    $AoH = $rdf->data;

Get or set the data contained in the RDF.  POE::XUL::RDF only implements
a simplified data format.  C<$AoH> must be an arrayref of hashrefs.  The 
top arrayref is a C<RDF:Seq>.  Each hashref is an C<RDF:li>.  Keys are the
XML tags in the L</NS> namespace.  Values are text nodes.  If a key name
begins with 'RDF:' it is placed as an attribute of the C<RDF:Description>.

Example:

    [ { city=>"Montreal", TZ=>"+5", 'RDF:note' => 'Something' },
      { city=>"Cochabamba", TZ=>"+4" }
    ]

Becomes roughly

    <RDF:Seq>
        <RDF:li><RDF:Description note="Something">
            <NS:city>Montreal</NS:city> 
            <NS:TZ>+5</NS:TZ>
        </RDF:Description></RDF:li>
        <RDF:li><RDF:Description>
            <NS:city>Cochabamba</NS:city>
            <NS:TZ>+4</NS:TZ>
        </RDF:Description></RDF:li>
    </RDF:Seq>


=head3 RDF:about

RDF:about is a special attribute.  Is is converted into an absolute URL
with L</baseref>.  

What's more, if the first element in L</data> is the string 'RDF:about',
the second element is used as the C<about> attribute of the main C<RDF:Seq>.

Example:

    $rdf->baseref( 'http://example.com' );
    $rdf->data( [ 'RDF:about' => 'some-cities', 
                  { city=>"Montreal", TZ=>"+5", 'RDF:about' => 'canada/mtl' },
              ] );

Becomes roughly:

    <RDF:Seq about="http://example.com/some-cities>
        <RDF:li><RDF:Description about="http://example.com/canada/mtl>
            <NS:city>Montreal</NS:city> 
            <NS:TZ>+5</NS:TZ>
        </RDF:Description></RDF:li>
    </RDF:Seq>


=head2 fragment

    my $frag = $rdf->fragment( $name );

Builds an URL that references L<$name> fragment of the current RDF.

=head2 rdf_fragment

    my $frag = $rdf->rdf_fragment( $name );

Builds an L<rdf:> URL that references L<$name> fragment of the current RDF.
Useful for setting the L<sort> attribute of a L<TreeCol>, for example 

        TreeCol( id=>'TZ', sort=>$rdf->rdf_fragment( 'TZ' ) );


=head1 DATASOURCES INTERFACE

The following 3 methods are used to interface with the L<ChangeManager>. You
might want to overload them if you wish to define a new type of datasource.
For example, a DBI datasource.

=head2 as_xml

    my $xml = $rdf->as_xml;

Convert the RDF to an XML string.

=head2 mime_type

    $resp->content_type( $rdf->mime_type );

Returns the MIME-type of the RDF.  Defaults to 'application/rdf+xml'.


=head2 index_of

    my $row = $rdf->index_of( $col, $value );

Search the the first tupple that has the L<$col> column set to L<$value>.
This is needed because if the user has sorted the data in the browser, the
Select event's C<selectedIndex> will reference the row as seen on the screen,
not the row as present in the dataset.

=head1 SEE ALSO

L<POE::XUL::Node>

=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 by Philip Gwyn.  All rights reserved;

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
