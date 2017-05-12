##
##  String::Divert - String Object supporting Folding and Diversion
##  Copyright (c) 2003-2005 Ralf S. Engelschall <rse@engelschall.com>
##
##  This file is part of String::Divert, a Perl module providing
##  a string object supporting folding and diversion.
##
##  This program is free software; you can redistribute it and/or
##  modify it under the terms of the GNU General Public  License
##  as published by the Free Software Foundation; either version
##  2.0 of the License, or (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this file; if not, write to the Free Software Foundation,
##  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
##
##  Divert.pm: Module Implementation
##

#   _________________________________________________________________________
#
#   STANDARD OBJECT ORIENTED API
#   _________________________________________________________________________
#

package String::Divert;

use 5.006;
use strict;
use warnings;

use Carp;
require Exporter;

our $VERSION   = '0.96';

our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw();

#   internal: create an anonymous object name
my $_anonymous_count = 1;
sub _anonymous_name () {
    return sprintf("ANONYMOUS:%d", $_anonymous_count++);
}

#   object construction
sub new ($;$) {
    my ($proto, $name) = @_;

    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);

    $name ||= &String::Divert::_anonymous_name();

    $self->{name}      = $name;                             # name of object
    $self->{overwrite} = 'none';                            # overwrite mode (none|once|always)
    $self->{storage}   = 'all';                             # storage mode (none|fold|all)
    $self->{copying}   = 'pass';                            # copying mode (pass|clone)
    $self->{chunks}    = [];                                # string chunks
    $self->{diversion} = [];                                # stack of active diversions
    $self->{foldermk}  = '{#%s#}';                          # folder text representation format
    $self->{folderre}  = '\{#([a-zA-Z_][a-zA-Z0-9_]*)#\}';  # folder text representation regexp
    $self->{folderlst} = undef;                             # folder object of last folding operation

    return $self;
}

#   object destruction (explicit)
sub destroy ($) {
    $_[0]->overload(0);
    bless $_[0], 'UNIVERSAL';
    undef $_[0];
    return;
}

#   object destruction (implicit)
sub DESTROY ($) {
    $_[0]->overload(0);
    bless $_[0], 'UNIVERSAL';
    return;
}

#   clone object
sub clone ($) {
    my ($self) = @_;
    my $ov = $self->overload();
    $self->overload(0);
    eval { require Storable; };
    croak "required module \"Storable\" not installed" if ($@);
    my $clone = Storable::dclone($self);
    $self->overload($ov);
    $clone->overload($ov);
    return $clone;
}

#   operation: set/get name of object
sub name ($;$) {
    my ($self, $name) = @_;
    return $self->{diversion}->[-1]->name($name)
        if (@{$self->{diversion}} > 0);
    my $old_name = $self->{name};
    if (defined($name)) {
        $self->{name} = $name;
    }
    return $old_name;
}

#   operation: set/get overwrite mode
sub overwrite ($;$) {
    my ($self, $mode) = @_;
    return $self->{diversion}->[-1]->overwrite($mode)
        if (@{$self->{diversion}} > 0);
    my $old_mode = $self->{overwrite};
    if (defined($mode)) {
        croak "invalid overwrite mode argument"
            if ($mode !~ m/^(none|once|always)$/);
        $self->{overwrite} = $mode;
    }
    return $old_mode;
}

#   operation: set/get storage mode
sub storage ($;$) {
    my ($self, $mode) = @_;
    return $self->{diversion}->[-1]->storage($mode)
        if (@{$self->{diversion}} > 0);
    my $old_mode = $self->{storage};
    if (defined($mode)) {
        croak "invalid storage mode argument"
            if ($mode !~ m/^(none|fold|all)$/);
        $self->{storage} = $mode;
    }
    return $old_mode;
}

#   operation: set/get copy constructor mode
sub copying ($;$) {
    my ($self, $mode) = @_;
    return $self->{diversion}->[-1]->copying($mode)
        if (@{$self->{diversion}} > 0);
    my $old_mode = $self->{copying};
    if (defined($mode)) {
        croak "invalid copying mode argument"
            if ($mode !~ m/^(clone|pass)$/);
        $self->{copying} = $mode;
    }
    return $old_mode;
}

