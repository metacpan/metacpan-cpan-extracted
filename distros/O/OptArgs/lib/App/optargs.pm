package App::optargs;
use strict;
use warnings;
use OptArgs;
use lib 'lib';
our $VERSION = '0.1.20';

$OptArgs::COLOUR = 1;

arg class => (
    isa      => 'Str',
    required => 1,
    comment  => 'OptArgs-based module to load',
);

arg name => (
    isa     => 'Str',
    comment => 'Name of the command',
    default => sub { '<command>' }
);

opt indent => (
    isa     => 'Int',
    comment => 'Number of spaces to indent sub-commands',
    alias   => 'i',
    default => 4,
);

opt spacer => (
    isa     => 'Str',
    comment => 'Character to use for indent spaces',
    default => ' ',
    alias   => 's',
);

opt full => (
    isa     => 'Bool',
    comment => 'Print the full usage messages',
    alias   => 'f',
);

sub run {
    my $opts = shift;

    die $@ unless eval "require $opts->{class};";

    my $initial = do { my @tmp = split( /::/, $opts->{class} ) };
    my $indent = $opts->{spacer} x $opts->{indent};

    binmode( STDOUT, ':encoding(utf8)' );

    foreach my $cmd ( OptArgs::_cmdlist() ) {
        my $length = do { my @tmp = split( /::/, $cmd ) }
          - $initial;
        my $space = $indent x $length;

        unless ( $opts->{full} ) {
            my $usage = OptArgs::_synopsis($cmd);
            $usage =~ s/^usage: \S+/$space$opts->{name}/;
            print $usage;
            next;
        }

        my $usage = OptArgs::_usage($cmd);
        $usage =~ s/^usage: \S+/usage: $opts->{name}/;

        my $n = 79 - length $space;
        print $space, '#' x $n, "\n";
        print $space, "# $cmd\n";
        print $space, '#' x $n, "\n";
        $usage =~ s/^/$space/gm;
        print $usage;
        print $space . "\n";
    }
}

1;

__END__

=head1 NAME

App::optargs - implementation of the optargs(1) command

=head1 VERSION

0.1.20 development release.

=head1 SYNOPSIS

    use OptArgs;
    dispatch(qw/run App::optargs/);

=head1 DESCRIPTION

This is the implementation of the L<optargs>(1) command. It contains a
single function which expects to be called by  C<OptArgs::dispatch()>:

=over

=item run(\%opts)

Run with options as defined by \%opts.

=back

=head1 SEE ALSO

L<OptArgs>

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2012-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

