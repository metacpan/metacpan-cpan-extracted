package Template::Caribou::Role;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Caribou core engine
$Template::Caribou::Role::VERSION = '1.2.2';

use 5.20.0;
use strict;
use warnings;
no warnings qw/ uninitialized /;

use Carp;
use Moose::Role;
use Template::Caribou::Utils;

use Path::Tiny;

use Template::Caribou::Tags;

use List::AllUtils qw/ uniq any /;

use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    as_is => [ 'template' ],
);

use experimental 'signatures';

has indent => (
    is      => 'rw',
    default => 1,
);

has can_add_templates => (
    is => 'rw',
);

sub template {
    my $class = shift;

    # cute way to say $self might or might not be there
    my( $coderef, $name, $self ) = reverse @_;

    if ( $self ) {
        local $Carp::CarpLevel = 1;
        croak "can only add templates from instances created via 'anon_instance' ",
            "or with the attribute 'can_add_templates'" unless $self->can_add_templates;

        $class = $self->meta;
    }

    carp "redefining '$name'" 
        if $class->can('get_all_method_names') and any { $name eq $_ } $class->get_all_method_names;
    carp "redefining '$name'" if $class->name->can($name);


    $class->add_method( $name => sub {
        my( $self, @args ) = @_;
        if( defined wantarray ) {
            return $self->render( $coderef, @args );
        }
        else {
            # void context
            $self->render( $coderef, @args );
            return;
        }
    });
}



sub anon_instance($class,@args) {
    Class::MOP::Class
        ->create_anon_class(superclasses => [ $class ])
        ->new_object( can_add_templates => 1, @args);
}

sub get_render {
    my ( $self, $template, @args ) = @_;
    local $Template::Caribou::IN_RENDER;
    return $self->render($template,@args);
}

sub render {
    my ( $self, $template, @args ) = @_;

    # 0.1 is true, and yet will round down to '0' for the first indentation
    local $Template::Caribou::TAG_INDENT_LEVEL 
        = $Template::Caribou::TAG_INDENT_LEVEL // 0.1 * !! $self->indent;

    my $output = $self->_render($template,@args);

    # if we are still within a render, we turn the string
    # into an object to say "don't touch"
    $output = Template::Caribou::String->new( $output ) 
        if $Template::Caribou::IN_RENDER;

    # called in a void context and inside a template => print it
    print ::RAW $output if $Template::Caribou::IN_RENDER;

    return $output;
}

