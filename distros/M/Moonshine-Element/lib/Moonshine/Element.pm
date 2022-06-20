package Moonshine::Element;

use strict;
use warnings;
use Ref::Util qw/is_scalarref is_arrayref is_hashref is_blessed_ref/;
use UNIVERSAL::Object;
use Data::GUID;
use Autoload::AUTOCAN;

our $VERSION = '0.12';

use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our @ISA;
BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS;

BEGIN {
    my @ATTRIBUTES =
      qw/accept accept_charset accesskey action align alt async autocomplete
      autofocus autoplay autosave bgcolor border buffered challenge charset checked cite class
      code codebase color cols colspan content contenteditable contextmenu controls coords datetime
      default defer dir dirname disabled download draggable dropzone enctype for form formaction
      headers height hidden high href hreflang http_equiv icon id integrity ismap itemprop keytype
      kind label lang language list loop low manifest max maxlength media method min multiple muted
      name novalidate open optimum pattern ping placeholder poster preload radiogroup readonly rel
      required reversed rows rowspan sandbox scope scoped seamless selected shape size sizes span
      spellcheck src srcdoc srclang srcset start step style summary tabindex target title type usemap
      value width wrap aria_autocomplete aria_atomic aria_busy aria_checked aria_controls
      aria_disabled aria_dropeffect aria_flowto aria_grabbed aria_expanded aria_haspopup aria_hidden
      aria_invalid aria_label aria_labelledby aria_live aria_level aria_multiline aria_multiselectable
      aria_orientation aria_pressed aria_readonly aria_required aria_selected aria_sort aria_valuemax
      aria_valuemin aria_valuenow aria_valuetext aria_owns aria_relevant role data_toggle data_target
      aria_describedby onkeyup onkeydown onclick onchange/;

    %HAS = (
        (
            map {
                $_ => sub { undef }
              } @ATTRIBUTES,
            qw/parent data/
        ),
        (
            map {
                $_ => sub { [] }
            } qw/children after_element before_element/
        ),
        tag            => sub { die "$_ is required" },
        attribute_list => sub { \@ATTRIBUTES },
        guid           => sub { Data::GUID->new->as_string },
    );

    for my $attr ( @ATTRIBUTES,
        qw/data tag attribute_list children after_element before_element guid parent/
      )
    {
        no strict 'refs';
        {
            *{"has_$attr"} = sub {
                my $val = $_[0]->{$attr};
                defined $val or return undef;
                is_arrayref($val) and return scalar @{$val};
                is_hashref($val) and return map { $_; }
                  sort keys %{$val};
                return 1;
              }
        };
        {
            *{"clear_$attr"} = sub { undef $_[0]->{$attr} }
        };
        {
            *{"$attr"} = sub {
                my $val = $_[0]->{$attr};
                defined $_[1] or return $val;
                is_arrayref($val) && not is_arrayref( $_[1] )
                  and return push @{$val}, $_[1];
                is_hashref($val) && is_hashref( $_[1] )
                  and map { $_[0]->{$attr}->{$_} = $_[1]->{$_} } keys %{ $_[1] }
                  and return 1;
                $_[0]->{$attr} = $_[1] and return 1;
              }
        };
    }
}

sub AUTOCAN {
    my ( $self, $meth ) = @_;
    return if $meth =~ /BUILD|DEMOLISH/;
    my $element = $self->get_element($meth, ['name']);
    return sub { $element } if $element;
    die "AUTOCAN: ${meth} cannot be found";
}

sub BUILDARGS {
    my ( $self, $args ) = @_;

    for my $ele (qw/children before_element after_element/) {
        next unless is_arrayref($args->{$ele});
        for ( 0 .. ( scalar @{ $args->{$ele} } - 1 ) ) {
            $args->{$ele}[$_] = $self->build_element( $args->{$ele}[$_] );
        }
    }
    
    if (is_arrayref($args->{data})) {
        for ( 0 .. ( scalar @{ $args->{data} } - 1 ) ) {
            next unless is_hashref($args->{data}[$_]) or is_blessed_ref($args->{data}[$_]);
            $args->{data}[$_] = $self->build_element( $args->{data}[$_] );
        }
    }

    return $args;
}

sub build_element {
    my ( $self, $build_args, $parent ) = @_;

    $build_args->{parent} = $parent // $self;
    if ( is_blessed_ref($build_args) ) {
        return $build_args if $build_args->isa('Moonshine::Element');
        die "I'm not a Moonshine::Element";
    }

    return $self->new($build_args);
}

