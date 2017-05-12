package Object::Disoriented;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp qw<croak>;

sub import {
    my (undef, $package, @functions) = @_;

    croak "What functions in $package do you want to disorient?"
        if !@functions;

    if (!eval "CORE::require $package; 1") {
        # Make the error message look like the caller's.
        $@ =~ s/\n* \s+ at \s+ \(eval \s+ \d+\) \s+ line \s+ \d+\.\n*\z//xms;
        croak $@;
    }

    # Create a (presumably spurious) instance
    my $instance = $package->new;

    # Ensure all desired functions exist as methods
    my @missing = grep { !$instance->can($_) } @functions;
    croak "Methods not found in $package: @missing"
        if @missing;

    # Build a sub for each desired function
    my $caller = caller;
    for my $name (@functions) {
        set_symbol($caller, $name, sub { $instance->$name(@_) });
    }

    return;
}

sub set_symbol {
    my ($package, $name, $value) = @_;
    no strict qw<refs>;
    *{"$package\::$name"} = $value;
}

1;
__END__

=head1 NAME

Object::Disoriented - remove object-orientation from modules

=head1 SYNOPSIS

    use Object::Disoriented HTML::Fraction => qw<tweak>;

    print tweak($html);

=head1 DESCRIPTION

Some Perl modules have interfaces that seem object-oriented interfaces, but
for no apparent reason.  For example, LE<eacute>on Brocard's
otherwise-excellent HTML::Fractions module insists you use it in an OO
manner:

    my $fractionifier = HTML::Fraction->new;
    print $fractionifier->tweak($html);

There's never anything interesting in the instance.  You have to spend code
on creating the instance, and then you have to pass that spurious instance
to each call.

I think that's pretty tedious; I'd much rather just have functions to call.
Enter Object::Disoriented.

Object::Disoriented is only used with C<use>.  The first argument is the
name of the unnecessarily-OO class; the class gets loaded if need be.
Subsequent arguments are the names of the functions you want:

    use Object::Disoriented HTML::Fraction => qw<tweak tweak_frac>;

Object::Disoriented internally creates an instance of the class you name.
The names you ask for are exported into your namespace; they are
freshly-created functions which just call the appropriate methods on the
instance it created for.

If you want to disorient two or more modules in a single Perl package, just
use Object::Disoriented more than once:

    use Object::Disoriented HTML::Fraction => qw<tweak tweak_frac>;
    use Object::Disoriented CGI::Simple    => qw<param upload_info>;

=head1 SEE ALSO

L<HTML::Fraction>, L<CGI::Simple>

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Aaron Crane.

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License, or (at your option) under the terms of the
GNU General Public License version 2.

=cut
