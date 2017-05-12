use ExtUtils::MakeMaker;

my $has_graphviz = eval "require GraphViz";

warn $has_graphviz ? <<GRAPHVIZWARN : <<NOGRAPHVIZWARN, <<GRAPHVIZPATCH;
GraphViz.pm detected.
GRAPHVIZWARN
GraphViz.pm not detected, but you may not need it.
NOGRAPHVIZWARN

    GraphViz.pm and the underlying AT&T graphviz toolkit are (only) used
    to render state machine diagrams.  It is not needed to generate
    source code from StateML files, etc.

    GraphViz support is experimental and you may need to patch
    GraphViz.pm to properly escape node and arc labels (otherwise, text
    from the StateML files cause GraphViz.pm to generate invalid
    specifications for the "dot" program).  See the file GraphViz.patch
    in the same directory as this Makefile.PL.

    The underlying graphviz program from AT&T should also be up to date
    (some versions have various layou bugs), and don't expect perfect
    results for large, complicated graphs.

    All that being said, I use GraphViz locally to graph almost all the
    state machines we do.

GRAPHVIZPATCH

WriteMakefile(
    NAME          => 'StateML',
    EXE_FILES     => [ 'bin/stml' ],
    VERSION_FROM  => 'lib/StateML.pm',
    PREREQ_PM => {
#        'GraphViz'                => 0,  #recommended, not required
        'XML::SAX::ParserFactory' => 0,
        'XML::Filter::Mode'       => 0,
        'Template'                => 2,   ## Template Toolkit
    },
);


sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}
