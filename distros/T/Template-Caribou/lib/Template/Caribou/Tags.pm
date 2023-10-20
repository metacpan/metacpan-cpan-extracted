package Template::Caribou::Tags;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: generates tags functions for Caribou templates
$Template::Caribou::Tags::VERSION = '1.2.2';
use strict;
use warnings;

use Carp;

use Template::Caribou::Role;

use List::AllUtils qw/ pairmap pairgrep /;
use Ref::Util qw/ is_plain_hashref /;

use parent 'Exporter::Tiny';
use experimental 'signatures', 'postderef';
use XML::Writer;

our @EXPORT_OK = qw/ render_tag mytag attr /;


sub attr(@args){
    return $_{$args[0]} if @args == 1;

    croak "number of attributes must be even" if @args % 2;

    no warnings 'uninitialized';
    while( my ( $k, $v ) = splice @args, 0, 2 ) {
        if ( $k =~ s/^\+// ) {
            $_{$k} = { map { $_ => 1 } split ' ', $_{$k} }
                unless ref $_{$k};

            $_{$k}{$v} = 1;
        }
        elsif ( $k =~ s/^-// ) {
            $_{$k} = { map { $_ => 1 } split ' ', $_{$k} }
                unless ref $_{$k};

            delete $_{$k}{$v};
        }
        else {
            $_{$k} = $v;
        }
    }

    return;
}


