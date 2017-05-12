package RPC::Serialized::Client::STDIO;
{
  $RPC::Serialized::Client::STDIO::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Client';

use IO::Handle;

sub new {
    my $class = shift;

    my $ifh = IO::Handle->new_from_fd( STDIN->fileno, "r" );
    my $ofh = IO::Handle->new_from_fd( STDOUT->fileno, "w" );

    $ofh->autoflush(1);

    return $class->SUPER::new(
        @_, {rpc_serialized => {ifh => $ifh, ofh => $ofh}},
    );
}

1;

# ABSTRACT: RPC client using Standard I/O


__END__
=pod

=head1 NAME

RPC::Serialized::Client::STDIO - RPC client using Standard I/O

=head1 VERSION

version 1.123630

=head1 SYNOPSIS

 use RPC::Serialized::Client::STDIO;
  
 my $c = RPC::Serialized::Client::STDIO->new;
  
 my $result = $c->remote_sub_name(qw/ some data /);
     # remote_sub_name gets mapped to an invocation on the RPC server
     # it's best to wrap this in an eval{} block

=head1 DESCRIPTION

This module allows you to communicate with an L<RPC::Serialized> server over
Standard Input and Standard Output.

You would not normally use this module directly, except perhaps for testing.
It might be more useful as a base class upon which to build another more
useful client.

For further information on how to pass settings into C<RPC::Serialized>, and
make RPC calls against the server, please see the L<RPC::Serialized> manual
page.

=head1 THANKS

This module is a derivative of C<YAML::RPC>, written by C<pod> and Ray Miller,
at the University of Oxford Computing Services. Without their brilliant
creation this system would not exist.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

