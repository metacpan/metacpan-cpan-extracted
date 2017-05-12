#
# This file is part of Module-Packaged-Generator
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Module::Packaged::Generator::CPAN;
BEGIN {
  $Module::Packaged::Generator::CPAN::VERSION = '1.111930';
}
# ABSTRACT: interface to Parse::CPAN::Packages::Fast

use Moose;
use MooseX::ClassAttribute;
use MooseX::Has::Sugar;
use Parse::CPAN::Packages::Fast;

with 'Module::Packaged::Generator::Role::Logging';
with 'Module::Packaged::Generator::Role::UrlFetching';


# -- private attributes

# parse::cpan::packages::fast object
class_has _cpan => ( ro, isa=>'Parse::CPAN::Packages::Fast', lazy_build );
sub _build__cpan {
    my $self = shift->new;
    $self->log( "fetching fresh cpan index" );
    my $file = '02packages.details.txt.gz';
    my $url  = "http://www.perl.org/CPAN/modules/$file";
    my $pkgfile = $self->fetch_url( $url, $file );

    $self->log( "parsing $pkgfile" );
    return Parse::CPAN::Packages::Fast->new($pkgfile->stringify);
}


# -- public methods


sub module2dist {
    my ($self, $modname) = @_;
    my $pkg;
    eval { $pkg = $self->_cpan->package( $modname ); };
    return unless $pkg;
    return $pkg->distribution->dist;
}

1;


=pod

=head1 NAME

Module::Packaged::Generator::CPAN - interface to Parse::CPAN::Packages::Fast

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This class is a wrapper around L<Parse::CPAN::Packages::Fast>,
responsible for updating cpan index, parsing it and answering questions
related to CPAN packages index.

=head1 METHODS

=head2 module2dist

    my $dist = $cpan->module2dist( $modname );

Return the CPAN distribution which owns C<$modname>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

