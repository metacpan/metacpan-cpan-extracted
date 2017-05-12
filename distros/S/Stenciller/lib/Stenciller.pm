use 5.10.1;
use strict;
use warnings;

package Stenciller;

our $VERSION = '0.1400'; # VERSION:
# ABSTRACT: Transforms a flat file format to different output

use Moose;
with 'Stenciller::Utils';
use MooseX::AttributeDocumented;
use namespace::autoclean;

use Module::Pluggable search_path => ['Stenciller::Plugin'];
use Module::Load;
use Carp 'croak';
use List::Util qw/any/;
use PerlX::Maybe qw/maybe provided/;
use Types::Standard qw/Maybe Bool ArrayRef Str/;
use Types::Path::Tiny qw/File/;
use Types::Stenciller qw/Stencil/;
use Stenciller::Stencil;

has filepath => (
    is => 'ro',
    isa => File,
    required => 1,
    coerce => 1,
    documentation => 'The textfile to parse.',
);
has is_utf8 => (
    is => 'ro',
    isa => Bool,
    default => 1,
    documentation => 'Determines how the stencil file is read.'
);
has stencils => (
    is => 'ro',
    isa => ArrayRef[Stencil],
    traits => ['Array'],
    default => sub { [ ] },
    documentation => 'After parsing, this contains all parsed stencils.',
    init_arg => undef,
    handles => {
        add_stencil => 'push',
        all_stencils => 'elements',
        get_stencil => 'get',
        count_stencils => 'count',
        has_stencils => 'count',
    },
);
has header_lines => (
    is => 'ro',
    isa => ArrayRef[Str],
    traits => ['Array'],
    default => sub { [] },
    init_arg => undef,
    documentation => 'After parsing, this contains all lines in the header.',
    handles => {
        add_header_line => 'push',
        all_header_lines => 'elements',
    },
);
has skip_if_input_empty => (
    is => 'ro',
    isa => Bool,
    default => 1,
    documentation => 'If a stencil has no input content, skip entire stencil.',
);
has skip_if_output_empty => (
    is => 'ro',
    isa => Bool,
    default => 1,
    documentation => 'If a stencil has no output content, skip entire stencil.',
);

around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;
    my @args = @_;

    if(scalar @args == 1 && ref $args[0] eq 'HASH') {
        $class->$next(%{ $args[0] });
    }
    else {
        $class->$next(@args);
    }
};

sub BUILD {
    shift->parse;
}
around has_stencils => sub {
    my $next = shift;
    my $self = shift;

    my $count = $self->$next;
    return !!$count || 0;
};

# Str :$plugin_name!          does doc('Plugin that will generate output.'),
# HashRef :$constructor_args? does doc('Constructor arguments for the plugin.')     = {},
# HashRef :$transform_args?   does doc('Settings for the specific transformation.') = {}, ...
# --> Str     but assumed     does doc('The transformed content.')
sub transform {
    my $self = shift;
    my %args = @_;

    my $plugin_name = $args{'plugin_name'} || carp('plugin_name is a mandatory key in the call to transform()');
    my $constructor_args = $args{'constructor_args'} || {};
    my $transform_args = $args{'transform_args'} || {};

    my $plugin_class = "Stenciller::Plugin::$plugin_name";
    Module::Load::load($plugin_class);
    die sprintf "Can't load %s: %s", $plugin_class, $@ if $@;

    if(!$plugin_class->does('Stenciller::Transformer')) {
        croak("[$plugin_name] doesn't do the Stenciller::Transformer role. Quitting.");
    }
    return $plugin_class->new(stenciller => $self, %{ $constructor_args })->transform($transform_args);
}

sub parse {
    my $self = shift;
    my @contents = split /\v/ => $self->is_utf8 ? $self->filepath->slurp_utf8 : $self->filepath->slurp;

    my $stencil_start = qr/^== +stencil +(\{.*\} +)?==$/;
    my $input_start = qr/^--+input--+$/;
    my $input_end = qr/^--+end input--+$/;
    my $output_start = qr/^--+output--+$/;
    my $output_end = qr/^--+end output--+$/;

    my $environment = 'header';
    my $line_count = 0;

    my $stencil = undef;

    LINE:
    foreach my $line (@contents) {
        ++$line_count if $environment ne 'next_stencil'; # because then we are redo-ing the line

        if(any { $environment eq $_ } (qw/header next_stencil/)) {
            $self->add_header_line($line) and next LINE if $line !~ $stencil_start;

            my $possible_hash = $1;
            my $settings = defined $possible_hash && $possible_hash =~ m{\{.*\}}
                         ? $self->eval_to_hashref($possible_hash, $self->filepath)
                         : {}
                         ;

            my $stencil_name = exists $settings->{'name'} ? delete $settings->{'name'} : $self->filepath->basename(qr/\..*/) . "-$line_count";
            $stencil_name =~ s{[. -]}{_}g;
            $stencil_name =~ s{[^a-zA-Z0-9_]}{}g;

            $stencil = Stenciller::Stencil->new(
                        stencil_name => $stencil_name,
                        loop_values => delete $settings->{'loop'},
                        line_number => $line_count,
                  maybe skip  => delete $settings->{'skip'},
               provided scalar keys %{ $settings }, extra_settings => $settings,
            );
            $environment = 'before_input';
        }
        elsif($environment eq 'before_input') {
            $stencil->add_before_input($line) and next LINE if $line !~ $input_start;
            $environment = 'input';
        }
        elsif($environment eq 'input') {
            $stencil->add_input($line) and next LINE if $line !~ $input_end;
            $environment = 'between';
        }
        elsif($environment eq 'between') {
            $stencil->add_between($line) and next LINE if $line !~ $output_start;
            $environment = 'output';
        }
        elsif($environment eq 'output') {
            $stencil->add_output($line) and next LINE if $line !~ $output_end;
            $environment = 'after_output';
        }
        elsif($environment eq 'after_output') {
            $stencil->add_after_output($line) and next LINE if $line !~ $stencil_start;
            $self->handle_completed_stencil($stencil);
            $environment = 'next_stencil';
            redo LINE;
        }
    }
    if($environment ne 'after_output') {
        croak (sprintf 'File <%s> appears malformed. Ended on <%s>', $self->filepath, $environment);
    }
    $self->handle_completed_stencil($stencil);
}

