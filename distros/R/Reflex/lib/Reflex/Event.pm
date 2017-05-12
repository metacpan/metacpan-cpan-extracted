package Reflex::Event;
$Reflex::Event::VERSION = '0.100';
use Moose;
use Scalar::Util qw(weaken);

# Class scoped storage.
# Each event class has a set of attribute names.
# There's no reason to calculate them every _clone() call.
my %attribute_names;

has _name => (
	is      => 'ro',
	isa     => 'Str',
	default => 'generic',
);

has _emitters => (
	is       => 'ro',
	isa      => 'ArrayRef[Any]',
	traits   => ['Array'],
	required => 1,
	handles  => {
		get_first_emitter => [ 'get', 0  ],
		get_last_emitter  => [ 'get', -1 ],
		get_all_emitters  => 'elements',
	}
);

sub _get_attribute_names {
	my $self = shift();
	return(
		$attribute_names{ ref $self } ||= [
			map { $_->name() }
			$self->meta()->get_all_attributes()
		]
	);
}

#sub BUILD {
#	my $self = shift();
#
#	# After build, weaken any emitters passed in.
#	#my $emitters = $self->_emitters();
#	#weaken($_) foreach @$emitters;
#}

sub push_emitter {
	my ($self, $item) = @_;

	use Carp qw(confess); confess "wtf" unless defined $item;

	my $emitters = $self->_emitters();
	push @$emitters, $item;
	#weaken($emitters->[-1]);
}

sub _headers {
	my $self = shift();
	return (
		map  { "-" . substr($_,1), $self->$_() }
		grep /^_/,
		@{ $self->_get_attribute_names() },
	);
}

sub _body {
	my $self = shift();
	return (
		map  { $_, $self->$_() }
		grep /^[^_]/,
		@{ $self->_get_attribute_names() },
	);
}

sub make_event_cloner {
	my $class = shift();

	my $class_meta = $class->meta();

	my @fetchers;
	foreach my $attribute_name (
		map { $_->name } $class_meta->get_all_attributes
	) {
		my $override_name = $attribute_name;
		$override_name =~ s/^_/-/;

		next if $attribute_name eq '_emitters';

		push @fetchers, (
			join ' ', (
				"\"$attribute_name\" => (",
				"(exists \$override_args{\"$override_name\"})",
				"? \$override_args{\"$override_name\"}",
				": \$self->$attribute_name()",
				")",
			)
		);
	}

	my $cloner_code = join ' ', (
		'sub {',
		'my ($self, %override_args) = @_;',
		'my %clone_args = ( ',
		join(',', @fetchers),
		');',
		'my $type = $override_args{"-type"} || ref($self);',
		'my $emitters = $self->_emitters() || [];',
		'$type->new(%clone_args, _emitters => [ @$emitters ]);',
		'}'
	);

	my $cloner = eval $cloner_code;
	if ($@) {
		die(
			"cloner compile error: $@\n",
			"cloner: $cloner_code\n"
		);
	}

	$class_meta->add_method( _clone => $cloner );
}

# Override Moose's dump().
sub dump {
	my $self = shift;

	my $dump = "=== $self ===\n";
	my %clone = ($self->_headers(), $self->_body());
	foreach my $k (sort keys %clone) {
		$dump .= "  $k: " . ($clone{$k} // '(undef)') . "\n";
		if ($k eq '-emitters') {
			my @emitters = $self->get_all_emitters();
			for my $i (0..$#emitters) {
				$dump .= "    emitter $i: $emitters[$i]\n";
			}
		}
	}

	# No newline so we get line numbers.
	$dump .= "===";

	return $dump;
}

__PACKAGE__->make_event_cloner;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Rocco Caputo

=head1 VERSION

This document describes version 0.100, released on April 02, 2017.

=for Pod::Coverage make_event_cloner push_emitter

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=back

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Reflex>.

=head1 AUTHOR

Rocco Caputo <rcaputo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Reflex/>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
