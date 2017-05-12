#!/usr/bin/env perl

use strict;
use warnings;

use MojoX::ValidateHeadLinks;

use Getopt::Long;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'help',
 'doc_root=s',
 'maxlevel=s',
 'minlevel=s',
 'url=s',
) )
{
	pod2usage(1) if ($option{'help'});

	# Return 0 for success and 1+ for failure.

	exit MojoX::ValidateHeadLinks -> new(%option) -> run;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

validate.head.links.pl - Ensure CSS and JS links in web pages point to real files

=head1 SYNOPSIS

validate.head.links.pl [options]

	Options:
	-help
	-doc_root aDirName
	-maxlevel logOption1
	-minlevel logOption2
	-url aURL

Exit value: 0 for success, 1+ for failure. Die upon error.

The exit value is the number of files not found.

=head1 OPTIONS

=over 4

=item o -doc_root aDirName

The root directory of the web site. This option is mandatory.

Default: ''.

=item o -help

Print help and exit.

=item o -maxlevel logOption1

This option affects Log::Handler.

See the Log::Handler::Levels docs.

Default: 'notice'.

For more details in the printed report, try:

my($validator) = MojoX::ValidateHeadLinks -> new(doc_root => $d, maxlevel => 'debug', url => $u);

=item o -minlevel logOption2

This option affects Log::Handler.

See the Log::Handler::Levels docs.

Default: 'error'.

No lower levels are used.

=item -url aURL

The URL of the web site's home page. This option is mandatory.

Default: ''.

=back

=cut
