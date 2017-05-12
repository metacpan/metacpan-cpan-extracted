package Poet::Util::File;
$Poet::Util::File::VERSION = '0.16';
use File::Basename qw(basename dirname);
use File::Path qw();
use File::Slurp qw(read_dir read_file write_file);
use File::Spec::Functions qw(abs2rel canonpath catdir catfile rel2abs);
use List::MoreUtils qw(uniq);
use strict;
use warnings;
use base qw(Exporter);

File::Path->import( @File::Path::EXPORT, @File::Path::EXPORT_OK );

our @EXPORT_OK =
  uniq( qw(abs2rel basename canonpath catdir catfile dirname read_file rel2abs write_file),
    @File::Path::EXPORT, @File::Path::EXPORT_OK );
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

1;

__END__

=pod

=head1 NAME

Poet::Util::File - File utilities

=head1 SYNOPSIS

    # In a script...
    use Poet::Script qw(:file);

    # In a module...
    use Poet qw(:file);

    # In a component...
    <%class>
    use Poet qw(:file);
    </%class>

=head1 DESCRIPTION

This group of utilities includes

=over

=item basename, dirname

From L<File::Basename|File::Basename>.

=item mkpath, make_path, rmtree, remove_tree

From L<File::Path|File::Path>.

=item read_file, write_file, read_dir

From L<File::Slurp|File::Slurp>.

=item abs2rel canonpath catdir catfile rel2abs

From L<File::Spec::Functions|File::Spec::Functions>.

=back

=head1 SEE ALSO

L<Poet|Poet>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
