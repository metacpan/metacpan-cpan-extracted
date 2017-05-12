package Task::Dancer;
use strict;
use warnings;
our $VERSION = '0.39';

1;

__END__

=head1 NAME

Task::Dancer - Dancer in a box

=head1 VERSION

Version 0.39

=head1 DESCRIPTION

This Task installs Dancer, optional engines, templates and assorted
modules that are not included in the Dancer core distribution.

If you've written anything relating to Dancer, please let us know.

We try to maintain a list of modules that are maintained and install
properly. If any of the modules C<Task::Dancer> tried to install
failing, warn us, so we can temporarily disable it. Also, tell us
if any module temporarily disabled is working again.

=head1 INCLUDES MODULES

=head2 Template Engines

=over 4

=item L<Dancer::Template::Alloy>

=item L<Dancer::Template::Haml>

=item L<Dancer::Template::HtmlTemplate>

=item L<Dancer::Template::Mason>

=item L<Dancer::Template::Mason2>

=item L<Dancer::Template::MicroTemplate>

=item L<Dancer::Template::MojoTemplate>

=item L<Dancer::Template::TemplateFlute>

=item L<Dancer::Template::TemplateSandbox>

=item L<Dancer::Template::Tenjin>

=item L<Dancer::Template::Tiny>

=item L<Dancer::Template::Xslate>

=back

=head2 Logging Engines

=over 4

=item L<Dancer::Logger::ColorConsole>

=item L<Dancer::Logger::ConsoleSpinner>

=item L<Dancer::Logger::Log4perl>

=item L<Dancer::Logger::Pipe>

=item L<Dancer::Logger::PSGI>

=item L<Dancer::Logger::Syslog>

=back

=head2 Serialization

=over 4

=item L<Dancer::Serializer::UUEncode>

=back

=head2 Session Engines

=over 4

=item L<Dancer::Session::CHI>

=item L<Dancer::Session::Cookie>

=item L<Dancer::Session::KiokuDB>

=item L<Dancer::Session::Memcached>

=item L<Dancer::Session::MongoDB>

=item L<Dancer::Session::PSGI>

=item L<Dancer::Session::Storable>

=back

=head2 Plugins

=over 4

=item L<Dancer::Plugin::Async>

=item L<Dancer::Plugin::Auth::Basic>

=item L<Dancer::Plugin::Auth::Htpasswd>

=item L<Dancer::Plugin::Auth::Extensible>

=item L<Dancer::Plugin::Auth::Tiny>

=item L<Dancer::Plugin::Auth::Twitter>

=item L<Dancer::Plugin::Bcrypt>

=item L<Dancer::Plugin::Browser>

=item L<Dancer::Plugin::Cache::CHI>

=item L<Dancer::Plugin::Captcha::SecurityImage>

=item L<Dancer::Plugin::Database>

=item L<Dancer::Plugin::DBIC>

=item L<Dancer::Plugin::DebugDump>

=item L<Dancer::Plugin::DebugToolbar>

=item L<Dancer::Plugin::DirectoryView>

=item L<Dancer::Plugin::Email>

=item L<Dancer::Plugin::EncodeID>

=item L<Dancer::Plugin::EscapeHTML>

=item L<Dancer::Plugin::Feed>

=item L<Dancer::Plugin::FlashMessage>

=item L<Dancer::Plugin::FlashNote>

=item L<Dancer::Plugin::FormattedOutput>

=item L<Dancer::Plugin::FormValidator>

=item L<Dancer::Plugin::Hosts>

=item L<Dancer::Plugin::LibraryThing>

=item L<Dancer::Plugin::Memcached>

=item L<Dancer::Plugin::MemcachedFast>

=item L<Dancer::Plugin::MobileDevice>

=item L<Dancer::Plugin::Mongo>

=item L<Dancer::Plugin::Nitesi>

=item L<Dancer::Plugin::NYTProf>

=item L<Dancer::Plugin::Params::Normalization>

=item L<Dancer::Plugin::Passphrase>

=item L<Dancer::Plugin::Preprocess::Sass>

=item L<Dancer::Plugin::Progress>

=item L<Dancer::Plugin::ProxyPath>

=item L<Dancer::Plugin::Redis>

=item L<Dancer::Plugin::REST>

=item L<Dancer::Plugin::Scoped> (temporarily disabled)

=item L<Dancer::Plugin::SimpleCRUD>

=item L<Dancer::Plugin::SiteMap>

=item L<Dancer::Plugin::SMS>

=item L<Dancer::Plugin::SporeDefinitionControl> (disabled)

=item L<Dancer::Plugin::Stomp>

=item L<Dancer::Plugin::TimeRequest>

=item L<Dancer::Plugin::Thumbnail>

=item L<Dancer::Plugin::ValidateTiny>

=item L<Dancer::Plugin::XML::RSS>

=back

=head1 More Plack middlewares

=over 4

=item L<Dancer::Middleware::Rebase>

=item L<Dancer::Debug>

=back

=head1 AUTHOR

Sawyer X, C<xsawyerx AT cpan DOT org>

Alberto Simoes, C<ambs AT cpan DOT org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-dancer at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Dancer>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Dancer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Dancer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Dancer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Dancer>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Dancer/>

=back

=head1 ACKNOWLEDGEMENTS

L<Dancer> team.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

