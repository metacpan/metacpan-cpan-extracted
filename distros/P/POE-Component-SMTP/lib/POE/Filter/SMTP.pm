package POE::Filter::SMTP;
#
# $Revision: 1.2 $
# $Id: SMTP.pm,v 1.2 2004/06/29 15:39:18 cwest Exp $
#
use strict;
$^W = 1; # At least for development.

use base qw[POE::Filter::Line];

use vars qw[$VERSION];
$VERSION = (qw$Revision: 1.2 $)[1];

use constant CRLF => qq[\x0D\x0A]; # RFC 2821, 2.3.7

sub new {
    my ($class) = @_;
    
    return $class->SUPER::new( Literal => CRLF );
}

sub get_one {
    my ($self) = shift;

    my $lines = $self->SUPER::get_one( @_ );

    foreach my $line ( @{$lines} ) {
        my ($command, $data) = split /\s+/, $line, 2;
        $data =~ s/\s+$// if $data;
        $line = [ uc( $command ), $data ];
    }
    
    return $lines;
}

sub put {
    my ($self, $lines) = @_;

    my $code = shift @{$lines};
    return $self->SUPER::put( [ "$code @{$lines}" ] )
      if @{$lines} == 1;

    my @output;    
    push @output, "$code-$lines->[$_]"
      foreach 0 .. $#{$lines} - 1;
    push @output, "$code $lines->[-1]";
    
    return $self->SUPER::put( \@output );
}

1;

__END__

=pod

=head1 NAME

POE::Filter::SMTP - SMTP Protocol Filter

=head1 SYNOPSIS

  use POE::Filter::SMTP;

=head1 DESCRIPTION

POE::Fitler::SMTP fitlers input and output and splits command and arguments,
as well as return codes and return strings.  It is a sub class of
L<POE::Filter::Line|POE::Filter::Line>.

=head1 BUGS

No doubt.

See http://rt.cpan.org to report bugs.

=head1 AUTHOR

Casey West <casey@geeknest.com>

=head1 COPYRIGHT

Copyright (c) 2003 Casey West.  All rights reserved.  This program 
is free software; you can redistribute it and/or modify it under the same 
terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<POE::Component::Server::SMTP>, L<POE>.

=cut

