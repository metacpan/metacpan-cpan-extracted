package Path::Router::Route::Slurpy;
{
  $Path::Router::Route::Slurpy::VERSION = '0.141330';
}
use Moose;

extends 'Path::Router::Route';

use Carp qw( croak );
use Path::Router::Route::Slurpy::Match;
use List::MoreUtils qw( any );

# ABSTRACT: Adds slurpy matching to Path::Router 


sub is_component_slurpy {
    my ($self, $component) = @_;
    $component =~ /^[+*]:/;
}


sub is_component_optional {
    my ($self, $component) = @_;
    $component =~ /^[?*]:/;
}


sub is_component_variable {
    my ($self, $component) = @_;
    $component =~ /^[?*+]?:/;
}


sub get_component_name {
    my ($self, $component) = @_;
    my ($name) = ($component =~ /^[?*+]?:(.*)$/);
    return $name;
}


sub has_slurpy_match {
    my $self = shift;
    return any { $self->is_component_slurpy($_) } reverse @{ $self->components };
}


sub create_default_mapping {
    my $self = shift;

    my %defaults = %{ $self->defaults };
    for my $key (keys %defaults) {
        if (ref $defaults{$key} eq 'ARRAY') {
            $defaults{$key} = [ @{ $defaults{$key} } ];
        }
    }

    return \%defaults;
}


sub match {
    my ($self, $parts) = @_;

    return unless (
        @$parts >= $self->length_without_optionals &&
        ($self->has_slurpy_match || @$parts <= $self->length)
    );

    my @parts = @$parts; # for shifting

    my $mapping = $self->has_defaults ? $self->create_default_mapping : {};

    for my $c (@{ $self->components }) {
        unless (@parts) {
            die "should never get here: " .
                "no \@parts left, but more required components remain"
                    unless $self->is_component_optional($c);

            last;
        }

        my $part;
        if ($self->is_component_slurpy($c)) {
            $part = [ @parts ];
            @parts = ();
        }
        else {
            $part = shift @parts;
        }

        if ($self->is_component_variable($c)) {
            my $name = $self->get_component_name($c);

            if (my $v = $self->has_validation_for($name)) {
                return unless $v->check($part);
            }

            $mapping->{$name} = $part;
        }

        else {
            return unless $c eq $part;
        }
    }

    return Path::Router::Route::Slurpy::Match->new(
        path    => join('/', @$parts),
        route   => $self,
        mapping => $mapping,
    );
}


sub generate_match_code {
    croak("The inline matching mode is not supported by Path::Router::Route::Slurpy. Please see the CAVEATS section of that module's documentation for details.");
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Path::Router::Route::Slurpy - Adds slurpy matching to Path::Router 

=head1 VERSION

version 0.141330

=head1 SYNOPSIS

    use Path::Router;
    use Path::Router::Route::Slurpy;
    use Moose::Util::TypeConstraints;
    use List::MoreUtils qw( all );

    my $router = Path::Router->new(
        route_class => 'Path::Router::Route::Slurpy',
        inline      => 0, # IMPORTANT! See CAVEATS
    );

    $router->add_route('page/*:page' => (
        validations => subtype('ArrayRef[Str]' => where {
            all { /^[_a-z0-9\-.]+(?:\.[_a-z0-9\-]+)*$/i } @$_
        }),
        target => 'MyApp::Controller::Page',
    );

    $router->add_route('attachment/+:file' => (
        validations => subtype('ArrayRef[Str]' => where {
            all { /^[_a-z0-9\-.]+(?:\.[_a-z0-9\-]+)*$/i } @$_
        }),
        target => 'MyApp::Controller::Attachment',
    );

=head1 DESCRIPTION

This adds the ability to perform "slurpy" matching in L<Path::Router>. This code
originated out of my desire to use L<Path::Router>, but to allow for arbitrary
length paths in a hierarchical wiki. For example, I wanted to build a route with
a path match defined like this:

    page/*:page

Here the final C<:page> variable should match any number of path parts. The
built-in L<Path::Router> match has no way to do this.

In addition to the C<?> variable modifier that L<Path::Router::Route> provides,
this adds a C<+> which matches 1 or more path parts and C<*> which matches 0 or
more path parts. These additional matches will be returned in the match mapping
as arrays (possibly empty in the case of C<*>). Similarly, validations of these
matches must also be based upon an C<ArrayRef> Moose type.

=head1 CAVEATS

L<Path::Router> provides a very nice inline code generation tool that speeds
matching up a little bit. This works by generating the Perl code needed to
perform the matches and compiling that directly. This means there's a slight
startup cost, but that all matching operations are faster, which is a good
thing.

Unfortunately, I have not yet implemented this code generation yet. So you
B<MUST> pass the C<inline> setting to the constructor, like so:

    my $router = Path::Router->new(
        route_class => 'Path::Router::Route::Slurpy',
        inline      => 0,
    );

Without that, the module does not work as of this writing.

=head1 EXTENDS

L<Path::Router::Route>

=head1 METHODS

=head2 is_component_slurpy

If the path component is like "*:var" or "+:var", it is slurpy.

=head2 is_component_optional

If the path component is like "?:var" or "*:var", it is optional.

=head2 is_component_variable

If the path component is like "?:var" or "+:var" or "*:var" or ":var", it is a
variable.

=head2 get_component_name

Grabs the name out of a variable.

=head2 has_slurpy_match

Returns true if any component is slurpy.

=head2 create_default_mapping

If a default value is an array reference, copies that array.

=head2 match

Adds support for slurpy matching.

=head2 generate_match_code

As of this writing, this will always die with a warning that the C<< inline => 0 >> setting must be set on the L<Path::Router> constructor. 

See L</CAVEATS> for details.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
