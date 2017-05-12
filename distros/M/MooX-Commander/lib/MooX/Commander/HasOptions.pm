package MooX::Commander::HasOptions;

use Moo::Role;
use Getopt::Long;
use String::CamelSnakeKebab qw/lower_snake_case/;

has argv    => (is => 'lazy');
has options => (is => 'rw', builder => 1);

sub _build_options { [] }

around '_build_options' => sub {
    my $orig = shift;
    my $self = shift;

    my $definitions = $self->$orig;
    my $options;
    my %params;
    $params{'help|h'} = \$options->{help};

    for my $definition (@$definitions) {
        $definition =~ m/^([A-Za-z0-9_\-]+)/;
        die "that didn't work" unless $1;
        my $key = lower_snake_case $1;
        $params{$definition} = \$options->{$1};
    }

    @ARGV = @{ $self->argv };
    Getopt::Long::GetOptions(%params);

    $self->usage if $options->{help};

    return $options;
};

around 'usage' => sub { 
    my $orig = shift;
    my $self = shift;
    my $message = shift;
    print $message . "\n" if $message;
    print $self->$orig(@_);
    exit 1;
};

1;

=encoding utf-8

=head1 NAME

MooX::Commander::HasOptions - Moo role to add options to a subcommand

=head1 SYNOPSIS

    package PieFactory::Cmd::Throw;
    use Moo;
    with 'MooX::Commander::HasOptions';

    # This array is used to configure Getopt::Long
    sub _build_options {(
        'angrily|a',
        'speed|s=i',
    )}

    # This string is printed and the program exits.
    sub usage {
       return <<EOF
    usage: pie-factory throw <pie> <target> [options]

    Throw <pie> at <target>.  Valid values for <pie> are apple pie, rhubarb
    pie, or mud pie.

    OPTIONS
      -a, --angrily  Curse the target after throwing the pie
      -s, --speed    Throw the pie this many mph
      -h, --help     Show this message

    EOF
    }

    sub go {
        my ($self, $pie, $target) = @_;

        # print usage and then exit unsuccessfully
        $self->usage unless $pie && $target;

        # print "Not a valid value for <pie>\n", usage() and exit unsuccessfully
        $self->usage("Not a valid value for <pie>") unless $pie eq 'rhubarb';

        $self->curse_loudly if $self->options->{angrily};
        $self->throw($pie => $target, $self->options->{speed});
    }

=head1 DESCRIPTION

MooX::Commander::HasOptions is a simple Moo::Role thats adds option parsing to
your module.  Be sure to also read L<MooX::Commander>.

It parses values in the $self->argv attribute with L<Getopt::Long>.
Getopt::Long is configured using the return value of _build_options().

If a user asks for help with '--help' or '-h', the usage is shown and
the program exits unsuccessfully.

This module doesn't dynamically generate usage/help statements.  I wasn't
interested in solving that problem.  I think its not possible or very difficult
to do well and usually leads to a very complex and verbose user interface and a
one size fits all usage/help output that is inflexible and poorly formatted.  

I suspect people who really care about the usability of their command line
applications will want to tweak help output based on the situation and their
personal preferences.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

