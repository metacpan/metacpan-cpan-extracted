package Template::Plugin::CSV;
use strict;
use base qw(Template::Plugin);
use Template::Plugin;
use Text::CSV;

our $VERSION = '0.04';

sub new {
    my ($class, $context) = @_;
    my $csv = Text::CSV->new();
    bless {
        csv => $csv,
        _CONTEXT => $context
    }, $class;
}

sub dump {
    my $self = shift;
    my $array = shift;
    $self->{csv}->combine(@$array);
    return $self->{csv}->string;
}

sub dump_values {
    my $self = shift;
    my $h = shift;
    my @values = values %$h;
    $self->{csv}->combine(@values);
    return $self->{csv}->string;
}

1;

=head1 NAME

Template::Plugin::CSV - Plugin for generating CSV

=head1 SYNOPSIS

    [% USE CSV %]

    [% CSV.dump(list_var) %]
    [% CSV.dump_values(hash_var) %]

=head1 DESCRIPTION

This is a very simple TT2 Plugin for generating CSV. A CSV object
will be instantiated via the following directive:

    [% USE CSV %]

=head1 METHODS

There are two methods supported by the CSV object.  Each will
output a comma-sepeated line.

=head2 dump()

Given a list and dump a comma-sepearted line of its elements.

=head2 dump_values()

Given a hash and dump a comma-sepearte lines of its values.

=head2 new()

A Template::Plugin constructor.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 Kang-min Liu, All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Dumper|Template::Plugin::Dumper>, L<Text::CSV|Text::CSV>
