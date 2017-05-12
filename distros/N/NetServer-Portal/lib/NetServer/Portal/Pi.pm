use strict;
package NetServer::Portal::Pi;
use NetServer::Portal qw(term);
use Cwd;
use Symbol;
use Scalar::Util qw(reftype);
use Data::Dumper;

NetServer::Portal->register(cmd => "pi",
			    title => "Perl Introspector",
			    package => __PACKAGE__);

if (!defined &Data::Dumper::Maxdepth) {
    warn "Data::Dumper::Maxdepth is not available
NetServer::Portal::Pi will be too verbose";
    eval q[sub Data::Dumper::Maxdepth{}];
}
sub new_dumper {
    my $o = Data::Dumper->new(@_);
    $o->Indent(1);
    $o;
}

my $Help = "*** Perl Introspector ***


Type ':help' to load this buffer!

output buffer commands:
  ,         previous screen full
  .         next screen full
  :10       jump to line 10 (like vi)
  /REx      search for /REx/

  <         previous buffer
  >         next buffer

  :w <file> write buffer to <file>
  :history  show history of commands

navigational commands:

  ls [-1afpv]
    -1 single column format
    -a show everything
    -f functions
    -p sub-packages
    -v variables (scalars, arrays, hashes, and IOs)

  cd ..          move to preceeding \"directory\"
  cd <package>   use 'ls' to see options
  cd \$code       must evaluate to a REF
                 (for fun, try: cd [1,2,[],4,[],6])

  :pwd           show the working \"directory\"
";

sub new {
    my ($class, $client) = @_;
    my $o = $client->conf(__PACKAGE__);
    $o->{Package} ||= [];
    $o->{Path} ||= [];
    $o->{I} ||= [];
    if (!exists $o->{O}) {
	$o->{O} = [ { line => 0, buf => [split /\n/, $Help] } ];
    }
    $o->{buffer} ||= 0;
    $o;
}

sub update {
    my ($o, $c) = @_;
    
    my $ln = $c->format_line;
    my $conf = $c->conf;
    my $rows = $conf->{rows};
    my $cols = $conf->{cols};

    my $s = term->Tputs('cl',1,$c->{io}->fd);

    # optionally wrap lines longer than $cols XXX

    # turn off line numbers with
    # :set number

    my $output_rows = $rows - 4;
    if (@{$o->{O}}) {
	my $cur = $o->{O}[$o->{buffer}];
	my $O = $cur->{buf};
	my $max_line = @$O - $output_rows/2;
	$max_line = 0
	    if $max_line < 0;
	$cur->{line} = 0
	    if $cur->{line} < 0;
	$cur->{line} = $max_line
	    if $cur->{line} > $max_line;
	my $to = $cur->{line} + $output_rows - 1;
	$to = $#$O if
	    $to > $#$O;
	for (my $lx= $cur->{line}; $lx <= $to; $lx++) {
	    my $l = $O->[$lx];

	    # snarfed from Carp:
	    $l =~ s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
	    $l =~ s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;

	    my $note = '';
	    if ($lx == $cur->{line} or $lx == $to) {
		$note = " [".($lx+1)."]";
	    } elsif (($lx+1) % 4 == 0) {
		$note = " .";
	    }
	    my $part = substr $l, 0, $cols - length($note) - 1;
	    if ($note) {
		$part .= ' ' x ($cols - length($part) - length($note) - 1);
		$part .= $note;
	    }

	    $part .= "\n"
		if $part !~ /\n$/;
	    $s .= $part;
	}
	$s .= "\n" x ($output_rows + $cur->{line} - $to - 1);
    } else {
	$s .= "\n" x $output_rows;
    }
    $s .= "\n";
    $s .= $ln->($o->{error});
    my $at='';
    if (@{$o->{Path}}) {
	my @p = @{$o->{Path}};
	$at = "\$at=$p[$#p] "
    }
    $s .= (join('::', @{$o->{Package}}) || 'main')." $at";
    $s;
}

sub add_buffer {
    my ($o, $lines) = @_;
    unshift @{$o->{O}}, { line => 0, buf => $lines };
    $o->{buffer} = 0;
}

