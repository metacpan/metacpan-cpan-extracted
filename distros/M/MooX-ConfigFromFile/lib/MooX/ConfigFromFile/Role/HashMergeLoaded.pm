package MooX::ConfigFromFile::Role::HashMergeLoaded;

use strict;
use warnings;

our $VERSION = '0.007';

use Hash::Merge;

use Moo::Role;

requires "loaded_config";

has "config_merger" => ( is => "lazy" );

sub _build_config_merger { Hash::Merge->new('LEFT_PRECEDENT') }

around _build_loaded_config => sub {
    my ( $next, $class, $params ) = @_;

    defined $params->{raw_loaded_config} or $params->{raw_loaded_config} = $class->_build_raw_loaded_config($params);
    defined $params->{config_merger}     or $params->{config_merger}     = $class->_build_config_merger($params);

    my $config_merged = {};
    for my $c ( map { values %$_ } @{ $params->{raw_loaded_config} } )
    {
        %$config_merged = %{ $params->{config_merger}->merge( $config_merged, $c ) };
    }

    $config_merged;
};

1;

=head1 NAME

MooX::ConfigFromFile::Role::HashMergeLoaded - allows better merge stragegies for multiple config files

=head1 SYNOPSIS

  package MyApp::Cmd::TPau;

  use DBI;
  use Moo;
  use MooX::Cmd with_configfromfile => 1;
  
  with "MooX::ConfigFromFile::Role::HashMergeLoaded";

  has csv => (is => "ro", required => 1);

  sub execute
  {
      my $self = shift;
      DBI->connect("DBI::csv:", undef, undef, $self->csv);
  }

  __END__
  $ cat etc/myapp.json
  {
    "csv": {
      "f_ext": ".csv/r",
      "csv_sep_char": ";",
      "csv_class": "Text::CSV_XS"
    }
  }
  $cat etc/myapp-tpau.json
  {
    "csv": {
      "f_dir": "data/tpau"
    }
  }

=head1 DESCRIPTION

This is an additional role for MooX::ConfigFromFile to allow better merging
of deep structures.

=head1 ATTRIBUTES

=head2 config_merger

This attribute contains the instance of the merger used to merge the
I<raw_loaded_config> into I<loaded_config>.

=head2 loaded_config

This role modifies the builder for I<loaded_config> by merging the items
from I<raw_loaded_config> in order of appearance. It is assumed that more
relevant config files are in front and are filled up with defaults in
following ones.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
