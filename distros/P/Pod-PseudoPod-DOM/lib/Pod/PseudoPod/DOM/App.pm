package Pod::PseudoPod::DOM::App;
# ABSTRACT: helper functions shared between bin/ppdom2* modules

use strict;
use warnings;
use autodie;
use Exporter 'import';
our @EXPORT_OK = qw( open_fh );

sub open_fh
{
    my ($file, $mode) = @_;

    # default to reading
    $mode ||= '<';

    open my $fh, $mode . ':encoding(UTF-8)', $file;
    return $fh;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::App - helper functions shared between bin/ppdom2* modules

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
