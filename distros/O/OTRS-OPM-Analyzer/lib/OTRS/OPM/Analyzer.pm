package OTRS::OPM::Analyzer;

# ABSTRACT: Analyze OTRS add-ons (.opm files)

use Moose;
use Moose::Util::TypeConstraints;

use OTRS::OPM::Parser;
use OTRS::OPM::Analyzer::Utils::Config;

our $VERSION = 0.06;

# define types
subtype 'OPMFile' =>
  as 'Object' =>
  where { $_->isa( 'OTRS::OPM::Parser' ) };

# declare attributes
has opm => (
    is  => 'rw',
    isa => 'OPMFile',
);

has configfile => (
    is  => 'ro',
    isa => 'Str',
);

has roles => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef]',
    default => sub {
        +{
            file => [qw/
                SystemCall
                PerlCritic
                TemplateCheck
                BasicXMLCheck
                PerlTidy
            /],
            opm  => [qw/
                UnitTests
                Documentation
                Dependencies
                License
            /],
        };
    },
    auto_deref => 1,
);

sub _load_roles {
    my ($self) = @_;
    
    my %roles = $self->roles;
    
    for my $area ( keys %roles ) {
        for my $role ( @{ $roles{$area} } ) {
            with __PACKAGE__ . '::Role::' . $role => {
                -alias    => { check => 'check_' . lc $role },
                -excludes => 'check',
            };
        }
    }
}

sub analyze {
    my ($self,$opm) = @_;
    
    $self->_load_roles;
    
    my $opm_object = OTRS::OPM::Parser->new(
        opm_file => $opm,
    );
    my $success    = $opm_object->parse;
    
    return if !$success;
    
    $self->opm( $opm_object );
    
    my %analysis_data;
    
    # do all the checks that are based on the content of files
    my %roles   = $self->roles;
    my $counter = 1;
    
    for my $file ( $opm_object->files ) {
        
        ROLE:
        for my $role ( @{ $roles{file} || [] } ) {
            my ($sub) = $self->can( 'check_' . lc $role );
            next ROLE if !$sub;
            
            my $result   = $self->$sub( $file );
            my $filename = $file->{filename};
            
            $analysis_data{$role}->{$filename} = $result;
        }
        last if $counter++ == 4;
    }
    
    # do the opm check - some checks have to be performed on the opm itself
    # as these checks are no checks of the content
    ROLE:
    for my $role ( @{ $roles{opm} || [] } ) {
        my ($sub) = $self->can( 'check_' . lc $role );
        next ROLE if !$sub;
        
        my $result   = $self->$sub( $opm_object );
        $analysis_data{$role} = $result;
    }
    
    # return analysis data
    return \%analysis_data;
}

sub config {
    my ($self) = @_;
    
    if ( !$self->{__config} ) {
        $self->{__config} = OTRS::OPM::Analyzer::Utils::Config->new(
            $self->configfile,
        );
    }
    
    return $self->{__config};
}

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer - Analyze OTRS add-ons (.opm files)

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use OTRS::OPM::Analyzer;
  use Data::Dumper;
  
  my $opm      = 'test.opm';
  my $config   = $FindBin::Bin . '/../conf/base.yml';
  my $analyzer = OTRS::OPM::Analyzer->new(
      configfile => $config,
      roles => {
          opm => [qw/Dependencies/],
      },
  );
  my $results  = $analyzer->analyze( $opm );
  
  print Dumper $results;

=head1 DESCRIPTION

OTRS add ons are plain XML files with all information in it. Even the files that are shipped with
the add on is in this XML file (base64 encoded). Those add ons should be implemented in the
OTRS way of Perl programming and include some specific files (like documentation).

=head1 METHODS

=head2 analyze

=head2 config

=head1 SHIPPED ROLES

=head2 Base

=head2 BasicXMLCheck

=head2 Dependencies

=head2 Documentation

=head2 License

=head2 PerlCritic

=head2 PerlTidy

=head2 SystemCall

=head2 TemplateCheck

=head2 UnitTests

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
