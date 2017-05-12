
use strict;

package Plack::Middleware::Debug::Log4perl;

use parent qw(Plack::Middleware::Debug::Base);

our $VERSION = '0.04';

use Log::Log4perl qw(get_logger :levels);
use Log::Log4perl::Layout;
use Log::Log4perl::Level;

use Data::Dumper;

# let's try keeping a handle on the layout
my $timer;

sub run
{
	my($self, $env, $panel) = @_;

	if (Log::Log4perl->initialized()) {

		if (my $appender = Log::Log4perl->appender_by_name('psgi_debug_panel')) {

			$appender->clear();

			$timer->reset() if $timer;
		}
		else {

			my $logger = Log::Log4perl->get_logger("");

			# Define a layout
			my $layout = Log::Log4perl::Layout::PatternLayout->new("%r >> %p >> %m >> %c >> at %F line %L%n");

			# Define an 'in memory' appender
			my $appender = Log::Log4perl::Appender->new(
				"Log::Log4perl::Appender::TestBuffer",
				name => "psgi_debug_panel");

			$appender->layout($layout);

			$logger->add_appender($appender);
			$logger->level($TRACE);

			# hang on to the timer, so we can reset it
			$timer = $layout->{timer};
		}
	}

	return sub {
		my $res = shift;

		if (my $appender = Log::Log4perl->appenders()->{psgi_debug_panel}) {

			my $log = $appender->{appender}->{buffer};

			$log =~ s/ >> /\n/g;
			my $list = [ split '\n', $log ];

			$panel->content( sub { $self->render_list_pairs($list) } );
		}
		else {

			$panel->content( 'Log4perl appender not enabled' );
		}
	};
}

my $list_template = __PACKAGE__->build_template(<<'EOTMPL');
<table>
    <thead>
        <tr>
            <th>Time</th>
            <th>Level</th>
            <th>Message</th>
            <th>Source</th>
            <th>Line</th>
        </tr>
    </thead>
    <tbody>
% my $i;
% while (@{$_[0]->{list}}) {
% my($time, $level, $message, $source, $line) = splice(@{$_[0]->{list}}, 0, 5);
            <tr class="<%= ++$i % 2 ? 'plDebugOdd' : 'plDebugEven' %>">
                <td><%= $time %></td>
                <td><%= $level %></td>
                <td><%= $message %></td>
                <td><%= $source %></td>
                <td><%= $line %></td>
            </tr>
% }
    </tbody>
</table>
EOTMPL

sub render_list_pairs {

    my ($self, $list, $sections) = @_;
    if ($sections) {
        $self->render($list_template, { list => $list });
    }else{
        $self->render($list_template, { list => $list });
    }
}

1;
__END__

=head1 NAME

Plack::Middleware::Debug::Log4perl

Plack debug panel to show detailed Log4perl debug messages.

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::Debug::Log4perl;

    builder {
      enable 'Debug', panels => [qw/Memory Timer Log4perl/];
      enable 'Log4perl', category => 'plack', conf => \$log4perl_conf;
      $app;
    };

=head1 DESCRIPTION

This module provides a plack debug panel that displays the Log4perl messages for the current HTTP request.

Ideally configure Log4perl using Plack::Midleware::Log4perl, or directly in your .psgi file.  This way we can hook into the root logger at run time and create the required stealth logger automatically.  If you're able to do this, you can skip the next bit.

For applications that configure / init their own logger, you must create a Log4perl appender using TestBuffer, named 'log4perl_debug_panel'.

In your Log4perl.conf:

    log4perl.rootLogger = TRACE, DebugPanel

    log4perl.appender.DebugPanel              = Log::Log4perl::Appender::TestBuffer
    log4perl.appender.DebugPanel.name         = psgi_debug_panel
    log4perl.appender.DebugPanel.mode         = append
    log4perl.appender.DebugPanel.layout       = PatternLayout
    log4perl.appender.DebugPanel.layout.ConversionPattern = %r >> %p >> %m >> %c >> at %F line %L%n
    log4perl.appender.DebugPanel.Threshold = TRACE

=head1 SEE ALSO

Log4perl: L<Log::Log4perl>

Plack Debug Panel: L<Plack::Middleware::Debug>

Source Repository: L<http://github.com/miketonks/Plack-Middleware-Debug-Log4perl>

=head1 AUTHORS

Mike Tonks

Thanks to Lyle Hopkins (Bristol & Bath Perl Mongers) for help with the threading tests.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

