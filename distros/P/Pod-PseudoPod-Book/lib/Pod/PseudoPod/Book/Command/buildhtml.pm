package Pod::PseudoPod::Book::Command::buildhtml;
# ABSTRACT: command module for C<ppbook buildhtml>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use autodie;
use Pod::PseudoPod::DOM::App::ToHTML;
use File::Spec::Functions qw( catfile catdir splitpath );

sub execute
{
    my ($self, $opt, $args) = @_;
    my $is_epub             = grep { /build_xhtml/ } @$args;
    my $suffix              = $is_epub ? 'xhtml' : 'html';
    my @files               = $self->gather_files( $suffix );

    push @files, '--role=epub' if $is_epub;

    Pod::PseudoPod::DOM::App::ToHTML::process_files_with_output( @files );
}

sub gather_files
{
    my ($self, $suffix) = @_;

    my @chapters;

    if (my @order = $self->chapter_order)
    {
        my $build_prefix  = $self->get_build_prefix;
        @chapters         = map { chomp; catfile( $build_prefix, "$_.pod" ) }
                                @order;
    }
    else
    {
        @chapters = $self->get_built_chapters;
    }

    return $self->map_chapters_to_output( $suffix, 'html', @chapters );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::Book::Command::buildhtml - command module for C<ppbook buildhtml>

=head1 VERSION

version 1.20210620.2051

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
