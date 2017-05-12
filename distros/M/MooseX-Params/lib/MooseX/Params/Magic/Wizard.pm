package MooseX::Params::Magic::Wizard;
{
  $MooseX::Params::Magic::Wizard::VERSION = '0.010';
}

# ABSTRACT: Magic behavior for %_

use 5.010;
use strict;
use warnings;
use Carp ();
use Scalar::Readonly qw(readonly_on);
use MooseX::Params::Util;
use MooseX::Params::Magic::Data;
use parent 'MooseX::Params::Magic::Base';

sub data
{
    my ($ref, %data) = @_;
    return MooseX::Params::Magic::Data->new(%data);
}

sub fetch
{
    my ( $ref, $data, $key ) = @_;

    # throw exception if $key is not a valid parameter name
    my @allowed = $data->allowed_parameters;
    Carp::croak("Attempt to access non-existant parameter $key")
        unless $key ~~ @allowed;

    # quit if this parameter has already been processed
    return if exists $$ref{$key};

    my $builder = $data->get_parameter($key)->builder_sub;
    my $wrapped = $data->wrap($builder, $data->package, $data->parameters, $key);

    # this check should not be necessary
    if ($builder)
    {
        my %updated = $wrapped->(%$ref);
        foreach my $updated_key ( keys %updated )
        {
            next if exists $$ref{$updated_key};
            my $value  = $updated{$updated_key};
            $$ref{$updated_key} = $value;
            readonly_on $$ref{$updated_key};
        }
    }
    else
    {
        my $value = undef;
        $ref->{$key} = $value;
        readonly_on $$ref{$key};
    }
}

sub store
{
    my ( $ref, $data, $key ) = @_;

    my @allowed = $data->allowed_parameters;
    Carp::croak("Attempt to create non-existant parameter $key")
        unless $key ~~ @allowed;

    my $caller   = caller;
    my $op = $_[-1];

    if ( # see http://rt.cpan.org/Public/Bug/Display.html?id=74453
           $op->name eq 'hslice' and $op->flags & 16 and $op->flags & 128 and not $op->private and
         # values can only be set by MooseX::params::Magic::Wizard::fetch()
           $caller ne 'MooseX::Params::Magic::Wizard'
         # fix for http://rt.cpan.org/Public/Bug/Display.html?id=73819
           and $caller ne 'MooseX::Params::Util' )
    {
        Carp::croak "Attempt to modify read-only parameter '$key'";
    }
}

1;

__END__
=pod

=for :stopwords Peter Shangov TODO invocant isa metaroles metarole multimethods sourcecode
backwards buildargs checkargs slurpy preprocess

=head1 NAME

MooseX::Params::Magic::Wizard - Magic behavior for %_

=head1 VERSION

version 0.010

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

