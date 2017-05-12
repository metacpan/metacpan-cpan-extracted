package Object::Boolean;

use base 'Class::Data::Inheritable';
use Sub::Exporter -setup =>
  { exports => { True => \&_build_true_or_false, 
                False => \&_build_true_or_false } };
use warnings;
use strict;

our $VERSION = '0.02';

# overrideable class data
__PACKAGE__->mk_classdata( strTrue  => 'true' );
__PACKAGE__->mk_classdata( strFalse => 'false' );
__PACKAGE__->mk_classdata( numTrue  => 1 );
__PACKAGE__->mk_classdata( numFalse => 0 );

# boolean behavior
use overload 'bool' => \&_is_true;

# String behavior
use overload '""'   => \&_str;
use overload 'eq'   => \&_eq;
use overload 'ne'   => \&_not_eq;
use overload 'not'  => \&_not;

# Numeric behavior
use overload '0+'   => \&_num;
use overload '=='   => \&_num_eq;
use overload '!='   => \&_num_not_eq;
use overload '!'    => \&_not;

# constructor
sub new {
    my ( $class, $value ) = @_;
    $class = ref $class if ref $class;
    bless \( 
        my $state = ( !$value || $value eq $class->strFalse ? 0 : 1 ) 
    ), $class;
}
# _is_true() and new() depend on $state being a scalar ref.  Nothing else does.
sub _is_true    { my($s)=@_; $$s }

# build exportable constants
sub _build_true_or_false {
    my $class = shift;
    my $name  = shift;
    my $method =
      (   $name eq 'True'  ? 'numTrue'
        : $name eq 'False' ? 'numFalse'
        :                    die("bad export param : $name") );
    return sub { $class->new($class->$method) };
}

# functions used in overloading
sub _str { my($s)=@_; $s->_is_true ? $s->strTrue : $s->strFalse; }
sub _num { my($s)=@_; $s->_is_true ? $s->numTrue : $s->numFalse; }

sub _eq     { my($s,$t)=@_; $s->_str eq (ref $t eq ref $s ? $t->_str : $t); }
sub _num_eq { my($s,$t)=@_; $s->_num == (ref $t eq ref $s ? $t->_num : $t); }

sub _not_eq     { my($s,$t)=@_; !$s->_eq($t);    }
sub _num_not_eq { my($s,$t)=@_; !$s->_num_eq($t);}

sub _not {
    my ($s) = @_;
    my $class = ref $s;
    $s->_is_true ? $class->new( $class->numFalse ) : $class->new( $class->numTrue );
}

=head1 NAME

Object::Boolean - Represent boolean values as objects

=head1 SYNOPSIS

    use Object::Boolean;
    use Object::Boolean qw/True False/; # ..or export some constants
    use Object::Boolean                 # ..or rename those constants
        True => { -as => 'TRUE' },   
        False => { -as => 'FALSE' };

    # Create a "false" object by calling new() with a Perl 
    # false value or the word 'false'.
    my $f = Object::Boolean->new(0);
    my $f = Object::Boolean->new('');
    my $f = Object::Boolean->new(2+2==3);
    my $f = Object::Boolean->new('false');

    # Create a "true" object by calling new() with anything else
    my $t = Object::Boolean->new(1);
    my $t = Object::Boolean->new(2+2==4);
    my $t = Object::Boolean->new('true');
    my $t = Object::Boolean->new('elephant');

    # In boolean context, it behaves like a boolean value.
    if ($f) { print "it's true" }
    print "\$f is false" unless $f;
    print "1+1==2 and it's true" if 1+1==2 && $t;

    # In string context, it becomes "true" or "false"
    print "It was a $f alarm.";
    print "Those are $f teeth.";

    # Boolean negation produces a new boolean object.
    print (!$f)." love is hard to find.";

    # Checking for numeric or string equality with other boolean
    # objects compares them as though they were in a boolean context.
    if ($t!=$f) { print "They are not the same." } # like xor
    if ($t==$t) { print "They are both true or both false." }
    if (Object::Boolean->new(1) eq Object::Boolean->new(2)) {
        # this will be true
    }

    # Comparison to non-boolean objects treats booleans as strings 
    # for string equality or the numbers 0 or 1 for numeric equality
    my $true = Object::Boolean->new('true');
    print "true" if $true eq 'true'; # true
    print 'true' if $true == 1;      # also true
    print 'true' if $true == 27;     # no, not true
    print 'true' if $true eq 'True'; # not true

=head1 DESCRIPTION

Package for representing booleans as objects which stringify to true/false
and numerify to 0/1.  Derived classes can easily stringify/numerify to other 
values.

=head1 FUNCTIONS

=over

=item new

Create a new Object::Boolean object.

=back

=head1 SEE ALSO

Object::Boolean::YesNo -- to stringify to 'Yes' and 'No' instead of 'true' and 'false'.

=head1 VERSION

Version 0.02

=head1 AUTHOR

Brian Duggan, C<< <bduggan at matatu.org> >>

=head1 LICENSE

Copyright 2008 Brian Duggan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

