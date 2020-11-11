package App::TenableSC::Logger;

use strict;
use warnings;

use Time::Piece;

our $VERSION = '0.300';

#-------------------------------------------------------------------------------
# CONSTRUCTOR
#-------------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless {}, $class;
}

#-------------------------------------------------------------------------------

sub log {
    my ( $self, $level, $message ) = @_;

    my $now = Time::Piece->new->datetime;
    print STDERR "[$now] [$$] $level - $message\n";

    return;
}

#-------------------------------------------------------------------------------

sub info {
    return shift->log( 'INFO', shift );
}

#-------------------------------------------------------------------------------

sub debug {
    return shift->log( 'DEBUG', shift );
}

#-------------------------------------------------------------------------------

sub warning {
    return shift->log( 'WARNING', shift );
}

#-------------------------------------------------------------------------------

sub error {
    return shift->log( 'ERROR', shift );
}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

App::TenableSC::Logger - Simple Logger package for App::TenableSC


=head1 SYNOPSIS

    use App::TenableSC::Logger;

    my $logger = App::TenableSC::Logger->new;
    $logger->debug('Hello, Tenable.sc');


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 METHODS


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
