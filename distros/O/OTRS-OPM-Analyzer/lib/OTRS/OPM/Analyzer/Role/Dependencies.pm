package OTRS::OPM::Analyzer::Role::Dependencies;

# ABSTRACT: Check that all dependencies were declared

use Moose::Role;

use File::Basename;
use File::Temp ();
use Module::CoreList;
use Module::OTRS::CoreList;
use PPI;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ( $self, $opm ) = @_;
    
    # get all dependencies declared in opm file
    my %named_dependencies = map{ my $name = $_->{name}; $name => 1; }$opm->dependencies;
    my @otrs_versions      = $opm->framework;
    my $perl_version       = $self->config->get( 'general.perl_version' );
    
    my %uses;

    # get all modules used, required, Required by the files    
    for my $file ( $opm->files ) {
        my @file_uses = $self->_get_file_dependencies( $file );
        if ( @file_uses ) {
            @uses{@file_uses} = (1) x @file_uses;
        }
    }
    
    # check which dependencies are not declared in 
    my @not_declared;
    
    DEPENDENCY:
    for my $dependency ( keys %uses ) {
        
        # check if it is declared
        next DEPENDENCY if $named_dependencies{$dependency};
        
        # check if it is a standard otrs module
        for my $otrs_version ( @otrs_versions ) {
            next DEPENDENCY if Module::OTRS::CoreList->shipped(
                $otrs_version,
                $dependency,
            );
        }
        
        # check if it is a standard perl module
        my $first_release = Module::CoreList->first_release( $dependency );
        next DEPENDENCY if $first_release and $first_release < $perl_version;
        
        # the dependency is not declared
        push @not_declared, $dependency;
    }
    
    return join ', ', @not_declared;
}

sub _get_file_dependencies {
    my ( $self, $document ) = @_;
    
    return if $document->{filename} !~ m{ \. (?:pl|pm) \z }xms;
    
    my $ppi = PPI::Document->new( \$document->{content} );
    
    my @uses;
    
    # get all 'use' and 'require' statements that include a module
    my $includes = $ppi->find( 'PPI::Statement::Include' ) || [];
    for my $include ( @{$includes} ) {
        
        # we don't care for "deactivation"
        next if $include->type eq 'no';
        
        # get module name
        my $module = $include->module;
        next if !$module;
        
        push @uses, $module;
    }
    
    # get modulenames that are included via MainObject->Require()
    push @uses, $self->_get_required_modules( $ppi );
    
    return @uses;
}

sub _get_required_modules {
    my ( $self, $ppi ) = @_;
    
    # method invocation starts with '->' operator
    my $operators = $ppi->find( 'PPI::Token::Operator' );
    
    my @uses;
    for my $op ( $operators ) {
        next if $op ne '->';
        
        # next to the -> the methodname should be found. We need 'Require()'
        my $sibling = $op->snext_sibling;
        next if $sibling ne 'Require';
        
        # get the parameter list of Require()
        my $list = $sibling->snext_sibling;
        next if !$list->isa( 'PPI::Structure::List' );
        
        # find strings. We don't care for dynamic module includes
        my $strings = $list->find(
            sub {
                $_[1]->isa( 'PPI::Token::Quote::Single' ) ||
                $_[1]->isa( 'PPI::Token::Quote::Double' )
            }
        );
        
        # check that is a namen, not a variable
        for my $string ( @{$strings} ) {
            push @uses, $string->content if $string->content =~ m{ \A [A-Za-z] }xms;
        }
    }
    
    return @uses;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::Dependencies - Check that all dependencies were declared

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This role checks if all dependencies were declared. To achieve this, all modules that are
C<use>d are compared to the modules OTRS ships and those that are shipped with the Perl
core.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
