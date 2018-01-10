package Mojolicious::Plugin::JIPConf;

use Mojo::Base 'Mojolicious::Plugin';

use JIP::Conf;
use Carp qw(croak);
use English qw(-no_match_vars);

our $VERSION = '0.021';

sub register {
    my ($self, $app, $param_hashref) = @ARG;

    my $helper_name = $param_hashref->{'helper_name'};

    croak q{Bad argument "helper_name"}
        unless defined $helper_name and length $helper_name;

    my $conf = JIP::Conf::init(
        map { $param_hashref->{$_} } qw(path_to_file path_to_variable),
    );

    croak(sprintf q{Plugin "%s" already exists in $app}, $helper_name)
        if $app->can($helper_name);

    $app->helper($helper_name => sub { $conf });

    return $app->$helper_name;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::JIPConf - Plugin for JIP::Conf.

=head1 VERSION

This document describes C<Mojolicious::Plugin::JIPConf> version C<0.021>.

=head1 SYNOPSIS

=head2 Mojolicious

    sub startup {
        my $self = shift;

        my $conf = $self->plugin('JIPConf', {
            helper_name      => 'conf',
            path_to_file     => $self->home->rel_file('my_settings.pm'),
            path_to_variable => 'My::settings',
        });

        $self->app->log->info($conf->user->greeting);
    }

    # in controller
    sub my_controller_action {
        my $self = shift;

        my $conf = $self->conf;

        render $self->render(text => $conf->user->greeting);
    }

=head2 Mojolicious::Lite

    my $conf = plugin JIPConf => {
        helper_name      => 'conf',
        path_to_file     => app->home->rel_file('my_settings.pm'),
        path_to_variable => 'My::settings',
    };

    app->log->info($conf->user->greeting);

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2018 Vladimir Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

