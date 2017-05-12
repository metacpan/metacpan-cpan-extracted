package Pipe::Tube::Csv;
use strict;
use warnings;

our $VERSION = '0.04';

use base 'Pipe::Tube';
use Text::CSV;
use Data::Dumper;


sub init {
    my ($self, $attr) = @_;
    die "First paramater of csv should be HASH reference or nothing" if $attr and ref $attr ne 'HASH';
	$attr ||= {};

    $self->logger("Receiving Csv definition: " . Dumper $attr);

    $self->{csv} = Text::CSV->new($attr);

    return $self;
}

sub run {
    my ($self, @input) = @_;

    my @resp;
    foreach my $line (@input) {
      $self->{csv}->parse($line);
      push @resp, [ $self->{csv}->fields ];
    }
    return @resp;
}

1;

__END__

=head1 NAME

Pipe::Tube::Csv - Csv processor tube in Pipe

=head1 SYNPOSIS

  my @resp = Pipe->for(@rows)->csv->run;

  my @resp = Pipe->cat("t/data/file1", "t/data/file2")
            ->csv({ sep_char => "\t" })
            ->run;

=head1 DESCRIPTION

The ->csv()  call can get a HASH reference parameter, the same parameter as
L<Text::CSV> would get. We pass it directly to that module.

Split up lines of csv file and return an array reference for each line.

TODO: use the first row as key names and on every other row return a hash of the values
 using the above header


=head1 AUTHOR

Gabor Szabo <gabor@szabgab.com>

=head1 COPYRIGHT

Copyright 2006-2012 by Gabor Szabo <gabor@szabgab.com>.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 See Also

L<Pipe> and L<Text::CSV>


=cut


