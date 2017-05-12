###########################################
package PasswordMonkey::Filler::Password;
###########################################
use strict;
use warnings;
use base qw(PasswordMonkey::Filler);

###########################################
sub prompt {
###########################################
    my($self) = @_;

    return qr([Pp]assword:);
}

1;

__END__

=head1 NAME

PasswordMonkey::Filler::Password - Password filler for shell password prompts

=head1 SYNOPSIS

    use PasswordMonkey::Filler::Password;

=head1 DESCRIPTION

Waits for a prompt like

    Password:

or

    password:

and sends the configured password if it sees one.

=head1 AUTHOR

2011, Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Yahoo! Inc. All rights reserved. The copyrights to 
the contents of this file are licensed under the Perl Artistic License 
(ver. 15 Aug 1997).

