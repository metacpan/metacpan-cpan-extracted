#
# This file is part of Task-BeLike-RSRCHBOY-Web
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Task::BeLike::RSRCHBOY::Web;
{
  $Task::BeLike::RSRCHBOY::Web::VERSION = '0.002';
}

# ABSTRACT: Web-related modules RSRCHBOY uses!

!!42;



=pod

=head1 NAME

Task::BeLike::RSRCHBOY::Web - Web-related modules RSRCHBOY uses!

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This is a task package cataloging the web-related modules I often use.  I've
broken it out of L<Task::BeLike::RSRCHBOY> so as to reduce that package's
footprint on machines where these are not needed.

=head1 TASK CONTENTS

=head2 Other Tasks

=head3 L<Task::Catalyst>

=head3 L<Task::BeLike::RSRCHBOY> 0.002

=head2 Catalyst

=head3 L<Catalyst::Runtime> 5.9

=head3 L<Catalyst::Devel>

=head3 L<CatalystX::SimpleLogin>

=head3 L<CatalystX::RoleApplicator>

=head3 L<Catalyst::Plugin::Authentication>

=head3 L<Catalyst::Plugin::Authorization::ACL>

=head3 L<Catalyst::Plugin::Authorization::Roles>

=head3 L<Catalyst::Plugin::AutoCRUD> 1.112560

=head3 L<Catalyst::Plugin::RedirectAndDetach>

=head3 L<Catalyst::Plugin::Session>

=head3 L<Catalyst::Plugin::Session::State::Cookie>

=head3 L<Catalyst::Plugin::Session::Store::File>

=head3 L<Catalyst::TraitFor::Request::BrowserDetect>

=head3 L<Catalyst::TraitFor::Request::REST::ForBrowsers>

=head3 L<Catalyst::Controller::REST>

=head3 L<Catalyst::Model::DBIC::Schema> 0.59

=head3 L<Catalyst::View::TT>

=head3 L<Catalyst::View::Haml>

=head3 L<MooseX::MethodAttributes::Role>

=head2 Dancer

=head3 L<Dancer>

=head2 Plack / PSGI

=head3 L<Plack>

=head3 L<Plack::Middleware::Debug>

=head3 L<Plack::Middleware::MethodOverride> 0.10

=head3 L<Plack::Middleware::SetAccept>

=head3 L<Starlet>

=head3 L<Starman>

=head2 Forms

=head3 L<HTML::FormHandler>

=head2 Templating / etc

=head3 L<HTML::Builder> 0.006

=head3 L<Text::Haml>

=head3 L<Template>

=head3 L<Template::Plugin::JSON::Escape>

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

