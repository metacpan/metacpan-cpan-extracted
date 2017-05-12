package Plient::Protocol::File;

use warnings;
use strict;
require Plient::Protocol unless $Plient::bundle_mode;
our @ISA = 'Plient::Protocol';

sub prefix { 'file' }
sub methods { qw/get/ }

sub get {
    my ( $file, $args ) = @_;
    $file =~ s!file:(?://)?!!; # file:foo/bar is valid too
    open my $fh, '<', $file or warn "failed to open $file: $!" and return;
    local $/;
    <$fh>;
}

1;

__END__

=head1 NAME

Plient::Protocol::File - 


=head1 SYNOPSIS

    use Plient::Protocol::File;

=head1 DESCRIPTION


=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