sub _generate_mytag {
    my ( undef, undef, $arg ) = @_;

    $arg->{'-as'} ||= $arg->{tag}
        or die "mytag needs to be given '-as' or 'name'\n";

    my $tagname = $arg->{tag} || 'div';

    my $groom = sub {
        
        no warnings 'uninitialized';

        if( my $defaults = $arg->{classes} || $arg->{class} ) {
            $_{class} = { map { $_ => 1 } split ' ', $_{class} }
                unless ref $_{class};
            if( ref $defaults ) {
                $_{class}{$_} //= 1 for @$defaults;
            }
            else {
                $_{class}{$_} //=  1 for split ' ', $defaults;
            }
        }

        $_{$_} ||= $arg->{attr}{$_} for eval { keys %{ $arg->{attr} } };

        $arg->{groom}->() if $arg->{groom};
    };

    return sub :prototype(&) {
        my $inner = shift;
        render_tag( $tagname, $inner, $groom, $arg->{indent}//1 );
    }
}


sub render_tag {
    my ( $tag, $inner_sub, $groom, $indent ) = @_;

    $indent //= 1;

    local $Template::Caribou::TAG_INDENT_LEVEL = $indent ? $Template::Caribou::TAG_INDENT_LEVEL : 0;

    my $sub = ref $inner_sub eq 'CODE' ? $inner_sub : sub { $inner_sub };

    # need to use the object for calls to 'show'
    my $bou = $Template::Caribou::TEMPLATE || Moose::Meta::Class->create_anon_class(
        roles => [ 'Template::Caribou::Role' ]
    )->new_object;

    local %_;

    my $inner = do {
        local $Template::Caribou::TAG_INDENT_LEVEL = $Template::Caribou::TAG_INDENT_LEVEL;

        $Template::Caribou::TAG_INDENT_LEVEL++
            if $Template::Caribou::TAG_INDENT_LEVEL // $bou->indent;

        $bou->get_render($sub);
    };

    if ( $groom ) {
        local $_ = "$inner";  # stringification required in case it's an object

        $groom->();

        $inner = $_;
    }

    # Setting UNSAFE here so that the inner can be written with raw
    # as we don't want inner to be escaped as it is already escaped
    my $writer = XML::Writer->new(OUTPUT => 'self', UNSAFE => 1);
    my @attributes = pairmap { (  $a => $b ) x (length $b > 0) }
        map { 
            $_ => is_plain_hashref($_{$_})
                ? join ' ', sort { $a cmp $b } pairmap { $a } pairgrep { $b } $_{$_}->%* 
                : $_{$_} 
        }
       grep { defined $_{$_} }
       sort keys %_;

    no warnings qw/ uninitialized /;

    my $prefix = !!$Template::Caribou::TAG_INDENT_LEVEL
        && "\n" . ( '  ' x $Template::Caribou::TAG_INDENT_LEVEL );

    if (length($inner)) {
        $writer->startTag($tag, @attributes);
        $writer->raw("$inner$prefix");
        $writer->endTag($tag);
    }
    else {
        $writer->emptyTag($tag, @attributes);
    }

    my $output = Template::Caribou::String->new( $prefix . $writer->to_string() );

    return print_raw( $output );
}

sub print_raw($text) {
    print ::RAW $text;
    return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Caribou::Tags - generates tags functions for Caribou templates

=head1 VERSION

version 1.2.2

=head1 SYNOPSIS

    package MyTemplate;

    use Template::Caribou;

    use Template::Caribou::Tags
        mytag => { 
            -as   => 'foo',
            tag   => 'p',
            class => 'baz'
        };

    template bar => sub {
        foo { 'hello' };
    };

    # <p class="baz">hello</p>
    print __PACKAGE__->new->bar;

=head1 DESCRIPTION

This module provides the tools to create tag libraries, or ad-hoc tags.

For pre-defined sets of tags, you may want to look at L<Template::Caribou::Tags::HTML>,
L<Template::Caribou::Tags::HTML::Extended>, and friends.

=head2 Core functionality

Tag functions are created using the C<render_tag> function. For example:

    package MyTemplate;

    use Template::Caribou;

    use Template::Caribou::Tags qw/ render_tag /;

    sub foo(&) { render_tag( 'foo', shift ) }

    # renders as '<foo>hi!</foo>'
    template main => sub {
        foo { "hi!" };
    };   

=head2 Creating ad-hoc tags

Defining a function and using C<render_tag> is a little bulky and, typically, will only be used when creating
tag libraries. In most cases, 
the C<my_tag> export keyword can be used to create custom tags. For example, the
previous C<foo> definition could have been done this way:

    package MyTemplate;

    use Template::Caribou;

    use Template::Caribou::Tags
        mytag => { tag => 'foo' };

    # renders as '<foo>hi!</foo>'
    template main => sub {
        foo { 
            "hi!";
        };
    };   

=head1 EXPORTS

By default, nothing is exported.
The functions C<render_tag> and C<attr> can be exported by this module. 

Custom tag functions can also be defined via the export keyword C<mytag>.

C<mytag> accepts the following arguments:

=over

=item tag => $name

Tagname that will be used. If not specified, defaults to C<div>.

=item -as => $name

Name under which the tag function will be exported. If not specified, defaults to the 
value of the C<tag> argument. At least one of C<-as> or C<tag> must be given explicitly.

=item groom => sub { }

Grooming function for the tag block. See C<render_tag> for more details.

=item classes => \@classes

Default value for the 'class' attribute of the tag. 

    use Template::Caribou::Tags 
                    # <div class="main">...</div>
        mytag => { -as => 'main_div', classes => [ 'main' ] };

If you want to remove a default class from the tag,
set its value to C<0> in C<%_>. E.g.,

    main_div { $_{class}{main} = 0; ... };

=item attr => \%attributes

Default set of attributes for the tag.

    use Template::Caribou::Tags 
                    # <input disabled="disabled">...</input>
        mytag => { -as => 'disabled_input', tag => 'input', attr => { disabled => 'disabled' } };

=back

=function attr( $name => $value )

I recommend you use C<%_> directly instead.

Accesses the attributes of a tag within its block.

If provided an even number of parameters, sets the attributes to those values.

    div {
        attr class => 'foo', 
             style => 'text-align: center';

        "hi there";
    };

    # <div class="foo" style="text-align: center">hi there</div>

Many calls to C<attr> can be done within the same block.

    div {
        attr class => 'foo';
        attr style => 'text-align: center';

        "hi there";
    };

    # <div class="foo" style="text-align: center">hi there</div>

To add/remove to an attribute instead of replacing its value, prefix the attribute name
with a plus or minus sign. Doing either will automatically 
turn the value in C<%_> to a hashref.

    div {
        attr class    => 'foo baz';

        attr '+class' => 'bar';
        attr '-class' => 'baz';

        "hi there";
    };

    # <div class="foo bar">hi there</div>

The value of an attribute can also be queried by passing a single argument to C<attr>.

    div { 
        ...; # some complex stuff here

        my $class = attr 'class';

        attr '+style' => 'text-align: center' if $class =~ /_centered/;

        ...;
    }

=function render_tag( $tag_name, $inner_block, \&groom, $indent )

Prints out a tag in a template. The C<$inner_block> is a string or coderef
holding the content of the tag. 

If the C<$inner_block> is empty, the tag will be of the form
C<< <foo /> >>.

    render_tag( 'div', 'hello' );         #  <div>hello</div>

    render_tag( 'div', sub { 'hello' } )  # <div>hello</div>

    render_tag( 'div', '' );              #  <div />

An optional grooming function can be passed. If it is, an hash holding the 
attributes of the tag, and its inner content will be passed to it as C<%_> and C<$_>, respectively.

   # '<div>the current time is Wed Nov 25 13:18:33 2015</div>'
   render_tag( 'div', 'the current time is DATETIME', sub {
        s/DATETIME/scalar localtime/eg;
   });

   # '<div class="mine">foo</div>'
   render_tag( 'div', 'foo', sub { $_{class} = 'mine' } )

An optional C<$indent> argument can also be given. If explicitly set to
C<false>, the tag won't be indented even when the template
is in pretty-print mode. Used for tags where whitespaces
are significant or would alter
the presentation (e.g., C<pre> or C<emphasis>). Defaults to C<true>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
