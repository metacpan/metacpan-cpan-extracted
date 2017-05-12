package MooseX::Templated::Util;

=head1 NAME

MooseX::Templated::Util - helper methods

=head1 SYNOPSIS

  use MooseX::Templated::Util qw/ where_pm /;

=head1 METHODS

=head2 where_pm( 'ClassName' )

Returns the file path information for a given class path

  $abs_file = where_pm( 'Some::Module' );
  # /path/to/Some/Module.pm

  ($abs_file, $inc_path, $require) = where_pm( 'Some::Module' );

  # /path/to/Some/Module.pm
  # /path/to
  # Some/Module.pm


=cut

use strict;
use warnings;
use Path::Class;
use Exporter 'import';
use namespace::autoclean;

our (@ISA, @EXPORT_OK);
BEGIN {
  require Exporter;
  @ISA = qw/ Exporter /;
  @EXPORT_OK = qw/ where_pm /;
}

# This is a drop-in rewrite of a similar function in Find::Where
# (which no longer installs on perl > 5.22 and doesn't look
# like it's going to be fixed anytime soon)
sub where_pm {
  my $class = shift;
  my $inc_path = \@INC;
  my $abs_file;
  my $require;

  my @module_parts = split( '::', $class );
  $module_parts[-1] .= '.pm';

  # go through each PATH and return the first file we find
  PATH: foreach my $path ( @$inc_path ) {
    my $module_file_abs = file( $path, @module_parts );
    if ( -f $module_file_abs ) {
      $abs_file = "" . $module_file_abs->absolute;
      $inc_path = "" . dir( $path );
      $require =  "" . file( @module_parts );
      last PATH;
    }
  }
  return wantarray ? ($abs_file, $inc_path, $require) : $abs_file;
}

1;
