package Acme::Noose;
use strict;
use warnings;
# ABSTRACT: just enough object orientation to hang yourself
our $VERSION = '0.001'; # VERSION

use Noose ();
BEGIN {
    *Acme::Noose:: = \%Noose::;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::Noose - just enough object orientation to hang yourself

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is simply a (more accurately named) alias of L<Noose>.

=for Pod::Coverage new

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Noose/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Noose>
and may be cloned from L<git://github.com/doherty/Noose.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Noose/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
