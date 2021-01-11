package Task::OpenTracing;

use version; our $VERSION = version->declare('v0.0.1');

1;

__END__
=pod

=encoding utf8

=head1 NAME

Task::OpenTracing - install all the OpenTracing modules

=head1 SYNOPSIS

  cpanm Task::OpenTracing
  cpanm --with-feature=integrations --with-feature=development Task::OpenTracing

=head1 BUNDLES

=head2 Base

=over

=item L<OpenTracing::GlobalTracer>

=item L<OpenTracing::Implementation>

=item L<OpenTracing::Implementation::NoOp>

=item L<OpenTracing::Manual>

=back

=head2 instrumentation

  cpanm --with-feature=instrumentation Task::OpenTracing

=over

=item L<OpenTracing::AutoScope>

=item L<OpenTracing::WrapScope>

=back

=head2 integrations

  cpanm --with-feature=integrations Task::OpenTracing

=over

=item L<DBIx::OpenTracing>

=item L<CGI::Application::Plugin::OpenTracing>

=item L<Log::Log4perl::OpenTracing>

=back

=head2 development

  cpanm --with-feature=development Task::OpenTracing

=over

=item L<OpenTracing::Implementation::Test>

=item L<OpenTracing::Interface>

=item L<OpenTracing::Types>

=item L<OpenTracing::Role>

=item L<Test::OpenTracing::Integration>

=back

=head2 datadog

  cpanm --with-feature=datadog Task::OpenTracing

=over

=item L<OpenTracing::Implementation::DataDog>

=item L<CGI::Application::Plugin::OpenTracing::DataDog>

=back

=head1 AUTHOR

Szymon Nieznański <snieznanski@perceptyx.com>

=head1 LICENSE AND COPYRIGHT

'Task::OpenTracing' is Copyright (C) 2021, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.

=cut
