package Siebel::Srvrmgr::Daemon::Action;

=pod

=head1 NAME

Siebel::Srvrmgr::Daemon::Action - base class for Siebel::Srvrmgr::Daemon action

=head1 SYNOPSIS

This class must be subclassed and the C<do> method overrided.

An subclass should return true ONLY when was able to identify the type of output received. Beware that the output expected must include also
the command executed or the L<Siebel::Srvrmgr::ListParser> object will not be able to identify the type of the output (L<Siebel::Srvrmgr::Daemon> does that).

This can be accomplish using something like this in the C<do> method:

    sub do {
        my ($self, $buffer) = @_;
		$self->get_parser()->parse($buffer);
		my $tree = $self->get_parser()->get_parsed_tree();

		foreach my $obj ( @{$tree} ) {

			if ( $obj->isa('Siebel::Srvrmgr::ListParser::Output::MyOutputSubclassName') ) {
				my $data =  $obj->get_data_parsed();
                # do something
				return 1;
			}

		}

		return 0;
	}

Where MyOutputSubclassName is a subclass of L<Siebel::Srvrmgr::ListParser::Output>.

If this kind of output is not identified and the proper C<return> given, L<Siebel::Srvrmgr::Daemon> can enter in a 
infinite loop.

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Carp;
our $VERSION = '0.29'; # VERSION

=pod

=head1 ATTRIBUTES

=head2 parser

A reference to a L<Siebel::Srvrmgr::ListParser> object. This attribute is required during object creation 
and is read-only.

=cut

has parser => (
    isa      => 'Siebel::Srvrmgr::ListParser',
    is       => 'ro',
    required => 1,
    reader   => 'get_parser'
);

=pod

=head2 params

An array reference. C<params> is an optional attribute during the object creation and it is used to pass additional parameters. How
those parameters are going to be used is left to who is creating subclasses of L<Siebel::Srvrmgr::Daemon::Action>.

This attribute is read-only.

=cut

# :TODO:19-01-2014:: add a method to remove the params reference when desired to release memory

has params => (
    isa     => 'ArrayRef',
    is      => 'ro',
    reader  => 'get_params',
    default => sub { [] }
);

=pod

=head2 expected_output

A string telling the expected output type the L<Siebel::Srvrmgr::Daemon::Action> subclass expectes to find. This is a lazy attribute since each subclass may have a
different type of expected output.

The string must be the name of a subclass of L<Siebel::Srvrmgr::ListParser::Output> and it will be used for validation during execution of C<do_parsed> method.

=cut

has expected_output => (
    isa     => 'Str',
    is      => 'ro',
    reader  => 'get_exp_output',
    writer  => '_set_exp_output',
    builder => '_build_exp_output',
    lazy    => 1                      #some subclasses will not use it
);

sub _build_exp_output {
	
	my $self = shift;

    confess blessed($self)
      . ', as a subclass of Siebel::Srvrmgr::Daemon::Action, must override the _build_exp_output method';

}

=pod

=head1 METHODS

=head2 get_parser

Returns the L<Siebel::Srvrmgr::ListParser> object stored into the C<parser> attribute.

=head2 get_params

Returns the array reference stored in the C<params> attribute.

=head2 do

This method expects to receive a array reference (with the content to be parsed) as parameter and it will do something with it. Usually this should be
identify the type of output received, giving it to the proper parse and processing it somehow.

Every C<do> method must return true (1) if output was used, otherwise false (0).

This method does:

=over

=item parsing of the content of the buffer with the parser returned by C<get_parser> method

=item invokes the C<do_parsed> method passing the tree returned from the parser

=item clear the parser with the C<clear_parsed_tree> method.

=item returns the returned value of the C<do_parsed> method.

=back

=cut

sub do {

    my $self   = shift;
    my $buffer = shift;

    $self->get_parser()->parse($buffer);

    my $tree = $self->get_parser()->get_parsed_tree();

    my $was_found = 0;

    foreach my $item ( @{$tree} ) {

        $was_found = $self->do_parsed($item);
        last if ($was_found);

    }

    $self->get_parser()->clear_parsed_tree();

    return $was_found;

}

=pod

=head2 do_parsed

This method must be overrided by subclasses or it will C<die> with trace.

It expects an array reference with the parsed tree given by C<get_parsed_tree> of a L<Siebel::Srvrmgr::ListParser> instance.

This method is invoked internally by C<do> method, but is also usable directly if the parsed tree is given as expected.

If the output is used, this method must returns true, otherwise false.

=cut

sub do_parsed {

    confess
'do_parsed must be overrided by subclasses of Siebel::Srvrmgr::Daemon::Action';

}

=pod

=head1 CAVEATS

This class may be changed to a role instead of a superclass in the future since it's methods could be used by different classes.

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Moose::Manual::MethodModifiers>

=item *

L<Siebel::Srvrmgr::ListParser>

=item *

L<Siebel::Srvrmgr::Daemon>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
