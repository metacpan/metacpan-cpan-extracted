#!/usr/bin/env perl
use strict;
use warnings;

package # HIDE THIS.
    Paludis::UseCleaner::App::Stub;

## no critic( Modules::RequireVersionVar )
    #
#ABSTRACT: command line client for Paludis::UseCleaner

#PODNAME: paludis-usecleaner.pl



require Paludis::UseCleaner::App;

Paludis::UseCleaner::App::run();




__END__
=pod

=head1 NAME

paludis-usecleaner.pl - command line client for Paludis::UseCleaner

=head1 VERSION

version 0.01000307

=head1 SYNOPSIS

    paludis-usecleaner.pl

For more extended usage, see L<Paludis::UseCleaner::App>

    paludis-usecleaner.pl -q

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

