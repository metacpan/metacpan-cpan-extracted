package Tags::Utils::Preserve;

use strict;
use warnings;

use Class::Utils qw(set_params);
use List::Util 1.33 qw(any);
use Readonly;

# Constants.
Readonly::Scalar my $LAST_INDEX => -1;

our $VERSION = 0.16;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Preserved elements.
	$self->{'preserved'} = [];

	# Process params.
	set_params($self, @params);

	# Initialization.
	$self->reset;

	# Object.
	return $self;
}

# Process for begin of element.
sub begin {
	my ($self, $element) = @_;

	$self->save_previous;
	if (scalar @{$self->{'preserved'}}
		&& any { $element eq $_ } @{$self->{'preserved'}}) {

		push @{$self->{'preserved_stack'}}, $element;
		$self->{'preserved_flag'} = 1;
	}

	# Return preserved flags.
	return wantarray
		? ($self->{'preserved_flag'}, $self->{'prev_preserved_flag'})
		: $self->{'preserved_flag'};
}

# Process for end of element.
sub end {
	my ($self, $element) = @_;

	$self->save_previous;
	my $stack = $self->{'preserved_stack'};
	if (scalar @{$stack} && $element eq $stack->[$LAST_INDEX]) {
		pop @{$stack};
		if (! scalar @{$stack}) {
			$self->{'preserved_flag'} = 0;
		}
	}

	# Return preserved flags.
	return wantarray
		? ($self->{'preserved_flag'}, $self->{'prev_preserved_flag'})
		: $self->{'preserved_flag'};
}

# Get preserved flag.
sub get {
	my $self = shift;

	# Return preserved flags.
	return wantarray
		? ($self->{'preserved_flag'}, $self->{'prev_preserved_flag'})
		: $self->{'preserved_flag'};
}

# Resets.
sub reset {
	my $self = shift;

	# Preserved flag.
	$self->{'preserved_flag'} = 0;

	# Previsous preserved flag.
	$self->{'prev_preserved_flag'} = 0;

	# Preserved elements.
	$self->{'preserved_stack'} = [];

	return;
}

# Save previous stay.
sub save_previous {
	my $self = shift;

	$self->{'prev_preserved_flag'} = $self->{'preserved_flag'};

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags::Utils::Preserve - Class to check if content in element is preserved?

=head1 SYNOPSIS

 use Tags::Utils::Preserve;

 my $obj = Tags::Utils::Preserve->new(%params);
 my $preserved_flag = $obj->begin($element);
 my ($preserved_flag, $prev_preserved_flag) = $obj->begin($element);
 my $preserved_flag = $obj->end($element);
 my ($preserved_flag, $prev_preserved_flag) = $obj->end($element);
 my $preserved_flag = $obj->get;
 my ($preserved_flag, $prev_preserved_flag) = $obj->get;
 $obj->reset;
 $obj->save_previous;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::Utils::Preserve->new(%params);

Constructor.

=over 8

=item * C<preserved>

Preserved elements.

Default value is [].

=back

Returns instance of object.

=head2 C<begin>

 my $preserved_flag = $obj->begin($element);
 my ($preserved_flag, $prev_preserved_flag) = $obj->begin($element);

Process for begin of element.

Returns preserved flag in scalar context.

Returns preserved flag and previous preserved flag in array context.

=head2 C<end>

 my $preserved_flag = $obj->end($element);
 my ($preserved_flag, $prev_preserved_flag) = $obj->end($element);

Process for end of element.

Returns preserved flag in scalar context.

Returns preserved flag and previous preserved flag in array context.

=head2 C<get>

 my $preserved_flag = $obj->get;
 my ($preserved_flag, $prev_preserved_flag) = $obj->get;

Get preserved flag.

Returns preserved flag in scalar context.

Returns preserved flag and previous preserved flag in array context.

=head2 C<reset>

 $obj->reset;

Resets.

Returns undef.

=head2 C<save_previous>

 $obj->save_previous;

Save previous stay.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=preserve_test.pl

 use strict;
 use warnings;

 use Tags::Utils::Preserve;

 # Begin element helper.
 sub begin_helper {
         my ($pr, $element) = @_;
         print "ELEMENT: $element ";
         my ($pre, $pre_pre) = $pr->begin($element);
         print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";
 }
 
 # End element helper.
 sub end_helper {
         my ($pr, $element) = @_;
         print "ENDELEMENT: $element ";
         my ($pre, $pre_pre) = $pr->end($element);
         print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";
 
 }
 
 # Object.
 my $pr = Tags::Utils::Preserve->new(
         'preserved' => ['element']
 );
 
 # Process.
 begin_helper($pr, 'foo');
 begin_helper($pr, 'element');
 begin_helper($pr, 'foo');
 end_helper($pr, 'foo');
 end_helper($pr, 'element');
 end_helper($pr, 'foo');

 # Output:
 # ELEMENT: foo PRESERVED: 0 PREVIOUS PRESERVED: 0
 # ELEMENT: element PRESERVED: 1 PREVIOUS PRESERVED: 0
 # ELEMENT: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
 # ENDELEMENT: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
 # ENDELEMENT: element PRESERVED: 0 PREVIOUS PRESERVED: 1
 # ENDELEMENT: foo PRESERVED: 0 PREVIOUS PRESERVED: 0

=head1 DEPENDENCIES

L<Class::Utils>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Tags>

Install the Tags modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz/>

=head1 LICENSE AND COPYRIGHT

© 2005-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.16

=cut
