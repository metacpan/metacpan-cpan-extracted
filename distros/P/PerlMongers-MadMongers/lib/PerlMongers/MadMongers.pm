use strict;
use warnings;
package PerlMongers::MadMongers;
$PerlMongers::MadMongers::VERSION = '0.0001';
=head1 NAME

PerlMongers::MadMongers - Madison Wisconsin Area Perl Mongers

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

 use PerlMongers::MadMongers;

 my $mm = PerlMongers::MadMongers->new;

 say join(',' @{$mm->members});

 say $mm->website;

 say $mm->add_values(1,2,3,4);


=head1 DESCRIPTION

This is a set of utilities for the local Madison Perl Mongers group.


=head1 METHODS

=head2 new()

Constructor.

=cut

sub new {
    my $class = shift;
    bless {}, $class;
}

=head2 members()

Returns an array reference of the first names of the people who showed up on 2016-04-12.

=cut

sub members { 
    return [qw(Timm JT Steve Dave Jim Rob Matt Ken Doc)];
}

=head2 website()

Returns the URL string of our web site.

=cut

sub website {
    return 'http://www.madmongers.org';
}   

=head2 add_values(value1, value2, ...)

Takes a list of values and returns their sum.

=over

=item value1

A number you want to add.

=item value2

Another number to add to C<value1>.

=item ...

And so on.

=back

=cut

sub add_values {
    my ($self, @values) = @_;
    my $sum = 0;
    foreach my $value (@values) {
        $sum += $value;
    }
    return $sum;
}

=head1 COPYRIGHT

Licensed under the same terms as Perl itself.

=cut

1;
