package Railsish::CoreHelpers;
our $VERSION = '0.21';

# ABSTRACT: Things that you'll need in about everywhere.

use strict;
use warnings;

use Exporter::Lite;
our @EXPORT = qw(railsish_mode app_root logger);

use Log::Dispatch;
use Log::Dispatch::File;

use File::Spec::Functions;

sub railsish_mode {
    $ENV{RAILSISH_MODE} || "development"
}

sub app_root {
    catfile($ENV{APP_ROOT}, @_)
}

use Railsish::Logger;
{
    my $logger;
    sub logger {
	return $logger if defined($logger);
	$logger = Railsish::Logger->new;
	return $logger;
    }
}

1;

__END__
=head1 NAME

Railsish::CoreHelpers - Things that you'll need in about everywhere.

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

