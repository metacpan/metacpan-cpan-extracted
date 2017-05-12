package Template::Stash::Encode;

use strict;
use warnings;

use Encode;
use Template::Config;

use base $Template::Config::STASH;

=head1 NAME

Template::Stash::Encode - Encode charactor code on stash variables

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	use Template::Stash::Encode;
	use Template;

	my Template $tt = Template->new(
		STASH => Template::Stash::Encode->new(icode => 'utf8', ocode => 'shiftjis')
	);

=head1 METHODS

=head2 new

Constructor (See L<Template::Stash>).
See below constructor parameter of hash reference.

=over 2

=item icode

Input charactor code. (See L<Encode>)

=item ocode

Output charactor code. (See L<Encode>)

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	$self->{icode} = 'utf8' unless (exists $self->{icode} && $self->{icode});
	$self->{ocode} = 'utf8' unless (exists $self->{ocode} && $self->{ocode});
	
	return $self;
}

=head2 get

Override method.

=cut

sub get {
	my $self = shift;
	my $result = $self->SUPER::get(@_);
	return $result if (ref $result);
	
	Encode::from_to($result, $self->{icode}, $self->{ocode});
	return $result;
}

=head1 SEE ALSO

L<Template>, L<Encode>

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-stash-encode at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Stash-Encode>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Stash::Encode

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Stash-Encode>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Stash-Encode>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Stash-Encode>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Stash-Encode>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Template::Stash::Encode
