package Path::Tiny::Glob::Visitor;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: directory visitor for Path::Tiny::Glob
$Path::Tiny::Glob::Visitor::VERSION = '0.1.0';
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

has found => (
    is => 'rw',
    default => sub { [] },
);

has next => (
    is => 'rw',
    default => sub { +{} },
);

sub as_list($self) {
    $self->match;
    return lazy_fixed_list $self->found->@*, $self->subvisitors;
}

sub subvisitors($self) {
    return map {
        Path::Tiny::Glob::Visitor->new(
            path => Path::Tiny::path($_),
            globs => $self->next->{$_},
        )->as_list
    } sort keys $self->next->%*;
}

sub match( $self ) {

    my @rules = map { $self->glob2rule( $_ ) } $self->globs->@*;

    my $state = $self->path->visit(sub {
        my( $path, $state ) = @_;

        for my $rule ( @rules ) {
            next unless $rule->[0]->($path);
            if( $rule->[1] ) {
                $state->{path}{$path}||=[];
                push( $state->{path}{$path}->@*, $rule->[1] );
            }
            else {
                $state->{found}{$path} = 1;
            }
        }
    });


   delete $state->{path}{$_} for keys $state->{found}->%*;

   $self->next(
       $state->{path}
   ) if $state->{path};

   $self->found([ keys $state->{found}->%* ]);
}

# turn a glob into a regular expression
sub glob2re($glob) {
    $glob =~ s/\?/.?/g;
    $glob =~ s/\*/.*/g;
    return qr/^$glob$/;
}

sub glob2rule($self,$glob) {
    my( $head, @rest ) = @$glob;

    if ( $head eq '.' ) {
        return $self->glob2rule(\@rest);
    }

    if( $head eq '**' ) {
        return [ sub { $_[0]->is_dir }, $glob ], $self->glob2rule(\@rest) if @rest;

        return [ sub { $_[0]->is_file } ], [ sub { $_[0]->is_dir }, ['**'] ];
    }

    return [ $self->segment2code($head, 'is_dir' ), \@rest ] if @rest;

    return [ $self->segment2code($head, ('is_file') x ! ref $head) ];

}

sub segment2code($self,$segment,$type_test=undef) {

    $segment = glob2re($segment) unless ref $segment;

    my $test = ref $segment eq 'Regexp'
        ? sub { $_->basename =~ $segment  }
        : $segment;

    return $type_test ? sub { $_->$type_test and $test->() } : $test;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Tiny::Glob::Visitor - directory visitor for Path::Tiny::Glob

=head1 VERSION

version 0.1.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
