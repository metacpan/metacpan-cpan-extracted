#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Pcore::Util::Data qw[from_json to_json];
use Pcore::Util::Text qw[decode_utf8 encode_utf8];
use Pcore::Src::File;

my $cv = P->cv;

AnyEvent::Socket::tcp_server( '127.0.0.1', 55_555, Coro::unblock_sub { on_accept(@_) } );

$cv->recv;

sub on_accept ( $fh, $host, $port ) {
    my $h = P->handle($fh);

    while () {
        my $msg = $h->read_line($LF);

        last if !$msg;

        # decode message, ignore invalid json
        eval { $msg = from_json $msg->$*; 1; } or last;

        my $cmd = 'CMD_' . ( delete( $msg->[1]->{cmd} ) // q[] );

        last if !$cmd || !main->can($cmd);

        main->$cmd( $h, $msg->[0], $msg->[1] );
    }

    return;
}

sub CMD_src ( $self, $h, $id, $args ) {
    my $path = $args->{path} // 'temp';

    if ( $args->{ft} ) {
        if ( $args->{ft} eq 'perl' ) {
            $path .= '.perl' if !defined $args->{path};
        }
        else {
            $path .= ".$args->{ft}";
        }
    }

    my $res = Pcore::Src::File->new( {
        action      => $args->{action},
        path        => $path,
        is_realpath => $args->{path} ? 1 : 0,
        in_buffer   => \encode_utf8 $args->{content},
        dry_run     => 0,
    } )->run;

    my $json = to_json [
        $id,
        {   was_changed => $res->was_changed                  ? 1 : 0,
            is_error    => $res->severity_range_is('ERROR')   ? 1 : 0,
            is_warn     => $res->severity_range_is('WARNING') ? 1 : 0,
            content     => decode_utf8 $res->out_buffer->$*
        }
    ];

    $h->write($json);

    return;
}

sub CMD_browser_print ( $self, $h, $id, $args ) {

    # only MSWIN currently supported
    return if !$MSWIN;

    $args->{content} =~ s/\t/    /smg;
    $args->{content} =~ s/&/&amp;/smg;
    $args->{content} =~ s/</&lt;/smg;
    $args->{content} =~ s/>/&gt;/smg;
    $args->{content} =~ s/"/&quot;/smg;
    $args->{content} =~ s/'/&#39;/smg;

    my $temp = $ENV->{TEMP_DIR} . q[vim-browserprint.html];

    $args->{font} = [ split /:/sm, $args->{font} ]->[0] =~ s/_/ /smgr if $args->{font};

    my $header = <<"EOF";
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=$args->{encoding}">
</head>
<body>
<pre style="font-family: '$args->{font}' !important; font-size: 12pt; white-space: pre-wrap;">
EOF

    state $footer = <<'EOF';
</pre>
</body>
</html>
EOF

    P->file->write_text( $temp, $header, $args->{content}, $footer );

    if ($MSWIN) {
        require Win32::Process;

        my $proc;

        Win32::Process::Create( $proc, $ENV{COMSPEC}, qq[/C start file://$temp], 0, Win32::Process::CREATE_NO_WINDOW(), q[.] ) || die;
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=cut
