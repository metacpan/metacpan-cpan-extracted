package Slackware::Slackget::SpecialFileContainerList;

use warnings;
use strict;

require Slackware::Slackget::List ;

=head1 NAME

Slackware::Slackget::SpecialFileContainerList - This class is a container of Slackware::Slackget::SpecialFileContainer object

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';
our @ISA = qw( Slackware::Slackget::List );

=head1 SYNOPSIS

This class is a container of Slackware::Slackget::SpecialFileContainer object, and allow you to perform some operations on this packages list. As the SpecialFileContainer class, it is a slack-get's internal representation of data.

    use Slackware::Slackget::SpecialFileContainerList;

    my $containerlist = Slackware::Slackget::SpecialFileContainerList->new();
    $containerlist->add($container);
    my $conainer = $containerlist->get($index);
    my $container = $containerlist->Shift();

Please read the Slackware::Slackget::List documentation for more informations (L<Slackware::Slackget::List>).

=head1 CONSTRUCTOR

=head2 new

This class constructor don't take any parameters.

	my $containerlist = new Slackware::Slackget::SpecialFileContainerList ();

=cut

sub new
{
	my ($class,%args) = @_ ;
	my $self={list_type => 'Slackware::Slackget::SpecialFileContainer','root-tag' => 'slack-get'};
	foreach (keys(%args))
	{
		$self->{$_} = $args{$_};
	}
	$self->{LIST} = [] ;
	$self->{ENCODING} = 'utf8' ;
	$self->{ENCODING} = $args{'encoding'} if(defined($args{'encoding'})) ;
	bless($self);#,$class
	return $self;
}

=head2 get_all_media_id

return a list of all id of the SpecialFileContainers.

=cut

sub get_all_media_id {
	my $self = shift;
	my %shortnames=();
	foreach my $obj (@{$self->get_all}){
		$shortnames{$obj->id}=1;
	}
	return keys(%shortnames);
}


=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::SpecialFileContainerList
