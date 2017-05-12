#
# This file is part of Task-TravisCI-Cache
#
# This software is Copyright (c) 2015 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Task::TravisCI::Cache;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.001-5-g24c805a
$Task::TravisCI::Cache::VERSION = '0.002';

# ABSTRACT: Packages pulled in when building a Perl cache for TravisCI

!!42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::TravisCI::Cache - Packages pulled in when building a Perl cache for TravisCI

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This task distribution defines the packages installed inside my TravisCI
cache, at L<https://github.com/RsrchBoy/travis-p5-cache>.

Note that while I say "my ...  cache", that certainly doesn't mean that you
cannot use it, or that I won't accept pull-requests for the inclusion of
additional packages (within reason, at least).  While I'm aiming for a more
general use case than "just @RsrchBoy's distributions", for right now that
provides a convenient initial target.

This distribution is build using the L<LatestPrereqs plugin|Dist::Zilla::Plugin::LatestPrereqs>,
so it will always depend on the latest versions of the specified modules at
the time of creation.

=head1 TASK CONTENTS

=head2 All

=head3 L<Dist::Zilla::PluginBundle::RSRCHBOY>

=head3 L<Text::Wrap> 2013.0523

The installed version appears to cause some random ABEND on the Travis v5.18 image, currently.

=head3 L<Task::BeLike::RSRCHBOY>

=head3 L<DBIx::Class::Schema::Loader>

=head3 L<Devel::Cover::Report::Coveralls>

The better to see your test coverage, my dear.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
