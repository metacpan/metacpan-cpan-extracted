package Muuse;

use strictures 2;
use Import::Into;

use Moose            ();
use MooseX::ShortHas ();

our $VERSION = '1.222490'; # VERSION

# ABSTRACT: Moose but with less typing

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
    $_->import::into( $caller ) for qw( Moose MooseX::ShortHas );
}

1;

__END__

=pod

=head1 NAME

Muuse - Moose but with less typing

=head1 VERSION

version 1.222490

=head1 SYNOPSIS

    use Muuse;
    
    ro "hro";
    lazy hlazy => sub { 2 };
    rwp "hrwp";
    rw "hrw";

=head1 DESCRIPTION

Muuse imports both L<Moose> and L<MooseX::ShortHas>, making it even less work in
typing and reading to set up an object.

=head1 SEE ALSO

=over 4

=item *

L<Mu> - the Moo module from whence this sprang

=back

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/wchristian/Muuse/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/Muuse>

  git clone https://github.com/wchristian/Muuse.git

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 CONTRIBUTOR

=for stopwords mst - Matt S. Trout (cpan:MSTROUT)

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
