#
# This file is part of MooseX-AttributeShortcuts
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package MooseX::AttributeShortcuts::Trait::Attribute;
our $AUTHORITY = 'cpan:RSRCHBOY';
$MooseX::AttributeShortcuts::Trait::Attribute::VERSION = '0.032';
# ABSTRACT: Shortcuts attribute trait proper

use namespace::autoclean;
use MooseX::Role::Parameterized;
use Moose::Util::TypeConstraints  ':all';
use MooseX::Types::Moose          ':all';
use MooseX::Types::Common::String ':all';

use aliased 'MooseX::Meta::TypeConstraint::Mooish' => 'MooishTC';

use List::Util 1.33 'any';

# lazy...
my $_acquire_isa_tc = sub { goto \&Moose::Util::TypeConstraints::find_or_create_isa_type_constraint };


parameter writer_prefix  => (isa => NonEmptySimpleStr, default => '_set_');
parameter builder_prefix => (isa => NonEmptySimpleStr, default => '_build_');

with 'MooseX::AttributeShortcuts::Trait::Attribute::HasAnonBuilder';


has constraint => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_constraint',
);

has original_isa => (
    is        => 'ro',
    predicate => 'has_original_isa',
);

has trigger_method => (
    is        => 'ro',
    predicate => 'has_trigger_method',
);


after attach_to_class => sub {
    my ($self, $class) = @_;

    return unless $self->has_anon_builder && !$self->anon_builder_installed;

    ### install our anon builder as a method: $class->name
    $class->add_method($self->builder => $self->anon_builder);
    $self->_set_anon_builder_installed;

    return;
};


before _process_options => sub { shift->_mxas_process_options(@_) };

# this feels... bad.  But I'm not sure there's any way to ensure we
# process options on a clone/extends without wrapping new().

around new => sub {
    my ($orig, $self) = (shift, shift);
    my ($name, %options) = @_;

    $self->_mxas_process_options($name, \%options)
        if $options{__hack_no_process_options};

    return $self->$orig($name, %options);
};


# NOTE: remove_delegation() will also automagically remove any custom
# accessors we create here

# handle: handles => { name => sub { ... }, ... }
around _make_delegation_method => sub {
    my ($orig, $self) = (shift, shift);
    my ($name, $coderef) = @_;

    ### _make_delegation_method() called with a: ref $coderef
    return $self->$orig(@_)
        unless 'CODE' eq ref $coderef;

    # this coderef will be installed as a method on the associated class itself.
    my $custom_coderef = sub {
        # aka $self from the class instance's perspective
        my $associated_class_instance = shift @_;

        # in $coderef, $_ will be the attribute metaclass
        local $_ = $self;
        return $associated_class_instance->$coderef(@_);
    };

    return $self->_process_accessors(custom => { $name => $custom_coderef });
};

sub _mxas_process_options {
    my ($class, $name, $options) = @_;

    my $_has = sub { defined $options->{$_[0]}             };
    my $_opt = sub { $_has->(@_) ? $options->{$_[0]} : q{} };
    my $_ref = sub { ref $_opt->(@_) || q{}                };

    # handle: is => ...
    $class->_mxas_is_rwp($name, $options, $_has, $_opt, $_ref);
    $class->_mxas_is_lazy($name, $options, $_has, $_opt, $_ref);

    # handle: builder => 1, builder => sub { ... }
    $class->_mxas_builder($name, $options, $_has, $_opt, $_ref);

    # handle: isa_instance_of => ...
    $class->_mxas_isa_instance_of($name, $options, $_has, $_opt, $_ref);
    # handle: isa => sub { ... }
    $class->_mxas_isa_mooish($name, $options, $_has, $_opt, $_ref);

    # handle: constraint => ...
    $class->_mxas_constraint($name, $options, $_has, $_opt, $_ref);
    # handle: coerce => [ ... ]
    $class->_mxas_coerce($name, $options, $_has, $_opt, $_ref);


    my %prefix = (
        predicate => 'has',
        clearer   => 'clear',
        trigger   => '_trigger_',
    );

    my $is_private = sub { $name =~ /^_/ ? $_[0] : $_[1] };
    my $default_for = sub {
        my ($opt) = @_;

        return unless $_has->($opt);
        my $opt_val = $_opt->($opt);

        my ($head, $mid)
            = $opt_val eq '1'  ? ($is_private->('_', q{}), $is_private->(q{}, '_'))
            : $opt_val eq '-1' ? ($is_private->(q{}, '_'), $is_private->(q{}, '_'))
            :                    return;

        $options->{$opt} = $head . $prefix{$opt} . $mid . $name;
        return;
    };

    ### set our other defaults, if requested...
    $default_for->($_) for qw{ predicate clearer };
    my $trigger = "$prefix{trigger}$name";
    do { $options->{trigger} = sub { shift->$trigger(@_) }; $options->{trigger_method} = $trigger }
        if $options->{trigger} && $options->{trigger} eq '1';

    return;
}

