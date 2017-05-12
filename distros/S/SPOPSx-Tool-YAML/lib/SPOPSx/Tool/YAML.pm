package SPOPSx::Tool::YAML;

use strict;
use warnings;

our $VERSION = '0.03';

use YAML qw(Load Dump);

=head1 NAME

SPOPSx::Tool::HashField - A SPOPS extension for the storage of complex objects

=head1 SYNOPSIS

  %conf = (
      table_alias => {
          # ...
          yaml_fields => [ qw/ arguments locals results / ],
          # ...
      }
  );

=head1 DESCRIPTION

This allows for the storage of Perl aggregate types in a database field. This uses L<YAML> to perform the marshalling and unmarshalling. This is handy because you can use third-party tools to update the stored data with relative ease and the data is readable even in other languages that have a YAML model. The data structure can be arbritraily deep.

=cut

# As far as I can tell from the docs, this is technically a violation of the
# guidelines for building rulesets. However, this is pretty much the same thing
# that SPOPS::Tool::DateConvert does.
sub ruleset_factory {
	my ($class, $rstab) = @_;
	push @{ $rstab->{post_fetch_action} }, \&convert_to_yaml;
	push @{ $rstab->{pre_save_action} }, \&convert_to_string;
	push @{ $rstab->{post_save_action} }, \&convert_to_yaml;
	return __PACKAGE__
}

# TODO Add a thingy to walk the created data structure and attempt to require
# any packages objects have been blessed into.
sub convert_to_yaml {
	my $self = shift;
	my @yaml_fields = @{ $self->CONFIG->{yaml_fields} };
	for my $yaml_field (@yaml_fields) {
		$self->{$yaml_field} = Load($self->{$yaml_field});
	}

	return 1;
}

sub convert_to_string {
	my $self = shift;
	my @yaml_fields = @{ $self->CONFIG->{yaml_fields} };
	for my $yaml_field (@yaml_fields) {
		$self->{$yaml_field} = Dump($self->{$yaml_field});
	}

	return 1;
}

=head1 INSTALLATION

Just the typical install tricks will do:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

or:

  perl Makefile.PL
  make
  make test
  make install

Take your pick.

=head1 SEE ALSO

L<SPOPS>, L<YAML>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

Contentment is distributed and licensed under the same terms as Perl itself.

=cut

1
