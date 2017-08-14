#
# This file is part of MooseX-RelatedClasses
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::RelatedClasses;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.011-2-g61ae6c8
$MooseX::RelatedClasses::VERSION = '0.012';

# ABSTRACT: Parameterized role for related class attributes

use MooseX::Role::Parameterized;
use namespace::autoclean;
use autobox::Core;
use autobox::Camelize;
use MooseX::AttributeShortcuts 0.020;
use MooseX::Types::Common::String ':all';
use MooseX::Types::LoadableClass ':all';
use MooseX::Types::Perl ':all';
use MooseX::Types::Moose ':all';
use MooseX::Util 'with_traits', 'find_meta';

use Module::Find 'findallmod';

use Class::Load 'load_class';
use String::RewritePrefix;

use Moose::Exporter;


{
    package MooseX::RelatedClasses::Exports;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.011-2-g61ae6c8
$MooseX::RelatedClasses::Exports::VERSION = '0.012';

    # This is a little awkward, but it resolves the unpleasantness of having
    # these functions become part of the role (!!!)
    #
    # Here we simply create a "dummy" package using Moose exporter, then pull
    # its imports in via an "also" in the main package.  This resolves things
    # nicely without having to do any meta-tinkering.
    #
    # Sadly.

    use strict;
    use warnings;

    use MooseX::Util 'find_meta';
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        with_meta => [ qw{
            related_class
            related_classes
            related_namespace
        } ],
    );

    sub related_class { goto \&related_classes }

    sub related_classes {
        my $meta = shift;

        if (@_ % 2 == 1) {
            unshift @_, ref $_[0] ? 'names' : 'name';
        }

        find_meta('MooseX::RelatedClasses')->apply($meta, @_);
    }

    sub related_namespace {
        my ($meta, $namespace) = (shift, shift);

        my %args = (
            all_in_namespace => 1,
            namespace        => $namespace,
            name             => $namespace,
            @_,
        );

        ### %args
        find_meta('MooseX::RelatedClasses')->apply($meta, %args);
    }
}

Moose::Exporter->setup_import_methods(
    also => 'MooseX::RelatedClasses::Exports',
);


parameter name  => (
    traits    => [Shortcuts],
    is        => 'ro',
    isa       => PackageName,
    predicate => 1,
);

parameter names => (
    traits    => [Shortcuts],
    is        => 'rwp',
    predicate => 1,
    lazy      => 1,

    isa        => HashRef[Identifier],
    constraint => sub { do { is_PackageName($_) or die 'keys must be PackageName' } for $_->keys; 1 },
    coerce     => [
        ArrayRef              => sub { +{ map { $_ => $_->decamelize } @$_ } },
        PackageName()->name() => sub { +{       $_ => $_->decamelize       } },
    ],

    default => sub { confess 'name parameter required!' unless $_[0]->has_name; $_[0]->name },
);

parameter namespace => (
    traits    => [Shortcuts],
    is        => 'rwp',
    isa       => Maybe[PackageName],
    predicate => 1,
);

parameter all_in_namespace => (isa => Bool, default => 0);
parameter load_all         => (isa => Bool, default => 0);
parameter private          => (isa => Bool, default => 0);

# TODO use rewrite prefix to look for traits in namespace

