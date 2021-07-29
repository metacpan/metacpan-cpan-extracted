package Rex::Hook::File::Impostor;

# ABSTRACT: execute Rex file management commands on a copy of the managed path

use 5.012;
use warnings;

use Digest::MD5;
use English qw( -no_match_vars );
use File::Basename;
use File::Spec;
use Rex 1.013004 -base;
use Rex::Hook;
use Sys::Hostname;

our $VERSION = 'v0.2.0';

register_function_hooks { before => { file => \&impostor_hook, }, };

sub impostor_hook {
    my ( $managed_path, @opts ) = @_;

    my $impostor_path = get_impostor_for($managed_path);

    mkdir dirname($impostor_path);

    if ( is_file($managed_path) ) {
        Rex::Logger::debug("Copying $managed_path to $impostor_path");
        cp $managed_path, $impostor_path;
    }

    return $impostor_path, @opts;
}

sub get_impostor_for {
    my $path = shift;

    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);
    $volume =~ s/://gmsx;

    return File::Spec->join( get_impostor_directory(), $volume, $directories,
        $file );
}

sub get_impostor_directory {
    my $hasher = Digest::MD5->new();

    $hasher->add(hostname);
    $hasher->add($PID);

    my $unique_id = $hasher->hexdigest();

    my $impostor_directory = File::Spec->join( Rex::Config->get_tmp_dir(),
        'rex_hook_file_impostor', $unique_id );

    mkdir $impostor_directory;
    return $impostor_directory;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ferenc Erki CPAN sponsorware

=head1 NAME

Rex::Hook::File::Impostor - execute Rex file management commands on a copy of the managed path

=head1 VERSION

version v0.2.0

=head1 SYNOPSIS

    use Rex::Hook::File::Impostor;

=head1 DESCRIPTION

This module makes L<Rex|https://metacpan.org/pod/Rex> execute file management commands on a copy of the managed path instead of the original one.

This could be particularly useful when it is loaded conditionally to be combined with other modules. For example together with L<Rex::Hook::File::Diff|https://metacpan.org/pod/Rex::Hook::File::Diff>, it could be used to show a diff of file changes without actually changing the original file contents.

It works by installing a L<before hook|https://metacpan.org/pod/Rex::Commands::File#Hooks> for file commands, which makes a copy of the original file into a temporary directory, and then overrides the original arguments of the L<file commands|https://metacpan.org/pod/Rex::Commands::File#file>.

=head1 DIAGNOSTICS

This module does not do any error checking (yet).

=head1 CONFIGURATION AND ENVIRONMENT

It uses the same temporary directory that is used by Rex. Therefore it can be configured with L<set_tmp_dir|https://metacpan.org/pod/Rex::Config#set_tmp_dir>:

    Rex::Config->set_tmp_dir($tmp_dir);

This module does not use any environment variables.

=head1 DEPENDENCIES

See the included C<cpanfile>.

=head1 INCOMPATIBILITIES

There are no known incompatibilities with other modules.

=head1 BUGS AND LIMITATIONS

There are no known bugs. Make sure they are reported.

=head1 AUTHOR

Ferenc Erki <erkiferenc@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020,2021 by Ferenc Erki.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 3, June 2007

Early versions of this software were L<sponsorware|https://github.com/sponsorware/docs>. Thanks to L<GitHub sponsors|https://github.com/sponsors/ferki>, it is now available to everyone!

=cut
