package MooseX::Extended;

# ABSTRACT: Extend Moose with safe defaults and useful features

use 5.20.0;
use warnings;

use Moose::Exporter;
use Moose                     ();
use MooseX::StrictConstructor ();
use mro                       ();
use namespace::autoclean      ();
use Module::Load 'load';
use MooseX::Extended::Core qw(
  _assert_import_list_is_valid
  _debug
  _disabled_warnings
  _enabled_features
  _our_import
  _our_init_meta
  field
  param
);
use feature _enabled_features();
no warnings _disabled_warnings();
use B::Hooks::AtRuntime 'after_runtime';
use Import::Into;

our $VERSION = '0.34';

sub import {
    my ( $class, %args ) = @_;
    my @caller = caller(0);
    $args{_import_type} = 'class';
    $args{_caller_eval} = ( $caller[1] =~ /^\(eval/ );    # https://github.com/Ovid/moosex-extended/pull/34
    my $target_class = _assert_import_list_is_valid( $class, \%args );
    my @with_meta    = grep { not $args{excludes}{$_} } qw(field param);
    if (@with_meta) {
        @with_meta = ( with_meta => [@with_meta] );
    }
    my ( $import, undef, undef ) = Moose::Exporter->setup_import_methods(
        @with_meta,
        install => [qw/unimport/],
        also    => ['Moose'],
    );
    _our_import( $class, $import, $target_class );
}

# Internal method setting up exports. No public
# documentation by design
sub init_meta ( $class, %params ) {
    Moose->init_meta(%params);
    _our_init_meta( $class, \&_apply_default_features, %params );
}

# XXX we don't actually use the $params here, even though we need it for
# MooseX::Extended::Role. But we need to declare it in the signature to make
# this code work
sub _apply_default_features ( $config, $for_class, $params = undef ) {
    if ( my $types = $config->{types} ) {
        _debug("$for_class: importing types '@$types'");
        MooseX::Extended::Types->import::into( $for_class, @$types );
    }

    MooseX::StrictConstructor->import( { into => $for_class } ) unless $config->{excludes}{StrictConstructor};
    Carp->import::into($for_class)                              unless $config->{excludes}{carp};
    namespace::autoclean->import::into($for_class)              unless $config->{excludes}{autoclean};

    unless ( $config->{excludes}{immutable} or $config->{_caller_eval} ) {    # https://github.com/Ovid/moosex-extended/pull/34

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
    unless ( $config->{excludes}{true} or $config->{_caller_eval} ) {    # https://github.com/Ovid/moosex-extended/pull/34
        eval {
            load true;
            true->import::into($for_class);                              # no need for `1` at the end of the module
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

version 0.34

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
known bugs. We believe it's ready for production, but make no promises.

This is a quick overview. See L<MooseX::Extended::Manual::Tutorial> for more
information.

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
        use feature qw( signatures postderef postderef_qq );
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
intended to be passed to the constructor.

B<Note>: the C<has> function is still available, even if it's not needed.
Unlike C<param> and C<field>, it still requires an C<is> option.

Also, while your author likes the postfix block syntax, it's not required. You
can even safely inline multiple packages in the same file:

    package My::Point;
    use MooseX::Extended types => 'Num';

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
if you have a C<croak> method, our importing of C<Carp::croak> will be a
problem.

A single argument to C<excludes> can be a string. Multiple C<excludes> require
an array reference:

        use MooseX::Extended excludes => [qw/StrictConstructor autoclean/];

You can exclude the following:

=over 4

=item * C<StrictConstructor>

    use MooseX::Extended excludes => 'StrictConstructor';

Excluding this will no longer import C<MooseX::StrictConstructor>.

=item * C<autoclean>

    use MooseX::Extended excludes => 'autoclean';

Excluding this will no longer import C<namespace::autoclean>.

=item * C<c3>

    use MooseX::Extended excludes => 'c3';

Excluding this will no longer apply the C3 mro.

=item * C<carp>

    use MooseX::Extended excludes => 'carp';

Excluding this will no longer import C<Carp::croak> and C<Carp::carp>.

=item * C<immutable>

    use MooseX::Extended excludes => 'immutable';

Excluding this will no longer make your class immutable.

=item * C<true>

    use MooseX::Extended excludes => 'true';

Excluding this will require your module to end in a true value.

=item * C<param>

    use MooseX::Extended excludes => 'param';

Excluding this will make the C<param> function unavailable.

=item * C<field>

    use MooseX::Extended excludes => 'field';

Excluding this will make the C<field> function unavailable.

=back

=head2 C<includes>

Several I<optional> features of L<MooseX::Extended> make this module much more
powerful. For example, to include try/catch and a C<method> keyword:

        use MooseX::Extended includes => [ 'method', 'try' ];

A single argument to C<includes> can be a string. Multiple C<includes> require
an array reference:

        use MooseX::Extended includes => [qw/method try/];

See L<MooseX::Extended::Manual::Includes> for more information.

=head1 REDUCING BOILERPLATE

Let's say you've settled on the following feature set:

    use MooseX::Extended
      excludes => [qw/StrictConstructor carp/],
      includes => 'method',
      types    => ':Standard';

And you keep typing that over and over. We've removed a lot of boilerplate,
but we've added different boilerplate. Instead, just create
C<My::Custom::Moose> and C<use My::Custom::Moose;>. See
L<MooseX::Extended::Custom> for details.

=head1 IMMUTABILITY

=head2 Making Your Class Immutable

You no longer need to end your Moose classes with:

    __PACKAGE__->meta->make_immutable;

That prevents further changes to the class and provides some optimizations to
make the code run much faster. However, it's somewhat annoying to type. We do
this for you, via L<B::Hooks::AtRuntime>. You no longer need to do this yourself.

=head2 Making Your Instance Immutable

By default, attributes defined via C<param> and C<field> are read-only.
However, if they contain a reference, you can fetch the reference, mutate it,
and now everyone with a copy of that reference has mutated state.

To handle that, we offer a new C<< clone => $clone_type >> pair for attributes.

See the L<MooseX::Extended::Manual::Cloning> documentation.

=head1 OBJECT CONSTRUCTION

Object construction for L<MooseX::Extended> is identical to Moose because
MooseX::Extended I<is> Moose, so no changes are needed.  However, in addition
to C<has>, we also provide C<param> and C<field> attributes, both of which are
C<< is => 'ro' >> by default.

The C<param> is I<required>, whether by passing it to the constructor, or using
C<default> or C<builder>.

The C<field> is I<forbidden> in the constructor and is lazy if it has a
builder, because that builder is often dependent on attributes set in the
constructor (and why call it if it's not used?).

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

You can also do this:

    param name ( isa => NonEmptyStr, builder => sub {...} );

That's the same as:

    param name ( isa => NonEmptyStr, builder => '_build_name' );

    sub _build_name {...}

See L<MooseX::Extended::Manual::Shortcuts> for a full explanation.

=head1 INVALID ATTRIBUTE DEFINITIONS

The following L<Moose> code will print C<WhoAmI>. However, the second attribute
name is clearly invalid.

    package Some::Class {
        use Moose;

        has name   => ( is => 'ro' );
        has '-bad' => ( is => 'ro' );
    }

    my $object = Some::Class->new( name => 'WhoAmI' );
    say $object->name;

C<MooseX::Extended> will throw a
L<Moose::Exception::InvalidAttributeDefinition> exception if it encounters an
illegal method name for an attribute.

This also applies to various attributes which allow method names, such as
C<clone>, C<builder>, C<clearer>, C<writer>, C<reader>, and C<predicate>.

Trying to pass a defined C<init_arg> to C<field> will also throw this
exception, unless the init_arg begins with an underscore. (It is sometimes
useful to be able to define an C<init_arg> for unit testing.)

=head1 BUGS AND LIMITATIONS

You cannot (at this time) use C<multi> subs with the debugger. This is due to
a bug in L<Syntax::Keyword::MultiSub> that should be fixed in the next release
of that module.

If you must have multisubs and the debugger, the follow patch to
L<Syntax::Keyword::MultiSub> fixes the issue:

    --- old/lib/Syntax/Keyword/MultiSub.xs  2021-12-16 10:59:30 +0000
    +++ new/lib/Syntax/Keyword/MultiSub.xs  2022-08-12 10:23:06 +0000
    @@ -129,6 +129,7 @@
     redo:
         switch(o->op_type) {
           case OP_NEXTSTATE:
    +      case OP_DBSTATE:
             o = o->op_next;
             goto redo;

See also:

=over 4

=item * L<The github issue|https://github.com/Ovid/moosex-extended/issues/45>

=back

=head1 MANUAL

=over 4

=item * L<MooseX::Extended::Manual::Tutorial>

=item * L<MooseX::Extended::Manual::Overview>

=item * L<MooseX::Extended::Manual::Construction>

=item * L<MooseX::Extended::Manual::Includes>

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

=head1 SEE ALSO

=over 4

=item * L<Corinna|https://github.com/Ovid/Cor>

The RFC of the new version of OOP planned for the Perl core.

=item * L<MooseX::Modern|https://metacpan.org/pod/MooseX::Modern>

MooseX::Modern - Precision classes for Modern Perl

=item * L<Zydeco|https://metacpan.org/pod/Zydeco>

Zydeco - Jazz up your Perl

=item * L<Dios|https://metacpan.org/pod/Dios>

Dios - Declarative Inside-Out Syntax

=item * L<MooseX::AttributeShortcuts|https://metacpan.org/pod/MooseX::AttributeShortcuts>

MooseX::AttributeShortcuts - Shorthand for common attribute options

=back

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