role {
    my ($p, %opts) = @_;

    confess 'Cannot specify both the "name" and "names" parameters!'
        if $p->has_name && $p->has_names;

    # check namespace
    if (not $p->has_namespace) {

        die 'Either a namespace or a consuming metaclass must be supplied!'
            unless $opts{consumer};

        $p->_set_namespace($opts{consumer}->name);
    }

    if ($p->all_in_namespace) {

        confess 'Cannot use an empty namespace and all_in_namespace!'
            unless $p->has_namespace;

        my $ns = $p->namespace;

        ### finding for namespace: $ns
        my %mod =
            map { s/^${ns}:://; $_ => $_->decamelize }
            map { load_class($_) if $p->load_all; $_ }
            Module::Find::findallmod $ns
            ;

        ### %mod
        $p->_set_names(\%mod);
    }

    for my $name ($p->names->keys->flatten) {
        my $identifier = $p->names->{$name};

        my $full_name
            = $p->namespace
            ? $p->namespace . '::' . $name
            : $name
            ;

        my $pvt = $p->private ? '_' : q{};

        # SomeThing::More -> some_thing__more
        my $local_name           = "${identifier}_class";
        my $original_local_name  = "original_$local_name";
        my $original_reader      = "$pvt$original_local_name";
        my $traitsfor_local_name = $local_name . '_traits';
        my $traitsfor_reader     = "$pvt$traitsfor_local_name";

        ### $full_name
        has "$pvt$original_local_name" => (
            traits     => [Shortcuts],
            is         => 'lazy',
            isa        => LoadableClass,
            constraint => sub { $_->isa($full_name) },
            coerce     => 1,
            init_arg   => "$pvt$local_name",
            builder    => sub { $full_name },
        );

        has "$pvt$local_name" => (
            traits     => [Shortcuts],
            is         => 'lazy',
            isa        => LoadableClass,
            constraint => sub { $_->isa($full_name) },
            coerce     => 1,
            init_arg   => undef,
            builder    => sub {
                my $self = shift @_;

                return with_traits( $self->$original_reader() =>
                    $self->$traitsfor_reader()->flatten,
                );
            },
        );

        # XXX do the same original/local init_arg swizzle here too?
        has "$pvt$traitsfor_local_name" => (
            traits  => [Shortcuts, 'Array'],
            is      => 'lazy',
            isa     => ArrayRef[LoadableRole],
            builder => sub { [ ] },
            handles => {
                "${pvt}has_$traitsfor_local_name" => 'count',
            },
        );
    }

    return;
};

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Kulag Parameterized Namespacing findable

=head1 NAME

MooseX::RelatedClasses - Parameterized role for related class attributes

=head1 VERSION

This document describes version 0.012 of MooseX::RelatedClasses - released August 13, 2017 as part of MooseX-RelatedClasses.

=head1 SYNOPSIS

    # with this:
    with 'MooseX::RelatedClasses' => {
        name => 'Thinger', namespace => undef,
    };

    # this:
    use MooseX::RelatedClasses;
    related_class name => 'Thinger', namespace => undef;

    # ...or this:
    use MooseX::RelatedClasses;
    related_class 'Thinger', namespace => undef;

    # ...we get three attributes:
    #
    #   thinger_class
    #   thinger_class_traits
    #   original_thinger_class
    #
    # ...and they look like this:

    has thinger_class => (
        traits     => [ Shortcuts ],                # MooseX::AttributeShortcuts
        is         => 'lazy',                       # MX::AttributeShortcuts
        isa        => LoadableClass,                # MooseX::Types::LoadableClass
        init_arg   => undef,
        constraint => sub { $_->isa('Thinger') },   # MX::AttributeShortcuts
        builder    => sub { ... compose original class and traits ... },
    );

    has thinger_class_traits => (
        traits  => [ Shortcuts ],
        is      => 'lazy',
        isa     => ArrayRef[LoadableRole],
        builder => sub { [ ] },
    );

    has original_thinger_class => (
        traits     => [ Shortcuts ],
        is         => 'lazy',
        isa        => LoadableClass,
        constraint => sub { $_->isa('Thinger') },
        coerce     => 1,
        init_arg   => 'thinger_class',
        builder    => sub { 'My::Framework::Thinger' },
    );

=head1 DESCRIPTION

Have you ever built out a framework, or interface API of some sort, to
discover either that you were hardcoding your related class names (not very
extension-friendly) or writing the same code for the same type of attributes
to specify what related classes you're using?

Alternatively, have you ever been using a framework, and wanted to tweak one
tiny bit of behaviour in a subclass, only to realize it was written in such a
way to make that difficult-to-impossible without a significant effort?

This package aims to end that, by providing an easy, flexible way of defining
"related classes", their base class, and allowing traits to be specified.

=head1 ROLE PARAMETERS

Parameterized roles accept parameters that influence their construction.  This role accepts the following parameters.

=head2 name

The name of a class, without the prefix, to consider related.  e.g. if My::Foo
is our namespace and My::Foo::Bar is the related class:

    name => 'Bar'

...is the correct specification.

This parameter is optional, so long as either the names or all_in_namespace
parameters are given.

=head2 names [ ... ]

One or more names that would be legal for the name parameter.

=head2 all_in_namespace (Bool)

True if all findable packages under the namespace should be used as related
classes.  Defaults to false.

=head2 namespace

The namespace our related classes live in.  If this is not given explicitly,
the name of the consuming class will be used as the namespace.  If the
consuming class' metaclass is not available (e.g. the role is being
constructed by something other than a consumer), then this parameter is
mandatory.

