
=head1 NAME

Palm::Progect::VersionDelegator - Delegate to specific Progect db driver based on version

=head1 SYNOPSIS

    package Palm::Progect::Record;
    use vars qw(@ISA);

    @ISA = qw(Palm::Progect::Record);

    1;

=head1 DESCRIPTION

Delegate to specific database driver based on database version.  If
version is not specified, then it will delegate to the database driver
with the highest number.

For instance to create a version 0.18 Record, the user can do the following:

    my $record = Palm::Progect::Record->new(
        raw_record => $some_raw_data,
        version    => 18,
    );

Behind the scenes, this call will be translated into the equivalent of:

    require 'Palm/Progect/DB_18/Record.pm';
    my $record = Palm::Progect::DB_18::Record->new(
        raw_record => $some_raw_data,
    );

=cut

package Palm::Progect::VersionDelegator;

use strict;
use 5.004;
use File::Spec;
use Carp;

sub new {
    my $proto      = shift;
    my $this_class = ref $proto || $proto;

    my @base_class  = split /::/, $this_class; # e.g. ('Palm', 'Progect')
    my $module_name = pop @base_class;         # e.g. 'Record'

    my %args = @_;

    my $version = delete $args{'version'} || 0;

    my $version_class = '';
    if ($version > 0) {
        $version_class = 'DB_' . $version;
    }
    else {
        # Latest version was requested.
        $version_class = 'DB_' . _latest_version(File::Spec->join(@base_class));
    }

    my $module_path  = File::Spec->join(@base_class,$version_class, $module_name . '.pm');
    my $module_class = join '::', @base_class, $version_class, $module_name;

    require $module_path;

    return $module_class->new(%args);
}

# Cache the latest version to avoid repeatedly searching
# through the filesystem

# Find latest version of module
# find directories matching DB_yy
# and pick the one where yy is the greatest

my %Latest_Version;
sub _latest_version {
    my $base_class_path = shift;

    if (! exists $Latest_Version{$base_class_path}) {


        local *DIR;

        my $max_version          = 0;
        my $max_version_filename = '';

        foreach my $inc (@INC) {
            my $path = File::Spec->join($inc, $base_class_path);

            next unless -d $path;

            if (opendir DIR, $path) {
                my @subdirs = readdir(DIR);
                close DIR;

                foreach my $subdir (@subdirs) {
                    next unless -d File::Spec->join($path, $subdir);
                    next unless $subdir =~ /^DB_(\d+)$/;

                    my $subdir_version = $1;

                    next unless $subdir_version > $max_version;

                    $max_version          = $subdir_version;
                }
            }
        }
        $Latest_Version{$base_class_path} = $max_version;
    }

    return $Latest_Version{$base_class_path};
}

1;

__END__

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

C<progconv>

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut

