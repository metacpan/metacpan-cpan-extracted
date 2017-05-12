# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Style;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

my @style_elements = qw(template fontset dynamic decoration formatter);
sub objtype($;) {ucfirst $_[0]}

use constant ObjDefaults =>
{ type         => 'style'

, -templates   => [ 'PPresenter::Template::Default' ]
, -fontsets    => [ 'PPresenter::Fontset::TkFonts'
                  , 'PPresenter::Fontset::XScaling' ]
, -dynamics    => [ 'PPresenter::Dynamic::Default'  ]
, -formatters  => [ 'PPresenter::Formatter::Plain'
                  , 'PPresenter::Formatter::Simple'
                  , 'PPresenter::Formatter::Markup' ]
, -decorations => [ 'PPresenter::Decoration::Solid'
                  , 'PPresenter::Decoration::Lines1' ]
};

sub InitObject()
{   my $style = shift;

    print PPresenter::TRACE "Creating style $style.\n";
    $style->SUPER::InitObject;

    # Get all the modules.

    foreach (@style_elements)
    {   my $type   = objtype($_);
        my $list   = "-${_}s";
        my $show   = $style->{show};

        no strict 'refs';
        my @loaded
           = map {PPresenter::StyleElem::load($_, style=>$style, show=>$show)}
                        @{$style->{$list}};
        $style->{$list} = \@loaded;
    }

    # Select all firsts as starting defaults.
    # In the initiation of derived classes, you can select other defaults.

    map {$style->select($_, 'FIRST')} @style_elements;

    print PPresenter::TRACE "Initialized style $style.\n";
}

#
# About style-elements, in general.
# Only the four functions below may be called from other modules: all
# other may change in later versions of this package.
#

sub find($;$)
{   my ($style, $type, $name) = @_;

    $name = 'SELECTED' unless defined $name;

    unless(grep {$type eq $_} @style_elements)
    {   warn "Cannot find unknown style-type $type for style $style.\n";
        return undef;
    }

    return $style->{selected}{$type}
       if $name eq 'SELECTED';

    return PPresenter::Template->fromList($style->{-templates}, $name)
       if $type eq 'template';

    return PPresenter::Fontset->fromList($style->{-fontsets}, $name)
       if $type eq 'fontset';

    return PPresenter::Dynamic->fromList($style->{-dynamics}, $name)
       if $type eq 'dynamic';

    return PPresenter::Decoration->fromList($style->{-decorations}, $name)
       if $type eq 'decoration';

    return PPresenter::Formatter->fromList($style->{-formatters}, $name)
       if $type eq 'formatter';

    die "Unknown style-element $type.\n"
}

sub add($$)
{   my ($style, $type, $element) = @_;

    return $style->{show}->addStyle($element)
       if $type eq 'style';

    unless(grep {$type eq $_} @style_elements)
    {   warn "Cannot add unknown style-type $type to style $style.\n";
        return $style;
    }

    my $list    = "-${type}s";
    my $objtype = objtype($type);

    unless($element->isa("PPresenter::$objtype"))
    {   warn "Cannot add $element as a $objtype in style $style.\n";
        return $style;
    }

    unshift @{$style->{$list}}, $element;
    print PPresenter::TRACE "Added $type $element.\n";

    return $style;
}

# The change-function on a style is a bit different, because it can be
# used to change its style-elements too, not only the overal style settings.
sub change($$@)
{   my ($style, $type, $element) = (shift,shift,shift);

    return $style unless defined $type;

    unless(grep {$type eq $_} @style_elements)
    {   # Change style's options itself, hence not $type=>$elem
        return $style->SUPER::change($type,$element,@_);
    }

    if($element eq 'ALL')
    {   map {$_->change(@_)} @{$style->{"-${type}s"}};
        return $style;
    }
        
    # When a scalar is presented, that must be the name of an existing
    # element.
    if(ref $element eq '')
    {   $style->find($type, $element)->change(@_);
        return $style;
    }

    $element->change(@_);
    $style;
}

sub select($$)
{   my ($style, $type, $name) = @_;

    unless(grep {$type eq $_} @style_elements)
    {  warn "Cannot select unknown style-type $type to style $style.\n";
       return;
    }

    my $found = $style->find($type, $name);

    unless(defined $found)
    {   warn "Could not find $type $name in style $style.\n";
        return 0
    }

    $style->{selected}{$type} = $found;

    return $found;
}

# When a new slide is produced, the selected style-elements are copied
# to it and merged with the slide specified data.

sub get_slide_pref($$;)
{   my ($style, $slide, $type) = @_;

    my $selected = $style->find($type, 'SELECTED');

    if(defined $slide->{"-$type"})
    {   # User specified non-default style element.
        my $elem = $style->find($type, $slide->{"-$type"});

        $slide->{$type} = $elem->copy
            if defined $elem;

        warn <<WARN unless defined $elem;
Cannot find $type "$slide->{"-$type"}", so try to continue by falling
   back on the default $type, being "$selected".
WARN

        # user's spec not needed anymore.
        delete $slide->{"-$type"};
    }

    # Copy defs of selected slide when user didn't specify one.
    $slide->{$type} =  $selected->copy
        unless defined $slide->{$type};

    return $style;
}

#
# Collecting style elements.
#

sub styleFlags($)
{   my $options = shift;
    my %flags;

    foreach (@style_elements, 'style')
    {   $flags{$_} = $options->{"-$_"}
            if defined $options->{"-$_"};
    }

    return \%flags;
}

sub styleElems($)
{   my ($style, $slide, $flags) = @_;
    my %elems;

    foreach (keys %{$style->{selected}})
    {   my $elem = exists $flags->{$_}
                 ? $style->find($_ => $flags->{$_})
                 : $style->{selected}{$_};

        die "Slide $slide: Cannot find $_ $flags->{$_}.\n"
            unless defined $elem;

        $elem->setUsed;
        $elems{$_} = $elem;
    }

    \%elems;
}

sub collectSlidePrefs($)
{   my ($style, $slide) = @_;

    # Collect a copy of the selected elements.
    map {$style->get_slide_pref($slide, $_)} @style_elements;

    # Merge-in user's specifications if they overrule parts of this
    # style element.

    foreach my $flag (keys %$slide)
    {   next    unless $flag =~ /^-/;    # user options start with dash.
        my $flag_used = 0;

        foreach (@style_elements)
        {   next unless exists $slide->{$_}{$flag};
            $slide->{$_}{$flag} = $slide->{$flag};
            $flag_used++;
        }

        warn "Flag $flag is not usable for slide \"$slide\"; removed.\n"
            unless $flag_used;

        delete $slide->{$flag};
    }

    return $style;
}

1;
