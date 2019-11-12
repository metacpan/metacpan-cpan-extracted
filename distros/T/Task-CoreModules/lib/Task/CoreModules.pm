use strict;
use warnings;
package Task::CoreModules; # git description: 19fbbe4
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: All the modules that should have been installed for your perl
# KEYWORDS: core corelist modules missing

our $VERSION = '0.001';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::CoreModules - All the modules that should have been installed for your perl

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    $ cpanm Task::CoreModules

=head1 DESCRIPTION

This is a distribution that contains no code of its own, but merely declares dependencies on a number of other
modules: all the modules that should have been bundled with your version of Perl, but may have been omitted due to
overly-zealous distribution package managers who decided to omit some modules to "save space".

Simply declare a dependency on C<Task::CoreModules> in your project, and when installed, all core modules are
installed. If you already have them, then no action is taken.

=head1 FUNCTIONS/METHODS

None.

=head1 SEE ALSO

=over 4

=item *

L<Module::CoreList> - where "core" modules are listed for each Perl version.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Task-CoreModules>
(or L<bug-Task-CoreModules@rt.cpan.org|mailto:bug-Task-CoreModules@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
