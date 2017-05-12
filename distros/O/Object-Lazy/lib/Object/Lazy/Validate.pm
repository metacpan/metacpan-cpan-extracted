package Object::Lazy::Validate; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.12';

use Params::Validate qw(:all);

sub validate_new { ## no critic (ArgUnpacking)
    return validate_with(
        params => \@_,
        spec   => [
            {type => SCALAR},
            {type => CODEREF | HASHREF},
        ],
        stack_skip => 1,
    );
}

# check and modify params
sub init {
    my $params = shift;

    if (ref $params eq 'CODE') {
        $params = {
            build => $params,
        };
    }

    return validate_with(
        params => $params,
        spec   => {
            build        => {type => CODEREF},
            isa          => {type => SCALAR | ARRAYREF, default => []},
            DOES         => {type => SCALAR | ARRAYREF, default => []},
            VERSION      => {type => SCALAR | OBJECT, optional => 1},
            version_from => {type => SCALAR, optional => 1},
            logger       => {type => CODEREF, optional => 1},
            ref          => {
                type      => SCALAR,
                optional  => 1,
                callbacks => {
                    'depends use Object::Lazy::Ref' => sub {
                        $Object::Lazy::Ref::VERSION;
                    }
                }
            },
        },
        called => 'the 2nd parameter hashref',
    );
};

# $Id$

1;

__END__

=pod

=head1 NAME

Object::Lazy::Validate - validator and initializer for Object::Lazy

=head1 VERSION

0.12

=head1 SYNOPSIS

    use Object::Lazy::Validate;

    my ($class, $params) = Object::Lazy::Validate::validate_new(@_);

    $params = Object::Lazy::Validate::init($params);

=head1 DESCRIPTION

Validator and initializer for Object::Lazy

=head1 SUBROUTINES/METHODS

=head2 sub validate_new

Validator for the constructor of the package Object::Lazy.

=head2 sub init

Initializer for the constructor of the package ObjectLazy.

=head1 DIAGNOSTICS

Validator and initializer can confess at false parameters.

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Params::Validate|Params::Validate>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2012,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
