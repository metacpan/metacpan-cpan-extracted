package MooX::Role::Parameterized;

use strict;
use warnings;

# ABSTRACT: MooX::Role::Parameterized - roles with composition parameters

use Module::Runtime qw(use_module);
use Carp            qw(carp croak);
use Exporter        qw(import);
use Moo::Role       qw();
use MooX::BuildClass;
use MooX::Role::Parameterized::Mop;

our $VERSION = "0.501";

our @EXPORT = qw(parameter role apply apply_roles_to_target);

our $VERBOSE = 0;

our %INFO;

sub apply {
    carp "apply method is deprecated, please use 'apply_roles_to_target'"
      if $VERBOSE;

    goto &apply_roles_to_target;
}

sub apply_roles_to_target {
    my ( $role, $args, %extra ) = @_;

    croak
      "unable to apply parameterized role: not an MooX::Role::Parameterized"
      if !__PACKAGE__->is_role($role);

    $args = [$args] if ref($args) ne ref( [] );

    my $target = defined( $extra{target} ) ? $extra{target} : (caller)[0];

    if (   exists $INFO{$role}
        && exists $INFO{$role}{code_for}
        && ref $INFO{$role}{code_for} eq "CODE" )
    {
        my $mop = MooX::Role::Parameterized::Mop->new(
            target => $target,
            role   => $role
        );

        my $parameter_definition_klass =
          _fetch_parameter_definition_klass($role);

        foreach my $params ( @{$args} ) {
            if ( defined $parameter_definition_klass ) {
                eval { $params = $parameter_definition_klass->new($params); };

                croak(
                    "unable to apply parameterized role '${role}' to '${target}': $@"
                ) if $@;
            }

            $INFO{$role}{code_for}->( $params, $mop );
        }
    }

    Moo::Role->apply_roles_to_package( $target, $role );
}

sub role(&) {    ##no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $package = (caller)[0];

    $INFO{$package} ||= { is_role => 1 };

    croak "role subroutine called multiple times on '$package'"
      if exists $INFO{$package}{code_for};

    $INFO{$package}{code_for} = shift;
}

sub parameter {
    my $package = (caller)[0];

    $INFO{$package} ||= { is_role => 1 };

    push @{ $INFO{$package}{parameters_definition} ||= [] }, \@_;
}

sub is_role {
    my ( $klass, $role ) = @_;

    return !!( $INFO{$role} && $INFO{$role}->{is_role} );
}

sub build_apply_roles_to_package {
    my ( $klass, $orig ) = @_;

    return sub {
        my $target = (caller)[0];

        while (@_) {
            my $role = shift;

            eval { use_module($role) };

            if ( MooX::Role::Parameterized->is_role($role) ) {
                my $params = [ {} ];

                if ( @_ && ref $_[0] ) {
                    $params = shift;

                    $params = [$params] if ref($params) ne ref( [] );
                }

                foreach my $args ( @{$params} ) {
                    $role->apply_roles_to_target( $args, target => $target );
                }

                next;
            }

            if ( defined $orig && ref $orig eq 'CODE' ) {
                $orig->($role);

                next;
            }

            if ( Moo::Role->is_role($role) ) {
                Moo::Role->apply_roles_to_package( $target, $role );
                eval {
                    Moo::Role->_maybe_reset_handlemoose($target);    ##no critic(Subroutines::ProtectPrivateSubs)
                };

                next;
            }

            croak "Can't apply role to '${target}' - '${role}' is neither a "
              . "MooX::Role::Parameterized, Moo::Role or Role::Tiny role";
        }
    };
}


sub _fetch_parameter_definition_klass {
    my $role = shift;

    return if !exists $INFO{$role};

    if ( !exists $INFO{$role}{parameter_definition_klass} ) {
        return if !exists $INFO{$role}{parameters_definition};

        my $parameters_definition = $INFO{$role}{parameters_definition};

        $INFO{$role}{parameter_definition_klass} =
          _create_parameters_klass( $role, $parameters_definition );

        delete $INFO{$role}{parameters_definition};
    }

    return $INFO{$role}{parameter_definition_klass};
}

sub _create_parameters_klass {
    my ( $package, $parameters_definition ) = @_;

    my $klass = "${package}::__MOOX_ROLE_PARAMETERIZED_PARAMS__";

    return $klass if $klass->isa("Moo::Object");

    my @klass_definition = ( extends => "Moo::Object" );

    foreach my $parameter_definition ( @{$parameters_definition} ) {
        push @klass_definition, has => $parameter_definition;
    }

    BuildClass $klass => @klass_definition;

    return $klass;
}

1;
__END__

=head1 NAME

MooX::Role::Parameterized - roles with composition parameters

