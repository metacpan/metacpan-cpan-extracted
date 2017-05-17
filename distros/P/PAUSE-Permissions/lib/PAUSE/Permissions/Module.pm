package PAUSE::Permissions::Module;
$PAUSE::Permissions::Module::VERSION = '0.17';
use Moo;

# TODO: I had isa when I was using Moose, need to put those back

has 'name' => (is => 'ro');

# has 'm' => (is => 'ro', isa => 'Str');
has 'm' => (is => 'ro');

# has 'f' => (is => 'ro', isa => 'Str');
has 'f' => (is => 'ro');

# has 'c' => (is => 'ro', isa => 'ArrayRef[Str]');
has 'c' => (is => 'ro');

sub owner
{
    my $self = shift;

    return $self->m || $self->f || undef;
}

sub registered_maintainer
{
    my $self = shift;
    return $self->m || undef;
}

sub first_come
{
    my $self = shift;
    return $self->f || undef;
}

sub co_maintainers
{
    my $self = shift;
    my @comaints;

    push(@comaints, $self->f) if defined($self->m) && defined($self->f);
    push(@comaints, @{ $self->c }) if defined($self->c);

    @comaints = sort @comaints;
    return @comaints;
}

sub all_maintainers
{
    my $self = shift;
    my @all;

    push(@all, $self->m)      if defined($self->m);
    push(@all, $self->f)      if defined($self->f);
    push(@all, @{ $self->c }) if defined($self->c);

    @all = sort @all;
    return @all;
}

1;

=head1 NAME

PAUSE::Permissions::Module - PAUSE permissions for one module (from 06perms.txt)

=head1 SYNOPSIS

 use PAUSE::Permissions::Module;

 my %options =
    (
     name => 'HTTP::Client',
     m    => 'LINC',
     f    => 'P5P,
     c    => ['NEILB'],
    );
  
 my $mp = PAUSE::Permissions::Module->new( %options );
 
 print "owner = ", $mp->owner, "\n";

=head1 DESCRIPTION

PAUSE::Permissions::Module is a data class, an instance of which is returned
by the C<module_permissions()> method in L<PAUSE::Permissions>.
It's not expected that you'll instantiate this module yourself,
but you're probably reading this to find out what methods are supported.

=head1 METHODS

To understand the three levels of PAUSE permissions, see L<PAUSE::Permissions/"The 06params.txt file">.

=head2 owner 

Returns a single PAUSE id, or C<undef>.

=head2 co_maintainers

Returns a list of PAUSE ids,
which will be empty if the module doesn't have any co-maintainers.
The list will be sorted alphabetically.

B<Note:> if a module has both an 'm' permission and an 'f' permission,
then the user with the 'f' permission will included in the list returned by C<co_maintainers()>,
because PAUSE treats them as a co-maintainer.

=head2 registered_maintainer

Returns the PAUSE id of the registered maintainer of the module
(the 'm' permission),
or C<undef> if there isn't one defined for the module.

=head2 first_come

Returns the PAUSE id of the 'first uploader' for the module
(the 'f' permission),
or C<undef> if there isn't one defined for the module.

=head2 all_maintainers

Returns the PAUSE id of all users who have permissions for this module,
in alphabetical order.

=head1 SEE ALSO

L<PAUSE::Permissions>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

Thanks to Andreas KE<ouml>nig, for patiently answering many questions
on how this stuff all works.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2013 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

