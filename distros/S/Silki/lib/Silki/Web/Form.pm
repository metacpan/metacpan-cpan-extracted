package Silki::Web::Form;
{
  $Silki::Web::Form::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use HTML::DOM;

use HTML::FillInForm;
use Silki::Config;
use Silki::Web::FormData;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has 'html' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'exclude' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has '_dom' => (
    is      => 'rw',
    isa     => 'HTML::DOM',
    lazy    => 1,
    default => sub {
        my $dom = HTML::DOM->new();
        $dom->write( $_[0]->html() );
        return $dom;
    },
);

has 'errors' => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef|Str]',
    default => sub { [] },
);

has 'form_data' => (
    is      => 'ro',
    isa     => 'Silki::Web::FormData',
    default => sub { Silki::Web::FormData->new() },
);

has 'filled_in_form' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_fill_in_form',
);

has 'make_pretty' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'is_fragment' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub _fill_in_form {
    my $self = shift;

    $self->_fill_errors();

    $self->_fill_form_data();

    $self->_collapse_single_option_selects();

    my $html = $self->_form_html_from_dom();

    return $html;
}

sub _fill_errors {
    my $self = shift;

    my $errors = $self->errors();
    return unless @{$errors};

    my $error_div = $self->_dom()->createElement('div');
    $error_div->className('form-error');

    for my $error ( @{$errors} ) {
        if ( ref $error && $error->{field} ) {
            my $div = $self->_get_div_for_field( $error->{field} )
                or next;

            $div->className( $div->className() . ' error' );

            my $p = $self->_create_error_para( $error->{message} );
            $div->insertBefore( $p, $div->firstChild() );
        }
        else {
            my $p = $self->_create_error_para(
                ref $error ? $error->{message} : $error );

            $error_div->appendChild($p);
        }
    }

    my $form = $self->_dom()->getElementsByTagName('form')->[0];
    if ( @{ $error_div->childNodes() } ) {
        $form->insertBefore( $error_div, $form->firstChild() );
    }
}

sub _get_div_for_field {
    my $self = shift;
    my $id   = shift;

    my $elt = $self->_dom()->getElementById($id);

    return unless $elt;

    my $node = $elt;

    while ( $node = $node->parentNode() ) {
        return $node
            if lc $node->tagName() eq 'div'
                && $node->className() =~ /form-item/;

        last if lc $node->tagName() eq 'form';
    }
}

sub _create_error_para {
    my $self = shift;
    my $text = shift;

    # The extra span is for the benefit of CSS, so we can set the left margin
    # of the paragraph
    my $span = $self->_dom()->createElement('span');
    $span->appendChild( $self->_dom()->createTextNode($text) );

    my $p = $self->_dom()->createElement('p');
    $p->className('error-message');
    $p->appendChild($span);

    return $p;
}

sub _fill_form_data {
    my $self = shift;

    my $data = $self->form_data();
    return unless $data->has_sources();

    my $html = $self->_form_html_from_dom();

    my $filled = HTML::FillInForm->fill(
        \$html, $data,
        ignore_fields => $self->exclude()
    );

    my $dom = HTML::DOM->new();
    $dom->write($filled);

    $self->_set_dom($dom);
}

sub _collapse_single_option_selects {
    my $self = shift;

    my @to_collapse;
    for my $select ( @{ $self->_dom()->getElementsByTagName('select') } ) {
        next if $select->id() =~ /^wpms-/;

        my @options = $select->options();

        next if @options != 1;

        push @to_collapse, [ $select, $options[0] ];
    }

    # Modifying the dom as we loop through it seems to cause weirdness
    # where some select elements get skipped.
    $self->_collapse_single_option_select( @{$_} ) for @to_collapse;
}

sub _collapse_single_option_select {
    my $self   = shift;
    my $select = shift;
    my $option = shift;

    my $div = $self->_dom()->createElement('div');
    $div->className('text-for-hidden');
    $div->appendChild($_) for @{ $option->childNodes() };

    my $hidden = $self->_dom()->createElement('input');
    $hidden->setAttribute( type  => 'hidden' );
    $hidden->setAttribute( name  => $select->getAttribute('name') );
    $hidden->setAttribute( value => $option->getAttribute('value') );

    my $parent = $select->parentNode();

    $parent->replaceChild( $div, $select );
    $parent->appendChild($hidden);
}

sub _form_html_from_dom {
    my $self = shift;

    return $self->_dom()->documentElement()->as_HTML( undef, q{}, {} )
        if $self->is_fragment();

    my $form = $self->_dom()->getElementsByTagName('form')->[0];

    return $form->as_HTML( undef, q{}, {} );
}

# This bizarro bit seems to fix some tests. Sigh ...
{
    package
        HTML::DOM::Node;

    no warnings 'redefine';

    sub as_HTML {
        ( my $clone = shift->clone )->deobjectify_text;
        $clone->SUPER::as_HTML(@_);
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Does post-processing on HTML forms

__END__
=pod

=head1 NAME

Silki::Web::Form - Does post-processing on HTML forms

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

