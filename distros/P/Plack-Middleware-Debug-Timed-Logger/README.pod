package Plack::Middleware::Debug::Timed::Logger;

use 5.16.0;
use strict;
use warnings;

use parent qw(Plack::Middleware::Debug::Base);
use Plack::Middleware::Timed::Logger;
use Data::Dump;
use List::Util;

=head1 NAME

Plack::Middleware::Debug::Timed::Logger - An Event Log Debug Panel

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = '0.0.5';

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
      enable 'Timed::Logger';
      enable 'Debug', panels =>['Timed::Logger'];
      $app;
    };

=head1 DESCRIPTION

A debug panel that shows information about L<Timed::Logged> events that happend
during the request.

If you are using Dancer to build your web application you may want to use
L<Timed::Logger::Dancer::AdoptPlack> to help you to bridge Dancer's conrollers
with this middleware.

This module was inspired by L<Plack::Middleware::Debug::DBIC::QueryLog>.

=head1 METHODS

=head2 run

A method used by L<Plack::Middleware::Debug> to render a panel.

=head2 vardump

A helper function that renders perl structures into strings.

=cut

my $template = __PACKAGE__->build_template(<<'EOTMPL');
% while(my ($name, $log) = each(%{$_[0]->{logger}->log})) {
<h3><%= $name %>:</h3>
<table>
    <thead>
        <tr>
            <th>Type</th>
            <th>Service</th>
            <th>Path</th>
            <th>Elapsed</th>
            <th>Response</th>
            <th>Request</th>
        </tr>
    </thead>
    <tbody>
%   my $i;
%   foreach (sort { $a->started <=> $b->started } @{$log}) {
        <tr class="<%= ++$i % 2 ? 'plDebugOdd' : 'plDebugEven' %>">
%         if (defined($_->data->{type})) {
            <td><%= $_->data->{type} %></td>
%         } else {
            <td>(undef)</td>
%         }
%         if (defined($_->data->{id})) {
            <td><%= $_->data->{id} %></td>
%         } else {
            <td>(undef)</td>
%         }
%         if (defined($_->data->{path})) {
            <td><%= $_->data->{path} %></td>
%         } else {
            <td>(undef)</td>
%         }
            <td><%= sprintf('%.4f', $_->elapsed) %></td>
            <td><pre><%= vardump($_->data->{response}) %></pre></td>
            <td><pre><%= vardump($_->data->{request}) %></pre></td>
        </tr>
%   }
        <tr>
            <th colspan="6"><%= sprintf('Elapsed total: %.4f s', $_[0]->{logger}->elapsed_total($name)) %></th>
        </tr>
    </tbody>
</table>
% }
EOTMPL

sub vardump {
    my $scalar = shift;
    return '(undef)' unless defined($scalar);
    return "$scalar" unless ref($scalar);
    return scalar(Data::Dump::dump($scalar));
}

sub run {
  my ($self, $env, $panel) = @_;

  return sub {
    $panel->title('Events log');
    $panel->nav_title('Events log');
    my $logger = Plack::Middleware::Timed::Logger->get_logger_from_env($env);
    $panel->nav_subtitle(sprintf('Total: %.4f s', $logger->elapsed_total));
    $panel->content(sub {
                      return $self->render($template, { logger => $logger });
                    });
  };
}

=head1 SEE ALSO

L<Timed::Logger>, L<Plack::Middleware::Timed::Logger>, L<Timed::Logger::Dancer::AdoptPlack>,
L<Plack::Middleware::Debug>

=head1 AUTHOR

Nikolay Martynov, C<< <kolya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-middleware-debug-timed-logger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-Debug-Timed-Logger>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Middleware::Debug::Timed::Logger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-Debug-Timed-Logger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Middleware-Debug-Timed-Logger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Middleware-Debug-Timed-Logger>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Middleware-Debug-Timed-Logger/>

=back


=head1 ACKNOWLEDGEMENTS

Logan Bell and Belden Lyman.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nikolay Martynov and Shutterstock Inc (http://shutterstock.com). All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Plack::Middleware::Debug::Timed::Logger
