# Copyright (C) 2000-2002, Free Software Foundation FSF.
#
# Style-Elements
#

package PPresenter::StyleElem;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

use constant ObjDefaults =>
{ style => undef
, show  => undef
};

#
# load
#
# Recursively visits style-element definitions.  If they define a @INCLUDES
# those packages listed there are visited, and the package itself is not.
#

sub load($;@)
{   my ($class, @args) = @_;

    no strict 'refs';
    unless(defined %{"${class}::"})
    {   eval "use $class";
        die "$@\n" if $@;
    }

    my @expanded;
    no strict 'refs';

    if(defined @{"${class}::INCLUDES"})
    {   my @expanded = @{"${class}::INCLUDES"};
#       local $" = "\n    ";
#       print PPresenter::TRACE "  $class contains\n    @expanded\n";
        return map {load($_, @args)} @expanded;
    }

    print PPresenter::TRACE "  Loading $class.\n";
    $class->new(@args);
}

# Used style-elements can only be changed when the name is changed
# with it, to avoid change on previously defined slides.

sub setUsed() {shift->{users}++}
sub isUsed()
{   my $self = shift;
    defined $self->{users} && $self->{users} > 0;
}

# Copy
# Make a copy of a style element.  Per slide, the copy is made and then
# overruled by slide-specifics.  Of course, the class of the element (always
# a hash) is preserved.  Users can never (when used according to the rules)
# add fields to this hash which have no default.
#

sub copy()
{   my $self = shift;
    my $copy = bless { %$self }, ref $self;
    delete $copy->{users};
    $copy;
}

#
# Change
# User wants some settings to be changed.  But: this is dangerous, because
# in one of the previously defined slide, this style-element may already
# be used.  In that case, we add a new, changed style-element in front
# of the elements in the style.
#

sub change(@)
{   my $self    = shift;
    my $name    = $self->{-name};

    if($self->isUsed)
    {   $self = $self->copy;
        $self->{style}->add($self->{type}, $self);
    }

    while($#_ >0)
    {   my ($field, $contents) = (shift, shift);

        unless(exists $self->{$field})
        {   warn "A ",ref $self,
                 " does not contain a setting named $field.  Skipped.\n";
            next;
        }

        $self->{$field} = $contents;
    }

    return $self;
}

1;
