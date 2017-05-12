# $Id: Constants.pm,v 1.13 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Delicious::Constants;

$Net::Delicious::Constants::VERSION = '1.14';

=head1 NAME

Net::Delicious::Constants - del.icio.us constant variables

=head1 SYNOPSIS

  # Import all the constants exported
  # by Net::Delicious::Constants::Uri
  # into the current package.

  use Net::Delicious::Constants qw (:uri);

=head1 DESCRIPTION

Import del.icio.us constant variables

=cut

sub import {
    my $self = shift;
    
    #
    
    my @sets  = ();
    my $debug = 0;
    
    foreach (@_) {
	if ($_ =~ /^:(.*)/) {
	    push @sets, $1;
	}
	
	elsif (/^\+(.*)/) {
	    
	    if ($1 eq "debug") {
		$debug = 1;
	    }
	}
	
	else { next; }
    }
    
    #
    
    foreach my $set (@sets) {
	
	# paranoia / 
	# will destroy ya
	$set =~ s/:://g;
	
	my $package = join("::",__PACKAGE__,ucfirst(lc($set)));
	my $caller  = caller;
	
	print STDERR "* $caller wants to import $set\n"
	    if ($debug);
	
	eval "require $package;";
	die $@ if ($@);
	
	no strict 'refs';
	
	foreach my $constant (@{$package."::EXPORT_OK"}) {
	    *{join("::",$caller,$constant)} = \&{join("::",$package,$constant)};
	}
    }
}


=head1 VERSION

1.13

=head1 DATE

$Date: 2008/03/03 16:55:04 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Delicious>

=head1 LICENSE

Copyright (c) 2004-2008 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
