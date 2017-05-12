package CDB_File_Thawed;
use strict;
use CDB_File;
use Storable qw(thaw);
our @ISA = qw(CDB_File);

sub new {
	my($class, $filename, $tempfile) = @_;
  my $maker = CDB_File->new($filename, $tempfile);
  my $self = { maker => $maker };
  bless $self, 'CDB_File::Maker_Thawed';
  return $self;
}

sub FETCH {
  my($self, $key) = @_;
  my $value = CDB_File::FETCH($self, $key);
  $value = thaw($value);
}

package CDB_File::Maker_Thawed;
use strict;
use CDB_File;
use Storable qw(nfreeze);
our @ISA = qw(CDB_File::Maker);

sub insert {
  my($self, $key, $value) = @_;
  $value = nfreeze($value);
  CDB_File::Maker::insert($self->{maker}, $key, $value);
}

sub finish {
  my($self) = @_;
  CDB_File::Maker::finish($self->{maker});
}

1;

__END__

=head1 NAME

CDB_File_Thawed - Storable thaw() values in a CDB_File

=head1 SYNOPSIS

  # to create a CDB file:
  my $cdb = CDB_File_Thawed->new($filename, $tempfile) or die $!;
  $cdb->insert($key1, $value1);
  $cdb->insert($key2, $value2);
  $cdb->finish;

  # to use a CDB file:
  tie my %cdb, 'CDB_File_Thawed', $filename2 or die "tie failed: $!\n";
  # use %cdb has a normal (but read-only) hash
  
=head1 DESCRIPTION

This module is a small wrapper around CDB_File which makes sure to use
Storable's nfreeze() and thaw() methods to store values. CDB_File is an
interface to Dan Berstein's Constant DataBase library, which as the name
implies is a fast, reliable, simple package for creating and reading
constant databases. Using this module you can store Perl data structures
and objects in a fast CDB_File.

=head1 CONSTRUCTOR

=head2 new($filename)

The constructor. Takes the destination filename and a temporary fiename
as arguments:

  my $cdb = CDB_File_Thawed->new($filename, $tempfile) or die $!;

=head1 METHODS

=head2 insert

Inserts a key, value pair. The value may be a data structure or object:

  $cdb->insert($key, $value);

=head2 finish

Finalised the new CDB file:

  $cdb->finish; 

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
