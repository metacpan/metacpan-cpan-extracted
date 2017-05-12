use strict;

=head1 NAME

Rubyish::Object - the parent class of all classes in Rubyish

=head1 DESCRIPTION

This implements the "Object" class in ruby.

Baiscally if you are defining a Rubyish class, you should not use this
class as the base class, but just say C<use Rubyish;> in your code.
This is almost all for the internals of Rubyish Perl.

=cut

package Rubyish::Object;
use feature qw(switch);

use UNIVERSAL::isa;
use Scalar::Util qw(refaddr);
use Rubyish::Syntax::def;
use Rubyish::Kernel;

=head1 FUNCTIONS

=head2 new()

The default constructor for all sub-classes.

=cut

sub new {
    my ($class) = @_;
    my $self = {};
    return bless $self, $class;
}

=head2 object_id(), __id__()

Returns the internal address of the object_id

=cut

def object_id {
    refaddr $self;
};

{ no strict; *__id__ = *object_id; }

# overwrite the same method in Class
def superclass {
    my $class = ref($self) || $self;
    no strict;
    return ${"${class}::ISA"}[-1];
};

# overwrite the same method in Class
def class {
    return ref($self) || "Rubyish::Class";
};

sub is_a {
    my ($self, $class) = @_;
    if (ref($self)) {
        return 1 if $self->class eq $class;
        return ref($self)->isa($class);
    }

    return $self->isa($class);
}

{ no strict; *kind_of = *is_a; }

=head2 __send__($name, @args)

Invokes method by string

    package Animal;
    use base Rubyish::Object;

    def hello {
        my ($self, $arg) = @_;
        "hello, $arg.";
    }

    1;

    my $dog = Animal->new;
    print $dog->__send__("hello", "perl"); # "hello, perl."

=cut

sub __send__ {
    my ($self, $name, @args) = @_;
    if (my $sub = $self->can($name)) {
        $sub->($self, @args);
    }
}

{
    no strict;
    *send = *__send__;
}

=head2 to_yaml()

Serialize the object to YAML.

=cut

use YAML;
sub to_yaml {
    return YAML::Dump(@_);
}

=head2 methods()

Return a list of names of instance methods.

=cut

use Class::Inspector;
def methods {
    my $methods = Class::Inspector->methods(ref($self), "public");
    Rubyish::Kernel::Array($methods);
};

=head2 inpsect()

Returns a string containing a human-readable representation of obj.

=cut

def inspect {
    scalar($self) =~ /\w+=\w+(\((.*)\))/;
    "#<" . ref($self) . ":" . $2 . ">";
};

=head2 ancestors()

All ancestors of this object.

=cut

def ancestors {
    no strict;
    Array([@{ref($self) . "::ISA"}]);
    # not completed
};

=head2 clone

Produces a shollow copy a object. New object would not have the same memory address as ordinary object.

=cut

use Clone;
*clone = *Clone::clone;

1;

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>, shelling C<shelling@cpan.org>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008,2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
