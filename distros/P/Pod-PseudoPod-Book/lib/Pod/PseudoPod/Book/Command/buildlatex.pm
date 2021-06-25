package Pod::PseudoPod::Book::Command::buildlatex;
# ABSTRACT: command module for C<ppbook buildlatex>

use parent 'Pod::PseudoPod::Book::Command';

use strict;
use warnings;

use autodie;
use Path::Class;
use File::Basename;
use Pod::PseudoPod::DOM::App::ToLaTeX;

sub execute
{
    my ($self, $opt, $args) = @_;

    Pod::PseudoPod::DOM::App::ToLaTeX::process_files_with_output(
        $self->map_chapters_to_output( 'tex', 'latex',
            $self->get_built_chapters
        )
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::Book::Command::buildlatex - command module for C<ppbook buildlatex>

=head1 VERSION

version 1.20210620.2051

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
