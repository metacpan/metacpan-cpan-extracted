package TM::Materialized::JTM;
# $Id: JTM.pm,v 1.1 2010/04/09 09:57:17 az Exp $ 

use strict;
use Class::Trait qw(TM::Serializable::JTM);
use TM::Materialized::Stream;
use base qw (TM::Materialized::Stream);

use vars qw($VERSION);
$VERSION = qw(('$Revision: 1.2 $'))[1];

=pod

=head1 NAME

TM::Materialized::JTM - Topic Maps, trait for JSON Topic Map instances.

=head1 SYNOPSIS

  use TM::Materialized::JTM;
  my $tm=TM::Materialized::JTM(file=>"somefile.jtm");
  $tm->sync_in;
  ...
  # map was modified, now save the changes
  $tm->sync_out;

=head1 DESCRIPTION

This package provides map parsing and creating functionality for JTM (JSON Topic Map) instances.
The JSON Topic Map format is defined here: L<http://www.cerny-online.com/jtm/1.0/>.

=head1 INTERFACE

=head2 Methods

=over

=item B<Constructor>

I<$tm> = TM::Materialized::JTM->new (...);

The constructor expects a hash as described in L<TM::Materialized::Stream>, with one additional 
key/value parameter:

=over

=item * B<format> (choices: C<"json">, C<"yaml">)

This option controls whether the JTM data is treated as being in JSON format
or in YAML (which is a superset of JSON). This applies to both reading and writing of
map data. 

The default value is C<"json">.

=back

=cut

sub new 
{
    my ($class,%options)=@_;

    $options{psis}=$TM::PSI::topicmaps; 
    $options{format}||="json";

    return bless $class->SUPER::new(%options), $class;
}

=pod

=item B<format>

I<$tm>->format('json');

I<$curformat>=I<$tm>->format;

This method gets or sets the format parameter for future operations. Possible choices: C<"json">, C<"yaml">.

=cut

sub format
{
    my ($self,$format)=@_;

    $self->{format}=$format if ($format=~/^(json|yaml)$/);
    return $self->{format};
}

=pod

=back

=head1 SEE ALSO

L<TM::Serializable::JTM>

=head1 AUTHOR INFORMATION

Copyright 2010, Alexander Zangerl, All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

1;
