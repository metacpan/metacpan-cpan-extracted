package Test::Database::Driver::DBM;
$Test::Database::Driver::DBM::VERSION = '1.113';
use strict;
use warnings;

use File::Spec;
use File::Path;
use DBD::DBM;

use Test::Database::Driver;
our @ISA = qw( Test::Database::Driver );

sub is_filebased {1}

sub _version { return DBD::DBM->VERSION; }

sub dsn {
    my ( $self, $dbname ) = @_;
    my $dbdir = File::Spec->catdir( $self->base_dir(), $dbname );
    mkpath( [$dbdir] );
    return $self->make_dsn( f_dir => $dbdir );
}

sub drop_database {
    my ( $self, $dbname ) = @_;
    my $dbdir = File::Spec->catdir( $self->base_dir(), $dbname );
    rmtree( [$dbdir] );
}

'DBM';

__END__

=head1 NAME

Test::Database::Driver::DBM - A Test::Database driver for DBM

=head1 SYNOPSIS

    use Test::Database;
    my @handles = Test::Database->handles( 'DBM' );

=head1 DESCRIPTION

This module is the L<Test::Database> driver for L<DBD::DBM>.

=head1 SEE ALSO

L<Test::Database::Driver>

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2008-2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

