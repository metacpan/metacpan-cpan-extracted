#!/usr/bin/perl -c

package Resource::Dispose;

=head1 NAME

Resource::Dispose - Syntax sugar for dispose pattern

=head1 SYNOPSIS

  use Resource::Dispose;
  {
      resource my $obj = Some::Class->new;
  }
  # $obj->DISPOSE is called even if $obj can not be freed and destroyed

=head1 DESCRIPTION

The dispose pattern is a design pattern which is used to handle resource
cleanup in runtime environment that use automatic garbage collection.  In Perl
there is possibility that the object will be destructed during global
destruction and it leads to memory leaking and other drawbacks like unclosed
file handles, etc.

This module provides new keyword C<resource> as a syntax sugar for dispose
pattern. The C<DISPOSE> method of the resource object is called if the
resource is going out of scope.

=for readme stop

=cut


use strict;
use warnings;

our $VERSION = '0.01';


use Devel::Declare ();
use Guard ();
use Carp qw(croak);


our @CARP_NOT = qw(Devel::Declare);


sub import {
    my ($class) = @_;

    my $caller = caller;

    Devel::Declare->setup_for(
        $caller,
        { resource => { const => \&parser } }
    );

    no strict 'refs';
    *{$caller.'::resource'} = sub ($) {};

    return 1;
};


our $Prefix = '';

sub get_linestr {
    return substr Devel::Declare::get_linestr, length $Prefix;
};

sub set_linestr {
    return Devel::Declare::set_linestr $Prefix . $_[0];
};

sub parser {
    my ($keyword, $offset) = @_;

    local $Prefix = substr get_linestr, 0, $offset;
    strip_keyword();

    my $linestr = get_linestr;

    $linestr =~ s/\s*(?:(local|my|our|state)\s*)?(\$\w+|\(.*?\))// or croak 'Syntax error';
    my ($scope, $decl) = ($1, $2);

    my $before = '';
    $before .= "$scope $decl; " if defined $scope;

    my @vars = $decl =~ /^\((.*)\)$/
             ? split /\s*,\s*/, $1
             : $decl;

    foreach my $var (@vars) {
        $before .= "Guard::scope_guard { $var->DISPOSE if eval { $var->can('DISPOSE') } }; ";
    };

    $before .= "$decl" if $linestr =~ /\s*=/ and $decl =~ /^\s*(\$\w+|\(\s*\$\w+\s*\))\s*$/;

    set_linestr($before . $linestr);

    return 1;
};

sub strip_space {
    my $skip = Devel::Declare::toke_skipspace length $Prefix;
    set_linestr substr get_linestr, $skip;
    return 1;
};

sub strip_keyword {
    strip_space;
    get_linestr =~ /^(resource)(?:\b|$)/ or croak 'Could not match resource keyword ', get_linestr;
    $Prefix .= $1;
    return $1;
};


1;


=for readme continue

=head1 SEE ALSO

This C<resource> keyword is inspired by C<using> keyword from C# language and
extended C<try> keyword from Java 7 language.

L<Guard>, L<Scope::Guard>, L<Devel::Declare>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Resource-Dispose/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Resource-Dispose>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
