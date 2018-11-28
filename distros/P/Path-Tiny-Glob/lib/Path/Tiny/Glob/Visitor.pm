package Path::Tiny::Glob::Visitor;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: directory visitor for Path::Tiny::Glob
$Path::Tiny::Glob::Visitor::VERSION = '0.0.1';
use Moo;

require Path::Tiny; 
use List::Lazy qw/ lazy_fixed_list /;

use experimental qw/
    signatures
    postderef
/;

has path => (
    is	    => 'ro',
    required => 1,
);

has globs => (
    is => 'ro',
    required => 1,
);

has children => (
    is => 'ro',
    lazy => 1,
    default => sub { 
        [ Path::Tiny::path($_[0]->path)->children ];
    }
);

has found => (
    is => 'ro',
    default => sub { [] },
);

has next => (
    is => 'ro',
    default => sub { +{} },
);

sub as_list($self) {

    for my $g ( $self->globs->@* ) {
        $self->match( $g );
    }

    return lazy_fixed_list $self->found->@*, $self->subvisitors;
}

sub subvisitors($self) {
    my @paths = sort keys $self->next->%*;

    return map {
        Path::Tiny::Glob::Visitor->new(
            path => $_,
            globs => $self->next->{$_},
        )->as_list
    } @paths;
}
    
sub match( $self, $glob ) {
    my( $head, $rest ) = split '/', $glob, 2;

    if( $head eq '.' ) {
        return $self->match( $rest );
    }

    if( $head eq '**' ) {

        return unless $rest;

        push $self->next->{$_}->@*, "**/$rest" for grep { $_->is_dir } $self->children->@*;
        $self->match( split '/', $rest, 2 );
        return;

    }

    # TODO optimize for when there is no globbing (no need
    # to check all the children)
    if( $rest ) {
        no warnings;
        push $self->next->{$_}->@*, $rest for grep { 
            $_->basename =~ glob2re($head) }
            grep { $_->is_dir }  $self->children->@*;
        return;
    }
    else {
        push $self->found->@*, grep { $_->is_file } grep { $_->basename =~ glob2re($head) } $self->children->@*;
    }
}

sub glob2re($glob) {
    $glob =~ s/\?/.?/g;
    $glob =~ s/\*/.*/g;
    return qr/^$glob$/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Tiny::Glob::Visitor - directory visitor for Path::Tiny::Glob

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
