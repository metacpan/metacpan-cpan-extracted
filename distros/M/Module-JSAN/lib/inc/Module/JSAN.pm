package inc::Module::JSAN;

use strict;

our $VERSION = '0.04';


require inc::Module::JSAN;
require Module::JSAN;


sub import {
    goto &Module::JSAN::import;
}


__PACKAGE__;

__END__

=pod

=head1 NAME

inc::Module::JSAN - Module::JSAN configuration system

=head1 SYNOPSIS

  use inc::Module::JSAN;

=head1 DESCRIPTION

This is a loader module for Module::JSAN. It doesn't provide
any functionality by itself, please refer to L<Module::JSAN>
documentation for a description how to create JSAN distributions. 

=head1 DETAILS

This module first checks whether the F<inc/.author> directory exists,
and removes the whole F<inc/> directory if it does, so the module author
always get a fresh F<inc> every time they run F<Makefile.PL>.  Next, it
unshifts C<inc> into C<@INC>, then loads B<Module::JSAN> from there.

=head1 AUTHORS

Nickolay Platonov, C<< <nplatonov at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Many thanks to Module::Install authors, on top of which this module is mostly based.

=head1 COPYRIGHT

Copyright 2009 Nickolay Platonov, C<< <nplatonov at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
