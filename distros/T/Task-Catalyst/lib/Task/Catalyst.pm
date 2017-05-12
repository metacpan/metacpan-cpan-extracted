use strict;
use warnings;

package Task::Catalyst;
BEGIN {
  $Task::Catalyst::VERSION = '4.02';
}
# ABSTRACT: All you need to start with Catalyst


1;

__END__
=pod

=head1 NAME

Task::Catalyst - All you need to start with Catalyst

=head1 VERSION

version 4.02

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Task::Catalyst'>

=head1 DESCRIPTION

Installs everything you need to write serious Catalyst applications.

=head1 TASK CONTENTS

=head2 Core Modules

=head3 L<Catalyst> 5.80

=head3 L<Catalyst::Devel> 1.26

=head3 L<Catalyst::Manual> 5.80

=head2 Recommended Models

=head3 L<Catalyst::Model::Adaptor>

=head3 L<Catalyst::Model::DBIC::Schema>

=head2 Recommended Views

=head3 L<Catalyst::View::TT>

=head3 L<Catalyst::View::Email>

=head2 Recommended Components

=head3 L<Catalyst::Controller::ActionRole>

=head3 L<CatalystX::Component::Traits>

=head3 L<CatalystX::SimpleLogin>

=head3 L<Catalyst::Action::REST>

=head3 L<Catalyst::Component::InstancePerContext>

=head2 Session Support

=head3 L<Catalyst::Plugin::Session>

=head3 L<Catalyst::Plugin::Session::State::Cookie>

=head3 L<Catalyst::Plugin::Session::Store::File>

=head3 L<Catalyst::Plugin::Session::Store::DBIC>

=head2 Authentication and Authorization

=head3 L<Catalyst::Plugin::Authentication>

=head3 L<Catalyst::Authentication::Store::DBIx::Class>

=head3 L<Catalyst::Authentication::Credential::HTTP>

=head3 L<Catalyst::ActionRole::ACL>

=head2 Recommended Plugins

=head3 L<Catalyst::Plugin::Static::Simple>

=head3 L<Catalyst::Plugin::Unicode::Encoding>

=head3 L<Catalyst::Plugin::I18N>

=head3 L<Catalyst::Plugin::ConfigLoader>

=head2 Testing, Debugging and Profiling

=head3 L<Test::WWW::Mechanize::Catalyst>

=head3 L<Catalyst::Plugin::StackTrace>

=head3 L<CatalystX::REPL>

=head3 L<CatalystX::LeakChecker>

=head3 L<CatalystX::Profile>

=head2 Deployment

=head3 L<FCGI>

=head3 L<FCGI::ProcManager>

=head3 L<Starman>

=head3 L<local::lib>

=head1 AUTHORS

=over 4

=item *

Sebastian Riedel <sri@oook.de>

=item *

Brian Cassidy <bricas@cpan.org>

=item *

Andy Grundman <andy@hybridized.org>

=item *

Marcus Ramberg <mramberg@cpan.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Rafael Kitover <rkitover@io.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sebastian Riedel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

