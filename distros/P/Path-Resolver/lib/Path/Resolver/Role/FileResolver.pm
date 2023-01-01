package Path::Resolver::Role::FileResolver 3.100455;
# ABSTRACT: a resolver that natively finds absolute file paths
use Moose::Role;
with 'Path::Resolver::Role::Resolver' => { -excludes => 'default_converter' };

use autodie;
use namespace::autoclean;

use Path::Resolver::SimpleEntity;
use Path::Resolver::Types qw(AbsFilePath);
use Path::Resolver::CustomConverter;

use MooseX::Types;

#pod =head1 SYNOPSIS
#pod
#pod The FileResolver role is a specialized form of the Resolver role, and can be
#pod used in its place.  (Anything that does the FileResolver role automatically
#pod does the Resolver role, too.)
#pod
#pod FileResolver classes have a native type of Path::Resolver::Types::AbsFilePath
#pod (from L<Path::Resolver::Types>).  Basically, they will natively return a
#pod Path::Class::File pointing to an absolute file path.
#pod
#pod FileResolver classes also have a default converter that will convert the
#pod AbsFilePath to a L<Path::Resolver::SimpleEntity>, meaning that by default a
#pod FileResolver's C<entity_at> will return a SimpleEntity.  This entity will be
#pod constructed by reading the file B<in raw mode>.  In other words, it is the
#pod byte string contents of the file, not any decoded character string.  If you
#pod want to a Unicode string of a file's contents, you must decode it yourself.
#pod
#pod =cut

sub native_type { AbsFilePath }

my $converter = Path::Resolver::CustomConverter->new({
  input_type  => AbsFilePath,
  output_type => class_type('Path::Resolver::SimpleEntity'),
  converter   => sub {
    my ($converter, $abs_path) = @_;

    open my $fh, '<:raw', "$abs_path";
    my $content = do { local $/; <$fh> };
    Path::Resolver::SimpleEntity->new({ content_ref => \$content });
  },
});

sub default_converter { $converter }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::Role::FileResolver - a resolver that natively finds absolute file paths

=head1 VERSION

version 3.100455

=head1 SYNOPSIS

The FileResolver role is a specialized form of the Resolver role, and can be
used in its place.  (Anything that does the FileResolver role automatically
does the Resolver role, too.)

FileResolver classes have a native type of Path::Resolver::Types::AbsFilePath
(from L<Path::Resolver::Types>).  Basically, they will natively return a
Path::Class::File pointing to an absolute file path.

FileResolver classes also have a default converter that will convert the
AbsFilePath to a L<Path::Resolver::SimpleEntity>, meaning that by default a
FileResolver's C<entity_at> will return a SimpleEntity.  This entity will be
constructed by reading the file B<in raw mode>.  In other words, it is the
byte string contents of the file, not any decoded character string.  If you
want to a Unicode string of a file's contents, you must decode it yourself.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
