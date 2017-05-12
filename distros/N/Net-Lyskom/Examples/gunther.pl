#!/usr/bin/perl -w

use Net::Lyskom;

# Globals

our $kom = Net::Lyskom->new;	# Connect to Lysator by default
our $komuser = "Günther";
our $kompass = "password";
our $confname = "Inlägg }t mig";
our $confno;
our $starttime = time() - (3600*24*7); # One week in seconds

# Let's login

sub do_login {
    my @tmp = $kom->lookup_z_name(name => $komuser,
				  want_pers => 1,
				  want_conf => 0);

    die "Ambiguous username, aborting.\n" if @tmp > 1;
    die "Username does not exist, aborting.\n" if @tmp == 0;

    $kom->login(pers_no => $tmp[0]->conf_no, password => $kompass)
      or die "Login failed: $kom->{err_string}\n";
}

# Lookup our conference

sub lookup_conf {
    my @tmp = $kom->lookup_z_name(name => $confname,
				  want_pers => 0,
				  want_conf => 1);

    die "Ambiguous conference name, aborting.\n" if @tmp > 1;
    die "Conference does not exist, aborting.\n" if @tmp == 0;
    $confno = $tmp[0]->conf_no;
}

# Find first text sent to our conference

sub is_in_conf {		# Is this text in our conference?
    my $t = shift;
    my $s = $kom->get_text_stat($t);
    return undef unless $s;

    foreach ($s->misc_info) {
	if ($_->type =~ /recpt/ && $_->data == $confno) {
	    return 1;		# Return success
	}
    }
    return undef;		# Return failure
}

sub find_first {
    my $text = $kom->get_last_text($starttime);

    until (is_in_conf($text)) {
	$text = $kom->find_next_text_no($text)
    };
    return $text;
}

# And which local text number is that?

sub global_to_local {
    my $global = shift;

    foreach ($kom->get_text_stat($global)->misc_info) {
	next unless $_->type =~ /recpt/ && $_->data == $confno;
	return $_->loc_no;
    }
    return undef;		# Not possible to get here
}

# Get the global numbers of all texts we're interested in

sub all_global {
    my $local = shift;
    my @all;
    my $map;

    do {
	$map = $kom->local_to_global(conf => $confno,
				     first => $local,
				     number => 255);
	push @all, $map->global_text_numbers;
	$local = $map->range_end;
    } while ($map->later_texts_exist);

    return @all;
}

# And now for the real work

sub get_subject {
    my $no = shift;
    my $text = $kom->get_text(text => $no, start_char => 0, end_char => 100);
    $text =~ s/\n.*$//s;	# Remove everything from the first linefeed
    return $text;
}

sub make_statistics {
    my %subject;

    foreach my $textno (@_) {
	my $subj = get_subject($textno);
	my $stat = $kom->get_text_stat($textno);
	
	$subject{$subj}{count} += 1;
	$subject{$subj}{lines} += $stat->no_of_lines;
	$subject{$subj}{chars} += $stat->no_of_chars;
    }
    return %subject;
}

# Format the result

sub time2str {
    my $t = shift;

    my ($sec,$min,$hour,$mday,$mon) = localtime($t);
    return sprintf "%d/%d %d:%02d:%02d",$mday,$mon+1,$hour,$min,$sec;
}

sub format_statistics {
    my %stats = @_;
    my @lines = sort {$stats{$b}{count} <=> $stats{$a}{count}} keys %stats;
    splice @lines, 25 if @lines > 25; # Truncate to 25 subject lines
    my $res;

    $res .= "Antal:    Antal inlägg med en viss ärenderad.\n";
    $res .= "Avg. t/i: Genomsnittligt antal tecken per inlägg.\n";
    $res .= "Ang. r/i: Genomsnittligt antal rader per inlägg.\n\n";
    $res .= "Inlägg skrivna mellan ".time2str($starttime)." och ".time2str(time)." har räknats.\n\n";
    $res .= "Endast de 25 mest förekommande ärenderaderna visas.\n\n";
    $res .= "Antal Avg. t/i Avg. r/i  Ärende\n";
    $res .= "===== ======== ========  =============================================\n";
    foreach my $l (@lines)
    {
	$res .= sprintf "%5d %8.1f %8.2f  %.45s\n",
	  $stats{$l}{count},
	    $stats{$l}{chars}/$stats{$l}{count},
	      $stats{$l}{lines}/$stats{$l}{count},
		$l;
    }
    $res .= "\n";

    return $res;
}

# Send string as a text to Lyskom

sub commit {
    my $body = shift;

    $kom->create_text(
		      subject => "Veckans ärenderadsstatistik",
		      body => $body,
		      recpt => [$confno]
		     );
}

# String the lot together

do_login;
lookup_conf;
commit format_statistics make_statistics all_global global_to_local find_first;
