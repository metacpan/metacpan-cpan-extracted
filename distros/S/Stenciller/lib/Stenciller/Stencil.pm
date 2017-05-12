use 5.10.1;
use strict;
use warnings;

package Stenciller::Stencil;

use Moose;
use MooseX::AttributeDocumented;
use namespace::autoclean;

use Types::Standard qw/ArrayRef CodeRef HashRef Str Bool Int/;

our $VERSION = '0.1400'; # VERSION:
# ABSTRACT: One part of a file

my @attrs = qw/before_input input between output after_output/;

my $order = 1;
foreach my $attr (@attrs) {
    has $attr => (
        is => 'ro',
        isa => ArrayRef[Str],
        default => sub { [] },
        traits => ['Array'],
        #init_arg => undef,
        documentation_order => ++$order,
        documentation => sprintf ('Holds all lines of the %s section.', $attr),
        handles => {
            "has_$attr"    => 'count',
            "add_$attr"    => 'push',
            "all_$attr"    => 'elements',
            "map_$attr"    => 'map',
            "get_$attr"    => 'get',
            "count_$attr"  => 'count',
        },
    );
}
has skip => (
    is => 'ro',
    isa => Bool,
    default => 0,
    documentation => 'Should the Stencil not be included in the result?',
);
has line_number => (
    is => 'ro',
    isa => Int,
    documentation => 'Can be referenced in the output for easier backtracking.',
);
has stencil_name => (
    is => 'ro',
    isa => Str,
    documentation => q{Can be given in the stencil hash with 'name'. Depends on used plugins if it is necessary/useful.},
    documentation_default => '[filename]_[linenumber]',
);
has extra_settings => (
    is => 'ro',
    isa => HashRef,
    default => sub { { } },
    traits => ['Hash'],
    documentation => 'Any extra key-value pairs in the stencil header.',
    handles => {
        get_extra_setting => 'get',
        set_extra_setting => 'set',
        keys_extra_settings => 'keys',
    },
);
has loop_values => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    traits => ['Array'],
    documentation_order => 0,
    handles => {
        has_loop_values => 'count',
        add_loop_value => 'get',
        all_loop_values => 'elements',
    },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my @args = @_;

    my %args = @args;
    $args{'loop_values'} = [] if !defined $args{'loop_values'};

    return $class->$orig(%args);
};

# Remove all empty lines for each group until we have a line with content, then keep everything
around add_before_input => sub {
    my $orig = shift;
    my $self = shift;
    my $text = shift;
    return $self->ensure_content($orig, $self->has_before_input, $text);
};
around add_input => sub {
    my $orig = shift;
    my $self = shift;
    my $text = shift;
    return $self->ensure_content($orig, $self->has_input, $text);
};
around add_between => sub {
    my $orig = shift;
    my $self = shift;
    my $text = shift;
    return $self->ensure_content($orig, $self->has_between, $text);
};
around add_output => sub {
    my $orig = shift;
    my $self = shift;
    my $text = shift;
    return $self->ensure_content($orig, $self->has_output, $text);
};
around add_after_output => sub {
    my $orig = shift;
    my $self = shift;
    my $text = shift;
    return $self->ensure_content($orig, $self->has_after_output, $text);
};
sub ensure_content {
    my $self = shift;
    my $orig = shift; # CodeRef
    my $already_have = shift; # Bool
    my $text = shift;

    $self->$orig($text) if $already_have || $text !~ m{^\s*$};
    return $self;
}

sub clone_with_loop_value {
    my $self = shift;
    my $loop_value = shift;

    my $clone = Stenciller::Stencil->new(
        before_input => [$self->map_before_input( sub { my $text = $_; $text =~ s{ \[ var \] }{$loop_value}x; $text })],
               input => [$self->map_input( sub { my $text = $_; $text =~ s{ \[ var \] }{$loop_value}x; $text })],
             between => [$self->map_between( sub { my $text = $_; $text =~ s{ \[ var \] }{$loop_value}x; $text })],
              output => [$self->map_output( sub { my $text = $_; $text =~ s{ \[ var \] }{$loop_value}x; $text })],
        after_output => [$self->map_after_output( sub { my $text = $_; $text =~ s{ \[ var \] }{$loop_value}x; $text })],
        stencil_name => $self->stencil_name . "_$loop_value",
        (map { $_ => $self->$_ } qw/line_number extra_settings/)
    );

    return $clone;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stenciller::Stencil - One part of a file

=head1 VERSION

Version 0.1400, released 2016-02-03.



=head1 SYNOPSIS

    # In a plugin (this is pretty similar to what ToUnparsedText does)
    sub render {
        my $self = shift;
        my @out = ();

        STENCIL:
        foreach my $stencil ($self->stenciller->all_stencils) {
            push @out => join "\n" => $stencil->all_before_input;
            push @out => join "\n" => $stencil->all_input;
            push @out => join "\n" => $stencil->all_between;
            push @out => join "\n" => $stencil->all_output;
            push @out => join "\n" => $stencil->all_after_output;
        }
        return join "\n" => @out;
    }

=head1 DESCRIPTION

A C<Stencil> is one section of the file format defined in L<Stenciller>.

=head1 ATTRIBUTES


=head2 before_input

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the before_input section.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the before_input section.</p>

=end markdown

=head2 input

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the input section.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the input section.</p>

=end markdown

=head2 between

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the between section.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the between section.</p>

=end markdown

=head2 output

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the output section.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the output section.</p>

=end markdown

=head2 after_output

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the after_output section.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Holds all lines of the after_output section.</p>

=end markdown

=head2 extra_settings

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#HashRef">HashRef</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Any extra key-value pairs in the stencil header.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#HashRef">HashRef</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default is a <code>coderef</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Any extra key-value pairs in the stencil header.</p>

=end markdown

=head2 line_number

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Can be referenced in the output for easier backtracking.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Can be referenced in the output for easier backtracking.</p>

=end markdown

=head2 skip

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Should the Stencil not be included in the result?</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Should the Stencil not be included in the result?</p>

=end markdown

=head2 stencil_name

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Can be given in the stencil hash with 'name'. Depends on used plugins if it is necessary/useful.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Can be given in the stencil hash with 'name'. Depends on used plugins if it is necessary/useful.</p>

=end markdown

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
