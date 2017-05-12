package Piffle::Template;
use strict;
use base qw{Exporter};
use vars qw{@EXPORT_OK $VERSION $PACKAGE_NUM};
use File::Spec;
use Symbol;
use Carp;
use utf8;
no bytes;

@EXPORT_OK = qw{template_to_perl expand_template};
$VERSION = '0.3.1';


sub __make_package_name
{
	return sprintf("%s::G%05d", __PACKAGE__, ++$PACKAGE_NUM);
}


sub __slurp
{
	my ($file, $rbuf) = @_;
	my $fh = gensym();
	local $/; undef $/;
	open($fh, '<', $file) or croak("open $file: $!");
	$$rbuf = <$fh>;
	close($fh);	
}


sub __path_search
{
	my ($item, @inc) = @_;
	foreach my $dir (@inc)
	{
		my $path = File::Spec->catfile($dir, $item);
		return $path if -f $path;
	}
	return undef;
}


sub __make_interpolation
{
	my ($ivar, $itype) = @_;
	if ($itype eq 'raw')
	{
		return ";print join('', ($ivar));\n";
	}
	my $perl_line = '';
	if ($itype eq 'uri')
	{
		$perl_line = qq{
			;print join('', map {
				local \$_ = pack('C*', unpack('C*', \$_));
				s{([^a-zA-Z0-9_.-])}{
					sprintf('%%%02X', ord(\$1))
				}eg;
				\$_;
			} ($ivar));
		};
	}
	else
	{
		$perl_line = qq{
			;print join('', map {
				local \$_ = \$_;
				s{([&"'<>])}{
					sprintf('&#%d;', ord(\$1))
				}eg;
				\$_;
			} ($ivar));
		};
	}
	$perl_line =~ s/\n/\040/gs;
	$perl_line =~ s/\s+/\040/g;
	$perl_line =~ s/^\s*//g;
	$perl_line =~ s/\s*$//g;
	return $perl_line . "\n";
}


sub expand_template
{
	my %opt = @_;

	# Various options
	my ($in_buf, $filename, $errors_to, @inc);
	@inc = @{$opt{include_path} || []};
	$errors_to = $opt{errors_to} || 'die';

	# Pick an input source
	if ($opt{source})
	{
		$in_buf = $opt{source};
		$filename = "AnonString";
	}
	elsif ($opt{source_file})
	{
		my $file = $opt{source_file};
		if (ref $file)
		{
			$filename = "AnonFilehandle";
			local $/; undef $/;
			$in_buf = <$file>;
		}
		else
		{
			__slurp($file, \$in_buf);
			$filename = $file;
		}
	}
	else
	{
		croak "No source: use either 'source' or 'source_text'";
	}

	# Decide on where to stuff the output
	my ($out_buf, $out_fh, $close_out);
	$out_buf = '';
	if ($opt{output_file})
	{
		my $file = $opt{output_file};
		local $/;
		undef $/;
		if (ref $file)
		{
			$out_fh = $file;
		}
		else
		{
			$out_fh = gensym();
			open($out_fh, '>', $file)
			    or croak("open $file: $!");
			$close_out = 1;
		}
	}
	else
	{
		if ($] < 5.008)
		{
			# They'll end up with weirdly-named files in the CWD
			# if we don't give up here.
			croak("Store-and-return is not supported for ".
			      "versions of Perl older than 5.8: you must use " .
			      "\"output_file\" instead. Croaked");
		}
		open($out_fh, '>>', \$out_buf)
		    or croak("open-string failed: $!");
		$close_out = 1;
	}

	if ($opt{reported_filename})
	{
		$filename = $opt{reported_filename};
	}

	# Transform
	my $perl = template_to_perl($in_buf, $filename, @inc);
	my $pkg = __make_package_name();
	my $old_out_fh = select($out_fh);
	eval "package $pkg;\nno strict;\n$perl";
	select($old_out_fh);
	close($out_fh) if $close_out;
	if ($@)
	{
		if (! defined $errors_to)
		{
			# suppress: no-op
		}
		elsif (ref($errors_to))
		{
			if (ref($errors_to) eq 'CODE')
			{
				$errors_to->($@);
			}
			else
			{
				print $errors_to $@;
			}
		}
		else
		{
			die $@;
		}
	}
	return $out_buf; #potentially undef
}


sub expand
{
	my $self = shift;
	goto &expand_template;
}


sub template_to_perl
{
	my ($tmpl, $filename, @inc) = @_;
	$filename =~ m/^(.*)$/;
	$filename = $1;
	$filename =~ s/\"/\"\"/g;
	my $nlines = 1;
	my $perl_script = '';
	pos($tmpl) = 0;
	while ($tmpl =~ m{
		\G (.*?)                     #1: preceding or final plaintext
	        (?: \{ ([\%\$\@] \w+)        #2: scalar interpolation
		       (?:,(\w+))? \}        #3: ... with explicit escaping
		 | \<\?include (\s+.*?) \?\> #4: textual inclusion
		 | \<\?perl (\s+.*?) \?\>    #5: perl blocks
		 | \z
		 )
	}gsxi)
	{
		my $txt = $1;
		my ($ivar, $itype) = ($2, $3);
		my $include = $4;
		my $perl = $5;
		if (defined($txt) && $txt ne '')
		{
			$txt =~ s/([\'\\])/\\$1/gs;
			$perl_script .= "\n#line $nlines";
			$perl_script .= " \"$filename\""
			    if defined $filename;
			$perl_script .= "\n;print '$txt';\n";
			$nlines += ($txt =~ s/\n/\n/g);
		}
		if (defined $ivar)
		{
			$perl_script .= "\n#line $nlines";
			$perl_script .= " \"$filename\""
			    if defined $filename;
			$perl_script .= "\n";

			$itype ||= ',xml';
			$itype =~ s/^,//;
			$itype = lc($itype);
			$perl_script .= __make_interpolation($ivar, $itype);
			$nlines += ($ivar =~ s/\n/\n/g);
		}
		elsif (defined $include)
		{
			my $ifile = $include;
			$ifile =~ s/\s+/\040/sg;
			$ifile =~ s/\s*$//;
			$ifile =~ s/^\s*//;
			my $ipath = __path_search($ifile, @inc);
			if (! $ipath)
			{
				my $msg = "Can't locate \"$ifile\" in "
				  . "include_path (include_path contains: "
				  . join(" ", @inc) . ")";
				carp $msg;
			}
			else
			{
				my $ibuf;
				__slurp($ipath, \$ibuf);
				$perl_script .= template_to_perl
					($ibuf, $ipath, @inc);
			}
			$nlines += ($include =~ s/\n/\n/g);
		}
		elsif (defined $perl)
		{
			#  $perl =~ s/^\040//;
			$perl_script .= "\n#line $nlines";
			$perl_script .= " \"$filename\""
			    if defined $filename;
			$perl_script .= "\n$perl\n";
			$nlines += ($perl =~ s/\n/\n/g);
		}
	}
	return $perl_script;
}

1;
