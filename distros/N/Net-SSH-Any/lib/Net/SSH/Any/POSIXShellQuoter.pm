package Net::SSH::Any::POSIXShellQuoter;

my $noquote_class = '\\w/\\-=@';
my $glob_class    = '*?\\[\\],{}:!.^~';

sub quote {
    shift;
    my $quoted = join '',
	map { ( m|^'$|                  ? "\\'"  :
		m|^[$noquote_class]*$|o ? $_     :
		"'$_'" ) } split /(')/, $_[0];
    length $quoted ? $quoted : "''";
}

sub quote_glob {
    shift;
    my $arg = shift;
    my @parts;
    while ((pos $arg ||0) < length $arg) {
	if ($arg =~ m|\G'|gc) {
	    push @parts, "\\'";
	}
	elsif ($arg =~ m|\G([$noquote_class$glob_class]+)|gco) {
	    push @parts, $1;
	}
	elsif ($arg =~ m|\G(\\[$glob_class\\])|gco) {
	    push @parts, $1;
	}
	elsif ($arg =~ m|\G\\|gc) {
	    push @parts, '\\\\'
	}
	elsif ($arg =~ m|\G([^$glob_class\\']+)|gco) {
	    push @parts, "'$1'";
	}
	else {
	    require Data::Dumper;
	    $arg =~ m|\G(.+)|gc;
	    die "Internal error: unquotable string:\n". Data::Dumper::Dumper($1) ."\n";
	}
    }
    my $quoted = join('', @parts);
    length $quoted ? $quoted : "''";
}

1;