# handle: is => 'rwp'
sub _mxas_is_rwp {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    return unless $_opt->('is') eq 'rwp';

    $options->{is}     = 'ro';
    $options->{writer} = $class->canonical_writer_prefix . $name;

    return;
}

# handle: is => 'lazy'
sub _mxas_is_lazy {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    return unless $_opt->('is') eq 'lazy';

    $options->{is}       = 'ro';
    $options->{lazy}     = 1;
    $options->{builder}  = 1
        unless $_has->('builder') || $_has->('default');

    return;
}

# handle: lazy_build => 'private'
sub _mxas_lazy_build_private {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    return unless $_opt->('lazy_build') eq 'private';

    $options->{lazy_build} = 1;
    $options->{clearer}    = "_clear_$name";
    $options->{predicate}  = "_has_$name";

    return;
}

# handle: builder => 1, builder => sub { ... }
sub _mxas_builder {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    return unless $_has->('builder');

    if ($_ref->('builder') eq 'CODE') {

        $options->{anon_builder} = $options->{builder};
        $options->{builder}      = 1;
    }

    $options->{builder} = $class->_mxas_builder_name($name)
        if $options->{builder} eq '1';

    return;
}

sub _mxas_isa_mooish {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    return unless $_ref->('isa') eq 'CODE';

    ### build a mooish type constraint...
    $options->{original_isa} = $options->{isa};
    $options->{isa} = MooishTC->new(constraint => $options->{isa});

    return;
}

# handle: isa_instance_of => ...
sub _mxas_isa_instance_of {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    return unless $_has->('isa_instance_of');

    if ($_has->('isa')) {

        $class->throw_error(
            q{Cannot use 'isa_instance_of' and 'isa' together for attribute }
            . $_opt->('definition_context')->{package} . '::' . $name
        );
    }

    $options->{isa} = class_type(delete $options->{isa_instance_of});

    return;
}

# handle: coerce => [ ... ]
sub _mxas_coerce {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    if ($_ref->('coerce') eq 'ARRAY') {

        ### must be type => sub { ... } pairs...
        my @coercions = @{ $_opt->('coerce') };
        confess 'You must specify an "isa" when declaring "coercion"'
            unless $_has->('isa');
        confess 'coercion array must be in pairs!'
            if @coercions % 2;
        confess 'must define at least one coercion pair!'
            unless @coercions > 0;

        my $our_coercion = Moose::Meta::TypeCoercion->new;
        my $our_type
            = $options->{original_isa}
            ? $options->{isa}
            : $_acquire_isa_tc->($_opt->('isa'))->create_child_type
            ;

        $our_coercion->add_type_coercions(@coercions);
        $our_type->coercion($our_coercion);

        $options->{original_isa} ||= $options->{isa};
        $options->{isa}            = $our_type;
        $options->{coerce}         = 1;

        return;
    }

    # If our original constraint has coercions and our created subtype
    # did not have any (as specified in the 'coerce' option), then
    # copy the parent's coercions over.

    if ($_has->('original_isa') && $_opt->('coerce') eq '1') {

        my $isa_type = $_acquire_isa_tc->($_opt->('original_isa'));

        if ($isa_type->has_coercion) {

            # create our coercion as a copy of the parent
            $_opt->('isa')->coercion(Moose::Meta::TypeCoercion->new(
                type_constraint   => $_opt->('isa'),
                type_coercion_map => [ @{ $isa_type->coercion->type_coercion_map } ],
            ));
        }

    }

    return;
}

