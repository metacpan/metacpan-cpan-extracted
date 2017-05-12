package Task::Dancer2;
use strict;
use warnings;
our $VERSION = '0.06';

1;

__END__

=head1 NAME

Task::Dancer2 - Dancer2... in a box!

=head1 VERSION

Version 0.06

=head1 DESCRIPTION

This Task installs Dancer2, optional engines, templates and assorted
modules that are not included in the Dancer2 core distribution. It is
based heavily on the awesome L<Task::Dancer> distribution by Sawyer X
and ambs.

If you've written anything relating to Dancer2, please let us know.

We try to maintain a list of modules that are maintained and install
properly. If any of the modules in C<Task::Dancer2> tried to install
and failed, please let us know so we can temporarily disable it. Also, 
tell us if any module that was temporarily disabled is working again.

=head1 INCLUDES MODULES

=head2 Template Engines

=over 4

=item L<Dancer2::Template::Caribou> (disabled)

=item L<Dancer2::Template::Haml>

=item L<Dancer2::Template::HTCompiled>

=item L<Dancer2::Template::Mason2>

=item L<Dancer2::Template::MojoTemplate>

=item L<Dancer2::Template::TemplateFlute>

=item L<Dancer2::Template::TextTemplate>

=item L<Dancer2::Template::Xslate> (disabled)

=back

=head2 Logging Engines

=over 4

=item L<Dancer2::Logger::Console::Colored>

=item L<Dancer2::Logger::File::RotateLogs>

=item L<Dancer2::Logger::Syslog>

=back

=head2 Serialization

=over 4

=item L<Dancer2::Serializer::CBOR>

=back

=head2 Session Engines

=over 4

=item L<Dancer2::Session::CGISession>

=item L<Dancer2::Session::Cookie>

=item L<Dancer2::Session::DBIC>

=item L<Dancer2::Session::JSON> 

=item L<Dancer2::Session::Memcached>

=item L<Dancer2::Session::MongoDB> (disabled)

=item L<Dancer2::Session::PSGI>

=item L<Dancer2::Session::Redis>

=item L<Dancer2::Session::Sereal> (disabled)

=back

=head2 Plugins

=over 4

=item L<Dancer2::Plugin::Adapter>

=item L<Dancer2::Plugin::Ajax>

=item L<Dancer2::Plugin::AppRole::Helper>

=item L<Dancer2::Plugin::Articulate>

=item L<Dancer2::Plugin::Auth::Extensible>

=item L<Dancer2::Plugin::Auth::Extensible::Provider::DBIC>

=item L<Dancer2::Plugin::Auth::Extensible::Provider::Usergroup>

=item L<Dancer2::Plugin::Auth::HTTP::Basic::DWIW>

=item L<Dancer2::Plugin::Auth::OAuth>

=item L<Dancer2::Plugin::Auth::Tiny>

=item L<Dancer2::Plugin::Auth::YARBAC> (disabled)

=item L<Dancer2::Plugin::BrowserDetect>

=item L<Dancer2::Plugin::Cache::CHI>

=item L<Dancer2::Plugin::Captcha> 

=item L<Dancer2::Plugin::Chain>

=item L<Dancer2::Plugin::ConditionalCaching>

=item L<Dancer2::Plugin::Database>

=item L<Dancer2::Plugin::DataTransposeValidator>

=item L<Dancer2::Plugin::DBIC>

=item L<Dancer2::Plugin::Deferred>

=item L<Dancer2::Plugin::ElasticSearch> (disabled)

=item L<Dancer2::Plugin::Email>

=item L<Dancer2::Plugin::Emailesque>

=item L<Dancer2::Plugin::Feed>

=item L<Dancer2::Plugin::GoogleAnalytics>

=item L<Dancer2::Plugin::Growler>

=item L<Dancer2::Plugin::HTTP::Auth::Extensible> (disabled)

=item L<Dancer2::Plugin::JWT>

=item L<Dancer2::Plugin::Locale> (disabled)

=item L<Dancer2::Plugin::Locale::Wolowitz> (disabled)

=item L<Dancer2::Plugin::LogContextual>

=item L<Dancer2::Plugin::LogReport>

=item L<Dancer2::Plugin::Model>

=item L<Dancer2::Plugin::Multilang>

=item L<Dancer2::Plugin::Negotiate>

=item L<Dancer2::Plugin::ParamKeywords>

=item L<Dancer2::Plugin::Passphrase>

=item L<Dancer2::Plugin::Path::Class>

=item L<Dancer2::Plugin::ProgressStatus>

=item L<Dancer2::Plugin::Queue> 

=item L<Dancer2::Plugin::Queue::MongoDB> 

=item L<Dancer2::Plugin::reCAPTCHA>

=item L<Dancer2::Plugin::Redis>

=item L<Dancer2::Plugin::Res>

=item L<Dancer2::Plugin::REST>

=item L<Dancer2::Plugin::RootURIFor>

=item L<Dancer2::Plugin::RoutePodCoverage>

=item L<Dancer2::Plugin::Sixpack>

=item L<Dancer2::Plugin::Syntax::GetPost>

=item L<Dancer2::Plugin::UnicodeNormalize>

=back

=head1 AUTHOR

Jason A. Crome C< cromedome AT cpan DOT org >

=head1 CONTRIBUTORS

Rory Zweistra

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-dancer at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Dancer>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Dancer2

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Dancer2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Dancer2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Dancer2>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Dancer2/>

=back

=head1 ACKNOWLEDGEMENTS

L<Dancer2> team.

Sawyer X, C<xsawyerx AT cpan DOT org>

Alberto Simoes, C<ambs AT cpan DOT org>

=head1 LICENSE AND COPYRIGHT

Copyright 2015, Jason A. Crome.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

