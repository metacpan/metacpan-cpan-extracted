package SqlBatch::AbstractPlan;

# ABSTRACT: Abstract class for a plan object 

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Data::Dumper;

sub new {
    my ($class,$config,%defaults)=@_;

    my $self = { 
	%defaults,
	configuration => $config,
    };

    return bless $self, $class;
}

sub configuration {
    my $self = shift;
    return $self->{configuration};
}

sub add_instructions {
    my $self = shift;

    croak "Abstract methode";
}

1;

__END__

=head1 NAME

SqlBatch::AbstractPlan

=head1 DESCRIPTION

This class an abstract class for L<SqlBatch::Plan>

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
