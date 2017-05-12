# ==========================================
# Copyright (C) 2004 kyle dawkins
# kyle-at-centralparksoftware.com
# ObjectivePerl is free software; you can
# redistribute and/or modify it under the 
# same terms as perl itself.
# ==========================================

package ObjectivePerl::Object;
use strict;
sub new {
	return bless {}, $_[0];
}
sub init { return $_[0] }
sub handleUnknownSelector {
	my ($self, $message, $selectors) = @_;
	return undef;
}
1;
__END__

=head1 NAME

ObjectivePerl::Object - Root class for ObjectivePerl objects

=head1 SYNOPSIS

	use ObjectivePerl;
	@implementation MyClass

	+ new {
		~[$super new];
	}
	@end

In this example, MyClass is a subclass of
ObjectivePerl::Object, even without being
declared as such; all classes declared in this
way descend from ObjectivePerl::Object.

=head1 DESCRIPTION

This is the root class to all classes declared using the
ObjectivePerl @implementation/@end syntax.  It needs to
be there so that all classes declared in this way have
some super-class and can invoke $super from methods.

=head2 USES

Generally you don't instantiate or subclass this
directly.

=head1 BUGS

None known.

=head1 SEE ALSO

   ObjectivePerl

=head1 AUTHOR

kyle dawkins, E<lt>kyle@centralparksoftware.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by kyle dawkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
