#
# This file is part of Reindeer
#
# This software is Copyright (c) 2017, 2015, 2014, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Reindeer;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.018-20-g9af504b
$Reindeer::VERSION = '0.019';

# ABSTRACT: Moose with more antlers

use strict;
use warnings;

use Reindeer::Util;
use Moose::Exporter 2.1400;
use Import::Into;
use Class::Load;

use MooseX::Traitor 0.002;
use Moose::Util::TypeConstraints ();

my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    install => [ qw{ import unimport } ],

    also          => [ 'Moose', Reindeer::Util::also_list() ],
    trait_aliases => [ Reindeer::Util::trait_aliases()      ],
    as_is         => [ Reindeer::Util::as_is()              ],

    base_class_roles => [ qw{ MooseX::Traitor } ],
);

sub init_meta {
    my ($class, %options) = @_;
    my $for_class = $options{for_class};

    # enable features to the level of Perl being used
    my $features
        = $] >= 5.026 ? ':5.26'
        : $] >= 5.024 ? ':5.24'
        : $] >= 5.022 ? ':5.22'
        : $] >= 5.020 ? ':5.20'
        : $] >= 5.018 ? ':5.18'
        : $] >= 5.016 ? ':5.16'
        : $] >= 5.014 ? ':5.14'
        : $] >= 5.012 ? ':5.12'
        : $] >= 5.010 ? ':5.10'
        :               undef
        ;

    do { require feature; feature->import($features) }
        if $features;

    ### $for_class
    Moose->init_meta(for_class => $for_class);

    ### more properly in import()?
    Reindeer::Util->import_type_libraries({ -into => $for_class });
    Path::Class->export_to_level(1);
    Try::Tiny->import::into(1);
    MooseX::Params::Validate->import({ into => $for_class });
    Moose::Util::TypeConstraints->import(
        { into => $for_class },
        qw{ class_type role_type duck_type },
    );
    MooseX::MarkAsMethods->import({ into => $for_class }, autoclean => 1);

    goto $init_meta if $init_meta;
}

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alex Balhatchet AutoDestruct MultiInitArg UndefTolerant
autoclean rwp ttl metaclass Specifing

=head1 NAME

Reindeer - Moose with more antlers

=head1 VERSION

This document describes version 0.019 of Reindeer - released June 09, 2017 as part of Reindeer.

=head1 SYNOPSIS

    # ta-da!
    use Reindeer;

    # ...is the same as:
    use feature ':5.xx'; # where xx is appropriate for your running perl
    use Moose;
    use MooseX::MarkAsMethods autoclean => 1;
    use MooseX::AlwaysCoerce;
    use MooseX::AttributeShortcuts;
    # etc, etc, etc

=head1 DESCRIPTION

Like L<Moose>?  Use MooseX::* extensions?  Maybe some L<MooseX::Types>
libraries?  Hate that you have to use them in every.  Single.  Class.

Reindeer aims to resolve that :)  Reindeer _is_ Moose -- it's just Moose with
a number of the more useful/popular extensions already applied.  Reindeer is a
drop-in replacement for your "use Moose" line, that behaves in the exact same
way... Just with more pointy antlers.

=for Pod::Coverage     init_meta

=head1 EARLY RELEASE!

Be aware this package should be considered early release code.  While L<Moose>
and all our incorporated extensions have their own classifications (generally
GA or "stable"), this bundling is still under active development, and more
extensions, features and the like may still be added.

That said, my goal here is to increase functionality, not decrease it.

When this package hits GA / stable, I'll set the release to be >= 1.000.

=head1 NEW CLASS METHODS

=head2 with_traits()

This method allows you to easily compose a new class with additional traits:

    my $foo = Bar->with_traits('Stools', 'Norm')->new(beer => 1, tab => undef);

(See also L<MooseX::Traits>.)

=head1 NEW ATTRIBUTE OPTIONS

Unless specified here, all options defined by Moose::Meta::Attribute
and Class::MOP::Attribute remain unchanged.

For the following, "$name" should be read as the attribute name; and the
various prefixes should be read using the defaults

=head2 coerce => 0

Coercion is ENABLED by default; explicitly pass "coerce => 0" to disable.

(See also L<MooseX::AlwaysCoerce>.)

=head2 lazy_require => 1

The reader methods for all attributes with that option will throw an exception
unless a value for the attributes was provided earlier by a constructor
parameter or through a writer method.

(See also L<MooseX::LazyRequire>.)

=head2 is => 'rwp'

