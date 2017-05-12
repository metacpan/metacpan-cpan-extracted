package SPOPS::Initialize;

# $Id: Initialize.pm,v 3.4 2004/06/02 00:48:21 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::ClassFactory;
use SPOPS::Exception qw( spops_error );

my $log = get_logger();

$SPOPS::Initialize::VERSION = sprintf("%d.%02d", q$Revision: 3.4 $ =~ /(\d+)\.(\d+)/);

# Main interface -- take the information read in from 'read_config()'
# and create SPOPS classes, then initialize them

sub process {
    my ( $class, $p ) = @_;
    $p ||= {};
    my $config = $p->{config};
    if ( $p->{directory} or $p->{filename} ) {
        $config = $class->read_config( $p );
        return unless ( ref $config eq 'HASH' );
        delete $p->{filename};
        delete $p->{directory};
        delete $p->{pattern};
    }

    # We were given more than one configuration to process, so merge

    if ( ref $config eq 'ARRAY' ) {
        my $full_config = {};
        foreach my $single_config ( @{ $config } ) {
            next unless ( ref $single_config eq 'HASH' );
            foreach my $object_key ( keys %{ $single_config } ) {
                $full_config->{ $object_key } = $single_config->{ $object_key };
            }
        }
        $config = $full_config;
    }

    my $class_created_ok = SPOPS::ClassFactory->create( $config, $p ) || [];
    unless ( scalar @{ $class_created_ok } ) {
        $log->warn( "No classes were created by 'SPOPS::ClassFactory->create()'" );
        return undef;
    }

    # Now go through each of the classes created and initialize

    my @full_success = ();
    foreach my $spops_class ( @{ $class_created_ok } ) {
        eval { $spops_class->class_initialize() };
        if ( $@ ) {
            spops_error "Failed to run class_initialize() on ",
                        "[$spops_class]: $@";
        }
        push @full_success, $spops_class;
    }
    return \@full_success;
}


# Read in one or more configuration files (see POD)

sub read_config {
    my ( $class, $p ) = @_;
    my @config_files = ();

    # You can specify one or more filenames to read

    if ( $p->{filename} ) {
        if ( ref $p->{filename} eq 'ARRAY' ) {
            push @config_files, @{ $p->{filename} };
        }
        else {
            push @config_files, $p->{filename};
        }
    }

    # Or specify a directory and, optionally, a pattern to match for
    # files to read

    elsif ( $p->{directory} and -d $p->{directory} ) {
        my $dir = $p->{directory};
        $log->is_info &&
            $log->info( "Reading configuration files from ($dir) with pattern ($p->{pattern})" );
        opendir( CONF, $dir )
               || spops_error "Cannot read configuration files from directory [$dir]: $!";
        my @directory_files = readdir( CONF );
        close( CONF );
        foreach my $file ( @directory_files ) {
            my $full_filename = "$dir/$file";
            next unless ( -f $full_filename );
            if ( $p->{pattern} ) {
                next unless ( $file =~ /$p->{pattern}/ );
            }
            push @config_files, $full_filename;
        }
    }

    # Now read in each of the files and assign the values to the main
    # $spops_config.

    my %spops_config = ();
    foreach my $file ( @config_files ) {
        $log->is_info &&
            $log->info( "Reading configuration from file: ($file)" );
        my $data = $class->read_perl_file( $file );
        if ( ref $data eq 'HASH' ) {
            foreach my $spops_key ( keys %{ $data } ) {
                $spops_config{ $spops_key } = $data->{ $spops_key };
            }
        }
    }

    return \%spops_config;
}


# Read in a Perl data structure from a file and return

sub read_perl_file {
    my ( $class, $filename ) = @_;
    return undef unless ( -f $filename );
    eval { open( INFO, $filename ) || die $! };
    if ( $@ ) {
        warn "Cannot open config file for evaluation ($filename): $@ ";
        return undef;
    }
    local $/ = undef;
    no strict;
    my $info = <INFO>;
    close( INFO );
    my $data = eval $info;
    if ( $@ ) {
        spops_error "Cannot read data structure from [$filename]: $@";
    }
    return $data;
}

1;

__END__

=pod

=head1 NAME

SPOPS::Initialize - Provide methods for initializing groups of SPOPS objects at once

