
package TaskForest::Test;

use strict;
use warnings;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}

use Test::More;

sub checkStatusText {
    my ($content, $expected_lines) = @_;

    my @received_lines = split(/[\r?\n]/, $content);
    my @status = ();
    my ($regex, $line);

    while ( defined ($line = shift(@received_lines))) { last if $line eq ""; }

    while (@received_lines) {
        my $expected_line = shift(@$expected_lines);
        my ($family, $job, $status, $rc, $tz, $start, $astart, $stop) = @$expected_line;
        my ($jb) = $job =~ /([^\-]+)/;

        $line = shift(@received_lines); $regex = "${family}::$job +$status +$rc +$tz +$start +$astart +$stop"; like($line, qr/$regex/, "Got Line $line");
    }
    if (@$expected_lines) {
        diag("ERROR: expected a few more lines than we got");
        die;
    }
}




sub checkStatus {
    my ($content, $expected_lines) = @_;

    my @received_lines = split(/[\r?\n]/, $content);
    my @status = ();
    my $html;
    while ( defined ($html = shift(@received_lines))) { last if $html eq "<div class=status>"; }

    while ($received_lines[0] ne "</div>") {
        my $expected_line = shift(@$expected_lines);
        my ($family, $job, $status, $rc, $tz, $start, $astart, $stop) = @$expected_line;
        my ($jb) = $job =~ /([^\-]+)/;

        $html = shift(@received_lines);  is($html, qq[    <dl class=job>],                                                "Got '<dl class=job>',                                             ");
        $html = shift(@received_lines);  is($html, qq[      <dt>Family Name</dt>],                                        "Got ' <dt>Family Name</dt>',                                     ");
        $html = shift(@received_lines);  is($html, qq[      <dd><a href="/rest/1.0/families.html/$family">$family</a></dd>],"Got ' <dd><a href=\"/rest/1.0/families.html/$family\">$family</a></dd>'");
        $html = shift(@received_lines);  is($html, qq[      <dt>Job Name</dt>],                                           "Got ' <dt>Job Name</dt>',                                        ");
        $html = shift(@received_lines);  is($html, qq[      <dd><a href="/rest/1.0/jobs.html/$jb">$job</a></dd>],         "Got ' <dd><a href=\"/rest/1.0/jobs.html/$jb\">$job</a></dd>',        ");
        $html = shift(@received_lines);  is($html, qq[      <dt>Status</dt>],                                             "Got ' <dt>Status</dt>',                                          ");
        $html = shift(@received_lines);  is($html, qq[      <dd>$status</dd>],                                            "Got ' <dd>$status</dd>',                                         ");
        $html = shift(@received_lines);  is($html, qq[      <dt>Return Code</dt>],                                        "Got ' <dt>Return Code</dt>',                                     ");
        $html = shift(@received_lines);  is($html, qq[      <dd>$rc</dd>],                                                "Got ' <dd>$rc</dd>',                                             ");
        $html = shift(@received_lines);  is($html, qq[      <dt>Time Zone</dt>],                                          "Got ' <dt>Time Zone</dt>',                                       ");
        $html = shift(@received_lines);  is($html, qq[      <dd>$tz</dd>],                                                "Got ' <dd>$tz</dd>',                                             ");
        $html = shift(@received_lines);  is($html, qq[      <dt>Scheduled Start Time</dt>],                               "Got ' <dt>Scheduled Start Time</dt>',                            ");
        $html = shift(@received_lines);  is($html, qq[      <dd>$start</dd>],                                             "Got ' <dd>$start</dd>',                                          ");
        $html = shift(@received_lines);  is($html, qq[      <dt>Actual Start Time</dt>],                                  "Got ' <dt>Actual Start Time</dt>',                               ");
        $html = shift(@received_lines);  is($html, qq[      <dd>$astart</dd>],                                            "Got ' <dd>$astart</dd>',                                         ");
        $html = shift(@received_lines);  is($html, qq[      <dt>Stop Time</dt>],                                          "Got ' <dt>Stop Time</dt>',                                       ");
        $html = shift(@received_lines);  is($html, qq[      <dd>$stop</dd>],                                              "Got ' <dd>$stop</dd>',                                           ");
        $html = shift(@received_lines);  is($html, qq[    </dl>],                                                         "Got '</dl>',                                                     ");
    }
}