sub _render ($self, $method, @args) {
    local $Template::Caribou::TEMPLATE = $self;
            
    local $Template::Caribou::IN_RENDER = 1;
    local $Template::Caribou::OUTPUT;

    unless(ref $method) {
        $method = $self->can($method)
            or die "no template named '$method' found\n";
    }

    local *STDOUT;
    local *::RAW;
    tie *STDOUT, 'Template::Caribou::Output';
    tie *::RAW, 'Template::Caribou::OutputRaw';

    select STDOUT;

    my $res = $method->( $self, @args );

    return( $Template::Caribou::OUTPUT 
            or ref $res ? $res : Template::Caribou::Output::escape( $res ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Caribou::Role - Caribou core engine

=head1 VERSION

version 1.2.2

=head1 SYNOPSIS

    package MyTemplate;

    use Template::Caribou;

    has name => ( is => 'ro' );

    template greetings => sub {
        my $self = shift;

        print "hello there, ", $self->name;
    };

    # later on...
    
    my $template =  MyTemplate->new( name => 'Yanick' );

    print $template->greetings;

=head1 DESCRIPTION

This role implements the rendering core of Caribou, which mostly deals
with defining the templates of a class and calling them.

=head2 The templates

The templates are subs expected to print or return the content they are generating.
Under the hood, they are snugly wrapped within a C<render> call and turned
into methods of the template class.

    package MyTemplate;

    use Template::Caribou;

    has name => ( is => 'ro' );

    template greetings => sub {
        my( $self, %args ) = @_;

        'hi there ' . $self->name . '!' x $args{excited};
    };

    my $bou = MyTemplate->new( name => 'Yanick' );

    print $bou->greetings; 
        # prints 'hi there Yanick'

    print $bou->greetings(excited => 1);
        # print 'hi there Yanick!

In addition of those arguments, the file descriptions
C<::STDOUT> and C<::RAW> are locally defined. Anything printed to C<::RAW> is added verbatim to the
content of the template, whereas something printed to C<STDOUT> will be HTML-escaped. 

If nothing has been printed at all by the template, it'll take its return
value as its generated content.

    # prints '&lt;hey>'
    print MyTemplate->render(sub{
        print "<hey>";
    });
    
    # prints '<hey>'
    print MyTemplate->render(sub{
        print ::RAW "<hey>";
    });

    # prints 'onetwo'
    print MyTemplate->render(sub{
        print "one";
        print "two";
    });
    
    # prints 'one'
    print MyTemplate->render(sub{
        print "one";
        return "ignored";
    });
    
    # prints 'no print, not ignored'
    print MyTemplate->render(sub{
        return "no print, not ignored";
    });

Template methods can, of course, be called within other template methods.
When invoked from within a template, their content is implicitly printed
to C<::RAW>.

    template outer => sub {
        my $self = shift;

        say 'alpha';
        $self->inner;
        say 'gamma';
    };

    template inner => sub {
        say 'beta';
    };

    ...;

    print $bou->outer; # prints 'alpha beta gamma'

=head2 Definiting templates via template instances

Templates are usually defined for the class via the 
C<template> keyword. C<template> can also be used as a method. By default,
though, it'll die as adding a template that way will not only add it to
the instance, but for to class itself, which is probably more
than you bargained for.

    $bou->template( foo => sub { ... } );
    # dies with 'can only add templates from instances created 
    # via 'anon_instance' or with the attribute 'can_add_templates'

If you want to add a template to a single instance, use
the class method C<anon_instance>, which will create a singleton
class inheriting from the main template class.

    my $bou = MyTemplate->anon_instance( name => 'Yanick' );

    $bou->template( foo => sub { ... } ); # will work

Or if you really want to augment the whole class with new
templates, you can set the C<can_add_templates> attribute of
the object to C<true>.

    $bou->can_add_templates(1); 
    $bou->template( foo => sub { ... } ); # will work too

=head1 METHODS

=head2 new

    my $bou = MyTemplate->new(
        indent            => 1,
        can_add_templates => 0,
    );

=over

=item indent => $boolean

If set to a C<true> value, the nested tags rendered inside
the templates will be indented. Defaults to C<true>.

=item can_add_templates

If templates can be added to the class via the method
invocation of C<template>.

=back

=head2 indent

    $bou->indent($bool);

Accessor to the indent attribute. Indicates if the tags rendered 
within the templates should be pretty-printed with indentation or not. 

=head2 can_add_templates

    $bou->can_add_templates($bool);

Accessor. If set to C<true>, allows new templates to be
defined for the class via the C<template> method.

=head2 template( $name => sub { ... } )

Defines the template C<$name>. Will trigger an exception unless
C<can_add_templates> was set to C<true> or the object was
created via C<anon_instance>.

Warnings will be issued if the template redefines an already-existing
function/method in the namespace.

=head2 anon_instance(@args_for_new)

Creates an anonymous class inheriting from the current one and builds an object instance
with the given arguments. Useful when wanting to define templates for one specific instance.

=head2 render

    $bou->render( $coderef, @template_args );
    $bou->render( $template_name, @template_args );

Renders the given C<$coderef> as a template, passing it the C<@template_args>, and returns its generated output. 

    print $bou->render( sub {
        my( $self, $name ) = @_;

        'hi ' . $name . "\n";
    }, $_ ) for @friends; 

The template can also be given by name.

    template foo => sub { ... };

    # later on

    $bou->render( 'foo', @args );

    # which is equivalent to

    $bou->foo(@args);

=head2 get_render

Like C<render>, but always return the generated template content, even
when called inside a template.

    template foo => sub { 'foo' };
    template bar => sub { 'bar' };

    print $bou->render(sub{
        my $self = shift;

        $self->foo;
        my $bar = $self->get_render(sub{ $self->bar });
        $bar =~  y/r/z/;
        say $bar;
    });

    # prints 'foobaz'

=head1 SEE ALSO

L<http://babyl.dyndns.org/techblog/entry/caribou>  - The original blog entry
introducing L<Template::Caribou>.

L<Template::Declare>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
