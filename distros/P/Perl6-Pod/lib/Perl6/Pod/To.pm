package Perl6::Pod::To;
our $VERSION = '0.01';
use strict;
use warnings;

=pod

=head1 NAME

Perl6::Pod::To - base class for output formatters

=head1 SYNOPSIS


=head1 DESCRIPTION

Perl6::Pod::To - base class for output formatters

=cut

use Carp;
use Perl6::Pod::Utl::AbstractVisiter;
use base 'Perl6::Pod::Utl::AbstractVisiter';
use Perl6::Pod::Block::SEMANTIC;

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );

    # check if exists context
    # create them instead
    unless ( $self->context ) {
        use Perl6::Pod::Utl::Context;
        $self->context( new Perl6::Pod::Utl::Context:: );
    }
    unless ( $self->writer ) {
        use Perl6::Pod::Writer;
        $self->{writer} = new Perl6::Pod::Writer(
            out => ( $self->{out} || \*STDOUT ),
            escape => 'xml'
        );
    }

    #init head levels
    $self->{HEAD_LEVELS} = 0;
    $self;
}

sub writer {
    return $_[0]->{writer};
}

sub w {
    return $_[0]->writer;
}

sub context {
    my $self = shift;
    if (@_) {
        $self->{context} = shift;
    }
    return $self->{context};
}

#TODO then visit to child -> create new context !
sub visit_childs {
    my $self = shift;
    foreach my $n (@_) {
        die "Unknow type $n (not isa Perl6::Pod::Block)"
          unless UNIVERSAL::isa( $n, 'Perl6::Pod::Block' )
              || UNIVERSAL::isa( $n, 'Perl6::Pod::Lex::Block' );
        unless ( defined $n->childs ) {

            #die " undefined childs for". Dumper ($n)
            next;
        }
        $self->visit( $n->childs );
    }
}

sub _make_dom_node {
    my $self = shift;
    my $n = shift || return;

    # if string -> nothing to do
    unless ( ref($n) ) {
        return $n;
    }

    # here convert lexer base block to
    # instance of DOM class
    my $name = $n->name;
    my $map  = $self->context->use;
    my $class;
    #convert lexer blocks
    unless ( UNIVERSAL::isa( $n, 'Perl6::Pod::Block' ) ) {

        my %additional_attr = ();
        if ( UNIVERSAL::isa( $n, 'Perl6::Pod::Lex::FormattingCode' ) ) {
            $class = $map->{ $name . '<>' } || $map->{'*<>'};
        }

        # UNIVERSAL::isa( $n, 'Perl6::Pod::Lex::Block' )
        else {

            if ( $name =~ /(para|code)/ ) {

                # add { name=>$name }
                # for text and code blocks

                $additional_attr{name} = $name;
            }

            $class = $map->{$name}
              || (
                $name eq uc($name)
                ? 'Perl6::Pod::Block::SEMANTIC'
                : $map->{'*'}
              );
        }

        #create instance
        my $el =
            $class eq '-'
          ? $n
          : $class->new( %$n, %additional_attr, context => $self->context );

        #if no instanse -> skip this element
        return undef unless ($el);
        $n = $el;
    }
    return $n;
}

sub visit {
    my $self = shift;
    my $n    = shift;

    # if string -> paragraph
    unless ( ref($n) ) {
        return $self->w->print($n);
    }

    if ( ref($n) eq 'ARRAY' ) {

        #       $self->visit($_) for @$n;
        my @nodes = grep { defined $_ }       #skip empty nodes
          map { $self->_make_dom_node($_) }
          map { ref($_) eq 'ARRAY' ? @$_ : $_ } @$n;
        my ( $prev, $next ) = ();
        for ( my $i = 0 ; $i <= $#nodes ; ++$i ) {
            if ( $i == $#nodes ) {
                $next = undef;
            }
            else {
                $next = $nodes[ $i + 1 ];
            }
            $self->visit( $nodes[$i], $prev, $next );
            $prev = $nodes[$i];
        }
        return;
    }

    die "Unknown node type $n (not isa Perl6::Pod::Lex::Block)"
      unless UNIVERSAL::isa( $n, 'Perl6::Pod::Lex::Block' );

    #unless already converted to DOM element
    unless ( UNIVERSAL::isa( $n, 'Perl6::Pod::Block' ) ) {
        $n = $self->_make_dom_node($n) || return;
    }
    my $name = $n->name;

    #prcess head levels
    #TODO also semantic BLOCKS
    if ( $name eq 'head' ) {
        $self->switch_head_level( $n->level );
    }

    #process nested attr
    my $nested = $n->get_attr->{nested};
    if ($nested) {
        $self->w->start_nesting($nested);
    }

    #make method name
    my $method = $self->__get_method_name($n);

    #call method
    $self->$method( $n, @_ );    # $prev, $to in @_

    if ($nested) {
        $self->w->stop_nesting($nested);
    }
}

=head2 switch_head_level

Service method for =head

=cut

sub switch_head_level {
    my $self = shift;
    if (@_) {
        my $prev = $self->{HEAD_LEVELS};
        $self->{HEAD_LEVELS} = shift;
        return $prev;
    }
    $self->{HEAD_LEVELS};
}

sub __get_method_name {
    my $self = shift;
    my $el = shift || croak "empty object !";
    my $method;
    use Data::Dumper;
    unless ( UNIVERSAL::isa( $el, 'Perl6::Pod::Block' ) ) {
        warn "unknown block" . Dumper($el);
    }
    my $name = $el->name || die "Can't get element name for " . Dumper($el);
    if ( UNIVERSAL::isa( $el, 'Perl6::Pod::FormattingCode' ) ) {
        $method = "code_$name";
    }
    else {
        $method = "block_$name";
    }
    return $method;
}

sub block_File {
    my $self = shift;
    return $self->visit_childs(shift);
}

sub block_pod {
    my $self = shift;
    return $self->visit_childs(shift);
}

#comments
sub code_Z        { }
sub block_comment { }

sub write {
    my $self = shift;
    my $tree = shift;
    $self->visit($tree);
}

=head2 parse \$TEXT

parse text

=cut

sub parse {
    my $self = shift;
    my $text = shift;
    use Perl6::Pod::Utl;
    my $tree = Perl6::Pod::Utl::parse_pod( ref($text) ? $$text : $text, @_ )
      || return "Error";
    $self->start_write;
    $self->write($tree);
    $self->end_write;
    0;
}

# unless have export method
# try element methods for export
sub __default_method {
    my $self = shift;
    my $n    = shift;

    #detect output format
    # Perl6::Pod::To::DocBook -> to_docbook
    my $export_format = $self->{format};
    unless ($export_format) {
           ( $export_format = ref($self) ) =~ s/^.*To::([^:]+)/lc "$1"/es;
    }
    my $export_method = lc "to_$export_format";
    unless ( $export_method && UNIVERSAL::can( $n, $export_method ) ) {
        my $method = $self->__get_method_name($n);
        warn ref($self)
          . ": Method '$method' for class "
          . ref($n)
          . " not implemented. But also can't found export method "
          . ref($n)
          . "::$export_method";
        return;
    }

    #call method for export
    $n->$export_method( $self, @_ )    # $prev, $to
}

sub start_write {
    my $self = shift;
}

sub end_write {
    my $self = shift;
}

1;
__END__


=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut


