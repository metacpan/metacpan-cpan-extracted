package Tags::Utils::Preserve;

use strict;
use warnings;

use Class::Utils qw(set_params);
use List::MoreUtils qw(any);
use Readonly;

# Constants.
Readonly::Scalar my $LAST_INDEX => -1;

our $VERSION = 0.13;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Preserved tags.
	$self->{'preserved'} = [];

	# Process params.
	set_params($self, @params);

	# Initialization.
	$self->reset;

	# Object.
	return $self;
}

# Process for begin of tag.
sub begin {
	my ($self, $tag) = @_;

	$self->save_previous;
	if (scalar @{$self->{'preserved'}}
		&& any { $tag eq $_ } @{$self->{'preserved'}}) {

		push @{$self->{'preserved_stack'}}, $tag;
		$self->{'preserved_flag'} = 1;
	}

	# Return preserved flags.
	return wantarray
		? ($self->{'preserved_flag'}, $self->{'prev_preserved_flag'})
		: $self->{'preserved_flag'};
}

# Process for end of tag.
sub end {
	my ($self, $tag) = @_;

	$self->save_previous;
	my $stack = $self->{'preserved_stack'};
	if (scalar @{$stack} && $tag eq $stack->[$LAST_INDEX]) {
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

	# Preserved tag.
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
 my $preserved_flag = $obj->begin;
 my ($preserver_flag, $prev_preserved_flag) = $obj->begin;
 my $preserved_flag = $obj->end;
 my ($preserved_flag, $prev_preserved_flag) = $obj->end;
 $obj->get;
 $obj->reset;
 $obj->save_previous;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<preserved>

 Preserved tags.

=back

=item C<begin()>

 Process for begin of tag.
 Returns preserved flag in scalar context.
 Returns preserved flag and previous preserved flag in array context.

=item C<end()>

 Process for end of tag.
 Returns preserved flag in scalar context.
 Returns preserved flag and previous preserved flag in array context.

=item C<get()>

 Get preserved flag.
 Returns preserved flag in scalar context.
 Returns preserved flag and previous preserved flag in array context.

=item C<reset()>

 Resets.
 Returns undef.

=item C<save_previous()>

 Save previous stay.
 Returns undef.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Tags::Utils::Preserve;

 # Begin element helper.
 sub begin_helper {
         my ($pr, $tag) = @_;
         print "TAG: $tag ";
         my ($pre, $pre_pre) = $pr->begin($tag);
         print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";
 }
 
 # End element helper.
 sub end_helper {
         my ($pr, $tag) = @_;
         print "ENDTAG: $tag ";
         my ($pre, $pre_pre) = $pr->end($tag);
         print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";
 
 }
 
 # Object.
 my $pr = Tags::Utils::Preserve->new(
         'preserved' => ['tag']
 );
 
 # Process.
 begin_helper($pr, 'foo');
 begin_helper($pr, 'tag');
 begin_helper($pr, 'foo');
 end_helper($pr, 'foo');
 end_helper($pr, 'tag');
 end_helper($pr, 'foo');

 # Output:
 # TAG: foo PRESERVED: 0 PREVIOUS PRESERVED: 0
 # TAG: tag PRESERVED: 1 PREVIOUS PRESERVED: 0
 # TAG: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
 # ENDTAG: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
 # ENDTAG: tag PRESERVED: 0 PREVIOUS PRESERVED: 1
 # ENDTAG: foo PRESERVED: 0 PREVIOUS PRESERVED: 0

=head1 DEPENDENCIES

L<Class::Utils>,
L<List::MoreUtils>,
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

© 2005-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.13

=cut
