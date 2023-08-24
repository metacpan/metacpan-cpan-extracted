package Resource::Silo::Metadata;

use strict;
use warnings;
our $VERSION = '0.08';

=head1 NAME

Resource::Silo::Metadata - resource container metadata for L<Resource::Silo>.

=head1 DESCRIPTION

This class stores information about available resources in a specific
container class. Normally only used internally.

See also L<Resource::Silo/meta>.

=head1 METHODS

=cut

use Carp;
use Module::Load qw( load );
use Scalar::Util qw( looks_like_number reftype );
use Sub::Quote qw( quote_sub );

my $BARE_REX = '[a-z][a-z_0-9]*';
my $ID_REX   = qr(^$BARE_REX$)i;
my $MOD_REX  = qr(^$BARE_REX(?:::$BARE_REX)*$)i;

# Define possible reftypes portably
my $CODE   = reftype sub { };
my $REGEXP = ref qr/.../;
sub _is_empty { $_[0] eq '' };

=head2 new( $target )

$target is the name of the module where resource access methods will be created.

=cut

sub new {
    my ($class, $target) = @_;
    return bless {
        target  => $target,
        preload => [],
    }, $class;
};

=head2 add( $resource_name, ... )

Create resource type. See L<Resource::Silo/resource> for details.

=cut

