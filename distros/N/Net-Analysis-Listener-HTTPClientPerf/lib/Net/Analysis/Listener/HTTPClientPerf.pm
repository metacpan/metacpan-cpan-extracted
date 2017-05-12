package Net::Analysis::Listener::HTTPClientPerf;
# $Id: TCP.pm 81 2004-11-07 15:40:29Z abworrall $

# {{{ Boilerplate

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;

use Carp qw(carp croak confess);

use Params::Validate qw(:all);

use base qw(Net::Analysis::Listener::Base);

# }}}

use HTTP::Response;
use HTTP::Request;
use Net::Analysis::Constants qw(:packetclasses);
use Net::Analysis::Time;
use Data::Dumper; #XXXX
use PostScript::Simple;

#### Callbacks
#
# {{{ validate_configuration

sub validate_configuration {
    my $self = shift;

    my %h =validate(@_,{v             => {type => SCALAR, default => 1},
                        tsnap         => {type => SCALAR, default => 25000},
                        #tsnap => {type => SCALAR, default => 100000},
                        show_all_packets => {type => SCALAR, default => 0},
                        file   => {type => SCALAR, default => 'out.ps'},
                        pdf    => {type => SCALAR, default => undef},
                        ggv    => {type => SCALAR, default => undef},
                       });

    return \%h;
}

# }}}

# {{{ setup

sub setup {
    my ($self) = shift;

    # Setup our data structure
    $self->{open_boxes} = {};
    $self->{closed_boxes} = {};
}

# }}}
# {{{ teardown

sub teardown {
    my ($self) = shift; # No arguments to this callback

    croak ("teardown has open boxes") if (keys %{$self->{open_boxes}});

    $self->_generate_report();
}

# }}}
# {{{ tcp_packet

sub tcp_packet {
    my ($self, $args) = @_;
    my $pkt     = $args->{pkt};
    my $k       = $pkt->{socketpair_key};
    my $box     = $self->_box($k);

    #die Dumper($args);

    confess "bad args (".join(',',keys %$args).")" if (!defined $pkt);

    $self->_add_packet_to_box ($box, $pkt);

    # Build overall bounds for the entire data set
    if (!defined $self->{t_start} || $self->{t_start} > $pkt->{time}) {
        $self->{t_start} = $pkt->{time} + 0;
    }
    if (!defined $self->{t_end} || $self->{t_end} < $pkt->{time}) {
        $self->{t_end} = $pkt->{time} + 0;
    }

    $self->_trace ("[$k] - $pkt");
}

# }}}
# {{{ tcp_session_start

sub tcp_session_start {
    my ($self, $args) = @_;
    my $k       = $args->{socketpair_key};
    my $pkt     = $args->{pkt}; # Might be undef

    # Open up a new session box, based on this packet
    if (exists $self->{open_boxes}{$k}) {
        croak ("$k already has open box ?")
    }
    if (!$pkt) {
        croak ("new session, no packet; what to do here ?");
    }

    $self->_box($k, {t_start => $pkt->{time}});

    $self->_trace ("[$k]==== START $pkt->{time}\n");
}

# }}}
# {{{ tcp_session_end

sub tcp_session_end {
    my ($self, $args) = @_;
    my $k       = $args->{socketpair_key};
    my $pkt     = $args->{pkt}; # Might be undef

    if (exists $self->{open_boxes}{$k}) {
        $self->{open_boxes}{$k}{t_end} = $pkt->{time} if (defined $pkt);
        $self->{closed_boxes}{$k} = delete ($self->{open_boxes}{$k});

    } else {
        #carp ("$k has no box to close [".($pkt ? "$pkt" : 'no  pkt')."]");
    }

    $self->_trace ("[$k]==== END\n");
}

# }}}
# {{{ http_transaction

# args: (req,req_mono,resp,resp_mono,socketpair_key,t_elapsed,t_end,t_start)

