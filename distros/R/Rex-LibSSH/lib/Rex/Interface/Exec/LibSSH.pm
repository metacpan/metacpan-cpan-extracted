# ABSTRACT: Rex command execution via Net::LibSSH exec channels

package Rex::Interface::Exec::LibSSH;
our $VERSION = '0.004';
use strict;
use warnings;

use Rex;
use Rex::Config;
use Rex::Logger;
use Rex::Commands;
use Rex::Interface::Shell;
use Rex::Interface::Exec::Base;
use base qw(Rex::Interface::Exec::Base);

sub new {
    my ( $that, %args ) = @_;
    my $proto = ref($that) || $that;
    return bless {%args}, $proto;
}

# 3-arg signature is the one Rex::Commands::Run::run actually invokes:
#   $exec->exec($cmd, $path, $option)
# The 2-arg form on Base.pm leaves $path glued onto $option, which means
# the env hash never reaches us. Mimic Rex::Interface::Exec::SSH here so
# environment variables are routed through a shell wrapper.
sub exec {
    my ( $self, $cmd, $path, $option ) = @_;

    Rex::Logger::debug("LibSSH/preparing: $cmd");

    my $shell;
    if ( $option && $option->{_force_sh} ) {
        $shell = Rex::Interface::Shell->create("Sh");
    }
    else {
        $shell = $self->shell;
    }

    $shell->set_locale("C");
    $shell->path($path);

    if ( Rex::Config->get_source_global_profile ) {
        $shell->source_global_profile(1);
    }
    if ( Rex::Config->get_source_profile ) {
        $shell->source_profile(1);
    }

    if ( $option && exists $option->{env} ) {
        $shell->set_environment( $option->{env} );
    }

    my $wrapped = $shell->exec( $cmd, $option );
    Rex::Logger::debug("LibSSH/executing: $wrapped");

    my ( $out, $err ) = $self->_exec( $wrapped, $option );

    Rex::Logger::debug($out) if $out;
    if ($err) {
        Rex::Logger::debug("========= ERR ============");
        Rex::Logger::debug($err);
        Rex::Logger::debug("========= ERR ============");
    }

    return wantarray ? ( $out, $err ) : $out;
}

sub _exec {
    my ( $self, $cmd, $option ) = @_;

    my $ssh = Rex::is_ssh()
        or die "LibSSH exec: no active SSH connection";

    Rex::Logger::debug("LibSSH exec: $cmd");

    my $ch = $ssh->channel
        or die "LibSSH exec: failed to open channel";

    $ch->exec($cmd);

    my ( $out, $err ) = ( '', '' );

    # libssh processes all SSH protocol messages (including stderr window
    # adjustments) while blocking on the stdout read, so this sequential
    # approach is safe against deadlocks.
    $out = $ch->read;
    $err = $ch->read( -1, 1 );

    my $exit = $ch->exit_status;
    $ch->close;

    $? = $exit << 8;

    if ( ref $option eq 'HASH' && defined $out ) {
        $self->_continuous_read( $_, $option ) for split /\n/, $out;
    }

    return ( $out, $err );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Interface::Exec::LibSSH - Rex command execution via Net::LibSSH exec channels

=head1 VERSION

version 0.004

=head1 DESCRIPTION

L<Rex::Interface::Exec::LibSSH> implements Rex command execution using
L<Net::LibSSH> exec channels. Each C<run()> call opens a new channel,
executes the command, reads stdout and stderr, retrieves the exit status,
and closes the channel.

=head1 SEE ALSO

L<Rex::Interface::Connection::LibSSH>, L<Net::LibSSH::Channel>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-libssh/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
