use 5.024;
use utf8;
use warnings;
use strict;

package Task::BeLike::DRAKO;
$Task::BeLike::DRAKO::VERSION = '0.001';
# ABSTRACT: be more like DRAKO -- use what he uses

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::BeLike::DRAKO - be more like DRAKO -- use what he uses

=head1 VERSION

version 0.001

=head1 TASK CONTENTS

=head2 Archiving / Compression

=head3 L<Archive::Zip>

For working with .zip archives

=head3 L<Compress::LZ4Frame> 0.011001

Version 0.011001 required because: For fast compression and decompression of data

=head2 Code Quality

=head3 L<Perl::Critic>

The standard

=head3 L<Perl::Critic::Lax>

ot so strict rules for Perl::Critic

=head3 L<Perl::Tidy>

The other standard

=head3 L<Devel::Cover>

Check code coverage

=head3 L<Const::Fast>

For named constants

=head3 L<Try::Tiny::Retry>

This one is based on Try::Tiny, so it comes with try, catch and finally.
It also comes with retry and some more functions allowing to try multiple
times before failing.

=head2 Performance

=head3 L<Devel::NYTProf>

Great profiler for finding bottlenecks

=head3 L<Inline::C>

For quick testing XS algorithms

=head2 Web-Development

=head3 L<Dancer2>

A nice and easy to use web framework

=head2 Package management

=head3 L<App::cpanminus>

My favorite cpan client

=head3 L<App::cpm>

Maybe my new favorite cpan client

=head2 Tools for building CPAN distributions

=head3 L<Dist::Zilla> 5

Version 5 required because: You don't want to make dists without it

=head3 L<Dist::Zilla::PluginBundle::Starter>

Better than the old Basic

=head3 L<Dist::Zilla::PluginBundle::Git>

Because everybody should use Git

=head3 L<Dist::Zilla::Plugin::GithubMeta>

Useful for projects hosted on Github

=head3 L<Pod::Weaver> 4

Version 4 required because: For POD generation

=head3 L<Pod::Elemental::Transformer::List>

So PodWeaver can make list cool

=head2 Other libraries

=head3 L<Moose>

The standard OO library

=head3 L<Data::Dumper>

For all your variable dumping needs

=head3 L<Log::Log4perl>

For logging

=head3 L<Devel::PPPort>

For a better XS development experience

=head1 AUTHOR

Felix Bytow <drako@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Felix Bytow.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
