#$Id: MD5.pm,v 0.01 2001/08/24 21:10:00 george@xorgate.com Exp $
package Apache::OpenIndex;
use strict;
use Digest::MD5;
use Apache::Util qw(escape_uri);
my $ofh;

# The following two directives can be used in httpd.conf file for adding the MD5 menu command.
#   OpenIndexOptions Import MD5 MD5 before=>MD5before after=>MD5after min=>1 max=>0 back=>MD5back
#   OpenIndexOptions Menu +MD5
#
# Copyright (c) 2001 George Sanderson All rights reserved. This
# program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 
#
sub MD5 {
    my ($r,$args,$cfg,$root,$src,$dst) = @_;
    my $file="$root$src";
    return 1 if -d $file;
    my $lang = new Apache::Language($r) if $cfg->{language};
    my $msg;
    my $cmdname=$lang->{MD5} || 'MD5';
    my $fh;
    unless(open($fh, $file)) {
	print STDERR "MD5() open: $file\n" if $debug;
	my $msg=$lang->{FileOpen} || 'File open';
	errmsg("${cmdname}: $msg");
	$args->{error}=1;
	return 0;
    }
    binmode($fh);
    my $md5=Digest::MD5->new;
    $md5->addfile($fh);
    my $digest=$md5->hexdigest;
    $r->log->notice(__PACKAGE__." $args->{user}: MD5: $file=$digest");
    ($file=$src)=~s:.*/::;	# strip off directory
    print {$ofh} "$file=$digest\n";
    close $fh;
    1;
}

sub MD5before {
    my ($r,$args,$cfg,$root,$items,$dst) = @_;
    my $file=$dst;
       $file.=".md5.txt" unless $args->{dst}; # Default file to contain the MD5s
    $args->{md5file}=$file;
    $file="$root$file";
    my $uri = $r->uri;
    my $lang = new Apache::Language($r) if $cfg->{language};
    my $msg;
    my $cmdname=$lang->{MD5} || 'MD5';
    unless(open($ofh, "+>$file")) {
	print STDERR "MD5before() open: $file\n" if $debug;
	$msg=$lang->{FileOpen} || 'File open';
	errmsg("${cmdname}: $msg");
	$args->{error}=1;
	return 0;
    }
    1;
}

sub MD5after {
    my ($r,$args,$cfg,$root,$dst) = @_;
    my $uri = $r->uri;
    $uri.="?proc=MD5";
    $uri.="&frame=main" if $cfg->{frames};
    $uri.='&md5file=';
    $uri.=escape_uri($args->{md5file});
    if($args->{dst}) {
	$uri.='&dst=';
	$uri.=escape_uri($args->{dst});
    }
    print STDERR "MD5after() REDIRECT to $uri\n" if $debug;
    $r->header_out(Location=>$uri);
    close $ofh;
    REDIRECT;
}

sub MD5back {
    my ($r,$args,$cfg,$root) = @_;
    my $uri = $r->uri;
    my $lang = new Apache::Language($r) if $cfg->{language};
    my $cmdname=$lang->{MD5} || 'MD5';
    my $file="$root$args->{md5file}";
    unless(open(FILE, $file)) {
	print STDERR "MD5back() call back open: $file\n" if $debug;
	my $msg=$lang->{FileOpen} || 'File open';
	errmsg("${cmdname}: $msg");
	$args->{error}=1;
	return 0;
    }
    return SKIP_INDEX unless httphead($r,"$cmdname results");
    header($r,$cfg) unless $cfg->{frames}; 
    tagout('h3',$cfg,'',qq~$cmdname results</h3>~);
    if($args->{error}) {
	if($cfg->{font}) {
	    tagout('font',$cfg,'',"ERROR: $errmsg</font></h3>");
	} else {
	    print qq~<font color=#FF0000> ERROR: $errmsg</font></h3>~;
	}
    }
    if($cfg->{table}) {
	tagout('table',$cfg,qq~col="2"~);
    } else {
	print qq~<table col="2" border>~;
    }
    tagout('tr',$cfg);
    tagout('th',$cfg,'',qq~ Filename </th>~);
    tagout('th',$cfg,'',qq~ MD5 Hash </th></tr>~);
    while(<FILE>) {
	my($file,$digest)=split /=/;
	tagout('tr',$cfg);
	tagout('td',$cfg,'',qq~$file</td>~);
	tagout('td',$cfg,'',qq~$digest</td></tr>~);
    }
    $uri.="?frame=main" if $cfg->{frames};
    if($args->{dst}) {
	if($cfg->{frames}) {
	    $uri.='&dst=';
	} else {
	    $uri.='?dst=';
	}
	$uri.=escape_uri($args->{dst});
    }
    print '</table>';
    tagout('p',$cfg,'',qq~<a href="$uri">Back to Index</a>~);
    print "</body>" unless $cfg->{frames};
    print "</html>\n";
    close FILE;
    SKIP_INDEX;
}
1;

