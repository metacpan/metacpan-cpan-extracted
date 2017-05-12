# Copyright (c) 2012 Jasper Lievisse Adriaanse <jasper@mtier.org>
# Copyright (c) 2012-2013 M:tier Ltd.
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package Puppet::Tidy;

use 5.008;
use strict;
use Exporter;
use File::Copy;
use Text::Tabs;

use vars qw(@ISA @EXPORT $VERSION);

@ISA    = qw( Exporter );
@EXPORT = qw( &puppettidy );

$VERSION = '0.3';

my %config = (
    output_type => 'file',
    output_ext  => 'tdy',
    output_stream => undef,
    input_files => undef,
    input_stream => undef,
    validate => 0,
);

sub puppettidy(%){
    my %defaults = (
	argv => undef,
	source => undef,
	destination => undef,
    );

    my %args_hash = @_;
    %args_hash = (%defaults, %args_hash);

    # Don't bother with commandline args, if we're using the args_hash
    # to pass parameters.
    if ($args_hash{'source'} or $args_hash{'destination'}) {
	$config{'output_type'} = 'stream';
	$config{'input_stream'} = $args_hash{'source'};
	$config{'output_stream'} = $args_hash{'destination'};
	push(@{$config{'input_files'}}, "-");
    } else {
	parse_options(@ARGV);
    }

    if ($config{'input_files'} eq "-") {
	die unless ($config{'input_stream'} && $config{'output_stream'})
    }

    foreach my $file (@{$config{input_files}}) {
	my @input;

	if ($config{'output_type'} eq "file") {
	    # Just open it once for slurping, and open it once for writing later.
	    open(IF, "<$file") or die("Cannot open $file for reading: $!");
	    @input = <IF>;
	    close(IF);
	} else {
	    @input = $config{'input_stream'};
	}

	expand_tabs(\@input);
	commenting(\@input);
	trailing_whitespace(\@input);
	variable_string(\@input);
	quotes_resource_ref_type(\@input);
	quotes_title(\@input);
	quotes_attribute(\@input);
	handle_modes(\@input);
	quoted_booleans(\@input);

	if ($config{'output_type'} eq "file") {
	    open(OF, ">$file.tdy") or die("Cannot open $file.tdy for writing: $!");
	    foreach my $line (@input)
	    {
		print OF $line;
	    }
	    close(OF);
	    pp_validate("$file.tdy");
	} else {
	    @{$config{'output_stream'}} = @input;
	}
    }
}

sub usage()
{
    print STDERR << "EOF";
Puppet::Tidy $VERSION
usage: $0 [-ch] [file ...]
	-c      : Check/validate the output with "puppet parser validate".
	-h	: Show this help message.
EOF
    exit 1;
}

sub parse_options(@)
{
    require Getopt::Std;

    my %opt;
    Getopt::Std::getopts('ch', \%opt);

    usage() if defined($opt{h}) or (@ARGV < 1);

    if (defined($opt{c})) {
	# Make sure puppet is installed
	unless (grep { -x "$_/puppet"}split /:/,$ENV{PATH}) {
	    print STDERR "Puppet is not installed or cannot be run. Make sure it's in your \$PATH.\n";
	    exit 127;
	}

	$config{'validate'} = 1;
    }

    # Check if input files are readable at all up front.
    foreach my $f (@ARGV) {
	my $mode = (stat($f))[2];
	if (defined($mode) && ($mode & 4)) {
	    push(@{$config{'input_files'}}, $f);
	} else {
	    print "ERROR: $f is not readable or does not exist.\n";
	    exit 127;
	}
    }
}

# Check the output of Puppet::Tidy with "puppet parser validate".
sub pp_validate($)
{
    my $file = shift;

    open(PP, "puppet parser validate $file |") or
	die("Failed to validate manifest: $!\n");
    close(PP);
}

# Expand literal tabs to two spaces
sub expand_tabs(@)
{
    my $input = shift;
    $tabstop = 2;

    @$input = Text::Tabs::expand(@$input);
}

# Remove trailing whitespace.
sub trailing_whitespace(@)
{
    my $input = shift;
    foreach my $line (@$input)
    {
	$line =~ s/[^\S\n]+$//g;
    }
}

