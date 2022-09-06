package Muuse::Role;

use strictures 2;
use Import::Into;

use Moose::Role      ();
use MooseX::ShortHas ();

our $VERSION = '1.222490'; # VERSION

# ABSTRACT: Moose::Role but with less typing

#
# This file is part of Muuse
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#


sub import {
    my $caller = caller;
    $_->import::into( $caller ) for qw( Moose::Role MooseX::ShortHas );
}

1;

__END__

=pod

=head1 NAME

Muuse::Role - Moose::Role but with less typing

=head1 VERSION

version 1.222490

=head1 SYNOPSIS

    use Muuse::Role;
    
    ro "hro";
    lazy hlazy => sub { 2 };
    rwp "hrwp";
    rw "hrw";

=head1 DESCRIPTION

Mu imports both L<Moose::Role> and L<MooseX::ShortHas>, making it even less work
in typing and reading to set up a role.

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