sub http_transaction {
    my ($self, $args) = @_;
    my $k       = $args->{socketpair_key};
    my $pkt     = $args->{pkt}; # Might be undef
    my $uri     = $self->_full_uri($args);
    my $box     = $self->_box($k);

    #print "args: (".join(',', (sort keys %$args)).")\n";

    my $xact =
    {class            => $self->_classify_http_transaction ($uri, $args),
     uri              => $uri,
     t_xact_start     => $args->{t_start},
     t_xact_end       => $args->{t_end},
     t_xact_elapsed   => $args->{t_elapsed},

     t_req_start      => $args->{req_mono}->t_start(),
     t_req_end        => $args->{req_mono}->t_end(),
     t_req_elapsed    => $args->{req_mono}->t_elapsed(),
     req_n_packets    => $args->{req_mono}->n_packets(),

     t_resp_start     => $args->{resp_mono}->t_start(),
     t_resp_end       => $args->{resp_mono}->t_end(),
     t_resp_elapsed   => $args->{resp_mono}->t_elapsed(),
     resp_n_packets   => $args->{resp_mono}->n_packets(),

     req_size         => $args->{req_mono}->length(),
     resp_size        => $args->{resp_mono}->length(),
    };

    $self->_trace ("[$k]  == $uri ($xact->{t_xact_elapsed}s)\n");

    push (@{$box->{http_transactions}}, $xact);
}

# }}}

# {{{ as_string

sub as_string {
    my ($self) = @_;
    my $s = '';

    $s .= "[".ref($self)."]";

    return $s;
}

# }}}

#### Support for building data structure
#
# {{{ _trace

# This may become more clever ...

our $TRACE=0;

sub _trace {
    my ($self) = shift;

    return if (! $TRACE);

    foreach (@_) {
        my $l = $_; #  Skip 'Modification of a read-only value' errors
        chomp ($l);
        print "$l\n";
    }
}

# }}}

# {{{ _box

sub _box {
    my ($self, $k, $h) = @_;

    if (defined $h) {
        $self->{open_boxes}{$k} = $h;
    }

    return $self->{open_boxes}{$k};
}

# }}}
# {{{ _add_packet_to_box

# We cannot tell if the packet is in the request or the response. But that is
#  OK, since we know when to flag the start and end of both the request and
#  response phases. Even if they both fall in the same timebox, we also know
#  how many packets are in the request and response!

sub _add_packet_to_box {
    my ($self, $box, $pkt) = @_;

    confess "bad packet" if (!defined $pkt);

    my ($s,$real_us) = $pkt->{time}->numbers();
    my ($us)         = ($real_us) - ($real_us % $self->{tsnap});

    my (%hide) = (PKT_NOCLASS, 1);

    $hide{''.PKT_NONDATA} = 1 if (! $self->{show_all_packets});

    return if (exists $hide{$pkt->{class}});

    my $stack = $box->{pkt_stack}{$s}{$us} ||= [];
    push (@$stack, $pkt);

    if (!defined $box->{t_end} || $box->{t_end} < $pkt->{time}) {
        $box->{t_end} = $pkt->{time} + 0;
    }

    # Now add to a global stack
    my $glob_stack = $self->{global_pkt_stack}{$s}{$us} ||= [];
    push (@$glob_stack, $pkt)
}

# }}}
# {{{ _classify_http_transaction

# Say, into images vs. adserver stuff vs. javascript vs. content
sub _classify_http_transaction {
    my ($self, $uri, $args) = @_;

    return 0;
}

# }}}
# {{{ _full_uri

sub _full_uri {
    my ($self, $args) = @_;

    my $u = $args->{req}->header('host');
    $u .= $args->{req}->uri()->as_string();

    return $u;
}

# }}}

#### Support for generating report
#
# {{{ _generate_report

