package Tail::Tool;

# Created on: 2010-10-06 14:15:40
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Tail::Tool::File;

our $VERSION = version->new('0.4.7');

has files => (
    is      => 'rw',
    isa     => 'ArrayRef[Tail::Tool::File]',
    default => sub {[]},
);
has lines => (
    is      => 'rw',
    isa     => 'Int',
    default => 10,
);
has pre_process => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {[]},
    trigger => \&_pre_process_set,
);
has post_process => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {[]},
);
has printer => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_printer',
    #default => sub {
    #    sub { print "Default printer\n", ( ref $_ eq 'ARRAY' ? @$_ : @_ ) };
    #},
);
has last => (
    is  => 'rw',
    isa => 'Tail::Tool::File',
);

around BUILDARGS => sub {
    my ($orig, $class, @params) = @_;
    my %param;

    if ( ref $params[0] eq 'HASH' ) {
        %param = %{ shift @params };
    }
    else {
        %param = @params;
    }

    $param{pre_process}  ||= [];
    $param{post_process} ||= [];

    for my $key ( keys %param ) {
        next if $key eq 'post_process' || $key eq 'pre_process';

        if ( $key eq 'files' ) {
            my @extra = (
                no_inotify => $param{no_inotify},
                restart    => $param{restart},
            );
            for my $file ( @{ $param{$key} } ) {
                $file = Tail::Tool::File->new(
                    ref $file ? $file : ( name => $file, @extra )
                );
            }
        }
        elsif ( $key eq 'lines' || $key eq 'printer' || $key eq 'no_inotify' || $key eq 'restart' ) {
        }
        else {
            my $plg = _new_plugin( $key, $param{$key} );
            delete $param{$key};

            push @{ $param{ ( $plg->post ? 'post' : 'pre' ) . '_process' } }, $plg;
        }
    }

    return $class->$orig(%param);
};

sub _new_plugin {
    my ( $name, $value ) = @_;
    my $plugin = _load_plugin($name);

    my $plg = $plugin->new($value);

    return $plg;
}

sub _load_plugin {
    my ( $name ) = @_;
    my $plugin
        = $name =~ /^\+/
        ? substr $name, 1, 999
        : "Tail::Tool::Plugin::$name";
    my $plugin_file = $plugin;
    $plugin_file =~ s{::}{/}gxms;
    $plugin_file .= '.pm';
    {
        # don't load twice
        no strict qw/refs/; ## no critic
        if ( !${"Tail::Tool::Plugin::${name}::"}{VERSION} ) {
            eval { require $plugin_file };
            if ( $EVAL_ERROR ) {
                confess "Could not load the plugin $name (via $plugin_file)\n";
            }
        }
    }

    return $plugin;
}

sub tail {
    my ( $self, $no_start ) = @_;

    for my $file (@{ $self->files }) {
        next if $file->runner;
        $file->runner( sub { $self->run(@_) } );
        $file->tailer($self);
        $file->watch();
        $file->run() if !$no_start;
    }
}

sub run {
    my ( $self, $file ) = @_;

    my $first = !$file->started;
    my @lines = $file->get_line;

    if ( $first && @lines > $self->lines ) {
        @lines = @lines[ -$self->lines .. -1 ];
    }

    for my $pre ( @{ $self->pre_process } ) {
        my @new;
        if (@lines) {
            for my $line (@lines) {
                push @new, $pre->process($line, $file);
            }
        }
        elsif ( $pre->can('allow_empty') && $pre->allow_empty ) {
            push @new, $pre->process('', $file);
        }
        @lines = @new;
    }
    for my $post ( @{ $self->post_process } ) {
        my @new;
        for my $line (@lines) {
            push @new, $post->process($line, $file);
        }
        @lines = @new;
    }

    if ( @lines ) {
        if ( @{ $self->files } > 1 && ( !$self->last || $file ne $self->last ) ) {
            unshift @lines, "\n==> " . $file->name . " <==\n";
        }
        $self->last($file);
    }

    #warn join "", @lines if @lines;
    if ( $self->has_printer ) {
        my $printer = $self->printer;
        warn "Lines = " . scalar @lines, "\tPrinter " . $printer . "\n";

        $_ = \@lines;
        eval { &{$printer}() };
        warn "Error in printer: " . $@ if $@;
    }
    else {
        $self->default_printer(@lines);
    }

    $file->started(1) if $first;
    return;
}

sub default_printer {
    my ( $self, @lines ) = @_;
    print @lines;
}

sub _pre_process_set {
    my ($self, $pre_process) = @_;
    my @pre = @{ $pre_process };
    my @group;
    my @other;

    # sort (in order) pre process plugins
    for my $pre (@pre) {
        if ( ref $pre eq 'Tail::Tool::Plugin::GroupLines' ) {
            push @group, $pre;
        }
        else {
            push @other, $pre;
        }
    }

    # check that the sorted plugins match the current order
    my $differ = 0;
    for my $new_pre ( @group, @other ) {
        if ( $new_pre != shift @pre ) {
            $differ = 1;
            last;
        }
    }

    # if the orders differ, reset the plugins.
    if ($differ) {
        $self->pre_process([ @group, @other ]);
    }
}

1;

__END__

=head1 NAME

Tail::Tool - Tool for sophisticated tailing of files

=head1 VERSION

This documentation refers to Tail::Tool version 0.4.7.

=head1 SYNOPSIS

   use Tail::Tool;

   # Create a new Tail::Tool object tailing /tmp/test.log
   # with the spacing plugin initialised.
   my $tt = Tail::Tool->new(
       files => [
           '/tmpl/test.log',
       ],
       Spacing => {
           short_time  => 2,
           short_lines => 2,
           long_time   => 5,
           long_lines  => 10,
       },
       ...
   );

   # run the tail
   $tt->tail();

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<tail ()>

Description: Start tailing?

=head2 C<run ($file, $first)>

Param: C<$file> - Tail::Tool::File - The file to run

Param: C<$first> - bool - Specifies that this is the first time run has been
called.

=head2 C<run ( $file )>

Runs the the tailing of C<$file>.

=head2 C<default_printer ( @lines )>

Prints C<@lines> to STDOUT

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
