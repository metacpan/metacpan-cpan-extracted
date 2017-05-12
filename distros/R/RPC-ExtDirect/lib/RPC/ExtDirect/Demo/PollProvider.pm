package RPC::ExtDirect::Demo::PollProvider;

use strict;
use warnings;

use POSIX 'strftime';

use RPC::ExtDirect;
use RPC::ExtDirect::Event;

sub poll : ExtDirect(pollHandler) {
    my $time = strftime "Successfully polled at: %a %b %e %H:%M:%S %Y",
                        localtime;

    return RPC::ExtDirect::Event->new('message', $time);
}

1;

__END__

=pod

=head1 NAME

RPC::ExtDirect::Demo::PollProvider - Ext.Direct polling provider demo

=head1 DESCRIPTION

This module implements polling provider used in ExtJS Ext.Direct demo
scripts; it is not intended to be used per se but rather as an example.

I decided to keep it in the installation tree so that it will always
be available to look up without going to CPAN.

=head1 SEE ALSO

You can use C<perldoc -m RPC::ExtDirect::Demo::PollProvider> to see the actual
code.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2016 by Alexander Tokarev. 

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

