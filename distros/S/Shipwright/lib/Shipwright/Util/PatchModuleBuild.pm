package Shipwright::Util::PatchModuleBuild;
use strict;
use warnings;

sub import {
 
    use Module::Build;
    no warnings qw'redefine';
    sub Module::Build::Base::ACTION_manpages  {} ## no critic
    sub Module::Build::Base::ACTION_docs  {} ## no critic

}


1;

__END__

=head1 NAME

Shipwright::Util::PatchModuleBuild - use this to ignore man pages generation

=head1 DESCRIPTION

This stops Module::Build from failing to (or succeeding at) generating man pages 
during installation.
It does this by replacing Module::Build::Base::ACTION_manpages with a noop

=head1 AUTHOR

Jesse Vincent C<< <jesse@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