#   internal: split string into chunks
sub _chunking ($$) {
    my ($self, $string) = @_;
    my @chunks = ();
    my $folderre = $self->{folderre};
    while ($string =~ m/${folderre}()/s) {
        my ($prolog, $id) = ($`, $1);
        push(@chunks, $prolog) if ($prolog ne '' and $self->{storage} !~ m/^(none|fold)/);
        croak "empty folding object name"
            if ($id eq '');
        if ($self->{storage} ne 'none') {
            my $object = $self->folding($id);
            $object = $self->new($id) if (not defined($object));
            croak "cannot create new folding sub object \"$id\""
                if (not defined($object));
            push(@chunks, $object);
        }
        $string = $';
    }
    push(@chunks, $string) if ($string ne '' and $self->{storage} !~ m/^(none|fold)/);
    return @chunks;
}

#   operation: assign an object
sub assign ($$) {
    my ($self, $obj) = @_;
    return $self->{diversion}->[-1]->assign($obj)
        if (@{$self->{diversion}} > 0);
    croak "cannot assign undefined object"
        if (not defined($obj));
    if (&String::Divert::_isobj($obj)) {
        $self->{chunks} = [ $obj ];
        $self->{folderlst} = $obj if (ref($obj));
    }
    else {
        $self->{chunks} = [];
        foreach my $chunk ($self->_chunking($obj)) {
            push(@{$self->{chunks}}, $chunk);
            $self->{folderlst} = $chunk if (ref($chunk));
        }
    }
    return $self;
}

#   operation: append an object
sub append ($$) {
    my ($self, $obj) = @_;
    return $self->{diversion}->[-1]->append($obj)
        if (@{$self->{diversion}} > 0);
    croak "cannot append undefined object"
        if (not defined($obj));
    if (   $self->{overwrite} eq 'once'
        or $self->{overwrite} eq 'always') {
        $self->assign($obj);
        $self->{overwrite} = 'none'
            if ($self->{overwrite} eq 'once');
    }
    else {
        if (&String::Divert::_isobj($obj)) {
            push(@{$self->{chunks}}, $obj);
            $self->{folderlst} = $obj if (ref($obj));
        }
        else {
            foreach my $chunk ($self->_chunking($obj)) {
                if (ref($chunk) or (@{$self->{chunks}} > 0 and ref($self->{chunks}->[-1]))) {
                    push(@{$self->{chunks}}, $chunk);
                    $self->{folderlst} = $chunk if (ref($chunk));
                }
                elsif (@{$self->{chunks}} > 0) {
                    $self->{chunks}->[-1] .= $chunk;
                }
                else {
                    $self->{chunks} = [ $chunk ];
                }
            }
        }
    }
    return $self;
}

#   operation: unfold (and return) string contents temporarily
sub string ($) {
    my ($self) = @_;
    return $self->{diversion}->[-1]->string()
        if (@{$self->{diversion}} > 0);
    return $self->_string([]);
}

#   internal: string() operation with loop detection
sub _string ($$) {
    my ($self, $visit) = @_;
    my $string = '';
    if (grep { &String::Divert::_isobjeq($_, $self) } @{$visit}) {
        croak "folding loop detected: " .
            join(" -> ", map { $_->name() } @{$visit}) . 
            " -> " . $self->name();
    }
    push(@{$visit}, $self);
    foreach my $chunk (@{$self->{chunks}}) {
        if (ref($chunk)) {
            #   folding loop detection
            my $prefix = '';
            #   check for existing prefix
            #   (keep in mind that m|([^\n]+)$|s _DOES NOT_
            #   take a possibly existing terminating newline
            #   into account, so we really need an extra match!)
            if ($string =~ m|([^\n]+)$|s and $string !~ m|\n$|s) {
                $prefix = $1;
                $prefix =~ s|[^ \t]| |sg;
            }
            my $block = $chunk->_string($visit); # recursion!
            $block =~ s|\n(?=.)|\n$prefix|sg if ($prefix ne '');
            $string .= $block;
        }
        else {
            $string .= $chunk;
        }
    }
    pop(@{$visit});
    return $string;
}

#   operation: unfold string contents temporarily until already true or finally false
sub bool ($) {
    my ($self) = @_;
    return $self->{diversion}->[-1]->bool()
        if (@{$self->{diversion}} > 0);
    my $string = '';
    foreach my $chunk (@{$self->{chunks}}) {
        if (ref($chunk)) {
            $string .= $chunk->string(); # recursion!
        }
        else {
            $string .= $chunk;
        }
        return 1 if ($string);
    }
    return 0;
}

#   operation: append folding sub-object
sub fold ($;$) {
    my ($self, $id) = @_;
    return $self->{diversion}->[-1]->fold($id)
        if (@{$self->{diversion}} > 0);
    return undef if ($self->{storage} eq 'none');
    $id = &String::Divert::_anonymous_name()
        if (not defined($id));
    if (ref($id)) {
        croak "folding object not of class String::Divert"
            if (not &String::Divert::_isobj($id));
        push(@{$self->{chunks}}, $id);
        $self->{folderlst} = $id;
        return $id;
    }
    else {
        my $object = $self->folding($id);
        $object = $self->new($id) if (not defined($object));
        croak "unable to create new folding object"
            if (not defined($object));
        push(@{$self->{chunks}}, $object);
        $self->{folderlst} = $object;
        return $object;
    }
}

#   operation: unfold string contents permanently
sub unfold ($) {
    my ($self) = @_;
    return $self->{diversion}->[-1]->unfold()
        if (@{$self->{diversion}} > 0);
    my $string = $self->string();
    $self->{chunks} = $string ne '' ? [ $string ] : [];
    $self->{folderlst} = undef;
    return $string;
}

#   internal: check whether object is a String::Divert object
sub _isobj ($) {
    my ($obj) = @_;
    return (    ref($obj)
            and (   UNIVERSAL::isa($obj, "String::Divert")
                 or UNIVERSAL::isa($obj, "String::Divert::__OVERLOAD__")));
}

#   internal: compare whether two objects are the same
sub _isobjeq ($$) {
    my ($obj1, $obj2) = @_;
    my $ov1 = $obj1->overload();
    my $ov2 = $obj2->overload();
    $obj1->overload(0);
    $obj2->overload(0);
    my $rv = ($obj1 == $obj2);
    $obj1->overload($ov1);
    $obj2->overload($ov2);
    return $rv;
}

#   operation: lookup particular or all folding sub-object(s)
sub folding ($;$) {
    my ($self, $id) = @_;
    if (defined($id)) {
        my $folding; $folding = undef;
        foreach my $chunk (@{$self->{chunks}}) {
            if (ref($chunk)) {
                if (   (ref($id)     and &String::Divert::_isobjeq($chunk, $id))
                    or (not ref($id) and $chunk->name() eq $id) ) {
                    $folding = $chunk;
                    last;
                }
                $folding = $chunk->folding($id); # recursion!
                last if (defined($folding));
            }
        }
        return $folding;
    }
    else {
        my @foldings = ();
        foreach my $chunk (@{$self->{chunks}}) {
            if (ref($chunk)) {
                foreach my $subchunk ($chunk->folding()) {
                    push(@foldings, $subchunk);
                }
                push(@foldings, $chunk);
            }
        }
        return @foldings;
    }
}

#   operation: configure or generate textually represented folding object
sub folder ($;$$) {
    my ($self, $a, $b) = @_;
    if (defined($a) and defined($b)) {
        #   configure folder
        my $test = sprintf($a, "foo");
        my ($id) = ($test =~ m|${b}()|s);
        croak "folder construction format and matching regular expression do not correspond"
            if (not defined($id) or (defined($id) and $id ne "foo"));
        $self->{foldermk} = $a;
        $self->{folderre} = $b;
        return;
    }
    else {
        #   create folder
        return "" if ($self->{storage} eq 'none');
        $a = &String::Divert::_anonymous_name()
            if (not defined($a));
        my $folder = sprintf($self->{foldermk}, $a);
        return $folder;
    }
}

#   operation: push diversion of operations to sub-object
sub divert ($;$) {
    my ($self, $id) = @_;
    my $object; $object = undef;
    if (not defined($id)) {
        #   choose last folding object
        foreach my $obj (reverse ($self, @{$self->{diversion}})) {
            $object = $obj->{folderlst};
            last if (defined($object));
        }
        croak "no last folding sub-object found"
            if (not defined($object));
    }
    else {
        #   choose named folding object
        $object = $self->folding($id);
        croak "folding sub-object \"$id\" not found"
            if (not defined($object));
    }
    push(@{$self->{diversion}}, $object);
    return $self;
}

#   operation: pop diversion of operations to sub-object
sub undivert ($;$) {
    my ($self, $num) = @_;
    $num = 1 if (not defined($num));
    if ($num !~ m|^\d+$|) {
        #   lookup number by name
        my $name = $num;
        for (my $num = 1; $num <= @{$self->{diversion}}; $num++) {
            last if ($self->{diversion}->[-$num]->{name} eq $name);
        }
        croak "no object named \"$name\" found for undiversion"
            if ($num > @{$self->{diversion}});
    }
    $num = @{$self->{diversion}} if ($num == 0);
    croak "less number (".scalar(@{$self->{diversion}}).") of " .
        "diversions active than requested ($num) to undivert"
        if ($num > @{$self->{diversion}});
    while ($num-- > 0) {
        pop(@{$self->{diversion}});
    }
    return $self;
}

#   operation: lookup last or all diversion(s)
sub diversion ($) {
    my ($self) = @_;
    if (not wantarray) {
        #   return last diversion only (or undef if none exist)
        return $self->{diversion}->[-1];
    }
    else {
        #   return all diversions (in reverse order of activation) (or empty array if none exist)
        return reverse(@{$self->{diversion}});
    }
}

#   _________________________________________________________________________
#
#   API SWITCHING
#   _________________________________________________________________________
#

#   object overloading toogle method
sub overload ($;$) {
    #   NOTICE: This function is special in that it exploits the fact
    #   that Perl's @_ contains just ALIASES for the arguments of
    #   the function and hence the function can adjust them. This
    #   allows us to tie() the variable of our object ($_[0]) into the
    #   overloading sub class or back to our main class. Just tie()ing
    #   a copy of $_[0] (usually named $self in the other methods)
    #   would be useless, because the Perl TIE mechanism is attached to
    #   _variables_ and not to the objects itself. Hence this function
    #   does no "my ($self, $mode) = @_;" and instead uses @_ directly
    #   throughout its body.
    my $old_mode = (ref($_[0]) eq "String::Divert" ? 0 : 1);
    if (defined($_[1])) {
        if ($_[1]) {
            #   bless and tie into overloaded subclass
            my $self = $_[0];
            bless $_[0], "String::Divert::__OVERLOAD__";
            #tie   $_[0], "String::Divert::__OVERLOAD__", $self;
            #   according to "BUGS" section in "perldoc overload":
            #   "Relation between overloading and tie()ing is broken.
            #   Overloading is triggered or not basing on the previous
            #   class of tie()d value. This happens because the presence
            #   of overloading is checked too early, before any tie()d
            #   access is attempted. If the FETCH()ed class of the
            #   tie()d value does not change, a simple workaround is to
            #   access the value immediately after tie()ing, so that
            #   after this call the previous class coincides with the
            #   current one."... So, do this now!
            #my $dummy = ref($_[0]);
        }
        else {
            #   untie and rebless into master class
            #untie $_[0];
            bless $_[0], "String::Divert";
        }
    }
    return $old_mode;
}

#   _________________________________________________________________________
#
#   OPERATOR OVERLOADING API
#   _________________________________________________________________________
#

package String::Divert::__OVERLOAD__;

our @ISA       = qw(Exporter String::Divert);
our @EXPORT    = qw();
our @EXPORT_OK = qw();

#   define operator overloading
use overload (
     '""'       => \&op_string,
     'bool'     => \&op_bool,
     '0+'       => \&op_numeric,
     '.'        => \&op_concat,
     '.='       => \&op_append,
     '*='       => \&op_fold,
     '<>'       => \&op_unfold,
     '>>'       => \&op_divert,
     '<<'       => \&op_undivert,
     '='        => \&op_copyconst,
    #'${}'      => \&op_deref_string,
    #'%{}'      => \&op_deref_hash,
    #'nomethod' => \&op_unknown,
     'fallback' => 0
);

#sub TIESCALAR ($$) {
#    my ($class, $self) = @_;
#    bless $self, $class;
#    return $self;
#}

#sub UNTIE ($) {
#    my ($self) = @_;
#    return;
#}

#sub FETCH ($) {
#    my ($self) = @_;
#    return $self;
#}

#sub STORE ($$) {
#    my ($self, $other) = @_;
#    return $self if (ref($other));
#    $self->assign($other);
#    my $dummy = ref($self);
#    return $self;
#}

#sub op_deref_string ($$$) {
#    my $self = shift;
#    return $self;
#}

#sub op_deref_hash ($$$) {
#    my $self = shift;
#    return $self;
#}

sub op_copyconst {
    my ($self, $other, $reverse) = @_;
    if ($self->{copying} eq 'pass') {
        #   object is just passed-through
        return $self;
    }
    else { 
        #   object is recursively cloned
        return $self->clone();
    }
}

sub op_string ($$$) {
    my ($self, $other, $rev) = @_;
    return $self->string();
}

sub op_bool ($$$) {
    my ($self, $other, $reverse) = @_;
    return $self->bool();
}

sub op_numeric ($$$) {
    my ($self, $other, $reverse) = @_;
    return $self->string();
}

sub op_concat ($$$) {
    my ($self, $other, $reverse) = @_;
    return ($reverse ? $other . $self->string() : $self->string() . $other);
}

sub op_append ($$$) {
    my ($self, $other, $reverse) = @_;
    $self->append($other);
    return $self;
}

sub op_fold ($$$) {
    my ($self, $other, $reverse) = @_;
    $self->fold($other);
    return $self;
}

sub op_unfold ($$$) {
    my ($self, $other, $reverse) = @_;
    $self->unfold;
    return $self;
}

#sub op_folding ($$$) {
#    my ($self, $other, $reverse) = @_;
#    $self->folding($other);
#    return $self;
#}

sub op_divert ($$$) {
    my ($self, $other, $reverse) = @_;
    $self->divert($other);
    return $self;
}

sub op_undivert ($$$) {
    my ($self, $other, $reverse) = @_;
    $self->undivert($other);
    return $self;
}

#sub op_diversion ($$$) {
#    my ($self, $other, $reverse) = @_;
#    $self->diversion();
#    return $self;
#}

#sub op_unknown ($$$$) {
#    my ($self, $other, $rev, $op) = @_;
#    print "<op_unknown>: op=$op\n";
#    return $self;
#}

1;

