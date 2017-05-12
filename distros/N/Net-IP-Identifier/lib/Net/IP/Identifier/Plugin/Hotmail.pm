#===============================================================================
#      PODNAME:  Net::IP::Identifier::Plugin::Hotmail
#     ABSTRACT:  identify Hotmail owned IP addresses - obsolete
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Oct 12 19:32:46 PDT 2014
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Plugin::Hotmail;

use Role::Tiny::With;
with qw( Net::IP::Identifier_Role );

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    # as of May 2015, all netblocks previously owned by Hotmail are
    #    now owned directly by Microsoft - this module is obsolete
    $self->ips(
    );
    return $self;
}

sub name {
    return 'Hotmail';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Plugin::Hotmail - identify Hotmail owned IP addresses - obsolete

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 # OBSOLETE use Net::IP::Identifier::Plugin::Hotmail;

=head1 DESCRIPTION

This module is obsolete.  All netblocks previously known to be owned by
Hotmail are now owned by Microsoft (as of May 2015).

=head1 SEE ALSO

=over

=item IP::Net

=item IP::Net::Identifier

=item IP::Net::Identifier_Role

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
