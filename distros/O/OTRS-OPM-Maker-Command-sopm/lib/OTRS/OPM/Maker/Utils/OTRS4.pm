package OTRS::OPM::Maker::Utils::OTRS4;

use strict;
use warnings;

use List::Util qw(first);
use Carp;

sub packagesetup {
    my ($class, $type, $version, $function) = @_;

    $version = $version ? ' Version="' . $version . '"' : '';

    return qq~    <$type Type="post"$version><![CDATA[
        \$Kernel::OM->Get('var::packagesetup::' . \$Param{Structure}->{Name}->{Content} )->$function();
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

OTRS::OPM::Maker::Utils::OTRS4

=head1 VERSION

version 1.37

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
