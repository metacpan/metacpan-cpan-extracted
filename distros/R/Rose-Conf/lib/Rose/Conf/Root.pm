package Rose::Conf::Root;

use strict;

use Carp();

our $VERSION = '0.01';

sub import
{
  my($class, $dir) = @_;

  if(@_ < 2)
  {
    local $Carp::CarpLevel = 0;
    Carp::croak "Usage: use $class '/some/directory'";
  }
  else
  {
    if(defined $dir)
    {
      unless(-d $dir)
      {
        local $Carp::CarpLevel = 0;
        Carp::croak "No such directory: $dir";
      }

      $ENV{'ROSE_CONF_FILE_ROOT'} = $dir;
    }
    else
    {
      delete $ENV{'ROSE_CONF_FILE_ROOT'};
    }
  }
}

sub conf_root
{
  return $ENV{'ROSE_CONF_FILE_ROOT'}  unless(@_ > 1);
  shift->import(@_);
}

1;

__END__

=head1 NAME

Rose::Conf::Root - Recommended way to set the Rose file-based configuration
file root directory.

=head1 SYNOPSIS

    use Rose::Conf::Root '/path/to/your/conf/root';

    # or...

    use Rose::Conf::Root;
    Rose::Conf::Root->conf_root('/path/to/your/conf/root');

=head1 DESCRIPTION

C<Rose::Conf::Root> is the recommended way to set the Rose file-based
configuration module root directory.  Simply C<use> the module with a single
argument that specifies the path to the configuration root directory, or call
the C<conf_root()> class method with the same argument.

See the C<Rose::Conf> and C<Rose::Conf::FileBased> documentation for more
information on configuration modules and the file-based configuration module
root directory.

=head1 CLASS METHODS

=over 4

=item B<conf_root [PATH]>

Get or set the Rose file-base configuration module root directory. If present,
the PATH argument should not end with a path separator character (e.g., "/")

=back

=head1 AUTHOR

John C. Siracusa (siracusa@mindspring.com)

=head1 COPYRIGHT

Copyright (c) 2004 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
