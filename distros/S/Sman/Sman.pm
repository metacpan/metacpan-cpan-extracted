package Sman;

#$Id$
# small change

require 5.006;
use strict;

#$VERSION and $SMAN_DATA_VERSION moved to Sman/Util.pm

#our $VERSION = '1.03';
#our $SMAN_DATA_VERSION = "1.4";     # this is only relevant to Sman
    # SMAN_DATA_VERSION 1.2 enables section "N"
    # SMAN_DATA_VERSION 1.3 enables use of doclifter to convert pages
    # SMAN_DATA_VERSION 1.4 re-disables use of doclifter to convert pages

1;
__END__

=head1 NAME

Sman - Tool for searching and indexing man pages

=head1 SYNOPSIS

 % sman boot disk
    # searches for man pages about 'boot disk'

  % sman -m 10 -f -r linux kernel
    # show first 10 hits about the linux kernel
    # with the manpage's Rank and Filename

  % sman '(linux and kernel and module) or (eepro100 and ipchains)'
    # a more complex query

  % sman swishtitle=linux and desc=kernel
    # where title contains 'linux' and description contains 'kernel'

=head1 DESCRIPTION

Sman is the Searcher for Man pages. It depends on an index which is built by
the included sman-update which by default resides in /var/lib/sman/sman.index.
 
The two included progams,  sman and sman-update, will both
search for the first configuration file named sman.conf in /etc, 
/usr/local/etc/, $HOME, or the directory with sman. If no sman.conf file is found 
(or specified through the --config option), then the default 
configuration in /usr/local/etc/sman-defaults.conf will be used.

NOTE: In all cases command line options take precedence over directives read from
configuration files.

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<sman>, L<sman-update>, L<sman.conf>

=cut

