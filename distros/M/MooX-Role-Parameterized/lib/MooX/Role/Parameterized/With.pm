package MooX::Role::Parameterized::With;
use v5.12;
use strict;
use warnings;

our $VERSION = '0.701'; # VERSION

# ABSTRACT: dsl to apply roles with composition parameters

use Carp                      qw(carp);
use MooX::Role::Parameterized qw();

sub import {
    my $target = caller;

    {
        my $orig = $target->can('with');
        carp "will redefine 'with' function"
          if $orig && $MooX::Role::Parameterized::VERBOSE;

        no strict 'refs';
        no warnings 'redefine';

        *{ $target . '::with' } =
          MooX::Role::Parameterized->build_apply_roles_to_package($orig);
    }
}

1;

__END__

=head1 NAME

MooX::Role::Parameterized::With - dsl to apply roles with composition parameters

=head1 SYNOPSIS

    package Tag;

    use Moo::Role;
    use MooX::Role::Parameterized;

    parameter name => ( is => 'ro', required => 1 );

    role {
        my ( $params, $mop ) = @_;

        $mop->has( $params->name => ( is => 'rw' ) );
    };

    package Article;

    use Moo;
    use MooX::Role::Parameterized::With;    # overrides Moo::with

    with Tag => [                  # apply the parameterized role twice,
        { name => 'author' },      # once per parameter set,
        { name => 'editor' },
      ],
      Tag => { name => 'status' }; # then once more on its own

    has title => ( is => 'ro' );   # continue with normal Moo code

=head1 DESCRIPTION

This package tries to offer an easy way to add parameterized roles.

Will load and apply L<MooX::Roles::Parameterized> roles, just need use this package
with a hash of role => parameters.

=head1 AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
