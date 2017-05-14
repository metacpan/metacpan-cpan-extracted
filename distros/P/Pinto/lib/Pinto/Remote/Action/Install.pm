# ABSTRACT: Install packages from the repository

package Pinto::Remote::Action::Install;

use Moose;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Undef Bool HashRef ArrayRef Maybe Str);

use File::Temp;
use File::Which qw(which);

use Pinto::Result;
use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Remote::Action );

#------------------------------------------------------------------------------

has targets => (
    isa => ArrayRef [Str],
    traits  => ['Array'],
    handles => { targets => 'elements' },
    default => sub { $_[0]->args->{targets} || [] },
    lazy    => 1,
);

has do_pull => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has mirror_url => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_mirror_url',
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub _build_mirror_url {
    my ($self) = @_;

    my $stack      = $self->args->{stack};
    my $stack_dir  = defined $stack ? "/stacks/$stack" : '';
    my $mirror_url = $self->root . $stack_dir;

    if ( defined $self->password ) {

        # Squirt username and password into URL
        my $credentials = $self->username . ':' . $self->password;
        $mirror_url =~ s{^ (https?://) }{$1$credentials\@}mx;
    }

    return $mirror_url;
}

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    # Intercept attributes from the action "args" hash
    $args->{do_pull}       = delete $args->{args}->{do_pull}       || 0;
    $args->{cpanm_options} = delete $args->{args}->{cpanm_options} || {};

    return $args;
};

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $result;
    if ( $self->do_pull ) {

        my $request = $self->_make_request( name => 'pull' );
        $result = $self->_send_request( req => $request );

        throw 'Failed to pull packages' if not $result->was_successful;
    }

    # Pinto::Role::Installer will handle installation after execute()
    return defined $result ? $result : Pinto::Result->new;
};

#------------------------------------------------------------------------------

with qw( Pinto::Role::Installer );

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

Pinto::Remote::Action::Install - Install packages from the repository

=head1 VERSION

version 0.097

=for Pod::Coverage BUILD

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
