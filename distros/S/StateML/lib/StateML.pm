package StateML ;

$VERSION = 0.22 ;

=head1 NAME

StateML - State Machine Markup Language, with GraphViz and template-driven code generation

=head1 SYNOPSIS

   ## See the stml command for command line use (recommended)

   ## Here's what a .stml file might look like:

   <machine
       id="main"
       xmlns="http://slaysys.com/StateML/1.0"
       xmlns:C="http://your.com/path/to/ns/for/C/code"
       xmlns:Perl="http://your.com/path/to/ns/for/perl/code"
       xmlns:Java="http://your.com/path/to/ns/for/Java/code"
       ...
    >
       <event id="init">
           <C:api>void init_event_handler()</C:api>
       </event>
       <state id="#ALL" graphviz:style="dashed">
           <arc event_id="init" goto="running">
               <C:handler>init_device()</C:handler>
           </arc>
       </state>
       <state id="running"/>
   </machine>

   use StateML;

   my $machine = StateML->parse( $source ); ## filename, GLOB, etc.

   StateML->parse( $source, $machine ); ## Add to existing machine

   ... process $machine as needed, see stml source for ideas...

=head1 DESCRIPTION

WARNING: Alpha code.  I use it in production, but you may want to limit
your use to development only.

StateML is an XML dialect and a tool (L<stml|stml>) that reads this
dialect (by default from files with a ".stml" extension) and converts
it to source code using source code to a data structure.

It can then emit the data structure as a graphviz-generated image
or graph specification or you may take the data structure and do
what you want with it (bin/stml can pass it to template toolkit, for
instance).

=cut

use strict ;
#use SelfTest ;

=for testing
    use Test ;
    use StateML ;
    plan tests => 0 ;

=cut

use XML::SAX::ParserFactory;
use StateML::SAXHandler ;

=for testing
    my $m = StateML->parse( \'<machine><state id="1" /></machine>' ) ;
    ok( scalar $m->states, 1 ) ;

=cut

=over

=item parse

    my $m = StateML->parse( \$StateML_string ) ;
    my $m = StateML->parse( \*F ) ;

=cut

sub parse {
    my $self = shift ;

    my ( $source, $machine ) = @_;

    require StateML::SAXHandler;
    require XML::Filter::Mode;
    my $handler = StateML::SAXHandler->new( $machine ) ;

    my $mode_filter = XML::Filter::Mode->new(
        Handler => $handler,
        Modes   => [$machine->modes],
    );

    ## Require PurePerl for now to get the bugs out
    local $XML::ParserPackage = "XML::SAX::PurePerl";
    my $p = XML::SAX::ParserFactory->parser( 
        Handler           => $mode_filter,
        UseAttributeOrder => 1,
        Source            => $source,
    ) ;
    return $p->parse ;
}

=back

=cut

package StateML::Machine ;

use StateML::Constants qw( stateml_1_0_graphviz_ns );

=head1 graphviz Support

Any XML attributes in the namespace

    http://slaysys.com/StateML/1.0/GraphViz

(generally mapped to the "graphviz:" prefix), like

    <machine
      id="foo"
      xmlns="http://slaysys.com/StateML/1.0"
      xmlns:graphviz="http://slaysys.com/StateML/1.0/GraphViz"
    >

      <event graphviz:style="bold">

      <state id="foo"
        graphviz:style="dashed"
        graphviz:peripheries="2"
      >
    </machine>

are passed to the L<dot> program.  See the dot program for details.
StateML does not police these.

=cut

