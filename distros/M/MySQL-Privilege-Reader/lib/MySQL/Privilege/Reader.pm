package MySQL::Privilege::Reader;

use warnings;
use strict;

=head1 NAME

MySQL::Privilege::Reader - Determines which privileges are valid for a given MySQL Database Connection

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This modules reads, parses and returns a convenient (*) data structure with all
the available access privileges found in a given MySQL database connection.

(*) Convenient for me. If this is not exactly convenient for you, please feel
free to write me and ask for a more convenient data structure, and I will be
happy to build it into this module.

=head1 METHODS

=head2 get_privileges

=cut

sub get_privileges {
    my ( $class, $dbi ) = @_;
    die q{Not a DBI object}
      unless defined $dbi
          and ref $dbi
          and $dbi->isa('DBI::db');
    my %privileges;
    my @privileges =
      @{ $dbi->selectall_arrayref( 'SHOW PRIVILEGES', { Slice => {} } ) };
    foreach my $privilege (@privileges) {
        my @contexts = split qr{,}, $$privilege{Context};
        foreach my $context (@contexts) {
            push @{ $privileges{__PRIVILEGES_BY_CONTEXT}->{$context} },
              {
                Privilege => uc $$privilege{Privilege},
                Comment   => $$privilege{Comment}
              };
            push @{ $privileges{__CONTEXT_BY_PRIVILEGE}
                  ->{ uc $$privilege{Privilege} } }, $context;
        }
    }
    $privileges{__CONTEXTS} = [
        sort grep { !m{^__.*} }
          keys %{ $privileges{__PRIVILEGES_BY_CONTEXT} }
    ];
    return bless \%privileges, $class;
}

=head1 AUTHOR

Luis Motta Campos, C<< <lmc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mysql-privilege-reader at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MySQL-Privilege-Reader>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MySQL::Privilege::Reader

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MySQL-Privilege-Reader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MySQL-Privilege-Reader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MySQL-Privilege-Reader>

=item * Search CPAN

L<http://search.cpan.org/dist/MySQL-Privilege-Reader/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Luis Motta Campos.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; version 2 dated June, 1991 or at your option any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree; if
not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

=cut

1;    # End of MySQL::Privilege::Reader
