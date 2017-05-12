#!/usr/bin/perl -w
use strict;

#$Id$

# this file exists solely so that you can type
# perldoc 'sman.conf' or 'man sman.conf' and get 
# meaningful data.  

=head1 NAME

sman.conf - configuration file for sman and sman-update

=head1 SYNOPSIS

The sman.conf configuration file specifies several run-time options
for sman and sman-update.

=head1 DESCRIPTION 

sman.conf is the default name of the configuration file 
used for sman.  Sman looks for a file called sman.conf in several 
usual places, and if not found, falls back on sman-defaults.conf, 
likely from the default location of /usr/local/etc.  See 
L<Sman::Config> for details.

=head1 SMAN CONFIG FILE

Each line in a sman.conf file is either a comment or a directive.  
Comments are lines that begin with a # character.  
Directives are of the form:
    
    Directive values values values ...

The directives currently understood in an sman configuration file are:

=head2 COLCMD

A program that is used to strip out backspaces and 
such from the MANCMD output. If undefined, defaults
to 'col -b'

    Example: COLCMD col -b

=head2 MANCMD

Program that first converts the troff to ASCII. 
Absence of a MANCMD directive, or the setting AUTOCONFIG, causes
sman-update to try to ascertain the best man command on its own.
MANCMD understands a few format sequences that are used to specify
how to get man to convert your manfiles on your system.  The format sequences 
currently understood are:
  %F   the full pathname of the man file (ie, /usr/share/man/man1/ls.1.gz)
  %C   the command name (ie, ls)
  %S   the section (ie, 1 or 3pm)

  Example: MANCMD AUTOCONFIG (will choose one of the below)
or
  Example: MANCMD man %F     (linux likes this)
or
  Example: MANCMD man %S %C  (freebsd prefers this)

Also note that if you have a custom mechanism to translate
man files into XML, you can use it like this: 

  Example: MANCMD zcat --stdout -f %F | myprog

=head2 SWISHECMD
    
The path and options you'd like to use with Swish-e while indexing. 
If undefined, will default to 'swish-e'. Appropriate Swish-e options 
will be appended when indexing.

    Example: SWISHECMD swish-e -v 1

=head2 TMPDIR

where to put various temporary files. Defaults to /tmp.
(Use SWISHE_TMPDIR to set affect Swish-e at index time) 

    Example: TMPDIR /tmp 

=head2 TITLEALIASES, SECALIASES, DESCALIASES

Aliases for the XML tags we expect. These are in case an external program
returns tags different from what we expect.

    Examples:
    TITLEALIASES refentrytitle
    SECALIASES manvolnum
    DESCALIASES refpurpose 
    MANPAGEALIASES swishdefault

=head2 ENV_* (ENV_MANWIDTH, ...)

All parameters beginning with ENV_ have the ENV_ prefix stripped 
and are used to set environment variables of the corresponding names
for child processes.

In particular, on some versions of man, the MANWIDTH environment variable
controls the desired line width for manpage output. This can affect 
line-breaking during indexing on some systems.

    Example:
    ENV_MANWIDTH 256

=head2 SWISHE_* (SWISHE_IndexFile, ...)

All parameters beginning with SWISHE_ have the SWISHE_ prefix stripped 
and are written into a tmp config file for Swish-e at index time.

SWISHE_IndexFile is also used by sman to know which index to search.

You shouldn't need to change any of the other SWISHE_* parameters.
They are all documented (without the SWISHE_ prefix) in the Swish-e
documentation.

    Examples: 

    # SWISHE_IndexFile specifies which index to create and search
    SWISHE_IndexFile /var/lib/sman/sman.index 
    SWISHE_IndexComments      no 
    # SWISHE_UseStemming       yes   # for old versions of Swish-e
    SWISHE_FuzzyIndexingMode   Stem
    SWISHE_MetaNames          desc sec swishtitle 
    SWISHE_PropertyNames      desc sec 

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<sman>, L<sman-update>

1;