Specifying C<is =E<gt> 'rwp'> will cause the following options to be set:

    is     => 'ro'
    writer => "_set_$name"

rwp can be read as "read + write private".

=head2 is => 'lazy'

Specifying C<is =E<gt> 'lazy'> will cause the following options to be set:

    is       => 'ro'
    builder  => "_build_$name"
    lazy     => 1

B<NOTE:> Since 0.009 we no longer set C<init_arg =E<gt> undef> if no C<init_arg>
is explicitly provided.  This is a change made in parallel with L<Moo>, based
on a large number of people surprised that lazy also made one's C<init_def>
undefined.

=head2 is => 'lazy', default => ...

Specifying C<is =E<gt> 'lazy'> and a default will cause the following options to be
set:

    is       => 'ro'
    lazy     => 1
    default  => ... # as provided

That is, if you specify C<is =E<gt> 'lazy'> and also provide a C<default>, then
we won't try to set a builder, as well.

=head2 builder => 1

Specifying C<builder =E<gt> 1> will cause the following options to be set:

    builder => "_build_$name"

=head2 builder => sub { ... }

Passing a coderef to builder will cause that coderef to be installed in the
class this attribute is associated with the name you'd expect, and
C<builder =E<gt> 1> to be set.

e.g., in your class (or role),

    has foo => (is => 'ro', builder => sub { 'bar!' });

...is effectively the same as...

    has foo => (is => 'ro', builder => '_build_foo');
    sub _build_foo { 'bar!' }

The behaviour of this option in roles changed in 0.030, and the builder
methods will be installed in the role itself.  This means you can
alias/exclude/etc builder methods in roles, just as you can with any other
method.

=head2 clearer => 1

Specifying C<clearer =E<gt> 1> will cause the following options to be set:

    clearer => "clear_$name"

or, if your attribute name begins with an underscore:

    clearer => "_clear$name"

(that is, an attribute named "_foo" would get "_clear_foo")

=head2 predicate => 1

Specifying C<predicate =E<gt> 1> will cause the following options to be set:

    predicate => "has_$name"

or, if your attribute name begins with an underscore:

    predicate => "_has$name"

(that is, an attribute named "_foo" would get "_has_foo")

=head2 trigger => 1

Specifying C<trigger =E<gt> 1> will cause the attribute to be created with a trigger
that calls a named method in the class with the options passed to the trigger.
By default, the method name the trigger calls is the name of the attribute
prefixed with "_trigger_".

e.g., for an attribute named "foo" this would be equivalent to:

    trigger => sub { shift->_trigger_foo(@_) }

For an attribute named "_foo":

    trigger => sub { shift->_trigger__foo(@_) }

This naming scheme, in which the trigger is always private, is the same as the
builder naming scheme (just with a different prefix).

=head2 handles => { foo => sub { ... }, ... }

Creating a delegation with a coderef will now create a new, "custom accessor"
for the attribute.  These coderefs will be installed and called as methods on
the associated class (just as readers, writers, and other accessors are), and
will have the attribute metaclass available in $_.  Anything the accessor
is called with it will have access to in @_, just as you'd expect of a method.

e.g., the following example creates an attribute named 'bar' with a standard
reader accessor named 'bar' and two custom accessors named 'foo' and
'foo_too'.

    has bar => (

        is      => 'ro',
        isa     => 'Int',
        handles => {

            foo => sub {
                my $self = shift @_;

                return $_->get_value($self) + 1;
            },

            foo_too => sub {
                my $self = shift @_;

                return $self->bar + 1;
            },

            # ...as you'd expect.
            bar => 'bar',
        },
    );

...and later,

Note that in this example both foo() and foo_too() do effectively the same
thing: return the attribute's current value plus 1.  However, foo() accesses
the attribute value directly through the metaclass, the pros and cons of
which this author leaves as an exercise for the reader to determine.

You may choose to use the installed accessors to get at the attribute's value,
or use the direct metaclass access, your choice.

=head1 NEW KEYWORDS (SUGAR)

In addition to all sugar provided by L<Moose> (e.g. has, with, extends), we
provide a couple new keywords.

=head2 B<class_type ($class, ?$options)>

Creates a new subtype of C<Object> with the name C<$class> and the
metaclass L<Moose::Meta::TypeConstraint::Class>.

  # Create a type called 'Box' which tests for objects which ->isa('Box')
  class_type 'Box';

