package Path::Canonical;
use 5.008005;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw/canon_path canon_filepath/;

our $VERSION = "0.05";

sub canon_filepath {
    my $path = shift;
    return canon_path($path) if $^O ne 'MSWin32';
    $path =~ s!\\!/!g;
    $path =~ s!^([a-zA-Z]:|//[^/]+/+[^/]+)!!g;
    $path = ($&||'') . canon_path($path);
    $path =~ s!/!\\!g;
    $path;
}

sub canon_path {
    my $path = shift;
    my @ret = ();
    $path .= '/' if $path =~ /[.\/]$/;
    for my $tok (split(/\/+/, $path . '-')) {
         next if $tok eq '.';
         if ($tok eq '..') {
             pop @ret;
             next;
         }
         push @ret, $tok if $tok;
    }
    '/' . substr(join('/', @ret), 0, -1)
}

1;
__END__

=encoding utf-8

=head1 NAME

Path::Canonical - Simple utility to get canonical paths.

=head1 SYNOPSIS

    use Path::Canonical;

=head1 DESCRIPTION

Path::Canonical is a simple utility to get canonical paths.
Other tools such as Cwd::abs_path exist, but they need to refer to the actual entry in the file system in order to work.
This is not feasible, for example, when you just want to cleanse the specified path in a web application, where you may
be dealing with a virtual path that does not exist in the file system.

=head1 LICENSE

Copyright (C) mattn.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mattn E<lt>mattn.jp@gmail.comE<gt>

=cut

