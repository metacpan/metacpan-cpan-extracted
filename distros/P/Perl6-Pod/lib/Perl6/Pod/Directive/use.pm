package Perl6::Pod::Directive::use;

=pod

=head1 NAME

Perl6::Pod::Directive::use - handle =use directive

=head1 SYNOPSIS

Load the corresponding Perldoc module:

    =use Test::Tag
    =for Tag
    text data

Define own formatting code:
    
    =use Perldoc::TT
    =config TT<>  :allow<E>
    head1 Overview of the M<TT: $CLASSNAME > class


=head1 DESCRIPTION

Perldoc provides a mechanism by which you can extend the syntax, semantics, or content of your documentation: the =use directive.

Specifying a =use causes a Perldoc processor to load the corresponding Perldoc module at that point, or to throw an exception if it cannot. 

Such modules can specify additional content that should be included in the document. Alternatively, they can register classes that handle new types of block directives or formatting codes. 

Note that a module loaded via a =use statement can affect the content or the interpretation of subsequent blocks, but not the initial parsing of those blocks. Any new block types must still conform to the general syntax described in this document. Typically, a module will change the way that renderers parse the contents of specific blocks. 

A =use directive may be specified with either a module name or a URI:

    =use MODULE_NAME  OPTIONAL CONFIG DATA
    =                 OPTIONAL EXTRA CONFIG DATA
    
    =use URI

If a URI is given, the specified file is treated as a source of Pod to be included in the document. Any Pod blocks are parsed out of the contents of the =use'd file, and added to the main file's Pod representation at that point. 

If a module name is specified with any prefix except pod:, or without a prefix at all, then the corresponding .pm file (or another language's equivalent code module) is searched for in the appropriate module library path. If found, the code module require'd into the Pod parser (usually to add a class implementing a particular Pod extension). If no such code module is found, a suitable .pod file is searched for instead, the contents parsed as Pod, and the resulting block objects inserted into the main file's representation

Any options that are specified after the module name:

    =use Perldoc::Plugin::Image  :Jpeg  prefix=>'http://dev.perl.org'

are passed to the internal require that loads the corresponding module.

Collectively these alternatives allow you to create standard documentation inserts or stylesheets, to include Pod extracted from other code files, or to specify new types of documentation blocks and formatting codes:

=over

=item * To create a standard Pod insertion or stylesheet, create a .pod file and install it in your documentation path. Load it with either:

          =use Pod::Insertion::Name

or:

          =use pod:Pod::Insertion::Name

or:

          =use file:/full/path/spec/Pod/Insertion/Name.pod

or even:

          =use http://www.website.com/Pod/Insertion/Name.pod

=item *  To insert the Pod from a .pm file (for example, to have your class documentation include documentation from a base class):

          =use pod:Some::Other::Module

=item * To implement a new Pod block type or formatting code, create a .pm file and load it with either:

          =use New::Perldoc::Subclass

or (more explicitly):

          =use perl6:New::Perldoc::Subclass

=item * To create a module that inserts Pod and also require's a parser extension, install a .pod file that contains a nested =use that imports the necessary plug-in code. Then load the Pod file as above.

A typical example would be a Perldoc extension that also needs to specify some preconfiguration:

          =use Hybrid::Content::Plus::Extension

Then, in the file some_perl_doc_dir/Hybrid/Content/Plus/Extension.pod:

          =begin code :allow<R>
          =comment This file sets some config and also enables the Graph block

          =config Graph :formatted< B >

          =use perl6:Perldoc::Plugin::Graph-(*)-cpan:MEGAGIGA
          =end code

Note that =use is a fundamental Perldoc directive, like =begin or =encoding, so there is no paragraph or delimited form of =use. 

=back

=head1 NOTES

Perl6::Pod handle exended syntax:

    =use MODULE_NAME FORMAT_CODE<> OPTIONAL CONFIG DATA
    =                 OPTIONAL EXTRA CONFIG DATA

    =use MODULE_NAME BLOCK_NAME OPTIONAL CONFIG DATA
    =                 OPTIONAL EXTRA CONFIG DATA

Fo example:

    =comment Overwrite default class for standart formatting code
    =use Perldoc::TT B<>

    =comment Define custom BlockNames
    =use Perldoc::TT Alias1
    =use Perldoc::TT Alias2

Perl6::Pod also handle ${PERL6POD} variable in package namespace. It used for evalute Pod chunk for
loaded Module.

For package contains variable $PERL6POD:

    package UserDefined::Lib;
    use strict;
    use warnings;
    our $PERL6POD = <<POD;
    =begin pod
    =use UserDefined::Module
    =use UserDefined::Image
    =end pod
    POD
    1;

We can evalute Pod in the Pod file:

    =begin pod
    =comment Evalute $PERL6POD
    =use UserDefined::Lib
    =comment Now will use =Image  block
    =Image http://example.com/image.png
    =end pod


=cut

use warnings;
use strict;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

sub new {
      my ( $class, %args ) = @_;
      my $self = $class->SUPER::new(%args, parent_context=>1);
}

sub start {
    my $self = shift;
    my ( $parser, $attr ) = @_;
    $self->delete_element->skip_content;
    #handle
    #=use Module::Name block_name :config_attr
    my $opt = $self->{_pod_options};
    my ( $class, @params ) = split( /\s+/, $opt );
    my $prefix;
    #extract prefix
    if ( $class =~ /^(\w+)\:([^:][\w\:]+)$/ ) {
        #if perl
        ( $prefix, $class ) = ($1,$2);
    }
    #now determine name
    my $name;
    if ( $params[0] and $params[0] !~ /^:/) {
        $name = shift @params
    }
    unless ( $name ) { #get name from class
        ( $name ) = reverse split( /::/, $class);
    }

    $self->{_pod_options} = join " ", @params;

    #try to load class
    #    eval "use $class";
    #check non loaded mods

    #check non loaded mods
    my ( $main, $module ) = $class =~ m/(.*\:\:)?(\S+)$/;
    $main ||= 'main::';
    $module .= '::';
    no strict 'refs';
    unless ( exists $$main{$module} ) {
        eval "use $class";
        if ($@) {
            warn "Error register class :$class with $@ ";
            return "Error register class :$class with $@ ";
            next;
        }
    }
    #special handles for =use UserDefined::Lib
    #use $PERL6POD for include
    unless ( UNIVERSAL::isa( $class, 'Perl6::Pod::Block' ) ) {
        my $perl6pod = ${ "${class}::PERL6POD" };
        return unless defined ($perl6pod);
        #check if exists special variable
        $parser->_parse_chunk(\$perl6pod);
        return;
    }
    use strict 'refs';

    $parser->current_context->use->{$name} = $class;
    #store class options for loaded mods
    $parser->current_context->class_opts->{$name} = $self->{_pod_options};
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

