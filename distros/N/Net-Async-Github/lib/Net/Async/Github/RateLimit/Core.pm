package Net::Async::Github::RateLimit::Core;
$Net::Async::Github::RateLimit::Core::VERSION = '0.002';
use strict;
use warnings;

sub new { my $class = shift; bless { @_ }, $class }

sub limit { shift->{limit} }
sub remaining { shift->{remaining} }
sub reset : method { shift->{reset} }
sub seconds_left { shift->reset - time }

1;