sub _generate_report {
    my ($self) = @_;

    my ($gs_args) = '-dBATCH -dNOPAUSE -sDEVICE=pdfwrite';

    $self->_set_bounds();

    if ($self->{file}) {
        $self->_ps_report ($self->{file});
        system ("ggv $self->{file}") if ($self->{ggv});

        if ($self->{pdf}) {
            my $f = $self->{file};
            rename ($f, "$f.ps");
            system ("gs $gs_args -sOUTPUTFILE=$f $f.ps");
            unlink ("$f.ps");
        }

    } else {
        $self->_ascii_report();
    }
}

# }}}
# {{{ _set_bounds

sub _set_bounds {
    my ($self) = @_;

    # Baseline our times.
    $self->{t_base} = $self->{t_start} + 0;
    $self->{t_base}->round_usec ($self->{tsnap});

    my $t_diff = $self->{t_end} - $self->{t_base};
    $t_diff->round_usec($self->{tsnap}, 'up');

    $self->{n_cols} = $t_diff->usec() / $self->{tsnap};
}

# }}}
# {{{ _ascii_report

sub _ascii_report {
    my ($self) = @_;

    my ($s,$us) = $self->{t_base}->numbers();

    print "[                     ] | ";
    my $n = 1;
    foreach my $box_k (keys %{$self->{closed_boxes}}) {
        printf ("% 4d ", $n++);
    }
    print "\n";
    print "[                     ] | ";
    $n = 1;
    foreach my $box_k (keys %{$self->{closed_boxes}}) {
        printf ("---- ");
    }
    print "\n";

    for my $n (0..($self->{n_cols} - 1)) {

        # Display time column
        printf "[% 3d %s.%06d] ", $n, $s, $us;
        if (($n * $self->{tsnap}) % 1000000) { print "* " }
        else                                         { print "- " }

        foreach my $box_k (keys %{$self->{closed_boxes}}) {
            my $str = '';
            my $box = $self->{closed_boxes}{$box_k};
            if (exists $box->{hist}{$s}{$us}) {
                my $h = $box->{hist}{$s}{$us};
                my $n = $h->[PKT_DATA];

                if (!defined $n)  { $str = '' }
                elsif ($n < 100)  { $str = sprintf "% 4d",$n }
                else              { $str = "**" }

            }
            printf "%-4.4s ", $str;
        }

        print "\n";

        # Now move our time counter on.
        $us += $self->{tsnap};
        if ($us >= 1000000) {
            $s++;
            $us -= 1000000;
        }
    }
}

# }}}

#### PostScript gubbins - a bit of a midnight hack, all this
#
use constant { X => 0, Y => 1};
# {{{ _ps_report

sub _ps_report {
    my ($self, $fname) = @_;

    # Variables used to build up the diagram
    $self->{session_slots} = [];
    $self->{key}{uris} = [];

    my $p = $self->{ps} = PostScript::Simple->new (papersize=>'A4',
                                                   colour => 1,
                                                   eps => 0,
                                                   landscape => 1,
                                                   units => "mm");
    $p->newpage();
    $p->setfont("Helvetica", 10);

    # Various constants that control rendering
    $self->{const} = {origin => [15,15],

                      # Size of the default timebox (i.e. packet + spacing)
                      tbox_w => 1,
                      tbox_h => 0.65,

                      # Packet size
                      packet_w => 0.8,
                      packet_h => 0.5,

                      # TCP session (should be auto :/)
                      session_h     => 20,
                      session_pad_v => 2,
                     };

    $self->_ps_key();
    $self->_ps_axes();

    my $boxes = $self->{closed_boxes};
    my $sorter = box_sorter($boxes);
    foreach my $box_k (sort $sorter keys %$boxes)
    {
        my $box = $self->{closed_boxes}{$box_k};
        my $y   = $self->_ps_box_height ($box);

        $self->_ps_box ([$self->{const}{origin}[X], $y], $box);
    }

    # Now generate cumulative packets at bottom
    $self->_ps_box_packets ($self->{const}{origin}, $self->{global_pkt_stack});

    $p->output ($fname);
}

