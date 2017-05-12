package PPI::Document;
use strict;
use warnings;

sub index_line_to_sub {
    my $self = shift;
    $self->index_locations;

    my $package = 'main';
    my $sub     = 'main';

    my @lines;

    foreach my $token ( $self->tokens ) {

        my ( $line, $rowchar, $col ) = @{ $token->location };
        my $statement = $token->statement;

        $lines[$line] = [ $package, $sub ];
        next unless $statement;
        if ( $statement->class eq 'PPI::Statement::Sub' ) {
            $sub = $statement->name;
        } elsif ( $statement->class eq 'PPI::Statement::Package' ) {
            $package = $statement->namespace;
            $sub     = 'main';
        }

        $lines[$line] = [ $package, $sub ];
    }
    $self->{__line_to_sub} = \@lines;
}

sub line_to_sub {
    my ( $self, $line ) = @_;
    my $lines = $self->{__line_to_sub};
    return ( undef, undef ) unless $lines->[$line];

    my ( $package, $sub ) = @{ $lines->[$line] };

    return ( $package, $sub );
}

package PPIx::LineToSub;
use strict;
use warnings;
use PPI;
our $VERSION = '0.33';

1;

__END__

=head1 NAME

PPIx::LineToSub - Find the package and subroutine by line

=head1 SYNOPSIS

  use PPIx::LineToSub;
  my $document = PPI::Document->new('t/hello.pl');
  $document->index_line_to_sub;

  my($package, $sub) = $document->line_to_sub(1);

=head1 DESCRIPTION

L<PPIx::LineToSub> is a module which, given a Perl file and a line
number, will return the package and sub in effect.

=head1 SEE ALSO

L<PPI>.

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.