=head1 SYNOPSIS

    package Counter;
    use Moo::Role;
    use MooX::Role::Parameterized;    
    use Types::Standard qw( Str );

    parameter name => (
        is       => 'ro',  # this is mandatory on Moo
        isa      => Str,   # optional type
        required => 1,     # mark the parameter "name" as "required"
    );

    role {
        my ( $p, $mop ) = @_;

        my $name = $p->name; # $p->{name} will also work
    
        $mop->has($name => (
            is      => 'rw',
            default => sub { 0 },
        ));
    
        $mop->method("increment_$name" => sub {
            my $self = shift;
            $self->$name($self->$name + 1);
        });
    
        $mop->method("reset_$name" => sub {
            my $self = shift;
            $self->$name(0);
        });
    };
    
    package MyGame::Weapon;
    use Moo;
    use MooX::Role::Parameterized::With;
    
    with Counter => {          # injects 'enchantment' attribute and
        name => 'enchantment', # methods increment_enchantment ( +1 )
    };                         # reset_enchantment (set to zero)
    
    package MyGame::Wand;
    use Moo;
    use MooX::Role::Parameterized::With;

    with Counter => {         # injects 'zapped' attribute and
        name => 'zapped',     # methods increment_zapped ( +1 )
    };                        # reset_zapped (set to zero)

=head1 DESCRIPTION

It is an B<experimental> port of L<MooseX::Role::Parameterized> to L<Moo>.

=head1 FUNCTIONS

This package exports the following subroutines: C<parameter>, C<role>, C<apply_roles_to_target> and C<apply>.

=head2 parameter

This function receive the same parameter as C<Moo::has>. If present, the parameter hash reference will be blessed as a Moo class. This is useful to add default values or set some parameters as required.

=head2 role

This function accepts just B<one> code block. Will execute this code then we apply the Role in the 
target classand will receive the parameter hash reference + one B<mop> object.

The B<params> reference will be blessed if there is some parameter defined on this role.

The B<mop> object is a proxy to the target class. 

It offer a better way to call C<has>, C<after>, C<before>, C<around>, C<with> and C<requires> without side effects. 

Use C<method> to inject a new method and C<meta> to access TARGET_PACKAGE->meta

Please use:

  my ($params, $mop) = @_;
  ...
  $mop->has($params->{attribute} =>(...));

  $mop->method(name => sub { ... });

  $mop->meta->make_immutable;

=head2 apply

Alias to C<apply_roles_to_target>

=head2 apply_roles_to_target

When called, will apply the C</role> on the current package. The behavior depends of the parameter list.

This will install the role in the target package. Does not need call C<with>.

Important, if you want to apply the role multiple times, like to create multiple attributes, please pass an B<arrayref>.

    package FooWith;

    use Moo;
    use MooX::Role::Parameterized::With; # overrides Moo::with

    with "Bar" => {           # apply parameterized role Bar once
        attr => 'baz',
        method => 'run'
    }, "Other::Role" => [     # apply parameterized role "Other::Role" twice
        { ... },              # with different parameters
        { ... },
    ],
    "Other::Role" => { ...},  # apply it again
    "Some::Moo::Role",
    "Some::Role::Tiny";

    has foo => ( is => 'ro'); # continue with normal Moo code

=head1 STATIC METHOS

=head2 is_role

Returns true if the package is a L<MooX::Role::Parameterized>.

  MooX::Role::Parameterized->is_role("My::Role");

=head1 DEPRECATED FUNCTIONS

=head2 hasp

Removed

=head2 method

Removed

=head1 VARIABLES

=head2 MooX::Role::Parameterized::VERBOSE

By setting C<$MooX::Role::Parameterized::VERBOSE> with some true value we will carp on certain conditions 
(method override, unable to load package, etc).

Default is false.

=head1 MooX::Role::Parameterized::With

See L<MooX::Role::Parameterized::With> package to easily load and apply roles.

Allow to do this:

    package FooWith;

    use Moo;
    use MooX::Role::Parameterized::With; # overrides Moo::with

    with "Bar" => {           # apply parameterized role Bar once
        attr => 'baz',
        method => 'run'
    }, "Other::Role" => [     # apply parameterized role "Other::Role" twice
        { ... },              # with different parameters
        { ... },
      ],
      "Some::Moo::Role",
      "Some::Role::Tiny";

    has foo => ( is => 'ro'); # continue with normal Moo code

=head1 SEE ALSO

L<MooseX::Role::Parameterized> - Moose version

=head1 THANKS

=over

=item *

FGA <fabrice.gabolde@gmail.com>

=item *

PERLANCAR <perlancar@gmail.com>

=item *

CHOROBA <choroba@cpan.org>

=item *

Ed J <mohawk2@users.noreply.github.com>

=back

=head1 LICENSE

The MIT License
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software
 without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to
 whom the Software is furnished to do so, subject to the
 following conditions:
  
  The above copyright notice and this permission notice shall
  be included in all copies or substantial portions of the
  Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
   WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR
   PURPOSE AND NONINFRINGEMENT. IN NO EVENT
   SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
