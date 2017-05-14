# ABSTRACT: Generates a stub 03modlist.data.gz file

package Pinto::ModlistWriter;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use IO::Zlib;
use HTTP::Date qw(time2str);

use Pinto::Types qw(File);
use Pinto::Util qw(debug throw);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);

has modlist_file => (
    is      => 'ro',
    isa     => File,
    default => sub { $_[0]->stack->modules_dir->file('03modlist.data.gz') },
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub write_modlist {
    my ($self) = @_;

    my $stack        = $self->stack;
    my $modlist_file = $self->modlist_file;

    debug("Writing module list for stack $stack at $modlist_file");

    my $fh = IO::Zlib->new( $modlist_file->stringify, 'wb' ) or throw $!;
    print {$fh} $self->modlist_data;
    close $fh or throw $!;

    return $self;
}

#------------------------------------------------------------------------------

sub modlist_data {
    my ($self) = @_;

    my $writer  = ref $self;
    my $version = $self->VERSION || 'UNKNOWN';
    my $package = 'CPAN::Modulelist';
    my $date    = time2str(time);

    return <<"END_MODLIST";
File:        03modlist.data
Description: This a placeholder for CPAN.pm
Modcount:    0
Written-By:  $writer version $version
Date:        $date

package $package;

sub data { {} }

1;
END_MODLIST

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

Pinto::ModlistWriter - Generates a stub 03modlist.data.gz file

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
