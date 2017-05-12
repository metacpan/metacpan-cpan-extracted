package Spoon::Utils;
use Spiffy -Base;
const directory_perms => 0755;

sub assert_filepath {
    my $filepath = shift;
    return unless $filepath =~ s/(.*)[\/\\].*/$1/;
    return if -e $filepath;
    $self->assert_directory($filepath);
}

sub assert_directory {
    my $directory = shift;
    require File::Path;
    umask 0000;
    File::Path::mkpath($directory, 0, $self->directory_perms);
}

sub remove_tree {
    my $directory = shift;
    require File::Path;
    umask 0000;
    File::Path::rmtree($directory);
}

__END__

=head1 NAME 

Spoon::Utils - Spoon Utilities Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
