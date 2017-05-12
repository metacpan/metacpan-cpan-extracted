# -*- perl -*-
#
#
#   ExtUtils::PerlPP - A Perl Preprocessor
#
#
#   This module is Copyright (C) 1998 by
#
#       Jochen Wiedmann
#       Am Eisteich 9
#       72555 Metzingen
#       Germany
#
#       Email: joe@ispsoft.de
#       Phone: +49 7123 14887
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either the GNU
#   General Public License or the Artistic License, as specified in
#   the Perl README file.
#

use strict;
use Exporter;


package ExtUtils::PerlPP;

use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(ppp);
$VERSION = '0.02';


sub new {
    my $proto = shift;
    my $self = { @_ };
    bless ($self, (ref($proto) || $proto));
    $self;
}


sub ppp {
    my($in, $out, $config) = @_ ? @_ : @ARGV;
    my $parser = ExtUtils::PerlPP->new('in_fh' => $in,
				       'out_fh' => $out,
				       'config' => $config);
    $parser->parse();
}


sub _ParseVar {
    my($self, $config, $var, $subvar) = @_;
    my($text) = sprintf("%s%s", $var, (defined($subvar) ? $subvar : ""));
    my $result;
    if (!exists($config->{$var})) {
	if ($self->{'no_config_default'}) {
	    return '';
	}
	$result = $Config::Config{$var};
    } else {
	$result = $config->{$var};
    }

    while (defined($result)  &&  $subvar  &&  $subvar =~ /^\-\>(\w+)/) {
	$var = $1;
	$subvar = $';
	if ($var =~ /^\d+$/) {
	    if (ref($result) ne 'ARRAY') {
		return '';
	    }
	    $result = $result->[$var];
	} else {
	    if (ref($result) ne 'HASH') {
		return '';
	    }
	    $result = $result->{$var};
	}
    }

    if (!defined($result)) {
	$result = '';
    } elsif (ref($result) eq 'CODE') {
	$result = &$result($self, $text);
	if (!defined($result)) {
	    $result = '';
	}
    }

    $result;
}


sub _ParseVars {
    my($self, $config, $line) = @_;
    $line =~ s/\~\~(\w+)((\-\>\w+)*)\~\~/$self->_ParseVar($config, $1, $2)/eg;
    $line;
}


sub _Condition {
    my($self, $lineNum, $config, $line) = @_;
    $line = $self->_ParseVars($config, $line);
    my $result = eval $line;
    if ($@) {
	die "Error while evaluating condition at line $lineNum: $@";
    }
    $result;
}


