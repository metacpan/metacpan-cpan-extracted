package Net::Lujoyglamour::Result::Url;

use warnings;
use strict;
use Carp;

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/g; 

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('short_url');
__PACKAGE__->add_columns(longu =>
			 { accessor  => 'long_url',
			   data_type => 'VARCHAR',
			   size      => 255,
			   is_nullable => 0,
			   is_auto_increment => 0
			 },
                          shortu =>
			 { accessor => 'short_url',
			   data_type => 'VARCHAR',
			   size      => $Net::Lujoyglamour::short_url_size,
			   is_nullable => 0,
			   is_auto_increment => 0
			 }
                         );

__PACKAGE__->set_primary_key( qw/ shortu longu/ );


"lujo and glamour all over again"; # Magic true value required at end of module

__END__

=head1 NAME

Net::Lujoyglamour::Result::Url - Class representing paired short/long URLs


=head1 SYNOPSIS

    use Net::Lujoyglamour;

    my $dsn = 'dbi:SQLite:dbname=:memory:'; # This or other will do
    my $schema = Net::Lujoyglamour->connect($dsn);
    my $rs_url = $schema->resultset('Url'); # For short

    my $url = $rs_url->single( { short => $one_short } );

    print $url->short_url." corresponds to ". $url->long_url;


=head1 DESCRIPTION

Represents the table that contains long/short URLs. 

=head1 INTERFACE 

Fully inherited from L<DBIx::Class::Core>, only thing you have to
    worry about is the automatically defined accessors C<short_url>
    and C<long_url> that retrieve each part of the URL pair


=head1 DIAGNOSTICS

Diagnostics are inherited from base class, so there might be some
    amount of database-related funkyness.

=head1 CONFIGURATION AND ENVIRONMENT

See L<Net::Lujoyglamour> for configuration.

=head1 DEPENDENCIES

L<Net::Lujoyglamour>, L<DBIx::Class::Core> and related classes. 

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-lujoyglamour@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
