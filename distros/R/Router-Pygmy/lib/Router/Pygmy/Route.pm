package Router::Pygmy::Route;
$Router::Pygmy::Route::VERSION = '0.05';
use strict;
use warnings;

# ABSTRACT: simple route object 

use Carp;
our @CARP_NOT = qw(Router::Pygmy);

sub spec { shift()->{spec}; }

sub arg_names { shift()->{arg_names}; }

sub arg_idxs { shift()->{arg_idxs}; }

sub parts { shift()->{parts}; }

sub new {
    my ($class, %fields) = @_;
    return bless(\%fields, $class);
}

sub parse {
    my ( $class, $spec ) = @_;

    my ( @arg_names, @arg_idxs, @parts );
    my $i = 0;
    for my $part ( grep { $_ } split m{/}, $spec ) {
        my $is_arg = $part =~ s/^://;
        if ($is_arg) {
            push @parts,     undef;
            push @arg_idxs,  $i;
            push @arg_names, $part;
        }
        else {
            push @parts, $part;
        }
        $i++;
    }
    return $class->new(
        spec      => $spec,
        parts     => \@parts,
        arg_names => \@arg_names,
        arg_idxs  => \@arg_idxs,
    );
}

sub path_for {
    my $this = shift;

    my @parts = @{ $this->parts };
    @parts[ @{ $this->arg_idxs } ] = $this->args_for(@_);
    return join '/', @parts;
}

sub args_for {
    my $this = shift;
    my $args
        = !@_ || !defined $_[0] ? []
        : !ref $_[0] ? [ shift() ]
        :              shift();

    my $arg_names = $this->arg_names;

    if ( ref $args eq 'ARRAY' ) {

        # positional args
        @$args == @$arg_names
            or croak sprintf
            "Invalid arg count for route '%s', got %d args, expected %d",
            $this->spec, scalar @$args, scalar @$arg_names;
        return @$args;
    }
    elsif ( ref $args eq 'HASH' ) {

        # named args
        keys %$args == @$arg_names
            && not( grep { !exists $args->{$_}; } @$arg_names )
            or croak sprintf
            "Invalid args for route '%s', got (%s) expected (%s)",
            $this->spec,
            join( ', ', map {"'$_'"} sort { $a cmp $b } keys %$args ),
            join( ', ', map {"'$_'"} @$arg_names );

        return @$args{@$arg_names};
    }
    else {
        croak sprintf "Invalid args for route '%s' (%s)", $this->spec, $args;
    }
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 

__END__

=pod

=encoding UTF-8

=head1 NAME

Router::Pygmy::Route - simple route object 

=head1 VERSION

version 0.05

=head1 AUTHOR

Roman Daniel <roman.daniel@davosro.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
