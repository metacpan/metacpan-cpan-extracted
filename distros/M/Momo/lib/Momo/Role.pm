package Momo::Role;

# ABSTRACT support role
use feature ();
use strict;
use warnings;
use utf8;
use base qw(Role::Tiny);

sub _getglob  { no strict 'refs'; \*{ $_[0] } }
sub _getstash { no strict 'refs'; \%{"$_[0]::"} }

sub import {
    my $target = caller;
    my $me     = shift;

    strict->import;
    warnings->import( FATAL => 'all' );
    utf8->import;

    no strict 'refs';
    return
      if ( \%{'Role::Tiny::INFO'} )->{$target}
      ;    # already exported into this package
    ( \%{'Role::Tiny::INFO'} )->{$target}{is_role} = 1;

    # get symbol table reference
    my $stash = _getstash($target);

    # install before/after/around subs
    foreach my $type (qw(before after around)) {
        *{ _getglob "${target}::${type}" } = sub {
            require Class::Method::Modifiers;
            push @{ ( \%{'Role::Tiny::INFO'} )->{$target}{modifiers} ||= [] },
              [ $type => @_ ];
            return;
        };
    }
    *{ _getglob "${target}::requires" } = sub {
        push @{ ( \%{'Role::Tiny::INFO'} )->{$target}{requires} ||= [] }, @_;
        return;
    };
    *{ _getglob "${target}::has" } = sub {
        require Momo;
        Momo::attr( $target, @_ );
    };
    *{ _getglob "${target}::with" } = sub {
        $me->apply_roles_to_package( $target, @_ );
        return;
    };
    my @not_methods = ( map { *$_{CODE} || () } grep !ref($_), values %$stash );
    @{ ( \%{'Role::Tiny::INFO'} )->{$target}{not_methods} = {} }{@not_methods}
      = @not_methods;

    # a role does itself
    ( \%{'Role::Tiny::APPLIED_TO'} )->{$target} = { $target => undef };
}

1;

=encoding utf8

=head1 NAME

Momo::Role is a subclass of Role::Tiny and support C<has> method.

=head1 SYNOPSIS

    
    package Role1;

    use Momo::Role;

    has is_role => 1;

    sub can_run{ .... };
    sub can_fly{ .... };
    
    1;


=head1 DESCRIPTION


For the detail,check L<Momo>,L<Role::Tiny>.


=head1 SEE ALSO


L<Role::Tiny>


=head1 AUTHOR


舌尖上的牛氓 C<yiming.jin@live.com>  

QQ: 492003149

QQ-Group: 211685345

Site: L<http://perl-china.com>

=head1 Copyright

Copyright (C) <2013>, <舌尖上的牛氓>.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

# niumang // vim: ts=2 sw=2 expandtab
# TODO - Edit.
