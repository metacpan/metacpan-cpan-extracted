## no critic (RequireExplicitPackage, ProhibitMultiplePackages)

use strict;
use warnings;

package Sig::PackageScoped::Paranoid;

our $VERSION = '99';

use Sig::PackageScoped;

tie $SIG{__DIE__}, 'Sig::PackageScoped::Paranoid::Tie', '__DIE__';
tie $SIG{__WARN__}, 'Sig::PackageScoped::Paranoid::Tie', '__WARN__';


package Sig::PackageScoped::Paranoid::Tie;

our $VERSION = '99';

our $SELF;
sub TIESCALAR
{
    my $class = shift;
    my $word  = shift;

    $SELF = bless \$word, $class;

    return $SELF;
}

sub FETCH
{
    my $self    = shift;
    my $package = caller(0);

    return ( exists $Sig::PackageScoped::HANDLERS{$package}{$$self} ?
	     $Sig::PackageScoped::HANDLERS{$package}{$$self} :
	     sub { die @_ }
	   );
}

sub STORE
{
    my $self    = shift;
    my $package = caller(0);

    Sig::PackageScoped::set_sig( package => $package,
				 $$self  => shift );

    return;
}


1;

__END__

=head1 NAME

Sig::PackageScoped::Paranoid - All $SIG{__DIE__} and $SIG{__WARN__} assignments are module-scoped

=head1 SYNOPSIS

  use Sig::PackageScoped::Paranoid;

  package Foo;

  $SIG{__DIE__} = sub { die "in Foo" };

  package Bar;

  die "not in Foo";

=head1 DESCRIPTION

Whenever a handler is assigned C<$SIG{__DIE__}> or C<$SIG{__WARN__}>
the effects are now scoped to the package that did the assignment.

This module needs to be loaded B<before> any other module that assigns
to C<$SIG{__DIE__}> or C<$SIG{__WARN__}> for this to work.

This will catch B<any> attempt to set C<$SIG{__DIE__}> or
C<$SIG{__WARN__}> and B<force> it to be package-scoped.  This will
probably break things like C<CGI::Carp> so use it with care.  OTOH,
modules that globally set these signals deserve to be broken.

The fact that this works scares me deeply. It is not recommended that
you use this code in any sort of production environment.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=cut
