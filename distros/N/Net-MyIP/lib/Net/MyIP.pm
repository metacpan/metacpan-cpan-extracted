package Net::MyIP;

our $VERSION = '0.02';

use utf8;
use JSON::XS;
use LWP::Simple qw(get);

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub myip {
	return decode_json(get('https://api.myip.com'));
}

1;
__END__

=head1 NAME

Net::MyIP - Get ip address from https://api.myip.com/

=head1 SYNOPSIS

	use Net::MyIP;
	my $ip = Net::MyIP->new->myip();

	say $ip->{ip};
	say $ip->{country};
	say $ip->{cc};

=head1 AUTHOR

Rajkumar Reddy, E<lt>mesg.raj@outlook.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by raj

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
