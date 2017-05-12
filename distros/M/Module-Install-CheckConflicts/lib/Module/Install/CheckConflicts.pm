use strict;
use warnings;

package Module::Install::CheckConflicts;

use base 'Module::Install::Base';

BEGIN {
    our $VERSION = '0.02';
    our $ISCORE  = 1;
}

sub check_conflicts {
    my ($self, %conflicts) = @_;

    my %conflicts_found;
    for my $mod (sort keys %conflicts) {
        next unless $self->can_use($mod);

        my $installed = $mod->VERSION;
        next unless $installed le $conflicts{$mod};

        $conflicts_found{$mod} = $installed;
    }

    return unless scalar keys %conflicts_found;

    my $dist = $self->name;

    print <<"EOM";

***
  WARNING:

    This version of ${dist} conflicts with
    the version of some modules you have installed.

    You will need to upgrade these modules after
    installing this version of ${dist}.

    List of the conflicting modules and their installed
    versions:

EOM

    for my $mod (sort keys %conflicts_found) {
        print sprintf("    %s :   %s (<= %s)\n",
            $mod, $conflicts_found{$mod}, $conflicts{$mod},
        );
    }

    print "\n***\n";

    return if $ENV{PERL_MM_USE_DEFAULT};
    return unless -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

    sleep 4;
}

1;

__END__

=head1 NAME

Module::Install::CheckConflicts - notify users of possible conflicts with the distribution they're installing

=head1 SYNOPSIS

    check_conflicts(

        # Until version 0.08, Some::Module relied on a deprecated function we
        # removed now. It has been ported to the new API in 0.09.
        'Some::Module' => '0.08',

        ...
    );

=head1 DESCRIPTION

Sometimes APIs need to be broken in incompatible ways. That's fine, as long as
all dependencies that relied on the old way have been updated already. If users
install install a new version of your module, but aren't aware that they need
to update other modules that might have been broken by that new version,
they'll be left with a non-functional installation of those depending modules.

This module allows to declare modules your distribution breaks in your
C<Makefile.PL>. If a user is installing your distribution, a message explaining
the situation and a list of additional modules he needs to upgrade will
presented.

=head1 COMMANDS

=head2 check_conflicts

    check_conflicts($module => $version, ...);

Declares conflicts of your distribution. Takes a list of module/version pairs.
The version number is the version of the B<incompatible> code, not the version
number of the fixed version.

If the user installing your distribution has any conflicting module installed,
a warning message will be printed. That warning will contain the list of
conflicts, including the installed version and the declared conflicting
version.

When running the C<Makefile.PL> from an interactive terminal, there'll be a
pause of 4 seconds after print a warning, to give the user a better chance of
noticing it.

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009  Florian Ragwitz

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
