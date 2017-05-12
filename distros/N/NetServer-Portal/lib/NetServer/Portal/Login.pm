use strict;
package NetServer::Portal::Login;
use NetServer::Portal qw($Host %PortInfo term);

NetServer::Portal->register(cmd => "menu",
			    title => "Main Menu",
			    package => __PACKAGE__);

sub new {
    bless { error => '' }
}

sub update {
    my ($o, $c) = @_;
    if (!$o->{user}) {
	my $s = "$o->{error}\n\n\n[$Host] $0 #$$\n\nlogin: ";
	$o->{error} = '';
	$s;
    } else {
	my $conf = $c->conf;
	my $l = $c->format_line;
	my $s = NetServer::Portal::term->Tputs('cl',1,$c->{io}->fd);
	$s .= $l->("NetServer::Portal v$NetServer::Portal::VERSION");
	$s .= "\n";
	$s .= $l->("HOST: $Host");
	$s .= $l->("PID:  $$");
	$s .= $l->("USER: $o->{user}");
	$s .= "\n\n";

	my @p = values %PortInfo;
	@p = sort { $a->{title} cmp $b->{title} } @p;
	my $fmt = "  %-10s %-40s";
	for my $p (@p) {
	    $s .= $l->($fmt, '!'.$p->{cmd}, $p->{title});
	}
	$s .= $l->($fmt, '!exit', 'End Session');

	$s .= "\n";
	$s .= $l->($fmt, "dim r,c", "Change screen dimensions from [$conf->{rows},$conf->{cols}]");

	$s .= "\n" x ($conf->{rows} - 13 - @p);
	$s .= $l->($o->{error});
	$s .= "% ";
	$s;
    }
}

sub init_user {
    my ($o, $cl, $id) = @_;
    $o->{user} = $id;
    my $t = $NetServer::Portal::StoreTop;
    if (! exists $t->{$id}) {
	my $u = $t->{$id} = {};
	$u->{rows} = 24;
	$u->{cols} = 80;
	$u->{screen} = __PACKAGE__;
    } else {
	eval { $cl->set_screen($t->{$id}{screen}) };  # failure OK
    }
}

sub cmd {
    my ($o, $cl, $in) = @_;
    if (!$o->{user}) {
	if ($in) {
	    if ($in =~ m/^[a-zA-Z\d]+$/) {
		# optional password protection XXX
		$o->init_user($cl, $in);
	    } else {
		$o->{error} = "'$in' is not a valid login";
	    }
	}
    } else {
	if (!$in) {
	    $o->{error} = '';
	    return;
	}
	if ($in =~ m/^dim \s* (\d+) (\s*,\s*|\s+) (\d+)$/x) {
	    my ($r,$c) = ($1,$3);
	    $r = 12 if $r < 12;
	    $c = 70 if $c < 70;
	    my $conf = $cl->conf;
	    $conf->{rows} = $r;
	    $conf->{cols} = $c;
	} elsif ($in eq '!exit') {
	    $cl->cancel;
	} elsif ($in eq '!back') {
	    $cl->set_screen('back');
	} else {
	    for my $p (values %PortInfo) {
		if ($in eq '!'.$p->{cmd}) {
		    $cl->set_screen($p->{package});
		    return;
		}
	    }
	    $o->{error} = "What is '$in'?";
	}
    }
}

package NetServer::Portal::About;

NetServer::Portal->register(cmd => "about",
			    title => "About This Extension",
			    package => __PACKAGE__);

sub new { bless {}, shift }

sub cmd {
    my ($o, $cl) = @_;
    $cl->set_screen('back');
}

sub update {
    my ($o, $c) = @_;
    my $ln = $c->format_line;
    my $s = "NetServer::Portal v$NetServer::Portal::VERSION\n\n";
    $s .= 'Copyright © 2000 Joshua Nathaniel Pritikin.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.';
    $s .= "\n" x 3;
    $s .= q[Send questions about this extension to perl-loop@perl.org.
If you wish to subscribe to this mailing list, send email to:

     majordomo@perl.org

The body of your message should read:

     subscribe perl-loop


If you are curious about the author's motivation, see:
     http://why-compete.org


Enjoy! ];
    $s;
}

1;
