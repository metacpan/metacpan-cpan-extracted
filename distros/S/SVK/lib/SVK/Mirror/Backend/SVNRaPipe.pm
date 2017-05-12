# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Mirror::Backend::SVNRaPipe;
use strict;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(ra requests fh unsent_buf buf_call current_editors pid));

use POSIX 'EPIPE';
use Socket;
use Storable qw(nfreeze thaw);
use SVK::Editor::Serialize;
use SVK::Util qw(slurp_fh);
use SVK::Config;
use SVK::I18N;

=head1 NAME

SVK::Mirror::Backend::SVNRaPipe - Transparent SVN::Ra requests pipelining

=head1 SYNOPSIS

 my @req = (['rev_proplist', 3'], ['replay', 3 0, 1, 'EDITOR'])
 $generator = sub { shift @req };
 $pra = SVK::Mirror::Backend::SVNRaPipe->new($ra, $generator);

 $pra->rev_proplsit(3);
 $pra->replay(3, 0, 1, SVK::Editor->new);

=head1 DESCRIPTION



=cut

sub new {
    my ($class, $ra , $gen) = @_;

    socketpair(my $c, my $p, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
	or  die "socketpair: $!";

    my $self = $class->SUPER::new(
        {
            ra              => $ra,
            requests        => $gen,
            fh              => $c,
            current_editors => 0,
            buf_call        => [],
            unsent_buf      => ''
        }
    );

    if (my $pid = fork) {
	close $p;
	$self->pid($pid);
	return $self;
    }
    else {
	die "cannot fork: $!" unless defined $pid;
	close $c;
    }

    $self->fh($p);
    $File::Temp::KEEP_ALL = 1;
    # Begin external process for buffered ra requests and send response to parent.
    my $config = SVK::Config->svnconfig;
    my $max_editor_in_buf
        = $config ? $config->{config}->get( 'svk', 'ra-pipeline-buffer', '5' ) : 5;
    my $pool = SVN::Pool->new_default;
    local $SIG{INT} = 'IGNORE';
    while ( my $req = $gen->() ) {
        $pool->clear;
        my ( $cmd, @arg ) = @$req;

        my $default_threshold = 2 * 1024 * 1024;
        @arg = map {
            $_ eq 'EDITOR'
                ? SVK::Editor::Serialize->new(
                  { textdelta_threshold => $config ? $config->{config}->get(
                        'svk', 'ra-pipeline-delta-threshold',
                        "$default_threshold"
                    ) : $default_threshold,
                    cb_serialize_entry =>
                        sub { $self->_enqueue(@_); $self->try_flush }
                  } )
                : $_
        } @arg;

	# Note that we might want to switch to bandwidth based buffering,
	while ($self->current_editors > $max_editor_in_buf) {
	    $self->try_flush(1);
	}

	my $ret = $self->ra->$cmd(@arg);
	if ($cmd eq 'replay') { # XXX support other requests using editors
	    ++$self->{current_editors};
	    $self->_enqueue([undef, 'close_edit']);
	}
	else {
	    $self->_enqueue([$ret, $cmd]);
	}
	$self->try_flush();
    }

    while ($#{$self->buf_call} >= 0) {
	$self->try_flush($p, 1) ;
    }
    exit;
}

sub _enqueue {
    my ($self, $entry) = @_;
    push @{$self->buf_call}, $entry;
}

sub try_flush {
    my $self = shift;
    my $wait = shift;
    my $max_write = $wait ? -1 : 10;
    if ($wait) {
	$self->fh->blocking(1);
    }
    else {
	$self->fh->blocking(0);
	my $wstate = '';
	vec($wstate,fileno($self->fh),1) = 1;
	select(undef, $wstate, undef, 0);;
	return unless vec($wstate,fileno($self->fh),1);
    }
    my $i = 0;
    my $buf = $self->buf_call;
    while ( $#{$buf} >= 0 || length($self->unsent_buf) ) {
	if (my $len = length $self->unsent_buf) {
	    if (my $ret = syswrite($self->fh, $self->unsent_buf)) {
		substr($self->{unsent_buf}, 0, $ret, '');
		last if $ret != $len;
	    }
	    else {
		die if $! == EPIPE;
		return;
	    }
	}
	last if $#{$buf} < 0;
	my $msg = nfreeze($buf->[0]);
	$msg = pack('N', length($msg)).$msg;

	if (my $ret = syswrite($self->fh, $msg)) {
	    $self->{unsent_buf} .= substr($msg, $ret)  if length($msg) != $ret;
	    if ((shift @$buf)->[1] eq 'close_edit') {
		--$self->{current_editors} ;
	    }
	}
	else {
	    die if $! == EPIPE;
	    # XXX: check $! for fatal
	    last;
	}
    }
}

# Client code reading pipelined responses

sub read_msg {
    my $self = shift;
    my ($len, $msg);
    read $self->fh, $len, 4 or Carp::confess $!;
    $len = unpack ('N', $len);
    my $rlen = read $self->fh, $msg, $len or die $!;
    return \$msg;
}

sub ensure_client_cmd {
    my ($self, @arg) = @_;
    # XXX: error message
    my @exp = @{$self->requests->()};
    for (@exp) {
	my $arg = shift @arg;
	if ($_ eq 'EDITOR') {
	    die unless UNIVERSAL::isa($arg, 'SVK::Editor');
	    return $arg;
	}
	Carp::confess "pipeline ra error: got $arg but expecting $_" if ($_ cmp $arg);
    }
    die join(',',@arg) if @arg;
}

sub rev_proplist {
    my $self = shift;
    $self->ensure_client_cmd('rev_proplist', @_);
    # read synchronous msg
    my $data = thaw( ${$self->read_msg} );
    die 'inconsistent response' unless $data->[1] eq 'rev_proplist';
    return $data->[0];
}

sub reparent {
    my $self = shift;
    $self->ensure_client_cmd('reparent', @_);
    # read synchronous msg
    my $data = thaw( ${$self->read_msg} );
    die 'inconsistent response' unless $data->[1] eq 'reparent';
    return $data->[0];
}

sub replay {
    my $self = shift;
    my $editor = $self->ensure_client_cmd('replay', @_);
    my $baton_map = {};
    my $baton_pool = {};

    eval {

    while ((my $data = $self->read_msg )) {
	my ($next, $func, @arg) = @{thaw($$data)};
	my $baton_at = SVK::Editor->baton_at($func);
	my $baton = $arg[$baton_at];
	if ($baton_at >= 0) {
	    $arg[$baton_at] = $baton_map->{$baton};
	}

	my $pool = SVN::Pool->new;
	my $ret = $self->emit_editor_call($editor, $func, $pool, @arg);

	last if $func eq 'close_edit';

	if ($func =~ m/^close/) {
	    Carp::cluck $func unless $baton_map->{$baton};
	    delete $baton_map->{$baton};
	    delete $baton_pool->{$baton};
	}

	if ($next) {
	    # if we are keeping this parent baton, set the pool as the
	    # default pool as well.
	    $pool->default if $pool;
	    $baton_pool->{$next} = $pool if $pool;
	    $baton_map->{$next} = $ret
	}
    }
    };

    if ($@) {
	kill 15, $self->pid;
	waitpid $self->pid, 0;
	$self->pid(undef);
    }

    # destroy the remaining pool that became default pools in order.
    delete $baton_pool->{$_} 
        for reverse sort keys %$baton_pool;

    die $@ if $@;
}

sub emit_editor_call {
    my ($self, $editor, $func, $pool, @arg) = @_;
    my $ret;
    if ($func eq 'apply_textdelta') {
	my $svndiff = pop @arg;
	$ret = $editor->apply_textdelta(@arg, $pool);

	if ($ret && $#$ret > 0) {
	    my $stream = SVN::TxDelta::parse_svndiff(@$ret, 1, $pool);
	    if (ref $svndiff) { # inline
		print $stream $$svndiff;
	    }
	    else { # filename
		open my $fh, '<', $svndiff or die $!;
		slurp_fh($fh, $stream);
		close $fh;
		unlink $svndiff;
	    }
	    close $stream;
	}
    }
    else {
	# do not emit the fabricated close_edit, as replay doesn't
	# give us that.  We need that in the stream so the client code
	# of replay knows the end of response has reached.
	$ret = $editor->$func(@arg, $pool)
	    unless $func eq 'close_edit';
    }
    return $ret;
}

sub DESTROY {
    my $self = shift;
    return unless $self->pid;
    wait;
}

1;