# }}}
# {{{ _ps_axes

sub _ps_axes {
    my ($self) = @_;
    my $p = $self->{ps};
    my $tbox_width = 1;
    my ($x,$y) = @{$self->{const}{origin}};
    my $x_max = $x + $self->{n_cols}*$tbox_width;
    my ($height) = $self->{const}{session_h} - $self->{const}{session_pad_v} ;

    # Bottom box
    $p->setcolour    (230,230,230);
    $self->_ps_rect  ([$x,$y], $x_max - $x, $height, 'filled');

    # X axis
    $y -= 2.5;

    $p->setfont("Helvetica", 10);
    $p->setcolour(180, 180, 180); # Axes colour
    $p->setlinewidth( 0.5 );

    $p->line($x-0.25,$y, $x_max,$y);                          # X axis
    $p->line($x,$y,  $x,$y-1);                                # First tick
    $p->text($x-3, $y-4, $self->{t_base}->as_string('time')); # Base time

    # Ticks & labels for X axis
    my $n = 1;
    my $x_tick = $self->_ps_time_to_x ($self->{t_base} + $n);
    while ($x_tick < $x_max) {
        $p->line($x_tick,$y,  $x_tick,$y-1);
        $p->text($x_tick-3, $y-4, "+${n}s");

        $x_tick = $self->_ps_time_to_x ($self->{t_base} + ++$n);
    }

    return;

    # Y axis
    $x -= 2.5;
    $y += 2.5;
    $p->line($x,$y-0.25, $x,$y + $self->{const}{session_h});
    $p->line($x,$y,  $x-1,$y);                                # First tick

    my $pkts_per_mm = 1 / $self->{const}{tbox_h};
    my $cols_per_sec = 1000000 / $self->{tsnap};

    #### This furniture doesn't seem that useful at the mo
    #
    # A perfect 56K modem is 33,600 bits/sec in one dir, == 4.2K, or 3 packets
    # ADSL is 512,000 bits/sec downstream, == 64K, or 48 packets
    # Ethernet is 100Mb/sec, == 12 MB /sec, 6000 packets/sec (ish)
    #my $y_56k      = $y + $pkts_per_mm * (   3 / $cols_per_sec);
    #my $y_ADSL     = $y + $pkts_per_mm * (  48 / $cols_per_sec);
    #my $y_ethernet = $y + $pkts_per_mm * (6000 / $cols_per_sec);
    #$p->line($x,$y_56k,       $x-1,$y_56k);
    #$p->line($x,$y_ADSL,      $x-1,$y_ADSL);
    #$p->line($x,$y_ethernet,  $x-1,$y_ethernet);
    #print "$y, $y_56k, $y_ADSL, $y_ethernet ($pkts_per_mm, $cols_per_sec)\n";
}

# }}}
# {{{ _ps_box

sub _ps_box {
    my ($self, $o, $box) = @_;
    my ($p) = $self->{ps};

    my ($height) = $self->{const}{session_h} - $self->{const}{session_pad_v} ;

    my ($s,$us) = $self->{t_base}->numbers();

    my $box_x1 = $self->_ps_time_to_x ($box->{t_start});
    my $t_end = $box->{t_end};
    $t_end->round_usec ($self->{tsnap}, 'up');
    my $box_x2 = $self->_ps_time_to_x ($t_end, 'no snap');
    my $box_w = $box_x2 - $box_x1;

    $p->setlinewidth ( 0.1 );
    $p->setcolour    ($self->_ps_get_box_colour());
    $self->_ps_rect  ([$box_x1, $o->[Y]], $box_w, $height, 'filled');

    my ($req_pkts);
    my $uri_offset = -1.6 ;
    for my $hx (@{$box->{http_transactions}}) {
        my $x1 = $self->_ps_time_to_x ($hx->{t_xact_start});
        my $width = $self->_ps_time_to_x ($hx->{t_xact_end}) - $x1 +1;#+1 for final column

        # Set colour based on $hx->{class}
        $p->setcolour(128,128,128); # Slopey colour

        $p->setlinewidth( 0.1 );
        $self->_ps_slopey ([$x1, $o->[Y]], $width, $height);

        # Print URL
        push (@{$self->{key}{uris}}, $hx->{uri});
        my $n = scalar (@{$self->{key}{uris}});
        $p->setfont("Helvetica", 5);
        $p->setcolour(0,0,0); # Packet colour
        $p->text($x1, $o->[Y]+$uri_offset, $n);
    }

    $self->_ps_box_packets ($o, $box->{pkt_stack});
}

