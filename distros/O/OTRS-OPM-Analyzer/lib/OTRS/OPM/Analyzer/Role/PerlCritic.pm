package OTRS::OPM::Analyzer::Role::PerlCritic;

# ABSTRACT: Check if the code matches the OTRS coding guideline

use Moose::Role;

use File::Basename;
use File::Temp ();
use Perl::Critic;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ($self,$document) = @_;
    
    return if $document->{filename} !~ m{ \. (?:pl|pm|pod|t) \z }xms;
    
    my ($file,$path,$suffix) = fileparse( $document->{filename}, qr{ \..* \z }xms );
    
    my $fh = File::Temp->new(
        SUFFIX => $suffix,
    );
    
    my $filename = $fh->filename;
    
    print $fh $document->{content};
    close $fh;
    
    my $conf_path    = $self->config->get( 'utils.config' );
    my $perlcriticrc = $self->config->get( 'utils.perlcritic.config' );
    my $theme        = $self->config->get( 'utils.perlcritic.theme' ) || 'otrs';
    my $include      = $self->config->get( 'utils.perlcritic.include' ) || ['otrs'];

    my %options;
    $options{-profile} = $conf_path . '/' . $perlcriticrc if $perlcriticrc;
    
    my $critic       = Perl::Critic->new(
        -theme    => $theme,
        -include  => $include,
        %options,
    );
    
    my @violations = $critic->critique( $filename );
    my $return     = join '', @violations;
    
    return $return;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::PerlCritic - Check if the code matches the OTRS coding guideline

=head1 VERSION

version 0.06

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