This parameter will also accept an explicit 'undef'.  If this is the case,
then related classes must be specified by their full name and it is an error
to attempt to enable the all_in_namespace option.

e.g.:

    with 'MooseX::RelatedClasses' => {
        namespace => undef,
        name      => 'LWP::UserAgent',
    };

...will provide the C<lwp__user_agent_class>, C<lwp__user_agent_traits> and
C<original_lwp__user_agent_class> attributes.

=head2 load_all (Bool)

If set to true, all related classes are loaded as we find them.  Defaults to
false.

=head2 private (Bool)

If true, attributes, accessors and builders will all be named according to the
same rules L<MooseX::AttributeShortcuts> uses.  (That is, in general prefixed
with an "_".)

=head1 FUNCTIONS

=head2 related_class()

Synonym for L</related_classes()>.

=head2 related_classes()

Takes the same options that the role takes as parameters.  That means that this:

    related_classes name => 'LWP::UserAgent', namespace => undef;

...is effectively the same as:

    with 'MooseX::RelatedClasses' => {
        name      => 'LWP::UserAgent',
        namespace => undef,
    };

=head2 related_namespace()

Given a namespace, declares that everything under that namespace is related.
That is,

    related_namespace 'Net::Amazon::EC2';

...is the same as:

    with 'MooseX::RelatedClasses' => {
        namespace        => 'Net::Amazon::EC2',
        name             => 'Net::Amazon::EC2',
        all_in_namespace => 1,
    };

=head1 EXAMPLES

=head2 Multiple Related Classes at Once

Use the L</names> option with an array reference of classes, and attribute
sets will be built for all of them.

    related_classes [ qw{ Thinger Dinger Finger } ];

    # or longhand:
    related_classes names => [ qw{ Thinger Dinger Finger } ];

=head2 Namespaces / Namespacing

Normally, related classes tend to be under the namespace of the class they
are related to.  For example, let's say we have a class named C<TimeLords>.
Related to this class are C<TimeLords::SoftwareWritten::Git>,
C<TimeLords::Gallifrey> and C<TimeLords::Enemies::Daleks>.

The C<TimeLords> package can start off like this, to include the proper
related classes:

    package TimeLords;

    use Moose;
    use timeandspace::autoclean;
    use MooseX::RelatedClasses;

    related_classes [ qw{ Gallifrey Enemies::Daleks SoftwareWritten::Git } ];

And that will generate the expected related class attributes:

    # TimeLords::Gallifrey
    gallifrey_class
    gallifrey_class_traits
    original_gallifrey_class
    # TimeLords::Enemies::Daleks
    enemies__daleks_class
    enemies__daleks_class_traits
    original_enemies__daleks_class
    # TimeLords::SoftwareWritten::Git
    software_written__git_class
    software_written__git_class_traits
    original_software_written__git_class

=head2 Related classes outside the namespace

Occasionally you'll want to use something like L<LWP::UserAgent>, which has
nothing to do with your class except that you use it, and would like to be
able to easily tweak it on the fly.  This can be done with the C<undef>
namespace:

    related_class 'LWP::UserAgent', namespace => undef;

This will cause the following related class attributes to be generated:

    lwp__user_agent_class
    lwp__user_agent_class_traits
    original_lwp__user_agent_class

=head1 INSPIRATION / MADNESS

The L<Class::MOP> / L<Moose> MOP show the beginnings of this:  with attributes
or methods named a certain way (e.g. *_metaclass()) the class to be used for a
particular thing (e.g. attribute metaclass) is stored in a fashion such that a
subclass (or trait) may overwrite and provide a different class name to be
used.

So too, here, we do this, but in a more flexible way: we track the original
related class, any additional traits that should be applied, and the new
(anonymous, typically) class name of the related class.

Another example is the (very useful and usable) L<Net::Amazon::EC2>.  It uses
L<Moose>, is nicely broken out into discrete classes, etc, but does not lend
itself to easy on-the-fly extension by developers with traits.

=head1 ANONYMOUS CLASS NAMES

Note that we use L<MooseX::Traitor> to compose anonymous classes, so the
"anonymous names" will look less like:

    Moose::Meta::Package::__ANON__::SERIAL::...

And more like:

    My::Framework::Thinger::__ANON__::SERIAL::...

Anonymous classes are only ever composed if traits for a related class are
supplied.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/moosex-relatedclasses/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 CONTRIBUTOR

=for stopwords Kulag

Kulag <g.kulag@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2015, 2014, 2013, 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