sub _mxas_constraint {
    my ($class, $name, $options, $_has, $_opt, $_ref) = @_;

    return unless $_has->('constraint');

    # check for errors...
    $class->throw_error('You must specify an "isa" when declaring a "constraint"')
        if !$_has->('isa');
    $class->throw_error('"constraint" must be a CODE reference')
        if $_ref->('constraint') ne 'CODE';

    # constraint checking! XXX message, etc?
    push my @opts, constraint => $_opt->('constraint')
        if $_ref->('constraint') eq 'CODE';

    # stash our original option away and construct our new one
    my $isa         = $options->{original_isa} = $_opt->('isa');
    $options->{isa} = $_acquire_isa_tc->($isa)->create_child_type(@opts);

    return;
}


role {
    my $p = shift @_;

    method canonical_writer_prefix  => sub { $p->writer_prefix  };
    method canonical_builder_prefix => sub { $p->builder_prefix };
};

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Alders David Etheridge Graham Karen Knop Olaf Steinbrunner

=head1 NAME

MooseX::AttributeShortcuts::Trait::Attribute - Shortcuts attribute trait proper

=head1 VERSION

This document describes version 0.032 of MooseX::AttributeShortcuts::Trait::Attribute - released June 13, 2017 as part of MooseX-AttributeShortcuts.

=head1 DESCRIPTION

This is the actual attribute trait that implements
L<MooseX::AttributeShortcuts>.  You should consult that package's
documentation for information on any of the new attribute options; we're
mainly going to document the additional attributes, methods, and role
parameters that this role provides.

All methods we include that chain off of Moose's _process_options() are
prefixed with '_mxas_' and generally are not documented in the POD; we
document any internal methods of L<Moose::Meta::Attribute> that we wrap or
otherwise override we document here as well.

=head1 ROLE PARAMETERS

Parameterized roles accept parameters that influence their construction.  This role accepts the following parameters.

=head2 writer_prefix

=head2 builder_prefix

=head1 ATTRIBUTES

=head2 constraint

CodeRef, read-only.

=head2 original_isa

=head2 trigger_method

Contains the name of the method that will be invoked as a trigger.

=head1 BEFORE METHOD MODIFIERS

=head2 _process_options

Here we wrap _process_options() instead of the newer _process_is_option(), as
that makes our life easier from a Moose 1.x/2.x compatibility perspective --
and that we're generally altering more than just the 'is' option at one time.

=head1 AROUND METHOD MODIFIERS

=head2 _make_delegation_method

Here we create and install any custom accessors that have been defined.

=head1 AFTER METHOD MODIFIERS

=head2 attach_to_class

We hijack attach_to_class in order to install our anon_builder, if we have
one.  Note that we don't go the normal associate_method/install_accessor/etc
route as this is kinda...  different.  (That is, the builder is not an
accessor of this attribute, and should not be installed as such.)

=head1 METHODS

=head2 has_constraint

Predicate for the L</constraint> attribute.

=head2 has_original_isa

Predicate for the L</original_isa> attribute.

=head2 has_trigger_method

Predicate for the L</trigger_method> attribute.

=head2 canonical_writer_prefix

Returns the writer prefix; this is almost always C<set_>.

=head2 canonical_builder_prefix

Returns the builder prefix; this is almost always C<_build_>.

=head1 PREFIXES

We accept two parameters on the use of this module; they impact how builders
and writers are named.

=head2 -writer_prefix

    use MooseX::::AttributeShortcuts -writer_prefix => 'prefix';

The default writer prefix is '_set_'.  If you'd prefer it to be something
else (say, '_'), this is where you'd do that.

=head2 -builder_prefix

    use MooseX::::AttributeShortcuts -builder_prefix => 'prefix';

The default builder prefix is '_build_', as this is what lazy_build does, and
what people in general recognize as build methods.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::AttributeShortcuts|MooseX::AttributeShortcuts>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/moosex-attributeshortcuts/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
