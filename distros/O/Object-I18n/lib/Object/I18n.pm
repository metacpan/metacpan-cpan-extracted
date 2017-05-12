package Object::I18n;

use 5.008003;
use strict;
use warnings;

# Not using Exporter
our @EXPORT = qw(i18n);
our $VERSION = '0.02';

use Carp;
use Scalar::Util qw(weaken);

=head1 NAME

Object::I18n - Internationalize objects

=head1 SYNOPSIS

    package Greeting;
    sub new { my $x = $_[1]; bless \$x; }
    sub greeting { @_ ? ${$_[1]} : (${$_[1]} = $_[2]) }
    use Object::I18n qw(id);
    __PACKAGE__->i18n->storage('Greeting::CDBI::I18n');
    __PACKAGE__->i18n->register('greeting');
    
    package main;
    my $obj = Greeting->new("Hello, world\n");
    print $obj->greeting;# "Hello, world\n"
    $obj->i18n->language('fr');
    print $obj->greeting;# exception
    $obj->greeting("Bonjour, monde\n");
    print $obj->greeting;# "Bonjour, monde\n"
    
=cut

my %i18n_object;

sub i18n {
    my $self = shift;
    my $class = ref $self || $self;
    my $i18n = $i18n_object{$class};
    return $i18n unless ref $self;

    _prune($i18n->{instance});
    my $oid_method = $i18n->{oid_method};
    my $oid = $self->$oid_method;
    my $instance_i18n = $i18n->{instance}{$oid};
    
    $i18n->{instance}{$oid} ||= $i18n->_clone($self);
}

sub import {
    my ($class, %opts) = (@_);
    my ($pkg) = caller;
    $class->_init_i18n_object($pkg, %opts);
    no strict 'refs';
    *{ "$pkg\::i18n" } = \&i18n;
}

sub oid {
    my $self = shift;
    my $oid_method = $self->{oid_method};
    return $self->{object}->$oid_method;
}

sub _prune {
    my ($instance) = @_;
    for my $oid (keys %$instance) {
        next if $instance->{$oid}{object};
        delete $instance->{$oid};
    }
}

sub _clone {
    my $self = shift;
    my ($obj) = @_;
    # XXX - may need deeper cloning than this
    my $clone = { %$self };
    delete $clone->{instance};
    delete $clone->{language};
    $clone->{object} = $obj;
    # $clone->{object} will be undef when the object is DESTROYed.
    weaken($clone->{object});
    return bless $clone, __PACKAGE__;
}

# The i18n object has these attributes:
#   class               - The package of the class or object
#   oid_method          - A method in "class" that returns a unique object id
#   language            - The current language for the class or object
#   object              - The object that contains the i18n object
#   instance            - A hash of i18n instances stored in the class i18n
#   registered_methods  - A hash of overridden methods
#
sub _init_i18n_object {
    my $class = shift;
    my ($pkg, %attrs) = @_;
    $attrs{oid_method}      ||= 'id';
    $attrs{storage_class}   ||= 'Object::I18n::Storage::MemHash';
    croak "invalid storage_class" if $attrs{storage_class} =~ /[^\w:]/;
    eval "require $attrs{storage_class}; 1" or die $@;

    my $obj = bless {
        class => $pkg,
        %attrs,
    }, $class;
    $i18n_object{$pkg} = $obj;
}

sub register {
    my $self = shift;
    my @methods = @_;
    my $registered = $self->{registered_methods} ||= {};
    my $class = $self->{class} 
        or die "register must be called as class method";
    for my $method (@methods) {
        croak "No such method '$method' found for class '$class'"
            unless my $code = $class->can($method);
        $registered->{$method} = $code;
        no strict 'refs';
        no warnings 'redefine';
        *{ "$class\::$method" } = sub {
            my $self = shift;
            return $self->$code(@_) unless $self->i18n->language;

            my $storage_class = $self->i18n->{storage_class};
            my $storage = $storage_class->new($self, $method)
                or croak "Could not create instance of '$storage_class'"
                         . "for '$method'";
            return $storage->store(@_) if @_;
            return $storage->fetch;
        };
    }
    keys %$registered;
}

sub storage_class {
    my $self = shift;
    $self->{storage_class};
}

sub registered_methods {
    my $self = shift;
    keys %{ $self->{registered_methods} };
}

sub language {
    my $self = shift;
    return $self->{language} = shift if @_;

    return $self->{language} unless exists $self->{object};
    return $self->{language} || $self->{class}->i18n->language;
}

# ->inject(attr=>'question',language=>'fr',notes=>$notes, data=>$data);
sub inject {
    my $self = shift;
    my %opts = @_;

    my $storage_class = $self->{storage_class};
    local($self->{language}) = $opts{language};
    my $storage = $storage_class->new($self->{object}, $opts{attr});
    $storage->store($opts{data});
    return unless $opts{notes} and my $history_class = $self->{history_class};

    $history_class->record($opts{notes});
}

sub is_injected {
    my $self = shift;
    my %opts = @_;

    my $storage_class = $self->{storage_class};
    my $storage = $storage_class->new($self->{object}, $opts{attr});
    return $storage->fetch;
}

=head1 DESCRIPTION

Object::I18n overrides methods in your class to return international content.
It provides one mixin method, i18n(), which returns an Object::I18n object.
The object returned is different depending on whether you call it on your
class or an instance of your class.  See L<"METHODS"> below.

=head2 METHODS

Most methods can be either class methods or object methods but this
doesn't mean what you may be accustomed to.  A method is considered to
act as a class method if it is called on an Object::I18n object returned
from the class form of the i18n() method.  It acts as an object method 
when called on the object returned from the object form of the i18n()
method.

=over

=item language [LANGUAGE]

Returns and optionally sets the current language.  If called as a class
method it affects all instances of a class, except those that have set
language() for themselves.  If unset, methods should behave as if
Object::I18n was not being used at all.

=item register METHODLIST

Registers the list of method names as i14able.  The methods will be
overridden so that they return i14ed content when C<language> is set.

=item storage_class [CLASS]

Returns and optionally set the class that controls how translations
are stored.

=item inject OPTIONS

Injects a new translation into your C<storage_class>.  The options are:

=over

=item language

The language the translation is in.  If not set then the language
returned by the language() method will be used.

=item attr

The attribute (method) in your class that the translation is for.

=item data

The actual translated text to be stored.

=item notes

Any notes to be saved along with the translation.  Requires you 
to have configured a C<history_class>.

=back

=back

=head1 EXPORT

C<i18n>.

=head1 AUTHOR

Rick Delaney, E<lt>rick@bort.caE<gt>

=head1 ACKNOWLEDGEMENTS

To be filled in.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Rick Delaney

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
