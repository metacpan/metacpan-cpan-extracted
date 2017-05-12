package SPOPS::Export::Perl;

# $Id: Perl.pm,v 3.3 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Export );
use Data::Dumper qw( Dumper );

$SPOPS::Export::Perl::VERSION  = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);

my @track = ();

sub create_footer { my $o = Dumper( \@track ); @track = (); return $o; }

sub create_record { push @track, $_[1]; return '' }

1;

__END__

=head1 NAME

SPOPS::Export::Perl - Dump SPOPS objects to a pure serialized Perl format

=head1 SYNOPSIS

 # See SPOPS::Export

=head1 DESCRIPTION

Just dump a set of SPOPS objects to a perl data structure using
L<Data::Dumper|Data::Dumper>.

=head1 PROPERTIES

No extra ones beyond L<SPOPS::Export|SPOPS::Export>

=head1 METHODS

B<create_record()>

Just track the record to be exported.

B<create_footer()>

Dump all tracked records out using L<Data::Dumper|Data::Dumper>.

=head1 BUGS

This will likely chew up tons of memory if you are exporting lots of
objects.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Import|SPOPS::Import>

L<Data::Dumper|Data::Dumper>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