=head1 SYNOPSIS

 # Bring in the class

 use SPOPS::Initialize;

 # Assumes that all your SPOPS configuration information is collected
 # in a series of files 'spops/*.perl'

 my $config = SPOPS::Initialize->read_config({
                              directory => '/path/to/spops',
                              pattern   => '\.perl' });

 # You could also have all your SPOPS classes in a single file:

 my $config = SPOPS::Initialize->read_config({
                              filename => '/path/to/my/spops.config' });

 # Or in a number of files:

 my $config = SPOPS::Initialize->read_config({
                              filename => [ '/path/to/my/spops.config.1',
                                            '/path/to/my/spops.config.2' ] });

 # As a shortcut, you read the config and process all at once

 SPOPS::Initialize->process({ directory => '/path/to/spops',
                              pattern   => '\.perl' });

 SPOPS::Initialize->process({ filename => '/path/to/my/spops.config' });

 SPOPS::Initialize->process({ filename => [ '/path/to/my/spops.config.1',
                                            '/path/to/my/spops.config.2' ] });

 # Use an already-formed config hashref from somewhere else

 SPOPS::Initialize->process({ config => \%spops_config });

 # You can also pass in multiple config hashrefs that get processed at
 # once, taking care of circular relationship problems (e.g., 'user'
 # links-to 'group', 'group' links-to 'user').

 SPOPS::Initialize->process({ config => [ $config1, $config2 ] });

=head1 DESCRIPTION

This class makes it simple to initialize SPOPS classes and should be
suitable for utilizing at a server (or long-running process) startup.

Initialization of a SPOPS class consists of four steps:

=over 4

=item 1.

Read in the configuration. The configuration can be in a separate
file, read from a database or built on the fly.

=item 2.

Ensure that the classes used by SPOPS are 'require'd.

=item 3.

Build the SPOPS class, using L<SPOPS::ClassFactory|SPOPS::ClassFactory>.

=item 4.

Initialize the SPOPS class. This ensures any initial work the class
needs to do on behalf of its objects is done. Once this step is
complete you can instantiate objects of the class and use them at
will.

=back

=head1 METHODS

B<process( \%params )>

The configuration parameter 'config' can refer to one or more SPOPS
object configuration hashrefs. These can be already-formed
configuration hashrefs which, if there are more than one,are merged.

Example:

 SPOPS::Initialize->process({ config => $spops_config });
 SPOPS::Initialize->process({ config => [ $spops_config, $spops_config ] });

You can also pass one or more filenames of SPOPS information (using
'filename', or a combination of 'directory' and
'pattern'). Filename/directory processing parameters are passed
directly to C<read_config()>.

Examples:

 # Process configurations in files 'user/spops.perl' and
 # 'group/spops.perl'

 SPOPS::Initialize->process({ filename => [ 'user/spops.perl',
                                            'group/spops.perl' ] });

 # Process all configuration files ending in .perl in the directory
 # 'conf/spops/':

 SPOPS::Initialize->process({ directory => 'conf/spops/',
                              pattern   => q(\.perl$) });

Other parameters in C<\%params> depend on C<SPOPS::ClassFactory> --
any values you pass will be passed through. This is fairly rare -- the
only one you might ever want to pass is 'alias_list', which is an
arrayref of aliases in the (merged or not) SPOPS config hashref to
process.

Example:

 # We're just clowning around, so only process 'bozo' -- 'user' and
 # 'group' aren't touched

 my $config = {  user  => { ... },
                 group => { ... },
                 bozo  => { ... } };
 SPOPS::Initialize->process({ config => $config, alias_list => [ 'bozo' ] });

B<read_config( \%params )>

Read in SPOPS configuration information from one or more files in the
filesystem.

Parameters:

=over 4

=item *

B<filename> ($ or \@)

One or more filenames, each with a fully-qualified path.

=item *

B<directory> ($)

Directory to read files from. If no B<pattern> given, we try to read
all the files from this directory.

B<pattern> ($)

Regular expression pattern to match the files in the directory
B<directory>. For instance, you can use

  \.perl$

to match all the files ending in '.perl' and read them in.

=back

=head1 SEE ALSO

L<SPOPS::ClassFactory|SPOPS::ClassFactory>

=head1 COPYRIGHT

Copyright (c) 2001-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