sub add_child {
    my $action = 'children';
    if ( defined $_[2] and my $parent = $_[0]->{parent} ) {
        my $guid  = $_[0]->guid;
        my $index = 0;
        ++$index until $parent->children->[$index]->guid eq $guid;
        ++$index if $_[2] eq 'after';
        my $element = $_[0]->build_element( $_[1], $parent );
        splice @{ $parent->{children} }, $index, 0, $element;
        return $element;
    }
    elsif ( defined $_[2] ) {
        $action = sprintf "%s_element", $_[2];
    }

    my $child = $_[0]->build_element( $_[1] );
    $_[0]->$action($child);
    return $child;
}

sub insert_child {
    my $element = $_[0]->build_element( $_[2] );
    splice @{ $_[0]->{children} }, $_[1], 0, $element;
    return $element;
}

sub add_before_element {
    return $_[0]->add_child( $_[1], 'before' );
}

sub add_after_element {
    return $_[0]->add_child( $_[1], 'after' );
}

sub render {
    my $html_attributes = '';
    for my $attribute ( @{ $_[0]->attribute_list } ) {
        my $html_attribute = $attribute;
        $html_attribute =~ s/_/-/;
        my $has_action = sprintf 'has_%s', $attribute;
        if ( $_[0]->$has_action ) {
            $html_attributes .= sprintf( '%s="%s" ',
                $html_attribute,
                $_[0]->_attribute_value( $attribute, $has_action ) );
        }
    }

    my $tag            = $_[0]->tag;
    my $render_element = $_[0]->_render_element;
    my $html           = sprintf '<%s %s>%s</%s>', $tag, $html_attributes,
      $render_element, $tag;

    if ( $_[0]->has_before_element ) {
        for ( @{ $_[0]->before_element } ) {
            $html = sprintf "%s%s", $_->render, $html;
        }
    }

    if ( $_[0]->has_after_element ) {
        for ( @{ $_[0]->after_element } ) {
            $html = sprintf "%s%s", $html, $_->render;
        }
    }

    return $_[0]->_tidy_html($html);
}

sub text {
    return $_[0]->has_data ? $_[0]->_attribute_value('data') : '';
}

sub set {
    is_hashref( $_[1] ) or die "args passed to set must be a hashref";

    for my $attribute ( keys %{ $_[1] } ) {
        $_[0]->$attribute( $_[1]->{$attribute} );
    }

    return $_[0];
}

sub get_element {
    for my $ele (qw/before_element data children after_element/) {
        next unless is_arrayref($_[0]->{$ele});
        for my $e ( @{$_[0]->{$ele}} ) {
            next unless is_blessed_ref($e);
            for ( @{ $_[2] } ) {
                my $has = sprintf 'has_%s', $_;
                $e->$has and $e->_attribute_value($_, $has) =~ m/$_[1]/
                    and return $e;
            }
            my $found = $e->get_element( $_[1], $_[2] );
            return $found if $found;
        }
    }
    return undef;
}

sub get_element_by_id {
    is_scalarref(\$_[1]) or die "first param passed to get_element_by_id not a scalar";
    return $_[0]->get_element($_[1], ['id']);
}

sub get_element_by_name {
    is_scalarref(\$_[1]) or die "first param passed to get_element_by_name not a scalar";
    return $_[0]->get_element($_[1], ['name']);
}

sub get_elements {
    $_[3] //= [];
    for my $ele (qw/before_element data children after_element/) {
        next unless is_arrayref($_[0]->{$ele});
        for my $e ( @{$_[0]->{$ele}} ) {
            next unless is_blessed_ref($e);
            for ( @{ $_[2] } ) {
                my $has = sprintf 'has_%s', $_;
                $e->$has and $e->_attribute_value($_, $has) =~ m/$_[1]/
                    and push @{ $_[3] }, $e;
            }
            $e->get_elements( $_[1], $_[2], $_[3] );
        }
    }
    return $_[3];
}

sub get_elements_by_class {
    is_scalarref(\$_[1]) or die "first param passed to get_elements_by_class not a scalar";
    return $_[0]->get_elements($_[1], ['class']);
}

sub get_elements_by_tag {
    is_scalarref(\$_[1]) or die "first param passed to get_elements_by_tag not a scalar";
    return $_[0]->get_elements($_[1], ['tag']);
}

