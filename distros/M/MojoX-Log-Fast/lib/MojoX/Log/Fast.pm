package MojoX::Log::Fast;

use Mojo::Base 'Mojo::Log';
use Carp 'croak';

our $VERSION = 'v1.0.1';

use Log::Fast;


my %MapLevel = (
    debug   => 'DEBUG',
    info    => 'INFO',
    warn    => 'WARN',
    error   => 'ERR',
    fatal   => 'ERR',
);


sub new {
    my $self = shift->SUPER::new();
    $self->{'_logger'} = shift || Log::Fast->global();
    if ($ENV{MOJO_LOG_LEVEL}) {
        $self->level($ENV{MOJO_LOG_LEVEL});
    }
    else {
        $self->level({reverse %MapLevel}->{ $self->{_logger}->level });
    }
    $self->unsubscribe('message');
    $self->on(message => \&_message);
    return $self;
}

sub config  { return shift->{'_logger'}->config(@_); }
sub ident   { return shift->{'_logger'}->ident(@_); }

sub handle  { croak q{log->handle: not supported, use log->config} };
sub path    { croak q{log->path: not supported, use log->config} };
sub format  { croak q{log->format: not implemented} }; ## no critic(ProhibitBuiltinHomonyms)

sub level {
    if (@_ == 1) {
        return $_[0]{'level'} if exists $_[0]{'level'};
        return $_[0]{'level'} = 'debug';
    }
    $_[0]{'level'} = $ENV{MOJO_LOG_LEVEL} || $_[1];
    $_[0]{'_logger'}->level($MapLevel{ $ENV{MOJO_LOG_LEVEL} || $_[1] });
    return $_[0];
}

sub _message {
    my ($self, $level, @lines) = @_;
    if ($level eq 'debug') {
        $self->{'_logger'}->DEBUG(join "\n", @lines);
    } elsif ($level eq 'info') {
        $self->{'_logger'}->INFO(join "\n", @lines);
    } elsif ($level eq 'warn') {
        $self->{'_logger'}->WARN(join "\n", @lines);
    } else { # error, fatal
        $self->{'_logger'}->ERR(join "\n", @lines);
    }
    return;
}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

MojoX::Log::Fast - Log::Fast for Mojolicious


=head1 VERSION

This document describes MojoX::Log::Fast version v1.0.1


=head1 SYNOPSIS

    use MojoX::Log::Fast;

    $app->log( MojoX::Log::Fast->new() );

    $app->log->config(...);
    $app->log->ident(...);


=head1 DESCRIPTION

This module provides a L<Mojo::Log> implementation that uses L<Log::Fast>
as the underlying log mechanism. It provides Log::Fast methods config(),
ident() and all Mojo::Log methods except handle(), path() and format().

=head2 LOG LEVELS

Mojo::Log's fatal() processed same as error() because Log::Fast doesn't
support that log level.

Log::Fast's NOTICE() level not available because Mojo::Log doesn't support
that log level.


=head1 INTERFACE 

=head2 new

        $log = MojoX::Log::Fast->new();
        $log = MojoX::Log::Fast->new( $logfast );

If Log::Fast instance $logfast doesn't provided then Log::Fast->global()
will be used by default.

=head2 config

=head2 ident

        $log->config( @params );
        $log->ident( @params );

Proxy these methods with given @params to Log::Fast instance.

=head2 handle

=head2 path

Not compatible with Log::Fast and thus not supported.

=head2 format

Not implemented yet, use much more flexible config() instead.

Let me know if you needs it.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-MojoX-Log-Fast/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-MojoX-Log-Fast>

    git clone https://github.com/powerman/perl-MojoX-Log-Fast.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=MojoX-Log-Fast>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/MojoX-Log-Fast>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Log-Fast>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=MojoX-Log-Fast>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/MojoX-Log-Fast>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
