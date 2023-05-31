package OPM::Maker::Command::depcheck;

# ABSTRACT: Check if ticketsystem addon dependencies are installed (works for ((OTRS)) Community Edition, Znuny and OTOBO)

use v5.10;

use strict;
use warnings;

our $VERSION = '1.0.1'; # VERSION

use version;

use Carp qw(croak);
use XML::LibXML;

use OPM::Maker -command;
use OPM::Maker::Utils qw(check_args_sopm);

sub abstract {
    return "check if OPM package depencies are already installed";
}

sub usage_desc {
    return "opmbuild depcheck [--home <ticketsystem_home>] <path_to_sopm_or_opm>";
}

sub opt_spec {
    return (
        [ 'home=s',     'Path to ticketsystem installation'  ],
        [ 'local_sopm', 'Checks if a .sopm for the required package exists in <home>' ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $sopm = check_args_sopm( $args, 1 );
    $self->usage_error( 'need path to .sopm or .opm' ) if
        !$sopm;

    if ( !$opt->{home} ) {
        for my $dir ( qw(otobo otrs znuny) ) {
            my $path = '/opt/' . $dir;

            next if ! -d $path;

            $opt->{home} = $path;
        }
    }

    if ( !-d $opt->{home} ) {
        $self->usage_error( "No ticketsystem found" );
    }
}

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $file = check_args_sopm( $args, 1 );

    my %opts;
    if ( !$ENV{OPM_UNSECURE} ) {
        %opts = (
            no_network      => 1,
            expand_entities => 0,
        );
    }

    my $size = -s $file;

    # if file is big, but not "too big"
    my $max_size = 31_457_280;
    if ( $ENV{OPM_MAX_SIZE} ) {
        $max_size = reformat_size( $ENV{OPM_MAX_SIZE} );
    }

    if ( $size > $max_size ) {
        croak "$file too big (max size: $max_size bytes)";
    }

    if ( $size > 10_000_000 ) {
        $opts{huge} = 1;
    }

    my $parser = XML::LibXML->new( %opts );
    my $tree   = $parser->parse_file( $file );
        
    my $root_elem = $tree->getDocumentElement;

    # retrieve file information
    my @package_req = $root_elem->findnodes( 'PackageRequired' );
    my @modules_req = $root_elem->findnodes( 'ModuleRequired' );
    
    for my $subpath ( '', qw(/Kernel/cpan-lib Custom) ) {
        push @INC, $opt->{home} . $subpath;
    }

    my @missing;

    DEP:
    for my $dependency ( @package_req, @modules_req ) {
        my $type    = $dependency->nodeName;
        my $version = $dependency->findvalue( '@Version' );
        my $name    = $dependency->textContent;
        
        my $result = _check_dep( $name, $version, $type );

        if ( $result && $opt->{local_sopm} && $type eq 'PackageRequired' ) {
            my $path = $opt->{home} . '/' . $name . '.sopm';
            if ( -f $path ) {
                my $local_tree    = $parser->parse_file( $path );
                my $root_elem     = $local_tree->getDocumentElement;

                my @local_names = $root_elem->findnodes('Name');
                my $local_name  = $local_names[0]->textContent;

                my @local_versions = $root_elem->findnodes('Version');
                my $local_version  = $local_versions[0]->textContent;

                if ( $local_name eq $name && version->new($local_version) > version->new( $version ) ) {
                    $result = '';
                }
            }
        }

        push @missing, $result if $result;
    }

    if ( !@missing ) {
        say "Everything ok!";
        return 0;
    }
    else {
        say "Missing: $_" for @missing;
        return 1;
    }
}

sub _check_dep {
    my ($name, $version, $type) = @_;

    if ( $type eq 'ModuleRequired' ) {
        my $path = $name . '.pm';
        $path =~ s{::}{/}g;

        eval {
            require $path;
            $name->VERSION( $version )
        } or return "CPAN-Module $name $version";
    }
    elsif ( $type eq 'PackageRequired' ) {
        require Kernel::System::ObjectManager;

        local $Kernel::OM = Kernel::System::ObjectManager->new;
        my $db_object     = $Kernel::OM->Get('Kernel::System::DB');

        my $sql = 'SELECT id, version FROM package_repository WHERE name = ?';
        $db_object->Prepare(
            SQL  => $sql,
            Bind => [ \$name ],
        );

        my $installed_version;
        while ( my @row = $db_object->FetchrowArray() ) {
            $installed_version = $row[1];
        }

        return "Addon $name $version" if !$installed_version;

        my $installed = version->new( $installed_version );
        my $required  = version->new( $version );

        return "Addon $name $version (installed $installed_version)" if $installed < $required;
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::depcheck - Check if ticketsystem addon dependencies are installed (works for ((OTRS)) Community Edition, Znuny and OTOBO)

=head1 VERSION

version 1.0.1

=head1 DESCRIPTION

Ticketsystem addons can define dependencies in the I<.opm> files, e.g.

    <PackageRequired Version="6.0.0">FAQ</PackageRequired>
    <ModuleRequired Version="8.0">Geo::IP2Location</ModuleRequired>
    <ModuleRequired Version="0.02">HTTP::AcceptLanguage</ModuleRequired>

In this case, the addon requires an other addon - FAQ with minimum version 6.0.0 -
and two CPAN modules.

This L<OPM::Maker> command checks for a given I<.sopm> or I<.opm> file
if the dependencies are already installed.

=head1 HOW IT WORKS

For the other addons, this command tries to find the ticketsystem installation
(it searches for I</opt/otrs>, I</opt/otobo> or I</opt/znuny>) and searches the database for
installed addons.

If it doesn't find the addons in the database, it looks for a
I</opt/{otrs,otobo,znuny}/$addonname.sopm> file. If that file exists
the addon is marked as I<installed>.

For the CPAN dependencies, this command tries to I<use> the module.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
