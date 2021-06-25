package Pod::PseudoPod::DOM::App::ToHTML;
# ABSTRACT: helper functions for bin/ppdom2html

use strict;
use warnings;
use autodie;

use Pod::PseudoPod::DOM;
use Pod::PseudoPod::DOM::Corpus;

use Pod::PseudoPod::DOM::App qw( open_fh );

sub process_files_with_output
{
    my ($role, @files) = process_args( @_ );
    my @docs;
    my %anchors;
    my $corpus = Pod::PseudoPod::DOM::Corpus->new;

    for my $file (@files)
    {
        my ($source, $output) = @$file;

        my $parser = Pod::PseudoPod::DOM->new(
            formatter_role => $role,
            formatter_args => { add_body_tags => 1, anchors => \%anchors },
            filename       => $output,
        );

        my $HTMLOUT = open_fh( $output, '>' );
        $parser->output_fh($HTMLOUT);

        $parser->no_errata_section(1); # don't put errors in doc output
        $parser->complain_stderr(1);   # output errors on STDERR instead

        die "Unable to open file ($source)\n" unless -e $source;
        $parser->parse_file( open_fh( $source ) );

        $corpus->add_document( $parser->get_document, $parser );
    }

    $corpus->write_documents;
    $corpus->write_index;
    $corpus->write_toc;
}

sub process_args
{
    my @files;
    my $role  = 'HTML';
    my %roles = ( html => 'HTML', epub => 'EPUB' );

    for my $arg (@_)
    {
        if ($arg =~ /^--(\w+)=(\w+)/)
        {
            if ($1 eq 'role')
            {
                $role = exists $roles{$2} ? $roles{$2} : $role;
            };
        }
        else
        {
            push @files, $arg;
        }
    }

    return "Pod::PseudoPod::DOM::Role::$role", @files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::App::ToHTML - helper functions for bin/ppdom2html

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
