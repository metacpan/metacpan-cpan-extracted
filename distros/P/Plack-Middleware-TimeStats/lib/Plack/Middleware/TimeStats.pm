package Plack::Middleware::TimeStats;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw/callback psgix option action/;
use Devel::TimeStats;

our $VERSION = '0.06';

sub prepare_app {
    my $self = shift;

    if ($self->psgix) {
        $self->psgix('psgix.'. $self->psgix);
    }
    else {
        $self->psgix('psgix.timestats');
    }

    $self->option(+{
        percentage_decimal_precision => 2,
    }) unless $self->option;

    $self->callback(
        sub {
            my ($stats, $env, $res) = @_;
            warn scalar($stats->report);
        }
    ) unless $self->callback;
}

sub call {
    my($self, $env) = @_;

    $env->{$self->psgix} = Devel::TimeStats->new($self->option);

    my $action = $self->action ? $self->action->($env) : $env->{PATH_INFO};

    $env->{$self->psgix}->profile(
        begin   => $action,
        comment => '',
    );

    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res = shift;

        $env->{$self->psgix}->profile(
            end => $action,
        );

        $self->callback->($env->{$self->psgix}, $env, $res);
        return;
    });
}


1;

__END__

=head1 NAME

Plack::Middleware::TimeStats - Plack Timing Statistics Middleware


=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "TimeStats";

        sub {
            my $env = shift;
            $env->{"psgix.timestats"}->profile("foo");
            [ 200, [], ["OK"] ]
        };
    };


=head1 DESCRIPTION

Plack::Middleware::TimeStats is the Plack middleware for getting a timing statistics.

This module provides the default, put a timing statistics to STDERR at the end of request, like below.

    .--------+-----------+---------.
    | Action | Time      | %       |
    +--------+-----------+---------+
    | /      | 0.000574s | 100.00% |
    |  - foo | 0.000452s | 78.75%  |
    '--------+-----------+---------'

=head2 HOW TO GET A STATS IN YOUR APP

You can get a timing profile by C<< $env->{"psgix.timestats"} >>. It's a L<Devel::TimeStats> object. So you call C<profile> method with an action string, then stack a timing stats.

    $env->{"psgix.timestats"}->profile("foo");

Check more methods in document of L<Devel::TimeStats>.


=head1 MIDDLEWARE OPTIONS

This module has few options.

=head2 callback : code reference

Default is to output a stats result to STDERR.

=head2 psgix : string

The key of psgix extension. Default is C<psgix.timestats>. You can NOT specify prefix C<psgix.>. It is required.

    enable "TimeStats";                     # 'psgix.timestats'
    enable "TimeStats", psgix => 'mystats'; # 'psgix.mystats'

=head2 option : hash reference

C<option> passes through to Devel::TimeStats's constructor.

=head2 action : code reference

Default is C<PATH_INFO>. You can set this option as code reference.


=head1 METHODS

=over

=item call

=item prepare_app

=back


=head1 REPOSITORY

Plack::Middleware::TimeStats is hosted on github
L<http://github.com/bayashi/Plack-Middleware-TimeStats>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Devel::TimeStats>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
