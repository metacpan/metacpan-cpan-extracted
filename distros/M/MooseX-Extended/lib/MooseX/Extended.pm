package MooseX::Extended;

# ABSTRACT: Extend Moose with safe defaults and useful features

use 5.20.0;
use warnings;

use Moose::Exporter;
use MooseX::Extended::Types ':all';
use Moose                     ();
use MooseX::StrictConstructor ();
use mro                       ();
use namespace::autoclean      ();
use Moose::Util 'throw_exception';
use Module::Load 'load';
use MooseX::Extended::Core qw(
  field
  param
  _debug
  _enabled_features
  _disabled_warnings
);
use feature _enabled_features();
use B::Hooks::AtRuntime 'after_runtime';
use Import::Into;

no warnings _disabled_warnings();

our $VERSION = '0.10';

my ( $import, undef, $init_meta ) = Moose::Exporter->setup_import_methods(
    with_meta => [ 'field', 'param' ],
    install   => [qw/unimport/],
    also      => ['Moose'],
);

# Should this be in the metaclass? It feels like it should, but
# the MOP really doesn't support these edge cases.
my %CONFIG_FOR;

sub import {
    my ( $class, %args ) = @_;
    my ( $package, $filename, $line ) = caller;
    state $check = compile_named(
        debug    => Optional [Bool],
        types    => Optional [ ArrayRef [NonEmptyStr] ],
        excludes => Optional [
            ArrayRef [
                Enum [
                    qw/
                      StrictConstructor
                      autoclean
                      c3
                      carp
                      immutable
                      true
                      /
                ]
            ]
        ],
    );
    eval {
        $check->(%args);
        1;
    } or do {

        # Not sure what's happening, but if we don't use the eval to trap the
        # error, it gets swallowed and we simply get:
        #
        # BEGIN failed--compilation aborted at ...
        my $error = $@;
        Carp::carp(<<"END");
Error:    Invalid import list to MooseX::Extended.
Package:  $package
Filename: $filename
Line:     $line
Details:  $error
END
        throw_exception(
            'InvalidImportList',
            class_name           => $package,
            moosex_extended_type => __PACKAGE__,
            line_number          => $line,
            messsage             => $error,
        );
    };

    # remap the arrays to hashes for easy lookup
    $args{excludes} = { map { $_ => 1 } $args{excludes}->@* };

    $CONFIG_FOR{$package} = \%args;
    @_ = $class;                       # anything else and $import blows up
    goto $import;
}

