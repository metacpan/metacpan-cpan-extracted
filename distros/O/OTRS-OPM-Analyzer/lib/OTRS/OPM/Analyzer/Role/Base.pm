package OTRS::OPM::Analyzer::Role::Base;

# ABSTRACT: interface for all checks

use Moose::Role;

requires 'check';

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::Base - interface for all checks

=head1 VERSION

version 0.07

=head1 INTERFACE

All checks that implement this interface have to provide a I<check> method.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
