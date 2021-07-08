package Sub::Deprecate;

use parent 'Exporter';
our @EXPORT_OK = qw( sub_trigger_once_with sub_rename_with );

use v5.20;
use strict;
use warnings;

our $VERSION = '0.03';

use experimental "signatures";

sub _cb_rename ($from, $to) {
	warn qq(You called "$from" which is deprecated. It has been replaced with "$to", which we will jump to.\n);
}

sub sub_rename_with :prototype($$$;&) ($pkg, $from, $to, $cb = \&_cb_rename) {
	no strict 'refs';
	no warnings 'redefine';
	my $abs_from = "${pkg}::$from";
	my $abs_to   = "${pkg}::$to";
	my $sr_from  = *{$abs_from}{CODE};
	my $sr_to    = *{$abs_to}{CODE};
	
	if ( defined $sr_from ) {
		die "The From function '$abs_from' must not exist.\n"
	}
	elsif ( ! defined $sr_to ) {
		die "The To function '$abs_to' must exist.\n"
	}
	elsif ( $abs_from eq $abs_to ) {
		die "From function '$abs_from' and To function '$abs_to' are the same.\n";
	}

	my sub _temp {
		if (defined $cb && ref $cb eq 'CODE' ) {
			$cb->($abs_from, $abs_to);
		}
		*{$abs_from} = $sr_to;
		goto &$sr_to;
	};

	*{$abs_from} = \&_temp;
	return 1;
}

sub sub_trigger_once_with :prototype($$&) ($pkg, $target, $cb) {
	no strict 'refs';
	no warnings 'redefine';

	my $abs_target = "${pkg}::$target";
	my $sr_target     = *{$abs_target}{CODE};

	unless ( defined $sr_target ) {
		die "The target '$abs_target' must exist.\n"
	}

	my sub _temp {
		$cb->($abs_target);
		*{$abs_target} = $sr_target;
		goto &$sr_target;
	};

	*{$abs_target} = \&_temp;
	return 1;
}

__END__

=head1 NAME

Sub::Deprecate - Enables runtime graceful deprecation notices on sub calls

=head1 SYNOPSIS

This module will assist in providing a more graceful deprecation when you
can't control all your users.

    use experimental 'signatures';
    use Sub::Deprecate qw(sub_rename_with sub_trigger_once_with);
    
    sub foo { 7 };
    sub_trigger_once_with( __PACKAGE__, 'foo', sub ($target) { warn "Triggered!" } );
    # foo() # will trigger cb event
    
    
    sub fancy_new { 7 }
    sub_rename_with( __PACKAGE__, 'old_and_deprecated', 'fancy_new', sub ($old, $new) { warn "sub old_and_deprecated is deprecated" } );
    old_and_deprecated() # will warn and redirect to fancy_new

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 sub_rename_with($pkg, $from, $to, &cb($from,$to))

Allows you to rename a function. Typically this is done when an
old and deprecated function is moved elsewhere and you wish to retain the old
name. A further callback can be provided which will received the name of the
old function, and the new function.

=head2 sub_trigger_once_with($pkg, $target, &cb($target))

Allows you to trigger a callback when a remote function is called.

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-deprecate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Deprecate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Deprecate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Deprecate>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sub-Deprecate>

=item * Search CPAN

L<https://metacpan.org/release/Sub-Deprecate>

=back


=head1 ACKNOWLEDGEMENTS

This module was inspired by the blog post here L<https://phoenixtrap.com/2021/06/29/gradual-method-renaming-in-perl/> by Mark Gardner.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Evan Carroll.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Sub::Deprecate
