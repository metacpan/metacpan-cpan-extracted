package OpenGL::Sandbox::MMap;
BEGIN { $OpenGL::Sandbox::MMap::VERSION = '0.03'; }
use strict;
use warnings;
use File::Map 'map_file';

# ABSTRACT: Wrapper around a memory-mapped scalar ref


sub size { length(${(shift)}) }

sub new {
	my ($class, $fname)= @_;
	my $map;
	my $self= bless \$map, $class;
	map_file $map, $fname;
	$self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGL::Sandbox::MMap - Wrapper around a memory-mapped scalar ref

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  my $mmap= OpenGL::Sandbox::MMap->new("Filename.ttf");

=head1 DESCRIPTION

This is a simple wrapper around File::Map to make it more convenient to open
read-only memory-mapped files, and to make sure they are distinctly held as
references and not accidentally copied into perl scalars.

=head1 ATTRIBUTES

=head2 size

Number of bytes mapped from file.  Same as C<length($$mmap)>

=head1 METHODS

=head2 new

  my $mmap= OpenGL::Sandbox::MMap->new($filename);

Return a blessed reference to a scalar which points to memory-mapped data.
C<$filename> is always opened read-only.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
