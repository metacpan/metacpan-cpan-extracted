package Net::SPID::OpenID;
$Net::SPID::OpenID::VERSION = '0.15';
use strict;
use warnings;

use Carp;

sub new {
    croak "OpenID for SPID is not implemented yet";
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::OpenID

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    my $spid = Net::SPID->new(protocol => 'openid');

=head1 ABSTRACT

This class is a placeholder, waiting for the OpenID SPID specs to be released.

=head1 CONSTRUCTOR

=head2 new

Calling C<new> will throw an exception as this class is not implemented yet.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
