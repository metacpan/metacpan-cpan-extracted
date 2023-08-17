package Config::MVP::Reader::Findable::ByExtension 2.200013;
# ABSTRACT: a Findable Reader that looks for files by extension

use Moose::Role;

with qw(Config::MVP::Reader::Findable);

use File::Spec;

#pod =method default_extension
#pod
#pod This method, B<which must be composed by classes including this role>, returns
#pod the default extension used by files in the format this reader can read.
#pod
#pod When the Finder tries to find configuration, it have a directory root and a
#pod basename.  Each (Findable) reader that it tries in turn will look for a file
#pod F<basename.extension> in the root directory.  If exactly one file is found,
#pod that file is read.
#pod
#pod =cut

requires 'default_extension';

#pod =method refined_location
#pod
#pod This role provides a default implementation of the
#pod L<C<refined_location>|Config::MVP::Reader::Findable/refined_location> method
#pod required by Config::MVP::Reader.  It will return a filename based on the
#pod original location, if a file exists matching that location plus the reader's
#pod C<default_extension>.
#pod
#pod =cut

sub refined_location {
  my ($self, $location) = @_;

  my $candidate_name = "$location." . $self->default_extension;
  return unless -r $candidate_name and -f _;
  return $candidate_name;
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP::Reader::Findable::ByExtension - a Findable Reader that looks for files by extension

=head1 VERSION

version 2.200013

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 default_extension

This method, B<which must be composed by classes including this role>, returns
the default extension used by files in the format this reader can read.

When the Finder tries to find configuration, it have a directory root and a
basename.  Each (Findable) reader that it tries in turn will look for a file
F<basename.extension> in the root directory.  If exactly one file is found,
that file is read.

=head2 refined_location

This role provides a default implementation of the
L<C<refined_location>|Config::MVP::Reader::Findable/refined_location> method
required by Config::MVP::Reader.  It will return a filename based on the
original location, if a file exists matching that location plus the reader's
C<default_extension>.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
