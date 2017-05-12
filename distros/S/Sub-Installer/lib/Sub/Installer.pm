package Sub::Installer;

use version; $VERSION = qv('0.0.3');

use warnings;
use strict;
use Carp;


sub reinstall_sub {
    my ($package_name, $sub_def_ref) = @_;
    croak "Usage: PackageName->reinstall_sub( \%sub_def )"
        unless @_==2 && ref $sub_def_ref eq 'HASH';
    no warnings 'redefine';
    my $last_install;
    for my $sub_name (keys %{$sub_def_ref}) {
        no strict 'refs';
        *{$package_name.'::'.$sub_name}
            = $last_install
            = Sub::Installer::Util::_normalize_sub($package_name, $sub_name, $sub_def_ref->{$sub_name});
    }
    return $last_install;
}

sub install_sub {
    my ($package_name, $sub_def_ref) = @_;
    croak "Usage: PackageName->install_sub( \%sub_def )"

        unless @_==2 && ref $sub_def_ref eq 'HASH';
    my $last_install;
    use warnings 'redefine';
    for my $sub_name (keys %{$sub_def_ref}) {
        no strict 'refs';
        *{$package_name.'::'.$sub_name}
            = $last_install
            = Sub::Installer::Util::_normalize_sub($package_name, $sub_name, $sub_def_ref->{$sub_name});
    }
    return $last_install;
}

package Sub::Installer::Util;

use Carp;

sub _normalize_sub {
    my ($package_name, $sub_name, $sub_code) = @_;
    if (!ref $sub_code) {
        if ($sub_code !~ /\A \s* sub \s* [{] .* [}] \s* \Z/xms) {
            $sub_code = "sub { $sub_code }";
        }
        $sub_code = eval "package $package_name; $sub_code"
            or croak "Can't install invalid code: $@";
    }
    return $sub_code;
}

package UNIVERSAL;
use base 'Sub::Installer';

1; # Magic true value required at end of module
__END__

=head1 NAME

Sub::Installer - A cleaner way to install (or reinstall) package subroutines


=head1 VERSION

This document describes Sub::Installer version 0.0.3


=head1 SYNOPSIS

    use Sub::Installer;

    $installed_ref = PackageName->install_sub({ subname => $sub_ref });

    $installed_ref = PackageName->install_sub({ subname => $sub_code_str });

    $installed_ref = PackageName->reinstall_sub({subname => $other_sub_ref });

  
=head1 DESCRIPTION

This module provides two universal methods that any package/class can use to
install subroutines in its own namespace.

=head1 INTERFACE 

=over

=item C<< PackageName->install_sub(\%sub_specs) >>

This method installs one or more subroutines in the package on which it's
invoked. Each subroutine is specified as an entry in the hash whose reference
is passed to the method. The key of each entry is the name of the subroutine,
and the corresponding value is either a subroutine reference, or a character
string containing the source code of the body of the subroutine.

For example:

    use Sub::Installer;

    MyClass->install_sub({ new => sub { bless { @[1..$#_] }, $_[0] } });

    # or, equivalently...

    MyClass->install_sub({ new => q{ bless { @[1..$#_] }, $_[0] } });

In either case, the method call returns a reference to the last
subroutine that was installed (though this is generally only useful if
you're installing a single subroutine).

In other words, calling:

    $ref = $PackageName->install_sub({ $sub_name => $sub_ref });

is just a cleaner and more maintainable way of writing:

    $ref = do {
        no strict 'refs';
        *{$PackageName.'::'.$subname} = $sub_ref;
    }


=item C<< PackageName->reinstall_sub(\%sub_specs) >>

This method acts exactly like C<install_sub()> except that it suppresses any
C<Subroutine I<subname> redefined> warnings.

That is, calling:

    $PackageName->reinstall_sub({ $sub_name => $sub_ref });

is just a cleaner and more maintainable way of writing:

    do {
        no warnings 'redefine';
        no strict 'refs';
        *{$PackageName.'::'.$subname} = $sub_ref;
    }

=back


=head1 DIAGNOSTICS

=over

=item Usage: PackageName->install_sub( \%sub_def )"

=item Usage: PackageName->reinstall_sub( \%sub_def )

You tried to call C<install_sub()> or C<reinstall_sub()> with the wrong
number of arguments, or without passing it a hash reference specifying
the subroutines to be installed. A common mistake is to pass raw
key/value pairs, without putting them in a hash first.

=item Can't install invalid code: %s

You passed a string instead of a subroutine reference, but that string
wasn't a valid subroutine body. The compiler's actual problem with the
code appears after the colon.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Sub::Installer requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-sub-installer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
