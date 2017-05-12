use 5.008;
use strict;
use warnings;

package Task::BeLike::hanekomu;
BEGIN {
  $Task::BeLike::hanekomu::VERSION = '1.103620';
}
# ABSTRACT: Install modules I like
1;


__END__
=pod

=head1 NAME

Task::BeLike::hanekomu - Install modules I like

=head1 VERSION

version 1.103620

=head1 DESCRIPTION

This L<Task> installs modules that I need to work with. They are listed in
this distribution's C<Makefile.PL>.

=head1 TASK CONTENTS

=head2 Toolchain

=head3 L<App::Ack>

=head3 L<App::Rgit>

=head3 L<DB::Pluggable>

=head3 L<DB::Pluggable::StackTraceAsHTML>

=head3 L<Devel::NYTProf>

=head3 L<Devel::Loaded>

=head3 L<Devel::SearchINC>

=head3 L<Perl::Tidy>

=head3 L<Pod::Wordlist::hanekomu>

=head3 L<Dist::Zilla>

=head3 L<Dist::Zilla::PluginBundle::MARCEL>

=head3 L<Pod::Weaver::PluginBundle::MARCEL>

=head3 L<Dist::Zilla::Plugin::Git::Init>

=head3 L<App::cpanoutdated>

=head3 L<App::cpanminus>

=head3 L<App::distfind>

=head3 L<Pod::Coverage::TrustPod>

=head2 Useful modules

=head3 L<YAML>

=head3 L<DBI>

=head3 L<DBD::SQLite>

=head3 L<File::Which>

=head3 L<File::Slurp>

=head3 L<Test::Differences>

=head2 Web, Networking, Events

=head3 L<LWP>

=head3 L<Web::Scraper>

=head3 L<Coro>

=head3 L<AnyEvent>

=head3 L<Task::Plack>

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Task-BeLike-hanekomu>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Task-BeLike-hanekomu/>.

The development version lives at L<http://github.com/hanekomu/Task-BeLike-hanekomu.git>
and may be cloned from L<git://github.com/hanekomu/Task-BeLike-hanekomu.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=cut

