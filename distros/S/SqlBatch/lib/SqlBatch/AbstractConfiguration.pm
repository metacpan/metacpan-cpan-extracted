package SqlBatch::AbstractConfiguration;

# ABSTRACT: Abstract configuration object

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;

sub new {
    my ($class, %overrides)=@_;

    my $self = {
	overrides => \%overrides,
    };

    $self = bless $self, $class;

    return $self;    
}

sub verbosity {
    my $self = shift;
    return $self->item('verbosity') // 0;
}

sub item {
    my $self = shift;
    my $name = shift;

    return $self->{overrides}->{$name};
}

1;

__END__

=head1 NAME

SqlBatch::AbstractConfiguration

=head1 DESCRIPTION

A minimalistic configuration baseclass 

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
