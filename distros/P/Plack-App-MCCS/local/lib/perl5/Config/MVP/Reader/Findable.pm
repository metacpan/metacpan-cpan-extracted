package Config::MVP::Reader::Findable 2.200013;
# ABSTRACT: a config class that Config::MVP::Reader::Finder can find

use Moose::Role;

#pod =head1 DESCRIPTION
#pod
#pod Config::MVP::Reader::Findable is a role meant to be composed alongside
#pod Config::MVP::Reader.
#pod
#pod =method refined_location
#pod
#pod This method is used to decide whether a Findable reader can read a specific
#pod thing under the C<$location> argument passed to C<read_config>.  The location
#pod could be a directory or base file name or dbh or almost anything else.  This
#pod method will return false if it can't find anything to read.  If it can find
#pod something to read, it will return a new (or unchanged) value for C<$location>
#pod to be used in reading the config.
#pod
#pod =cut

requires 'refined_location';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP::Reader::Findable - a config class that Config::MVP::Reader::Finder can find

=head1 VERSION

version 2.200013

=head1 DESCRIPTION

Config::MVP::Reader::Findable is a role meant to be composed alongside
Config::MVP::Reader.

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

=head2 refined_location

This method is used to decide whether a Findable reader can read a specific
thing under the C<$location> argument passed to C<read_config>.  The location
could be a directory or base file name or dbh or almost anything else.  This
method will return false if it can't find anything to read.  If it can find
something to read, it will return a new (or unchanged) value for C<$location>
to be used in reading the config.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
