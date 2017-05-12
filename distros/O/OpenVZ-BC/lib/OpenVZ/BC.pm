package OpenVZ::BC;

our $VERSION = '0.02';
our $default_bc_file = '/proc/bc/resources';

=pod

=head1 NAME

OpenVZ::BC - Perl access to OpenVZ Beancounter Data

=head1 SYNOPSIS

  use OpenVZ::BC;
  my $bc = OpenVZ::BC->new;
  my $resources = $bc->hash;

=head1 DESCRIPTION

Gives Perl access to OpenVZ beancounter data.  This data is typically stored
in /proc/user_beancounters or /proc/bc/resources.  By default, we use
/proc/bc/resources, but this can be overridden as described below.

=head1 INTERFACE

=head2 new

  my $bc = OpenVZ::BC->new;
  
  my $bc = OpenVZ::BC->new(
    bc_file => '/proc/user_beancounters',
  );

Creates the new OpenVZ::BC object.

=over 4

=item bc_file [optional]

If you specify bc_file here, it will override the default location.  Currently
that default location is /proc/bc/resources.  Specified here, it will define
the default location of this file for any methods used below.

=back

=cut

sub new
{
  my $class = shift;
  my %args = @_;
  my $self = {};
  $self->{bc_file} = $args{bc_file} || $default_bc_file;
  bless($self, $class);
  return $self;
}

=pod

=head2 hash

  my $resources = $bc->hash;
  
  my $resources = $bc->hash(
    bc_file => '/proc/user_beancounters',
  );
  
  my $resources = OpenVZ::BC->hash;
  
  my $resources = OpenVZ::BC->hash(
    bc_file => '/proc/user_beancounters',
  );

This returns a hashref containing the beancounter data from the default or
specified file.  If accessed via the $bc object, it will use the default
specified in that object.  If you use it via the class directly, it will use
the class default.

=over 4

=item bc_file [optional]

If you specify bc_file here, it will override the default location of either
the $bc object and/or the class.

=back

=cut

sub hash
{
  my $self = shift;
  my %args = @_;
  my $bc_file = $args{bc_file} || $self->{bc_file} || $default_bc_file;
  my $bc = {};

  if (open(BC, "<$bc_file"))
  {
    my $vpsid;
    <BC>; # skip the version
    my $columns = <BC>; # grab the columns
    my @columns = split(/\s+/, $columns);
    shift(@columns); # skip the blank column
    shift(@columns); # skip the uid column
    shift(@columns); # skip the resource column
    while (my $line = <BC>)
    {
      if ($line =~ s/^\s+(\d+)://)
      {
        $vpsid = $1;
      }
      next if ($vpsid eq '');
      my @data = split(/\s+/, $line);
      shift(@data); # skip the blank column
      my $resource = shift(@data);
      foreach my $column (@columns)
      {
        $bc->{$vpsid}->{$resource}->{$column} = shift(@data);
      }
    }
    close(BC);
  }
  else
  {
    die(qq(Unable to open $bc_file for read: $!\n));
  }

  return $bc;
}

=pod

=head1 TODO

Provide access to the /proc/bc/<VPSID>/resources files to access a single
VPS beancounters instead of reading the full server's beancounters.  This
would involve adding new methods.  Patches are welcome.

=head1 AUTHOR

  Dusty Wilson
  Megagram Managed Technical Services
  http://www.megagram.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