# Wuoted strings containing only a variable shouldn't be quoted, also
# single quoted strings containing a variable must be double quoted.
sub variable_string(@)
{
    my $input = shift;

    foreach my $line (@$input)
    {
	# Skip commented lines.
	next if (($line eq "\n") or ($line =~ m/^#/));

	# Remove double quotes around a standalone variable
	$line =~ s/"\$\{(.*?)\}"/\$\{$1\}/g;
	$line =~ s/"\$(.*?)"/\$$1/g;

	# Remove single quotes around a standalone variable
	$line =~ s/\x27\$(.*?)\x27/\$$1/g;
    }
}

# Gix double quotes when used when references resources (File, Group, etc).
# Bariables were already removed in the previous step so we can't have
# a Package["$pkg"] here anymore.
sub quotes_resource_ref_type(@)
{
    my $input = shift;
    foreach my $line (@$input) {
	if ($line =~ m/([^a-z][a-zA-Z]+)\[.*\]/) {
	    my $type = $1;
	    next unless $line =~ m/$type\[\"/;

	    $line =~ s/$type\["(.*?)"\]/$type\[\x27$1\x27\]/g;
	}
    }
}

# Titles, like '/etc/fstab': shouldn't contain doubles quotes, unless
# it contains or is a variable. Otherwise all titles should be single quoted.
sub quotes_title(@)
{
    my $input = shift;

    foreach my $line (@$input) {
	next if $line =~ m/\s*path/; # XXX: Tighten regexps below and remove me
	next if $line =~ m/\s*command/;  # XXX: Tighten regexps below and remove me
	next if ($line =~ m/\:\:/); # XXX: Skip lines with qualified variables

	# Strings with a variable should be double quoted, but care
	# must be taken if it's alse single quoted which is wrong anyway.
	if ($line =~ m/\$.*?:(\s*|$)/) {
	    next if $line =~ s/(\x27*)(\$\w+)(\x27*)/"$2"/g;
	    next if $line =~ s/(\$\w+)/"$1"/g;
	}
	$line =~ s/"(.*?)":/\x27$1\x27:/g; # Double to single quoted
	$line =~ s/(?!['"])(\w+):(?!.+['"]+)/\x27$1\x27:/g; # Bare word to single quoted
    }
}

# Certain attributes should be single quoted, unless it is, or contains
# a variable.
sub quotes_attribute(@)
{
    my $input = shift;
    my @attributes = qw(mode path); # XXX: non-exhaustive list

    # "Bare" to single quoted with no variables.
    foreach my $line (@$input) {
	next if $line =~ m/\$/;
	foreach my $attr (@attributes)
	{
	    $line =~ s/($attr)(\s+)=>(\s+)(\w+)/$1$2=>$3\x27$4\x27/g;
	}
    }

    # Double quoted to single quoted with no variables.
    foreach my $line (@$input) {
	next unless $line =~ m/=\> "/;
	next if $line =~ m/\$/;
	foreach my $attr (@attributes)
	{
	    $line =~ s/($attr)(\s+)=>(\s+)"(\w+)"/$1$2=>$3\x27$4\x27/g;
	}
    }

    # Variables should be double quoted for string interpolation,
    # which won't be done for at least mode since it's fully nummeric.
    foreach my $line (@$input) {
	next unless (($line =~ m/=\> '/) and ($line =~ m/\$/));
	foreach my $attr (@attributes)
	{
	    next if ($attr eq "mode");
	    $line =~ s/($attr)(\s+)=>(\s+)'(\w+)'/$1$2$3\x22$4\x22/g;
	}
    }
}

# File modes need to be specified with 4 digits.
sub handle_modes(@)
{
    my $input = shift;

    foreach my $line (@$input)
    {
	next if $line =~ m/\$/;
	# Rewrite to four digits if only three are defined.
	$line =~ s/mode(\s+)=>(\s+)\x27(\d{3})\x27/mode$1=>$2\x270$3\x27/g;
    }
}

# C (/**/) or C++ (//) style comments are not recommended.
sub commenting(@)
{
    my $input = shift;

    foreach my $line (@$input)
    {
	$line =~ s,(?!['"].+)//(?!.+['"]),#,; # C++ style
	$line =~ s,/\*(.*?)(\s+)\*/,#$1,; # C style
    }
}

# Insert a warning regarding quoted booleans. The lines aren't actually
# changed since this will change the meaning of the statement, so instead
# we just insert an XXX.
sub quoted_booleans(@)
{
    my $input = shift;

    foreach my $line (@$input)
    {
	next unless ($line =~ /(\x27|\x22)(false|true)(\x27|\x22)/);

	if ($line =~ /false/) {
	    ($] < 5.010000) ? $line =~ s/(?>\x0D\x0A|\v)//g : $line =~ s/\R//g;
	    $line = $line . " # XXX: Quoted boolean encountered.\n";
	}

	if ($line =~ /true/) {
	    $line =~ s/(\x22|\x27)true(\x22|\x27)/true/g;
	}
    }
}

1;

__END__

=head1 NAME

Puppet::Tidy - Tidies up your Puppet manifests

=head1 SYNOPSIS

    use Puppet::Tidy;

    Puppet::Tidy::puppettidy(
        source		=> $source,
        destination	=> \@destination
    );

=head1 DESCRIPTION

This module parses the Puppet code and applies a subset of checks from
the Puppet Style Guide onto it. Currently the set of checks is rather
limited, but already enough is implemented to catch common mistakes and
to save you a great deal of time cleaning up your manifests.

The Puppet Style Guide can be found at
L<http://docs.puppetlabs.com/guides/style_guide.html>.

=head2 CHECKS

Currently the following checks are implemented:

=head2 expand_tabs

    No literal tabs are allowed, this method converts literal tabs to two spaces.

=head2 trailing_whitespace

    Removes trailing whitespace.

=head2 variable_string

    Strings which only contain a variable, mustn't be quoted.

=head2 quotes_resource_ref_type

    Check for an idiom where reference resource types (File, Package, Group)
    have a double quoted string as argument. This requires the
    variable_string() method to be called before.

=head2 quotes_title

    Resource titles should be single quoted, unless they contain a variable.
    In which case they should be double quoted.

=head2 quotes_attribute

    Attributes should be enclosed in single quotes, unless they
    contain a variable in which case either double or no quoting
    is needed.

=head2 handle_modes

    File modes should be defined using four digits, not three as often
    done by mistake.

=head2 commenting

    Although Puppet supports C (/**/) and C++ (//) style comments, it's
    advised to use regular Puppet comments which use a pound sign (#).

=head2 quoted_booleans

    Booleans mustn't be quoted, since this means they're not nil, and will
    thus evaluate to true. These errors are not fixed by Puppet::Tidy since
    changing 'false' to true actually changing the meaning of a statement.
    Instead, a warning is inserted into the file.

=head1 LICENSE

This module is free software, can you redistribute it and/or modify it
under the terms of the ISC license. The full license text can be found
in this module's LICENSE file.

=head1 CREDITS

Thanks to M:tier Ltd. (L<http://www.mtier.org/>) for sponsoring development
of this module.

=head1 AUTHOR

  Jasper Lievisse Adriaanse

=cut
