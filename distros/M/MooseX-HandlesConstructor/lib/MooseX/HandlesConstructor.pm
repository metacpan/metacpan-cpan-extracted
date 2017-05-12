package MooseX::HandlesConstructor;
# ABSTRACT: Moo[se] extension that allows for setting handle accessors with the constructor
$MooseX::HandlesConstructor::VERSION = '0.001';
use strict;
use warnings;
use MooseX::MungeHas ();
use Import::Into;
use Class::Method::Modifiers qw(install_modifier);

sub import {
	my ($class) = @_;

	my $target = caller;

	my %_handles_via_accessors;

	MooseX::MungeHas->import::into( $target, sub {
		my $name = shift;
		my %has_args = @_;
		if( exists $has_args{handles} ) {
			my %handles = %{ $has_args{handles} };
			my @accessors = grep {
					my $handle_val = $handles{$_};
					ref $handle_val eq 'ARRAY'
					and @$handle_val == 2
					and $handle_val->[0] eq 'accessor'
				} keys %handles;
			@_handles_via_accessors{ @accessors } = (1) x @accessors;
		}
	} );

	install_modifier( $target, 'fresh', BUILD => sub {} ) unless $target->can('BUILD');

	install_modifier($target, 'after', BUILD => sub {
		my ($self, $args) = @_;
		while( my ($attr, $attr_value) = each %$args ) {
			# NOTE This may be better handled as a set intersection
			# between (keys %_handles_via_accessors) and
			# (keys %$args) but for small hashes, it's probably not
			# efficient.
			if( exists $_handles_via_accessors{$attr} ) {
				$self->$attr( $attr_value );
			}
		}
	});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::HandlesConstructor - Moo[se] extension that allows for setting handle accessors with the constructor

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package Message;

    use Moo; # or Moose traits
    use MooX::HandlesVia;
    use MooseX::HandlesConstructor;

    has header => ( is => 'rw',
        default => sub { {} },
        handles_via => 'Hash',
        handles => {
            session =>  [ accessor => 'session'  ],
            msg_type => [ accessor => 'msg_type' ]
        }
    );

    # elsewhere...
    my $msg = Message->new( msg_type => 'reply', header => { answer => 42 }  );
    use Data::Dumper; print Dumper $msg->header;
    # $VAR1 = {
    #           'answer' => 42,
    #           'msg_type' => 'reply'
    #         };

=head1 DESCRIPTION

When using Moo or Moose handles that provide an accessor handle on an
attribute, it may make sense to pass the name of handles to the constructor to
simplify the API. Using this module will get all curried accessor handles
defined in a class and allow setting them when calling C<->new()>

=head1 SEE ALSO

L<MooX::HandlesVia>, L<Moose native delegation|Moose::Manual::Delegation/"NATIVE DELEGATION">.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
