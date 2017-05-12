package MooseX::MetaDescription::Description;
use Moose;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

has 'descriptor' => (
    is       => 'ro',  
    does     => 'MooseX::MetaDescription::Meta::Trait',   
    weak_ref => 1, 
    required => 1,
);

no Moose; 1;

__END__

=pod

=head1 NAME

MooseX::MetaDescription::Description - A base class for Meta Descriptions

=head1 DESCRIPTION

This is a base class for building more complex custom meta-description
classes. All it does by default is to provide a back-link to the original
attribute it is describing.

=head1 METHODS 

=over 4

=item B<descriptor>

The actual attribute that is being described.

=item B<meta>

The Moose metaclass.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