# }}}
# {{{ _ps_box_packets

sub _ps_box_packets {
    my ($self, $o, $stack) = @_;

    for my $s (sort keys %$stack) {
        for my $us (sort keys (%{$stack->{$s}})) {
            my $x = $self->_ps_time_to_x (Net::Analysis::Time->new($s,$us));
            my $y = $o->[Y];
            my $pkts = $stack->{$s}{$us};

            foreach my $pkt (@$pkts) {
                $self->_ps_packet ([$x, $y], $pkt);
                $y += $self->{const}{tbox_h};
            }
        }
    }
}

# }}}
# {{{ _ps_packet

sub _ps_packet {
    my ($self, $o, $pkt) = @_;
    my $p = $self->{ps};
    my ($x,$y) = @$o;
    my $type = $pkt->{class};

    my ($w ,$h) = ($self->{const}{packet_w}, $self->{const}{packet_h});

    # Base packet
    $p->setlinewidth( 0.01 );
    $p->setcolour(0,0,0); # Normal packet colour

    if ($type == PKT_DUP_DATA) {
        $p->setcolour(128,0,0);
        $self->_ps_rect ($o, $w, $h, 'filled');

        #$p->setcolour(255,255,255);
        #$p->line ($x,$y, $x+$w, $y+$h);
        #$p->line ($x+$w,$y, $x, $y+$h);

    } elsif ($type == PKT_FUTURE_DATA) {
        $p->setcolour(0,0,128);
        $self->_ps_rect ($o, $w, $h, 'filled');

        # Draw a single line
        #$p->setcolour(255,255,255);
        #$p->line ($x+$w,$y, $x, $y+$h);

    } elsif ($type == PKT_NONDATA) {
        $self->_ps_rect ($o, $w, $h);

    } elsif ($type == PKT_DATA) {
        my $dest_port;
        ($dest_port) = ($pkt->{to} =~ /:([\d]+)$/);

        if ($dest_port < 1024) {
            # Assume to be a request packet
            my ($radius) = ( ($w < $h) ? $w : $h ) / 2.0;
            $p->circle( {filled => 1}, $x+$w/2.0, $y+$h/2.0, $radius);
        } else {
            # Assume to be a response packet
            $self->_ps_rect ($o, $w, $h, 'filled');
        }

    } else {
        carp "how to render $type packet ?\n";
    }
}

# }}}
# {{{ _ps_rect

sub _ps_rect {
    my ($self, $o, $w, $h, $filled) = @_;
    my $p   = $self->{ps};

    my $opt = {offset => $o};
    $opt->{filled} = 1 if ($filled);

    $p->polygon($opt, 0,0, $w,0, $w,$h, 0,$h, 0,0);
}

# }}}
# {{{ _ps_slopey

sub _ps_slopey {
    my ($self, $o, $w, $h, $filled) = @_;
    my $p   = $self->{ps};

    my $opt = {offset => $o};
    $opt->{filled} = 1 if ($filled);

    $p->polygon($opt, 0,0, $w,0, $w,$h*0.8, 0,$h, 0,0);
}

# }}}

# {{{ _ps_time_to_x

# This handy routine takes a time, and works out the PostScript X position.
# Snaps into a timebox by default, but optional last parameter prevents this.

