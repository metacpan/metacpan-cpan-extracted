##
# name:      Stardoc
# abstract:  Acmeist Documentation Toolset
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Stardoc;
use 5.008003;

our $VERSION = '0.18';

use IO::All 0.41;
use Mouse 0.93;
use Template::Toolkit::Simple 0.13;
use YAML::XS 0.35;

1;

=head1 SYNOPSIS

    use Stardoc;

=head1 DESCRIPTION

Stardoc is a toolset for making programming documentation easier.

It is intended to one day be a way to write Acmeist documentation. That is,
documentation that you write once, and it works in all programming languages.

=head1 WARNING

This is a very early release. Don't use Stardoc yet. Things are still being
worked out.

=head1 CURRENT USAGE

Right now, you can use it to simplify your Perl module docs.

Take a look at the source code for this module. The POD lacks several standard
sections. These sections are generated from the information provided in the
special Stardoc section at the top.

The Stardoc section starts with C<##> and contains a YAML map or metadata.
