package OPM::Maker::Command::filetest;
$OPM::Maker::Command::filetest::VERSION = '1.00';
# ABSTRACT: check if filelist in .sopm includes the files on your disk

use strict;
use warnings;

use File::Find::Rule;
use Path::Class ();
use XML::LibXML;

use OPM::Maker -command;

sub abstract {
    return "Check if filelist in .sopm includes the files on your disk";
}

sub usage_desc {
    return "opmbuild filetest <path_to_sopm>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    
    $self->usage_error( 'need path to .sopm' ) if
        !$args or
        'ARRAY' ne ref $args or
        !defined $args->[0] or
        $args->[0] !~ /\.sopm\z/ or
        !-f $args->[0];
}

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $file = $args->[0];
    my $parser = XML::LibXML->new;
    my $tree   = $parser->parse_file( $file );
    
    my $sopm_path = Path::Class::File->new( $file );
    my $path      = $sopm_path->dir;
    
    my $path_str     = $path->stringify;
    my $ignore_files = File::Find::Rule->file->name(".*");    
    my @files_in_fs  = File::Find::Rule->file
        ->not( $ignore_files )
        ->in ( $path_str );
    
    my %fs = map{ $_ =~ s{\A\Q$path_str\E/?}{}; $_ => 1 }
        grep{ $_ !~ /\.git|CVS|svn/ }@files_in_fs;
        
    delete $fs{ $sopm_path->basename };
    
    my $root_elem = $tree->getDocumentElement;
    
    # retrieve file information
    my @files = $root_elem->findnodes( 'Filelist/File' );
    
    my @not_found;
    
    FILE:
    for my $file ( @files ) {
        my $name = $file->findvalue( '@Location' );
        
        push @not_found, $name if !delete $fs{$name};
    }
    
    if ( @not_found ) {
        print "Files listed in .sopm but not found on disk:\n",
            map{ "    - $_\n" }@not_found;
    }
    
    if ( %fs ) {
        print "Files found on disk but not listed in .sopm:\n",
            map{ "    - $_\n" }sort keys %fs;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::filetest - check if filelist in .sopm includes the files on your disk

=head1 VERSION

version 1.00

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
