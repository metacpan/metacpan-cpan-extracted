package Statistics::R::IO::RDS;
# ABSTRACT: Supply object methods for RDS files
$Statistics::R::IO::RDS::VERSION = '1.0001';
use 5.010;

use Class::Tiny::Antlers;

extends 'Statistics::R::IO::Base';

use Statistics::R::IO::REXPFactory;
use Carp;

use namespace::clean;


sub read {
    my $self = shift;
    
    my $data = $self->_read_and_uncompress;
    
    my ($value, $state) = @{Statistics::R::IO::REXPFactory::unserialize($data)};
    croak 'Could not parse RDS file' unless $state;
    croak 'Unread data remaining in the RDS file' unless $state->eof;
    $value
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::IO::RDS - Supply object methods for RDS files

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::IO::RDS;
    
    my $rds = Statistics::R::IO::RDS->new('file.rds');
    my $var = $rds->read;
    print $var->to_pl;
    $rds->close;

=head1 DESCRIPTION

C<Statistics::R::IO::RDS> provides an object-oriented interface to
parsing RDS files. RDS files store a serialization of a single R
object (and, if the object contains references to other objects, such
as environments, all the referenced objects as well). These files are
created in R using the C<readRDS> function and are typically named
with the C<.rds> file extension.

=head1 METHODS

C<Statistics::R::IO::RDS> inherits from L<Statistics::R::IO::Base> and
provides an implementation for the L</read> method that parses RDS
files.

=over

=item read

Reads the contents of the filehandle and returns a
L<Statistics::R::REXP>.

=back

=head1 BUGS AND LIMITATIONS

Instances of this class are intended to be immutable. Please do not
try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
