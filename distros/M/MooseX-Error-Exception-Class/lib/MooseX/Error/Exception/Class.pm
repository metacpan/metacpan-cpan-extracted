package MooseX::Error::Exception::Class;

use 5.008001;
use warnings;
use strict;

our $VERSION = '0.099';
$VERSION = eval { return $VERSION };

use Exception::Class 1.29 (
	'Exception::Moose' => {
		'description' => 'Error',
		'fields'      => [qw(message longmess)],
	},
	'Exception::Moose::Validation' => {
		'description' => 'Validation error',
		'isa'         => 'Exception::Moose',
		'fields'      => [qw(attribute type value message longmess)],
	},
);

sub Exception::Moose::full_message { ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . '  Time error caught: '
	  . localtime() . "\n";

	# Add trace to it if asked for.
	if ( ( $self->longmess() ) ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $string;
} ## end sub Exception::Moose::full_message

sub Exception::Moose::Validation::full_message
{ ## no critic 'Capitalization'
	my $self = shift;

	my $string =
	    $self->description()
	  . qq{:\n  '}
	  . $self->attribute()
	  . q{' not }
	  . $self->type()
	  . q{ (value passed in: '}
	  . $self->value
	  . qq{')\n}
	  . '  Time error caught: '
	  . localtime() . "\n";

	# Add trace to it if asked for.
	if ( ( $self->longmess() ) ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $string;
} ## end sub Exception::Moose::Validation::full_message

sub new {
	my ( $self, @args ) = @_;
	return $self->_create_error(@args);
}

sub _create_error {
	my ( $self, %args ) = @_;

	my @args = exists $args{message} ? $args{message} : ();
	my $info = join q{}, @args;

	if ($info =~ m{\A
	               Attribute [ ] \((.*)\)  # $1 = attribute name
				   [ ] does [ ] not [ ] pass [ ] the 
				   [ ] type [ ] constraint [ ] because: 
				   [ ] Validation [ ] failed [ ] for [ ] '(.*)' # $2 = type
				   [ ] failed [ ] with [ ] value [ ] (.*) # $3 = bad value
				   \z}msx
	  )
	{
		my ( $attr_name, $attr_type, $value ) = ( $1, $2, $3 );

		Exception::Moose::Validation->throw(
			message   => $info,
			attribute => $attr_name,
			type      => $attr_type,
			value     => $value,
			longmess  => exists $args{longmess} ? !!$args{longmess} : 1,
			ignore_class =>
			  [qw(MooseX::Error::Exception::Class Moose::Meta::Class)],
		);
	} else {
		Exception::Moose->throw(
			message  => $info,
			longmess => exists $args{longmess} ? !!$args{longmess} : 0,
			ignore_class =>
			  [qw(MooseX::Error::Exception::Class Moose::Meta::Class)],
		);
	}

	return;
} ## end sub _create_error

1;                                     # Magic true value required at end of module

__END__

=begin readme text

MooseX::Error::Exception::Class version 0.099

=end readme

=for readme stop

=head1 NAME

MooseX::Error::Exception::Class - Use Exception::Class exceptions for Moose errors

=head1 VERSION

This document describes MooseX::Error::Exception::Class version 0.099

=head1 SYNOPSIS

    # The "use metaclass" call has to go first, or it won't get picked up.
    use metaclass (
        metaclass => "Moose::Meta::Class",
        error_class => "MooseX::Error::Exception::Class",
    );
    use Moose;

=for readme continue

=head1 DESCRIPTION

This module, when used as a parameter to the Moose metaclass, converts errors 
to subclasses of L<Exception::Class::Base|Exception::Class::Base>.

The "interface" (other than what is shown in the synopsis) is methods of the 
exception objects that are thrown.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will install a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 INTERFACE 

=head2 C<Error> (Exception::Moose);

This is the exception object created when no other type of object applies. Other objects are subclasses of this one.

=head3 $@->message()

Returns the error.

=head2 C<Validation error> (Exception::Moose::Validation);

This is the exception object created when a validation error is detected.

=head3 $@->attribute()

Returns the attribute whose assigned value did not validate.

=head3 $@->type()

Returns the type that it was supposed to validate against.

=head3 $@->value()

Returns the value that validation was attempted upon.

=head1 CONFIGURATION AND ENVIRONMENT
  
MooseX::Error::ExceptionClass requires no configuration files or environment variables.

=for readme continue

=head1 DEPENDENCIES

L<Moose|Moose> version 0.88, L<Exception::Class|Exception::Class> version
1.29.

=for readme stop

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Error-Exception-Class>
if you have an account there.

2) Email to E<lt>bug-MooseX-Error-Exception-Class@rt.cpan.orgE<gt> if you do not.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=for readme continue

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <csjewell@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 SEE ALSO

L<Exception::Class|Exception::Class>, L<http://csjewell.comyr.com/perl/>

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