sub _render_element {
    my $element = $_[0]->text;
    if ( $_[0]->has_children ) {
        for ( @{ $_[0]->children } ) {
            $element .= $_->render;
        }
    }
    return $element;
}

sub _attribute_value {
    my ( $self, $attribute, $has_action ) = @_;

    $has_action //= sprintf( 'has_%s', $attribute );
    given ( ref $_[0]->{$attribute} ) {
        when (/HASH/) {
            my $value = '';
            map {
                $value and $value .= ' ';
                $value .= $_[0]->{$attribute}->{$_};
            } $_[0]->$has_action;
            return $value;
        }
        when (/ARRAY/) {
            my $value = '';
            for ( @{ $_[0]->{$attribute} } ) {
                $value and $value .= ' ';
                is_scalarref( \$_ ) and $value .= $_ and next;
                $value .= $self->build_element($_)->render;
                next;
            }
            return $value;
        }
        default {
            return $_[0]->{$attribute};
        }
    }
}

sub _tidy_html {
    $_[1] =~ s/\s+>/>/g;
    return $_[1];
}

1;

__END__

=head1 NAME

Moonshine::Element - Build some more html.

=head1 VERSION

Version 0.12 

=head1 DESCRIPTION

=head1 SYNOPSIS

    use Moonshine::Element;

    my $base = Moonshine::Element->new( tag => 'div' );

    my $child = $base->add_child({ tag => 'p' });
    $child->add_before_element({ tag => 'span' });
    $child->add_after_element({ tag => 'span' });
    $child->insert_child(0, { tag => "b" });
 
    $base->render
    .......

OUTPUT: <div><span></span><p><b></b></p><span></span></div>

=head1 ATTRIBUTES

=head2 Override/Set/Push

    $base->$attribute($p_tag);

=head2 Get

    $base->$attribute;
    $base->{$attribute}

=head2 Defined/Count/Keys
    
    $base->has_$attribute;

=head2 Clear

    $base->clear_$attribute;

=head2 Default attribute's

=head3 tag

html tag

=head3 data

Array, that holds the elements content, use text to join

=head3 children

elements can have children

=head3 after_element

Used when the element doesn't have a parent.

=head3 before_element

Used when the element doesn't have a parent.

=head3 attribute_list

List containing all valid attributes for the element

=head3 guid

Unique Identifier 

=head1 SUBROUTINES

=head2 add_child

Accepts a Hash reference that is used to build a new Moonshine::Element
which is pushed into that elements children attribute.

    $base->add_child(
        {
            tag => 'div'
            ....
        }
    );

=head2 add_before_element

Accepts a Hash reference that is used to build a new Moonshine::Element, if the current
element has a parent, we slice in the new element before the current. If no parent exists the new element
is pushed in the before_element attribute.

    $base->add_before_element(
        {
            tag => 'div',
            ....
        }
    );

=head2 add_after_element

Accepts a Hash reference that is used to build a new Moonshine::Element, if the current
element has a parent, we slice in the new element after the current. If no parent exists the new element
is pushed in the after_element attribute.

    $base->add_after_element(
        {
            tag => 'div',
            ....
        }
    );

=head2 get_element

Will always return the first element if one is found.

    $self->get_element('find-me', ['id', 'name']);

=head2 get_element_by_id

Accepts a id and returns a element or undef.

    my $element = $base->get_element_by_id('find-me');

=head2 get_element_by_name

Accepts a name and returns a element or undef.

    my $element = $base->get_element_by_name('findme');

or..

    $element->findme

=head2 get_elements

Returns ArrayRef of Elements.

    $self->get_elements('found', ['class']);

=head2 get_element_by_class

Accepts a Scalar returns ArrayRef of Elements.

    $self->get_elements_by_class('found');

=head2 get_elements_by_tag

Accepts a Scalar returns ArrayRef of Elements.

    $self->get_elements_by_tag('table');

=head2 render

Render the Element as html.

    $base->render;

Html attributes can be HashRef's (keys sorted and values joined), ArrayRef's(joined), or just Scalars.

=head1 AUTHOR

Robert Acock <ThisUsedToBeAnEmail@gmail.com>

=head1 CONFIGURATION AND ENVIRONMENT

=head1 INCOMPATIBILITIES

=head1 LICENSE AND COPYRIGHT
 
Copyright 2016 Robert Acock.
 
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:
 
L<http://www.perlfoundation.org/artistic_license_2_0>
 
Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.
 
If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.
 
This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
 
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.
 
Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

