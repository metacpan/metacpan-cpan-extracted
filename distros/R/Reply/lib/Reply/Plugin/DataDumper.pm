package Reply::Plugin::DataDumper;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::DataDumper::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: format results using Data::Dumper

use base 'Reply::Plugin';

use Data::Dumper;


sub new {
    my $class = shift;

    $Data::Dumper::Terse = 1;
    $Data::Dumper::Sortkeys = 1;

    return $class->SUPER::new(@_);
}

sub mangle_result {
    my $self = shift;
    my (@result) = @_;
    return Dumper(@result == 0 ? () : @result == 1 ? $result[0] : \@result);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::DataDumper - format results using Data::Dumper

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [DataDumper]

=head1 DESCRIPTION

This plugin uses L<Data::Dumper> to format results.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
