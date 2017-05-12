package Net::Google::Calendar::Server::Auth;

use strict;

=head1 NAME

Net::Google::Calendar::Server::Auth - the base class for authentication modules.

=cut

sub new {
    my $class = shift;
    my %opts  = @_;

    return bless \%opts, $class;
}

sub validate {
    return undef;
}

sub auth {
    return 0;
}

sub magic_cookie_auth {
	return 0;
}

1;
