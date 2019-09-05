#!/usr/bin/env perl
# Run Parse::Yapp to generate Sub::Multi::Tiny::SigParse

use 5.006;
use strict;
use warnings;

use Cwd 'abs_path';
use File::Spec;
use Parse::Yapp;

# Find the dist's root
my $here = abs_path(__FILE__);
die "Could not find my file location: $!" unless defined $here;
my ($volume,$directories,$file) = File::Spec->splitpath( $here );
my @dirs = File::Spec->splitdir( $directories );
die "Can't move up to the parent directory!" unless @dirs>1;
pop @dirs while $dirs[$#dirs] ne 'lib';     # In case of trailing slash
pop @dirs;
my @dist_base_dirs = @dirs;

# Find support/SigParse.yp
push @dirs, 'support';
my $yp_file = File::Spec->catpath(
    $volume,
    File::Spec->catdir(@dirs),
    'SigParse.yp'
);
die "Could not read $yp_file" unless -f $yp_file && -r _;

# Find lib/Sub/Multi/Tiny/SigParse.pm
@dirs = @dist_base_dirs;
push @dirs, qw(lib Sub Multi Tiny);
my $pm_dir = File::Spec->catpath(
    $volume,
    File::Spec->catdir(@dirs),
    ''
);
my $pm_file = File::Spec->catpath(
    $volume,
    File::Spec->catdir(@dirs),
    'SigParse.pm'
);

# Make sure the target directory exists
mkdir $pm_dir;  # Ignore errors

# The following code modified from Parse::Yapp's yapp(1) script, which is
# distributed under the same terms as Perl itself.
my $parser = Parse::Yapp->new(inputfile => $yp_file);
my ($warnings) = $parser->Warnings;
print STDERR $warnings if $warnings;

open(my $pm_fd, '>', $pm_file) or die "Cannot open $pm_file for writing: $!\n";
print {$pm_fd} $parser->Output(classname => 'Sub::Multi::Tiny::SigParse',
                                standalone => 0,
                                linenumbers => 1,
                                template => undef);
close $pm_fd;
print STDERR "# Generated $pm_file from $yp_file\n";
exit 0;

__END__
# Documentation {{{1

=head1 NAME

BuildSigParse - Run Parse::Yapp to generate Sub::Multi::Tiny::SigParse

=head1 SYNOPSIS

This is automatically run by L<Module::Build::Tiny> during the build process.

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=cut

# }}}1
# vi: set fdm=marker: #
