package Net::Riak::Role::Base;
{
  $Net::Riak::Role::Base::VERSION = '0.1702';
}

use MooseX::Role::Parameterized;

parameter classes => (
    isa      => 'ArrayRef',
    required => 1,
);

role {
    my $p = shift;

    my $attributes = $p->classes;

    foreach my $attr (@$attributes) {
        my $name     = $attr->{name};
        my $required = $attr->{required},
          my $class  = "Net::Riak::" . (ucfirst $name);
        has $name => (
            is       => 'rw',
            isa      => $class,
            required => $required,
        );
    }
};

1;

__END__

=pod

=head1 NAME

Net::Riak::Role::Base

=head1 VERSION

version 0.1702

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>, robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