my %known_args = (
    argument        => 1,
    class           => 1,
    dependencies    => 1,
    derived         => 1,
    cleanup         => 1,
    cleanup_order   => 1,
    fork_cleanup    => 1,
    ignore_cache    => 1,
    init            => 1,
    literal         => 1,
    preload         => 1,
    require         => 1,
);
sub add {
    my $self = shift;
    my $name = shift;
    if (@_ % 2) {
        my $init = pop @_;
        unshift @_, init => $init;
    }
    my (%spec) = @_;
    my $target = $self->{target};

    croak "resource: name must be an identifier"
        unless defined $name and !ref $name and $name =~ $ID_REX;
    croak "resource: attempt to redefine resource '$name'"
        if defined $self->{resource}{$name};
    croak "resource: attempt to replace existing method '$name' in $target"
        if $target->can($name);

    my @extra = grep { !$known_args{$_} } keys %spec;
    croak "resource '$name': unknown arguments in specification: @extra"
        if @extra;

    {
        # validate 'require' before 'class'
        if (!ref $spec{require}) {
            $spec{require} = defined $spec{require} ? [ $spec{require} ] : [];
        };
        croak "resource '$name': 'require' must be a module name or a list thereof"
            unless ref $spec{require} eq 'ARRAY';
        my @bad = grep { $_ !~ $MOD_REX } @{ $spec{require} };
        croak "resource '$name': 'require' doesn't look like module name(s): "
            .join ", ", map { "'$_'" } @bad
                if @bad;
    };

    if (defined (my $value = $spec{literal})) {
        defined $spec{$_}
            and croak "resource '$name': 'literal' is incompatible with '$_'"
                for qw( init class argument );
        $spec{init} = sub { $value };
        $spec{dependencies} //= [];
        $spec{derived}      //= 1;
    };

    _make_init_class($self, $name, \%spec)
        if (defined $spec{class});

    if (my $deps = delete $spec{dependencies}) {
        croak "resource '$name': 'dependencies' must be an array"
            unless ref $deps eq 'ARRAY';
        my @bad = grep { !/$ID_REX/ } @$deps;
        croak "resource '$name': illegal dependency name(s): "
            .join ", ", map { "'$_'" } @bad
                if @bad;
        $spec{allowdeps} = { map { $_ => 1 } @$deps };
    };

    croak "resource '$name': 'init' must be a function"
        unless ref $spec{init} and reftype $spec{init} eq $CODE;

    if (!defined $spec{argument}) {
        $spec{argument} = \&_is_empty;
    } elsif (ref $spec{argument} eq $REGEXP) {
        my $rex = qr(^(?:$spec{argument})$);
        $spec{argument} = sub { $_[0] =~ $rex };
    } elsif ((reftype $spec{argument} // '') eq $CODE) {
        # do nothing, we're fine
    } else {
        croak "resource '$name': 'argument' must be a regexp or function";
    }

    $spec{cleanup_order} //= 0;
    croak "resource '$name': 'cleanup_order' must be a number"
        unless looks_like_number($spec{cleanup_order});

    croak "resource '$name': 'cleanup*' is useless while 'ignore_cache' is in use"
        if $spec{ignore_cache} and (
            defined $spec{cleanup}
            or defined $spec{fork_cleanup}
            or $spec{cleanup_order} != 0
        );

    croak "resource '$name': 'cleanup' must be a function"
        if defined $spec{cleanup} and (reftype $spec{cleanup} // '') ne $CODE;
    croak "resource '$name': 'fork_cleanup' must be a function"
        if defined $spec{fork_cleanup} and (reftype $spec{fork_cleanup} // '') ne $CODE;

    if ($spec{preload}) {
        push @{ $self->{preload} }, $name;
    };

    $self->{resource}{$name} = \%spec;

    # Move code generation into Resource::Silo::Container
    # so that exceptions via croak() are attributed correctly.
    {
        no strict 'refs'; ## no critic Strictures
        *{"${target}::$name"} =
            Resource::Silo::Container::_make_resource_accessor($name, \%spec);
    }

    return $self;
};

sub _make_init_class {
    my ($self, $name, $spec) = @_;

    my $class = $spec->{class};
    $spec->{dependencies} //= {};

    croak "resource '$name': 'class' doesn't look like a package name: '$class'"
        unless $class =~ $MOD_REX;
    defined $spec->{$_} and croak "resource '$name': 'class' is incompatible with '$_'"
        for qw(init argument);
    croak "resource '$name': 'class' requires 'dependencies' to be a hash"
        unless ref $spec->{dependencies} eq 'HASH';

    my %deps = %{ $spec->{dependencies} };

    push @{ $spec->{require} }, $class;

    my %pass_args;
    my @realdeps;
    my @body = ("my \$c = shift;", "$class->new(" );

    # format: constructor_arg => [ resource_name, resource_arg ]
    foreach my $key (keys %deps) {
        my $entry = $deps{$key};

        if (ref $entry eq 'SCALAR') {
            # pass a literal value to the constructor
            $pass_args{$key} = $$entry;
            next;
        };

        if (defined $entry and !ref $entry) {
            # allow bareword, and alias `foo => 1` to `foo => ['foo']
            $entry = $key if $entry eq '1';
            $entry = [ $entry ];
        };
        croak "resource '$name': dependency '$key' has wrong format"
            unless (
                    ref $entry eq 'ARRAY'
                and @$entry <= 2
                and ($entry->[0] // '') =~ $ID_REX
            );
        push @realdeps, $entry->[0];

        push @body, length ($entry->[1] // '')
            ? sprintf( "\t'%s' => \$c->%s('%s'),",
                quotemeta $key, $entry->[0], quotemeta $entry->[1] )
            : sprintf( "\t'%s' => \$c->%s,", quotemeta $key, $entry->[0] );
    };
    push @body, "\t\%pass_args"
        if %pass_args;
    push @body, ");";

    $spec->{init} = quote_sub(
        "init_of_$name",
        join( "\n", @body ),
        (%pass_args ? { '%pass_args' => \%pass_args, } : {}),
        {
            no_install => 1,
            package    => $self->{target},
        }
    );
    $spec->{dependencies} = \@realdeps;
};

sub _make_dsl {
    my $inst = shift;
    return sub { $inst->add(@_) };
};

=head2 list

Returns a list (or arrayref in scalar context)
containing the names of known resources.

B<EXPERIMENTAL>. Return value structure is subject to change.

=cut

sub list {
    my $self = shift;
    my @list = sort grep { !/^-/ } keys %{ $self->{resource} };
    return wantarray ? @list : \@list;
};

=head2 self_check()

Check setup validity. Dies on errors, return C<$self> otherwise.

The following checks are available so far:

=over

=item * dependencies must be defined;

=item * required modules must be loadable.

=back

B<EXPERIMENTAL>. Interface & performed checks may change in the future.

=cut

sub self_check {
    my $self = shift;

    my $res = $self->{resource};
    foreach my $name (sort keys %$res) {
        my $entry = $res->{$name};

        my @missing_deps = grep { !$res->{$_} } keys %{ $entry->{allowdeps} || {} };
        croak "resource '$name': missing dependencies: ".
            join ", ", map { "'$_'" } @missing_deps
                if @missing_deps;

        foreach my $mod ( @{ $entry->{require} } ) {
            eval { load $mod; 1 }
                or croak "resource '$name': failed to load '$mod': $@";
        };
    };

    return $self;
};

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Konstantin Uvarin, C<< <khedin@gmail.com> >>

This program is free software.
You can redistribute it and/or modify it under the terms of either:
the GNU General Public License as published by the Free Software Foundation,
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
