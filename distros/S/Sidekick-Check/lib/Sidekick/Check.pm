#!/usr/bin/perl
package Sidekick::Check;
{
  $Sidekick::Check::VERSION = '0.0.1';
}

use v5.10;

use strict;
use warnings;

use Module::Pluggable::Object ();

my $package = __PACKAGE__;

# for internal functions
my $parse_args;

sub new { return $package; }

sub is { return 0 + !( shift->errors( @_ ) ); }

sub errors {
    my $self   = shift;
    my $value  = shift;
    my @checks = @_;
    my @errors;

    for my $check ( @checks ) {
        my ($method, $name, @args) = $check->$parse_args( $value );
        next if $self->$method( @args );
        push @errors, $name;
        last unless wantarray;
    }

    return wantarray ? @errors : shift @errors;
}

# dinamically add is_* methods based on plugins
my $finder = Module::Pluggable::Object->new(
        'package' => $package, 'require' => 1,
    );

{
    no strict 'refs';
    for my $plugin ( $finder->plugins ) {
        my $check = $plugin->can('check')
            || next;
        my $method = join( '::', ( split '::', lc $plugin )[3,] );
        *{ sprintf '%s::is_%s', $package, $method } = $check;
    }
}

# internal functions

$parse_args = sub {
    my $method = shift;
    my $value  = shift;
    my $name   = shift;
    my @args;

    given ( ref $method ) {
        when ( 'ARRAY' ) {
            ($method, @args) = @{ $method };
            return $method->$parse_args( $value, undef, @args );
        }
        when ( 'HASH' ) {
            ($method, $name, my $args) = @{ $method }{ qw(is name args) };
            return $method->$parse_args( $value, $name, $args || ()  );
        }
        when ( 'CODE'  ) { }
        when ( '' ) {
            $name   ||= $method;
            $method   = join( '_', 'is', $method );
        }
        default {
            die 'unssupported'
        }
    }

    return ( $method, $name, $value, @args );
};

1;
# ABSTRACT: Plugin based validation mechanism
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Sidekick::Check - Plugin based validation mechanism

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

    my $sc = Sidekick::Check->new();

    my $ok       = $sc->is( $value, 'filled', [ 'length', 10 ] );
    my @errors   = $sc->errors( $value, 'defined', sub { $_[1] eq 'test' } );
    my $lengthok = $sc->is_length( $value, 10 );

=head1 DESCRIPTION

C<Sidekick::Check> provides a simple interface to handle validations and the ability to add additional plugins in a easy manner.

=head1 METHODS

=head2 new

Returns 'Sidekick::Check'.

=head2 is

    my $ok = $sc->is( $value, @checks );

Returns 1 if all checks passed.

See L</errors>.

=head2 errors

    my @errors = $sc->errors( $value, 'defined', sub { $_[1] =~ /^\w+$/ }, )
    my $error  = $sc->errors(
            $value,
            [ 'length', 10 ],
            {
                'is'   => \&sub,
                'args' => [ 1, 2 ],
                'name' => 'special_test',
            },
        );

Returns an array of failed checks. In SCALAR context, returns the first error and exits.

=head3 Allowed check types:

=head4 ARRAY

    @errors = $sc->errors( ..., [ 'length', 10 ] );
    @errors = $sc->errors( ..., [ \&sub, 1, 2, 3 ] );

An array ref with the check to use and the arguments to pass.

=head4 CODE

    @errors = $sc->errors( ..., \&sub );
    @errors = $sc->errors( ..., sub { ... } );

An anonymous subroutine or a reference to one. Must return 1 for success.

=head4 HASH

    @errors = $sc->errors( ..., { 'is' => 'filled' } );
    @errors = $sc->errors( ..., { 'is' =>  \&sub, 'args' => [...], 'name' => 'teste' } );

A hash ref with the following keys:

B<is>
The check to use.

B<args>
The arguments to use with check.

B<name>
The name that is returned on error. This is specially usefull with anonymous subroutines.

=head4 SCALAR

    @errors = $sc->errors( ..., 'defined' );

The name of the plugin to use.

=head2 is_*

    my $defined  = $sc->is_defined( $value );
    my $lengthok = $sc->is_length( $value, 10 );

All plugins are mapped as a is_* method in Sidekick::Check. See L</PLUGINS>.

=for POD::Weaver is_filled is_defined

=head1 PLUGINS

    package Sidekick::Check::Plugin::NAME

    sub check {
        my $self  = shift; # 'Sidekick::Check'
        my $value = shift; # the value to validate
        my @args  = @_   ; # additional args

        # return 0 if it fails, otherwise 1.
        ...
    }

=head1 SEE ALSO

=over 4

=item *

L<Sidekick::Check::Plugin::Defined>

=item *

L<Sidekick::Check::Plugin::Filled>

=back

=head1 AUTHOR

André Rivotti Casimiro <rivotti@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by André Rivotti Casimiro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
