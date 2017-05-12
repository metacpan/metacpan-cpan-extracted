package POD::Credentials;

use warnings;
use strict;
use English qw( -no_match_vars);
use version; our $VERSION =  '0.04';

=head1 NAME

POD::Credentials - POD credentials OO wrapper (see also, author, license, copyright) 

=head1 VERSION

Version 0.04

=head1 DESCRIPTION

instance of this class is capable of setting up POD credentials, as 
C<see also, author, license, copyright> and returning  it  as string

=head1 SYNOPSIS

    use POD::Credentials;
    my $cred = POD::Credentials->new({
 				      author => 'Joe Doe', 
     				      license => <license text, default is Perl artistic>,
 				      copyright => <some text, default is copyright 
     						    by author name with current year'>
     				    });
    print $cred->asString();

## it will automatically set B<SEE ALSO> as the link to the name of the caller's package if defined and not C<main>

=head1 METHODS 

accessors/mutators are provided by  L<Class::Accessor::Fast> for each public field

=head2 new()

constructor, accepts single parameter - reference to hash where keys from the list:
C<author copyright license year see_also>

=head2 author()

accessor/mutator  for the C<AUTHOR> pod element

=head2 copyright()

accessor/mutator  for the C<COPYRIGHT> pod element

=head2  license()

accessor/mutator  for the C<LICENSE> pod element

=head2 year()

accessor/mutator  for the year used in C<COPYRIGHT>

=head2 see_also()

accessor/mutator  for the C<SEE ALSO> pod element

=head2  end_module()

if set then module will be finished with:


    __END__
  
    1;

and then credentials pod will be added

=cut

use POSIX qw(strftime);
use Class::Accessor::Fast;
use Class::Fields;
use Carp;
use base qw(Class::Accessor::Fast Class::Fields);
use fields qw(author copyright license year see_also end_module);
POD::Credentials->mk_accessors(POD::Credentials->show_fields('Public')); 
 
sub new {
    my ( $that, $param ) = @_;
    my $class = ref($that) || $that;
    my $self = fields::new($class);
    # setting defaults
    $self->year(strftime "%Y", localtime(time));
    if ($param  && ref($param) ne 'HASH' ) {
        croak("ONLY hash ref accepted as param and not:   $param ");
    }
    ## initializing
    map { $self->{$_} = $param->{$_} if $_  && $self->can($_)} keys %{$param};   ###
    
    return $self;
}
 
=head2 asString()

   returns string repsresentation, no arguments accepted

=cut

sub asString {
    my ($self) = @_;
    my $string =  $self->end_module?"\n\n1;\n\n__END__\n\n":"\n";
    my($see_also,  $author, $copyright, $license) = ($self->see_also, $self->author,$self->copyright,$self->license); 
    map {  s/^\s+// if defined $_ }($see_also,  $author, $copyright, $license); 
    if($see_also) {
        $string .= "\n=head1  SEE ALSO\n\n$see_also\n";
    }  
    if($author) {
        $string .= "\n=head1 AUTHOR\n\n$author\n";
    }
    if($copyright) {
        $string .= "\n=head1 COPYRIGHT\n\n$copyright\n";
    } elsif($author) {
        $string .= "\n=head1 COPYRIGHT\n\nCopyright (c) " . $self->year  . ", $author. All rights reserved.\n";
    }
    if($license) {
        $string .= "\n=head1 LICENSE\n\n$license\n";
    } else {
        $string .= "\n=head1 LICENSE\n\nThis program is free software.\nYou can redistribute it and/or modify it under the same terms as Perl itself.\n";
    }
    $string .= "\n=cut\n\n";
    return $string;
}

=head1 AUTHOR

Maxim Grigoriev,  maxim_at_fnal_gov

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-credentials at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POD-Credentials>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
 

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POD::Credentials


You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POD-Credentials>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POD-Credentials>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POD-Credentials>

=item * Search CPAN

L<http://search.cpan.org/dist/POD-Credentials>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009  Fermi Research Alliance (FRA).

This program is free software; you can redistribute it and/or modify it
under the Fermitools license, see L<http://fermitools.fnal.gov/about/terms.html>


=cut

1; # End of POD::Credentials
