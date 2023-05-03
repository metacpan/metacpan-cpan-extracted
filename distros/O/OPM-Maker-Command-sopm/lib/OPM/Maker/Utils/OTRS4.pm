package OPM::Maker::Utils::OTRS4;
$OPM::Maker::Utils::OTRS4::VERSION = '1.1.1';
# ABSTRACT: helper functions for ((OTRS)) Community Edition >= 4 

use strict;
use warnings;

use List::Util qw(first);
use Carp;

sub packagesetup {
    my ($class, $type, $version, $function, $runtype, $package) = @_;

    $version = $version ? ' Version="' . $version . '"' : '';

    $runtype //= 'post';

    if ( $package ) {
        $package = sprintf "'%s'", $package;
    }
    else {
        $package = '$Param{Structure}->{Name}->{Content}';
    }

    return qq~    <$type Type="$runtype"$version><![CDATA[
        \$Kernel::OM->Get('var::packagesetup::' . $package )->$function();
    ]]></$type>~;
}

sub filecheck {
    my ($class, $files) = @_;

    if ( first{ $_ =~ m{Kernel/Output/HTML/[^/]+/.*?\.dtl\z} }@{$files} ) {
        carp "The old template engine was replaced with Template::Toolkit. Please use bin/otrs.MigrateDTLToTT.pl.\n";
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Utils::OTRS4 - helper functions for ((OTRS)) Community Edition >= 4 

=head1 VERSION

version 1.1.1

=head1 METHODS

=head2 packagesetup

=head2 filecheck

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
