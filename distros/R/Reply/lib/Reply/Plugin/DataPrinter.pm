package Reply::Plugin::DataPrinter;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::DataPrinter::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: format results using Data::Printer

use base 'Reply::Plugin';

use Data::Printer alias => 'p', colored => 1, return_value => 'dump';


sub mangle_result {
    my ($self, @result) = @_;
    return unless @result;
    ( @result == 1 ) && return p($result[0]);
    return p(@result);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::DataPrinter - format results using Data::Printer

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [DataPrinter]

=head1 DESCRIPTION

This plugin uses L<Data::Printer> to format results.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