sub handle_completed_stencil {
    my $self = shift;
    my $stencil = shift;

    return if !Stencil->check($stencil);
    return if $stencil->skip;
    return if !$stencil->has_input  && $self->skip_if_input_empty;
    return if !$stencil->has_output && $self->skip_if_output_empty;

    if(!$stencil->has_loop_values) {
        $self->add_stencil($stencil);
        return;
    }

    foreach my $loop_value ($stencil->all_loop_values) {
        my $clone = $stencil->clone_with_loop_value($loop_value);
        $self->add_stencil($clone);
    }
}

sub max_stencil_index {
    return shift->count_stencils - 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stenciller - Transforms a flat file format to different output



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg" alt="Requires Perl 5.10.1+" /> <a href="https://travis-ci.org/Csson/p5-Stenciller"><img src="https://api.travis-ci.org/Csson/p5-Stenciller.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-90.0%-yellow.svg" alt="coverage 90.0%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Stenciller.svg?branch=master)](https://travis-ci.org/Csson/p5-Stenciller) ![coverage 90.0%](https://img.shields.io/badge/coverage-90.0%-yellow.svg)

=end markdown

=head1 VERSION

Version 0.1400, released 2016-02-03.



=head1 SYNOPSIS

    use Stenciller;
    my $stenciller = Stenciller->new(filepath => 't/corpus/test-1.stencil');
    my $content = $stenciller->transform(plugin_name => 'ToUnparsedText');

=head1 DESCRIPTION

Stenciller reads a special fileformat and provides a way to convert the content into different types of output. For example, it can be used to create documentation and tests from the same source file.

=head2 File format

    == stencil {} ==

    --input--

    --end input--

    --output--

    --end output--

This is the basic layout. A stencil ends when a new stencil block is discovered (there is no fixed limit to the number of stencils in a file). The (optional) hash is for settings. Each stencil has five parts: C<before_input>, C<input>, C<between>, C<output> and C<after_output>. In addition to this
there is a header before the first stencil.

=head1 ATTRIBUTES


=head2 filepath

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#File">File</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The textfile to parse.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#File">File</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">required</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The textfile to parse.</p>

=end markdown

=head2 is_utf8

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Determines how the stencil file is read.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Determines how the stencil file is read.</p>

=end markdown

=head2 skip_if_input_empty

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If a stencil has no input content, skip entire stencil.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If a stencil has no input content, skip entire stencil.</p>

=end markdown

=head2 skip_if_output_empty

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If a stencil has no output content, skip entire stencil.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>If a stencil has no output content, skip entire stencil.</p>

=end markdown

=head2 header_lines

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>After parsing, this contains all lines in the header.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>After parsing, this contains all lines in the header.</p>

=end markdown

=head2 stencils

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Stenciller#Stencil">Stencil</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>After parsing, this contains all parsed stencils.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Stenciller#Stencil">Stencil</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">not in constructor</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>After parsing, this contains all parsed stencils.</p>

=end markdown

=head1 METHODS

=head2 transform

    $stenciller->transform(
        plugin_name => 'ToUnparsedText',
        constructor_args => {
            plugin_specific_args => ...,
        },
        tranform_args => {
            transformation_specific_args => ...,
        },
    );

C<plugin_name> is mandatory and should be a class under the C<Stenciller::Plugin> namespace.

C<constructor_args> is optional. This hash reference will be passed on to the plugin constructor. Valid keys depends on the plugin.

C<transform_args> is optional. This hash reference will be passed on to the C<transform> method in the plugin. Valid keys depends on the plugin.

=head1 PLUGINS

The actual transforming is done by plugins. There are two plugins bundled in this distribution:

=over 4

=item *

L<Stenciller::Plugin::ToUnparsedText>

=item *

L<Stenciller::Plugin::ToHtmlPreBlock>

=item *

L<Pod::Elemental::Transformer::Stenciller>

=back

Custom plugins should be in the L<Stenciller::Plugin> namespace and consume the L<Stenciller::Transformer> role.

=head1 SOURCE

L<https://github.com/Csson/p5-Stenciller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Stenciller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