By default, the name of the type and the name of the class are the same, but
you can specify both separately.

  # Create a type called 'Box' which tests for objects which ->isa('ObjectLibrary::Box');
  class_type 'Box', { class => 'ObjectLibrary::Box' };

(See also L<Moose::Util::TypeConstraints>.)

=head2 B<role_type ($role, ?$options)>

Creates a C<Role> type constraint with the name C<$role> and the
metaclass L<Moose::Meta::TypeConstraint::Role>.

  # Create a type called 'Walks' which tests for objects which ->does('Walks')
  role_type 'Walks';

By default, the name of the type and the name of the role are the same, but
you can specify both separately.

  # Create a type called 'Walks' which tests for objects which ->does('MooseX::Role::Walks');
  role_type 'Walks', { role => 'MooseX::Role::Walks' };

(See also L<Moose::Util::TypeConstraints>.)

=head2 class_has => (...)

Exactly like L<Moose/has>, but operates at the class (rather than instance)
level.

(See also L<MooseX::ClassAttribute>.)

=head2 default_for

default_for() is a shortcut to extend an attribute to give it a new default;
this default value may be any legal value for default options.

    # attribute bar defined elsewhere (e.g. superclass)
    default_for bar => 'new default';

... is the same as:

    has '+bar' => (default => 'new default');

=head2 abstract

abstract() allows one to declare a method dependency that must be satisfied by a
subclass before it is invoked, and before the subclass is made immutable.

    abstract 'method_name_that_must_be_satisfied';

=head2 requires

requires() is a synonym for abstract() and works in the way you'd expect.

=head1 OVERLOADS

It is safe to use overloads in your Reindeer classes and roles; they will
work just as you expect: overloads in classes can be inherited by subclasses;
overloads in roles will be incorporated into consuming classes.

(See also L<MooseX::MarkAsMethods>)

=head1 AVAILABLE OPTIONAL ATTRIBUTE TRAITS

