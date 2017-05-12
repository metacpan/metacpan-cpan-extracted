#!/usr/bin/perl -w

package Module::InstalledVersion;

use strict;
use Carp ();
use File::Spec ();

use vars '$VERSION';
$VERSION = "0.05";

=pod

=head1 NAME

Module::InstalledVersion - Find out what version of a module is installed

=head1 SYNOPSIS

    use Module::InstalledVersion;
    my $m = new Module::InstalledVersion 'Foo::Bar';
    print "Version is $m->{version}\n";
    print "Directory is $m->{dir}\n";

=head1 DESCRIPTION

This module finds out what version of another module is installed,
without running that module.  It uses the same regexp technique used by
L<Extutils::MakeMaker> for figuring this out.

Note that it won't work if the module you're looking at doesn't set
$VERSION properly.  This is true of far too many CPAN modules.

=cut

sub new {
    shift;
    my ($module_name) = @_;
    my $self = {};
    $module_name = File::Spec->catfile(split(/::/, $module_name));

    DIR: foreach my $dir (@INC) {
        my $filename = File::Spec->catfile($dir, "$module_name.pm");
        if (-e $filename ) {
            $self->{dir} = $dir;
            if (open IN, "$filename") {
                while (<IN>) {
                    # the following regexp comes from the Extutils::MakeMaker
                    # documentation.
                    if (/([\$*])(([\w\:\']*)\bVERSION)\b.*\=/) {
                        local $VERSION;
                        my $res = eval $_;
                        $self->{version} = $VERSION || $res;
                        last DIR;
                    }
                }
            } else {
                Carp::carp "Can't open $filename: $!";
            }
        }
    }
    bless $self;
    return $self;
}

=head1 COPYRIGHT

Copyright (c) 2001 Kirrily Robert.
This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Extutils::MakeMaker>

=head1 AUTHOR

Kirrily "Skud" Robert <skud@cpan.org>

=cut
