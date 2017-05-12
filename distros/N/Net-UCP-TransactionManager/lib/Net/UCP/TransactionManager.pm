package Net::UCP::TransactionManager;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.02';

use constant HIGHEST_NBR => 99;

sub new { bless({}, shift())->_init(@_); }

sub get_trn {
    my ($self, $resp) = @_;
    
    return unless defined $resp;
    return $1 if ($resp =~ m/^(\d{2}).*/);
}

sub next_trn {
    my $self = shift;
    
    $self->{TRN}++;
    ($self->{TRN} > HIGHEST_NBR) && do{ $self->{TRN} = 0 };
    return $self->{TRN};
}

sub current_trn {
    my $self = shift;

    $self->reset_trn() if !defined $self->{TRN};
    return $self->{TRN};
}

sub set_trn {
    my $self    = shift;
    my $tmp_trn = shift;

    if ($tmp_trn =~ m/\A\d+\Z/) {
	$self->{TRN} = $tmp_trn;
	$self->{TRN} = 0 if ($self->{TRN} > HIGHEST_NBR);
    }

    return $self->current_trn();
}

sub reset_trn {
    my $self = shift;
    $self->{TRN} = 0;
}

sub padding {
    my $self = shift;
    return sprintf("%02d", $self->{TRN});
}

sub _init {
    my $self = shift;
    
    $self->reset_trn();
    $self;
}

1;
__END__

=head1 NAME

Net::UCP::TransactionManager - Perl extension to manage UCP session transaction numbers 

=head1 SYNOPSIS

  use Net::UCP::TransactionManager;

=head1 DESCRIPTION

    This module is used by Net::UCP - see Net::UCP Module 

=head2 EXPORT

None

=head1 SEE ALSO
 
  Net::UCP

=head1 AUTHOR

Marco Romano, E<lt>nemux@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Marco Romano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
