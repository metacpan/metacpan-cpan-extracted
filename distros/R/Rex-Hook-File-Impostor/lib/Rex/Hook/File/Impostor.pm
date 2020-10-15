package Rex::Hook::File::Impostor;

# ABSTRACT: execute Rex file management commands on a copy of the original file

use 5.012;
use strict;
use warnings;

our $VERSION = 'v0.1.1';

use File::Basename;
use File::Spec;
use Rex 1.012 -base;
use Rex::Hook;

register_function_hooks { before => { file => \&copy_file, }, };

sub copy_file {
    my ( $original_file, @opts ) = @_;

    my $impostor_file = get_impostor_for($original_file);

    Rex::Logger::debug("Copying $original_file to $impostor_file");

    if ( is_windows() ) {
        my $exec = Rex::Interface::Exec->create;
        $exec->exec("copy /v /y $original_file $impostor_file");
    }
    else {
        cp $original_file, $impostor_file;
    }

    return $impostor_file, @opts;
}

sub get_impostor_for {
    my $file = shift;

    return File::Spec->catfile( get_impostor_dir(), basename($file) );
}

sub get_impostor_dir {
    my $tmp_dir =
      File::Spec->catfile( Rex::Config->get_tmp_dir(), 'rex_hook_file_impostor' );

    mkdir $tmp_dir;
    return $tmp_dir;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ferenc Erki CPAN sponsorware

=head1 NAME

Rex::Hook::File::Impostor - execute Rex file management commands on a copy of the original file

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

    use Rex::Hook::File::Impostor;

=head1 DESCRIPTION

This module lets L<Rex|https://metacpan.org/pod/Rex> execute file management commands on a copy of the file instead of the original one.

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

This software is Copyright (c) 2020 by Ferenc Erki.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 3, June 2007

Early versions of this software were L<sponsorware|https://github.com/sponsorware/docs>. Thanks to L<GitHub sponsors|https://github.com/sponsors/ferki>, it is now available to everyone!

=cut
