# NAME

Net::SMPP::SSL - SSL support for Net::SMPP

# SYNOPSIS

       use Net::SMPP::SSL;
    
       my $ssmpp = Net::SMPP::SSL->new_connect( 'example.com', port => 3550 ); 

# DESCRIPTION

Net::SMPP::SSL implements the same API as Net::SMPP, but uses IO::Socket::SSL for its network operations. 

For interface documentation, please see Net::SMPP.

The implementation is based the approach used for Net::SMTP::SSL, thanks to the authors.

# SEE ALSO
Net::SMPP, IO::Socket::SSL, perl.

# LICENSE

Copyright (C) Stefan Stuehrmann.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Stefan Stuehrmann <stefan.stuehrmann@emnify.com>