# Internal method setting up exports. No public
# documentation by design
sub init_meta ( $class, %params ) {
    my $for_class = $params{for_class};
    Moose->init_meta(%params);

    my $config = $CONFIG_FOR{$for_class};

    if ( $config->{debug} ) {
        $MooseX::Extended::Debug = $config->{debug};
    }
    if ( exists $config->{excludes} ) {
        foreach my $category ( sort keys $config->{excludes}->%* ) {
            _debug("$for_class exclude '$category'");
        }
    }

    if ( my $types = $config->{types} ) {
        _debug("$for_class: importing types '@$types'");
        MooseX::Extended::Types->import::into( $for_class, @$types );
    }

    MooseX::StrictConstructor->import( { into => $for_class } )
      unless $config->{excludes}{StrictConstructor};

    Carp->import::into($for_class)
      unless $config->{excludes}{carp};

    namespace::autoclean->import::into($for_class)
      unless $config->{excludes}{autoclean};

    # see perldoc -v '$^P'
    if ($^P) {
        say STDERR "We are running under the debugger or using code that uses debugger code (e.g., Devel::Cover). $for_class is not immutable";
    }
    else {
        unless ( $config->{excludes}{immutable} ) {

            # after_runtime is loaded too late under the debugger
            eval {
                load B::Hooks::AtRuntime, 'after_runtime';
                after_runtime {
                    $for_class->meta->make_immutable;
                    if ( $config->{debug} ) {

                        # they're doing debug on a class-by-class basis, so
                        # turn this off after the class compiles
                        $MooseX::Extended::Debug = 0;
                    }
                };
                1;
            } or do {
                my $error = $@;
                warn
                  "Could not load 'B::Hooks::AtRuntime': $error. You class is not immutable. You can `use MooseX::Extended excludes => ['immutable'];` to suppress this warning.";
            };
        }
    }
    unless ( $config->{excludes}{true} ) {
        eval {
            load true;
            true->import;    # no need for `1` at the end of the module
            1;
        } or do {
            my $error = $@;
            warn
              "Could not load 'true': $error. Your class must end in a true value. You can `use MooseX::Extended excludes => ['true'];` to suppress this warning.";
        };
    }

    # If we never use multiple inheritance, this should not be needed.
    mro::set_mro( $for_class, 'c3' )
      unless $config->{excludes}{c3};

    feature->import( _enabled_features() );
    warnings->unimport(_disabled_warnings);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Extended - Extend Moose with safe defaults and useful features

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    package My::Names {
        use MooseX::Extended types => [qw(compile Num NonEmptyStr Str PositiveInt ArrayRef)];
        use List::Util 'sum';

        # the distinction between `param` and `field` makes it easier to
        # see which are available to `new`
        param _name => ( isa => NonEmptyStr, init_arg => 'name' );
        param title => ( isa => Str,         required => 0 );

        # forbidden in the constructor
        field created => ( isa => PositiveInt, default => sub {time} );

        sub name ($self) {
            my $title = $self->title;
            my $name  = $self->_name;
            return $title ? "$title $name" : $name;
        }

        sub add ( $self, $args ) {
            state $check = compile( ArrayRef [ Num, 1 ] );    # at least one number
            ($args) = $check->($args);
            return sum( $args->@* );
        }

        sub warnit ($self) {
            carp("this is a warning");
        }
    }

=head1 DESCRIPTION

This module is B<BETA> code. It's feature-complete for release and has no
known bugs.

This class attempts to create a safer version of Moose that defaults to
read-only attributes and is easier to read and write.

It tries to bring some of the lessons learned from L<the Corinna
project|https://github.com/Ovid/Cor>, while acknowledging that you can't
always get what you want (such as true encapsulation and true methods).

This:

    package My::Class {
        use MooseX::Extended;

        ... your code here
    }

Is sort of the equivalent to:

    package My::Class {
        use v5.20.0;
        use Moose;
        use MooseX::StrictConstructor;
        use feature qw( signatures postderef postderef_qq);
        no warnings qw( experimental::signatures experimental::postderef );
        use namespace::autoclean;
        use Carp;
        use mro 'c3';

        ... your code here

        __PACKAGE__->meta->make_immutable;
    }
    1;

It also exports two functions which are similar to Moose C<has>: C<param> and
C<field>.

A C<param> is a required parameter (defaults may be used). A C<field> is not
allowed to be passed to the constructor.

Note that the C<has> function is still available, even if it's not needed.

Also, while your author likes the postfix block syntax, it's not required. You
can even safely inline multiple packages in the same file:

    package My::Point;
    use MooseX::Extended types => [qw/Num/];

    param [ 'x', 'y' ] => ( isa => Num );

    package My::Point::Mutable;
    use MooseX::Extended;
    extends 'My::Point';

    param [ '+x', '+y' ] => ( writer => 1, clearer => 1, default => 0 );

    sub invert ($self) {
        my ( $x, $y ) = ( $self->x, $self->y );
        $self->set_x($y);
        $self->set_y($x);
    }

# MooseX::Extended will cause this to return true, even if we try to return
# false
0;

=head1 CONFIGURATION

You may pass an import list to L<MooseX::Extended>.

    use MooseX::Extended
      excludes => [qw/StrictConstructor carp/],      # I don't want these features
      types    => [qw/compile PositiveInt HashRef/]; # I want these type tools

=head2 C<types>

Allows you to import any types provided by L<MooseX::Extended::Types>.

This:

    use MooseX::Extended::Role types => [qw/compile PositiveInt HashRef/];

Is identical to this:

    use MooseX::Extended::Role;
    use MooseX::Extended::Types qw( compile PositiveInt HashRef );

=head2 C<excludes>

You may find some features to be annoying, or even cause potential bugs (e.g.,
if you have a `croak` method, our importing of C<Carp::croak> will be a
problem. You can exclude the following:

=over 4

=item * C<StrictConstructor>

    use MooseX::Extended::Role excludes => ['StrictConstructor'];

Excluding this will no longer import C<MooseX::StrictConstructor>.

=item * C<autoclean>

    use MooseX::Extended::Role excludes => ['autoclean'];

Excluding this will no longer import C<namespace::autoclean>.

=item * C<c3>

    use MooseX::Extended::Role excludes => ['c3'];

Excluding this will no longer apply the C3 mro.

=item * C<carp>

    use MooseX::Extended::Role excludes => ['carp'];

Excluding this will no longer import C<Carp::croak> and C<Carp::carp>.

=item * C<immutable>

    use MooseX::Extended::Role excludes => ['immutable'];

Excluding this will no longer make your class immutable.

=item * C<true>

    use MooseX::Extended::Role excludes => ['carp'];

Excluding this will require your module to end in a true value.

=back

=head1 IMMUTABILITY

=head2 Making Your Class Immutable

You no longer need to end your Moose classes with:

    __PACKAGE__->meta->make_immutable;

That prevents further changes to the class and provides some optimizations to
make the code run much faster. However, it's somewhat annoying to type. We do
this for you, via C<B::Hooks::AtRuntime>. You no longer need to do this yourself.

=head2 Making Your Instance Immutable

By default, attributes defined via C<param> and C<field> are read-only.
However, if they contain a reference, you can fetch the reference, mutate it,
and now everyone with a copy of that reference has mutated state.

To handle that, we offer a new C<< clone => $clone_type >> pair for attributes.

See the L<MooseX::Extended::Manual::Cloning> documentation.

=head1 OBJECT CONSTRUCTION

Objection construction for L<MooseX::Extended> is like Moose, so no
changes are needed.  However, in addition to C<has>, we also provide C<param>
and C<field> attributes, both of which are C<< is => 'ro' >> by default.

The C<param> is I<required>, whether by passing it to the constructor, or using
C<default> or C<builder>.

The C<field> is I<forbidden> in the constructor and lazy by default.

Here's a short example:

    package Class::Name {
        use MooseX::Extended types => [qw(compile Num NonEmptyStr Str)];

        # these default to 'ro' (but you can override that) and are required
        param _name => ( isa => NonEmptyStr, init_arg => 'name' );
        param title => ( isa => Str,         required => 0 );

        # fields must never be passed to the constructor
        # note that ->title and ->name are guaranteed to be set before
        # this because fields are lazy by default
        field name => (
            isa     => NonEmptyStr,
            default => sub ($self) {
                my $title = $self->title;
                my $name  = $self->_name;
                return $title ? "$title $name" : $name;
            },
        );
    }

See L<MooseX::Extended::Manual::Construction> for a full explanation.

=head1 ATTRIBUTE SHORTCUTS

When using C<field> or C<param>, we have some attribute shortcuts:

    param name => (
        isa       => NonEmptyStr,
        writer    => 1,   # set_name
        reader    => 1,   # get_name
        predicate => 1,   # has_name
        clearer   => 1,   # clear_name
        builder   => 1,   # _build_name
    );

    sub _build_name ($self) {
        ...
    }

See L<MooseX::Extended::Manual::Shortcuts> for a full explanation.

=head1 INVALID ATTRIBUTE NAMES

The following L<Moose> code will print C<WhoAmI>. However, the second attribute
name is clearly invalid.

    package Some::Class {
        use Moose;

        has name   => ( is => 'ro' );
        has '-bad' => ( is => 'ro' );
    }

    my $object = Some::Class->new( name => 'WhoAmI' );
    say $object->name;

C<MooseX::Extended> will throw a C<Moose::Exception::InvalidAttributeDefinition> exception
if it encounters an illegal method name for an attribute.

This also applies to various attributes which allow method names, such as
C<clone>, C<builder>, C<clearer>, C<writer>, C<reader>, and C<predicate>.

=head1 DEBUGGER SUPPORT

When running L<MooseX::Extended> under the debugger, there are some
behavioral differences you should be aware of.

=over 4

=item * Your classes won't be immutable

Ordinarily, we call C<< __PACKAGE__->meta->make_immutable >> for you. This
relies on L<B::Hooks::AtRuntime>'s C<after_runtime> function. However, that
runs too late under the debugger and dies. Thus, we disable this feature under
the debugger. Your classes may run a bit slower, but hey, it's the debugger!

=item * C<namespace::autoclean> will frustrate you

It's very frustrating when running under the debugger and doing this:

	13==>       my $total = sum(3,4,5);
	DB<4>
	Undefined subroutine &main::sum called at (eval 423) ...

We had removed C<namespace::autoclean> when running under the debugger, but
backed that out: L<https://github.com/Ovid/moosex-extreme/issues/11>.

=back

=head1 MANUAL

=over 4

=item * L<MooseX::Extended::Manual::Overview>

=item * L<MooseX::Extended::Manual::Construction>

=item * L<MooseX::Extended::Manual::Shortcuts>

=item * L<MooseX::Extended::Manual::Cloning>

=back

=head1 RELATED MODULES

=over 4

=item * L<MooseX::Extended::Types> is included in the distribution.

This provides core types for you.

=item * L<MooseX::Extended::Role> is included in the distribution.

C<MooseX::Extended>, but for roles.

=back

=head1 TODO

Some of this may just be wishful thinking. Some of this would be interesting if
others would like to collaborate.

=head2 Tests

Tests! Many more tests! Volunteers welcome :)

=head2 Configurable Types

We provide C<MooseX::Extended::Types> for convenience, along with the C<declare> 
function. We should write up (and test) examples of extending it.

=head2 C<BEGIN::Lift>

This idea maybe belongs in C<MooseX::Extended::OverKill>, but ...

Quite often you see things like this:

    BEGIN { extends 'Some::Parent' }

Or this:

    sub serial_number; # required by a role, must be compile-time
    has serial_number => ( ... );

In fact, there are a variety of Moose functions which would work better if
they ran at compile-time instead of runtime, making them look a touch more
like native functions. My various attempts at solving this have failed, but I
confess I didn't try too hard.

=head1 NOTES

There are a few things you might be interested to know about this module when
evaluating it.

Most of this is written with bog-standard L<Moose>, so there's nothing
terribly weird inside, but you may wish to note that we use
L<B::Hooks::AtRuntime> and L<true>. They seem sane, but I<caveat emptor>.

This module was originally released on github as C<MooseX::Extreme>, but
enough people pointed out that it was not extreme at all. That's why the
repository is L<https://github.com/Ovid/moosex-extreme/>.

=head1 SEE ALSO

=over 4

=item * L<MooseX::Modern|https://metacpan.org/pod/MooseX::Modern>

=item * L<Corinna|https://github.com/Ovid/Cor>

=back

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
