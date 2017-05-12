###########################################
package PasswordMonkey::Filler::Sudo;
###########################################
use strict;
use warnings;
use base qw(PasswordMonkey::Filler);

###########################################
sub prompt {
###########################################
    my($self) = @_;

    return qr(\[sudo\] password for [\w_]+:);
}

1;

__END__

=head1 NAME

PasswordMonkey::Filler::Sudo - Password filler for the sudo command

=head1 SYNOPSIS

    use PasswordMonkey::Filler::Sudo;

=head1 DESCRIPTION

Waits for a prompt like

    [sudo] password for joeuser:

and sends the configured Password if it sees one.

=head1 AUTHOR

2011, Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Yahoo! Inc. All rights reserved. The copyrights to 
the contents of this file are licensed under the Perl Artistic License 
(ver. 15 Aug 1997).