### HACKHACKHACK: There is no clean way to build a non-template back end,
### yet I want to generate any image format Graphviz can, so I hack it
### in this way.  This is called by the stml program, and as such should
### be somewhere other than here.  Will clean up some day...
sub as_GraphViz {
    my $self = shift ;

    my ( $options ) = @_ ;

    $options->{page_size} ||= "8x10";

    require GraphViz ;
    my $g = GraphViz->new(
        width  => 8,  # defaults
        height => 10,
        $self->attributes( stateml_1_0_graphviz_ns ),
        exists $options->{page_size}
            ? do {
                my ( $w, $h ) =
                    $options->{page_size} =~ /^([\d.]+)[x,]([\d.]+)\z/
                    or die "Invalid page size specification\n";
                (
                    width  => $w,
                    height => $h,
                );
            }
            : (),
    ) ;

    my $show_all = 0 ;

    for ( $self->arcs ) {
        my $from = $_->{FROM} ;
        die "undefined state $_->{FROM}." unless defined $from ;
        $show_all ||= uc $from eq "#ALL";
    }

    for ( $show_all ? ( $self->all_state ) : (), $self->states ) {
        my $label =  $_->name;
        $label .= "\n(" . $_->id . ")" if $options->{show_ids};
        $label .=
            join( "",
                $options->{show_handlers}
                    ? (
                        map( "\nentry: $_", @{$_->{ENTRY_HANDLERS}} ),
                        map( "\nexit:  $_", @{$_->{EXIT_HANDLERS}}  ),
                    )
                    : (),
                ( $options->{show_description}
                    && defined $_->{DESCRIPTION}
                    && length $_->{DESCRIPTION}
                )
                    ? "\n$_->{DESCRIPTION}"
                    : (),
            ) ;

        $_->attribute( stateml_1_0_graphviz_ns, "style", "dashed" )
            if uc $_->id eq "#ALL"
               && ! defined $_->attribute( stateml_1_0_graphviz_ns, "style" ) ;

        $_->{NODE_ID} = $g->add_node(
            $_->id,
            shape    => "record",
            label    => $label,
            height   => 0,
            width    => 0,
            fontsize => $options->{font_size} || 10,
            length $_->{PARENT_ID} && $_->{PARENT_ID} ne $self->id
                ? ( cluster => $_->{PARENT_ID} )
                : (),
            $_->attributes( stateml_1_0_graphviz_ns ),
        ) ;
    }

    my @arcs = $self->arcs;
    my $fold_arcs = 0;

    if ( $fold_arcs ) {
        my %arcs;
        for ( @arcs ) {
            my $name = $_->name;
            $name .= "[" . $_->guard . "]" if defined $_->guard;

            my $key = join "",
                $_->from,
                "->",
                $_->to,
                map { ( "/", $_ ) } $_->handler_descriptions;
            if ( my $arc = $arcs{$key} ) {
                $arc->name( $arc->name . ",\n" . $name );
                $arc->{IsCompositeArc} = 1;
            }
            else {
                $arcs{$key} = StateML::Arc->new( %$_ );
            }
        }
        @arcs = values %arcs;
    }

    for ( @arcs ) {
        my $from = $self->state_by_id( $_->{FROM} )->{NODE_ID} ;
        die "undefined state $_->{FROM}." unless defined $from ;
        my $to   = $self->state_by_id( $_->{TO} )->{NODE_ID} ;
        die "undefined state $_->{TO}." unless defined $to;
        my $label = $_->name;
        $label .=
            "\n[" . $_->guard . "]" if defined $_->guard && length $_->guard;

        if ( $options->{show_handlers} ) {
#            my @descs = $_->handler_descriptions;
#            my $s = join "", $label, @descs;
#            my $prefix = "\n";
#                $_->{IsCompositeArc}
#                || @descs > 1
#                || $s =~ tr/\n//
#                || length $s > 20
#                ? "\n"
#                : "";

            $label .= join "", map "\n  / $_", map {
                local $_ = $_;
                s/\n/\n    /g;
                $_;
            } $_->handler_descriptions;
        }

        if ( defined $_->{DESCRIPTION} && length $_->{DESCRIPTION} ) {
            my $s = "\n$_->{DESCRIPTION}";
            $s =~ s/\n/\n    /;
            $label .= $s;
        }

        $label .= "\n";
        $label =~ s/\\/\\\\/g;
        $label =~ s/"/\\"/g;
        $label =~ s/\n/\\l/g;

        $_->attribute( stateml_1_0_graphviz_ns, "style", "dashed" )
            if uc $from eq "#ALL"
               && ! defined $_->attribute( stateml_1_0_graphviz_ns, "style" ) ;

        $g->add_edge(
            $from => $to,
            fontsize => $options->{font_size} || 10,
            label => "$label",
            $_->attributes( stateml_1_0_graphviz_ns ),
        ) ;
    }

    return $g ;
}

=head1 LIMITATIONS

Alpha code.  Ok test suite, but we may need to change things in
non-backward compatible ways.

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut


1 ;
