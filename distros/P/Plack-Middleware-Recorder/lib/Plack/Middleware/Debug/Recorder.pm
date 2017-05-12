## no critic (RequireUseStrict)
package Plack::Middleware::Debug::Recorder;
$Plack::Middleware::Debug::Recorder::VERSION = '0.06';
## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Plack::Middleware::Debug::Base';

sub run {
    my ( $self, $env, $panel ) = @_;

    $panel->title('Recorder');

    return sub {
        my ( $res ) = @_;

        unless(exists $env->{'Plack::Middleware::Recorder.active'}) {
            $panel->disabled(1);
            return;
        }

        my $status = $env->{'Plack::Middleware::Recorder.active'}
            ? 'ON'
            : 'OFF';

        my $color     = $status eq 'ON' ? 'green' : 'red';
        my $start_url = $env->{'Plack::Middleware::Recorder.start_url'};
        my $stop_url  = $env->{'Plack::Middleware::Recorder.stop_url'};

        my $content = <<HTML;
<div class='plRecorderStatus'>
Request recording is <span style='color: $color'>$status</span>
</div>
<div>
    <button class='plRecorderStart'>Start Recording</button>
    <br />
    <button class='plRecorderStop'>Stop Recording</button>
</div>
<script type='text/javascript'>
    (function(\$) {
        \$(document).ready(function() {
            \$('.plRecorderStart').click(function() {
                \$.get('$start_url', function(data) {
                    \$('.plRecorderStatus').html('Request recording is <span style="color: green">ON</span>');
                });
            });
            \$('.plRecorderStop').click(function() {
                \$.get('$stop_url', function(data) {
                    \$('.plRecorderStatus').html('Request recording is <span style="color: red">OFF</span>');
                });
            });
        });
    })(jQuery);
</script>
HTML

        $panel->content($content);
    };
}

1;

# ABSTRACT: Debug panel to communicate with the Recorder middleware

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Debug::Recorder - Debug panel to communicate with the Recorder middleware

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  builder {
    enable 'Recorder', output => $output;
    enable 'Debug', panels => [qw/Recorder/];
    $app;
  };

=head1 DESCRIPTION

This debug panel displays the current state of the recorder middleware (whether or not it's currently recording),
and provides some buttons for turning recording on or off.

=head1 SEE ALSO

L<Plack::Middleware::Recorder>, L<Plack::Middleware::Debug>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/hoelzro/plack-middleware-recorder/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
