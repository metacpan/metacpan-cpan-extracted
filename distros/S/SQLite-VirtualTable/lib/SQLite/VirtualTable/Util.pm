package SQLite::VirtualTable::Util;

use strict;
use warnings;

our $VERSION = '0.03';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(unescape);

my %esc = ( "\n" => 'n',
	    "\r" => 'r',
	    "\t" => 't' );
my %unesc = reverse %esc;

sub unescape {
    my $s = shift;
    $s =~ s{\\([tnr\\"' =:#!])|\\u([\da-fA-F]{4})|["']}{
                defined $1 ? $unesc{$1}||$1 :
                defined $2 ? chr hex $2 :
                '';
           }ge;
    $s;
}


1;

__END__


=head1 NAME

SQLite::VirtualTable::Util - Helper functions for SQLite::VirtualTable

=head1 SYNOPSIS

  use SQLite::VirtualTable::Utill qw(unescape);

  my $foo = unescape $bar;

=head1 DESCRIPTION

This module contains some utility functions that are used by
SQLite::VirtualTable and derived modules.

=head2 FUNCTIONS:

=over 4

=item unescape($arg)

remove quotes and resolve escaped characters from the argument.

=back

=head1 AUTHOR

Salvador FandiE<ntilde>o (sfandino@yahoo.com).

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Qindel Formacion y Servicios, S. L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