We export the following trait aliases.  These traits are not
automatically applied to attributes, and are lazily loaded (e.g. if you don't
use them, they won't be loaded and are not dependencies).

They can be used by specifying them as:

    has foo => (traits => [ TraitAlias ], ...);

=head2 AutoDestruct

    has foo => (
        traits  => [ AutoDestruct ],
        is      => 'ro',
        lazy    => 1,
        builder => 1,
        ttl     => 600,
    );

Allows for a "ttl" attribute option; this is the length of time (in seconds)
that a stored value is allowed to live; after that time the value is cleared
and the value rebuilt (given that the attribute is lazy and has a builder
defined).

See L<MooseX::AutoDestruct> for more information.

=head2 CascadeClearing

This attribute trait allows one to designate that certain attributes are to be
cleared when certain other ones are; that is, when an attribute is cleared
that clearing will be cascaded down to other attributes.  This is most useful
when you have attributes that are lazily built.

See L<MooseX::CascadeClearing> for more information and a significantly more
cogent description.

=head2 ENV

This is a Moose attribute trait that you use when you want the default value
for an attribute to be populated from the %ENV hash.  So, for example if you
have set the environment variable USERNAME to 'John' you can do:

    package MyApp::MyClass;

    use Moose;
    use MooseX::Attribute::ENV;

    has 'username' => (is=>'ro', traits=>['ENV']);

    package main;

    my $myclass = MyApp::MyClass->new();

    print $myclass->username; # STDOUT => 'John';

This is basically similar functionality to something like:

    has 'attr' => (
            is=>'ro',
            default=> sub {
                    $ENV{uc 'attr'};
            },
    );

If the named key isn't found in %ENV, then defaults will execute as normal.

See L<MooseX::Attribute::ENV> for more information.

=head2 MultiInitArg

    has 'data' => (
        traits    => [ MultiInitArg ],
        is        => 'ro',
        isa       => 'Str',
        init_args => [qw(munge frobnicate)],
    );

This trait allows your attribute to be initialized with any one of multiple
arguments to new().

See L<MooseX::MultiInitArg> for more information.

=head2 UndefTolerant

Applying this trait to your attribute makes it's initialization tolerant of
of undef.  If you specify the value of undef to any of the attributes they
will not be initialized (or will be set to the default, if applicable).
Effectively behaving as if you had not provided a value at all.

    package My:Class;
    use Moose;

    use MooseX::UndefTolerant::Attribute;

    has 'bar' => (
        traits    => [ UndefTolerant ],
        is        => 'ro',
        isa       => 'Num',
        predicate => 'has_bar'
    );

    # Meanwhile, under the city...

    # Doesn't explode
    my $class = My::Class->new(bar => undef);
    $class->has_bar # False!

See L<MooseX::UndefTolerant::Attribute> for more information.

=head1 INCLUDED EXTENSIONS

Reindeer includes the traits and sugar provided by the following extensions.
Everything their docs say they can do, you can do by default with Reindeer.

=head2 L<MooseX::AbstractMethod>

=head2 L<MooseX::AlwaysCoerce>

=head2 L<MooseX::AttributeShortcuts>

=head2 L<MooseX::ClassAttribute>

=head2 L<MooseX::CurriedDelegation>

=head2 L<MooseX::LazyRequire>

=head2 L<MooseX::MarkAsMethods>

Note that this causes any overloads you've defined in your class/role to be
marked as methods, and L<namespace::autoclean> invoked.

=head2 L<MooseX::NewDefaults>

=head2 L<MooseX::StrictConstructor>

=head2 L<MooseX::Traits>

This provides a new class method, C<with_traits()>, allowing you to compose
traits in on the fly:

    my $foo = Bar->with_traits('Stools')->new(...);

=head1 INCLUDED TYPE LIBRARIES

=head2 L<MooseX::Types::Moose>

=head2 L<MooseX::Types::Common::String>

=head2 L<MooseX::Types::Common::Numeric>

=head2 L<MooseX::Types::LoadableClass>

=head2 L<MooseX::Types::Path::Class>

=head2 L<MooseX::Types::Tied::Hash::IxHash>

=head1 OTHER

Non-Moose specific items made available to your class/role:

=head2 Perl v5.10 features

If you're running on v5.10 or greater of Perl, Reindeer will automatically
enable v5.10 features in the consuming class.

=head2 L<namespace::autoclean>

Technically, this is done by L<MooseX::MarkAsMethods>, but it's worth pointing
out here.  Any overloads present in your class/role are marked as methods
before autoclean is unleashed, so Everything Will Just Work as Expected.

=head2 L<Path::Class>

  use Path::Class;
  
  my $dir  = dir('foo', 'bar');       # Path::Class::Dir object
  my $file = file('bob', 'file.txt'); # Path::Class::File object
  
  # Stringifies to 'foo/bar' on Unix, 'foo\bar' on Windows, etc.
  print "dir: $dir\n";
  
  # Stringifies to 'bob/file.txt' on Unix, 'bob\file.txt' on Windows
  print "file: $file\n";
  
  my $subdir  = $dir->subdir('baz');  # foo/bar/baz
  my $parent  = $subdir->parent;      # foo/bar
  my $parent2 = $parent->parent;      # foo
  
  my $dir2 = $file->dir;              # bob

  # Work with foreign paths
  use Path::Class qw(foreign_file foreign_dir);
  my $file = foreign_file('Mac', ':foo:file.txt');
  print $file->dir;                   # :foo:
  print $file->as_foreign('Win32');   # foo\file.txt
  
  # Interact with the underlying filesystem:
  
  # $dir_handle is an IO::Dir object
  my $dir_handle = $dir->open or die "Can't read $dir: $!";
  
  # $file_handle is an IO::File object
  my $file_handle = $file->open($mode) or die "Can't read $file: $!";

See the L<Path::Class> documentation for more detail.

=head2 L<Try::Tiny>

You can use Try::Tiny's C<try> and C<catch> to expect and handle exceptional
conditions, avoiding quirks in Perl and common mistakes:

  # handle errors with a catch handler
  try {
    die "foo";
  } catch {
    warn "caught error: $_"; # not $@
  };

You can also use it like a standalone C<eval> to catch and ignore any error
conditions.  Obviously, this is an extreme measure not to be undertaken
lightly:

  # just silence errors
  try {
    die "foo";
  };

See the L<Try::Tiny> documentation for more detail.

=head1 CAVEAT

This author is applying his own assessment of "useful/popular extensions".
You may find yourself in agreement, or violent disagreement with his choices.
YMMV :)

=head1 ACKNOWLEDGMENTS

Reindeer serves largely to tie together other packages -- Moose extensions and
other common modules.  Those other packages are largely by other people,
without whose work Reindeer would have a significantly smaller rack.

We also use documentation as written for the other packages pulled in here to
help present a cohesive whole.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<L<Moose>, and all of the above-referenced packages.|L<Moose>, and all of the above-referenced packages.>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/reindeer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 CONTRIBUTOR

=for stopwords Alex Balhatchet

Alex Balhatchet <kaoru@slackwise.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2015, 2014, 2012, 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