sub _ps_time_to_x {
    my ($self, $time, $nosnap) = @_;
    my $o = $self->{const}{origin};
    my $tbox_width = $self->{const}{tbox_w};

    my $diff = $time - $self->{t_base};
    $diff->round_usec ($self->{tsnap}) unless ($nosnap);

    return $o->[X] + $tbox_width * ($diff->usec() / $self->{tsnap});
}

# }}}
# {{{ _ps_box_height

sub _ps_box_height {
    my ($self, $box) = @_;

    my $slots = $self->{session_slots};

    my $slot_n;
    foreach my $n (0 .. $#$slots + 1) {
        # Fill in next empty slot, or nextr slot that is now clear
        if (! $slots->[$n] || $box->{t_start} > $slots->[$n]) {
            $slots->[$n] = $box->{t_end};
            $slot_n = $n;
            last;
        }
    }

    $slot_n++; # Leave space for the cumulative count

    return ($self->{const}{origin}[Y] + 4 + $slot_n * $self->{const}{session_h});
}

# }}}
# {{{ _ps_key

sub _ps_key {
    my ($self) = @_;
    my ($p) = $self->{ps};

    my ($x, $y) = ($self->{const}{origin}[X], 195);
    my $n = 1;
    my ($req_b, $resp_b) = (0,0);

    # URL list
    $p->setcolour(0,0,0);
    $p->setfont("Courier", 5);

    my $boxes = $self->{closed_boxes};
    my $sorter = box_sorter($boxes);
    foreach my $box_k (sort $sorter keys %$boxes) {
        my $box = $self->{closed_boxes}{$box_k};

        for my $hx (@{$box->{http_transactions}}) {
            $p->text($x, $y - $n*2, sprintf ("% 3d) % 6db %s", $n,
                                             $hx->{resp_size},
                                             "http://$hx->{uri}"));
            $req_b += $hx->{req_size};
            $resp_b += $hx->{resp_size};
            $n++;
        }
    }
    $p->text ($x, $y - $n*2, sprintf ("--- % 7db (+% 05db in reqs)",
                                      $resp_b, $req_b));

    # Key
    my ($height) = $self->{const}{session_h} - $self->{const}{session_pad_v} ;
    ($x, $y) = ($self->{const}{origin}[X]+220, 195);

    $p->setlinewidth( 0.2 );
    $p->setcolour (255,255,255);
    $self->_ps_rect  ([$x-6, $y-$height-6], 57, $height+9, 'filled');

    $p->setcolour (0,0,0);
    $self->_ps_rect  ([$x-5, $y-$height-5], 55, $height+7,);

    $p->setfont("Helvetica", 12);
    $p->setcolour    (0,0,0);
    $p->text ($x-14, $y-3, "Key");

    $p->setfont("Helvetica", 6);

    # Session box
    $p->setcolour    ($self->_ps_get_box_colour());
    $self->_ps_rect  ([$x, $y-$height], 5, $height, 'filled');
    $p->setcolour    (0,0,0);
    $p->text ($x-3, $y-$height-3, "TCP session");

    # HTTP transaction
    $x += 14;
    $p->setcolour(128,128,128);
    $p->setlinewidth( 0.1 );
    $self->_ps_slopey ([$x, $y-$height], 5, $height);
    $p->setcolour    (0,0,0);
    $p->text ($x-3, $y-$height-3, "HTTP request");

    # Packet types
    $x += 14;
    $y -= 4;
    $self->_ps_packet ([$x, $y],   {class => PKT_DATA, to => '1.2.3.4:80'});
    $p->setcolour    (0,0,0);
    $p->text ($x+2, $y, 'request packet');

    $self->_ps_packet ([$x, $y-3], {class => PKT_DATA, to => '1.2.3.4:3333'});
    $p->setcolour    (0,0,0);
    $p->text ($x+2, $y-3, 'response packet');

    $self->_ps_packet ([$x, $y-6], {class => PKT_FUTURE_DATA});
    $p->setcolour    (0,0,0);
    $p->text ($x+2, $y-6, 'out of order packet');

    $self->_ps_packet ([$x, $y-9], {class => PKT_DUP_DATA});
    $p->setcolour    (0,0,0);
    $p->text ($x+2, $y-9, 'duplicate packet');

    if (exists $self->{show_all_packets}) {
        $self->_ps_packet ([$x, $y-12], {class => PKT_NONDATA});
        $p->setcolour    (0,0,0);
        $p->text ($x+2, $y-12, 'non-data packet');
    }
}