sub parse {
    my $line;
    my $self = shift;
    my $in = $self->{'in_fh'};
    my $out = $self->{'out_fh'};
    my $config = $self->{'config'};
    my $defaultConfig = !$self->{'no_config_default'};
    my $makeDirs = !$self->{'no_makedirs'};
    my @if_stack;
    my $if_state = 1;

    if (!ref($in)) {
	require IO::File;
	my $fh = IO::File->new($in, "r");
	if (!$fh) {
	    die "Error while opening $in: $!";
	}
	$in = $fh;
    }
    if (!ref($out)) {
	# Create directories, if desired
	if ($makeDirs) {
	    require File::Basename;
	    my $base = File::Basename::dirname($out);
	    if (! -d $base) {
		require File::Path;
	        File::Path::mkpath([$base], 0, 0755);
	    }
	}

	require IO::File;
	my $fh = IO::File->new($out, "w");
	if (!$fh) {
	    die "Error while opening $out: $!";
	}
	$out = $fh;
    }
    if (!ref($config)) {
	require IO::File;
	my $fh = IO::File->new($config, "r");
	if (!$fh) {
	    die "Error while opening $config: $!";
	}
	local($/) = undef;
	my $code = $fh->getline();
	if (!defined($code)) {
	    die "Error while reading $config: $!";
	}
	my $result = eval $code;
	if ($@) {
	    die "Error while evaluating $config: $!";
	}
	$config = $result;
    }

    if ($defaultConfig) {
	require Config;
    }

    my $lineNum = 0;
    while (defined($line = $in->getline())) {
	++$lineNum;
	if ($line =~ /^\s*\~\#if\#\~/) {
	    my $new_state = $if_state  &&
		$self->_Condition($lineNum, $config, $');
	    unshift(@if_stack, [$new_state, $if_state, $lineNum]);
	    $if_state = $new_state;
	} elsif ($line =~ /^\s*\~\#elsif\#\~/) {
	    if (!@if_stack) {
		die "~#elsif#~ without ~#if#~ at line $lineNum";
	    }
	    my $if_elem = $if_stack[0];
	    $if_state = $if_elem->[1] && !$if_elem->[0] &&
		$self->_Condition($lineNum, $config, $');
	    if ($if_state) {
		$if_elem->[0] = 1;
	    }
	} elsif ($line =~ /^\s*\~\#else\#\~/) {
	    if (!@if_stack) {
		die "~#else#~ without ~#if#~ at line $lineNum";
	    }
	    my $if_elem = $if_stack[0];
	    $if_state = $if_elem->[1] && !$if_elem->[0];
	    if ($if_state) {
		$if_elem->[0] = 1;
	    }
	} elsif ($line =~ /^\s*\~\#endif\#\~/) {
	    if (!@if_stack) {
		die "~#endif#~ without ~#if#~ at line $lineNum";
	    }
	    my $if_elem = shift @if_stack;
	    $if_state = $if_elem->[1];
	} elsif ($line =~ /^\s*\~\&([a-zA-Z_]\w*)\&\~/) {
	    $line = $';
	    my $var = $1;
	    my $code = '';
	    my $oldLineNum = $lineNum;

	    while (defined($line)  &&  $line !~ /\~\&\&\~/) {
		$code .= $line;
		$line = $in->getline();
	    }
	    if (!defined($line)) {
		die "~&$var&~ without ~&&~ at line $oldLineNum";
	    }
	    if ($line =~ /\~\&\&\~/) {
		$code .= $`;
	    }
	    $self->{'config'}->{$var} = eval "sub { $code }";
	    if ($@) {
		die "Error while defining method $var at line $oldLineNum: $@";
	    }
	} elsif ($if_state) {
	    if (!$out->print($self->_ParseVars($config, $line))) {
		die "Error while writing: $!";
	    }
	}
    }
}


1;

__END__

=head1 NAME

ExtUtils::PerlPP - A Perl Preprocessor


=head1 SYNOPSIS

    use ExtUtils::PerlPP;
    my $config = { 'version' => $VERSION,
		   'driver' => $DRIVER };


    # The long and winding road ...
    my $self = ExtUtils::PerlPP->new();

    $self->{'in_fh'} = IO::File->new('file.PL', 'r');
    $self->{'out_fh'} = IO::File->new('file', 'w');
    $self->{'config'} = 

    $self->parse();


    # And now a short cut for the same:
    ppp('file.PL', 'file', $config);


=head1 DESCRIPTION

Perl's installation suite, ExtUtils::MakeMaker, contains a mechanism for
installing preparsed files, so-called I<PL> files: If the MakeMaker utility
detects files with the extension C<.PL> then these files are executed
by I<make>, usually creating a file of the same name, except the C<.PL>
extension.

Writing these PL files is usually always the same, for example a typical
C<.PL> file might look like this:

    my $script = <<'SCRIPT';
    ... # True file following here
    SCRIPT

    # Modify variable $script, depending on configuration, local
    # site or whatever
    ...

    if (!open(FILE, ">file")  ||  !(print FILE $script)  ||
	!close(FILE)) {
	die "Cannot write file: $!";
    }

But in essence, what else is this than a Perl preprocessor?

Traditionally you have to write such a Perl preprocessor for yourself
all the time, although I have found that they always do the same, for
example:

=over 8

=item -

Fix defaults, for example installation paths.

=item -

Including or excluding code sections. It is a matter of taste whether one
likes to see

    if ($] < 5.003) {
	# Thirty lines of code following here
        ...
    } else {
        # A single line of code
        ...
    }

when already using Perl 5.005. I don't.

=back


This module is dedicated to simplify such tasks. In short, you can use
it like this:


=head2 Create a new preprocessor

You start with creating an instance of I<ExtUtils::PerlPP> by calling
the I<new> constructor:

    my $ppp = ExtUtils::PerlPP->new(%attr);

The constructor accepts a list of attributes, including the following:

=over 8

=item in_fh

The input file, any kind of IO object, for example an instance of
IO::File or IO::Scalar. More general: It can be any object that offers
a I<getline> method.

A scalar value (to be distinguished from an IO::Scalar instance!) will
be interpreted as a file name that the method opens for you.

=item out_fh

The output file; another IO object or any other object that offers a
I<print> method. A scalar value is accepted as output file name.

=item config

A hash ref of preprocessor variables. In other words

    $ppp->{'config'}->{'var'} = 1;

is what C<-Dvar=val> is for the C preprocessor. Similarly you can compare

    delete $ppp->{'config'};

with C<-Uvar>. See L<"Macro replacements"> below. Unlike C, variables may
be arbitrarily complex, in particular you can use hash or array refs as
values.

Surprisingly you may pass a scalar value again: In that case the file of
the same name evaluated and the result is used as a configuration hash.
In other words

    $ppp->{'config'} = "myapp.cfg";

is similar to

    $ppp->{'config'} = do "myapp.cfg";

Such config files can easily be created using the I<Data::Dumper> module.
L<Data::Dumper(3)>.

=item no_config_default

If a variable name is used, but no such attribute is present in the
I<config> hash, then by default the variable is looked up in the
C<$Config> from the I<Config> module. This behaviour is suppressed,
if you set I<no_config_default> to a TRUE value. L<Config(3)>.

=item no_makedirs

By default directories are created silently if required. For example,
if you pass a value of C</usr/local/foo/bar> as output file and only
C</usr/local> exists, then the subdirectory C<foo> will be created.
The option I<no_makedirs> suppresses this behaviour.

=back


=head2 Running the preprocessor

This is done by executing

    $ppp->parse();

A Perl exception will be thrown in case of errors, thus the complete
use might look like this:

    eval { $ppp->parse(); };
    if ($@) { print "An error occurred: $@\n" }


=head2 Using the frontend

Most applications won't call the I<new> or I<parse> methods directly,
but rather do a

    use ExtUtils::PerlPP;
    ppp('infile', 'outfile', 'configfile');

This is equivalent to

    my $parser = ExtUtils::PerlPP->new('in_fh' => 'infile',
				       'out_fh' => 'outfile',
                                       'config' => 'configfile');
    $parser->parse();

In order to be easily used within Makefiles, the ppp frontend can
read from @ARGV. That is, you can use the module like this:

    perl -MExtUtils::PerlPP -e ppp <infile> <outfile> <configfile>

from the commandline.


=head2 Macro replacements

The primary use of preprocessor variables (aka attributes of
C<$ppp->{'config'}>) is replacing patterns in the stream written to
the output file. With C<$c = $ppp->{'config'}> in mind the typical
patterns and their replacements are:

    ~~a~~		$c->{'a'}
    ~~b~~		$c->{'b'}
    ~~a->b~~		$c->{'a'}->{'b'}
    ~~a->e~~		$c->{'a'}->{'e'}
    ~~a->1~~		$c->{'a'}->[1]
    ~~a->1->b~~         $c->{'a'}->[1]->{'b'}

I hope the idea is obvious. Real world examples might be:

    my $config_file = "~~etc_dir~~/configuration";
    my $VERSION = "~~version~~";

Preprocessor variables need not be scalar values: If a variable contains a
code ref, then the module will execute

    &$var($ppp, $text);

and replace the pattern with the result. C<$text> is the pattern being
replaced, for example, if C<$ppp->{'config'}->{'bar'}> has the value
C<\&foo>, then C<~~bar~~> will be replaced with the result of

    foo($ppp, "bar");

Arguments are not yet supported.


=head2 Creating macros

When talking about code refs, we need a possibility to create them.
The best possibility is creating them within the input file, as in

    ~&foo&~ my($self, $text) = @_; $text x 2; ~&&~

This example is mainly equivalent to

    $ppp->{'config'}->{'foo'} = sub {
        my($self, $text) = @_; $text x 2;
    };

The C<~&var&~> definition must start at the beginning of a line, much
like the C preprocessor. The end pattern ~&&~ may appear at any point,
but the remaining line will be ignored.


=head2 Conditional output

The next application of a preprocessor is conditional output, as in an

    #ifdef var
    ...
    #endif

segment. This can be done with

    ~#if#~ <expression>
    ...
    ~#elsif#~ <expression>
    ...
    ~#else#~
    ...
    ~#endif#~

C<E<lt>expressionE<gt>> is handled as follows: First it is subject to
the usual pattern replacements and then it is evaluated as a Perl
expression returning a TRUE or FALSE value. Examples:

    ~#if#~ "~~a~~"

is TRUE, if and only if $ppp->{'config'}->{'a'} is TRUE.

Currently conditionals must start at the beginning of a line and expressions
must not exceed a single line. Nesting conditions is possible.


=head2 Embedding into MakeMaker

For using the preprocessor from within MakeMaker, I propose the following:
First of all you create a config file from within Makefile.PL. For example
the I<libnet> suite creates a file C<libnet.cfg> and the I<SNMP::Monitor>
and I<Cisco::Conf> modules create a file C<configuration>. The
I<Data::Dumper> module will aid you in that task. L<Data::Dumper(3)>.

Then you add the following to your Makefile.PL, I assume the name
C<myapp.cnf> for the config file:

    package MY;

    sub processPL {
        my($self) = shift;
        return "" unless $self->{PL_FILES};
        my(@m, $from, $to);
        foreach $from (sort keys %{$self->{PL_FILES}}) {
	    $to = $self->{PL_FILES}->{$from};
	    push @m, "
    all :: $self->{PL_FILES}->{$plfile}
	    $self->{NOECHO}\$(NOOP)

    $self->{PL_FILES}->{$plfile} :: $plfile
            \$(PERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) \
                    -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \
                    -MExtUtils::PerlPP -e 'ppp($from, $to, \"myapp.cnf\")'
    ";
        }
        join "", @m;
    }


Next you create your template files under their usual names, but add an
extension C<.PL>. The MakeMaker utility will automatically detect these
files for you and add appropriate rules to the Makefile it generates.


=head1 AUTHOR AND COPYRIGHT

This module is Copyright (C) 1998 by

       Jochen Wiedmann
       Am Eisteich 9
       72555 Metzingen
       Germany

       Email: joe@ispsoft.de
       Phone: +49 7123 14887

All rights reserved.

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.


=head1 SEE ALSO

L<ExtUtils::MakeMaker(3)>, L<Data::Dumper(3)>
