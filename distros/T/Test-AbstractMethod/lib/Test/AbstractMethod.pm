package Test::AbstractMethod;

use strict;

use base qw(Test::Builder::Module);

use vars qw(@EXPORT $VERSION);

$VERSION = 0.01;

@EXPORT = qw(call_abstract_function_ok call_abstract_method_ok call_abstract_class_method_ok);

sub call_abstract_function_ok($$;$) {
    my ($pkg, $method, $description) = @_;
    
    my $builder = Test::AbstractMethod->builder();
	
    eval {
        $pkg->can($method)->(0);
    };
    
    my $threw_exception = $@ && $@ =~ qr/$method\(\) should not be called as a function/;
    my $ok = $builder->ok( $threw_exception, $description );
    
    return $ok;
}

sub _call_abstract_method_ok($$$;$) {
    my ($pkg, $method, $callee, $description) = @_;
    
    my $builder = Test::AbstractMethod->builder();
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	
    my $cv = $pkg->can($method);
    eval {
        $cv->($callee);
    };
        
    my $threw_exception = $@ && $@ =~ qr/Class '$pkg' does not override ${method}()/;
    my $ok = $builder->ok( $threw_exception, $description );
    
    return $ok;
}

sub call_abstract_method_ok($$;$) {
    my ($pkg, $method, $description) = @_;

    my $callee = bless do { my $sv; \$sv; }, $pkg;
    return _call_abstract_method_ok($pkg, $method, $callee, $description);
}

sub call_abstract_class_method_ok($$;$) {
    my ($pkg, $method, $description) = @_;

    return _call_abstract_method_ok($pkg, $method, $pkg, $description);
}

1;
__END__

=head1 NAME

Test::AbstractMethod - Make sure your abstract methods croaks like they should

=head1 SYNOPSIS

	use Test::More tests => 3;
    use Test::AbstractMethod;
    
	use MyPackage;
	
    call_abstract_method_ok("MyPackage", "my_method")
    call_abstract_class_method_ok("MyPackage", "my_method")
    call_abstract_function_ok("MyPackage", "my_method")
    
=head1 DESCRIPTION

This module is a Test::Builder compatible testing module for testing calling abstract methods.

Abstract methods are methods that must be overridden by subclasses otherwise they throw an exception 
when called. This module can currently check that methods implemented as for example:

	package MyPackage;

	use Carp qw(croak);

	sub my_method {
	    my $self = shift;
	    $self = ref $self || $self;
	    croak "my_method() should not be called as a function" if !$self;
	    croak "Class '$self' does not override my_method()";
	}

The test functions in this module checks the exception thrown and not the implementation of a 
subroutine.

=head1 INTERFACE

=head2 FUNCTIONS

=over 4

=item call_abstract_method_ok  ( $package, $method, $description )

Calls the method I<$method> in I<$package>. First argument to method (ie self) will be 
a reference to a scalar blessed into I<$package>.

Checks that the subroutine throws an exception that matches the string 
"Class '${package}' does not override ${method}()"

=item call_abstract_class_method_ok ( $package. $method, $description ) 

Calls the method I<$method> in I<$package>. First argument to method (ie self) will be 
a I<$package>.

Checks that the subroutine throws an exception that matches the string 
"Class '${package}' does not override ${method}()"

=item call_abstract_function_ok ( $package, $method, $description ) 

Calls the method I<$method> in I<$package> as a function, that is not passing either 
the name of the package nor a reference blessed to the package as first argument.

Checks that the subroutine throws an exception that matches the string 
"${method}() should not be called as a function".

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-test-abstractmethod@rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Claes Jakobsson C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Claes Jakobsson C<< <claesjac@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