sub cmd {
    my ($o, $c, $in) = @_;
    
    my $conf = $c->conf;
    my $Rows = $conf->{rows};
    my $Cols = $conf->{cols};

    # these are invisible to command history
    if (!$in) {
	return
    } elsif ($in =~ m/^(\.+)$/) {
	$o->{O}[$o->{buffer}]{line} += length($1) * $Rows/2; #XXX
	return;
    } elsif ($in =~ m/^(,+)$/) {
	$o->{O}[$o->{buffer}]{line} -= length($1) * $Rows/2; #XXX
	return;
    } elsif ($in =~ m/^(\<+)$/) {
	$o->{buffer} += length $1;
	$o->{buffer} = $#{$o->{O}} if
	    $o->{buffer} > $#{$o->{O}};
	return;
    } elsif ($in =~ m/^(\>+)$/) {
	$o->{buffer} -= length $1;
	$o->{buffer} = 0 if
	    $o->{buffer} < 0;
	return;
    } elsif ($in =~ s,^/,,) {
	if (!$in) {
	    $in = $o->{last_search};
	} else {
	    $o->{last_search} = $in;
	}
	my $cur = $o->{O}[$o->{buffer}];
	my $buf = $cur->{buf};
	my $at = $cur->{line};
	my $ok;
	for (my $x=$at; $x < @$buf; $x++) {
	    if ($buf->[$x] =~ m/$in/) {
		next if $cur->{line} == $x;  # try to do something
		$cur->{line} = $x;
		$ok=1;
		last;
	    }
	}
	if (!$ok) {
	    $o->{error} = "No match for /$in/.";
	}
	return;
    } elsif ($in =~ s/^:\s*//) {
	if ($in =~ m/^(\d+)$/) {
	    $o->{O}[$o->{buffer}]{line} = $1 - $Rows/2; #XXX
	} elsif ($in eq 'help') {
	    $o->add_buffer([split /\n/, $Help]);
	} elsif ($in =~ /^w \s+ (.+)$/x) {
	    my $to = $1;
	    $to = getcwd.'/'.$to if
		$to !~ m,^/,;
	    my $buf = $o->{O}[$o->{buffer}]{buf};
	    my $fh = gensym;
	    open $fh, ">$to" or return $o->{error} = "open $to: $!";
	    my $char=0;
	    for (@$buf) {
		$char += 1+length $_;
		print $fh $_."\n";
	    }
	    close $fh;
	    $o->{error} = "$to ".(0+@$buf)." lines, $char characters";
	} elsif ($in eq 'history') {
	    my @tmp = @{$o->{I}};
	    $o->add_buffer(\@tmp);
	} elsif ($in eq 'pwd') {
	    my $Dumper = new_dumper($o->{Path});
	    $Dumper->Maxdepth(1);
	    $o->add_buffer(["Current path:",
			    '',
			    @{$o->{Package}},
			    split(/\n/, $Dumper->Dump)]);
	} else {
	    $o->{error} = "$in?  Try :help for a list of commands.";
	}
	return;
    }

    push @{$o->{I}}, $in;
    shift @{$o->{I}} if @{$o->{I}} > 16;

    if (!@{$o->{Path}} and $in =~ m/^ls (\s+ -[1apfv]+)? $/x) {
	# call resolve here XXX
	my %f;
	if ($1) {
	    my $flags = $1;
	    $flags =~ s/^\s*-//;
	    ++$f{$_} for split / */, $flags;
	}
	if ($f{a}) {
	    ++$f{$_} for qw(p f v);
	}
	++$f{p} if keys %f == 0;

	my $package = (join('::', @{$o->{Package}}) || 'main') . '::';
	my @got;

	no strict;
	local *stab = *{$package};
	while (my ($key,$val) = each(%stab)) {
	    local(*entry) = $val;
	    if ($f{v} and $key !~ /^_</ and defined $entry) {
		push @got, "\$$key";
	    }
	    if ($f{v} and $key !~ /^_</ and @entry) {
		push @got, "\@$key";
	    }
	    if ($key ne "main::" && $key ne "DB::" && %entry
		&& $key !~ /^_</
		&& !($package eq __PACKAGE__ and $key eq "stab")) {

		if ($key =~ /::$/) {
		    push @got, $key
			if $f{p};
		} elsif ($f{v}) {
		    push @got, "\%$key";
		}
	    }
	    my $fileno;
	    if ($f{v} and defined($fileno = fileno(*entry))) {
		push @got, "$key=$fileno";
	    }
	    if ($f{f} and defined &entry) {
		push @got, "\&$key";
	    }
	}
	@got = sort { $a cmp $b } @got;
	if (!$f{1}) {
	    my $maxlen=0;
	    for (@got) {
		s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
		s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
		$maxlen = length $_
		    if $maxlen < length $_;
	    }
	    ++$maxlen;
	    my $cols = int $Cols / $maxlen;
	    if ($cols > 1) {
		my $per = int(($cols + @got - 1) / $cols);
		my @grid;
		for (my $l=0; $l < $per; $l++) {
		    my $row='';
		    for (my $c=0; $c < $cols; $c++) {
			my $cel = $got[$l + $c*$per] || '';
			$cel .= ' 'x($maxlen - length $cel);
			$row .= $cel;
		    }
		    push @grid, $row;
		}
		@got = @grid;
	    }
	}
	$o->add_buffer(\@got);

    } elsif (@{$o->{Path}} and $in eq 'ls') {
	my @p = @{$o->{Path}};
	
	my $Dumper = new_dumper([ $p[$#p] ]);
	$Dumper->Maxdepth(1);
	$o->add_buffer([split /\n/,  $Dumper->Dump]);

    } elsif ($in =~ m,^cd (\s+/)? $,x) {
	@{$o->{Package}} = ();
	@{$o->{Path}} = ();
	
    } elsif ($in =~ s/^cd\s+//) {
	my @at = $o->resolve_path($in);
	return if (@at == 1 and !defined $at[0]);
	@{$o->{Package}} = ();
	while (@at and !ref $at[0]) {
	    push @{$o->{Package}}, shift(@at);
	}
	@{$o->{Path}} = @at;

    } else {
	$in .= "\n" if $in !~ /\n$/;
	my @warn;
	local $SIG{__WARN__} = sub {
	    push @warn, @_;
	};
	my $pack = join('::', @{$o->{Package}}) || 'main';
	my @eval = eval "no strict;\n#line 1 \"input\"\npackage $pack;\n$in";
	if ($@) {
	    $o->add_buffer([split /\n/, "package $pack;\n$in---\n$@"]);
	} else {
	    my $warns='';
	    $warns = join('', @warn)."---\n"
		if @warn;
	    my $Dumper = new_dumper(\@eval);
	    $o->add_buffer([split /\n/, "package $pack;\n$in---\n".$warns.
			    $Dumper->Dump]);
	}
    }
    pop @{$o->{O}} if @{$o->{O}} > 16;
}

sub resolve_path {
    my ($o, $path) = @_;
    my @at = (@{$o->{Package}}, @{$o->{Path}});
    @at=()
	if $path =~ s,^/,,;
    if ($path =~ m,^[\w\.\:/-]+$,) {
	my @step = split m'/+', $path;
	for my $step (@step) {
	    next if $step eq '.';
	    if ($step eq '..') {
		pop @at;
	    } else {
		if (@at and ref $at[$#at]) {
		    my $at = $at[$#at];
		    my $to;
		    if (reftype $at eq 'ARRAY') {
			$to = $at->[$step];
		    } elsif (reftype $at eq 'HASH') {
			$to = $at->[$step];
		    } else {
			$o->{error} = "Can't cd $step through '$at'.";
			return @at;
		    }
		    if (!ref $to) {
			$o->{error} = "Can't cd $step into '$to'.";
			return @at;
		    }
		    push @at, $to;
		} else {
		    $step =~ s/::$//;
		    push @at, $step;
		}
	    }
	}
	@at;
    } else {
	my $package = join('::', @{$o->{Package}}) || 'main';
	my @r = eval "no strict;\n#line 1 \"input\"\npackage $package;\n$path";
	if ($@) {
	    $o->{error} = $@;
	    return undef;
	}
	if (!@r) {
	    $o->{error} = "Nothing there.";
	} elsif (@r == 1) {
	    if (ref $r[0]) {
		return (@at, $r[0])
	    } else {
		$o->{error} = "Can't cd into '$r[0]'";
		return undef;
	    }
	} else {
	    return (@at, \@r);
	}
    }
}

1;
