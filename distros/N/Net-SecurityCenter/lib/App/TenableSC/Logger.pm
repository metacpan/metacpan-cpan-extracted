package App::TenableSC::Logger;

use strict;
use warnings;

use Time::Piece;

our $VERSION = '0.311';

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

sub info    { shift->log( 'INFO',    shift ) }
sub debug   { shift->log( 'DEBUG',   shift ) }
sub warning { shift->log( 'WARNING', shift ) }
sub error   { shift->log( 'ERROR',   shift ) }

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


=head1 CONSTRUCTOR

=head2 App::TenableSC::Logger->new

Create a new instance of L<App::TenableSC::Logger>.


=head1 METHODS

=head2 $logger->error|warning|debug|info ( $message )

Write message in STDERR.


=head1 SEE ALSO

L<Log::Log4perl>, L<Log::Any>, L<Mojo::Log>


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

This software is copyright (c) 2018-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
