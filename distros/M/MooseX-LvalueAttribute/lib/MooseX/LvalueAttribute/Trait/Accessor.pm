package MooseX::LvalueAttribute::Trait::Accessor;

our $VERSION   = '0.981';
our $AUTHORITY = 'cpan:TOBYINK';

use Moose::Role;

use Variable::Magic ();
use Hash::Util::FieldHash::Compat ();
use Scalar::Util ();

Hash::Util::FieldHash::Compat::fieldhash(our %LVALUES);

override _generate_accessor_method => sub
{
	my $self = shift;
	
	my $attr = $self->associated_attribute;
	my $attr_name = $attr->name;
	Scalar::Util::weaken($attr);
	
	# Some type constraints assign the value to a temporary variable
	# which results in very unusual error messages.
	#
	my ($SET, $GET);
	if ($MooseX::LvalueAttribute::INLINE and not $attr->type_constraint)
	{
		eval { $SET = $self->_generate_writer_method_inline };
		eval { $GET = $self->_generate_reader_method_inline };
	}
	
	return sub :lvalue {
		my $instance = shift;
		Scalar::Util::weaken($instance);
		
		unless (exists $LVALUES{$instance}{$attr_name})
		{
			my $wiz = Variable::Magic::wizard(
				set => $SET
					? sub { @_ = ($instance, ${$_[0]}); goto $SET }
					: sub { $attr->set_value($instance, ${$_[0]}) },
				get => $GET
					? sub { ${$_[0]} = $GET->($instance); $_[0] }
					: sub { ${$_[0]} = $attr->get_value($instance); $_[0] },
			);
			
			Variable::Magic::cast($LVALUES{$instance}{$attr_name}, $wiz);
		}
		
		@_ and $attr->set_value($instance, $_[0]);
		$LVALUES{$instance}{$attr_name};
	};
};

1;


__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::LvalueAttribute::Trait::Accessor - internals for MooseX::LvalueAttribute

=head1 DESCRIPTION

This accessor trait overrides the generation of accessors (but not
readers, writers, clearers or predicates) to supply the necessary lvalue
logic.

It currently I<< does not >> support inlining, so will make your accessors
slower I<< even when not used in an lvalue context >>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-LvalueAttribute>.

=head1 SEE ALSO

L<MooseX::LvalueAttribute>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on work by
Christopher Brown, C<< <cbrown at opendatagroup.com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster;
2008 by Christopher Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

