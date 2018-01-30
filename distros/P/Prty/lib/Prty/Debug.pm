package Prty::Debug;
use base qw/Prty::Object/;

use strict;
use warnings;

our $VERSION = 1.122;

# -----------------------------------------------------------------------------

=head1 NAME

Prty::Debug - Hilfe beim Debuggen von Programmen

=head1 BASE CLASS

L<Prty::Object>

=head1 METHODS

=head2 Module

=head3 modulePaths() - Pfade der geladenen Perl Moduldateien

=head4 Synopsis

    $str = $this->modulePaths;

=head4 Description

Liefere eine Aufstellung der Pfade der aktuell geladenen
Perl Moduldateien. Ein Modulpfad pro Zeile, alphabetisch sortiert.

=head4 Example

Die aktuell geladenen Moduldateien auf STDOUT ausgeben:

    print Prty::Debug->modulePaths;
    ==>
    /home/fs/lib/perl5/Prty/Debug.pm
    /home/fs/lib/perl5/Prty/Object.pm
    /home/fs/lib/perl5/Perl/Prty/Stacktrace.pm
    /usr/share/perl/5.20/base.pm
    /usr/share/perl/5.20/strict.pm
    /usr/share/perl/5.20/vars.pm
    /usr/share/perl/5.20/warnings.pm
    /usr/share/perl/5.20/warnings/register.pm

=cut

# -----------------------------------------------------------------------------

sub modulePaths {
    my $this = shift;
    return join("\n",sort values %INC)."\n";
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.122

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
