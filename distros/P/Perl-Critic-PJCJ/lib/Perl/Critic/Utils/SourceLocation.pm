package Perl::Critic::Utils::SourceLocation v0.1.4;

use v5.26.0;
use strict;
use warnings;
use feature      qw( signatures );
use experimental qw( signatures );

use parent qw( PPI::Element );

# This is NOT a Perl::Critic policy - it's a helper class
sub is_policy { 0 }

sub new ($class, %args) {
  bless {
    line_number   => $args{line_number},
    column_number => $args{column_number} // 1,
    content       => $args{content}       // "",
    filename      => $args{filename},
    },
    $class
}

# CRITICAL: This is what Perl::Critic::Violation actually calls
sub location ($self) {
  my $line = $self->{line_number};
  my $col  = $self->{column_number};
  [ $line, $col, $col, $line, $self->{filename} ]
}

# Standard PPI::Element interface
sub line_number          ($self) { $self->{line_number} }
sub column_number        ($self) { $self->{column_number} }
sub logical_line_number  ($self) { $self->{line_number} }
sub visual_column_number ($self) { $self->{column_number} }
sub logical_filename     ($self) { $self->{filename} }
sub content              ($self) { $self->{content} }
sub filename             ($self) { $self->{filename} }

# Support for filename extraction by violation system
# Return self as the "document"
sub top ($self) { $self }

"
She sent him scented letters
And he received them with a strange delight
"

__END__

=pod

=head1 NAME

Perl::Critic::Utils::SourceLocation - Synthetic PPI element

=head1 VERSION

version v0.1.4

=head1 SYNOPSIS

  # Used internally by ProhibitLongLines policy
  my $location = SourceLocation->new(
    line_number => 42,
    content     => "long line content"
  );

=head1 DESCRIPTION

This is a synthetic PPI element used by ProhibitLongLines policy to provide
accurate line number reporting when no real PPI token exists on a line (such as
within POD blocks).

=head1 METHODS

=head2 new

  my $location = Perl::Critic::Utils::SourceLocation->new(
    line_number   => 42,
    column_number => 1,
    content       => "line content",
    filename      => "file.pl"
  );

Creates a new SourceLocation object. Parameters:

=over 4

=item * line_number (required) - The line number in the source file

=item * column_number (optional) - The column number, defaults to 1

=item * content (optional) - The content of the line, defaults to empty string

=item * filename (optional) - The filename, can be undef

=back

=head2 is_policy

  my $is_policy = $location->is_policy;  # Always returns 0

Returns false to indicate this is not a Perl::Critic policy.

=head2 filename

  my $filename = $location->filename;

Returns the filename associated with this location, or undef if none was set.

=head1 AUTHOR

Paul Johnson C<< <paul@pjcj.net> >>

=head1 COPYRIGHT

Copyright 2025 Paul Johnson.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
