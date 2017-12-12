package Net::Hadoop::YARN;
$Net::Hadoop::YARN::VERSION = '0.203';
use strict;
use warnings;
use 5.10.0;

use Constant::FromGlobal DEBUG => { int => 1, default => 0, env => 1 };
use Net::Hadoop::YARN::ResourceManager;
use Net::Hadoop::YARN::NodeManager;
use Net::Hadoop::YARN::ApplicationMaster;
use Net::Hadoop::YARN::HistoryServer;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN

=head1 VERSION

version 0.203

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=head1 NAME

Net::Hadoop::YARN - Communicate with Apache Hadoop NextGen MapReduce (YARN)

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
