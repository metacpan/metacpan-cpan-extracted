package MoobX::Trait::Observer;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: turn a Moose attribute into a MoobX observer
$MoobX::Trait::Observer::VERSION = '0.1.2';

use Moose::Role;
use MoobX::Observer;

use experimental 'signatures';

Moose::Util::meta_attribute_alias('Observer');

before _process_options => sub {
    my( $self, $name, $args) = @_;

    my $gen = $args->{default};

    $args->{lazy} //= 1;

    $args->{default} = sub { 
        my @args = @_;
        MoobX::Observer->new(
            generator => sub { $gen->(@args) },
            autorun => !$args->{lazy},
        ) 
    };
    
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Trait::Observer - turn a Moose attribute into a MoobX observer

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    package Person;

    use MoobX;

    our $OPENING :Observable = 'Dear';

    has name => (
        traits => [ 'Observable' ],
        is     => 'rw',
    );

    has address => (
        is => 'ro',
        traits => [ 'Observer' ],
        default => sub {
            my $self = shift;
            join ' ', $Person::OPENING, $self->name
        },
    );

    my $person = Person->new( name => 'Wilfred' );

    print $person->address;  # Dear Wilfred

    $Person::OPENING = 'My very dear';

    print $person->address;  # My very dear Wilfred

=head1 DESCRIPTION

Turns an object attribute into an observer. The C<default> argument
is used as the value-generating function.

By default the attribute will be considered to be lazy.
If the C<lazy> attribute is explicitly 
set to C<false>, then the observer will be of the C<autorun>
variety. Be careful, though, as it'll probably not do what you want if you
observe other attributes.

    package MyThing;

    use MoobX;

    has foo => (
        is => [ 'Observable' ],
    );

    has bar => (
        is => [ 'Observer' ],
        lazy => 0,
        default => sub {
            my $self = shift;

            # OOPS! If 'bar' is processed before 'foo'
            # at the object init stage, `$self->foo`
            # will not be an observable yet, so `bar`
            # will be set to be `1` and never react to anything
            $self->foo + 1;
        },
    );

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
