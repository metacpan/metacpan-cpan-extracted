package MooseX::Extended::Role;

# ABSTRACT: MooseX::Extended roles

use strict;
use warnings;
use Moose::Exporter;
use MooseX::Extended::Types ':all';
use MooseX::Extended::Core qw(
  field
  param
  _debug
  _assert_import_list_is_valid
  _enabled_features
  _disabled_warnings
  _our_import
  _our_init_meta
);
use MooseX::Role::WarnOnConflict ();
use Moose::Role;
use Moose::Meta::Role;
use namespace::autoclean ();
use Import::Into;
use true;
use feature _enabled_features();
no warnings _disabled_warnings();

our $VERSION = '0.30';

# Should this be in the metaclass? It feels like it should, but
# the MOP really doesn't support these edge cases.
my %CONFIG_FOR;

sub import {
    my ( $class, %args ) = @_;
    my @caller = caller(0);
    $args{_import_type} = 'role';
    $args{_caller_eval} = ( $caller[1] =~ /^\(eval/ );
    my $target_class = _assert_import_list_is_valid( $class, \%args );
    my @with_meta    = grep { not $args{excludes}{$_} } qw(field param);
    if (@with_meta) {
        @with_meta = ( with_meta => [@with_meta] );
    }
    my ( $import, undef, undef ) = Moose::Exporter->setup_import_methods(
        @with_meta,
    );
    _our_import( $class, $import, $target_class );
}

sub init_meta ( $class, %params ) {
    my $for_class = $params{for_class};
    _our_init_meta( $class, \&_apply_default_features, %params );
    return $for_class->meta;
}

sub _apply_default_features ( $config, $for_class, $params ) {

    if ( my $types = $config->{types} ) {
        _debug("$for_class: importing types '@$types'");
        MooseX::Extended::Types->import::into( $for_class, @$types );
    }

    Carp->import::into($for_class)                 unless $config->{excludes}{carp};
    namespace::autoclean->import::into($for_class) unless $config->{excludes}{autoclean};
    true->import unless $config->{excludes}{true} || $config->{_caller_eval};    # https://github.com/Ovid/moosex-extended/pull/34
    MooseX::Role::WarnOnConflict->import::into($for_class) unless $config->{excludes}{WarnOnConflict};

    feature->import( _enabled_features() );
    warnings->unimport(_disabled_warnings);

    Moose::Role->init_meta(                                                      ##
        %$params,                                                                ##
        metaclass => 'Moose::Meta::Role'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Extended::Role - MooseX::Extended roles

=head1 VERSION

version 0.30

=head1 SYNOPSIS

    package Not::Corinna::Role::Created {
        use MooseX::Extended::Role types => ['PositiveInt'];

        field created => ( isa => PositiveInt, default => sub { time } );
    }

Similar to L<MooseX::Extended>, providing almost everything that module provides.
However, for obvious reasons, it does not include L<MooseX::StrictConstructor>
or make your class immutable, or set the C3 mro.

Note that there is no need to add a C<1> at the end of the role.

=head1 CONFIGURATION

You may pass an import list to L<MooseX::Extended::Role>.

    use MooseX::Extended::Role
      excludes => [qw/WarnOnConflict carp/],         # I don't want these features
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

=item * C<WarnOnConflict>

    use MooseX::Extended::Role excludes => ['WarnOnConflict'];

Excluding this removes the C<MooseX::Role::WarnOnConflict> role.

=item * C<autoclean>

    use MooseX::Extended::Role excludes => ['autoclean'];

Excluding this will no longer import C<namespace::autoclean>.

=item * C<carp>

    use MooseX::Extended::Role excludes => ['carp'];

Excluding this will no longer import C<Carp::croak> and C<Carp::carp>.

=item * C<true>

    use MooseX::Extended::Role excludes => ['true'];

Excluding this will require your module to end in a true value.

=item * C<param>

    use MooseX::Extended::Role excludes => ['param'];

Excluding this will make the C<param> function unavailable.

=item * C<field>

    use MooseX::Extended::Role excludes => ['field'];

Excluding this will make the C<field> function unavailable.

=back

=head2 C<includes>

Some experimental features are useful, but might not be quite what you want.

    use MooseX::Extended::Role includes => [qw/multi/];

    multi sub foo ($self, $x)      { ... }
    multi sub foo ($self, $x, $y ) { ... }

See L<MooseX::Extended::Manual::Includes> for more information.

=head1 IDENTICAL METHOD NAMES IN CLASSES AND ROLES

In L<Moose> if a class defines a method of the name as the method of a role
it's consuming, the role's method is I<silently> discarded. With
L<MooseX::Extended::Role>, you get a warning. This makes maintenance easier
when to prevent you from accidentally overriding a method.

For example:

    package My::Role {
        use MooseX::Extended::Role;

        sub name {'Ovid'}
    }

    package My::Class {
        use MooseX::Extended;
        with 'My::Role';
        sub name {'Bob'}
    }

The above code will still run, but you'll get a very verbose warning:

    The class My::Class has implicitly overridden the method (name) from
    role My::Role. If this is intentional, please exclude the method from
    composition to silence this warning (see Moose::Cookbook::Roles::Recipe2)

To silence the warning, just be explicit about your intent:

    package My::Class {
        use MooseX::Extended;
        with 'My::Role' => { -excludes => ['name'] };
        sub name {'Bob'}
    }

Alternately, you can exclude this feature. We don't recommend this, but it
might be useful if you're refactoring a legacy Moose system.

    use MooseX::Extended::Role excludes => [qw/WarnOnConflict/];

=head1 ATTRIBUTE SHORTCUTS

C<param> and C<field> in roles allow the same L<attribute
shortcuts|MooseX::Extended::Manual::Shortcuts> as L<MooseX::Extended>.

=head1 BUGS AND LIMITATIONS

If the MooseX::Extended::Role is loaded via I<stringy> eval, C<true> is not
loaded, This is because there were intermittant errors (maybe 1 out of 5
times) being thrown. Removing this feature under stringy eval solves this. See
L<this github ticket for more
infomration|https://github.com/Ovid/moosex-extended/pull/34>.

=head1 REDUCING BOILERPLATE

Let's say you've settled on the following feature set:

    use MooseX::Extended::Role
        excludes => [qw/WarnOnConflict carp/],
        includes => [qw/multi/];

And you keep typing that over and over. We've removed a lot of boilerplate,
but we've added different boilerplate. Instead, just create
C<My::Custom::Moose::Role> and C<use My::Custom::Moose::Role;>. See
L<MooseX::Extended::Role::Custom> for details.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