# }}}
# {{{ _ps_get_box_colour

{
    my ($col_n) = 0;
    my (@pastels) = ([255, 230, 230],
                     [230, 255, 230],
                     [230, 230, 255],

                     [255, 255, 230],
                     [255, 230, 255],
                     [230, 255, 255],

                     [210, 230, 255],
                     [210, 255, 230],
                     [230, 210, 255],
                     [230, 255, 210],
                     [255, 210, 230],
                     [255, 230, 210],
                    );

    sub _ps_get_box_colour {
        return @{$pastels[$col_n++ % scalar(@pastels)]};
    }
}

# }}}

# {{{ box_sorter

sub box_sorter {
    my ($boxes) = @_;

    return sub { $boxes->{$a}{t_start} <=> $boxes->{$b}{t_start} };
}

# }}}

1;
__END__
# {{{ POD

=head1 NAME

Net::Analysis::Listener::HTTPClientPerf - analysis of client performance

=head1 SYNOPSIS

Listens for:
  tcp_packet
  tcp_session_start
  tcp_session_end
  http_transaction

No events are emitted.

=head1 ABSTRACT

Generate a pretty PostScript file with HTTP sessions, requests and packets
shown along a time axis. It is geared towards TCP sessions arising over a short
time span (say, <40s) originating from a single browser.

=head1 CONFIGURATION

 v                - verbosity
 tsnap=NN         - the width of each packet column, in microseonds. Larger
                     values compress the graph; packet columns become taller.
                     Defaults to 25000ms.
 show_all_packets - plot non-data packets as well as data packets
 file             - output filename
 pdf              - whether to exec `gs -sDEVICE=pdfwrite -sOUTPUTFILE=out.pdf`
 ggv              - whether to auto-invoke ggv on the output

=head1 DESCRIPTION

We listen to the C<http_transaction> events, and build up a data structure
designed for a graphical report.

Each time we see C<tcp_sesssion_start>, we start up a new session box. In this
box, we build a packet histogram over time, as C<tcp_packet> events are seen.
The C<tsnap> setting defines the time window; any packets for that session that
flow within the window are added together. At the end, each window will contain
a count of the packets, and also counts for the different classes (data vs.
duplicates vs. non-data, etc).

As we see C<http_transaction> events, we classify them based on their headers.
A record of the times, and class, of each transaction is added to the session
box.

When the session box is closed, we run through the various histograms, and
assign each set of counters a HTTP classification based on which http
transaction event their time lies within (e.g. request, response). We then run
through the http transaction list and insert req_start,req_stop, resp_start,
and resp_stop timings into the histogram sequence.

At this point, for each session we now have a time-ordered sequence of http
event timings, and fully classified packet histograms.

We now do a quick check over all the session boxes, to get scales for the axes.
Horiztonal is time; vertical is number of packets. We draw the axes, and also
any relevant graph furniture.

Then draw all the boxes. Sessions are stacked where they are concurrent; else
they are fitted in, to give a sense of the number of concurrent sessions that
were used during the request.

=head1 TODO

Better autoscaling of time axis; tsnap should be fully automatic

Output SVG instead of PostScript.

Incorporate DNS lookups.

Classify HTTP transactions; say, javascript vs. adserver vs. content vs. images

=head1 SEE ALSO

L<Net::Analysis> - the framework this module sits on.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

 $  ggv out.ps
 $  gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=out.pdf out.ps

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}
