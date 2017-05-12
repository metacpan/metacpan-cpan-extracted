package Papery::Analyzer;

use strict;
use warnings;

use File::Spec;
use YAML::Tiny qw( Load );

sub analyze_file {
    my ( $class, $pulp, $path ) = @_;
    my $meta = $pulp->{meta};

    # $file is relative to __source
    my $abspath = File::Spec->catfile( $meta->{__source}, $path );

    open my $fh, $abspath or die "Can't open $path: $!";
    local $/;
    my $source = <$fh>;
    close $fh;

    # compute file extension
    my $ext = ( split /\./, $path )[-1];
    $meta->{_processor} = $meta->{_processors}{$ext}
        if exists $meta->{_processors}{$ext};

    # update meta
    $meta->{__source_path}    = $path;
    $meta->{__source_abspath} = $abspath;
    $meta->{_source}          = $source;
    return $class->analyze($pulp);
}

sub analyze {
    my ( $class, $pulp ) = @_;
    my $text = $pulp->{meta}{_source};

    # take the metadata out
    if ( $text =~ /\A---\n/ ) {
        ( undef, my $meta, $text ) = split /^---\n/m, $text, 3;
        $pulp->merge_meta( Load($meta) );
    }

    $pulp->{meta}{_text} = $text;
    return $pulp;
}

1;

__END__

=head1 NAME

Papery::Analyzer - Base class for Papery analyzers

=head1 SYNOPSIS

    package Papery::Analyzer::MyAnalyzer;
    
    use strict;
    use warnings;
    
    use Papery::Analyzer;
    our @ISA = qw( Papery::Analyzer );
    
    sub analyze {
        my ( $class, $pulp ) = @_;
    
        # analyze $pulp->{meta}{_source}
        # update $pulp->{meta}{_text}
    
        return $pulp;
    }
    
    1;

=head1 DESCRIPTION

C<Papery::Analyzer> is the base class for Papery analyzer classes.
Subclasses only need to define an C<analyze()> method, taking a
C<Papery::Pulp> object as the single parameter.

The C<analyze()> method is expected to take the C<_source> key from the
C<Papery::Pulp> object and use it to update the C<_text> key, that will
be later processed by C<Papery::Processor> classes.

=head1 METHODS

This class provides several methods:

=over 4

=item analyze_file( $pulp, $path )

Analyze the file under C<$path> and update the C<$pulp> object.
C<$path> is relative to C<__source>.

=item analyze( $pulp )

Analyze the C<_source> metadata, extract the YAML Front Matter, and
update the C<$pulp> metadata and C<_text>.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

