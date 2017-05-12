package OTRS::OPM::Analyzer::Role::PerlTidy;

# ABSTRACT: Check if the code matches the OTRS coding guidelines (part II)

use Moose::Role;

use File::Temp ();
use Perl::Tidy;
use Text::Diff;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ($self,$document) = @_;
    
    return if $document->{filename} !~ m{ \. (?:pl|pm|pod|t) \z }xms;
    
    # create temporary file
    my $fh_to_tidy = File::Temp->new;
    my $fh_check   = File::Temp->new;
    my $fh_temp    = File::Temp->new;
    
    my $file_check = $fh_check->filename;
    my $file_tidy  = $fh_to_tidy->filename;
    my $file_temp  = $fh_temp->filename;
    
    $fh_to_tidy->print( $document->{content} );
    $fh_check->print( $document->{content} );
    
    close $fh_to_tidy;
    close $fh_check;
    close $fh_temp;
    
    my $default    = do{ local $/; <DATA> };
    my $conf_path  = $self->config->get( 'utils.config' );
    my $perltidyrc = $self->config->get( 'utils.perltidy.config' );
    
    my %option     = $perltidyrc ? ( perltidyrc => $conf_path . '/' . $perltidyrc )
                                 : ( argv => $default );
    
    # run Perl::Tidy
    Perl::Tidy::perltidy(
        source      => $file_tidy,
        destination => $file_temp,
        %option,
    );
    
    # run it a second time to avoid a bug
    Perl::Tidy::perltidy(
        source      => $file_temp,
        destination => $file_tidy,
        %option,
    );
    
    # check if Perl::Tidy has done anything, use Text::Diff for that
    my $diff = Text::Diff::diff( $file_check, $file_tidy, { STYLE => 'Unified' } );
    
    if ( $diff ) {
        $diff =~ s{ \A --- \s* [^\s]+ }{--- Original}xms;
        $diff =~ s{ \A ([^\n]+) \r?\n\+\+\+ \s* [^\s]+ }{$1\n+++ AfterTidying}xms;
    }
    
    return $diff;
}

no Moose::Role;

1;

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::PerlTidy - Check if the code matches the OTRS coding guidelines (part II)

=head1 VERSION

version 0.06

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
-l=100 -i=4 -ci=4 -vt=0 -vtc=0 -cti=0 -pt=1 -bt=1 -sbt=1 -bbt=1 -nsfs -nolq -bbao -nola -ndnl
