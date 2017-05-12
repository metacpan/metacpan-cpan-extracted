# -*- Perl -*-

package SGML::DTDParse::Catalog;

use strict;
use vars qw($VERSION $CVS);

$VERSION = do { my @r=(q$Revision: 2.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
$CVS = '$Id: Catalog.pm,v 2.1 2005/07/02 23:51:18 ehood Exp $ ';

sub new {
    my $type = shift;
    my %param = @_;
    my $class = ref($type) || $type;
    my $self = bless {}, $class;

    $self->{'DIRECTIVE'} = [];
    $self->{'FILES'} = {};
    $self->{'VERBOSE'} = $param{'Verbose'} || $param{'Debug'};
    $self->{'DEBUG'} = $param{'Debug'};

    my $catfiles = $main::ENV{'SGML_CATALOG_FILES'};
    my @files = ();

    if ($catfiles =~ /;/) {
	@files = split(/;/, $catfiles);
    } else {
	@files = split(/:/, $catfiles);
    }

    foreach my $file (@files) {
	$self->parse($file);
    }

    return $self;
}

sub verbose {
    my $self = shift;
    my $val = shift;
    my $verb = $self->{'VERBOSE'};

    $self->{'VERBOSE'} = $val if defined($val);

    return $verb;
}

sub debug {
    my $self = shift;
    my $val = shift;
    my $dbg = $self->{'DEBUG'};

    $self->{'DEBUG'} = $val if defined($val);

    return $dbg;
}

sub parse {
    my $self = shift;
    my $file = shift;

    return 2 if $self->{'FILES'}->{$file};

    $self->{'FILES'}->{$file} = 1;

    return $self->load_catalog($file);
}

sub _find {
    my $self = shift;
    my $type = shift;
    my $key  = shift;

    foreach my $dir (@{$self->{'DIRECTIVE'}}) {
	my %hash = %{$dir};
	return $hash{'FILE'} if $hash{'TYPE'} = $type && $hash{$type} eq $key;
    }

    return undef;
}

sub system_map {
    my($self, $sysid) = @_;

    return $self->_find('SYSID', $sysid) || $sysid;
}

sub public_map {
    my($self, $pubid) = @_;

    $pubid =~ s/\s+/ /g;
    return $self->_find('PUBID', $pubid);
}

sub reverse_public_map {
    my($self, $filename) = @_;

    $filename =~ s/\\/\//g; # canonical path separator

    foreach my $dir (@{$self->{'DIRECTIVE'}}) {
	my %hash = %{$dir};
	my $key = $hash{'TYPE'};
	next if $key ne 'PUBID';

#	print "$key\n";
#	print $hash{$key}, "\n";
#	print $hash{'FILE'}, "\n";
#	print "\t$filename\n\n";

	return $hash{$key} if $hash{'FILE'} eq $filename;
    }

    return undef;
}

sub declaration {
    my($self, $pubid) = @_;

    $pubid =~ s/\s+/ /g;
    foreach my $dir (@{$self->{'DIRECTIVE'}}) {
	my %hash = %{$dir};

	return $hash{'FILE'}
	    if $hash{'TYPE'} eq 'DTDDECL' && $hash{'DTDDECL'} eq $pubid;

	return $hash{'FILE'}
	    if $hash{'TYPE'} eq 'SGMLDECL';
    }

    return undef;
}

sub load_catalog {
    my $self = shift;
    my $catalog = shift;
    my $drive = "";
    my $dir = "";
    my @directives = ();
    my $count = 0;
    local (*F, $_);

    print "Reading $catalog...\n" if $self->verbose();

    $catalog =~ s/\\/\//g; # canonical path separators
    $dir = $1 if $catalog =~ /^(.*)\/[^\/]+$/;
    $drive = substr($dir, 0, 2) if substr($dir, 1, 1) eq ':';

    if (!open(F, $catalog)) {
	print "Failed to open $catalog...\n" if $self->verbose();
	return;
    }

    read (F, $_, -s $catalog);
    close (F);

    while (/^\s*(\S+)/s) {
	my $keyword = uc($1);
	$_ = $';

	if ($keyword eq 'OVERRIDE') {
	    $_ =~ /^\s*\S+/s;
	    $_ = $';
	    next;
	}

	if ($keyword eq 'PUBLIC') {
	    my($pubid, $filename);
	    if (/^\s*[\"\']/s) {
		($pubid, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$pubid = $1;
		$_ = $';
	    }

	    if (/^\s*[\"\']/s) {
		($filename, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$filename = $1;
		$_ = $';
	    }

	    if ($filename =~ /^[a-z]:/s) {
		# nop
	    } elsif ($filename =~ /^[\\\/]/) {
		$filename = $drive . $filename;
	    } else {
		$filename = $dir . "/" . $filename if $dir ne "";
	    }

	    $directives[$count] = {};
	    $directives[$count]->{'TYPE'} = 'PUBID';
	    $directives[$count]->{'PUBID'} = $pubid;
	    $directives[$count]->{'FILE'} = $filename;
	    $count++;

	    # print "\"$pubid\" = \"$filename\"\n";

	    next;
	}

	if ($keyword eq 'SYSTEM') {
	    my($sysid, $filename);
	    if (/^\s*[\"\']/s) {
		($sysid, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$sysid = $1;
		$_ = $';
	    }

	    if (/^\s*[\"\']/s) {
		($filename, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$filename = $1;
		$_ = $';
	    }

	    if ($filename =~ /^[a-z]:/s) {
		# nop
	    } elsif ($filename =~ /^[\\\/]/) {
		$filename = $drive . $filename;
	    } else {
		$filename = $dir . "/" . $filename if $dir ne "";
	    }

	    $directives[$count] = {};
	    $directives[$count]->{'TYPE'} = 'SYSID';
	    $directives[$count]->{'SYSID'} = $sysid;
	    $directives[$count]->{'FILE'} = $filename;
	    $count++;

	    next;
	}

	if ($keyword eq 'DTDDECL') {
	    my($pubid, $filename);
	    if (/^\s*[\"\']/s) {
		($pubid, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$pubid = $1;
		$_ = $';
	    }

	    if (/^\s*[\"\']/s) {
		($filename, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$filename = $1;
		$_ = $';
	    }

	    if ($filename =~ /^[a-z]:/s) {
		# nop
	    } elsif ($filename =~ /^[\\\/]/) {
		$filename = $drive . $filename;
	    } else {
		$filename = $dir . "/" . $filename if $dir ne "";
	    }

	    $directives[$count] = {};
	    $directives[$count]->{'TYPE'} = 'DTDDECL';
	    $directives[$count]->{'DTDDECL'} = $pubid;
	    $directives[$count]->{'FILE'} = $filename;
	    $count++;

	    next;
	}

	if ($keyword eq 'SGMLDECL') {
	    my($filename);

	    if (/^\s*[\"\']/s) {
		($filename, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$filename = $1;
		$_ = $';
	    }

	    if ($filename =~ /^[a-z]:/s) {
		# nop
	    } elsif ($filename =~ /^[\\\/]/) {
		$filename = $drive . $filename;
	    } else {
		$filename = $dir . "/" . $filename if $dir ne "";
	    }

	    $directives[$count] = {};
	    $directives[$count]->{'TYPE'} = 'SGMLDECL';
	    $directives[$count]->{'SGMLDECL'} = 'SGMLDECL';
	    $directives[$count]->{'FILE'} = $filename;
	    $count++;

	    next;
	}

	if ($keyword eq 'DOCTYPE') {
	    my($tag, $filename);
	    if (/^\s*[\"\']/s) {
		($tag, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$tag = $1;
		$_ = $';
	    }

	    if (/^\s*[\"\']/s) {
		($filename, $_) = &parse_quoted_string("CATALOG", $_);
	    } else {
		/^\s*(\S+)/s;
		$filename = $1;
		$_ = $';
	    }

	    if ($filename =~ /^[a-z]:/s) {
		# nop
	    } elsif ($filename =~ /^[\\\/]/) {
		$filename = $drive . $filename;
	    } else {
		$filename = $dir . "/" . $filename if $dir ne "";
	    }

	    # nop...
	    next;
	}

	if ($keyword =~ /^\-\-/) {
	    $_ = $keyword . $_;
	    /^--.*?--/s;
	    $_ = $';
	    next;
	}

	die "Don't know how to parse CATALOG keyword: $keyword\n";
    }

    # now populate the real array; making sure that SGMLDECL goes to
    # the end of the array

    foreach my $dir (@directives) {
	my %hash = %{$dir};
	next if $hash{'TYPE'} eq 'SGMLDECL';
	push(@{$self->{'DIRECTIVE'}}, $dir);
    }

    foreach my $dir (@directives) {
	my %hash = %{$dir};
	next if $hash{'TYPE'} ne 'SGMLDECL';
	push(@{$self->{'DIRECTIVE'}}, $dir);
    }

    return 1;
}

sub strip_comment {
    my($text) = shift;
    while ($text =~ /^\s*--.*?--/s) {
	$text = $';
    }
    return $text;
}

sub parse_quoted_string {
    my($decl, $entity) = @_;
    my($text);

    if ($entity =~ /^\s*\"/s) {
	die "Unparseable text: $decl\n" if $entity !~ /^\s*\"(.*?)\"/s;
	$text = $1;
	$entity = &strip_comment($');
    } elsif ($entity =~ /^\s*\'/s) {
	die "Unparseable text: $decl\n" if $entity !~ /^\s*\'(.*?)\'/s;
	$text = $1;
	$entity = &strip_comment($');
    } else {
	die "Unexpected text: $decl\n";
    }

    return ($text, $entity);
}

1;
