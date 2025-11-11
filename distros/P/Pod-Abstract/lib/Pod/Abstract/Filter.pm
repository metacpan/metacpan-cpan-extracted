package Pod::Abstract::Filter;
use strict;
use warnings;

use Pod::Abstract;

use Module::Pluggable require => 1, search_path => ['Pod::Abstract::Filter'];

our $VERSION = '0.26';

=head1 NAME

Pod::Abstract::Filter - Generic Pod-in to Pod-out filter.

=head1 DESCRIPTION

This is a superclass for filter modules using
Pod::Abstract. Subclasses should override the C<filter>
sub. Pod::Abstract::Filter classes in the Pod::Abstract::Filter
namespace will be used by the C<paf> utility.

To create a filter, you need to implement:

=over

=item filter

Takes a Pod::Abstract::Node tree, and returns either another tree, or
a string. If a string is returned, it will be re-parsed to be input to
any following filter, or output directly if it is the last filter in
the list.

It is recommended your filter method produce a Node tree if you are able
to, as this will improve interoperability with other C<Pod::Abstract>
based software.

=item require_params

If you want positional arguments following your filter in the style of:

 paf find [thing] Pod::Abstract

then override require_params to list the named arguments that are to
be accepted after the filter name.

=back

=head1 METHODS

=head2 new

Create a new filter with the specified arguments.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    return bless { %args }, $class;
}

=head2 plugins_info

 my $info = Pod::Abstract::Filter->plugins_info;

Gets information for each paf command/plugin.

=cut

sub plugins_info {
    my $class = shift;

    my @plugins = $class->plugins;
    my $info = {};
    foreach my $p (@plugins) {
        $p =~ m/^Pod::Abstract::Filter::(.*)$/;
        my $cmd = $1;

        $info->{$cmd} = {
            class => $p,
            command => $cmd,
            summary => $class->summarise( $p ),
        };
    }

    return $info;
}

sub summarise {
    my $class = shift;
    my $mod = shift;
    
    $mod =~ s/::/\//g;
    $mod .= '.pm';
    my $filepath = '';
    foreach my $path (@INC) {
        if(-r "$path/$mod") {
            $filepath = "$path/$mod";
            last;
        }
    }

    my $pa = Pod::Abstract->load_file($filepath);
    my @texts = $pa->select('/head1[@heading eq \'NAME\']/:paragraph');
    return [] unless @texts;
    
    my $pt = join '', map { $_->pod } @texts;
    $pt =~ s/^Pod::Abstract::Filter:://;
    my ($command, $rest) = split / - /, $pt, 2;
    return [ ] unless $command && $rest; # Never mind if the module doesn't follow standard

    $rest =~ s/[\r\n]//g;


    # Reflow to max 72 chars.
    my $out = '';
    while( $rest ) {
        if( length $rest <= 72 ) {
            $out .= '    '.$rest;
            $rest = '';
        } else {
            my $i = 72;
            while( substr($rest, $i, 1) !~ /^\s$/ && $i > 0 ) {
                $i --;
            }
            if( $i == 0 ) {
                # Give up and finish the string.
                $out .= '    '.$rest;
            } else {
                $out .= '    '.substr( $rest, 0, $i, '')."\n";
                $rest =~ s/^\s*//;
            }
        }

    }

    return [ $command, $out ];
}

=head2 require_params

Override to return a list of parameters that must be provided. This
will be accepted in order on the command line, unless they are first
set using the C<-flag=xxx> notation.

=cut

sub require_params {
    return ( );
}

=head2 param

Get the named param. Read only.

=cut

sub param {
    my $self = shift;
    my $param_name = shift;
    return $self->{$param_name};
}

=head2 filter

Stub method. Does nothing, just returns the original tree.

=cut

sub filter {
    my $self = shift;
    my $pa = shift;
    
    return $pa;
}

=head2 run

Run the filter. If $arg is a string, it will be parsed
first. Otherwise, the Abstract tree will be used. Returns either a
string or an abstract tree (which may be the original tree, modified).

=cut

sub run {
    my $self = shift;
    my $arg = shift;
    
    if( eval { $arg->isa( 'Pod::Abstract::Node' ) } ) {
        return $self->filter($arg);
    } else {
        my $pa = Pod::Abstract->load_string($arg);
        return $self->filter($pa);
    }
}

=head1 AUTHOR

Ben Lilburne <bnej80@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2025 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
