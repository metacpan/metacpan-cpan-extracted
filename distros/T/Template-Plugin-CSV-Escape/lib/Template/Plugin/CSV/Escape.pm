package Template::Plugin::CSV::Escape;
use strict;
use warnings;
use base qw/Template::Plugin::Filter/;

our $VERSION     = '0.01';
our $FILTER_NAME = 'csv';

sub init {
    my $self = shift;
    $self->install_filter($self->{_ARGS}->[0] || $FILTER_NAME);
    $self;
}

sub filter {
    my ($self, $text) = @_;
    $text =~ s/\x22/\x22\x22/go;
    return qq{"$text"};
}

1;

__END__

=head1 NAME

Template::Plugin::CSV::Escape - CSV escape a string

=head1 SYNOPSIS

 [% USE CSV.Escape -%]
 [% FOR data IN datas -%]
 [% data.name | csv %],[% data.mail | csv %],[% data.address | csv %]
 [% END -%]

=head1 DESCRIPTION

CSV escape a string.

 [% foo = 'bar"baz' %]
 [% foo | csv %] "bar""baz"

=head1 AUTHOR

Ittetsu Miyazaki E<lt>ittetsu.miyazaki __at__ gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>

=cut
