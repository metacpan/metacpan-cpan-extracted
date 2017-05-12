package Sig::PackageScoped;

use strict;
use warnings;

our @EXPORT_OK = qw(set_sig unset_sig);

our $VERSION = '0.04';

our %HANDLERS;

sub import
{
    $SIG{__DIE__} = sub { my $package = caller(0);
			  exists $HANDLERS{$package}{__DIE__} ?
			  $HANDLERS{$package}{__DIE__}->(@_) :
			  die @_;
		        };
    $SIG{__WARN__} = sub { my $package = caller(0);
			   exists $HANDLERS{$package}{__WARN__} ?
			   $HANDLERS{$package}{__WARN__}->(@_) :
			   warn @_;
		         };

    return;
}

sub set_sig
{
    my %p = @_;

    my $package = $p{package} || caller(0);

    $HANDLERS{$package}{__DIE__} = $p{__DIE__} if exists $p{__DIE__};
    $HANDLERS{$package}{__WARN__} = $p{__WARN__} if exists $p{__WARN__};

    return;
}

sub unset_sig
{
    my %p = @_;

    my $package = delete $p{package} || caller(0);

    delete @{ $HANDLERS{$package} }{ keys %p };

    return;
}


1;

__END__

=head1 NAME

Sig::PackageScoped - Make $SIG{__DIE__} and $SIG{__WARN__} package scoped

=head1 SYNOPSIS

  use Sig::PackageScoped qw(set_sig unset_sig);

  set_sig( __DIE__ => sub { die "Really dead: @_" } );

  unset_sig( __DIE__ => 1 );

=head1 DESCRIPTION

If all your modules use this module's functions to declare their
signal handlers, then they won't overwrite each other.  If you're
working with modules that don't play nice, see
Sig::PackageScoped::Paranoid. But really, this is more of a
demonstration of weird things you can do with Perl than a good thing
to use in production. You have been warned.

=head1 EXPORTS

This module will optionally export the C<set_sig> and <unset_sig>
subroutines.  By default, nothing is exported.

=head1 FUNCTIONS

This module provides the following functions:

=head2 set_sig()

This function accepts a hash of options. The keys can be either
C<__DIE__> or C<__WARN__>, and the values should be coderefs to handle
the specified pseudo-signal.

=head2 unset_sig()

This function also expects a hash. The keys should be the
pseudo-signal to unset, and the value can be any true value.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sig-packagescoped@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2001-2007 David Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