sub cleanup_files {
    my $dir = shift;
	local *DIR;
    
	opendir DIR, $dir or die "opendir $dir: $!";
	my $found = 0;
	while ($_ = readdir DIR) {
        next if /^\.{1,2}$/;
        my $path = "$dir/$_";
		unlink $path if -f $path;
	}
	closedir DIR;
}


sub fakeRun {
    my ($log_dir, $family, $job, $status) = @_;
    
    open (OUT, ">$log_dir/$family.$job.pid") || die "Couldn't open pid file\n";
    print OUT "pid: 111\nactual_start: 1209270000\nstop: 1209270001\nrc: $status\n";
    close OUT;
    
    open (OUT, ">$log_dir/$family.$job.started") || die "Couldn't open started file\n";
    print OUT "00:00\n";
    close OUT;

    open (OUT, ">$log_dir/$family.$job.$status") || die "Couldn't open pid file\n";
    print OUT "$status\n";
    close OUT;
    
    
}


sub waitForFiles {
    my %args = @_;

    my $sleep_time = $args{sleep_time} || 3;
    my $num_tries  = $args{num_tries}  || 10;
    my $file_list  = $args{file_list};

    next unless @$file_list;
    my $num_files = scalar(@$file_list);

    for (my $n = 1; $n <= $num_tries; $n++) {
        sleep $sleep_time;
        my $found = 1;
        my @missing = ();
        foreach my $file (@$file_list) {
            if (! -e $file) {
                $found = 0;
                push (@missing, $file);
            }
        }
        return 1 if $found;
        diag("Loop # $n: missing the following files:\n  ", join("\n  ", @missing), "\n") unless $n %5;
    }
    return 0;
}


sub parseSMTPFile {
    my $file = shift;

    my @emails = ();

    open (F, $file);
    my $email;
    my $mode;
    while (<F>) {
        s/[\r\n]//;
        if (/^Accepted Connection/) {
            $mode = 'smtp';
            $email = {
                mail_from   => '',
                rcpt_to     => '',
                ehlo        => '',
                from        => '',
                to          => '',
                return_path => '',
                reply_to    => '',
                subject     => '',
                body        => [],
            };
        }
        elsif (/^C: < (.*)/) {
            my $line = $1;
            if ($mode eq 'smtp' && $line eq 'DATA') {
                $mode = 'header';
                next;
            }
            elsif ($mode eq 'header' && $line !~ /\S/) {
                $mode = 'message';
                next;
            }
            elsif ($mode eq 'message' && $line eq '.') {
                push (@emails, $email);
                $mode = '';
                next;
            }
            elsif ($mode eq 'smtp' && $line =~ /^(EHLO) (.*)/) {
                $email->{ehlo} = $2;
            }
            elsif ($mode eq 'smtp' && $line =~ /^(HELO) (.*)/) {
                $email->{ehlo} = $2;
            }
            elsif ($mode eq 'smtp' && $line =~ /^(MAIL FROM:)(.*)/) {
                $email->{mail_from} = $2;
            }
            elsif ($mode eq 'smtp' && $line =~ /^(RCPT TO:)(.*)/) {
                $email->{rcpt_to} = $2;
            }
            elsif ($mode eq 'header' && $line =~ /^([^:]+): (.*)/) {
                my $h = lc($1);
                my $v = $2;
                $h =~ s/\-/\_/g;
                $email->{$h} = $v;
            }
            elsif ($mode eq 'message') {
                push (@{$email->{body}}, $line);
            }
        }                
    }

    return \@emails;
}


1;

