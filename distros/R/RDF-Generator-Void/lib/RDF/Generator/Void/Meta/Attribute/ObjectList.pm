package RDF::Generator::Void::Meta::Attribute::ObjectList;

use Moose::Role;


=head1 NAME

RDF::Generator::Void::Meta::Attribute::ObjectList - Trait for list of RDF objects

=head1 SYNOPSIS

 has _endpoints => ( traits => ['ObjectList'] );
 has _titles => (
				  traits => ['ObjectList'],
				  isa      => 'ArrayRef[RDF::Trine::Node::Literal]',
				 );
 has resources => ( traits => ['ObjectList'] );

=head2 DESCRIPTION

This module gives you a trait to manage a list of RDF resources
typically used in an object position in an RDF triple. When declaring
attributes, you may use C<traits => ['ObjectList']> alone in which
case it'll give you a arrayref of strings and the methods to push to
the array, list all strings in the array, and to check if it is
empty. These are created by prefixing C<add_>, C<all_> and C<has_no_>
to your attribute name, respectively.

If you have an underscore in the beginning, the attribute will not
itself be a method, but you can still use the non-prefixed attribute
name as argument to the constructor, and you will have the same methods as above.

You may also give a C<isa> argument to the attribute. In that case,
you may set the arrayref to contain something other than strings, like
in the example above.

=cut

with (
    'Moose::Meta::Attribute::Native::Trait::Array',
);

around _process_options => sub {
	my $orig = shift;
	my (undef, $attr_name, $options) = @_;
	
	$options->{is}  = 'rw';
	$options->{isa} = 'ArrayRef[Str]' unless exists $options->{isa};

	if ($attr_name =~ /^_(.+)/) {
		$attr_name = $1;
		$options->{init_arg} = $attr_name;
	}
	
	# WTF isn't this like crazy to add traits to the class in a trait. Hmm, Nah, that's okay.
	$options->{traits} = [] unless exists $options->{traits};
	push @{ $options->{traits} }, 'Moose::Meta::Attribute::Native::Trait::Array';
	
	$options->{default} = sub {[]};
	$options->{handles} = {
								  sprintf("add_%s", $attr_name) => 'push',
								  sprintf("all_%s", $attr_name) => 'uniq',
								  sprintf("has_no_%s", $attr_name) => 'is_empty',
								 };
	$orig->(@_);
};



=head1 FURTHER DOCUMENTATION

Please see L<RDF::Generator::Void> for further documentation.

=head1 AUTHORS AND COPYRIGHT

This module was prototyped by Konstantin Baierer and is mostly his work.

Please see L<RDF::Generator::Void> for more information about authors
and copyright for this module.


=cut

1;
