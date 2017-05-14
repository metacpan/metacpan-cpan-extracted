# ABSTRACT: show some gratitude

package App::Pinto::Command::thanks;

use strict;
use warnings;

use Path::Class qw(dir);
use Pod::Usage qw(pod2usage);

use base qw(App::Pinto::Command);

#-------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#-------------------------------------------------------------------------------

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $path;
    for my $dir (@INC) {
        my $maybe = dir($dir)->file(qw(Pinto Manual Thanks.pod));
        do { $path = $maybe->stringify; last } if -f $maybe;
    }

    die "Could not find the Thanks pod.\n" if not $path;

    pod2usage(
        -verbose  => 99,
        -sections => 'THANK YOU',
        -input    => $path,
        -exitval  => 0,
    );

    return 1;
}

#-------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

App::Pinto::Command::thanks - show some gratitude

=head1 VERSION

version 0.097

=head1 SYNOPSIS

  pinto thanks

=head1 DESCRIPTION

This command shows our appreciation to those who contributed to the Pinto
crowdfunding campaign.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
