package Term::Multiplexed;

use strict;
use warnings;
use POSIX qw(access X_OK);

use vars qw($VERSION @EXPORT @EXPORT_OK @ISA);
$VERSION = "0.2";

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = ();
    @EXPORT_OK = qw(multiplexed multiplexer muxsocket attached detached);
}

BEGIN {
    require constant;
    my ($socket, $multiplexer);
    if(defined($ENV{STY})) {
        my $out = `LC_ALL="C" screen -ls`;
        if($out !~ /^No Sockets found/s) {
            $out =~ s/^.+\d+ Sockets? in (.*?)\/?\.\n.+$/$1/s;
            $socket = "$out/$ENV{STY}";
            $multiplexer = "screen";
        }
    }
    elsif(defined($ENV{TMUX})) {
        $socket = $ENV{TMUX};
        $socket =~ s/(,\d+)+$//;
        $multiplexer = "tmux";
    }
    constant->import({
        multiplexed => !!$socket,
        multiplexer => $multiplexer,
        muxsocket => $socket,
    });
}

sub attached { 
    if(multiplexed) {
        return !!access(muxsocket, X_OK);
    }
    else {
        warn "Not running inside a multiplexer";
        return undef;
    }
}
sub detached { !attached }
1;

__END__

=head1 NAME

Term::Multiplexed - Detect terminal multiplexers (screen, tmux)

=head1 SYNOPSIS

  use Term::Multiplexed qw(multiplexed attached multiplexer);
  if(multiplexed) {
      say "Using " . multiplexer . " as terminal multiplexer";
      say "Currently " . (attached ? : "not ") . "attached.";
  }

=head1 DESCRIPTION

When running scripts inside screen/tmux, it's often useful to detect this and
to detect whether the multiplexer of choice is currently attached or not. This
module does exactly that and nothing more.

=head2 EXPORTS

=head3 multiplexed

Returns whether we are running inside a terminal multiplexer or not. Currently
only screen and tmux are detected.

=head3 attached

Returns true when the multiplexer is attached. Returns undef when called
outside a multiplexed environment.

=head3 detached

Returns false when the multiplexer is attached. Returns undef when called
outside a multiplexed environment.

=head3 multiplexer

The name of the current multiplexer. Currently only "screen" and "tmux" are
possible return values.

=head3 muxsocket

The full filesystem path to the socket used by the multiplexer.

=head1 SEE ALSO

Manpages: screen(1) tmux(1)

=head1 AUTHOR

Dennis Kaarsemaker E<lt>dennis@kaarsemaker.netE<gt>

=head1 COPYRIGHT AND LICENSE

This software is placed in the public domain, no rights reserved
