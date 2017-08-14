package Mu;

use strictures 2;
use Import::Into;

use Moo            ();
use MooX::ShortHas ();

our $VERSION = '1.172231'; # VERSION

# ABSTRACT: Moo but with less typing

#
# This file is part of Mu
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
    $_->import::into( $caller ) for qw( Moo MooX::ShortHas );
}

1;

__END__

=pod

=head1 NAME

Mu - Moo but with less typing

=head1 VERSION

version 1.172231

=head1 SYNOPSIS

    use Mu;
    
    ro "hro";
    lazy hlazy => sub { 2 };
    rwp "hrwp";
    rw "hrw";

=head1 DESCRIPTION

Mu imports both L<Moo> and L<MooX::ShortHas>, making it even less work in typing
and reading to set up an object.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/wchristian/Mu/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/Mu>

  git clone https://github.com/wchristian/Mu.git

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
