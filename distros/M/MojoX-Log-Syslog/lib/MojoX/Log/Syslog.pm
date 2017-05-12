package MojoX::Log::Syslog;

use strict;
use warnings;
our $VERSION = '0.01';

use Mojo::Base 'Mojo::Log';
use File::Basename 'basename';
use Sys::Syslog qw(:DEFAULT setlogsock);
use Mojo::Util qw(encode);

has 'facility' => sub { 'USER' };
has 'ident'    => sub { basename($0) };
has 'logopt'   => sub { 'pid' };

sub append {
    my ($self, $msg) = @_;

    if (! $self->{log_opened}) {
        openlog($self->{ident}, $self->{logopt}, $self->{facility});
        $self->{log_opened} = 1;
    }

    my $this_level = $self->history ? $self->history->[-1]->[1] : 'debug'; # level
    my $syslog_levels = {
        debug   => 'debug',
        info    => 'info',
        warn    => 'warning',
        error   => 'err',
        fatal   => 'err', # FIX
    };
    my $level = $syslog_levels->{$this_level} || 'debug';

    return syslog($level, encode('UTF-8', $msg));
}

1;
__END__

=encoding utf-8

=head1 NAME

MojoX::Log::Syslog - Blah blah blah

=head1 SYNOPSIS

    use MojoX::Log::Syslog;

    $app->log( MojoX::Log::Syslog->new(
        facility => 'LOCAL1',
        ident    => 'my_app_name',
        logopt   => 'ndelay,pid'
    ) );

=head1 DESCRIPTION

MojoX::Log::Syslog provies a L<Mojo::Log> implementation that uses L<Sys::Syslog>
as the underlying log mechanism.

=head2 LOG LEVELS

Mojo::Log's fatal() processed same as error() because L<Sys::Syslog> doesn't
support that log level.

=head1 ATTRIBUTES

L<MojoX::Log::Syslog> implements the following attributes.

=head2 facility

syslog facility, default to USER

=head2 ident

syslog ident, default to basename($0)

=head2 logopt

syslog logopt, default to 'pid'

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
