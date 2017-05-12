# ABSTRACT: Base class for Locators

package Pinto::Locator;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Types qw(Dir Uri);
use Pinto::Util qw(throw tempdir);

#------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------

with qw(Pinto::Role::UserAgent);

#------------------------------------------------------------------------

has uri => (
    is        => 'ro',
    isa       => Uri,
    default   => 'http://backpan.perl.org',
    coerce    => 1,
);

has cache_dir => (
    is         => 'ro',
    isa        => Dir,
    default    => \&tempdir,
);

#------------------------------------------------------------------------

sub locate {
    my ($self, %args) = @_;

    $args{target} || throw 'Invalid arguments';

    $args{target} = Pinto::Target->new($args{target}) 
        if not ref $args{target};

    return $self->locate_package(%args)
        if $args{target}->isa('Pinto::Target::Package');

    return $self->locate_distribution(%args)
        if $args{target}->isa('Pinto::Target::Distribution');
        
    throw 'Invalid arguments';
}

#------------------------------------------------------------------------

sub locate_package { die 'Abstract method'}

#------------------------------------------------------------------------

sub locate_distribution { die 'Abstract method'}

#------------------------------------------------------------------------

sub refresh {}

#------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Locator - Base class for Locators

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
