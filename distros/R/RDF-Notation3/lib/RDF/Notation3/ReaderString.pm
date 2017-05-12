use strict;
use warnings;

package RDF::Notation3::ReaderString;

require 5.005_62;
use RDF::Notation3::Template::TReader;

############################################################

@RDF::Notation3::ReaderString::ISA = qw(RDF::Notation3::Template::TReader);

sub new {
    my ($class, $str) = @_;
    my @lines = split /\n|\r|\n\r/, $str;

    my $self = {
                lines => \@lines,
                tokens => [],
                ln => 0,
               };

    bless $self, $class;
    return $self;
}

sub _new_line {
    my ($self, $dont_modify) = @_;

    my $line = '';

    until ($line) {
        $line = shift @{$self->{lines}};
        $self->{ln}++;

        unless ($dont_modify or !$line) {
            $line =~ s/^\s*(.*)$/$1/;
            $line =~ s/^(\#.*)$//;
        }
        last unless (scalar @{$self->{lines}});
    }
    return $line;
}


1;

__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::ReaderString - RDF Notation3 string reader

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut

